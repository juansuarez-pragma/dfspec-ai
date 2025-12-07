import 'package:dfspec/src/models/quality_metrics.dart';
import 'package:test/test.dart';

void main() {
  group('MetricSeverity', () {
    test('debe tener labels correctos', () {
      expect(MetricSeverity.optimal.label, equals('Óptimo'));
      expect(MetricSeverity.acceptable.label, equals('Aceptable'));
      expect(MetricSeverity.warning.label, equals('Advertencia'));
      expect(MetricSeverity.critical.label, equals('Crítico'));
    });

    test('debe tener iconos correctos', () {
      expect(MetricSeverity.optimal.icon, equals('✓'));
      expect(MetricSeverity.acceptable.icon, equals('○'));
      expect(MetricSeverity.warning.icon, equals('⚠'));
      expect(MetricSeverity.critical.icon, equals('✗'));
    });
  });

  group('MetricCategory', () {
    test('debe tener labels correctos', () {
      expect(MetricCategory.coverage.label, equals('Cobertura'));
      expect(MetricCategory.complexity.label, equals('Complejidad'));
      expect(MetricCategory.performance.label, equals('Rendimiento'));
      expect(MetricCategory.maintainability.label, equals('Mantenibilidad'));
      expect(MetricCategory.documentation.label, equals('Documentación'));
      expect(MetricCategory.architecture.label, equals('Arquitectura'));
    });
  });

  group('MetricThreshold', () {
    test('debe evaluar valores correctamente', () {
      const threshold = MetricThreshold(
        optimal: 90,
        acceptable: 80,
        warning: 60,
      );

      expect(threshold.evaluate(95), equals(MetricSeverity.optimal));
      expect(threshold.evaluate(90), equals(MetricSeverity.optimal));
      expect(threshold.evaluate(85), equals(MetricSeverity.acceptable));
      expect(threshold.evaluate(70), equals(MetricSeverity.warning));
      expect(threshold.evaluate(50), equals(MetricSeverity.critical));
    });

    test('debe evaluar valores inversos correctamente', () {
      const threshold = MetricThreshold(
        optimal: 5,
        acceptable: 10,
        warning: 15,
      );

      expect(threshold.evaluateInverse(3), equals(MetricSeverity.optimal));
      expect(threshold.evaluateInverse(5), equals(MetricSeverity.optimal));
      expect(threshold.evaluateInverse(8), equals(MetricSeverity.acceptable));
      expect(threshold.evaluateInverse(12), equals(MetricSeverity.warning));
      expect(threshold.evaluateInverse(20), equals(MetricSeverity.critical));
    });

    test('debe serializar a JSON', () {
      const threshold = MetricThreshold(
        optimal: 90,
        acceptable: 80,
        warning: 60,
      );

      final json = threshold.toJson();

      expect(json['optimal'], equals(90));
      expect(json['acceptable'], equals(80));
      expect(json['warning'], equals(60));
    });

    test('debe deserializar desde JSON', () {
      final json = {
        'optimal': 95.0,
        'acceptable': 85.0,
        'warning': 70.0,
      };

      final threshold = MetricThreshold.fromJson(json);

      expect(threshold.optimal, equals(95));
      expect(threshold.acceptable, equals(85));
      expect(threshold.warning, equals(70));
    });
  });

  group('QualityMetric', () {
    test('debe calcular severidad correctamente', () {
      final metric = QualityMetrics.coverage(0.92);

      expect(metric.severity, equals(MetricSeverity.optimal));
      expect(metric.isOptimal, isTrue);
      expect(metric.needsAttention, isFalse);
    });

    test('debe calcular severidad inversa correctamente', () {
      final metric = QualityMetrics.cyclomaticComplexity(12);

      expect(metric.inverseScale, isTrue);
      expect(metric.severity, equals(MetricSeverity.warning));
      expect(metric.needsAttention, isTrue);
    });

    test('debe formatear valor con porcentaje', () {
      final metric = QualityMetrics.coverage(0.875);

      expect(metric.formattedValue, equals('87.5%'));
    });

    test('debe formatear valor con unidad', () {
      final metric = QualityMetrics.frameBudget(12.5);

      expect(metric.formattedValue, equals('12.50ms'));
    });

    test('debe formatear valor entero sin decimales', () {
      final metric = QualityMetrics.linesPerFile(200);

      expect(metric.formattedValue, equals('200'));
    });

    test('debe serializar a JSON', () {
      final metric = QualityMetrics.coverage(0.85);

      final json = metric.toJson();

      expect(json['id'], equals('coverage'));
      expect(json['name'], equals('Cobertura de Tests'));
      expect(json['category'], equals('coverage'));
      expect(json['value'], equals(0.85));
      expect(json['unit'], equals('%'));
    });

    test('debe deserializar desde JSON', () {
      final json = {
        'id': 'coverage',
        'name': 'Cobertura',
        'category': 'coverage',
        'value': 0.90,
        'threshold': {
          'optimal': 0.90,
          'acceptable': 0.85,
          'warning': 0.70,
        },
        'unit': '%',
      };

      final metric = QualityMetric.fromJson(json);

      expect(metric.id, equals('coverage'));
      expect(metric.value, equals(0.90));
      expect(metric.severity, equals(MetricSeverity.optimal));
    });

    test('toString debe mostrar icono y valor', () {
      final metric = QualityMetrics.coverage(0.92);

      expect(metric.toString(), contains('✓'));
      expect(metric.toString(), contains('Cobertura'));
      expect(metric.toString(), contains('92.0%'));
    });
  });

  group('QualityReport', () {
    test('debe crear reporte con metricas', () {
      final report = QualityReport(
        metrics: [
          QualityMetrics.coverage(0.90),
          QualityMetrics.cyclomaticComplexity(8),
          QualityMetrics.documentation(0.75),
        ],
        timestamp: DateTime(2024, 1, 15),
        projectName: 'test-project',
      );

      expect(report.metrics.length, equals(3));
      expect(report.projectName, equals('test-project'));
    });

    test('debe agrupar metricas por categoria', () {
      final report = QualityReport(
        metrics: [
          QualityMetrics.coverage(0.90),
          QualityMetrics.domainCoverage(0.95),
          QualityMetrics.cyclomaticComplexity(8),
        ],
        timestamp: DateTime.now(),
      );

      final byCategory = report.byCategory;

      expect(byCategory[MetricCategory.coverage]?.length, equals(2));
      expect(byCategory[MetricCategory.complexity]?.length, equals(1));
    });

    test('debe filtrar metricas por severidad', () {
      final report = QualityReport(
        metrics: [
          QualityMetrics.coverage(0.92), // optimal
          QualityMetrics.cyclomaticComplexity(8), // acceptable
          QualityMetrics.documentation(0.55), // critical
          QualityMetrics.linesPerFile(450), // warning
        ],
        timestamp: DateTime.now(),
      );

      expect(report.optimal.length, equals(1));
      expect(report.acceptable.length, equals(1));
      expect(report.warnings.length, equals(1));
      expect(report.critical.length, equals(1));
    });

    test('allAcceptable debe ser true sin critical ni warnings', () {
      final acceptable = QualityReport(
        metrics: [
          QualityMetrics.coverage(0.92),
          QualityMetrics.cyclomaticComplexity(5),
        ],
        timestamp: DateTime.now(),
      );

      final notAcceptable = QualityReport(
        metrics: [
          QualityMetrics.coverage(0.92),
          QualityMetrics.documentation(0.50), // critical
        ],
        timestamp: DateTime.now(),
      );

      expect(acceptable.allAcceptable, isTrue);
      expect(notAcceptable.allAcceptable, isFalse);
    });

    test('overallScore debe calcular correctamente', () {
      final report = QualityReport(
        metrics: [
          QualityMetrics.coverage(0.95), // optimal = 100
          QualityMetrics.cyclomaticComplexity(8), // acceptable = 75
          QualityMetrics.documentation(0.65), // warning = 50
          QualityMetrics.duplication(0.15), // critical = 25
        ],
        timestamp: DateTime.now(),
      );

      // (100 + 75 + 50 + 25) / 4 = 62.5
      expect(report.overallScore, equals(62.5));
    });

    test('overallScore debe ser 100 para reporte vacio', () {
      final report = QualityReport.empty();

      expect(report.overallScore, equals(100.0));
    });

    test('debe serializar y deserializar', () {
      final original = QualityReport(
        metrics: [
          QualityMetrics.coverage(0.90),
          QualityMetrics.cyclomaticComplexity(7),
        ],
        timestamp: DateTime(2024, 1, 15, 10, 30),
        projectName: 'test',
        context: 'analysis',
      );

      final json = original.toJson();
      final restored = QualityReport.fromJson(json);

      expect(restored.metrics.length, equals(2));
      expect(restored.projectName, equals('test'));
      expect(restored.context, equals('analysis'));
    });

    test('toSummary debe generar markdown valido', () {
      final report = QualityReport(
        metrics: [
          QualityMetrics.coverage(0.90),
          QualityMetrics.cyclomaticComplexity(15, files: ['file1.dart']),
        ],
        timestamp: DateTime(2024, 1, 15),
        projectName: 'test-project',
      );

      final summary = report.toSummary();

      expect(summary, contains('## Reporte de Calidad'));
      expect(summary, contains('test-project'));
      expect(summary, contains('Puntuación General'));
      expect(summary, contains('Cobertura'));
      expect(summary, contains('Complejidad'));
    });
  });

  group('QualityThresholds', () {
    test('debe tener todos los umbrales predefinidos', () {
      final all = QualityThresholds.all;

      expect(all.containsKey('coverage'), isTrue);
      expect(all.containsKey('cyclomatic-complexity'), isTrue);
      expect(all.containsKey('cognitive-complexity'), isTrue);
      expect(all.containsKey('lines-per-file'), isTrue);
      expect(all.containsKey('frame-budget'), isTrue);
      expect(all.containsKey('documentation'), isTrue);
      expect(all.containsKey('duplication'), isTrue);
    });

    test('coverage threshold debe seguir constitucion', () {
      const threshold = QualityThresholds.coverage;

      expect(threshold.optimal, equals(0.90));
      expect(threshold.acceptable, equals(0.85));
      expect(threshold.warning, equals(0.70));
    });

    test('domainCoverage debe ser mas estricto', () {
      const domain = QualityThresholds.domainCoverage;
      const general = QualityThresholds.coverage;

      expect(domain.optimal, greaterThan(general.optimal));
    });
  });

  group('QualityMetrics factories', () {
    test('coverage debe crear metrica correcta', () {
      final metric = QualityMetrics.coverage(0.87);

      expect(metric.id, equals('coverage'));
      expect(metric.category, equals(MetricCategory.coverage));
      expect(metric.unit, equals('%'));
      expect(metric.inverseScale, isFalse);
    });

    test('cyclomaticComplexity debe crear metrica inversa', () {
      final metric = QualityMetrics.cyclomaticComplexity(12);

      expect(metric.id, equals('cyclomatic-complexity'));
      expect(metric.category, equals(MetricCategory.complexity));
      expect(metric.inverseScale, isTrue);
    });

    test('frameBudget debe crear metrica de performance', () {
      final metric = QualityMetrics.frameBudget(10);

      expect(metric.id, equals('frame-budget'));
      expect(metric.category, equals(MetricCategory.performance));
      expect(metric.unit, equals('ms'));
      expect(metric.inverseScale, isTrue);
    });

    test('documentation debe incluir archivos sin documentar', () {
      final metric = QualityMetrics.documentation(
        0.80,
        undocumented: ['class Foo', 'method bar'],
      );

      expect(metric.details.length, equals(2));
      expect(metric.details, contains('class Foo'));
    });

    test('duplication debe incluir ubicaciones', () {
      final metric = QualityMetrics.duplication(
        0.05,
        locations: ['file.dart:10', 'file.dart:50'],
      );

      expect(metric.details.length, equals(2));
    });
  });
}
