import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dfspec/src/models/quality_metrics.dart';
import 'package:dfspec/src/services/quality_analyzer.dart';
import 'package:dfspec/src/utils/logger.dart';

/// Comando para análisis de calidad de código.
///
/// Uso:
/// ```bash
/// dfspec quality analyze
/// dfspec quality analyze --path=lib/src/domain/
/// dfspec quality analyze --format=json
/// dfspec quality complexity
/// dfspec quality docs --threshold=80
/// ```
class QualityCommand extends Command<int> {
  /// Crea el comando quality.
  QualityCommand() {
    addSubcommand(_AnalyzeSubcommand());
    addSubcommand(_ComplexitySubcommand());
    addSubcommand(_DocumentationSubcommand());
  }

  @override
  String get name => 'quality';

  @override
  String get description => 'Analiza métricas de calidad del código.';

  @override
  String get invocation => 'dfspec quality <subcomando>';
}

/// Subcomando para análisis completo.
class _AnalyzeSubcommand extends Command<int> {
  _AnalyzeSubcommand() {
    argParser
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Ruta específica a analizar (default: lib/).',
      )
      ..addOption(
        'format',
        allowed: ['markdown', 'json', 'summary'],
        defaultsTo: 'markdown',
        help: 'Formato de salida.',
      )
      ..addOption(
        'threshold',
        abbr: 't',
        defaultsTo: '70',
        help: 'Umbral mínimo de score (0-100).',
      )
      ..addFlag(
        'strict',
        help: 'Usa umbrales estrictos de la Constitución.',
        negatable: false,
      );
  }

  @override
  String get name => 'analyze';

  @override
  String get description => 'Ejecuta análisis completo de calidad.';

  @override
  Future<int> run() async {
    const logger = Logger();
    final path = argResults!['path'] as String?;
    final format = argResults!['format'] as String;
    final threshold = int.parse(argResults!['threshold'] as String);
    final strict = argResults!['strict'] as bool;

    logger.info('Analizando calidad del código...');

    try {
      final analyzer = QualityAnalyzer(
        projectRoot: Directory.current.path,
        customThresholds: strict ? _strictThresholds() : {},
      );

      final paths = path != null ? [path] : null;
      final report = await analyzer.analyze(paths: paths);

      _outputReport(report, format, logger);

      // Evaluar resultado
      final score = report.overallScore;
      logger.blank();

      if (score >= 85) {
        logger.success('Calidad ALTA: $score/100');
      } else if (score >= threshold) {
        logger.warning('Calidad ACEPTABLE: $score/100');
      } else {
        logger.error('Calidad BAJA: $score/100 (umbral: $threshold)');
        return 1;
      }

      return 0;
    } catch (e) {
      logger.error('Error en análisis: $e');
      return 1;
    }
  }

  void _outputReport(QualityReport report, String format, Logger logger) {
    switch (format) {
      case 'json':
        // ignore: avoid_print
        print(const JsonEncoder.withIndent('  ').convert(report.toJson()));
      case 'summary':
        _printSummary(report, logger);
      case 'markdown':
      default:
        // ignore: avoid_print
        print(report.toSummary());
    }
  }

  void _printSummary(QualityReport report, Logger logger) {
    logger.panel(
      'Resumen de Calidad',
      '''
Score: ${report.overallScore}/100
Métricas: ${report.metrics.length}
Críticos: ${report.critical.length}
Warnings: ${report.warnings.length}
''',
    );

    if (report.critical.isNotEmpty) {
      logger.section('Issues Críticos');
      for (final metric in report.critical) {
        logger.error('${metric.name}: ${metric.formattedValue}');
      }
    }
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

/// Subcomando para análisis de complejidad.
class _ComplexitySubcommand extends Command<int> {
  _ComplexitySubcommand() {
    argParser
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Ruta específica a analizar.',
      )
      ..addOption(
        'max',
        defaultsTo: '10',
        help: 'Complejidad ciclomática máxima permitida.',
      );
  }

  @override
  String get name => 'complexity';

  @override
  String get description => 'Analiza complejidad ciclomática y cognitiva.';

  @override
  Future<int> run() async {
    const logger = Logger();
    final path = argResults!['path'] as String?;
    final maxComplexity = int.parse(argResults!['max'] as String);

    logger.info('Analizando complejidad...');

    try {
      final analyzer = QualityAnalyzer(projectRoot: Directory.current.path);
      final paths = path != null ? [path] : null;
      final report = await analyzer.analyzeComplexity(paths: paths);

      // ignore: avoid_print
      print(report.toSummary());

      // Verificar umbral
      final complexityMetric = report.metrics.firstWhere(
        (m) => m.name.toLowerCase().contains('complex'),
        orElse: () => QualityMetrics.cyclomaticComplexity(0),
      );

      if (complexityMetric.value > maxComplexity) {
        logger.error(
          'Complejidad ${complexityMetric.value.toStringAsFixed(1)} '
          'excede el máximo permitido ($maxComplexity)',
        );
        return 1;
      }

      logger.success(
        'Complejidad OK: ${complexityMetric.value.toStringAsFixed(1)}',
      );
      return 0;
    } catch (e) {
      logger.error('Error: $e');
      return 1;
    }
  }
}

/// Subcomando para análisis de documentación.
class _DocumentationSubcommand extends Command<int> {
  _DocumentationSubcommand() {
    argParser
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Ruta específica a analizar.',
      )
      ..addOption(
        'threshold',
        abbr: 't',
        defaultsTo: '80',
        help: 'Porcentaje mínimo de documentación.',
      );
  }

  @override
  String get name => 'docs';

  @override
  String get description => 'Analiza cobertura de documentación.';

  @override
  Future<int> run() async {
    const logger = Logger();
    final path = argResults!['path'] as String?;
    final threshold = int.parse(argResults!['threshold'] as String);

    logger.info('Analizando documentación...');

    try {
      final analyzer = QualityAnalyzer(projectRoot: Directory.current.path);
      final paths = path != null ? [path] : null;
      final report = await analyzer.analyzeDocumentation(paths: paths);

      // ignore: avoid_print
      print(report.toSummary());

      // Verificar umbral
      final docMetric = report.metrics.firstWhere(
        (m) => m.name.toLowerCase().contains('doc'),
        orElse: () => QualityMetrics.documentation(1),
      );

      final coverage = docMetric.value * 100;
      if (coverage < threshold) {
        logger.error(
          'Documentación ${coverage.toStringAsFixed(0)}% '
          'por debajo del umbral ($threshold%)',
        );
        return 1;
      }

      logger.success('Documentación OK: ${coverage.toStringAsFixed(0)}%');
      return 0;
    } catch (e) {
      logger.error('Error: $e');
      return 1;
    }
  }
}
