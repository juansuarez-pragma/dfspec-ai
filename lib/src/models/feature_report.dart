/// Reportes de estado de features para DFSpec.
///
/// Este módulo define los modelos para generar reportes
/// detallados del progreso y calidad de las features.
library;

import 'package:meta/meta.dart';

/// Estado de una feature.
enum FeatureStatus {
  /// Planificada, aún no iniciada.
  planned('planned', 'Planificada', '📋'),

  /// En desarrollo activo.
  inProgress('in_progress', 'En Progreso', '🔨'),

  /// Implementación completa, pendiente verificación.
  implemented('implemented', 'Implementada', '✅'),

  /// Verificada y lista para producción.
  verified('verified', 'Verificada', '🎯'),

  /// Bloqueada por dependencias o issues.
  blocked('blocked', 'Bloqueada', '🚫'),

  /// Deprecada o cancelada.
  deprecated('deprecated', 'Deprecada', '⚠️');

  const FeatureStatus(this.id, this.label, this.icon);
  final String id;
  final String label;
  final String icon;
}

/// Fase de desarrollo TDD.
enum TddPhase {
  /// Escribiendo tests (RED).
  red('red', 'RED', '🔴'),

  /// Implementando código (GREEN).
  green('green', 'GREEN', '🟢'),

  /// Refactorizando (REFACTOR).
  refactor('refactor', 'REFACTOR', '🔵');

  const TddPhase(this.id, this.label, this.icon);
  final String id;
  final String label;
  final String icon;
}

/// Componente de una feature en Clean Architecture.
@immutable
class FeatureComponent {
  /// Crea un componente de feature.
  const FeatureComponent({
    required this.name,
    required this.layer,
    required this.type,
    this.status = ComponentStatus.pending,
    this.tddPhase,
    this.filePath,
    this.testPath,
    this.coverage,
    this.complexity,
    this.linesOfCode,
    this.hasDocumentation = false,
  });

  /// Nombre del componente.
  final String name;

  /// Capa de Clean Architecture.
  final ArchitectureLayer layer;

  /// Tipo de componente.
  final ComponentType type;

  /// Estado del componente.
  final ComponentStatus status;

  /// Fase TDD actual.
  final TddPhase? tddPhase;

  /// Ruta del archivo de implementación.
  final String? filePath;

  /// Ruta del archivo de test.
  final String? testPath;

  /// Cobertura de tests (0.0 - 1.0).
  final double? coverage;

  /// Complejidad ciclomática.
  final int? complexity;

  /// Líneas de código.
  final int? linesOfCode;

  /// Si tiene documentación.
  final bool hasDocumentation;

  /// Si está completo (implementado y testeado).
  bool get isComplete =>
      status == ComponentStatus.complete && (coverage ?? 0) >= 0.8;

  /// Crea desde JSON.
  factory FeatureComponent.fromJson(Map<String, dynamic> json) {
    return FeatureComponent(
      name: json['name'] as String,
      layer: ArchitectureLayer.values.firstWhere(
        (l) => l.id == json['layer'],
        orElse: () => ArchitectureLayer.domain,
      ),
      type: ComponentType.values.firstWhere(
        (t) => t.id == json['type'],
        orElse: () => ComponentType.other,
      ),
      status: ComponentStatus.values.firstWhere(
        (s) => s.id == json['status'],
        orElse: () => ComponentStatus.pending,
      ),
      tddPhase: json['tdd_phase'] != null
          ? TddPhase.values.firstWhere((p) => p.id == json['tdd_phase'])
          : null,
      filePath: json['file_path'] as String?,
      testPath: json['test_path'] as String?,
      coverage: (json['coverage'] as num?)?.toDouble(),
      complexity: json['complexity'] as int?,
      linesOfCode: json['lines_of_code'] as int?,
      hasDocumentation: json['has_documentation'] as bool? ?? false,
    );
  }

  /// Convierte a JSON.
  Map<String, dynamic> toJson() => {
        'name': name,
        'layer': layer.id,
        'type': type.id,
        'status': status.id,
        if (tddPhase != null) 'tdd_phase': tddPhase!.id,
        if (filePath != null) 'file_path': filePath,
        if (testPath != null) 'test_path': testPath,
        if (coverage != null) 'coverage': coverage,
        if (complexity != null) 'complexity': complexity,
        if (linesOfCode != null) 'lines_of_code': linesOfCode,
        'has_documentation': hasDocumentation,
      };

  @override
  String toString() =>
      'Component($name [${layer.label}/${type.label}]: ${status.label})';
}

