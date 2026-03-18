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

  void clearDraft() {
    _draft = SignupDraftModel();
    pendingUid = null;
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> registerAccountStep1({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    errorMessage = null;
    notifyListeners();

    try {
      final cleanEmail = email.trim();

      final credential = await _authService.signUpWithEmailPassword(
        email: cleanEmail,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('User creation failed.');
      }

      pendingUid = user.uid;

      _draft = _draft.copyWith(email: cleanEmail, password: password);

      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _friendlySignupError(e.code);
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'Signup failed. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> completeSignup() async {
    _setLoading(true);
    errorMessage = null;
    notifyListeners();

    try {
      final currentUser = _authService.currentUser;
      final uid = currentUser?.uid ?? pendingUid;

      if (uid == null) {
        errorMessage = 'Signup session expired. Please start again.';
        notifyListeners();
        return false;
      }

      final birthDate = _draft.childBirthDate;
      if (birthDate == null) {
        errorMessage = 'Child birth date is required.';
        notifyListeners();
        return false;
      }

      final appUser = AppUserModel(
        userId: uid,
        username: _draft.email,
        createdAt: DateTime.now(),
      );

      final profile = ProfileModel(
        profileId: uid,
        userId: uid,
        progressId: '',
        birthDate: birthDate,
        categoryId: '',
        courseNo: '',
        parentName: _draft.parentName,
        relationshipToChild: _draft.relationshipToChild,
        childName: _draft.childName,
      );

      await _userService.createUserAndProfile(user: appUser, profile: profile);

      // No longer a pending signup once saved.
      pendingUid = null;

      return true;
    } catch (_) {
      errorMessage = 'Could not save profile data. Please try again.';
      notifyListeners();
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
          currentUser.uid == pendingUid) {
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
      errorMessage = null;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.signInWithEmailPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _friendlyLoginError(e.code);
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'Login failed. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
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
        return 'Login error: $code';
    }
  }
}
