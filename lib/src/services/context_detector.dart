import 'dart:convert';
import 'dart:io';

import 'package:dfspec/src/models/feature_context.dart';
import 'package:dfspec/src/models/project_context.dart';

/// Servicio para detectar el contexto del proyecto y feature actual.
///
/// Utiliza los scripts bash para obtener información estructurada
/// y la convierte en modelos Dart tipados.
///
/// Ejemplo de uso:
/// ```dart
/// final detector = ContextDetector();
/// final context = await detector.detectFullContext();
/// print('Feature: ${context.feature.id}');
/// print('Status: ${context.feature.status}');
/// ```
class ContextDetector {
  /// Crea un detector de contexto.
  ///
  /// [scriptsPath] es la ruta a los scripts bash.
  /// Por defecto usa 'scripts/bash' relativo al directorio actual.
  ContextDetector({String? scriptsPath})
      : _scriptsPath = scriptsPath ?? 'scripts/bash';

  final String _scriptsPath;

  /// Detecta el contexto completo del proyecto.
  ///
  /// Ejecuta `detect-context.sh` y parsea el JSON resultante.
  /// Retorna [ProjectContext] con toda la información.
  ///
  /// Throws [ContextDetectionException] si hay error.
  Future<ProjectContext> detectFullContext({String? featureOverride}) async {
    final args = ['--json'];
    if (featureOverride != null) {
      args.add('--feature=$featureOverride');
    }

    final result = await _runScript('detect-context.sh', args);
    return ProjectContext.fromJson(result);
  }

  /// Detecta solo la feature actual.
  ///
  /// Más ligero que [detectFullContext] si solo necesitas
  /// información de la feature.
  Future<FeatureContext> detectCurrentFeature({String? featureOverride}) async {
    final context = await detectFullContext(featureOverride: featureOverride);
    return context.feature;
  }

  /// Verifica prerequisitos para un paso del flujo.
  ///
  /// [requireSpec] - Falla si no existe spec.md
  /// [requirePlan] - Falla si no existe plan.md
  /// [requireTasks] - Falla si no existe tasks.md
  ///
  /// Retorna [PrerequisitesResult] con paths y validación.
  Future<PrerequisitesResult> checkPrerequisites({
    bool requireSpec = false,
    bool requirePlan = false,
    bool requireTasks = false,
    String? featureOverride,
  }) async {
    final args = ['--json'];
    if (requireSpec) args.add('--require-spec');
    if (requirePlan) args.add('--require-plan');
    if (requireTasks) args.add('--require-tasks');
    if (featureOverride != null) args.add('--feature=$featureOverride');

    try {
      final result = await _runScript('check-prerequisites.sh', args);
      return PrerequisitesResult.fromJson(result, passed: true);
    } on ContextDetectionException catch (e) {
      // Si falla por requisito faltante, retornar resultado fallido
      return PrerequisitesResult(
        passed: false,
        featureId: '',
        paths: const FeaturePaths.empty(),
        availableDocuments: const [],
        errorMessage: e.message,
        errorCode: e.code,
      );
    }
  }

  /// Valida la calidad de una especificación.
  ///
  /// Retorna [SpecValidationResult] con score y findings.
  Future<SpecValidationResult> validateSpec({
    String? featureOverride,
    bool strict = false,
  }) async {
    final args = ['--json'];
    if (featureOverride != null) args.add('--feature=$featureOverride');
    if (strict) args.add('--strict');

    try {
      final result = await _runScript('validate-spec.sh', args);
      return SpecValidationResult.fromJson(result);
    } on ContextDetectionException catch (e) {
      return SpecValidationResult(
        passed: false,
        score: 0,
        featureId: featureOverride ?? '',
        specPath: '',
        findings: [
          SpecFinding(
            severity: FindingSeverity.critical,
            code: e.code,
            message: e.message,
            line: 0,
          ),
        ],
      );
    }
  }

