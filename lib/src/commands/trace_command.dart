import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dfspec/src/models/traceability.dart';
import 'package:dfspec/src/services/consistency_analyzer.dart';
import 'package:dfspec/src/utils/logger.dart';

/// Comando para análisis de trazabilidad y consistencia.
///
/// Genera la matriz de trazabilidad entre artefactos SDD:
/// REQ → US → AC → TASK → CODE → TEST
///
/// Detecta:
/// - Requisitos sin User Stories
/// - User Stories sin criterios de aceptación
/// - User Stories sin tareas
/// - Tareas sin implementación
/// - Código sin tests
///
/// Uso:
/// ```bash
/// dfspec trace <feature-id>
/// dfspec trace --all
/// dfspec trace user-auth --format=json
/// dfspec trace user-auth --export=matrix.html
/// ```
class TraceCommand extends Command<int> {
  /// Crea el comando trace.
  TraceCommand() {
    argParser
      ..addFlag(
        'all',
        abbr: 'a',
        help: 'Analiza todas las features del proyecto.',
        negatable: false,
      )
      ..addOption(
        'format',
        abbr: 'f',
        allowed: ['summary', 'matrix', 'json', 'markdown'],
        defaultsTo: 'summary',
        help: 'Formato de salida.',
      )
      ..addOption(
        'export',
        abbr: 'e',
        help: 'Exportar matriz a archivo (HTML, JSON, o Markdown).',
      )
      ..addFlag(
        'orphans-only',
        help: 'Mostrar solo artefactos huérfanos.',
        negatable: false,
      )
      ..addFlag(
        'issues-only',
        help: 'Mostrar solo issues de consistencia.',
        negatable: false,
      )
      ..addOption(
        'severity',
        allowed: ['all', 'critical', 'warning', 'info'],
        defaultsTo: 'all',
        help: 'Filtrar issues por severidad.',
      )
      ..addFlag(
        'ci',
        help: 'Modo CI: falla si hay issues críticos.',
        negatable: false,
      );
  }

  @override
  String get name => 'trace';

  @override
  String get description => 'Genera matriz de trazabilidad y analiza consistencia SDD.';

  @override
  String get invocation => 'dfspec trace <feature-id> [opciones]';

  @override
  Future<int> run() async {
    const logger = Logger();
    final all = argResults!['all'] as bool;
    final format = argResults!['format'] as String;
    final exportPath = argResults!['export'] as String?;
    final orphansOnly = argResults!['orphans-only'] as bool;
    final issuesOnly = argResults!['issues-only'] as bool;
    final severity = argResults!['severity'] as String;
    final ci = argResults!['ci'] as bool;

    if (!all && argResults!.rest.isEmpty) {
      logger.error('Debe especificar un feature-id o usar --all');
      logger.info('Uso: dfspec trace <feature-id>');
      logger.info('     dfspec trace --all');
      return 1;
    }

    try {
      final analyzer = ConsistencyAnalyzer(projectRoot: Directory.current.path);
      final reports = <ConsistencyReport>[];

      if (all) {
        // Analizar todas las features
        final features = await _discoverFeatures();
        if (features.isEmpty) {
          logger.warning('No se encontraron features en specs/features/');
          return 0;
        }

        for (final featureId in features) {
          final report = await analyzer.analyze(featureId);
          reports.add(report);
        }
      } else {
        // Analizar feature específica
        final featureId = argResults!.rest.first;
        final report = await analyzer.analyze(featureId);
        reports.add(report);
      }

      // Filtrar por severidad si es necesario
      final filteredReports = _filterBySeverity(reports, severity);

      // Output según formato
      if (exportPath != null) {
        await _exportReport(filteredReports, exportPath, logger);
      } else {
        _outputReports(
          filteredReports,
          format,
          orphansOnly,
          issuesOnly,
          logger,
        );
      }

      // Evaluar resultado para CI
      final hasCritical = reports.any(
        (r) => r.issues.any((i) => i.severity == IssueSeverity.critical),
      );

      if (ci && hasCritical) {
        logger.error('CI: Se encontraron issues críticos');
        return 1;
      }

      return 0;
    } catch (e) {
      logger.error('Error en análisis de trazabilidad: $e');
      return 1;
    }
  }

