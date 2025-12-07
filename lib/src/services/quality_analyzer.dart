import 'dart:io';

import 'package:dfspec/src/models/quality_metrics.dart';

/// Analizador de métricas de calidad de código.
///
/// Calcula métricas de complejidad, cobertura, mantenibilidad
/// y documentación para proyectos Dart/Flutter.
class QualityAnalyzer {
  /// Crea un analizador.
  QualityAnalyzer({
    required this.projectRoot,
    this.customThresholds = const {},
  });

  /// Directorio raíz del proyecto.
  final String projectRoot;

  /// Umbrales personalizados (override de defaults).
  final Map<String, MetricThreshold> customThresholds;

  /// Analiza el proyecto completo y genera reporte.
  Future<QualityReport> analyze({
    String? context,
    List<String>? paths,
  }) async {
    final metrics = <QualityMetric>[];

    // Obtener archivos Dart
    final files = await _getDartFiles(paths);
    if (files.isEmpty) {
      return QualityReport.empty();
    }

    // Calcular métricas
    metrics.add(await _calculateLinesMetric(files));
    metrics.add(await _calculateComplexityMetric(files));
    metrics.add(await _calculateDocumentationMetric(files));
    metrics.add(await _calculateDuplicationMetric(files));

    return QualityReport(
      metrics: metrics,
      timestamp: DateTime.now(),
      context: context,
      projectName: _extractProjectName(),
    );
  }

  /// Analiza solo métricas de complejidad.
  Future<QualityReport> analyzeComplexity({List<String>? paths}) async {
    final files = await _getDartFiles(paths);
    final metrics = <QualityMetric>[
      await _calculateComplexityMetric(files),
      await _calculateLinesMetric(files),
    ];

    return QualityReport(
      metrics: metrics,
      timestamp: DateTime.now(),
      context: 'complexity',
    );
  }

  /// Analiza solo métricas de documentación.
  Future<QualityReport> analyzeDocumentation({List<String>? paths}) async {
    final files = await _getDartFiles(paths);
    final metrics = <QualityMetric>[
      await _calculateDocumentationMetric(files),
    ];

    return QualityReport(
      metrics: metrics,
      timestamp: DateTime.now(),
      context: 'documentation',
    );
  }

  /// Obtiene archivos Dart del proyecto.
  Future<List<File>> _getDartFiles(List<String>? paths) async {
    final files = <File>[];

    if (paths != null && paths.isNotEmpty) {
      for (final path in paths) {
        final fullPath = path.startsWith('/') ? path : '$projectRoot/$path';
        final entity = FileSystemEntity.typeSync(fullPath);

        if (entity == FileSystemEntityType.file && path.endsWith('.dart')) {
          files.add(File(fullPath));
        } else if (entity == FileSystemEntityType.directory) {
          files.addAll(await _findDartFiles(Directory(fullPath)));
        }
      }
    } else {
      // Analizar lib/ por defecto
      final libDir = Directory('$projectRoot/lib');
      if (await libDir.exists()) {
        files.addAll(await _findDartFiles(libDir));
      }
    }

    return files;
  }

