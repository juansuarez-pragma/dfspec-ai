/// Generador de reportes de features para DFSpec.
///
/// Este servicio analiza el código y genera reportes
/// detallados del estado de las features.
library;

import 'dart:io';

import 'package:dfspec/src/models/feature_report.dart';
import 'package:yaml/yaml.dart';

/// Generador de reportes de features.
class ReportGenerator {
  /// Crea un generador de reportes.
  ReportGenerator({required this.projectRoot});

  /// Directorio raíz del proyecto.
  final String projectRoot;

  /// Genera un reporte para una feature específica.
  Future<FeatureReport> generateFeatureReport(String featureName) async {
    final components = await _analyzeFeatureComponents(featureName);
    final metrics = FeatureMetrics.fromComponents(components);
    final issues = _detectIssues(components, metrics);
    final recommendations = _generateRecommendations(components, metrics);
    final status = _determineStatus(components, metrics);

    final specPath = await _findSpecPath(featureName);
    final planPath = await _findPlanPath(featureName);

    return FeatureReport(
      featureName: featureName,
      status: status,
      components: components,
      metrics: metrics,
      generatedAt: DateTime.now(),
      specPath: specPath,
      planPath: planPath,
      issues: issues,
      recommendations: recommendations,
    );
  }

  /// Genera un reporte del proyecto completo.
  Future<ProjectReport> generateProjectReport() async {
    final features = await _discoverFeatures();
    final reports = <FeatureReport>[];

    for (final feature in features) {
      reports.add(await generateFeatureReport(feature));
    }

    final projectName = await _getProjectName();
    final version = await _getProjectVersion();

    return ProjectReport(
      projectName: projectName,
      features: reports,
      generatedAt: DateTime.now(),
      version: version,
    );
  }

  /// Analiza los componentes de una feature.
  Future<List<FeatureComponent>> _analyzeFeatureComponents(
      String featureName) async {
    final components = <FeatureComponent>[];

    // Buscar archivos relacionados con la feature
    final featurePattern = featureName.replaceAll('-', '_').toLowerCase();

    // Analizar Domain
    final domainDir = Directory('$projectRoot/lib/src/domain');
    if (await domainDir.exists()) {
      await for (final file in domainDir.list(recursive: true)) {
        if (file is File && file.path.endsWith('.dart')) {
          final fileName = file.path.split('/').last.replaceAll('.dart', '');
          if (_matchesFeature(fileName, featurePattern)) {
            components.add(await _analyzeFile(
              file,
              ArchitectureLayer.domain,
              _determineComponentType(fileName, ArchitectureLayer.domain),
            ));
          }
        }
      }
    }

    // Analizar Data
    final dataDir = Directory('$projectRoot/lib/src/data');
    if (await dataDir.exists()) {
      await for (final file in dataDir.list(recursive: true)) {
        if (file is File && file.path.endsWith('.dart')) {
          final fileName = file.path.split('/').last.replaceAll('.dart', '');
          if (_matchesFeature(fileName, featurePattern)) {
            components.add(await _analyzeFile(
              file,
              ArchitectureLayer.data,
              _determineComponentType(fileName, ArchitectureLayer.data),
            ));
          }
        }
      }
    }

    // Analizar Presentation
    final presentationDir = Directory('$projectRoot/lib/src/presentation');
    if (await presentationDir.exists()) {
      await for (final file in presentationDir.list(recursive: true)) {
        if (file is File && file.path.endsWith('.dart')) {
          final fileName = file.path.split('/').last.replaceAll('.dart', '');
          if (_matchesFeature(fileName, featurePattern)) {
            components.add(await _analyzeFile(
              file,
              ArchitectureLayer.presentation,
              _determineComponentType(fileName, ArchitectureLayer.presentation),
            ));
          }
        }
      }
    }

    return components;
  }

