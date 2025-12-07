/// Configuración de CI/CD para DFSpec.
///
/// Este módulo define la configuración del pipeline de CI/CD
/// siguiendo los principios de la Constitución DFSpec.
library;

import 'package:meta/meta.dart';

/// Tipos de triggers para el pipeline.
enum CITrigger {
  /// Solo en Pull Requests a main.
  pullRequestMain('pull_request_main', 'PR a main'),

  /// En push a cualquier rama.
  pushAny('push_any', 'Push a cualquier rama'),

  /// En push a main.
  pushMain('push_main', 'Push a main'),

  /// En tags de versión.
  tagVersion('tag_version', 'Tag de versión'),

  /// Manual.
  manual('manual', 'Ejecución manual');

  const CITrigger(this.id, this.label);
  final String id;
  final String label;
}

/// Etapas del pipeline de CI.
enum CIStage {
  /// Verificación de formato.
  format('format', 'Formato', 1),

  /// Análisis estático.
  analyze('analyze', 'Análisis', 2),

  /// Ejecución de tests.
  test('test', 'Tests', 3),

  /// Verificación de cobertura.
  coverage('coverage', 'Cobertura', 4),

  /// Gates de calidad.
  qualityGates('quality_gates', 'Quality Gates', 5),

  /// Build del proyecto.
  build('build', 'Build', 6),

  /// Publicación de artefactos.
  publish('publish', 'Publicación', 7);

  const CIStage(this.id, this.label, this.order);
  final String id;
  final String label;
  final int order;
}

/// Estado de una etapa del pipeline.
enum StageStatus {
  /// Pendiente de ejecutar.
  pending('pending', '⏳'),

  /// En ejecución.
  running('running', '🔄'),

  /// Completada exitosamente.
  passed('passed', '✅'),

  /// Fallida.
  failed('failed', '❌'),

  /// Saltada.
  skipped('skipped', '⏭️');

  const StageStatus(this.id, this.icon);
  final String id;
  final String icon;
}

/// Resultado de una etapa del pipeline.
@immutable
class StageResult {
  /// Crea un resultado de etapa.
  const StageResult({
    required this.stage,
    required this.status,
    this.message,
    this.duration,
    this.artifacts = const [],
    this.logs = const [],
  });

  /// Deserializa desde JSON.
  factory StageResult.fromJson(Map<String, dynamic> json) {
    return StageResult(
      stage: CIStage.values.firstWhere((s) => s.id == json['stage']),
      status: StageStatus.values.firstWhere((s) => s.id == json['status']),
      message: json['message'] as String?,
      duration: json['duration_ms'] != null
          ? Duration(milliseconds: json['duration_ms'] as int)
          : null,
      artifacts: List<String>.from((json['artifacts'] as List?) ?? []),
      logs: List<String>.from((json['logs'] as List?) ?? []),
    );
  }

  /// Etapa ejecutada.
  final CIStage stage;

  /// Estado de la etapa.
  final StageStatus status;

  /// Mensaje descriptivo.
  final String? message;

  /// Duración de la ejecución.
  final Duration? duration;

  /// Artefactos generados.
  final List<String> artifacts;

  /// Logs de ejecución.
  final List<String> logs;

  /// Si la etapa fue exitosa.
  bool get isSuccess => status == StageStatus.passed;

  /// Si la etapa falló.
  bool get isFailed => status == StageStatus.failed;

  /// Serializa a JSON.
  Map<String, dynamic> toJson() => {
        'stage': stage.id,
        'status': status.id,
        if (message != null) 'message': message,
        if (duration != null) 'duration_ms': duration!.inMilliseconds,
        'artifacts': artifacts,
        'logs': logs,
      };

  @override
  String toString() =>
      'StageResult(${stage.label}: ${status.id}${message != null ? " - $message" : ""})';
}

/// Configuración de quality gates.
@immutable
class QualityGateConfig {
  /// Crea una configuración de quality gates.
  const QualityGateConfig({
    this.minCoverage = 85.0,
    this.maxCyclomaticComplexity = 10,
    this.maxCognitiveComplexity = 8,
    this.maxLinesPerFile = 400,
    this.requireDocumentation = true,
    this.minDocumentationCoverage = 80.0,
    this.requireCleanArchitecture = true,
    this.requireTddCorrespondence = true,
    this.requireImmutableEntities = true,
  });