  Future<List<String>> _discoverFeatures() async {
    final featuresDir = Directory('${Directory.current.path}/specs/features');
    if (!await featuresDir.exists()) return [];

    final features = <String>[];
    await for (final entity in featuresDir.list()) {
      if (entity is Directory) {
        final name = entity.path.split('/').last;
        if (!name.startsWith('.')) {
          features.add(name);
        }
      }
    }
    return features..sort();
  }

  List<ConsistencyReport> _filterBySeverity(
    List<ConsistencyReport> reports,
    String severity,
  ) {
    if (severity == 'all') return reports;

    final targetSeverity = switch (severity) {
      'critical' => IssueSeverity.critical,
      'warning' => IssueSeverity.warning,
      'info' => IssueSeverity.info,
      _ => null,
    };

    if (targetSeverity == null) return reports;

    return reports.map((r) {
      final filteredIssues = r.issues
          .where((i) => i.severity == targetSeverity)
          .toList();
      return ConsistencyReport(
        matrix: r.matrix,
        issues: filteredIssues,
        suggestions: r.suggestions,
      );
    }).toList();
  }

  void _outputReports(
    List<ConsistencyReport> reports,
    String format,
    bool orphansOnly,
    bool issuesOnly,
    Logger logger,
  ) {
    switch (format) {
      case 'json':
        _outputJson(reports, logger);

      case 'markdown':
        _outputMarkdown(reports, logger);

      case 'matrix':
        _outputMatrix(reports, logger);

      case 'summary':
      default:
        _outputSummary(reports, orphansOnly, issuesOnly, logger);
    }
  }

  void _outputSummary(
    List<ConsistencyReport> reports,
    bool orphansOnly,
    bool issuesOnly,
    Logger logger,
  ) {
    for (final report in reports) {
      final matrix = report.matrix;

      logger.title('Trazabilidad: ${matrix.featureId}');
      logger.blank();

      if (!orphansOnly && !issuesOnly) {
        // Resumen de artefactos
        logger.section('Artefactos');
        final headers = ['Tipo', 'Total', 'Cubiertos', 'Parciales', 'Huérfanos'];
        final rows = <List<String>>[];

        for (final type in ArtifactType.values) {
          final artifacts = matrix.byType(type);
          if (artifacts.isEmpty) continue;

          final covered = artifacts
              .where((a) => matrix.getCoverageStatus(a) == CoverageStatus.covered)
              .length;
          final partial = artifacts
              .where((a) => matrix.getCoverageStatus(a) == CoverageStatus.partial)
              .length;
          final orphan = artifacts
              .where((a) => matrix.getCoverageStatus(a) == CoverageStatus.orphan)
              .length;

          rows.add([
            type.prefix,
            artifacts.length.toString(),
            covered.toString(),
            partial.toString(),
            orphan.toString(),
          ]);
        }

        logger.table(headers, rows);
        logger.blank();

        // Score y cobertura
        logger.info('Cobertura: ${matrix.coveragePercentage.toStringAsFixed(1)}%');
        logger.info('Score de consistencia: ${report.score}/100');
        logger.info('Estado: ${report.passed ? "APROBADO" : "FALLIDO"}');
        logger.blank();
      }

      // Mostrar huérfanos
      if (orphansOnly || (!issuesOnly && matrix.orphanArtifacts.isNotEmpty)) {
        logger.section('Artefactos Huérfanos');
        for (final artifact in matrix.orphanArtifacts) {
          logger.warning('  ${artifact.type.prefix}-${artifact.id}: ${artifact.title}');
          logger.info('    Ubicación: ${artifact.location}');
        }
        logger.blank();
      }

      // Mostrar issues
      if (issuesOnly || (!orphansOnly && report.issues.isNotEmpty)) {
        logger.section('Issues de Consistencia');
        for (final issue in report.issues) {
          final icon = switch (issue.severity) {
            IssueSeverity.critical => '❌',
            IssueSeverity.warning => '⚠️',
            IssueSeverity.info => 'ℹ️',
          };
          logger.info('$icon [${issue.code}] ${issue.message}');
          if (issue.suggestion != null) {
            logger.info('   Sugerencia: ${issue.suggestion}');
          }
        }
        logger.blank();
      }

      // Sugerencias
      if (!orphansOnly && !issuesOnly && report.suggestions.isNotEmpty) {
        logger.section('Sugerencias');
        for (final suggestion in report.suggestions) {
          logger.info('  → $suggestion');
        }
        logger.blank();
      }
    }
  }