  /// Analiza un archivo y retorna su componente.
  Future<FeatureComponent> _analyzeFile(
    File file,
    ArchitectureLayer layer,
    ComponentType type,
  ) async {
    final content = await file.readAsString();
    final relativePath =
        file.path.replaceFirst('$projectRoot/', '');
    final fileName = file.path.split('/').last.replaceAll('.dart', '');

    // Calcular métricas
    final lines = content.split('\n');
    final linesOfCode = lines.where((l) => l.trim().isNotEmpty).length;
    final complexity = _calculateComplexity(content);
    final hasDocumentation = _hasDocumentation(content);

    // Buscar test correspondiente
    final testPath = await _findTestPath(relativePath);
    final coverage = testPath != null ? await _estimateCoverage(file, testPath) : null;

    // Determinar estado
    final status = _determineComponentStatus(testPath, coverage);

    return FeatureComponent(
      name: _formatName(fileName),
      layer: layer,
      type: type,
      status: status,
      filePath: relativePath,
      testPath: testPath,
      coverage: coverage,
      complexity: complexity,
      linesOfCode: linesOfCode,
      hasDocumentation: hasDocumentation,
    );
  }

  bool _matchesFeature(String fileName, String featurePattern) {
    final normalizedFile = fileName.toLowerCase();
    final patterns = featurePattern.split('_');

    // Match si contiene alguna de las palabras clave de la feature
    return patterns.any(normalizedFile.contains);
  }

  ComponentType _determineComponentType(
      String fileName, ArchitectureLayer layer) {
    final lower = fileName.toLowerCase();

    switch (layer) {
      case ArchitectureLayer.domain:
        if (lower.contains('entity')) return ComponentType.entity;
        if (lower.contains('usecase') || lower.contains('use_case')) {
          return ComponentType.useCase;
        }
        if (lower.contains('repository')) return ComponentType.repository;
        return ComponentType.other;

      case ArchitectureLayer.data:
        if (lower.contains('model')) return ComponentType.model;
        if (lower.contains('datasource') || lower.contains('data_source')) {
          return ComponentType.dataSource;
        }
        if (lower.contains('repository')) return ComponentType.repositoryImpl;
        return ComponentType.other;

      case ArchitectureLayer.presentation:
        if (lower.contains('page') ||
            lower.contains('screen') ||
            lower.contains('widget')) {
          return ComponentType.widget;
        }
        if (lower.contains('provider') ||
            lower.contains('bloc') ||
            lower.contains('notifier') ||
            lower.contains('controller')) {
          return ComponentType.stateManager;
        }
        return ComponentType.other;

      case ArchitectureLayer.core:
        return ComponentType.other;
    }
  }

  int _calculateComplexity(String content) {
    // Complejidad ciclomática simplificada
    var complexity = 1;

    // Contar estructuras de control
    complexity += RegExp(r'\bif\s*\(').allMatches(content).length;
    complexity += RegExp(r'\belse\s+if\s*\(').allMatches(content).length;
    complexity += RegExp(r'\bfor\s*\(').allMatches(content).length;
    complexity += RegExp(r'\bwhile\s*\(').allMatches(content).length;
    complexity += RegExp(r'\bswitch\s*\(').allMatches(content).length;
    complexity += RegExp(r'\bcase\s+').allMatches(content).length;
    complexity += RegExp(r'\bcatch\s*\(').allMatches(content).length;
    complexity += RegExp(r'\?\?').allMatches(content).length;
    complexity += RegExp(r'\?\s*:').allMatches(content).length;
    complexity += RegExp(r'&&|\|\|').allMatches(content).length;

    return complexity;
  }

  bool _hasDocumentation(String content) {
    // Verificar si tiene documentación de clase/función
    final hasClassDoc = RegExp(r'///.*\nclass\s+').hasMatch(content);
    final hasFunctionDoc =
        RegExp(r'///.*\n\s*(Future|void|String|int|bool|dynamic|[A-Z]\w*)\s+\w+\s*\(')
            .hasMatch(content);
    return hasClassDoc || hasFunctionDoc;
  }

