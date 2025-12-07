import 'package:meta/meta.dart';

/// Nivel de severidad de una métrica.
enum MetricSeverity {
  /// Dentro del umbral óptimo.
  optimal('Óptimo'),

  /// Aceptable pero mejorable.
  acceptable('Aceptable'),

  /// Por debajo del umbral, necesita atención.
  warning('Advertencia'),

  /// Violación crítica de umbral.
  critical('Crítico');

  const MetricSeverity(this.label);
  final String label;

  /// Ícono representativo.
  String get icon {
    switch (this) {
      case MetricSeverity.optimal:
        return '✓';
      case MetricSeverity.acceptable:
        return '○';
      case MetricSeverity.warning:
        return '⚠';
      case MetricSeverity.critical:
        return '✗';
    }
  }
}

/// Categoría de métrica.
enum MetricCategory {
  /// Métricas de cobertura de tests.
  coverage('Cobertura'),

  /// Métricas de complejidad del código.
  complexity('Complejidad'),

  /// Métricas de rendimiento.
  performance('Rendimiento'),

  /// Métricas de mantenibilidad.
  maintainability('Mantenibilidad'),

  /// Métricas de documentación.
  documentation('Documentación'),

  /// Métricas de arquitectura.
  architecture('Arquitectura');

  const MetricCategory(this.label);
  final String label;
}

/// Umbral configurable para una métrica.
@immutable
class MetricThreshold {
  /// Crea un umbral.
  const MetricThreshold({
    required this.optimal,
    required this.acceptable,
    required this.warning,
  });

  /// Crea desde JSON.
  factory MetricThreshold.fromJson(Map<String, dynamic> json) {
    return MetricThreshold(
      optimal: (json['optimal'] as num).toDouble(),
      acceptable: (json['acceptable'] as num).toDouble(),
      warning: (json['warning'] as num).toDouble(),
    );
  }

  /// Valor para nivel óptimo (>=).
  final double optimal;

  /// Valor para nivel aceptable (>=).
  final double acceptable;

  /// Valor para nivel warning (>=). Por debajo es crítico.
  final double warning;

  /// Evalúa un valor contra los umbrales.
  MetricSeverity evaluate(double value) {
    if (value >= optimal) return MetricSeverity.optimal;
    if (value >= acceptable) return MetricSeverity.acceptable;
    if (value >= warning) return MetricSeverity.warning;
    return MetricSeverity.critical;
  }

  /// Umbral inverso (menor es mejor, ej: complejidad).
  MetricSeverity evaluateInverse(double value) {
    if (value <= optimal) return MetricSeverity.optimal;
    if (value <= acceptable) return MetricSeverity.acceptable;
    if (value <= warning) return MetricSeverity.warning;
    return MetricSeverity.critical;
  }

  /// Convierte a JSON.
  Map<String, dynamic> toJson() => {
        'optimal': optimal,
        'acceptable': acceptable,
        'warning': warning,
      };
}

/// Una métrica individual de calidad.
@immutable
class QualityMetric {
  /// Crea una métrica.
  const QualityMetric({
    required this.id,
    required this.name,
    required this.category,
    required this.value,
    required this.threshold,
    this.unit = '',
    this.description,
    this.details = const [],
    this.inverseScale = false,
  });

  /// Crea desde JSON.
  factory QualityMetric.fromJson(Map<String, dynamic> json) {
    return QualityMetric(
      id: json['id'] as String,
      name: json['name'] as String,
      category: MetricCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => MetricCategory.maintainability,
      ),
      value: (json['value'] as num).toDouble(),
      threshold: MetricThreshold.fromJson(
        json['threshold'] as Map<String, dynamic>,
      ),
      unit: json['unit'] as String? ?? '',
      description: json['description'] as String?,
      details: (json['details'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      inverseScale: json['inverseScale'] as bool? ?? false,
    );
  }

  /// Identificador único.
  final String id;

  /// Nombre descriptivo.
  final String name;

  /// Categoría de la métrica.
  final MetricCategory category;

  /// Valor actual.
  final double value;

  /// Umbral de evaluación.
  final MetricThreshold threshold;

  /// Unidad de medida (%, ms, etc).
  final String unit;

  /// Descripción de la métrica.
  final String? description;

  /// Detalles adicionales (archivos afectados, etc).
  final List<String> details;

  /// Si la escala es inversa (menor es mejor).
  final bool inverseScale;

  /// Severidad calculada.
  MetricSeverity get severity => inverseScale
      ? threshold.evaluateInverse(value)
      : threshold.evaluate(value);

  /// Si está en nivel óptimo.
  bool get isOptimal => severity == MetricSeverity.optimal;

  /// Si necesita atención.
  bool get needsAttention =>
      severity == MetricSeverity.warning || severity == MetricSeverity.critical;

  /// Valor formateado con unidad.
  String get formattedValue {
    if (unit == '%') {
      return '${(value * 100).toStringAsFixed(1)}%';
    }
    if (value == value.roundToDouble()) {
      return '${value.toInt()}$unit';
    }
    return '${value.toStringAsFixed(2)}$unit';
  }

  /// Convierte a JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'value': value,
        'threshold': threshold.toJson(),
        if (unit.isNotEmpty) 'unit': unit,
        if (description != null) 'description': description,
        if (details.isNotEmpty) 'details': details,
        if (inverseScale) 'inverseScale': inverseScale,
      };