  /// Deserializa desde JSON.
  factory QualityGateConfig.fromJson(Map<String, dynamic> json) {
    return QualityGateConfig(
      minCoverage: (json['min_coverage'] as num?)?.toDouble() ?? 85.0,
      maxCyclomaticComplexity:
          json['max_cyclomatic_complexity'] as int? ?? 10,
      maxCognitiveComplexity: json['max_cognitive_complexity'] as int? ?? 8,
      maxLinesPerFile: json['max_lines_per_file'] as int? ?? 400,
      requireDocumentation: json['require_documentation'] as bool? ?? true,
      minDocumentationCoverage:
          (json['min_documentation_coverage'] as num?)?.toDouble() ?? 80.0,
      requireCleanArchitecture:
          json['require_clean_architecture'] as bool? ?? true,
      requireTddCorrespondence:
          json['require_tdd_correspondence'] as bool? ?? true,
      requireImmutableEntities:
          json['require_immutable_entities'] as bool? ?? true,
    );
  }

  /// Cobertura mínima de tests (%).
  final double minCoverage;

  /// Complejidad ciclomática máxima.
  final int maxCyclomaticComplexity;

  /// Complejidad cognitiva máxima.
  final int maxCognitiveComplexity;

  /// Líneas máximas por archivo.
  final int maxLinesPerFile;

  /// Requiere documentación.
  final bool requireDocumentation;

  /// Cobertura mínima de documentación (%).
  final double minDocumentationCoverage;

  /// Requiere validación de Clean Architecture.
  final bool requireCleanArchitecture;

  /// Requiere correspondencia TDD.
  final bool requireTddCorrespondence;

  /// Requiere entidades inmutables.
  final bool requireImmutableEntities;

  /// Configuración por defecto basada en la Constitución.
  static const constitutional = QualityGateConfig();

  /// Configuración estricta.
  static const strict = QualityGateConfig(
    minCoverage: 90,
    maxCyclomaticComplexity: 8,
    maxCognitiveComplexity: 6,
    maxLinesPerFile: 300,
    minDocumentationCoverage: 90,
  );

  /// Configuración relajada para desarrollo.
  static const relaxed = QualityGateConfig(
    minCoverage: 70,
    maxCyclomaticComplexity: 15,
    maxCognitiveComplexity: 12,
    maxLinesPerFile: 500,
    minDocumentationCoverage: 60,
    requireDocumentation: false,
  );

  /// Serializa a JSON.
  Map<String, dynamic> toJson() => {
        'min_coverage': minCoverage,
        'max_cyclomatic_complexity': maxCyclomaticComplexity,
        'max_cognitive_complexity': maxCognitiveComplexity,
        'max_lines_per_file': maxLinesPerFile,
        'require_documentation': requireDocumentation,
        'min_documentation_coverage': minDocumentationCoverage,
        'require_clean_architecture': requireCleanArchitecture,
        'require_tdd_correspondence': requireTddCorrespondence,
        'require_immutable_entities': requireImmutableEntities,
      };

  @override
  String toString() =>
      'QualityGateConfig(coverage: $minCoverage%, complexity: $maxCyclomaticComplexity)';
}

/// Configuración completa del pipeline de CI.
@immutable
class CIConfig {
  /// Crea una configuración de CI.
  const CIConfig({
    required this.name,
    this.triggers = const [CITrigger.pullRequestMain],
    this.stages = const [
      CIStage.format,
      CIStage.analyze,
      CIStage.test,
      CIStage.coverage,
      CIStage.qualityGates,
      CIStage.build,
    ],
    this.qualityGates = const QualityGateConfig(),
    this.platforms = const ['ubuntu-latest'],
    this.dartVersions = const ['stable'],
    this.parallelJobs = true,
    this.failFast = true,
    this.cacheEnabled = true,
  });

