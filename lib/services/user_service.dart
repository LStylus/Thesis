import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user_model.dart';
import '../models/profile_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('profiles');

  Future<void> createUserAndProfile({
    required AppUserModel user,
    required ProfileModel profile,
  }) async {
    final batch = _firestore.batch();

    batch.set(_users.doc(user.userId), {
      ...user.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(_profiles.doc(profile.userId), {
      ...profile.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> deleteUserProfile(String uid) async {
    await _profiles.doc(uid).delete();
  }

  Stream<ProfileModel?> streamProfileByUserId(String uid) {
    return _profiles.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ProfileModel.fromMap(doc.data()!);
    });
  }

  Future<ProfileModel?> getProfileByUserId(String uid) async {
    final doc = await _profiles.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return ProfileModel.fromMap(doc.data()!);
  }
}
