class SignupDraftModel {
  final String email;
  final String parentName;
  final String relationshipToChild;
  final String childName;
  final DateTime? childBirthDate;

  SignupDraftModel({
    this.email = '',
    this.parentName = '',
    this.relationshipToChild = '',
    this.childName = '',
    this.childBirthDate,
  });

  SignupDraftModel copyWith({
    String? email,
    String? parentName,
    String? relationshipToChild,
    String? childName,
    DateTime? childBirthDate,
  }) {
    return SignupDraftModel(
      email: email ?? this.email,
      parentName: parentName ?? this.parentName,
      relationshipToChild: relationshipToChild ?? this.relationshipToChild,
      childName: childName ?? this.childName,
      childBirthDate: childBirthDate ?? this.childBirthDate,
    );
  }
}