  /// Busca archivos Dart recursivamente.
  Future<List<File>> _findDartFiles(Directory dir) async {
    final files = <File>[];

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        // Excluir archivos generados
        if (!entity.path.endsWith('.g.dart') &&
            !entity.path.endsWith('.freezed.dart') &&
            !entity.path.endsWith('.mocks.dart')) {
          files.add(entity);
        }
      }
    }

    return files;
  }

  /// Calcula métrica de líneas por archivo.
  Future<QualityMetric> _calculateLinesMetric(List<File> files) async {
    if (files.isEmpty) {
      return QualityMetrics.linesPerFile(0);
    }

    var totalLines = 0;
    final largeFiles = <String>[];
    const maxLines = 400;

    for (final file in files) {
      final content = await file.readAsString();
      final lines = content.split('\n').length;
      totalLines += lines;

      if (lines > maxLines) {
        largeFiles.add('${_relativePath(file.path)}: $lines líneas');
      }
    }

    final average = totalLines / files.length;

    return QualityMetrics.linesPerFile(average, files: largeFiles);
  }

  /// Calcula métrica de complejidad.
  Future<QualityMetric> _calculateComplexityMetric(List<File> files) async {
    if (files.isEmpty) {
      return QualityMetrics.cyclomaticComplexity(0);
    }

    var totalComplexity = 0;
    var functionCount = 0;
    final complexFiles = <String>[];

    for (final file in files) {
      final content = await file.readAsString();
      final complexity = _calculateCyclomaticComplexity(content);

      totalComplexity += complexity.total;
      functionCount += complexity.functionCount;

      if (complexity.max > 10) {
        complexFiles.add(
          '${_relativePath(file.path)}: complejidad máx ${complexity.max}',
        );
      }
    }

    final average = functionCount > 0 ? totalComplexity / functionCount : 0.0;

    return QualityMetrics.cyclomaticComplexity(average, files: complexFiles);
  }

  /// Calcula métrica de documentación.
  Future<QualityMetric> _calculateDocumentationMetric(List<File> files) async {
    if (files.isEmpty) {
      return QualityMetrics.documentation(1);
    }

    var documented = 0;
    var total = 0;
    final undocumented = <String>[];

    for (final file in files) {
      // Solo analizar archivos públicos (no empiezan con _)
      final filename = file.path.split('/').last;
      if (filename.startsWith('_')) continue;

      final content = await file.readAsString();
      final result = _analyzeDocumentation(content);

      documented += result.documented;
      total += result.total;

      for (final item in result.undocumented) {
        undocumented.add('${_relativePath(file.path)}: $item');
      }
    }

    final ratio = total > 0 ? documented / total : 1.0;

    return QualityMetrics.documentation(
      ratio,
      undocumented: undocumented.take(10).toList(),
    );
  }

  /// Calcula métrica de duplicación (simplificada).
  Future<QualityMetric> _calculateDuplicationMetric(List<File> files) async {
    if (files.isEmpty) {
      return QualityMetrics.duplication(0);
    }

    // Implementación simplificada: buscar bloques repetidos
    final allLines = <String, int>{};
    var totalLines = 0;
    var duplicatedLines = 0;
    final locations = <String>[];

    for (final file in files) {
      final content = await file.readAsString();
      final lines = content.split('\n');

      for (var i = 0; i < lines.length - 3; i++) {
        // Bloques de 4 líneas
        final block = lines.skip(i).take(4).join('\n').trim();

        // Ignorar bloques vacíos o muy cortos
        if (block.length < 50) continue;
        // Ignorar imports y comentarios
        if (block.startsWith('import') || block.startsWith('//')) continue;

        totalLines++;

        if (allLines.containsKey(block)) {
          duplicatedLines++;
          if (locations.length < 5) {
            locations.add('${_relativePath(file.path)}:${i + 1}');
          }
        } else {
          allLines[block] = i;
        }
      }
    }

    final ratio = totalLines > 0 ? duplicatedLines / totalLines : 0.0;

    return QualityMetrics.duplication(ratio, locations: locations);
  }

  /// Calcula complejidad ciclomática de un archivo.
  _ComplexityResult _calculateCyclomaticComplexity(String content) {
    // Patrones que incrementan complejidad
    final patterns = [
      RegExp(r'\bif\s*\('),
      RegExp(r'\belse\s+if\s*\('),
      RegExp(r'\bwhile\s*\('),
      RegExp(r'\bfor\s*\('),
      RegExp(r'\bcase\s+'),
      RegExp(r'\bcatch\s*\('),
      RegExp(r'\?\?'),
      RegExp(r'\?\s*:'), // Ternario
      RegExp('&&'),
      RegExp(r'\|\|'),
    ];

    var total = 0;
    var max = 0;
    var functionCount = 0;

    // Dividir por funciones/métodos (simplificado)
    final functionPattern = RegExp(
      r'(?:void|Future|Stream|[\w<>]+)\s+\w+\s*\([^)]*\)\s*(?:async\s*)?\{',
    );

    final functions = functionPattern.allMatches(content);
    functionCount = functions.length;

    if (functionCount == 0) {
      return _ComplexityResult(total: 1, max: 1, functionCount: 1);
    }

    // Calcular complejidad de todo el archivo (simplificado)
    for (final pattern in patterns) {
      total += pattern.allMatches(content).length;
    }

    // Complejidad base de 1 por función
    total += functionCount;
    max = total ~/ functionCount + 2;

    return _ComplexityResult(
      total: total,
      max: max,
      functionCount: functionCount,
    );
  }

  /// Analiza documentación de un archivo.
  _DocumentationResult _analyzeDocumentation(String content) {
    var documented = 0;
    var total = 0;
    final undocumented = <String>[];

    // Patrones de declaraciones públicas
    final patterns = [
      (
        RegExp(r'^class\s+(\w+)', multiLine: true),
        'class',
      ),
      (
        RegExp(r'^\s*(?:static\s+)?(?:const\s+)?(\w+)\s+(\w+)\s*[=;]', multiLine: true),
        'field',
      ),
      (
        RegExp(r'^\s*(?:Future|void|[\w<>]+)\s+(\w+)\s*\(', multiLine: true),
        'method',
      ),
    ];

    for (final (pattern, type) in patterns) {
      final matches = pattern.allMatches(content);

      for (final match in matches) {
        final name = match.group(1) ?? match.group(2) ?? '';

        // Ignorar privados y generados
        if (name.startsWith('_')) continue;
        if (name == 'build' || name == 'main') continue;

        total++;

        // Verificar si tiene doc comment antes
        final start = match.start;
        final before = content.substring(0, start);
        final lastNewline = before.lastIndexOf('\n');
        final linesBefore = before.substring(
          lastNewline > 50 ? lastNewline - 50 : 0,
          lastNewline > 0 ? lastNewline : start,
        );

        if (linesBefore.contains('///')) {
          documented++;
        } else {
          if (undocumented.length < 5) {
            undocumented.add('$type $name');
          }
        }
      }
    }

    return _DocumentationResult(
      documented: documented,
      total: total,
      undocumented: undocumented,
    );
  }

  /// Convierte ruta absoluta a relativa.
  String _relativePath(String path) {
    if (path.startsWith(projectRoot)) {
      return path.substring(projectRoot.length + 1);
    }
    return path;
  }

  /// Extrae nombre del proyecto del pubspec.
  String? _extractProjectName() {
    try {
      final pubspec = File('$projectRoot/pubspec.yaml');
      if (pubspec.existsSync()) {
        final content = pubspec.readAsStringSync();
        final match = RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(content);
        return match?.group(1);
      }
    } catch (_) {}
    return null;
  }
}

/// Resultado de cálculo de complejidad.
class _ComplexityResult {
  _ComplexityResult({
    required this.total,
    required this.max,
    required this.functionCount,
  });

  final int total;
  final int max;
  final int functionCount;
}

/// Resultado de análisis de documentación.
class _DocumentationResult {
  _DocumentationResult({
    required this.documented,
    required this.total,
    required this.undocumented,
  });

  final int documented;
  final int total;
  final List<String> undocumented;
}