  @override
  String toString() =>
      'Metric(${severity.icon} $name: $formattedValue)';
}

/// Reporte completo de métricas de calidad.
@immutable
class QualityReport {
  /// Crea un reporte.
  const QualityReport({
    required this.metrics,
    required this.timestamp,
    this.context,
    this.projectName,
  });

  /// Crea reporte vacío.
  factory QualityReport.empty() {
    return QualityReport(
      metrics: const [],
      timestamp: DateTime.now(),
    );
  }

  /// Crea desde JSON.
  factory QualityReport.fromJson(Map<String, dynamic> json) {
    return QualityReport(
      metrics: (json['metrics'] as List<dynamic>)
          .map((m) => QualityMetric.fromJson(m as Map<String, dynamic>))
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      context: json['context'] as String?,
      projectName: json['projectName'] as String?,
    );
  }

  /// Lista de métricas.
  final List<QualityMetric> metrics;

  /// Timestamp del reporte.
  final DateTime timestamp;

  /// Contexto del reporte (feature, archivo, etc).
  final String? context;

  /// Nombre del proyecto.
  final String? projectName;

  /// Métricas por categoría.
  Map<MetricCategory, List<QualityMetric>> get byCategory {
    final result = <MetricCategory, List<QualityMetric>>{};
    for (final metric in metrics) {
      result.putIfAbsent(metric.category, () => []).add(metric);
    }
    return result;
  }

  /// Métricas óptimas.
  List<QualityMetric> get optimal =>
      metrics.where((m) => m.severity == MetricSeverity.optimal).toList();

  /// Métricas aceptables.
  List<QualityMetric> get acceptable =>
      metrics.where((m) => m.severity == MetricSeverity.acceptable).toList();

  /// Métricas con advertencia.
  List<QualityMetric> get warnings =>
      metrics.where((m) => m.severity == MetricSeverity.warning).toList();

  /// Métricas críticas.
  List<QualityMetric> get critical =>
      metrics.where((m) => m.severity == MetricSeverity.critical).toList();

  /// Si todas las métricas están en nivel aceptable o mejor.
  bool get allAcceptable => critical.isEmpty && warnings.isEmpty;

  /// Puntuación general (0-100).
  double get overallScore {
    if (metrics.isEmpty) return 100;

    var score = 0.0;
    for (final metric in metrics) {
      switch (metric.severity) {
        case MetricSeverity.optimal:
          score += 100;
        case MetricSeverity.acceptable:
          score += 75;
        case MetricSeverity.warning:
          score += 50;
        case MetricSeverity.critical:
          score += 25;
      }
    }
    return score / metrics.length;
  }

  /// Convierte a JSON.
  Map<String, dynamic> toJson() => {
        'metrics': metrics.map((m) => m.toJson()).toList(),
        'timestamp': timestamp.toIso8601String(),
        if (context != null) 'context': context,
        if (projectName != null) 'projectName': projectName,
      };

