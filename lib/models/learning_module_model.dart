/// Models for the dynamic modules service (`POST /module`, port 8002).
///
/// Mirrors `dynamic_modules_service/api/schemas.py` — the personalized
/// practice module built from the child's age + detected processes.
library;

class PracticeItemModel {
  const PracticeItemModel({
    required this.text,
    required this.targetSound,
    required this.position,
  });

  final String text;
  final String targetSound;
  final String position;

  factory PracticeItemModel.fromMap(Map<String, dynamic> map) {
    return PracticeItemModel(
      text: map['text']?.toString() ?? '',
      targetSound: map['target_sound']?.toString() ?? '',
      position: map['position']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'text': text,
    'target_sound': targetSound,
    'position': position,
  };
}

class ModuleLevelModel {
  const ModuleLevelModel({required this.level, required this.items});

  final String level;
  final List<PracticeItemModel> items;

  factory ModuleLevelModel.fromMap(Map<String, dynamic> map) {
    return ModuleLevelModel(
      level: map['level']?.toString() ?? '',
      items: (map['items'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                PracticeItemModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'level': level,
    'items': items.map((item) => item.toMap()).toList(),
  };
}

class LearningModuleModel {
  const LearningModuleModel({
    required this.moduleId,
    required this.focusSounds,
    required this.focusProcesses,
    required this.outlineId,
    required this.outlineTitle,
    required this.levels,
    required this.rationale,
    required this.generatedBy,
    this.warning,
  });

  final String moduleId;
  final List<String> focusSounds;
  final List<String> focusProcesses;
  final String outlineId;
  final String outlineTitle;
  final List<ModuleLevelModel> levels;
  final String rationale;
  final String generatedBy;
  final String? warning;

  factory LearningModuleModel.fromMap(Map<String, dynamic> map) {
    return LearningModuleModel(
      moduleId: map['module_id']?.toString() ?? '',
      focusSounds: (map['focus_sounds'] as List? ?? const [])
          .map((sound) => sound.toString())
          .toList(),
      focusProcesses: (map['focus_processes'] as List? ?? const [])
          .map((process) => process.toString())
          .toList(),
      outlineId: map['outline_id']?.toString() ?? '',
      outlineTitle: map['outline_title']?.toString() ?? '',
      levels: (map['levels'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (level) =>
                ModuleLevelModel.fromMap(Map<String, dynamic>.from(level)),
          )
          .toList(),
      rationale: map['rationale']?.toString() ?? '',
      generatedBy: map['generated_by']?.toString() ?? '',
      warning: map['warning']?.toString(),
    );
  }

  /// Convenience: all practice items across every level, in order.
  List<PracticeItemModel> get allItems =>
      levels.expand((level) => level.items).toList();

  /// Convenience: items of one level (e.g. 'word').
  List<PracticeItemModel> itemsFor(String levelName) => levels
      .where((level) => level.level == levelName)
      .expand((level) => level.items)
      .toList();

  Map<String, dynamic> toMap() => {
    'module_id': moduleId,
    'focus_sounds': focusSounds,
    'focus_processes': focusProcesses,
    'outline_id': outlineId,
    'outline_title': outlineTitle,
    'levels': levels.map((level) => level.toMap()).toList(),
    'rationale': rationale,
    'generated_by': generatedBy,
    if (warning != null) 'warning': warning,
  };
}
