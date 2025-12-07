/// Niveles de severidad unificados para DFSpec.
///
/// Este archivo define enums de severidad que se usan en diferentes
/// contextos del proyecto. Cada enum tiene su propósito específico:
///
/// - [Severity]: Severidad general (critical, warning, info)
/// - [MetricLevel]: Nivel de una métrica (optimal, acceptable, warning, critical)
library;

/// Severidad estándar de tres niveles.
///
/// Usado para issues, findings, y problemas de consistencia.
///
/// Ejemplo:
/// ```dart
/// final issue = Issue(
///   severity: Severity.critical,
///   message: 'Missing tests',
/// );
/// ```
enum Severity {
  /// Crítico - debe corregirse antes de continuar.
  ///
  /// Bloquea el flujo de trabajo.
  critical('CRITICAL', '✗', 3),

  /// Warning - debería corregirse.
  ///
  /// No bloquea pero afecta la calidad.
  warning('WARNING', '⚠', 2),

  /// Info - sugerencia de mejora.
  ///
  /// Mejora opcional.
  info('INFO', 'ℹ', 1);

  const Severity(this.label, this.icon, this.weight);

  /// Etiqueta para mostrar.
  final String label;

  /// Icono representativo.
  final String icon;

  /// Peso para ordenamiento y cálculos.
  final int weight;

  /// Parsea desde string (case insensitive).
  static Severity fromString(String value) {
    return switch (value.toUpperCase()) {
      'CRITICAL' || 'ERROR' => Severity.critical,
      'WARNING' || 'WARN' => Severity.warning,
      'INFO' || 'INFORMATION' => Severity.info,
      _ => Severity.info,
    };
  }

  /// Color ANSI para terminal.
  String get ansiColor => switch (this) {
        Severity.critical => '\x1B[31m', // rojo
        Severity.warning => '\x1B[33m', // amarillo
        Severity.info => '\x1B[34m', // azul
      };

  /// ¿Es bloquente?
  bool get isBlocking => this == Severity.critical;

  /// Compara severidades (crítico > warning > info).
  bool isMoreSevereThan(Severity other) => weight > other.weight;

  /// Compara severidades.
  bool isAtLeast(Severity other) => weight >= other.weight;
}

/// Nivel de una métrica de calidad.
///
/// Usado para métricas de código, cobertura, complejidad, etc.
///
/// Ejemplo:
/// ```dart
/// final coverage = Metric(
///   name: 'Test Coverage',
///   value: 85,
///   level: MetricLevel.acceptable,
/// );
/// ```
enum MetricLevel {
  /// Dentro del umbral óptimo.
  optimal('Óptimo', '✓', 4),

  /// Aceptable pero mejorable.
  acceptable('Aceptable', '○', 3),

  /// Por debajo del umbral, necesita atención.
  warning('Advertencia', '⚠', 2),

  /// Violación crítica de umbral.
  critical('Crítico', '✗', 1);

  const MetricLevel(this.label, this.icon, this.score);

  /// Etiqueta para mostrar.
  final String label;

  /// Icono representativo.
  final String icon;

  /// Score numérico (mayor es mejor).
  final int score;

  /// Parsea desde string.
  static MetricLevel fromString(String value) {
    return switch (value.toLowerCase()) {
      'optimal' || 'excellent' => MetricLevel.optimal,
      'acceptable' || 'good' => MetricLevel.acceptable,
      'warning' || 'needs_improvement' => MetricLevel.warning,
      'critical' || 'poor' => MetricLevel.critical,
      _ => MetricLevel.warning,
    };
  }

  /// Color ANSI para terminal.
  String get ansiColor => switch (this) {
        MetricLevel.optimal => '\x1B[32m', // verde
        MetricLevel.acceptable => '\x1B[36m', // cyan
        MetricLevel.warning => '\x1B[33m', // amarillo
        MetricLevel.critical => '\x1B[31m', // rojo
      };

  /// ¿Pasa la calidad mínima?
  bool get passes => this == MetricLevel.optimal || this == MetricLevel.acceptable;

  /// ¿Requiere atención inmediata?
  bool get needsAttention => this == MetricLevel.critical;

  /// Convierte a Severity estándar.
  Severity toSeverity() => switch (this) {
        MetricLevel.optimal => Severity.info,
        MetricLevel.acceptable => Severity.info,
        MetricLevel.warning => Severity.warning,
        MetricLevel.critical => Severity.critical,
      };
}

/// Extensión para cálculos con listas de severidad.
extension SeverityListExtension on List<Severity> {
  /// La severidad más alta en la lista.
  Severity? get highest {
    if (isEmpty) return null;
    return reduce((a, b) => a.weight > b.weight ? a : b);
  }

  /// Cuenta de cada severidad.
  Map<Severity, int> get counts {
    final result = <Severity, int>{};
    for (final severity in Severity.values) {
      result[severity] = where((s) => s == severity).length;
    }
    return result;
  }

  /// ¿Tiene algún crítico?
  bool get hasCritical => any((s) => s == Severity.critical);

  /// ¿Tiene algún warning o crítico?
  bool get hasWarningOrWorse => any((s) => s.isAtLeast(Severity.warning));
}

/// Extensión para cálculos con listas de MetricLevel.
extension MetricLevelListExtension on List<MetricLevel> {
  /// El nivel más bajo en la lista.
  MetricLevel? get lowest {
    if (isEmpty) return null;
    return reduce((a, b) => a.score < b.score ? a : b);
  }

  /// Score promedio (0-4).
  double get averageScore {
    if (isEmpty) return 0;
    return map((l) => l.score).reduce((a, b) => a + b) / length;
  }

  /// ¿Todos pasan?
  bool get allPass => every((l) => l.passes);
}