  /// Genera resumen en formato markdown.
  String toSummary() {
    final buffer = StringBuffer();
    buffer.writeln('## Reporte de Calidad');
    buffer.writeln();

    if (projectName != null) {
      buffer.writeln('**Proyecto:** $projectName');
    }
    if (context != null) {
      buffer.writeln('**Contexto:** $context');
    }
    buffer.writeln('**Fecha:** ${timestamp.toIso8601String()}');
    buffer.writeln();

    // Score general
    buffer.writeln('### Puntuación General: ${overallScore.toStringAsFixed(1)}/100');
    buffer.writeln();

    // Resumen por severidad
    buffer.writeln('| Estado | Cantidad |');
    buffer.writeln('|--------|----------|');
    buffer.writeln('| ✓ Óptimo | ${optimal.length} |');
    buffer.writeln('| ○ Aceptable | ${acceptable.length} |');
    buffer.writeln('| ⚠ Advertencia | ${warnings.length} |');
    buffer.writeln('| ✗ Crítico | ${critical.length} |');
    buffer.writeln();

    // Métricas por categoría
    for (final entry in byCategory.entries) {
      buffer.writeln('### ${entry.key.label}');
      buffer.writeln();
      buffer.writeln('| Métrica | Valor | Estado |');
      buffer.writeln('|---------|-------|--------|');
      for (final metric in entry.value) {
        buffer.writeln(
          '| ${metric.name} | ${metric.formattedValue} | ${metric.severity.icon} |',
        );
      }
      buffer.writeln();
    }

    // Detalles de problemas
    final problems = [...warnings, ...critical];
    if (problems.isNotEmpty) {
      buffer.writeln('### Problemas Detectados');
      buffer.writeln();
      for (final metric in problems) {
        buffer.writeln('#### ${metric.severity.icon} ${metric.name}');
        if (metric.description != null) {
          buffer.writeln(metric.description);
        }
        if (metric.details.isNotEmpty) {
          for (final detail in metric.details) {
            buffer.writeln('- $detail');
          }
        }
        buffer.writeln();
      }
    }

    return buffer.toString();
  }
}

/// Umbrales predefinidos según la constitución DFSpec.
class QualityThresholds {
  QualityThresholds._();

  /// Cobertura total de tests (Artículo IX).
  static const coverage = MetricThreshold(
    optimal: 0.90, // 90%
    acceptable: 0.85, // 85%
    warning: 0.70, // 70%
  );

  /// Cobertura de domain.
  static const domainCoverage = MetricThreshold(
    optimal: 0.98, // 98%
    acceptable: 0.95, // 95%
    warning: 0.85, // 85%
  );

  /// Cobertura de data.
  static const dataCoverage = MetricThreshold(
    optimal: 0.95, // 95%
    acceptable: 0.90, // 90%
    warning: 0.80, // 80%
  );

  /// Cobertura de presentation.
  static const presentationCoverage = MetricThreshold(
    optimal: 0.85, // 85%
    acceptable: 0.80, // 80%
    warning: 0.70, // 70%
  );

  /// Complejidad ciclomática (inversa).
  static const cyclomaticComplexity = MetricThreshold(
    optimal: 5, // <= 5
    acceptable: 10, // <= 10
    warning: 15, // <= 15
  );

  /// Complejidad cognitiva (inversa).
  static const cognitiveComplexity = MetricThreshold(
    optimal: 5, // <= 5
    acceptable: 8, // <= 8
    warning: 12, // <= 12
  );

  /// Líneas por archivo (inversa).
  static const linesPerFile = MetricThreshold(
    optimal: 200, // <= 200
    acceptable: 400, // <= 400
    warning: 600, // <= 600
  );

  /// Frame budget en ms (inversa, Artículo X).
  static const frameBudget = MetricThreshold(
    optimal: 8, // <= 8ms
    acceptable: 16, // <= 16ms
    warning: 24, // <= 24ms
  );

  /// Documentación pública (Artículo XI).
  static const documentation = MetricThreshold(
    optimal: 0.95, // 95%
    acceptable: 0.80, // 80%
    warning: 0.60, // 60%
  );

  /// Profundidad de dependencias (inversa).
  static const dependencyDepth = MetricThreshold(
    optimal: 3, // <= 3
    acceptable: 5, // <= 5
    warning: 7, // <= 7
  );

  /// Duplicación de código (inversa).
  static const duplication = MetricThreshold(
    optimal: 0.03, // <= 3%
    acceptable: 0.05, // <= 5%
    warning: 0.10, // <= 10%
  );

