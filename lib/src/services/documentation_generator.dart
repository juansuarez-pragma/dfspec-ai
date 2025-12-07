import 'dart:io';

import 'package:dfspec/src/models/documentation_spec.dart';

/// Generador de documentación automática.
///
/// Genera documentación en formato Markdown basándose en
/// especificaciones y análisis del código fuente.
class DocumentationGenerator {
  /// Crea un generador.
  DocumentationGenerator({
    required this.projectRoot,
  });

  /// Directorio raíz del proyecto.
  final String projectRoot;

  /// Genera documentación desde una especificación.
  Future<DocumentationResult> generate(DocumentationSpec spec) async {
    final content = spec.generate();
    final outputPath = spec.outputPath ?? _defaultOutputPath(spec);
    final fullPath = '$projectRoot/$outputPath';

    // Crear directorio si no existe
    final dir = Directory(fullPath).parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Escribir archivo
    await File(fullPath).writeAsString(content);

    return DocumentationResult(
      spec: spec,
      content: content,
      outputPath: outputPath,
    );
  }

  /// Genera README de feature desde el código.
  Future<DocumentationResult> generateFeatureReadme({
    required String featureName,
    String? description,
  }) async {
    // Buscar archivos de la feature
    final featureFiles = await _findFeatureFiles(featureName);
    final components = await _extractComponents(featureFiles);
    final useCases = await _extractUseCases(featureFiles);

    final spec = DocumentationTemplates.featureReadme(
      featureName: featureName,
      description: description ?? 'Feature $featureName',
      useCases: useCases,
      components: components,
    );

    return generate(spec);
  }

  /// Genera documentación de arquitectura.
  Future<DocumentationResult> generateArchitecture({
    String? projectName,
  }) async {
    final name = projectName ?? await _extractProjectName() ?? 'Project';
    final layers = await _analyzeLayers();

    final spec = DocumentationTemplates.architecture(
      projectName: name,
      layers: layers,
    );

    return generate(spec);
  }

  /// Genera changelog entry.
  Future<DocumentationResult> generateChangelog({
    required String version,
    List<String> added = const [],
    List<String> changed = const [],
    List<String> fixed = const [],
    List<String> removed = const [],
    bool append = true,
  }) async {
    final spec = DocumentationTemplates.changelog(
      version: version,
      date: DateTime.now(),
      added: added,
      changed: changed,
      fixed: fixed,
      removed: removed,
    );

    if (append) {
      return _appendToChangelog(spec);
    }

    return generate(spec);
  }

  /// Genera especificación de feature.
  Future<DocumentationResult> generateFeatureSpec({
    required String featureName,
    required String description,
    required List<String> acceptanceCriteria,
    List<String> outOfScope = const [],
  }) async {
    final spec = DocumentationTemplates.featureSpec(
      featureName: featureName,
      description: description,
      acceptanceCriteria: acceptanceCriteria,
      outOfScope: outOfScope,
    );

    return generate(spec);
  }

  /// Genera plan de implementación.
  Future<DocumentationResult> generateImplementationPlan({
    required String featureName,
    required List<ImplementationStep> steps,
  }) async {
    final spec = DocumentationTemplates.implementationPlan(
      featureName: featureName,
      steps: steps,
    );

    return generate(spec);
  }

  /// Genera dartdoc para un archivo.
  Future<String> generateApiDoc(String filePath) async {
    final file = File('$projectRoot/$filePath');
    if (!await file.exists()) {
      throw FileSystemException('Archivo no encontrado', filePath);
    }

    final content = await file.readAsString();
    final documented = _addMissingDocs(content);

    return documented;
  }

  /// Verifica documentación y genera reporte.
  Future<DocumentationReport> verifyDocumentation({
    List<String>? paths,
  }) async {
    final files = await _getDartFiles(paths);
    final issues = <DocumentationIssue>[];
    var documented = 0;
    var total = 0;

    for (final file in files) {
      final content = await file.readAsString();
      final fileIssues = _checkDocumentation(content, file.path);
      issues.addAll(fileIssues);

      final stats = _countDocumented(content);
      documented += stats.documented;
      total += stats.total;
    }

    return DocumentationReport(
      filesAnalyzed: files.length,
      documented: documented,
      total: total,
      issues: issues,
    );
  }