  void _outputMatrix(List<ConsistencyReport> reports, Logger logger) {
    for (final report in reports) {
      final matrix = report.matrix;

      logger.title('Matriz de Trazabilidad: ${matrix.featureId}');
      logger.blank();

      // Crear tabla de trazabilidad
      final headers = ['Origen', 'Destino', 'Tipo Link', 'Verificado'];
      final rows = matrix.links.map((link) {
        return [
          '${link.source.type.prefix}-${link.source.id}',
          '${link.target.type.prefix}-${link.target.id}',
          link.linkType.name,
          if (link.isVerified) 'Si' else 'No',
        ];
      }).toList();

      if (rows.isEmpty) {
        logger.warning('No se encontraron links de trazabilidad.');
      } else {
        logger.table(headers, rows);
      }

      logger.blank();
      logger.info('Total links: ${matrix.links.length}');
      logger.info('Total artefactos: ${matrix.artifacts.length}');
    }
  }

  void _outputJson(List<ConsistencyReport> reports, Logger logger) {
    final json = reports.length == 1
        ? reports.first.toJson()
        : reports.map((r) => r.toJson()).toList();

    // ignore: avoid_print
    print(const JsonEncoder.withIndent('  ').convert(json));
  }

  void _outputMarkdown(List<ConsistencyReport> reports, Logger logger) {
    final buffer = StringBuffer();

    for (final report in reports) {
      final matrix = report.matrix;

      buffer.writeln('# Matriz de Trazabilidad: ${matrix.featureId}');
      buffer.writeln();
      buffer.writeln('Generado: ${matrix.generatedAt.toIso8601String()}');
      buffer.writeln();

      // Resumen
      buffer.writeln('## Resumen');
      buffer.writeln();
      buffer.writeln('| Métrica | Valor |');
      buffer.writeln('|---------|-------|');
      buffer.writeln('| Cobertura | ${matrix.coveragePercentage.toStringAsFixed(1)}% |');
      buffer.writeln('| Score | ${report.score}/100 |');
      buffer.writeln('| Estado | ${report.passed ? "APROBADO" : "FALLIDO"} |');
      buffer.writeln('| Artefactos | ${matrix.artifacts.length} |');
      buffer.writeln('| Links | ${matrix.links.length} |');
      buffer.writeln('| Issues | ${report.issues.length} |');
      buffer.writeln();

      // Artefactos por tipo
      buffer.writeln('## Artefactos');
      buffer.writeln();
      buffer.writeln('| Tipo | Total | Cubiertos | Huérfanos |');
      buffer.writeln('|------|-------|-----------|-----------|');

      for (final type in ArtifactType.values) {
        final artifacts = matrix.byType(type);
        if (artifacts.isEmpty) continue;

        final covered = artifacts
            .where((a) => matrix.getCoverageStatus(a) == CoverageStatus.covered)
            .length;
        final orphan = artifacts
            .where((a) => matrix.getCoverageStatus(a) == CoverageStatus.orphan)
            .length;

        buffer.writeln('| ${type.prefix} | ${artifacts.length} | $covered | $orphan |');
      }

      buffer.writeln();

      // Issues
      if (report.issues.isNotEmpty) {
        buffer.writeln('## Issues');
        buffer.writeln();

        for (final issue in report.issues) {
          final severity = issue.severity.name.toUpperCase();
          buffer.writeln('### [$severity] ${issue.code}');
          buffer.writeln();
          buffer.writeln(issue.message);
          if (issue.suggestion != null) {
            buffer.writeln();
            buffer.writeln('**Sugerencia:** ${issue.suggestion}');
          }
          buffer.writeln();
        }
      }

      // Sugerencias
      if (report.suggestions.isNotEmpty) {
        buffer.writeln('## Sugerencias');
        buffer.writeln();
        for (final suggestion in report.suggestions) {
          buffer.writeln('- $suggestion');
        }
        buffer.writeln();
      }
    }

    // ignore: avoid_print
    print(buffer);
  }