  /// Obtiene el siguiente número de feature disponible.
  Future<String> getNextFeatureNumber() async {
    final context = await detectFullContext();
    return context.nextFeatureNumber;
  }

  /// Verifica si estamos en un repositorio git.
  Future<bool> isGitRepository() async {
    final context = await detectFullContext();
    return context.git.isGitRepo;
  }

  /// Obtiene el branch actual.
  Future<String> getCurrentBranch() async {
    final context = await detectFullContext();
    return context.git.currentBranch;
  }

  /// Ejecuta un script y retorna el JSON parseado.
  Future<Map<String, dynamic>> _runScript(
    String scriptName,
    List<String> args,
  ) async {
    final scriptPath = '$_scriptsPath/$scriptName';

    // Verificar que el script existe
    if (!File(scriptPath).existsSync()) {
      throw ContextDetectionException(
        'Script no encontrado: $scriptPath',
        'SCRIPT_NOT_FOUND',
      );
    }

    final result = await Process.run('bash', [scriptPath, ...args]);

    if (result.exitCode != 0) {
      // Intentar parsear error JSON
      final output = result.stdout.toString();
      try {
        final json = jsonDecode(output) as Map<String, dynamic>;
        if (json['status'] == 'error') {
          final error = json['error'] as Map<String, dynamic>;
          throw ContextDetectionException(
            error['message'] as String? ?? 'Error desconocido',
            error['code'] as String? ?? 'UNKNOWN_ERROR',
          );
        }
      } catch (e) {
        if (e is ContextDetectionException) rethrow;
        // Si no es JSON, usar stderr
        throw ContextDetectionException(
          result.stderr.toString().isNotEmpty
              ? result.stderr.toString()
              : 'Script falló con código ${result.exitCode}',
          'SCRIPT_FAILED',
        );
      }
    }

    final output = result.stdout.toString();
    try {
      return jsonDecode(output) as Map<String, dynamic>;
    } catch (e) {
      throw ContextDetectionException(
        'Error parseando JSON: $e\nOutput: $output',
        'JSON_PARSE_ERROR',
      );
    }
  }
}

/// Resultado de verificación de prerequisitos.
class PrerequisitesResult {
  /// Crea resultado de prerequisitos.
  const PrerequisitesResult({
    required this.passed,
    required this.featureId,
    required this.paths,
    required this.availableDocuments,
    this.errorMessage,
    this.errorCode,
  });

  /// Crea desde JSON.
  factory PrerequisitesResult.fromJson(
    Map<String, dynamic> json, {
    required bool passed,
  }) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    final featureId = data['feature_id'] as String? ?? '';
    final pathsJson = data['paths'] as Map<String, dynamic>? ?? {};
    final availableDocs =
        (data['available_docs'] as List<dynamic>?)?.cast<String>() ?? [];

    return PrerequisitesResult(
      passed: passed,
      featureId: featureId,
      paths: featureId.isNotEmpty
          ? FeaturePaths(
              featureDir: pathsJson['feature_dir'] as String? ?? '',
              spec: pathsJson['spec'] as String? ?? '',
              plan: pathsJson['plan'] as String? ?? '',
              tasks: pathsJson['tasks'] as String? ?? '',
              research: pathsJson['research'] as String? ?? '',
              checklist: pathsJson['checklist'] as String? ?? '',
              dataModel: pathsJson['data_model'] as String? ?? '',
            )
          : const FeaturePaths.empty(),
      availableDocuments: availableDocs,
    );
  }

  /// Si pasó la verificación.
  final bool passed;

  /// ID de la feature detectada.
  final String featureId;

  /// Paths a los documentos.
  final FeaturePaths paths;

  /// Documentos disponibles.
  final List<String> availableDocuments;

  /// Mensaje de error si no pasó.
  final String? errorMessage;

  /// Código de error si no pasó.
  final String? errorCode;

  /// Si hay feature detectada.
  bool get hasFeature => featureId.isNotEmpty;

  /// Convierte a JSON.
  Map<String, dynamic> toJson() => {
        'passed': passed,
        'feature_id': featureId,
        'paths': paths.toJson(),
        'available_documents': availableDocuments,
        if (errorMessage != null) 'error_message': errorMessage,
        if (errorCode != null) 'error_code': errorCode,
      };
}

