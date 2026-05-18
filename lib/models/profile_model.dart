import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileModel {
  final String profileId;
  final String userId;
  final String email;
  final String progressId;
  final DateTime birthDate;
  final String categoryId;
  final String courseNo;

  final String parentName;
  final String relationshipToChild;
  final String childName;
  final String profileAssetPath;

  ProfileModel({
    required this.profileId,
    required this.userId,
    this.email = '',
    required this.progressId,
    required this.birthDate,
    required this.categoryId,
    required this.courseNo,
    required this.parentName,
    required this.relationshipToChild,
    required this.childName,
    this.profileAssetPath = '',
  });

  int get age => calculateAge(birthDate);

  ProfileModel copyWith({
    String? profileId,
    String? userId,
    String? email,
    String? progressId,
    DateTime? birthDate,
    String? categoryId,
    String? courseNo,
    String? parentName,
    String? relationshipToChild,
    String? childName,
    String? profileAssetPath,
  }) {
    return ProfileModel(
      profileId: profileId ?? this.profileId,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      progressId: progressId ?? this.progressId,
      birthDate: birthDate ?? this.birthDate,
      categoryId: categoryId ?? this.categoryId,
      courseNo: courseNo ?? this.courseNo,
      parentName: parentName ?? this.parentName,
      relationshipToChild: relationshipToChild ?? this.relationshipToChild,
      childName: childName ?? this.childName,
      profileAssetPath: profileAssetPath ?? this.profileAssetPath,
    );
  }

  static int calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;

    final hasHadBirthdayThisYear =
        (today.month > birthDate.month) ||
        (today.month == birthDate.month && today.day >= birthDate.day);

    if (!hasHadBirthdayThisYear) {
      age--;
    }

    return age;
  }

  Map<String, dynamic> toMap() {
    final childAge = age;

    return {
      'profileId': profileId,
      'userId': userId,
      'uid': userId,
      'email': email,
      'progressId': progressId,
      'birthDate': Timestamp.fromDate(birthDate),
      'childBirthDate': Timestamp.fromDate(birthDate),
      'age': childAge,
      'childAge': childAge,
      'categoryId': categoryId,
      'courseNo': courseNo,
      'parentName': parentName,
      'relationshipToChild': relationshipToChild,
      'childName': childName,
      'childNameNormalized': childName.trim().toLowerCase(),
      'profileAssetPath': profileAssetPath,
      'profileComplete': true,
    };
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    final parsedBirthDate = _parseDate(
      map['birthDate'] ?? map['childBirthDate'],
    );

    return ProfileModel(
      profileId: _stringValue(map['profileId'] ?? map['uid'] ?? map['userId']),
      userId: _stringValue(map['userId'] ?? map['uid'] ?? map['profileId']),
      email: _stringValue(map['email']),
      progressId: _stringValue(map['progressId']),
      birthDate: parsedBirthDate,
      categoryId: _stringValue(map['categoryId']),
      courseNo: _stringValue(map['courseNo']),
      parentName: _stringValue(map['parentName']),
      relationshipToChild: _stringValue(map['relationshipToChild']),
      childName: _stringValue(map['childName']),
      profileAssetPath: _stringValue(map['profileAssetPath']),
    );
  }

  static DateTime _parseDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static String _stringValue(Object? value) {
    if (value == null) return '';
    return value.toString();
  }
}
