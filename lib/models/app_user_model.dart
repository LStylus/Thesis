import 'package:cloud_firestore/cloud_firestore.dart';

class AppUserModel {
  final String userId;
  final String email;
  final DateTime? createdAt;

  AppUserModel({required this.userId, required this.email, this.createdAt});

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'uid': userId,
      'email': email,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    return AppUserModel(
      userId: (map['userId'] ?? map['uid'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      createdAt: _parseDate(map['createdAt']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
