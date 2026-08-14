class SpeechProfileModel {
  final String primaryTarget;
  final String secondaryTarget;
  final List<String> reviewTargets;
  final List<String> targetPhonemes;
  final String wordPosition;
  final List<String> approvedWords;
  final double? averageAccuracy;
  final int validAttempts;
  final Map<String, int> evidenceCounts;

  const SpeechProfileModel({
    required this.primaryTarget,
    required this.secondaryTarget,
    required this.reviewTargets,
    required this.targetPhonemes,
    required this.wordPosition,
    required this.approvedWords,
    required this.averageAccuracy,
    required this.validAttempts,
    required this.evidenceCounts,
  });

  factory SpeechProfileModel.fromMap(Map<String, dynamic> map) {
    return SpeechProfileModel(
      primaryTarget: map['primaryTarget']?.toString() ?? '',
      secondaryTarget: map['secondaryTarget']?.toString() ?? '',
      reviewTargets: _stringList(map['reviewTargets']),
      targetPhonemes: _stringList(map['targetPhonemes']),
      wordPosition: map['wordPosition']?.toString() ?? '',
      approvedWords: _stringList(map['approvedWords']),
      averageAccuracy: (map['averageAccuracy'] as num?)?.toDouble(),
      validAttempts: (map['validAttempts'] as num?)?.toInt() ?? 0,
      evidenceCounts: {
        for (final entry in (map['evidenceCounts'] as Map? ?? const {}).entries)
          entry.key.toString(): (entry.value as num?)?.toInt() ?? 0,
      },
    );
  }

  Map<String, dynamic> toMap() => {
    'primaryTarget': primaryTarget,
    'secondaryTarget': secondaryTarget,
    'reviewTargets': reviewTargets,
    'targetPhonemes': targetPhonemes,
    'wordPosition': wordPosition,
    'approvedWords': approvedWords,
    'averageAccuracy': averageAccuracy,
    'validAttempts': validAttempts,
    'evidenceCounts': evidenceCounts,
  };

  static List<String> _stringList(Object? value) {
    return (value as List? ?? const [])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