  Future<void> _exportReport(
    List<ConsistencyReport> reports,
    String path,
    Logger logger,
  ) async {
    final extension = path.split('.').last.toLowerCase();
    String content;

    switch (extension) {
      case 'json':
        final json = reports.length == 1
            ? reports.first.toJson()
            : reports.map((r) => r.toJson()).toList();
        content = const JsonEncoder.withIndent('  ').convert(json);

      case 'html':
        content = _generateHtmlReport(reports);

      case 'md':
      case 'markdown':
        final buffer = StringBuffer();
        _outputMarkdownToBuffer(reports, buffer);
        content = buffer.toString();

      default:
        logger.error('Formato de exportación no soportado: $extension');
        logger.info('Formatos soportados: .json, .html, .md');
        return;
    }

    await File(path).writeAsString(content);
    logger.success('Reporte exportado a: $path');
  }

  void _outputMarkdownToBuffer(List<ConsistencyReport> reports, StringBuffer buffer) {
    for (final report in reports) {
      final matrix = report.matrix;

      buffer.writeln('# Matriz de Trazabilidad: ${matrix.featureId}');
      buffer.writeln();
      buffer.writeln('Generado: ${matrix.generatedAt.toIso8601String()}');
      buffer.writeln();

      buffer.writeln('## Resumen');
      buffer.writeln();
      buffer.writeln('- Cobertura: ${matrix.coveragePercentage.toStringAsFixed(1)}%');
      buffer.writeln('- Score: ${report.score}/100');
      buffer.writeln('- Estado: ${report.passed ? "APROBADO" : "FALLIDO"}');
      buffer.writeln();
    }
  }

