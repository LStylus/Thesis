class TestingDefaults {
  static const authEmail = 'voicevoyage.test@example.com';
  static const authPassword = 'Test1234!';
  static const parentName = 'Test Parent';
  static const relationshipToChild = 'Guardian';
  static const childName = 'Test Child';
  static const screeningWordsPerAge = 3;

  static DateTime get childBirthDate {
    final today = DateTime.now();
    return DateTime(today.year - 6, today.month, today.day);
  }
}
