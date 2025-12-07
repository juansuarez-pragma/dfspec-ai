import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dfspec/src/models/quality_metrics.dart';
import 'package:dfspec/src/services/quality_analyzer.dart';
import 'package:dfspec/src/utils/logger.dart';

/// Comando para verificación constitucional de calidad.
///
/// Valida que el código cumpla con los quality gates definidos
/// en la Constitución DFSpec:
/// - TDD: Cobertura de tests >85%
/// - Architecture: Clean Architecture, dependencias correctas
/// - Complexity: Complejidad ciclomática <10, cognitiva <8
/// - Documentation: Cobertura >80%
///
/// Uso:
/// ```bash
/// dfspec verify --all
/// dfspec verify --gate=tdd
/// dfspec verify --gate=architecture
/// dfspec verify --gate=coverage --threshold=90
/// dfspec verify --gate=complexity --max=8
/// dfspec verify --gate=docs --threshold=85
/// ```
class VerifyCommand extends Command<int> {
  /// Crea el comando verify.
  VerifyCommand() {
    argParser
      ..addFlag(
        'all',
        abbr: 'a',
        help: 'Ejecuta todas las verificaciones constitucionales.',
        negatable: false,
      )
      ..addOption(
        'gate',
        abbr: 'g',
        allowed: ['tdd', 'architecture', 'coverage', 'complexity', 'docs'],
        help: 'Quality gate específico a verificar.',
      )
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Ruta específica a verificar.',
      )
      ..addOption(
        'threshold',
        abbr: 't',
        help: 'Umbral personalizado (0-100 para coverage/docs).',
      )
      ..addOption(
        'max',
        help: 'Valor máximo permitido (para complexity).',
      )
      ..addOption(
        'format',
        allowed: ['summary', 'markdown', 'json'],
        defaultsTo: 'summary',
        help: 'Formato de salida.',
      )
      ..addFlag(
        'strict',
        help: 'Usa umbrales estrictos de la Constitución.',
        negatable: false,
      )
      ..addFlag(
        'ci',
        help: 'Modo CI: falla si no pasa todos los gates.',
        negatable: false,
      );
  }

  @override
  String get name => 'verify';

  @override
  String get description =>
      'Verifica cumplimiento de quality gates constitucionales.';

  @override
  String get invocation => 'dfspec verify [opciones]';

  @override
  Future<int> run() async {
    const logger = Logger();
    final all = argResults!['all'] as bool;
    final gate = argResults!['gate'] as String?;
    final path = argResults!['path'] as String?;
    final thresholdStr = argResults!['threshold'] as String?;
    final maxStr = argResults!['max'] as String?;
    final format = argResults!['format'] as String;
    final strict = argResults!['strict'] as bool;
    final ci = argResults!['ci'] as bool;

    if (!all && gate == null) {
      logger.error('Debe especificar --all o --gate=<quality-gate>');
      logger.info('Gates disponibles: tdd, architecture, coverage, complexity, docs');
      logger.info('Ejemplo: dfspec verify --all');
      logger.info('         dfspec verify --gate=coverage --threshold=90');
      return 1;
    }

    try {
      final analyzer = QualityAnalyzer(
        projectRoot: Directory.current.path,
        customThresholds: strict ? _strictThresholds() : {},
      );

      final paths = path != null ? [path] : null;
      final results = <_GateResult>[];

      if (all) {
        // Ejecutar todos los gates
        results.addAll(await _runAllGates(analyzer, paths, thresholdStr, maxStr));
      } else if (gate != null) {
        // Ejecutar gate específico
        results.add(await _runGate(
          analyzer,
          gate,
          paths,
          thresholdStr,
          maxStr,
        ));
      }

      // Output según formato
      _outputResults(results, format, logger);

      // Evaluar resultado
      final passed = results.every((r) => r.passed);
      final failed = results.where((r) => !r.passed).length;

      logger.blank();
      if (passed) {
        logger.success('Verificación APROBADA: Todos los gates pasaron');
        return 0;
      } else {
        logger.error('Verificación FALLIDA: $failed gate(s) no pasaron');
        return ci ? 1 : 0;
      }
    } catch (e) {
      logger.error('Error en verificación: $e');
      return 1;
    }
  }

  Future<List<_GateResult>> _runAllGates(
    QualityAnalyzer analyzer,
    List<String>? paths,
    String? thresholdStr,
    String? maxStr,
  ) async {
    final results = <_GateResult>[];

    // Coverage/TDD gate
    results.add(await _runGate(analyzer, 'coverage', paths, thresholdStr, null));

    // Complexity gate
    results.add(await _runGate(analyzer, 'complexity', paths, null, maxStr));

    // Documentation gate
    results.add(await _runGate(analyzer, 'docs', paths, thresholdStr, null));

    // Architecture gate (verificación de estructura)
    results.add(await _runArchitectureGate(paths));

    return results;
  }

  Future<_GateResult> _runGate(
    QualityAnalyzer analyzer,
    String gate,
    List<String>? paths,
    String? thresholdStr,
    String? maxStr,
  ) async {
    switch (gate) {
      case 'tdd':
      case 'coverage':
        return _runCoverageGate(thresholdStr);

      case 'complexity':
        final max = maxStr != null ? int.parse(maxStr) : 10;
        return _runComplexityGate(analyzer, paths, max);

      case 'docs':
        final threshold = thresholdStr != null ? int.parse(thresholdStr) : 80;
        return _runDocsGate(analyzer, paths, threshold);

      case 'architecture':
        return _runArchitectureGate(paths);

      default:
        return _GateResult(
          name: gate,
          passed: false,
          message: 'Gate desconocido: $gate',
          value: 0,
          threshold: 0,
        );
    }
  }

  Future<_GateResult> _runCoverageGate(String? thresholdStr) async {
    final threshold = thresholdStr != null ? int.parse(thresholdStr) : 85;

    // Verificar si existe coverage
    final coverageFile = File('${Directory.current.path}/coverage/lcov.info');

    if (!await coverageFile.exists()) {
      return _GateResult(
        name: 'Coverage (TDD)',
        passed: false,
        message: 'No se encontró coverage. Ejecute: flutter test --coverage',
        value: 0,
        threshold: threshold.toDouble(),
      );
    }

    // Parsear lcov.info
    final content = await coverageFile.readAsString();
    final coverage = _parseLcovCoverage(content);

    return _GateResult(
      name: 'Coverage (TDD)',
      passed: coverage >= threshold,
      message: coverage >= threshold
          ? 'Cobertura ${coverage.toStringAsFixed(1)}% >= umbral $threshold%'
          : 'Cobertura ${coverage.toStringAsFixed(1)}% < umbral $threshold%',
      value: coverage,
      threshold: threshold.toDouble(),
    );
  }

  double _parseLcovCoverage(String content) {
    var linesHit = 0;
    var linesFound = 0;

    for (final line in content.split('\n')) {
      if (line.startsWith('LH:')) {
        linesHit += int.parse(line.substring(3));
      } else if (line.startsWith('LF:')) {
        linesFound += int.parse(line.substring(3));
      }
    }

    if (linesFound == 0) return 0;
    return (linesHit / linesFound) * 100;
  }

  Future<_GateResult> _runComplexityGate(
    QualityAnalyzer analyzer,
    List<String>? paths,
    int max,
  ) async {
    final report = await analyzer.analyzeComplexity(paths: paths);

    final complexityMetric = report.metrics.firstWhere(
      (m) => m.name.toLowerCase().contains('complex'),
      orElse: () => throw Exception('No se encontró métrica de complejidad'),
    );

    final value = complexityMetric.value;

    return _GateResult(
      name: 'Complejidad Ciclomática',
      passed: value <= max,
      message: value <= max
          ? 'Complejidad ${value.toStringAsFixed(1)} <= máximo $max'
          : 'Complejidad ${value.toStringAsFixed(1)} > máximo $max',
      value: value,
      threshold: max.toDouble(),
      details: complexityMetric.details.isNotEmpty
          ? {'files': complexityMetric.details}
          : null,
    );
  }

  Future<_GateResult> _runDocsGate(
    QualityAnalyzer analyzer,
    List<String>? paths,
    int threshold,
  ) async {
    final report = await analyzer.analyzeDocumentation(paths: paths);

    final docMetric = report.metrics.firstWhere(
      (m) => m.name.toLowerCase().contains('doc'),
      orElse: () => throw Exception('No se encontró métrica de documentación'),
    );

    final coverage = docMetric.value * 100;

    return _GateResult(
      name: 'Documentación',
      passed: coverage >= threshold,
      message: coverage >= threshold
          ? 'Documentación ${coverage.toStringAsFixed(0)}% >= umbral $threshold%'
          : 'Documentación ${coverage.toStringAsFixed(0)}% < umbral $threshold%',
      value: coverage,
      threshold: threshold.toDouble(),
      details: docMetric.details.isNotEmpty
          ? {'undocumented': docMetric.details}
          : null,
    );
  }

  Future<_GateResult> _runArchitectureGate(List<String>? paths) async {
    final projectRoot = Directory.current.path;
    final violations = <String>[];

    // Verificar estructura Clean Architecture
    final requiredDirs = ['lib/src/domain', 'lib/src/data', 'lib/src/presentation'];
    for (final dir in requiredDirs) {
      final fullPath = '$projectRoot/$dir';
      if (!await Directory(fullPath).exists()) {
        violations.add('Falta directorio: $dir');
      }
    }

    // Verificar que domain no importe data ni presentation
    final domainDir = Directory('$projectRoot/lib/src/domain');
    if (await domainDir.exists()) {
      await for (final file in domainDir.list(recursive: true)) {
        if (file is File && file.path.endsWith('.dart')) {
          final content = await file.readAsString();

          if (content.contains("import 'package:") &&
              (content.contains('/data/') || content.contains('/presentation/'))) {
            final relativePath = file.path.replaceFirst('$projectRoot/', '');
            violations.add('$relativePath importa data o presentation');
          }
        }
      }
    }

    // Verificar tests para cada archivo en lib/src
    final libDir = Directory('$projectRoot/lib/src');
    final testDir = Directory('$projectRoot/test');

    if (await libDir.exists() && await testDir.exists()) {
      var libFiles = 0;
      var testFiles = 0;

      await for (final file in libDir.list(recursive: true)) {
        if (file is File && file.path.endsWith('.dart') && !file.path.contains('.g.dart')) {
          libFiles++;
        }
      }

      await for (final file in testDir.list(recursive: true)) {
        if (file is File && file.path.endsWith('_test.dart')) {
          testFiles++;
        }
      }

      final testRatio = libFiles > 0 ? testFiles / libFiles : 0;
      if (testRatio < 0.5) {
        violations.add(
          'Bajo ratio de tests: $testFiles tests para $libFiles archivos (${(testRatio * 100).toStringAsFixed(0)}%)',
        );
      }
    }

    return _GateResult(
      name: 'Arquitectura (Clean)',
      passed: violations.isEmpty,
      message: violations.isEmpty
          ? 'Arquitectura cumple con Clean Architecture'
          : '${violations.length} violaciones encontradas',
      value: violations.isEmpty ? 100 : 0,
      threshold: 100,
      details: violations.isNotEmpty ? {'violations': violations} : null,
    );
  }

  void _outputResults(List<_GateResult> results, String format, Logger logger) {
    switch (format) {
      case 'json':
        final json = results.map((r) => r.toJson()).toList();
        // ignore: avoid_print
        print(const JsonEncoder.withIndent('  ').convert(json));

      case 'markdown':
        _outputMarkdown(results, logger);

      case 'summary':
      default:
        _outputSummary(results, logger);
    }
  }

  void _outputSummary(List<_GateResult> results, Logger logger) {
    logger.title('Verificación Constitucional');
    logger.blank();

    final headers = ['Gate', 'Estado', 'Valor', 'Umbral', 'Mensaje'];
    final rows = results.map((r) {
      final status = r.passed ? 'PASS' : 'FAIL';
      return [
        r.name,
        status,
        r.value.toStringAsFixed(1),
        r.threshold.toStringAsFixed(1),
        r.message,
      ];
    }).toList();

    logger.table(headers, rows);

    // Mostrar detalles de violaciones
    for (final result in results) {
      if (!result.passed && result.details != null) {
        final violations = result.details!['violations'] as List<dynamic>?;
        if (violations != null && violations.isNotEmpty) {
          logger.blank();
          logger.section('Violaciones en ${result.name}');
          for (final v in violations.take(10)) {
            logger.warning('  - $v');
          }
          if (violations.length > 10) {
            logger.info('  ... y ${violations.length - 10} más');
          }
        }
      }
    }
  }

  void _outputMarkdown(List<_GateResult> results, Logger logger) {
    final buffer = StringBuffer();

    buffer.writeln('# Reporte de Verificación Constitucional');
    buffer.writeln();
    buffer.writeln('| Gate | Estado | Valor | Umbral |');
    buffer.writeln('|------|--------|-------|--------|');

    for (final r in results) {
      final status = r.passed ? '✅ PASS' : '❌ FAIL';
      buffer.writeln(
        '| ${r.name} | $status | ${r.value.toStringAsFixed(1)} | ${r.threshold.toStringAsFixed(1)} |',
      );
    }

    buffer.writeln();

    // Detalles
    for (final result in results) {
      if (!result.passed) {
        buffer.writeln('## ${result.name}');
        buffer.writeln();
        buffer.writeln('**Mensaje:** ${result.message}');
        buffer.writeln();

        if (result.details != null) {
          final violations = result.details!['violations'] as List<dynamic>?;
          if (violations != null && violations.isNotEmpty) {
            buffer.writeln('**Violaciones:**');
            for (final v in violations) {
              buffer.writeln('- $v');
            }
            buffer.writeln();
          }
        }
      }
    }

    // ignore: avoid_print
    print(buffer);
  }

  Map<String, MetricThreshold> _strictThresholds() {
    return {
      'cyclomatic_complexity': const MetricThreshold(
        optimal: 5,
        acceptable: 8,
        warning: 10,
      ),
      'lines_per_file': const MetricThreshold(
        optimal: 200,
        acceptable: 300,
        warning: 400,
      ),
      'documentation': const MetricThreshold(
        optimal: 0.95,
        acceptable: 0.90,
        warning: 0.80,
      ),
    };
  }
}

/// Resultado de verificación de un gate.
class _GateResult {
  _GateResult({
    required this.name,
    required this.passed,
    required this.message,
    required this.value,
    required this.threshold,
    this.details,
  });

  final String name;
  final bool passed;
  final String message;
  final double value;
  final double threshold;
  final Map<String, dynamic>? details;

  Map<String, dynamic> toJson() => {
        'name': name,
        'passed': passed,
        'message': message,
        'value': value,
        'threshold': threshold,
        if (details != null) 'details': details,
      };
}
