class ProfileModel {
  final String profileId;
  final String userId;
  final String progressId;
  final DateTime birthDate;
  final String categoryId;
  final String courseNo;

  // App-specific fields
  final String parentName;
  final String relationshipToChild;
  final String childName;

  ProfileModel({
    required this.profileId,
    required this.userId,
    required this.progressId,
    required this.birthDate,
    required this.categoryId,
    required this.courseNo,
    required this.parentName,
    required this.relationshipToChild,
    required this.childName,
  });

  int get age => _calculateAge(birthDate);

  static int _calculateAge(DateTime birthDate) {
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
    return {
      'profileId': profileId,
      'userId': userId,
      'progressId': progressId,
      'birthDate': birthDate.toIso8601String(),
      'age': age, // derived from birthDate
      'categoryId': categoryId,
      'courseNo': courseNo,
      'parentName': parentName,
      'relationshipToChild': relationshipToChild,
      'childName': childName,
    };
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    final birthDate =
        DateTime.tryParse(map['birthDate'] ?? '') ?? DateTime.now();

    return ProfileModel(
      profileId: map['profileId'] ?? '',
      userId: map['userId'] ?? '',
      progressId: map['progressId'] ?? '',
      birthDate: birthDate,
      categoryId: map['categoryId'] ?? '',
      courseNo: map['courseNo'] ?? '',
      parentName: map['parentName'] ?? '',
      relationshipToChild: map['relationshipToChild'] ?? '',
      childName: map['childName'] ?? '',
    );
  }
}
