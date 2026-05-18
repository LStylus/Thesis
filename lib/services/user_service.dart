import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user_model.dart';
import '../models/profile_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('profiles');

  String createProfileId() => _profiles.doc().id;

  Future<ParentAccountInfo?> fetchParentAccount(String uid) async {
    final userDoc = await _users.doc(uid).get();
    final userData = userDoc.data();

    if (userData != null) {
      final parentName = _stringValue(userData['parentName']);
      if (parentName.isNotEmpty) {
        return ParentAccountInfo(
          userId: uid,
          email: _stringValue(userData['email']),
          parentName: parentName,
          relationshipToChild: _stringValue(userData['relationshipToChild']),
        );
      }
    }

    final legacyProfileDoc = await _profiles.doc(uid).get();
    final legacyProfileData = legacyProfileDoc.data();
    if (legacyProfileData == null) return null;

    final parentName = _stringValue(legacyProfileData['parentName']);
    if (parentName.isEmpty) return null;

    return ParentAccountInfo(
      userId: uid,
      email: _stringValue(legacyProfileData['email']),
      parentName: parentName,
      relationshipToChild: _stringValue(
        legacyProfileData['relationshipToChild'],
      ),
    );
  }

  Future<void> createUserAndProfile({
    required AppUserModel user,
    required ProfileModel profile,
  }) async {
    final userRef = _users.doc(user.userId);
    final userDoc = await userRef.get();
    final existingUserData = userDoc.data();
    final legacyProfileId = _stringValue(existingUserData?['profileId']);
    final childProfileIds = <String>[
      if (legacyProfileId.isNotEmpty && legacyProfileId != profile.profileId)
        legacyProfileId,
      profile.profileId,
    ];
    final hasChildCount = existingUserData?['childCount'] != null;
    final childCountValue = hasChildCount
        ? FieldValue.increment(1)
        : childProfileIds.length;

    final batch = _firestore.batch();
    final profileData = profile.toMap();

    batch.set(userRef, {
      ...user.toMap(),
      'role': 'parent',
      'parentName': profile.parentName,
      'relationshipToChild': profile.relationshipToChild,
      'activeProfileId': profile.profileId,
      'activeChildName': profile.childName,
      'activeChildBirthDate': Timestamp.fromDate(profile.birthDate),
      'activeChildAge': profile.age,
      'childProfileIds': FieldValue.arrayUnion(childProfileIds),
      'childCount': childCountValue,
      'profileComplete': true,
      if (!userDoc.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(_profiles.doc(profile.profileId), {
      ...profileData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(
      userRef.collection('children').doc(profile.profileId),
      {
        ...profileData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Stream<ProfileModel?> streamActiveProfileByUserId(String uid) {
    return _users.doc(uid).snapshots().asyncExpand((userDoc) {
      final userData = userDoc.data();
      final activeProfileId = _stringValue(userData?['activeProfileId']);
      final legacyProfileId = _stringValue(userData?['profileId']);
      final profileId = activeProfileId.isNotEmpty
          ? activeProfileId
          : legacyProfileId.isNotEmpty
          ? legacyProfileId
          : uid;

      return _profiles.doc(profileId).snapshots().map((profileDoc) {
        if (!profileDoc.exists || profileDoc.data() == null) return null;
        return ProfileModel.fromMap(profileDoc.data()!);
      });
    });
  }

  static String _stringValue(Object? value) {
    if (value == null) return '';
    return value.toString();
  }
}

class ParentAccountInfo {
  final String userId;
  final String email;
  final String parentName;
  final String relationshipToChild;

  const ParentAccountInfo({
    required this.userId,
    required this.email,
    required this.parentName,
    required this.relationshipToChild,
  });
}
