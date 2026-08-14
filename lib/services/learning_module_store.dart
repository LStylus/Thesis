import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/learning_module_model.dart';

/// The persisted learning data: the last module request inputs (age +
/// detected processes) and the resulting module (null until a fetch
/// succeeds).  Keeping the inputs lets gameplay RETRY the fetch when the
/// module service was unavailable during screening.
class StoredLearningData {
  const StoredLearningData({this.age, this.processes = const [], this.module});

  final int? age;
  final List<Map<String, dynamic>> processes;
  final LearningModuleModel? module;

  bool get hasInputs => age != null && processes.isNotEmpty;
}

/// Persists the child's learning data between sessions as a JSON file in
/// the app documents directory — no extra dependencies.
class LearningModuleStore {
  static const String _fileName = 'voice_voyage_learning_module.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<StoredLearningData> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return const StoredLearningData();
      final decoded =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final findings = decoded['findings'] as Map<String, dynamic>? ?? const {};
      final rawModule = decoded['module'];
      return StoredLearningData(
        age: findings['age'] as int?,
        processes: (findings['processes'] as List? ?? const [])
            .whereType<Map>()
            .map((p) => Map<String, dynamic>.from(p))
            .toList(),
        module: rawModule is Map<String, dynamic>
            ? LearningModuleModel.fromMap(rawModule)
            : null,
      );
    } catch (error) {
      debugPrint('[modules-store] load_failed error=$error');
      return const StoredLearningData();
    }
  }

  Future<void> saveFindings({
    required int age,
    required List<Map<String, dynamic>> processes,
  }) async {
    try {
      final current = await load();
      await _write(
        findings: {'age': age, 'processes': processes},
        module: current.module,
      );
      debugPrint('[modules-store] findings_saved age=$age processes=${processes.length}');
    } catch (error) {
      debugPrint('[modules-store] findings_save_failed error=$error');
    }
  }

  Future<void> save(LearningModuleModel module) async {
    try {
      final current = await load();
      await _write(findings: current.age != null
          ? {'age': current.age, 'processes': current.processes}
          : null, module: module);
      debugPrint('[modules-store] saved module ${module.moduleId}');
    } catch (error) {
      debugPrint('[modules-store] save_failed error=$error');
    }
  }

  Future<void> _write({Map<String, dynamic>? findings, LearningModuleModel? module}) async {
    final file = await _file();
    await file.writeAsString(jsonEncode({
      if (findings != null) 'findings': findings,
      if (module != null) 'module': module.toMap(),
    }));
  }

  Future<void> clear() async {
    try {
      final file = await _file();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (error) {
      debugPrint('[modules-store] clear_failed error=$error');
    }
  }
}
