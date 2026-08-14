import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/learning_module_model.dart';

/// Client for the Dynamic Modules Service (`POST /module`, port 8002).
///
/// Sends the child's age + detected phonological processes as form fields
/// (mirroring the phoneme service's multipart style) and receives a
/// personalized practice module (syllables → words → phrases → sentences).
class DynamicModulesService {
  DynamicModulesService({String? baseUrl})
    : baseUrl = baseUrl ?? _defaultBaseUrl;

  final String baseUrl;

  /// On Android emulator, 10.0.2.2 maps to the host machine's localhost.
  static String get _defaultBaseUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:8002';
    return 'http://127.0.0.1:8002';
  }

  Uri get _moduleUri {
    return Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/module');
  }

  /// Build a practice module from the child's age and detected processes.
  ///
  /// [processes] entries carry the phoneme service's detected process shape:
  /// `{process, position, detail}` — `target_sound` is optional (the backend
  /// parses it from the detail string when absent).
  Future<LearningModuleModel> buildModule({
    required int age,
    required List<Map<String, dynamic>> processes,
  }) async {
    debugPrint(
      '[modules-api] module_request age=$age processes=${processes.length} '
      'uri=$_moduleUri',
    );

    try {
      final response = await http
          .post(
            _moduleUri,
            body: {'age': age.toString(), 'processes': jsonEncode(processes)},
          )
          .timeout(const Duration(minutes: 1));

      Map<String, dynamic>? decoded;
      try {
        if (response.body.isNotEmpty) {
          decoded = jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (_) {
        // fall through to status handling
      }

      if (response.statusCode != 200) {
        final message = _extractError(decoded, response.statusCode);
        throw ModuleRequestException(message);
      }

      final module = LearningModuleModel.fromMap(decoded ?? const {});
      debugPrint(
        '[modules-api] module_success module_id=${module.moduleId} '
        'outline=${module.outlineId} generated_by=${module.generatedBy} '
        'levels=${module.levels.length}',
      );
      return module;
    } on TimeoutException {
      throw ModuleRequestException('Module service request timed out.');
    } on SocketException {
      throw ModuleRequestException(
        'Could not connect to the module service at $baseUrl.',
      );
    }
  }

  String _extractError(Map<String, dynamic>? decoded, int statusCode) {
    if (decoded == null) {
      return 'Module service returned HTTP $statusCode.';
    }
    final error = decoded['error']?.toString();
    if (error != null) {
      final detail = decoded['detail']?.toString();
      return detail != null && detail.isNotEmpty ? '$error: $detail' : error;
    }
    final detail = decoded['detail'];
    if (detail is List && detail.isNotEmpty) {
      return detail.map((d) => d['msg']?.toString() ?? '').join('; ');
    }
    return 'Module service returned HTTP $statusCode.';
  }
}

class ModuleRequestException implements Exception {
  ModuleRequestException(this.message);

  final String message;

  @override
  String toString() => 'ModuleRequestException: $message';
}