/// Estado de un componente.
enum ComponentStatus {
  /// Pendiente de iniciar.
  pending('pending', 'Pendiente', '⏳'),

  /// En progreso.
  inProgress('in_progress', 'En Progreso', '🔄'),

  /// Completo.
  complete('complete', 'Completo', '✅'),

  /// Con errores.
  failed('failed', 'Fallido', '❌');

  const ComponentStatus(this.id, this.label, this.icon);
  final String id;
  final String label;
  final String icon;
}

/// Capa de Clean Architecture.
enum ArchitectureLayer {
  /// Capa de dominio.
  domain('domain', 'Domain', 1),

  /// Capa de datos.
  data('data', 'Data', 2),

  /// Capa de presentación.
  presentation('presentation', 'Presentation', 3),

  /// Capa core/común.
  core('core', 'Core', 0);

  const ArchitectureLayer(this.id, this.label, this.order);
  final String id;
  final String label;
  final int order;
}

/// Tipo de componente.
enum ComponentType {
  /// Entidad de dominio.
  entity('entity', 'Entity'),

  /// Caso de uso.
  useCase('use_case', 'Use Case'),

  /// Interfaz de repositorio.
  repository('repository', 'Repository'),

  /// Modelo de datos.
  model('model', 'Model'),

  /// Data source.
  dataSource('data_source', 'Data Source'),

  /// Implementación de repositorio.
  repositoryImpl('repository_impl', 'Repository Impl'),

  /// Widget/Page.
  widget('widget', 'Widget'),

  /// Provider/BLoC/Controller.
  stateManager('state_manager', 'State Manager'),

  /// Otro tipo.
  other('other', 'Other');

  const ComponentType(this.id, this.label);
  final String id;
  final String label;
}

/// Métricas de una feature.
@immutable
class FeatureMetrics {
  /// Crea métricas de feature.
  const FeatureMetrics({
    this.totalComponents = 0,
    this.completedComponents = 0,
    this.totalTests = 0,
    this.passingTests = 0,
    this.coverage = 0.0,
    this.averageComplexity = 0.0,
    this.totalLinesOfCode = 0,
    this.documentedPercentage = 0.0,
  });

  /// Total de componentes.
  final int totalComponents;

  /// Componentes completados.
  final int completedComponents;

  /// Total de tests.
  final int totalTests;

  /// Tests pasando.
  final int passingTests;

  /// Cobertura de código.
  final double coverage;

  /// Complejidad promedio.
  final double averageComplexity;

  /// Total de líneas de código.
  final int totalLinesOfCode;

  /// Porcentaje documentado.
  final double documentedPercentage;

  /// Progreso de implementación (0.0 - 1.0).
  double get progress =>
      totalComponents > 0 ? completedComponents / totalComponents : 0.0;

  /// Tasa de éxito de tests (0.0 - 1.0).
  double get testSuccessRate =>
      totalTests > 0 ? passingTests / totalTests : 1.0;

  /// Si cumple los umbrales de calidad.
  bool get meetsQualityThresholds =>
      coverage >= 0.85 &&
      averageComplexity <= 10 &&
      documentedPercentage >= 0.8;

  /// Calcula métricas desde componentes.
  factory FeatureMetrics.fromComponents(List<FeatureComponent> components) {
    if (components.isEmpty) return const FeatureMetrics();

    final completed =
        components.where((c) => c.status == ComponentStatus.complete).length;

    final coverages = components
        .where((c) => c.coverage != null)
        .map((c) => c.coverage!)
        .toList();
    final avgCoverage =
        coverages.isNotEmpty ? coverages.reduce((a, b) => a + b) / coverages.length : 0.0;

    final complexities = components
        .where((c) => c.complexity != null)
        .map((c) => c.complexity!)
        .toList();
    final avgComplexity = complexities.isNotEmpty
        ? complexities.reduce((a, b) => a + b) / complexities.length
        : 0.0;

    final totalLoc = components
        .where((c) => c.linesOfCode != null)
        .fold(0, (sum, c) => sum + c.linesOfCode!);

    final documented = components.where((c) => c.hasDocumentation).length;
    final docPercentage =
        components.isNotEmpty ? documented / components.length : 0.0;

    return FeatureMetrics(
      totalComponents: components.length,
      completedComponents: completed,
      coverage: avgCoverage,
      averageComplexity: avgComplexity,
      totalLinesOfCode: totalLoc,
      documentedPercentage: docPercentage,
    );
  }