  Future<String?> _findTestPath(String relativePath) async {
    // Convertir path de lib a test
    final testPath = relativePath
        .replaceFirst('lib/', 'test/')
        .replaceFirst('.dart', '_test.dart');

    final testFile = File('$projectRoot/$testPath');
    if (await testFile.exists()) {
      return testPath;
    }

    // Buscar en subcarpetas de test
    final unitTestPath = relativePath
        .replaceFirst('lib/', 'test/unit/')
        .replaceFirst('.dart', '_test.dart');

    final unitTestFile = File('$projectRoot/$unitTestPath');
    if (await unitTestFile.exists()) {
      return unitTestPath;
    }

    return null;
  }

  Future<double?> _estimateCoverage(File sourceFile, String testPath) async {
    // Estimación básica basada en proporción de líneas test/source
    try {
      final testFile = File('$projectRoot/$testPath');
      if (!await testFile.exists()) return null;

      final sourceLines = (await sourceFile.readAsString())
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .length;
      final testLines = (await testFile.readAsString())
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .length;

      // Heurística: si hay más líneas de test que de source, buena cobertura
      final ratio = testLines / sourceLines;
      return (ratio * 0.7).clamp(0.0, 1.0);
    } catch (_) {
      return null;
    }
  }

  ComponentStatus _determineComponentStatus(
      String? testPath, double? coverage) {
    if (testPath == null) return ComponentStatus.pending;
    if (coverage == null) return ComponentStatus.inProgress;
    if (coverage >= 0.8) return ComponentStatus.complete;
    return ComponentStatus.inProgress;
  }

  String _formatName(String fileName) {
    // Convertir snake_case a Title Case
    return fileName
        .split('_')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }

  List<FeatureIssue> _detectIssues(
      List<FeatureComponent> components, FeatureMetrics metrics) {
    final issues = <FeatureIssue>[];

    // Issues de cobertura
    if (metrics.coverage < 0.85) {
      issues.add(FeatureIssue(
        title: 'Cobertura insuficiente',
        description:
            'La cobertura actual (${(metrics.coverage * 100).toStringAsFixed(1)}%) está por debajo del umbral del 85%',
        severity:
            metrics.coverage < 0.5 ? IssueSeverity.critical : IssueSeverity.warning,
        category: IssueCategory.coverage,
      ));
    }

    // Issues de complejidad
    for (final comp in components) {
      if (comp.complexity != null && comp.complexity! > 10) {
        issues.add(FeatureIssue(
          title: 'Alta complejidad en ${comp.name}',
          description:
              'Complejidad ciclomática de ${comp.complexity} excede el límite de 10',
          severity: comp.complexity! > 15
              ? IssueSeverity.critical
              : IssueSeverity.warning,
          category: IssueCategory.complexity,
          filePath: comp.filePath,
        ));
      }
    }

    // Issues de documentación
    final undocumented =
        components.where((c) => !c.hasDocumentation).toList();
    if (undocumented.isNotEmpty && metrics.documentedPercentage < 0.8) {
      issues.add(FeatureIssue(
        title: 'Documentación incompleta',
        description:
            '${undocumented.length} componentes sin documentación adecuada',
        severity: IssueSeverity.warning,
        category: IssueCategory.documentation,
      ));
    }

    // Issues de TDD
    final withoutTests =
        components.where((c) => c.testPath == null).toList();
    if (withoutTests.isNotEmpty) {
      issues.add(FeatureIssue(
        title: 'Componentes sin tests',
        description:
            '${withoutTests.length} componentes no tienen archivo de test correspondiente',
        severity: IssueSeverity.critical,
        category: IssueCategory.tdd,
      ));
    }

    return issues;
  }

  List<String> _generateRecommendations(
      List<FeatureComponent> components, FeatureMetrics metrics) {
    final recommendations = <String>[];

    if (metrics.coverage < 0.85) {
      recommendations.add(
          'Aumentar la cobertura de tests al menos al 85% para cumplir con los estándares de calidad');
    }

    if (metrics.averageComplexity > 8) {
      recommendations.add(
          'Refactorizar componentes con alta complejidad para mejorar la mantenibilidad');
    }

    if (metrics.documentedPercentage < 0.8) {
      recommendations.add(
          'Agregar documentación DartDoc a clases y métodos públicos');
    }

    final pendingComponents =
        components.where((c) => c.status == ComponentStatus.pending).toList();
    if (pendingComponents.isNotEmpty) {
      recommendations.add(
          'Completar la implementación de ${pendingComponents.length} componentes pendientes');
    }

    if (recommendations.isEmpty) {
      recommendations.add(
          'La feature cumple con todos los estándares de calidad. Continuar con la verificación final.');
    }

    return recommendations;
  }