  /// Busca archivos de una feature.
  Future<List<File>> _findFeatureFiles(String featureName) async {
    final files = <File>[];
    final searchDirs = [
      '$projectRoot/lib/src/domain',
      '$projectRoot/lib/src/data',
      '$projectRoot/lib/src/presentation',
    ];

    for (final dirPath in searchDirs) {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File &&
              entity.path.endsWith('.dart') &&
              entity.path.toLowerCase().contains(featureName.toLowerCase())) {
            files.add(entity);
          }
        }
      }
    }

    return files;
  }

  /// Extrae componentes de archivos.
  Future<List<String>> _extractComponents(List<File> files) async {
    final components = <String>[];

    for (final file in files) {
      final content = await file.readAsString();
      final classPattern = RegExp(r'class\s+(\w+)');

      for (final match in classPattern.allMatches(content)) {
        final className = match.group(1);
        if (className != null && !className.startsWith('_')) {
          components.add(className);
        }
      }
    }

    return components;
  }

  /// Extrae usecases de archivos.
  Future<List<String>> _extractUseCases(List<File> files) async {
    final useCases = <String>[];

    for (final file in files) {
      if (file.path.contains('usecase')) {
        final content = await file.readAsString();
        final classPattern = RegExp(r'class\s+(\w+)');

        for (final match in classPattern.allMatches(content)) {
          final className = match.group(1);
          if (className != null && !className.startsWith('_')) {
            // Convertir CamelCase a descripción
            final description = className
                .replaceAllMapped(
                  RegExp('([A-Z])'),
                  (m) => ' ${m.group(1)}',
                )
                .trim();
            useCases.add(description);
          }
        }
      }
    }

    return useCases;
  }

  /// Analiza las capas del proyecto.
  Future<Map<String, String>> _analyzeLayers() async {
    final layers = <String, String>{};

    final domainDir = Directory('$projectRoot/lib/src/domain');
    if (await domainDir.exists()) {
      final domainFiles = await _countFilesIn(domainDir);
      layers['Domain'] = '''
Capa de dominio con $domainFiles archivos.
- Entidades inmutables
- Interfaces de repositorios
- Casos de uso
''';
    }

    final dataDir = Directory('$projectRoot/lib/src/data');
    if (await dataDir.exists()) {
      final dataFiles = await _countFilesIn(dataDir);
      layers['Data'] = '''
Capa de datos con $dataFiles archivos.
- Modelos con serialización
- Implementaciones de repositorios
- Datasources
''';
    }

    final presentationDir = Directory('$projectRoot/lib/src/presentation');
    if (await presentationDir.exists()) {
      final presentationFiles = await _countFilesIn(presentationDir);
      layers['Presentation'] = '''
Capa de presentación con $presentationFiles archivos.
- Páginas y pantallas
- Widgets reutilizables
- State management
''';
    }

    return layers;
  }

  /// Cuenta archivos en directorio.
  Future<int> _countFilesIn(Directory dir) async {
    var count = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        count++;
      }
    }
    return count;
  }

  /// Extrae nombre del proyecto.
  Future<String?> _extractProjectName() async {
    try {
      final pubspec = File('$projectRoot/pubspec.yaml');
      if (await pubspec.exists()) {
        final content = await pubspec.readAsString();
        final match =
            RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(content);
        return match?.group(1);
      }
    } catch (_) {}
    return null;
  }

  /// Append a changelog existente.
  Future<DocumentationResult> _appendToChangelog(
    DocumentationSpec spec,
  ) async {
    final changelogPath = '$projectRoot/CHANGELOG.md';
    final changelogFile = File(changelogPath);

    String finalContent;

    if (await changelogFile.exists()) {
      final existing = await changelogFile.readAsString();
      final newEntry = spec.generate();

      // Insertar después del título principal
      final titleEnd = existing.indexOf('\n\n');
      if (titleEnd > 0) {
        finalContent =
            '${existing.substring(0, titleEnd + 2)}${newEntry.split('\n').skip(2).join('\n')}\n${existing.substring(titleEnd + 2)}';
      } else {
        finalContent = '$newEntry\n$existing';
      }
    } else {
      finalContent = spec.generate();
    }

    await changelogFile.writeAsString(finalContent);

    return DocumentationResult(
      spec: spec,
      content: finalContent,
      outputPath: 'CHANGELOG.md',
    );
  }

  /// Obtiene archivos Dart.
  Future<List<File>> _getDartFiles(List<String>? paths) async {
    final files = <File>[];

    if (paths != null && paths.isNotEmpty) {
      for (final path in paths) {
        final fullPath = '$projectRoot/$path';
        final entity = FileSystemEntity.typeSync(fullPath);

        if (entity == FileSystemEntityType.file && path.endsWith('.dart')) {
          files.add(File(fullPath));
        } else if (entity == FileSystemEntityType.directory) {
          await for (final f in Directory(fullPath).list(recursive: true)) {
            if (f is File && f.path.endsWith('.dart')) {
              files.add(f);
            }
          }
        }
      }
    } else {
      final libDir = Directory('$projectRoot/lib');
      if (await libDir.exists()) {
        await for (final f in libDir.list(recursive: true)) {
          if (f is File &&
              f.path.endsWith('.dart') &&
              !f.path.endsWith('.g.dart') &&
              !f.path.endsWith('.freezed.dart')) {
            files.add(f);
          }
        }
      }
    }

    return files;
  }

  /// Verifica documentación en contenido.
  List<DocumentationIssue> _checkDocumentation(String content, String path) {
    final issues = <DocumentationIssue>[];
    final lines = content.split('\n');

    // Patrones a verificar
    final classPattern = RegExp(r'^class\s+(\w+)');
    final methodPattern =
        RegExp(r'^\s*(?:Future|void|[\w<>]+)\s+(\w+)\s*\(');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Verificar clases
      final classMatch = classPattern.firstMatch(line);
      if (classMatch != null) {
        final className = classMatch.group(1)!;
        if (!className.startsWith('_')) {
          // Verificar si tiene doc comment
          if (i == 0 || !lines[i - 1].trimLeft().startsWith('///')) {
            issues.add(DocumentationIssue(
              path: path,
              line: i + 1,
              type: 'class',
              name: className,
              message: 'Clase sin documentación',
            ));
          }
        }
      }

      // Verificar métodos públicos
      final methodMatch = methodPattern.firstMatch(line);
      if (methodMatch != null) {
        final methodName = methodMatch.group(1)!;
        if (!methodName.startsWith('_') &&
            methodName != 'build' &&
            methodName != 'main') {
          if (i == 0 || !lines[i - 1].trimLeft().startsWith('///')) {
            issues.add(DocumentationIssue(
              path: path,
              line: i + 1,
              type: 'method',
              name: methodName,
              message: 'Método sin documentación',
            ));
          }
        }
      }
    }

    return issues;
  }

  /// Cuenta elementos documentados.
  _DocStats _countDocumented(String content) {
    var documented = 0;
    var total = 0;
    final lines = content.split('\n');

    final publicPattern =
        RegExp(r'^(?:class|abstract class|\s*(?:final|const)?\s*\w+\s+\w+)');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (publicPattern.hasMatch(line) && !line.startsWith('_')) {
        total++;
        if (i > 0 && lines[i - 1].trim().startsWith('///')) {
          documented++;
        }
      }
    }

    return _DocStats(documented: documented, total: total);
  }

  /// Agrega documentación faltante.
  String _addMissingDocs(String content) {
    final lines = content.split('\n');
    final result = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Verificar si necesita doc
      if (_needsDoc(line) && (i == 0 || !lines[i - 1].trimLeft().startsWith('///'))) {
        final docComment = _generateDocComment(line);
        if (docComment != null) {
          result.add(docComment);
        }
      }

      result.add(line);
    }

    return result.join('\n');
  }

  /// Verifica si una línea necesita documentación.
  bool _needsDoc(String line) {
    final trimmed = line.trim();
    if (trimmed.startsWith('_')) return false;

    return RegExp(r'^class\s+\w+').hasMatch(trimmed) ||
        RegExp(r'^abstract\s+class\s+\w+').hasMatch(trimmed) ||
        RegExp(r'^\s*(?:Future|void|[\w<>]+)\s+\w+\s*\(').hasMatch(line);
  }

  /// Genera comentario de documentación.
  String? _generateDocComment(String line) {
    final classMatch = RegExp(r'^class\s+(\w+)').firstMatch(line.trim());
    if (classMatch != null) {
      final name = classMatch.group(1)!;
      final readable = _toReadable(name);
      return '/// $readable.';
    }

    final methodMatch =
        RegExp(r'^\s*(?:Future|void|[\w<>]+)\s+(\w+)\s*\(').firstMatch(line);
    if (methodMatch != null) {
      final name = methodMatch.group(1)!;
      if (name != 'build' && name != 'main') {
        final readable = _toReadable(name);
        return '  /// $readable.';
      }
    }

    return null;
  }

  /// Convierte CamelCase a texto legible.
  String _toReadable(String name) {
    final spaced = name
        .replaceAllMapped(RegExp('([A-Z])'), (m) => ' ${m.group(1)!.toLowerCase()}')
        .trim();
    if (spaced.isEmpty) return name;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  /// Determina ruta de salida por defecto.
  String _defaultOutputPath(DocumentationSpec spec) {
    switch (spec.type) {
      case DocumentationType.readme:
        return 'README.md';
      case DocumentationType.changelog:
        return 'CHANGELOG.md';
      case DocumentationType.contributing:
        return 'CONTRIBUTING.md';
      case DocumentationType.architecture:
        return 'docs/ARCHITECTURE.md';
      case DocumentationType.api:
        return 'docs/API.md';
      case DocumentationType.specification:
        return 'docs/specs/${spec.title.toLowerCase().replaceAll(' ', '-')}.md';
      case DocumentationType.implementationPlan:
        return 'docs/plans/${spec.title.toLowerCase().replaceAll(' ', '-')}.md';
    }
  }
}