/// Severidad de un finding de validación.
enum FindingSeverity {
  /// Bloquea implementación.
  critical,

  /// Debería resolverse.
  warning,

  /// Sugerencia de mejora.
  info,
}

/// Un problema encontrado en la validación.
class SpecFinding {
  /// Crea un finding.
  const SpecFinding({
    required this.severity,
    required this.code,
    required this.message,
    required this.line,
  });

  /// Crea desde JSON.
  factory SpecFinding.fromJson(Map<String, dynamic> json) {
    return SpecFinding(
      severity: _parseSeverity(json['severity'] as String? ?? 'info'),
      code: json['code'] as String? ?? '',
      message: json['message'] as String? ?? '',
      line: json['line'] as int? ?? 0,
    );
  }

  /// Severidad del problema.
  final FindingSeverity severity;

  /// Código del problema (ej: SPEC001).
  final String code;

  /// Descripción del problema.
  final String message;

  /// Línea donde se encontró (0 si no aplica).
  final int line;

  /// Convierte a JSON.
  Map<String, dynamic> toJson() => {
        'severity': severity.name.toUpperCase(),
        'code': code,
        'message': message,
        'line': line,
      };

  static FindingSeverity _parseSeverity(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return FindingSeverity.critical;
      case 'WARNING':
        return FindingSeverity.warning;
      default:
        return FindingSeverity.info;
    }
  }
}

/// Resultado de validación de especificación.
class SpecValidationResult {
  /// Crea resultado de validación.
  const SpecValidationResult({
    required this.passed,
    required this.score,
    required this.featureId,
    required this.specPath,
    required this.findings,
  });

  /// Crea desde JSON.
  factory SpecValidationResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final validation = data['validation'] as Map<String, dynamic>? ?? {};
    final findingsJson = validation['findings'] as List<dynamic>? ?? [];

    return SpecValidationResult(
      passed: validation['passed'] as bool? ?? false,
      score: validation['score'] as int? ?? 0,
      featureId: data['feature_id'] as String? ?? '',
      specPath: data['spec_path'] as String? ?? '',
      findings: findingsJson
          .map((f) => SpecFinding.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Si pasó la validación.
  final bool passed;

  /// Score de calidad (0-100).
  final int score;

  /// ID de la feature validada.
  final String featureId;

  /// Path al spec.md validado.
  final String specPath;

  /// Lista de problemas encontrados.
  final List<SpecFinding> findings;

  /// Cantidad de críticos.
  int get criticalCount =>
      findings.where((f) => f.severity == FindingSeverity.critical).length;

  /// Cantidad de warnings.
  int get warningCount =>
      findings.where((f) => f.severity == FindingSeverity.warning).length;

  /// Cantidad de info.
  int get infoCount =>
      findings.where((f) => f.severity == FindingSeverity.info).length;

  /// Convierte a JSON.
  Map<String, dynamic> toJson() => {
        'passed': passed,
        'score': score,
        'feature_id': featureId,
        'spec_path': specPath,
        'counts': {
          'critical': criticalCount,
          'warning': warningCount,
          'info': infoCount,
        },
        'findings': findings.map((f) => f.toJson()).toList(),
      };
}

/// Excepción de detección de contexto.
class ContextDetectionException implements Exception {
  /// Crea excepción.
  const ContextDetectionException(this.message, this.code);

  /// Mensaje de error.
  final String message;

  /// Código de error.
  final String code;

  @override
  String toString() => 'ContextDetectionException[$code]: $message';
}
