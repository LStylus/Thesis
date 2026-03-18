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
    return _userService.streamProfileByUserId(user.uid);
  }

  Future<void> signOut() => _authService.signOut();
}
