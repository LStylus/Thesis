class SignupDraftModel {
  final String email;
  final String password;
  final String parentName;
  final String relationshipToChild;
  final String childName;
  final DateTime? childBirthDate;

  SignupDraftModel({
    this.email = '',
    this.password = '',
    this.parentName = '',
    this.relationshipToChild = '',
    this.childName = '',
    this.childBirthDate,
  });

  SignupDraftModel copyWith({
    String? email,
    String? password,
    String? parentName,
    String? relationshipToChild,
    String? childName,
    DateTime? childBirthDate,
  }) {
    return SignupDraftModel(
      email: email ?? this.email,
      password: password ?? this.password,
      parentName: parentName ?? this.parentName,
      relationshipToChild: relationshipToChild ?? this.relationshipToChild,
      childName: childName ?? this.childName,
      childBirthDate: childBirthDate ?? this.childBirthDate,
    );
  }
}
