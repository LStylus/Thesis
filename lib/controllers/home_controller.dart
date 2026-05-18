import '../models/learning_report_model.dart';
import '../models/profile_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class HomeController {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  Stream<ProfileModel?> currentUserProfileStream() {
    final user = _authService.currentUser;
    if (user == null) {
      return Stream.value(null);
    }
    return _userService.streamActiveProfileByUserId(user.uid);
  }

  Stream<List<ProfileModel>> childProfilesStream() {
    final user = _authService.currentUser;
    if (user == null) {
      return Stream.value(const []);
    }
    return _userService.streamChildProfilesByUserId(user.uid);
  }

  Stream<LearningReportData> learningReportStream(ProfileModel profile) {
    final user = _authService.currentUser;
    if (user == null) {
      return Stream.value(LearningReportData.empty);
    }
    return _userService.streamLearningReport(
      userId: user.uid,
      profileId: profile.profileId,
    );
  }

  Stream<ParentAccountInfo?> parentAccountStream() {
    final user = _authService.currentUser;
    if (user == null) {
      return Stream.value(null);
    }
    return _userService.streamParentAccount(user.uid);
  }

  Future<void> switchActiveProfile(ProfileModel profile) async {
    final user = _authService.currentUser;
    if (user == null) return;
    await _userService.setActiveProfile(userId: user.uid, profile: profile);
  }

  Future<ProfileModel?> deleteChildProfile(ProfileModel profile) async {
    final user = _authService.currentUser;
    if (user == null) return null;
    return _userService.deleteChildProfile(userId: user.uid, profile: profile);
  }

  Future<void> ensureCurrentUserProfileAssets() async {
    final user = _authService.currentUser;
    if (user == null) return;
    await _userService.ensureProfileAssetsForUser(user.uid);
  }

  Future<void> saveGameplayLevelScore({
    required ProfileModel profile,
    required int levelIndex,
    required int accuracy,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return;
    await _userService.saveGameplayLevelScore(
      userId: user.uid,
      profileId: profile.profileId,
      activityIndex: 0,
      levelIndex: levelIndex,
      accuracy: accuracy,
    );
  }
}