  /// Todos los umbrales predefinidos.
  static Map<String, MetricThreshold> get all => {
        'coverage': coverage,
        'domain-coverage': domainCoverage,
        'data-coverage': dataCoverage,
        'presentation-coverage': presentationCoverage,
        'cyclomatic-complexity': cyclomaticComplexity,
        'cognitive-complexity': cognitiveComplexity,
        'lines-per-file': linesPerFile,
        'frame-budget': frameBudget,
        'documentation': documentation,
        'dependency-depth': dependencyDepth,
        'duplication': duplication,
      };
}

/// Métricas predefinidas para evaluación rápida.
class QualityMetrics {
  QualityMetrics._();

  /// Crea métrica de cobertura total.
  static QualityMetric coverage(double value) {
    return QualityMetric(
      id: 'coverage',
      name: 'Cobertura de Tests',
      category: MetricCategory.coverage,
      value: value,
      threshold: QualityThresholds.coverage,
      unit: '%',
      description: 'Porcentaje de código cubierto por tests',
    );
  }

  /// Crea métrica de cobertura de domain.
  static QualityMetric domainCoverage(double value) {
    return QualityMetric(
      id: 'domain-coverage',
      name: 'Cobertura Domain',
      category: MetricCategory.coverage,
      value: value,
      threshold: QualityThresholds.domainCoverage,
      unit: '%',
      description: 'Cobertura de capa domain (entities, usecases)',
    );
  }

  /// Crea métrica de complejidad ciclomática.
  static QualityMetric cyclomaticComplexity(double value, {List<String>? files}) {
    return QualityMetric(
      id: 'cyclomatic-complexity',
      name: 'Complejidad Ciclomática',
      category: MetricCategory.complexity,
      value: value,
      threshold: QualityThresholds.cyclomaticComplexity,
      description: 'Promedio de complejidad ciclomática',
      details: files ?? const [],
      inverseScale: true,
    );
  }

  /// Crea métrica de complejidad cognitiva.
  static QualityMetric cognitiveComplexity(double value, {List<String>? files}) {
    return QualityMetric(
      id: 'cognitive-complexity',
      name: 'Complejidad Cognitiva',
      category: MetricCategory.complexity,
      value: value,
      threshold: QualityThresholds.cognitiveComplexity,
      description: 'Promedio de complejidad cognitiva',
      details: files ?? const [],
      inverseScale: true,
    );
  }

  /// Crea métrica de líneas por archivo.
  static QualityMetric linesPerFile(double value, {List<String>? files}) {
    return QualityMetric(
      id: 'lines-per-file',
      name: 'Líneas por Archivo',
      category: MetricCategory.maintainability,
      value: value,
      threshold: QualityThresholds.linesPerFile,
      description: 'Promedio de líneas por archivo',
      details: files ?? const [],
      inverseScale: true,
    );
  }

  /// Crea métrica de frame budget.
  static QualityMetric frameBudget(double value) {
    return QualityMetric(
      id: 'frame-budget',
      name: 'Frame Budget',
      category: MetricCategory.performance,
      value: value,
      threshold: QualityThresholds.frameBudget,
      unit: 'ms',
      description: 'Tiempo promedio de renderizado de frame',
      inverseScale: true,
    );
  }

  /// Crea métrica de documentación.
  static QualityMetric documentation(double value, {List<String>? undocumented}) {
    return QualityMetric(
      id: 'documentation',
      name: 'Documentación',
      category: MetricCategory.documentation,
      value: value,
      threshold: QualityThresholds.documentation,
      unit: '%',
      description: 'Porcentaje de API pública documentada',
      details: undocumented ?? const [],
    );
  }

  /// Crea métrica de duplicación.
  static QualityMetric duplication(double value, {List<String>? locations}) {
    return QualityMetric(
      id: 'duplication',
      name: 'Duplicación de Código',
      category: MetricCategory.maintainability,
      value: value,
      threshold: QualityThresholds.duplication,
      unit: '%',
      description: 'Porcentaje de código duplicado',
      details: locations ?? const [],
      inverseScale: true,
    );
  }

  /// Crea métrica de profundidad de dependencias.
  static QualityMetric dependencyDepth(double value) {
    return QualityMetric(
      id: 'dependency-depth',
      name: 'Profundidad de Dependencias',
      category: MetricCategory.architecture,
      value: value,
      threshold: QualityThresholds.dependencyDepth,
      description: 'Máxima profundidad del árbol de dependencias',
      inverseScale: true,
    );
  }
}