  /// Deserializa desde JSON.
  factory CIConfig.fromJson(Map<String, dynamic> json) {
    return CIConfig(
      name: json['name'] as String,
      triggers: (json['triggers'] as List?)
              ?.map((t) => CITrigger.values.firstWhere((v) => v.id == t))
              .toList() ??
          [CITrigger.pullRequestMain],
      stages: (json['stages'] as List?)
              ?.map((s) => CIStage.values.firstWhere((v) => v.id == s))
              .toList() ??
          CIStage.values,
      qualityGates: json['quality_gates'] != null
          ? QualityGateConfig.fromJson(
              json['quality_gates'] as Map<String, dynamic>)
          : const QualityGateConfig(),
      platforms: List<String>.from(
        (json['platforms'] as List?) ?? ['ubuntu-latest'],
      ),
      dartVersions: List<String>.from(
        (json['dart_versions'] as List?) ?? ['stable'],
      ),
      parallelJobs: json['parallel_jobs'] as bool? ?? true,
      failFast: json['fail_fast'] as bool? ?? true,
      cacheEnabled: json['cache_enabled'] as bool? ?? true,
    );
  }

  /// Nombre del pipeline.
  final String name;

  /// Triggers que activan el pipeline.
  final List<CITrigger> triggers;

  /// Etapas del pipeline.
  final List<CIStage> stages;

  /// Configuración de quality gates.
  final QualityGateConfig qualityGates;

  /// Plataformas de ejecución.
  final List<String> platforms;

  /// Versiones de Dart a probar.
  final List<String> dartVersions;

  /// Ejecutar jobs en paralelo.
  final bool parallelJobs;

  /// Fallar rápido si una etapa falla.
  final bool failFast;

  /// Habilitar cache de dependencias.
  final bool cacheEnabled;

  /// Configuración por defecto para DFSpec.
  static const dfspecDefault = CIConfig(
    name: 'DFSpec CI',
    platforms: ['ubuntu-latest', 'macos-latest', 'windows-latest'],
    dartVersions: ['stable', '3.0.0'],
  );

  /// Genera el workflow de GitHub Actions.
  String generateGitHubWorkflow() {
    final buffer = StringBuffer();

    buffer.writeln('name: $name');
    buffer.writeln();

    // Triggers
    buffer.writeln('on:');
    for (final trigger in triggers) {
      switch (trigger) {
        case CITrigger.pullRequestMain:
          buffer.writeln('  pull_request:');
          buffer.writeln('    branches: [main]');
        case CITrigger.pushMain:
          buffer.writeln('  push:');
          buffer.writeln('    branches: [main]');
        case CITrigger.pushAny:
          buffer.writeln('  push:');
        case CITrigger.tagVersion:
          buffer.writeln('  push:');
          buffer.writeln('    tags:');
          buffer.writeln("      - 'v*'");
        case CITrigger.manual:
          buffer.writeln('  workflow_dispatch:');
      }
    }
    buffer.writeln();

    // Jobs
    buffer.writeln('jobs:');

    // Matrix setup
    if (platforms.length > 1 || dartVersions.length > 1) {
      buffer.writeln('  setup:');
      buffer.writeln('    runs-on: ubuntu-latest');
      buffer.writeln('    outputs:');
      buffer.writeln(r'      matrix: ${{ steps.set-matrix.outputs.matrix }}');
      buffer.writeln('    steps:');
      buffer.writeln('      - id: set-matrix');
      buffer.writeln('        run: |');
      buffer.writeln(
          '          echo "matrix={\\"os\\":${_jsonList(platforms)},\\"dart\\":${_jsonList(dartVersions)}}" >> \$GITHUB_OUTPUT');
      buffer.writeln();
    }

    // Stage jobs
    var previousStage = '';
    for (final stage in stages) {
      buffer.writeln('  ${stage.id}:');
      buffer.writeln('    name: ${stage.label}');

      if (platforms.length > 1 || dartVersions.length > 1) {
        buffer.writeln('    needs: setup');
        buffer.writeln(r'    runs-on: ${{ matrix.os }}');
        buffer.writeln('    strategy:');
        if (failFast) {
          buffer.writeln('      fail-fast: true');
        }
        buffer.writeln('      matrix:');
        buffer.writeln(
            r'        os: ${{ fromJson(needs.setup.outputs.matrix).os }}');
        buffer.writeln(
            r'        dart: ${{ fromJson(needs.setup.outputs.matrix).dart }}');
      } else {
        if (previousStage.isNotEmpty && !parallelJobs) {
          buffer.writeln('    needs: $previousStage');
        }
        buffer.writeln('    runs-on: ${platforms.first}');
      }

      buffer.writeln('    steps:');
      buffer.writeln('      - uses: actions/checkout@v4');
      buffer.writeln();
      buffer.writeln('      - uses: dart-lang/setup-dart@v1');
      buffer.writeln('        with:');

      if (dartVersions.length > 1) {
        buffer.writeln(r'          sdk: ${{ matrix.dart }}');
      } else {
        buffer.writeln('          sdk: ${dartVersions.first}');
      }

      buffer.writeln();

      if (cacheEnabled) {
        buffer.writeln('      - name: Cache dependencies');
        buffer.writeln('        uses: actions/cache@v4');
        buffer.writeln('        with:');
        buffer.writeln('          path: ~/.pub-cache');
        buffer.writeln(
            r"          key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}");
        buffer.writeln('          restore-keys: |');
        buffer.writeln(r'            ${{ runner.os }}-pub-');
        buffer.writeln();
      }

      buffer.writeln('      - name: Install dependencies');
      buffer.writeln('        run: dart pub get');
      buffer.writeln();

      // Stage-specific steps
      _writeStageSteps(buffer, stage);

      buffer.writeln();
      previousStage = stage.id;
    }

    return buffer.toString();
  }