  String _generateHtmlReport(List<ConsistencyReport> reports) {
    final buffer = StringBuffer();

    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="es">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>Matriz de Trazabilidad - DFSpec</title>');
    buffer.writeln('  <style>');
    buffer.writeln('    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; margin: 2rem; }');
    buffer.writeln('    h1 { color: #1a1a1a; border-bottom: 2px solid #0066cc; padding-bottom: 0.5rem; }');
    buffer.writeln('    h2 { color: #333; margin-top: 2rem; }');
    buffer.writeln('    table { border-collapse: collapse; width: 100%; margin: 1rem 0; }');
    buffer.writeln('    th, td { border: 1px solid #ddd; padding: 0.75rem; text-align: left; }');
    buffer.writeln('    th { background-color: #f5f5f5; font-weight: 600; }');
    buffer.writeln('    tr:nth-child(even) { background-color: #fafafa; }');
    buffer.writeln('    .passed { color: #28a745; font-weight: bold; }');
    buffer.writeln('    .failed { color: #dc3545; font-weight: bold; }');
    buffer.writeln('    .critical { background-color: #ffebee; }');
    buffer.writeln('    .warning { background-color: #fff8e1; }');
    buffer.writeln('    .info { background-color: #e3f2fd; }');
    buffer.writeln('    .score { font-size: 2rem; font-weight: bold; }');
    buffer.writeln('    .summary-box { display: flex; gap: 2rem; margin: 1rem 0; }');
    buffer.writeln('    .summary-item { padding: 1rem; border-radius: 8px; background: #f5f5f5; }');
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    for (final report in reports) {
      final matrix = report.matrix;

      buffer.writeln('<h1>Matriz de Trazabilidad: ${matrix.featureId}</h1>');
      buffer.writeln('<p>Generado: ${matrix.generatedAt.toIso8601String()}</p>');

      // Resumen
      buffer.writeln('<div class="summary-box">');
      buffer.writeln('  <div class="summary-item">');
      buffer.writeln('    <div>Cobertura</div>');
      buffer.writeln('    <div class="score">${matrix.coveragePercentage.toStringAsFixed(1)}%</div>');
      buffer.writeln('  </div>');
      buffer.writeln('  <div class="summary-item">');
      buffer.writeln('    <div>Score</div>');
      buffer.writeln('    <div class="score">${report.score}</div>');
      buffer.writeln('  </div>');
      buffer.writeln('  <div class="summary-item">');
      buffer.writeln('    <div>Estado</div>');
      buffer.writeln('    <div class="${report.passed ? 'passed' : 'failed'}">${report.passed ? 'APROBADO' : 'FALLIDO'}</div>');
      buffer.writeln('  </div>');
      buffer.writeln('</div>');

      // Tabla de artefactos
      buffer.writeln('<h2>Artefactos</h2>');
      buffer.writeln('<table>');
      buffer.writeln('<tr><th>Tipo</th><th>Total</th><th>Cubiertos</th><th>Parciales</th><th>Huérfanos</th></tr>');

      for (final type in ArtifactType.values) {
        final artifacts = matrix.byType(type);
        if (artifacts.isEmpty) continue;

        final covered = artifacts
            .where((a) => matrix.getCoverageStatus(a) == CoverageStatus.covered)
            .length;
        final partial = artifacts
            .where((a) => matrix.getCoverageStatus(a) == CoverageStatus.partial)
            .length;
        final orphan = artifacts
            .where((a) => matrix.getCoverageStatus(a) == CoverageStatus.orphan)
            .length;

        buffer.writeln('<tr><td>${type.prefix}</td><td>${artifacts.length}</td><td>$covered</td><td>$partial</td><td>$orphan</td></tr>');
      }

      buffer.writeln('</table>');

      // Tabla de links
      if (matrix.links.isNotEmpty) {
        buffer.writeln('<h2>Links de Trazabilidad</h2>');
        buffer.writeln('<table>');
        buffer.writeln('<tr><th>Origen</th><th>Destino</th><th>Tipo</th></tr>');

        for (final link in matrix.links) {
          buffer.writeln('<tr><td>${link.source.type.prefix}-${link.source.id}</td><td>${link.target.type.prefix}-${link.target.id}</td><td>${link.linkType.name}</td></tr>');
        }

        buffer.writeln('</table>');
      }

      // Issues
      if (report.issues.isNotEmpty) {
        buffer.writeln('<h2>Issues</h2>');
        buffer.writeln('<table>');
        buffer.writeln('<tr><th>Severidad</th><th>Código</th><th>Mensaje</th><th>Sugerencia</th></tr>');

        for (final issue in report.issues) {
          final cssClass = issue.severity.name;
          buffer.writeln('<tr class="$cssClass"><td>${issue.severity.name.toUpperCase()}</td><td>${issue.code}</td><td>${issue.message}</td><td>${issue.suggestion ?? '-'}</td></tr>');
        }

        buffer.writeln('</table>');
      }
    }

    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }
}
