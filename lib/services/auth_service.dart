import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  // FUTURE GOOGLE SIGN-IN
  // ----------------------------------------------------------
  // Uncomment later after adding:
  // 1. google_sign_in package
  // 2. Google provider in Firebase Console
  //
  // import 'package:google_sign_in/google_sign_in.dart';
  //
  // Future<UserCredential> signInWithGoogle() async {
  //   final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  //   if (googleUser == null) {
  //     throw Exception('Google sign-in was cancelled.');
  //   }
  //
  //   final GoogleSignInAuthentication googleAuth =
  //       await googleUser.authentication;
  //
  //   final credential = GoogleAuthProvider.credential(
  //     accessToken: googleAuth.accessToken,
  //     idToken: googleAuth.idToken,
  //   );
  //
  //   return _auth.signInWithCredential(credential);
  // }
}
