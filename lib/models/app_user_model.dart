class AppUserModel {
  final String userId;
  final String email;
  final DateTime? createdAt;

  AppUserModel({required this.userId, required this.email, this.createdAt});

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    return AppUserModel(
      userId: map['userId'] ?? '',
      email: map['email'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : null,
    );
  }
}