  /// Crea desde JSON.
  factory FeatureMetrics.fromJson(Map<String, dynamic> json) {
    return FeatureMetrics(
      totalComponents: json['total_components'] as int? ?? 0,
      completedComponents: json['completed_components'] as int? ?? 0,
      totalTests: json['total_tests'] as int? ?? 0,
      passingTests: json['passing_tests'] as int? ?? 0,
      coverage: (json['coverage'] as num?)?.toDouble() ?? 0.0,
      averageComplexity: (json['average_complexity'] as num?)?.toDouble() ?? 0.0,
      totalLinesOfCode: json['total_lines_of_code'] as int? ?? 0,
      documentedPercentage:
          (json['documented_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convierte a JSON.
  Map<String, dynamic> toJson() => {
        'total_components': totalComponents,
        'completed_components': completedComponents,
        'total_tests': totalTests,
        'passing_tests': passingTests,
        'coverage': coverage,
        'average_complexity': averageComplexity,
        'total_lines_of_code': totalLinesOfCode,
        'documented_percentage': documentedPercentage,
      };

  @override
  String toString() =>
      'Metrics(progress: ${(progress * 100).toStringAsFixed(1)}%, coverage: ${(coverage * 100).toStringAsFixed(1)}%)';
}

/// Reporte completo de una feature.
@immutable
class FeatureReport {
  /// Crea un reporte de feature.
  const FeatureReport({
    required this.featureName,
    required this.status,
    required this.components,
    required this.metrics,
    required this.generatedAt,
    this.description,
    this.specPath,
    this.planPath,
    this.issues = const [],
    this.recommendations = const [],
  });

  /// Nombre de la feature.
  final String featureName;

  /// Estado actual.
  final FeatureStatus status;

  /// Componentes de la feature.
  final List<FeatureComponent> components;

  /// Métricas calculadas.
  final FeatureMetrics metrics;

  /// Fecha de generación.
  final DateTime generatedAt;

  /// Descripción de la feature.
  final String? description;

  /// Ruta de la especificación.
  final String? specPath;

  /// Ruta del plan de implementación.
  final String? planPath;

  /// Issues encontrados.
  final List<FeatureIssue> issues;

  /// Recomendaciones.
  final List<String> recommendations;

  /// Componentes por capa.
  Map<ArchitectureLayer, List<FeatureComponent>> get componentsByLayer {
    final result = <ArchitectureLayer, List<FeatureComponent>>{};
    for (final component in components) {
      result.putIfAbsent(component.layer, () => []).add(component);
    }
    return result;
  }

  /// Si tiene issues críticos.
  bool get hasCriticalIssues =>
      issues.any((i) => i.severity == IssueSeverity.critical);

  /// Genera resumen markdown.
  String toMarkdown() {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('# Feature Report: $featureName');
    buffer.writeln();
    buffer.writeln('**Estado:** ${status.icon} ${status.label}');
    buffer.writeln(
        '**Generado:** ${generatedAt.toIso8601String().split('T').first}');
    if (description != null) {
      buffer.writeln();
      buffer.writeln('> $description');
    }
    buffer.writeln();

    // Métricas
    buffer.writeln('## Métricas');
    buffer.writeln();
    buffer.writeln('| Métrica | Valor | Estado |');
    buffer.writeln('|---------|-------|--------|');
    buffer.writeln(
        '| Progreso | ${(metrics.progress * 100).toStringAsFixed(1)}% | ${_progressIcon(metrics.progress)} |');
    buffer.writeln(
        '| Cobertura | ${(metrics.coverage * 100).toStringAsFixed(1)}% | ${metrics.coverage >= 0.85 ? '✅' : '⚠️'} |');
    buffer.writeln(
        '| Complejidad Promedio | ${metrics.averageComplexity.toStringAsFixed(1)} | ${metrics.averageComplexity <= 10 ? '✅' : '⚠️'} |');
    buffer.writeln(
        '| Documentación | ${(metrics.documentedPercentage * 100).toStringAsFixed(1)}% | ${metrics.documentedPercentage >= 0.8 ? '✅' : '⚠️'} |');
    buffer.writeln('| Líneas de Código | ${metrics.totalLinesOfCode} | - |');
    buffer.writeln();

    // Componentes por capa
    buffer.writeln('## Componentes');
    buffer.writeln();

    for (final layer in ArchitectureLayer.values) {
      final layerComponents = componentsByLayer[layer];
      if (layerComponents == null || layerComponents.isEmpty) continue;

      buffer.writeln('### ${layer.label}');
      buffer.writeln();
      buffer.writeln('| Componente | Tipo | Estado | Cobertura |');
      buffer.writeln('|------------|------|--------|-----------|');

      for (final comp in layerComponents) {
        final coverageStr = comp.coverage != null
            ? '${(comp.coverage! * 100).toStringAsFixed(0)}%'
            : '-';
        buffer.writeln(
            '| ${comp.name} | ${comp.type.label} | ${comp.status.icon} | $coverageStr |');
      }
      buffer.writeln();
    }

    // Issues
    if (issues.isNotEmpty) {
      buffer.writeln('## Issues');
      buffer.writeln();
      for (final issue in issues) {
        buffer.writeln('- ${issue.severity.icon} **${issue.title}**');
        buffer.writeln('  - ${issue.description}');
        if (issue.filePath != null) {
          buffer.writeln('  - Archivo: `${issue.filePath}`');
        }
      }
      buffer.writeln();
    }

    // Recomendaciones
    if (recommendations.isNotEmpty) {
      buffer.writeln('## Recomendaciones');
      buffer.writeln();
      for (final rec in recommendations) {
        buffer.writeln('- $rec');
      }
      buffer.writeln();
    }

    // Links
    buffer.writeln('## Referencias');
    buffer.writeln();
    if (specPath != null) {
      buffer.writeln('- [Especificación]($specPath)');
    }
    if (planPath != null) {
      buffer.writeln('- [Plan de Implementación]($planPath)');
    }

    return buffer.toString();
  }

  String _progressIcon(double progress) {
    if (progress >= 1.0) return '✅';
    if (progress >= 0.75) return '🟢';
    if (progress >= 0.5) return '🟡';
    if (progress >= 0.25) return '🟠';
    return '🔴';
  }

  /// Crea desde JSON.
  factory FeatureReport.fromJson(Map<String, dynamic> json) {
    return FeatureReport(
      featureName: json['feature_name'] as String,
      status: FeatureStatus.values.firstWhere(
        (s) => s.id == json['status'],
        orElse: () => FeatureStatus.planned,
      ),
      components: (json['components'] as List?)
              ?.map((c) => FeatureComponent.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      metrics: json['metrics'] != null
          ? FeatureMetrics.fromJson(json['metrics'] as Map<String, dynamic>)
          : const FeatureMetrics(),
      generatedAt: DateTime.parse(json['generated_at'] as String),
      description: json['description'] as String?,
      specPath: json['spec_path'] as String?,
      planPath: json['plan_path'] as String?,
      issues: (json['issues'] as List?)
              ?.map((i) => FeatureIssue.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }

  /// Convierte a JSON.
  Map<String, dynamic> toJson() => {
        'feature_name': featureName,
        'status': status.id,
        'components': components.map((c) => c.toJson()).toList(),
        'metrics': metrics.toJson(),
        'generated_at': generatedAt.toIso8601String(),
        if (description != null) 'description': description,
        if (specPath != null) 'spec_path': specPath,
        if (planPath != null) 'plan_path': planPath,
        if (issues.isNotEmpty) 'issues': issues.map((i) => i.toJson()).toList(),
        if (recommendations.isNotEmpty) 'recommendations': recommendations,
      };

  @override
  String toString() =>
      'FeatureReport($featureName: ${status.label}, progress: ${(metrics.progress * 100).toStringAsFixed(0)}%)';
}

/// Issue encontrado en una feature.
@immutable
class FeatureIssue {
  /// Crea un issue.
  const FeatureIssue({
    required this.title,
    required this.description,
    required this.severity,
    required this.category,
    this.filePath,
    this.line,
  });

  /// Título del issue.
  final String title;

  /// Descripción detallada.
  final String description;

  /// Severidad.
  final IssueSeverity severity;

  /// Categoría.
  final IssueCategory category;

  /// Archivo relacionado.
  final String? filePath;

  /// Línea del archivo.
  final int? line;

  /// Crea desde JSON.
  factory FeatureIssue.fromJson(Map<String, dynamic> json) {
    return FeatureIssue(
      title: json['title'] as String,
      description: json['description'] as String,
      severity: IssueSeverity.values.firstWhere(
        (s) => s.id == json['severity'],
        orElse: () => IssueSeverity.info,
      ),
      category: IssueCategory.values.firstWhere(
        (c) => c.id == json['category'],
        orElse: () => IssueCategory.other,
      ),
      filePath: json['file_path'] as String?,
      line: json['line'] as int?,
    );
  }

  /// Convierte a JSON.
  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'severity': severity.id,
        'category': category.id,
        if (filePath != null) 'file_path': filePath,
        if (line != null) 'line': line,
      };

  @override
  String toString() => 'Issue(${severity.icon} $title)';
}

/// Severidad de un issue.
enum IssueSeverity {
  /// Crítico - bloquea el desarrollo.
  critical('critical', 'Crítico', '🔴'),

  /// Warning - debe atenderse.
  warning('warning', 'Warning', '🟠'),

  /// Info - sugerencia.
  info('info', 'Info', '🔵');

  const IssueSeverity(this.id, this.label, this.icon);
  final String id;
  final String label;
  final String icon;
}

/// Categoría de un issue.
enum IssueCategory {
  /// Cobertura de tests.
  coverage('coverage', 'Cobertura'),

  /// Complejidad de código.
  complexity('complexity', 'Complejidad'),

  /// Documentación faltante.
  documentation('documentation', 'Documentación'),

  /// Violación de arquitectura.
  architecture('architecture', 'Arquitectura'),

  /// Correspondencia TDD.
  tdd('tdd', 'TDD'),

  /// Otro tipo.
  other('other', 'Otro');

  const IssueCategory(this.id, this.label);
  final String id;
  final String label;
}

/// Reporte de proyecto completo.
@immutable
class ProjectReport {
  /// Crea un reporte de proyecto.
  const ProjectReport({
    required this.projectName,
    required this.features,
    required this.generatedAt,
    this.version,
  });

  /// Nombre del proyecto.
  final String projectName;

  /// Reportes de features.
  final List<FeatureReport> features;

  /// Fecha de generación.
  final DateTime generatedAt;

  /// Versión del proyecto.
  final String? version;

  /// Total de features.
  int get totalFeatures => features.length;

  /// Features completadas.
  int get completedFeatures =>
      features.where((f) => f.status == FeatureStatus.verified).length;

  /// Progreso general del proyecto.
  double get overallProgress =>
      totalFeatures > 0 ? completedFeatures / totalFeatures : 0.0;

  /// Cobertura promedio.
  double get averageCoverage {
    if (features.isEmpty) return 0.0;
    return features.map((f) => f.metrics.coverage).reduce((a, b) => a + b) /
        features.length;
  }

  /// Features por estado.
  Map<FeatureStatus, List<FeatureReport>> get featuresByStatus {
    final result = <FeatureStatus, List<FeatureReport>>{};
    for (final feature in features) {
      result.putIfAbsent(feature.status, () => []).add(feature);
    }
    return result;
  }

  /// Genera resumen markdown.
  String toMarkdown() {
    final buffer = StringBuffer();

    buffer.writeln('# Project Report: $projectName');
    if (version != null) {
      buffer.writeln('**Versión:** $version');
    }
    buffer.writeln(
        '**Generado:** ${generatedAt.toIso8601String().split('T').first}');
    buffer.writeln();

    // Resumen
    buffer.writeln('## Resumen');
    buffer.writeln();
    buffer.writeln('| Métrica | Valor |');
    buffer.writeln('|---------|-------|');
    buffer.writeln('| Total Features | $totalFeatures |');
    buffer.writeln('| Completadas | $completedFeatures |');
    buffer.writeln(
        '| Progreso | ${(overallProgress * 100).toStringAsFixed(1)}% |');
    buffer.writeln(
        '| Cobertura Promedio | ${(averageCoverage * 100).toStringAsFixed(1)}% |');
    buffer.writeln();

    // Estado por feature
    buffer.writeln('## Features');
    buffer.writeln();
    buffer.writeln('| Feature | Estado | Progreso | Cobertura |');
    buffer.writeln('|---------|--------|----------|-----------|');

    for (final feature in features) {
      buffer.writeln(
          '| ${feature.featureName} | ${feature.status.icon} | ${(feature.metrics.progress * 100).toStringAsFixed(0)}% | ${(feature.metrics.coverage * 100).toStringAsFixed(0)}% |');
    }

    return buffer.toString();
  }

  /// Crea desde JSON.
  factory ProjectReport.fromJson(Map<String, dynamic> json) {
    return ProjectReport(
      projectName: json['project_name'] as String,
      features: (json['features'] as List)
          .map((f) => FeatureReport.fromJson(f as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.parse(json['generated_at'] as String),
      version: json['version'] as String?,
    );
  }

  /// Convierte a JSON.
  Map<String, dynamic> toJson() => {
        'project_name': projectName,
        'features': features.map((f) => f.toJson()).toList(),
        'generated_at': generatedAt.toIso8601String(),
        if (version != null) 'version': version,
      };

  @override
  String toString() =>
      'ProjectReport($projectName: $completedFeatures/$totalFeatures features)';
}