  FeatureStatus _determineStatus(
      List<FeatureComponent> components, FeatureMetrics metrics) {
    if (components.isEmpty) return FeatureStatus.planned;

    final allComplete =
        components.every((c) => c.status == ComponentStatus.complete);
    final anyFailed =
        components.any((c) => c.status == ComponentStatus.failed);
    final anyInProgress =
        components.any((c) => c.status == ComponentStatus.inProgress);

    if (anyFailed) return FeatureStatus.blocked;
    if (allComplete && metrics.meetsQualityThresholds) {
      return FeatureStatus.verified;
    }
    if (allComplete) return FeatureStatus.implemented;
    if (anyInProgress) return FeatureStatus.inProgress;
    return FeatureStatus.planned;
  }

  Future<String?> _findSpecPath(String featureName) async {
    final specFile =
        File('$projectRoot/docs/specs/features/$featureName.spec.md');
    if (await specFile.exists()) {
      return 'docs/specs/features/$featureName.spec.md';
    }
    return null;
  }

  Future<String?> _findPlanPath(String featureName) async {
    final planFile =
        File('$projectRoot/docs/specs/plans/$featureName.plan.md');
    if (await planFile.exists()) {
      return 'docs/specs/plans/$featureName.plan.md';
    }
    return null;
  }

  Future<List<String>> _discoverFeatures() async {
    final features = <String>[];

    // Buscar en dfspec.yaml
    final configFile = File('$projectRoot/dfspec.yaml');
    if (await configFile.exists()) {
      try {
        final content = await configFile.readAsString();
        final yaml = loadYaml(content) as YamlMap?;
        if (yaml != null && yaml['features'] is YamlMap) {
          features.addAll((yaml['features'] as YamlMap).keys.cast<String>());
        }
      } catch (_) {}
    }

    // Buscar en docs/specs/features
    final specsDir = Directory('$projectRoot/docs/specs/features');
    if (await specsDir.exists()) {
      await for (final file in specsDir.list()) {
        if (file is File && file.path.endsWith('.spec.md')) {
          final featureName = file.path
              .split('/')
              .last
              .replaceAll('.spec.md', '');
          if (!features.contains(featureName)) {
            features.add(featureName);
          }
        }
      }
    }

    return features;
  }

  Future<String> _getProjectName() async {
    final pubspecFile = File('$projectRoot/pubspec.yaml');
    if (await pubspecFile.exists()) {
      try {
        final content = await pubspecFile.readAsString();
        final yaml = loadYaml(content) as YamlMap?;
        if (yaml != null && yaml['name'] is String) {
          return yaml['name'] as String;
        }
      } catch (_) {}
    }
    return projectRoot.split('/').last;
  }

  Future<String?> _getProjectVersion() async {
    final pubspecFile = File('$projectRoot/pubspec.yaml');
    if (await pubspecFile.exists()) {
      try {
        final content = await pubspecFile.readAsString();
        final yaml = loadYaml(content) as YamlMap?;
        if (yaml != null && yaml['version'] is String) {
          return yaml['version'] as String;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Guarda un reporte de feature como archivo markdown.
  Future<void> saveFeatureReport(FeatureReport report, {String? outputPath}) async {
    final path = outputPath ?? 'docs/reports/${report.featureName}-report.md';
    final file = File('$projectRoot/$path');

    await file.parent.create(recursive: true);
    await file.writeAsString(report.toMarkdown());
  }

  /// Guarda un reporte de proyecto como archivo markdown.
  Future<void> saveProjectReport(ProjectReport report, {String? outputPath}) async {
    final path = outputPath ?? 'docs/reports/project-report.md';
    final file = File('$projectRoot/$path');

    await file.parent.create(recursive: true);
    await file.writeAsString(report.toMarkdown());
  }
}