/// Issue de documentación encontrado.
class DocumentationIssue {
  /// Crea un issue.
  const DocumentationIssue({
    required this.path,
    required this.line,
    required this.type,
    required this.name,
    required this.message,
  });

  /// Ruta del archivo.
  final String path;

  /// Número de línea.
  final int line;

  /// Tipo (class, method, property).
  final String type;

  /// Nombre del elemento.
  final String name;

  /// Mensaje descriptivo.
  final String message;

  @override
  String toString() => '$path:$line - $type $name: $message';
}

/// Reporte de verificación de documentación.
class DocumentationReport {
  /// Crea un reporte.
  const DocumentationReport({
    required this.filesAnalyzed,
    required this.documented,
    required this.total,
    required this.issues,
  });

  /// Archivos analizados.
  final int filesAnalyzed;

  /// Elementos documentados.
  final int documented;

  /// Total de elementos.
  final int total;

  /// Issues encontrados.
  final List<DocumentationIssue> issues;

  /// Porcentaje de cobertura.
  double get coverage => total > 0 ? documented / total : 1.0;

  /// Si cumple el umbral (80%).
  bool get meetsThreshold => coverage >= 0.80;

  /// Genera resumen.
  String toSummary() {
    final buffer = StringBuffer();
    buffer.writeln('## Reporte de Documentación');
    buffer.writeln();
    buffer.writeln('**Archivos analizados:** $filesAnalyzed');
    buffer.writeln(
      '**Cobertura:** ${(coverage * 100).toStringAsFixed(1)}% ($documented/$total)',
    );
    buffer.writeln('**Estado:** ${meetsThreshold ? '✓ OK' : '⚠ Por debajo del umbral'}');
    buffer.writeln();

    if (issues.isNotEmpty) {
      buffer.writeln('### Issues Encontrados');
      buffer.writeln();
      for (final issue in issues.take(20)) {
        buffer.writeln('- $issue');
      }
      if (issues.length > 20) {
        buffer.writeln('- ... y ${issues.length - 20} más');
      }
    }

    return buffer.toString();
  }
}

class _DocStats {
  _DocStats({required this.documented, required this.total});
  final int documented;
  final int total;
}
