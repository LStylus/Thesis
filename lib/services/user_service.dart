import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/profile_assets.dart';
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
          profileAssetPath: _stringValue(userData['parentProfileAssetPath']),
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
      profileAssetPath: _stringValue(legacyProfileData['parentProfileAssetPath']),
    );
  }

  Stream<ParentAccountInfo?> streamParentAccount(String uid) {
    return _users.doc(uid).snapshots().map((userDoc) {
      final userData = userDoc.data();
      if (userData == null) return null;

      final parentName = _stringValue(userData['parentName']);
      if (parentName.isEmpty) return null;

      return ParentAccountInfo(
        userId: uid,
        email: _stringValue(userData['email']),
        parentName: parentName,
        relationshipToChild: _stringValue(userData['relationshipToChild']),
        profileAssetPath: _stringValue(userData['parentProfileAssetPath']),
      );
    });
  }

  Future<void> createUserAndProfile({
    required AppUserModel user,
    required ProfileModel profile,
  }) async {
    final userRef = _users.doc(user.userId);
    final userDoc = await userRef.get();
    final existingUserData = userDoc.data();
    final legacyProfileId = _stringValue(existingUserData?['profileId']);
    final childProfileIds = <String>{
      ..._stringList(existingUserData?['childProfileIds']),
      if (legacyProfileId.isNotEmpty && legacyProfileId != profile.profileId)
        legacyProfileId,
      profile.profileId,
    }.toList();
    final hasChildCount = existingUserData?['childCount'] != null;
    final childCountValue = hasChildCount
        ? FieldValue.increment(1)
        : childProfileIds.length;
    final usedAssets = await _collectUsedProfileAssets(userRef, existingUserData);
    final parentProfileAssetPath =
        _stringValue(existingUserData?['parentProfileAssetPath']).isNotEmpty
        ? _stringValue(existingUserData?['parentProfileAssetPath'])
        : ProfileAssets.pickUnique(usedAssets, random: Random());
    usedAssets.add(parentProfileAssetPath);
    final enrichedProfile = profile.copyWith(
      profileAssetPath: profile.profileAssetPath.isNotEmpty
          ? profile.profileAssetPath
          : ProfileAssets.pickUnique(usedAssets, random: Random()),
    );
    usedAssets.add(enrichedProfile.profileAssetPath);

    final batch = _firestore.batch();
    final profileData = enrichedProfile.toMap();

    batch.set(userRef, {
      ...user.toMap(),
      'role': 'parent',
      'parentName': enrichedProfile.parentName,
      'relationshipToChild': enrichedProfile.relationshipToChild,
      'parentProfileAssetPath': parentProfileAssetPath,
      'activeProfileId': enrichedProfile.profileId,
      'activeChildName': enrichedProfile.childName,
      'activeChildBirthDate': Timestamp.fromDate(enrichedProfile.birthDate),
      'activeChildAge': enrichedProfile.age,
      'activeChildProfileAssetPath': enrichedProfile.profileAssetPath,
      'childProfileIds': FieldValue.arrayUnion(childProfileIds),
      'childCount': childCountValue,
      'usedProfileAssets': usedAssets.toList(),
      'profileComplete': true,
      if (!userDoc.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(_profiles.doc(enrichedProfile.profileId), {
      ...profileData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(
      userRef.collection('children').doc(enrichedProfile.profileId),
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

  Stream<List<ProfileModel>> streamChildProfilesByUserId(String uid) {
    final userRef = _users.doc(uid);
    return userRef.snapshots().asyncExpand((userDoc) {
      final userData = userDoc.data();
      final activeProfileId = _stringValue(userData?['activeProfileId']);
      final expectedIds = _profileIdsForUserData(userData);

      return userRef.collection('children').snapshots().asyncMap((snapshot) async {
        final profiles = snapshot.docs
            .map((doc) => ProfileModel.fromMap(doc.data()))
            .toList();
        final seenIds = profiles.map((profile) => profile.profileId).toSet();
        final missingIds = expectedIds
            .where((profileId) => !seenIds.contains(profileId))
            .toList();

        if (missingIds.isNotEmpty) {
          final missingProfiles = await _fetchProfilesByIds(missingIds);
          profiles.addAll(
            missingProfiles.where(
              (profile) => !seenIds.contains(profile.profileId),
            ),
          );
        }

        profiles.sort((left, right) {
          final leftRank = left.profileId == activeProfileId ? 0 : 1;
          final rightRank = right.profileId == activeProfileId ? 0 : 1;
          if (leftRank != rightRank) return leftRank.compareTo(rightRank);
          return left.childName.toLowerCase().compareTo(
            right.childName.toLowerCase(),
          );
        });

        return profiles;
      });
    });
  }

  Future<void> setActiveProfile({
    required String userId,
    required ProfileModel profile,
  }) {
    return _users.doc(userId).set({
      'activeProfileId': profile.profileId,
      'activeChildName': profile.childName,
      'activeChildBirthDate': Timestamp.fromDate(profile.birthDate),
      'activeChildAge': profile.age,
      'activeChildProfileAssetPath': profile.profileAssetPath,
      'childProfileIds': FieldValue.arrayUnion([profile.profileId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> ensureProfileAssetsForUser(String uid) async {
    final userRef = _users.doc(uid);
    final userDoc = await userRef.get();
    final userData = userDoc.data();
    if (userData == null) return;

    final childSnapshot = await userRef.collection('children').get();
    final childDocIds = childSnapshot.docs.map((doc) => doc.id).toSet();
    final profilesById = <String, ProfileModel>{};
    for (final doc in childSnapshot.docs) {
      final profile = ProfileModel.fromMap(doc.data());
      profilesById[profile.profileId] = profile;
    }

    final missingProfileIds = _profileIdsForUserData(userData)
        .where((profileId) => !profilesById.containsKey(profileId))
        .toList();
    if (missingProfileIds.isNotEmpty) {
      final missingProfiles = await _fetchProfilesByIds(missingProfileIds);
      for (final profile in missingProfiles) {
        profilesById[profile.profileId] = profile;
      }
    }

    final usedAssets = <String>{
      ..._stringList(userData['usedProfileAssets']),
    };
    final batch = _firestore.batch();
    var hasWrites = false;

    final existingParentAssetPath = _stringValue(userData['parentProfileAssetPath']);
    final parentProfileAssetPath = existingParentAssetPath.isNotEmpty
        ? existingParentAssetPath
        : ProfileAssets.pickUnique(usedAssets, random: Random());
    usedAssets.add(parentProfileAssetPath);
    if (existingParentAssetPath != parentProfileAssetPath) {
      hasWrites = true;
    }

    final assignedAssets = <String>{parentProfileAssetPath};
    String? activeChildProfileAssetPath;
    final orderedProfiles = profilesById.values.toList()
      ..sort(
        (left, right) => left.childName.toLowerCase().compareTo(
          right.childName.toLowerCase(),
        ),
      );

    for (final profile in orderedProfiles) {
      var resolvedAssetPath = profile.profileAssetPath;
      if (resolvedAssetPath.isEmpty || assignedAssets.contains(resolvedAssetPath)) {
        resolvedAssetPath = ProfileAssets.pickUnique(
          assignedAssets,
          random: Random(),
        );
      }

      assignedAssets.add(resolvedAssetPath);

      final needsUpdate =
          resolvedAssetPath != profile.profileAssetPath ||
          !childDocIds.contains(profile.profileId);
      if (needsUpdate) {
        hasWrites = true;
        final updatedProfile = profile.copyWith(
          profileAssetPath: resolvedAssetPath,
        );
        batch.set(_profiles.doc(profile.profileId), {
          'profileAssetPath': resolvedAssetPath,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        batch.set(
          userRef.collection('children').doc(profile.profileId),
          {
            ...updatedProfile.toMap(),
            if (!childDocIds.contains(profile.profileId))
              'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      if (profile.profileId == _stringValue(userData['activeProfileId'])) {
        activeChildProfileAssetPath = resolvedAssetPath;
      }
    }

    final finalUsedAssets = assignedAssets.toList();
    final currentUsedAssets = _stringList(userData['usedProfileAssets']);
    final currentActiveAsset = _stringValue(userData['activeChildProfileAssetPath']);
    if (!_listsMatchAsSets(currentUsedAssets, finalUsedAssets) ||
        currentActiveAsset != activeChildProfileAssetPath ||
        existingParentAssetPath != parentProfileAssetPath) {
      hasWrites = true;
    }

    if (!hasWrites) return;

    batch.set(userRef, {
      'parentProfileAssetPath': parentProfileAssetPath,
      'usedProfileAssets': finalUsedAssets,
      if (activeChildProfileAssetPath != null)
        'activeChildProfileAssetPath': activeChildProfileAssetPath,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<bool> childNameExists({
    required String userId,
    required String childName,
  }) async {
    final normalizedName = _normalizeName(childName);
    if (normalizedName.isEmpty) return false;

    final userRef = _users.doc(userId);
    final userDoc = await userRef.get();
    final userData = userDoc.data();
    final childSnapshot = await userRef.collection('children').get();

    for (final doc in childSnapshot.docs) {
      final data = doc.data();
      final normalized = _stringValue(data['childNameNormalized']).isNotEmpty
          ? _stringValue(data['childNameNormalized'])
          : _normalizeName(_stringValue(data['childName']));
      if (normalized == normalizedName) return true;
    }

    final childDocIds = childSnapshot.docs.map((doc) => doc.id).toSet();
    final missingProfileIds = _profileIdsForUserData(userData).where(
      (profileId) => !childDocIds.contains(profileId),
    );
    final missingProfiles = await _fetchProfilesByIds(missingProfileIds);
    for (final profile in missingProfiles) {
      if (_normalizeName(profile.childName) == normalizedName) return true;
    }

    return false;
  }

  static String _stringValue(Object? value) {
    if (value == null) return '';
    return value.toString();
  }

  static List<String> _stringList(Object? value) {
    if (value is Iterable) {
      return value
          .map(_stringValue)
          .where((entry) => entry.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static bool _listsMatchAsSets(List<String> left, List<String> right) {
    final leftSet = left.toSet();
    final rightSet = right.toSet();
    return leftSet.length == rightSet.length && leftSet.containsAll(rightSet);
  }

  static String _normalizeName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  List<String> _profileIdsForUserData(Map<String, dynamic>? userData) {
    final activeProfileId = _stringValue(userData?['activeProfileId']);
    final legacyProfileId = _stringValue(userData?['profileId']);
    return <String>{
      ..._stringList(userData?['childProfileIds']),
      if (activeProfileId.isNotEmpty) activeProfileId,
      if (legacyProfileId.isNotEmpty) legacyProfileId,
    }.toList();
  }

  Future<List<ProfileModel>> _fetchProfilesByIds(Iterable<String> profileIds) async {
    final ids = profileIds.where((profileId) => profileId.isNotEmpty).toList();
    if (ids.isEmpty) return const [];

    final docs = await Future.wait(ids.map((profileId) => _profiles.doc(profileId).get()));
    final profilesById = <String, ProfileModel>{};
    for (final doc in docs) {
      final data = doc.data();
      if (data == null) continue;
      final profile = ProfileModel.fromMap(data);
      profilesById[profile.profileId] = profile;
    }

    return ids
        .map((profileId) => profilesById[profileId])
        .whereType<ProfileModel>()
        .toList();
  }

  Future<Set<String>> _collectUsedProfileAssets(
    DocumentReference<Map<String, dynamic>> userRef,
    Map<String, dynamic>? userData,
  ) async {
    final usedAssets = <String>{
      ..._stringList(userData?['usedProfileAssets']),
    };
    final directPaths = [
      _stringValue(userData?['parentProfileAssetPath']),
      _stringValue(userData?['activeChildProfileAssetPath']),
    ];
    usedAssets.addAll(directPaths.where((path) => path.isNotEmpty));

    final childSnapshot = await userRef.collection('children').get();
    for (final doc in childSnapshot.docs) {
      final path = _stringValue(doc.data()['profileAssetPath']);
      if (path.isNotEmpty) {
        usedAssets.add(path);
      }
    }

    final missingProfileIds = _profileIdsForUserData(userData).where((profileId) {
      return !childSnapshot.docs.any((doc) => doc.id == profileId);
    });
    final missingProfiles = await _fetchProfilesByIds(missingProfileIds);
    for (final profile in missingProfiles) {
      if (profile.profileAssetPath.isNotEmpty) {
        usedAssets.add(profile.profileAssetPath);
      }
    }

    return usedAssets;
  }
}

class ParentAccountInfo {
  final String userId;
  final String email;
  final String parentName;
  final String relationshipToChild;
  final String profileAssetPath;

  const ParentAccountInfo({
    required this.userId,
    required this.email,
    required this.parentName,
    required this.relationshipToChild,
    this.profileAssetPath = '',
  });
}
