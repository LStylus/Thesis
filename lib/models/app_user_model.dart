class AppUserModel {
  final String userId;
  final String username;
  final DateTime? createdAt;

  AppUserModel({required this.userId, required this.username, this.createdAt});

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    return AppUserModel(
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : null,
    );
  }
}
