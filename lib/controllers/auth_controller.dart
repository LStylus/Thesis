import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user_model.dart';
import '../models/profile_model.dart';
import '../models/signup_draft_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  SignupDraftModel _draft = SignupDraftModel();
  SignupDraftModel get draft => _draft;

  bool isLoading = false;
  String? errorMessage;

  /// UID of the auth account created during step 1.
  /// It remains pending until the child info step is completed.
  String? pendingUid;

  bool _isExistingParentSession = false;
  bool get isExistingParentSession => _isExistingParentSession;

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }

  void saveParentInfo({
    required String parentName,
    required String relationshipToChild,
  }) {
    _draft = _draft.copyWith(
      parentName: parentName.trim(),
      relationshipToChild: relationshipToChild.trim(),
    );
    notifyListeners();
  }

  void saveChildInfo({
    required String childName,
    required DateTime? childBirthDate,
  }) {
    _draft = _draft.copyWith(
      childName: childName.trim(),
      childBirthDate: childBirthDate,
    );
    notifyListeners();
  }

  Future<bool> startAddChildForCurrentParent() async {
    errorMessage = null;
    _setLoading(true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        errorMessage = 'Please log in again to add another child.';
        return false;
      }

      final parentInfo = await _userService.fetchParentAccount(currentUser.uid);
      if (parentInfo == null || parentInfo.parentName.isEmpty) {
        errorMessage = 'Could not find this guardian account.';
        return false;
      }

      pendingUid = currentUser.uid;
      _isExistingParentSession = true;
      _draft = SignupDraftModel(
        email: currentUser.email ?? parentInfo.email,
        parentName: parentInfo.parentName,
        relationshipToChild: parentInfo.relationshipToChild,
      );

      return true;
    } catch (_) {
      errorMessage = 'Could not prepare the child profile form.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registerAccountStep1({
    required String email,
    required String password,
  }) async {
    errorMessage = null;
    _setLoading(true);

    try {
      final cleanEmail = email.trim();
      _isExistingParentSession = false;

      final credential = await _authService.signUpWithEmailPassword(
        email: cleanEmail,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('User creation failed.');
      }

      pendingUid = user.uid;
      _draft = SignupDraftModel(email: cleanEmail);

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return _continueWithExistingParent(
          email: email.trim(),
          password: password,
        );
      }

      errorMessage = _friendlySignupError(e.code);
      return false;
    } catch (_) {
      errorMessage = 'Signup failed. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _continueWithExistingParent({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        errorMessage = 'Could not verify this guardian account.';
        return false;
      }

      final parentInfo = await _userService.fetchParentAccount(user.uid);

      pendingUid = user.uid;
      _isExistingParentSession = true;
      _draft = SignupDraftModel(
        email: email,
        parentName: parentInfo?.parentName ?? '',
        relationshipToChild: parentInfo?.relationshipToChild ?? '',
      );

      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _friendlyExistingAccountError(e.code);
      return false;
    } catch (_) {
      errorMessage = 'Could not continue with this guardian account.';
      return false;
    }
  }

  Future<bool> completeSignup() async {
    errorMessage = null;
    _setLoading(true);

    try {
      final currentUser = _authService.currentUser;
      final uid = currentUser?.uid ?? pendingUid;

      if (uid == null) {
        errorMessage = 'Signup session expired. Please start again.';
        return false;
      }

      final birthDate = _draft.childBirthDate;
      if (birthDate == null) {
        errorMessage = 'Child birth date is required.';
        return false;
      }

      final childNameAlreadyExists = await _userService.childNameExists(
        userId: uid,
        childName: _draft.childName,
      );
      if (childNameAlreadyExists) {
        errorMessage =
            'A child with this name already exists in this guardian account.';
        return false;
      }

      final appUser = AppUserModel(userId: uid, email: _draft.email);

      final profile = ProfileModel(
        profileId: _userService.createProfileId(),
        userId: uid,
        email: _draft.email,
        progressId: '',
        birthDate: birthDate,
        categoryId: '',
        courseNo: '',
        parentName: _draft.parentName,
        relationshipToChild: _draft.relationshipToChild,
        childName: _draft.childName,
      );

      await _userService.createUserAndProfile(user: appUser, profile: profile);
      await _authService.updateCurrentUserDisplayName(_draft.parentName);

      pendingUid = null;
      _isExistingParentSession = false;
      return true;
    } catch (_) {
      errorMessage = 'Could not save profile data. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cancelPendingSignup() async {
    _setLoading(true);

    try {
      final currentUser = _authService.currentUser;

      if (pendingUid != null &&
          currentUser != null &&
          currentUser.uid == pendingUid &&
          !_isExistingParentSession) {
        await currentUser.delete();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Pending signup cleanup error: ${e.code}');
    } catch (e) {
      debugPrint('Pending signup cleanup error: $e');
    } finally {
      try {
        await _authService.signOut();
      } catch (_) {}

      _draft = SignupDraftModel();
      pendingUid = null;
      _isExistingParentSession = false;
      errorMessage = null;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    errorMessage = null;
    _setLoading(true);

    try {
      final credential = await _authService.signInWithEmailPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        try {
          await _userService.ensureProfileAssetsForUser(user.uid);
        } catch (e) {
          debugPrint('Profile backfill after login failed: $e');
        }
      }

      errorMessage = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _friendlyLoginError(e.code);
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Login failed. Please try again.';
      isLoading = false;
      notifyListeners();
      return false;
    } finally {
      if (isLoading) {
        _setLoading(false);
      }
    }
  }

  Future<void> signOut() => _authService.signOut();

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  String _friendlySignupError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'That email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-up is not enabled in Firebase.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Signup error: $code';
    }
  }

  String _friendlyExistingAccountError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'That email already exists. Enter the correct password to add another child.';
      case 'user-disabled':
        return 'This guardian account has been disabled.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Could not verify this guardian account.';
    }
  }

  String _friendlyLoginError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account was found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password login is not enabled in Firebase.';
      default:
        return 'Incorrect email or password.';
    }
  }
}