  void _writeStageSteps(StringBuffer buffer, CIStage stage) {
    switch (stage) {
      case CIStage.format:
        buffer.writeln('      - name: Verify formatting');
        buffer.writeln(
            '        run: dart format --output=none --set-exit-if-changed .');

      case CIStage.analyze:
        buffer.writeln('      - name: Analyze project source');
        buffer.writeln('        run: dart analyze --fatal-infos');

      case CIStage.test:
        buffer.writeln('      - name: Run tests');
        buffer.writeln('        run: dart test');

      case CIStage.coverage:
        buffer.writeln('      - name: Run tests with coverage');
        buffer.writeln('        run: |');
        buffer.writeln('          dart pub global activate coverage');
        buffer.writeln('          dart test --coverage=coverage');
        buffer.writeln(
            r'          dart pub global run coverage:format_coverage \');
        buffer.writeln(r'            --lcov \');
        buffer.writeln(r'            --in=coverage \');
        buffer.writeln(r'            --out=coverage/lcov.info \');
        buffer.writeln('            --report-on=lib');
        buffer.writeln();
        buffer.writeln('      - name: Check coverage threshold');
        buffer.writeln('        run: |');
        buffer.writeln(
            r'          COVERAGE=$(dart pub global run coverage:format_coverage --in=coverage --report-on=lib 2>/dev/null | grep -oP "\d+\.\d+" | head -1 || echo "0")');
        buffer.writeln(
            '          if (( \$(echo "\$COVERAGE < ${qualityGates.minCoverage}" | bc -l) )); then');
        buffer.writeln(
            '            echo "Coverage \$COVERAGE% is below threshold ${qualityGates.minCoverage}%"');
        buffer.writeln('            exit 1');
        buffer.writeln('          fi');

      case CIStage.qualityGates:
        buffer.writeln('      - name: Run quality gates');
        buffer.writeln('        run: |');
        buffer.writeln('          echo "Running DFSpec quality gates..."');
        buffer.writeln('          dart run bin/dfspec.dart verify --all');

      case CIStage.build:
        buffer.writeln('      - name: Build');
        buffer.writeln('        run: dart compile exe bin/dfspec.dart -o dfspec');
        buffer.writeln();
        buffer.writeln('      - name: Upload artifact');
        buffer.writeln('        uses: actions/upload-artifact@v4');
        buffer.writeln('        with:');
        buffer.writeln(r'          name: dfspec-${{ runner.os }}');
        buffer.writeln('          path: dfspec');

      case CIStage.publish:
        buffer.writeln('      - name: Publish to pub.dev');
        buffer.writeln('        run: dart pub publish --dry-run');
    }
  }

  String _jsonList(List<String> items) {
    return '[${items.map((i) => '\\"$i\\"').join(',')}]';
  }

  /// Serializa a JSON.
  Map<String, dynamic> toJson() => {
        'name': name,
        'triggers': triggers.map((t) => t.id).toList(),
        'stages': stages.map((s) => s.id).toList(),
        'quality_gates': qualityGates.toJson(),
        'platforms': platforms,
        'dart_versions': dartVersions,
        'parallel_jobs': parallelJobs,
        'fail_fast': failFast,
        'cache_enabled': cacheEnabled,
      };

  @override
  String toString() => 'CIConfig($name, triggers: ${triggers.length}, stages: ${stages.length})';
}

/// Resultado de ejecución del pipeline.
@immutable
class PipelineResult {
  /// Crea un resultado de pipeline.
  const PipelineResult({
    required this.config,
    required this.results,
    required this.startTime,
    this.endTime,
    this.commit,
    this.branch,
    this.pullRequest,
  });

  /// Deserializa desde JSON.
  factory PipelineResult.fromJson(Map<String, dynamic> json) {
    return PipelineResult(
      config: CIConfig.fromJson(json['config'] as Map<String, dynamic>),
      results: (json['results'] as List)
          .map((r) => StageResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      commit: json['commit'] as String?,
      branch: json['branch'] as String?,
      pullRequest: json['pull_request'] as int?,
    );
  }

  /// Configuración usada.
  final CIConfig config;

  /// Resultados por etapa.
  final List<StageResult> results;

  /// Inicio de ejecución.
  final DateTime startTime;

  /// Fin de ejecución.
  final DateTime? endTime;

  /// Commit asociado.
  final String? commit;

  /// Rama.
  final String? branch;

  /// Pull request asociado.
  final int? pullRequest;

  /// Si el pipeline fue exitoso.
  bool get isSuccess => results.every((r) => r.isSuccess || r.status == StageStatus.skipped);

  /// Si el pipeline falló.
  bool get isFailed => results.any((r) => r.isFailed);

  /// Duración total.
  Duration? get duration =>
      endTime?.difference(startTime);

  /// Resumen del pipeline.
  String toSummary() {
    final buffer = StringBuffer();

    buffer.writeln('# Pipeline: ${config.name}');
    buffer.writeln();
    buffer.writeln('**Estado:** ${isSuccess ? '✅ Exitoso' : '❌ Fallido'}');
    if (duration != null) {
      buffer.writeln('**Duración:** ${duration!.inMinutes}m ${duration!.inSeconds % 60}s');
    }
    if (commit != null) {
      buffer.writeln('**Commit:** ${commit!.substring(0, 7)}');
    }
    if (branch != null) {
      buffer.writeln('**Rama:** $branch');
    }
    if (pullRequest != null) {
      buffer.writeln('**PR:** #$pullRequest');
    }
    buffer.writeln();
    buffer.writeln('## Etapas');
    buffer.writeln();

    for (final result in results) {
      buffer.writeln(
          '- ${result.status.icon} **${result.stage.label}**: ${result.message ?? result.status.id}');
      if (result.duration != null) {
        buffer.writeln('  - Duración: ${result.duration!.inSeconds}s');
      }
    }

    return buffer.toString();
  }

  /// Serializa a JSON.
  Map<String, dynamic> toJson() => {
        'config': config.toJson(),
        'results': results.map((r) => r.toJson()).toList(),
        'start_time': startTime.toIso8601String(),
        if (endTime != null) 'end_time': endTime!.toIso8601String(),
        if (commit != null) 'commit': commit,
        if (branch != null) 'branch': branch,
        if (pullRequest != null) 'pull_request': pullRequest,
      };

  @override
  String toString() =>
      'PipelineResult(${config.name}: ${isSuccess ? "success" : "failed"})';
}
