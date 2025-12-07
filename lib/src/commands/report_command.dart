import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dfspec/src/services/report_generator.dart';
import 'package:dfspec/src/utils/logger.dart';

/// Comando para generar reportes de features y proyecto.
///
/// Uso:
/// ```bash
/// dfspec report --feature=city-search
/// dfspec report --project
/// dfspec report --feature=city-search --format=json
/// dfspec report --feature=city-search --output=reports/
/// ```
class ReportCommand extends Command<int> {
  /// Crea el comando report.
  ReportCommand() {
    argParser
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'Nombre de la feature para generar reporte.',
      )
      ..addFlag(
        'project',
        abbr: 'p',
        help: 'Genera reporte del proyecto completo.',
        negatable: false,
      )
      ..addOption(
        'format',
        allowed: ['markdown', 'json'],
        defaultsTo: 'markdown',
        help: 'Formato de salida del reporte.',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Directorio de salida para guardar el reporte.',
      )
      ..addFlag(
        'save',
        abbr: 's',
        help: 'Guarda el reporte en docs/reports/.',
        negatable: false,
      );
  }

  @override
  String get name => 'report';

  @override
  String get description => 'Genera reportes de features o proyecto.';

  @override
  String get invocation => 'dfspec report [opciones]';

  @override
  Future<int> run() async {
    const logger = Logger();
    final feature = argResults!['feature'] as String?;
    final isProject = argResults!['project'] as bool;
    final format = argResults!['format'] as String;
    final output = argResults!['output'] as String?;
    final save = argResults!['save'] as bool;

    if (feature == null && !isProject) {
      logger.error('Debe especificar --feature=<nombre> o --project');
      logger.info('Uso: dfspec report --feature=city-search');
      logger.info('     dfspec report --project');
      return 1;
    }

    try {
      final generator = ReportGenerator(projectRoot: Directory.current.path);

      if (feature != null) {
        return await _generateFeatureReport(
          generator: generator,
          feature: feature,
          format: format,
          output: output,
          save: save,
          logger: logger,
        );
      } else {
        return await _generateProjectReport(
          generator: generator,
          format: format,
          output: output,
          save: save,
          logger: logger,
        );
      }
    } catch (e) {
      logger.error('Error generando reporte: $e');
      return 1;
    }
  }

  Future<int> _generateFeatureReport({
    required ReportGenerator generator,
    required String feature,
    required String format,
    required String? output,
    required bool save,
    required Logger logger,
  }) async {
    logger.info('Generando reporte de feature: $feature');

    final report = await generator.generateFeatureReport(feature);

    // Output según formato
    final content = format == 'json'
        ? const JsonEncoder.withIndent('  ').convert(report.toJson())
        : report.toMarkdown();

    if (output != null || save) {
      final outputPath = output ?? 'docs/reports';
      final extension = format == 'json' ? 'json' : 'md';
      final filePath = '$outputPath/$feature-report.$extension';

      await _saveReport(filePath, content, logger);
    } else {
      // ignore: avoid_print
      print(content);
    }

    // Mostrar resumen
    logger.blank();
    logger.success('Reporte generado exitosamente');
    _printFeatureSummary(report, logger);

    return report.hasCriticalIssues ? 1 : 0;
  }

  Future<int> _generateProjectReport({
    required ReportGenerator generator,
    required String format,
    required String? output,
    required bool save,
    required Logger logger,
  }) async {
    logger.info('Generando reporte de proyecto...');

    final report = await generator.generateProjectReport();

    // Output según formato
    final content = format == 'json'
        ? const JsonEncoder.withIndent('  ').convert(report.toJson())
        : report.toMarkdown();

    if (output != null || save) {
      final outputPath = output ?? 'docs/reports';
      final extension = format == 'json' ? 'json' : 'md';
      final filePath = '$outputPath/project-report.$extension';

      await _saveReport(filePath, content, logger);
    } else {
      // ignore: avoid_print
      print(content);
    }

    // Mostrar resumen
    logger.blank();
    logger.success('Reporte de proyecto generado');
    _printProjectSummary(report, logger);

    return 0;
  }

  Future<void> _saveReport(
    String filePath,
    String content,
    Logger logger,
  ) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    logger.success('Reporte guardado en: $filePath');
  }

  void _printFeatureSummary(dynamic report, Logger logger) {
    logger.panel(
      'Resumen de Feature',
      '''
Feature: ${report.featureName}
Estado: ${report.status.name}
Progreso: ${(report.metrics.progress * 100).toStringAsFixed(0)}%
Componentes: ${report.components.length}
Issues: ${report.issues.length}
''',
    );
  }

  void _printProjectSummary(dynamic report, Logger logger) {
    logger.panel(
      'Resumen de Proyecto',
      '''
Proyecto: ${report.projectName ?? 'N/A'}
Features: ${report.features.length}
Progreso: ${(report.overallProgress * 100).toStringAsFixed(0)}%
''',
    );
  }
}
