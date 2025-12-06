import 'package:dfspec/src/models/feature_report.dart';
import 'package:test/test.dart';

void main() {
  group('FeatureStatus', () {
    test('debe tener iconos correctos', () {
      expect(FeatureStatus.planned.icon, equals('📋'));
      expect(FeatureStatus.inProgress.icon, equals('🔨'));
      expect(FeatureStatus.implemented.icon, equals('✅'));
      expect(FeatureStatus.verified.icon, equals('🎯'));
      expect(FeatureStatus.blocked.icon, equals('🚫'));
    });
  });

  group('TddPhase', () {
    test('debe tener ids correctos', () {
      expect(TddPhase.red.id, equals('red'));
      expect(TddPhase.green.id, equals('green'));
      expect(TddPhase.refactor.id, equals('refactor'));
    });
  });

  group('FeatureComponent', () {
    test('debe crear componente basico', () {
      const component = FeatureComponent(
        name: 'CityEntity',
        layer: ArchitectureLayer.domain,
        type: ComponentType.entity,
      );

      expect(component.name, equals('CityEntity'));
      expect(component.layer, equals(ArchitectureLayer.domain));
      expect(component.type, equals(ComponentType.entity));
      expect(component.status, equals(ComponentStatus.pending));
    });

    test('isComplete debe verificar estado y cobertura', () {
      const incomplete = FeatureComponent(
        name: 'Test',
        layer: ArchitectureLayer.domain,
        type: ComponentType.entity,
        status: ComponentStatus.complete,
        coverage: 0.5,
      );

      const complete = FeatureComponent(
        name: 'Test',
        layer: ArchitectureLayer.domain,
        type: ComponentType.entity,
        status: ComponentStatus.complete,
        coverage: 0.9,
      );

      expect(incomplete.isComplete, isFalse);
      expect(complete.isComplete, isTrue);
    });

    test('debe serializar y deserializar', () {
      const original = FeatureComponent(
        name: 'SearchCities',
        layer: ArchitectureLayer.domain,
        type: ComponentType.useCase,
        status: ComponentStatus.complete,
        tddPhase: TddPhase.green,
        filePath: 'lib/src/domain/usecases/search_cities.dart',
        testPath: 'test/unit/domain/search_cities_test.dart',
        coverage: 0.85,
        complexity: 5,
        linesOfCode: 50,
        hasDocumentation: true,
      );

      final json = original.toJson();
      final restored = FeatureComponent.fromJson(json);

      expect(restored.name, equals(original.name));
      expect(restored.layer, equals(original.layer));
      expect(restored.type, equals(original.type));
      expect(restored.status, equals(original.status));
      expect(restored.tddPhase, equals(original.tddPhase));
      expect(restored.coverage, equals(original.coverage));
    });
  });

  group('ComponentStatus', () {
    test('debe tener labels correctos', () {
      expect(ComponentStatus.pending.label, equals('Pendiente'));
      expect(ComponentStatus.inProgress.label, equals('En Progreso'));
      expect(ComponentStatus.complete.label, equals('Completo'));
      expect(ComponentStatus.failed.label, equals('Fallido'));
    });
  });

  group('ArchitectureLayer', () {
    test('debe tener orden correcto', () {
      expect(ArchitectureLayer.core.order, equals(0));
      expect(ArchitectureLayer.domain.order, equals(1));
      expect(ArchitectureLayer.data.order, equals(2));
      expect(ArchitectureLayer.presentation.order, equals(3));
    });
  });

  group('FeatureMetrics', () {
    test('debe calcular progress correctamente', () {
      const metrics = FeatureMetrics(
        totalComponents: 10,
        completedComponents: 7,
      );

      expect(metrics.progress, equals(0.7));
    });

    test('debe calcular testSuccessRate correctamente', () {
      const metrics = FeatureMetrics(
        totalTests: 20,
        passingTests: 18,
      );

      expect(metrics.testSuccessRate, equals(0.9));
    });

    test('meetsQualityThresholds debe verificar umbrales', () {
      const passing = FeatureMetrics(
        coverage: 0.90,
        averageComplexity: 5.0,
        documentedPercentage: 0.85,
      );

      const failing = FeatureMetrics(
        coverage: 0.70,
        averageComplexity: 15.0,
        documentedPercentage: 0.50,
      );

      expect(passing.meetsQualityThresholds, isTrue);
      expect(failing.meetsQualityThresholds, isFalse);
    });

    test('fromComponents debe calcular metricas', () {
      final components = [
        const FeatureComponent(
          name: 'A',
          layer: ArchitectureLayer.domain,
          type: ComponentType.entity,
          status: ComponentStatus.complete,
          coverage: 0.9,
          complexity: 5,
          linesOfCode: 50,
          hasDocumentation: true,
        ),
        const FeatureComponent(
          name: 'B',
          layer: ArchitectureLayer.domain,
          type: ComponentType.useCase,
          status: ComponentStatus.complete,
          coverage: 0.8,
          complexity: 7,
          linesOfCode: 100,
          hasDocumentation: false,
        ),
      ];

      final metrics = FeatureMetrics.fromComponents(components);

      expect(metrics.totalComponents, equals(2));
      expect(metrics.completedComponents, equals(2));
      expect(metrics.coverage, closeTo(0.85, 0.001));
      expect(metrics.averageComplexity, equals(6.0));
      expect(metrics.totalLinesOfCode, equals(150));
      expect(metrics.documentedPercentage, equals(0.5));
    });

    test('debe serializar y deserializar', () {
      const original = FeatureMetrics(
        totalComponents: 5,
        completedComponents: 3,
        totalTests: 10,
        passingTests: 9,
        coverage: 0.85,
        averageComplexity: 6.5,
        totalLinesOfCode: 500,
        documentedPercentage: 0.80,
      );

      final json = original.toJson();
      final restored = FeatureMetrics.fromJson(json);

      expect(restored.totalComponents, equals(original.totalComponents));
      expect(restored.coverage, equals(original.coverage));
      expect(restored.averageComplexity, equals(original.averageComplexity));
    });
  });

  group('FeatureReport', () {
    test('debe crear reporte basico', () {
      final report = FeatureReport(
        featureName: 'city-search',
        status: FeatureStatus.inProgress,
        components: const [],
        metrics: const FeatureMetrics(),
        generatedAt: DateTime(2024, 6, 15),
      );

      expect(report.featureName, equals('city-search'));
      expect(report.status, equals(FeatureStatus.inProgress));
    });

    test('componentsByLayer debe agrupar correctamente', () {
      final report = FeatureReport(
        featureName: 'test',
        status: FeatureStatus.inProgress,
        components: const [
          FeatureComponent(
            name: 'Entity1',
            layer: ArchitectureLayer.domain,
            type: ComponentType.entity,
          ),
          FeatureComponent(
            name: 'UseCase1',
            layer: ArchitectureLayer.domain,
            type: ComponentType.useCase,
          ),
          FeatureComponent(
            name: 'Model1',
            layer: ArchitectureLayer.data,
            type: ComponentType.model,
          ),
        ],
        metrics: const FeatureMetrics(),
        generatedAt: DateTime.now(),
      );

      final byLayer = report.componentsByLayer;

      expect(byLayer[ArchitectureLayer.domain]?.length, equals(2));
      expect(byLayer[ArchitectureLayer.data]?.length, equals(1));
    });

    test('hasCriticalIssues debe detectar issues criticos', () {
      final withCritical = FeatureReport(
        featureName: 'test',
        status: FeatureStatus.blocked,
        components: const [],
        metrics: const FeatureMetrics(),
        generatedAt: DateTime.now(),
        issues: const [
          FeatureIssue(
            title: 'Critical Issue',
            description: 'Something critical',
            severity: IssueSeverity.critical,
            category: IssueCategory.tdd,
          ),
        ],
      );

      final withoutCritical = FeatureReport(
        featureName: 'test',
        status: FeatureStatus.inProgress,
        components: const [],
        metrics: const FeatureMetrics(),
        generatedAt: DateTime.now(),
        issues: const [
          FeatureIssue(
            title: 'Warning',
            description: 'Just a warning',
            severity: IssueSeverity.warning,
            category: IssueCategory.documentation,
          ),
        ],
      );

      expect(withCritical.hasCriticalIssues, isTrue);
      expect(withoutCritical.hasCriticalIssues, isFalse);
    });

    test('toMarkdown debe generar markdown valido', () {
      final report = FeatureReport(
        featureName: 'city-search',
        status: FeatureStatus.implemented,
        description: 'Feature de búsqueda de ciudades',
        components: const [
          FeatureComponent(
            name: 'CityEntity',
            layer: ArchitectureLayer.domain,
            type: ComponentType.entity,
            status: ComponentStatus.complete,
            coverage: 0.9,
          ),
        ],
        metrics: const FeatureMetrics(
          totalComponents: 1,
          completedComponents: 1,
          coverage: 0.9,
          averageComplexity: 5.0,
          documentedPercentage: 1.0,
        ),
        generatedAt: DateTime(2024, 6, 15),
        specPath: 'docs/specs/features/city-search.spec.md',
      );

      final markdown = report.toMarkdown();

      expect(markdown, contains('# Feature Report: city-search'));
      expect(markdown, contains('✅ Implementada'));
      expect(markdown, contains('Feature de búsqueda'));
      expect(markdown, contains('Métricas'));
      expect(markdown, contains('Componentes'));
      expect(markdown, contains('CityEntity'));
      expect(markdown, contains('90.0%'));
    });

    test('debe serializar y deserializar', () {
      final original = FeatureReport(
        featureName: 'test-feature',
        status: FeatureStatus.verified,
        components: const [
          FeatureComponent(
            name: 'TestEntity',
            layer: ArchitectureLayer.domain,
            type: ComponentType.entity,
          ),
        ],
        metrics: const FeatureMetrics(totalComponents: 1),
        generatedAt: DateTime(2024, 6, 15, 10, 30),
        description: 'Test description',
        specPath: 'docs/spec.md',
        planPath: 'docs/plan.md',
        recommendations: ['Recommendation 1'],
      );

      final json = original.toJson();
      final restored = FeatureReport.fromJson(json);

      expect(restored.featureName, equals(original.featureName));
      expect(restored.status, equals(original.status));
      expect(restored.components.length, equals(1));
      expect(restored.description, equals(original.description));
      expect(restored.recommendations, equals(original.recommendations));
    });
  });

  group('FeatureIssue', () {
    test('debe crear issue con todos los campos', () {
      const issue = FeatureIssue(
        title: 'Baja cobertura',
        description: 'La cobertura está por debajo del 85%',
        severity: IssueSeverity.warning,
        category: IssueCategory.coverage,
        filePath: 'lib/src/entity.dart',
        line: 42,
      );

      expect(issue.title, equals('Baja cobertura'));
      expect(issue.severity, equals(IssueSeverity.warning));
      expect(issue.category, equals(IssueCategory.coverage));
      expect(issue.filePath, equals('lib/src/entity.dart'));
      expect(issue.line, equals(42));
    });

    test('debe serializar y deserializar', () {
      const original = FeatureIssue(
        title: 'Test Issue',
        description: 'Description',
        severity: IssueSeverity.critical,
        category: IssueCategory.architecture,
        filePath: 'lib/test.dart',
      );

      final json = original.toJson();
      final restored = FeatureIssue.fromJson(json);

      expect(restored.title, equals(original.title));
      expect(restored.severity, equals(original.severity));
      expect(restored.category, equals(original.category));
    });
  });

  group('IssueSeverity', () {
    test('debe tener iconos correctos', () {
      expect(IssueSeverity.critical.icon, equals('🔴'));
      expect(IssueSeverity.warning.icon, equals('🟠'));
      expect(IssueSeverity.info.icon, equals('🔵'));
    });
  });

  group('ProjectReport', () {
    test('debe calcular metricas de proyecto', () {
      final report = ProjectReport(
        projectName: 'MyApp',
        features: [
          FeatureReport(
            featureName: 'feature1',
            status: FeatureStatus.verified,
            components: const [],
            metrics: const FeatureMetrics(coverage: 0.9),
            generatedAt: DateTime.now(),
          ),
          FeatureReport(
            featureName: 'feature2',
            status: FeatureStatus.inProgress,
            components: const [],
            metrics: const FeatureMetrics(coverage: 0.8),
            generatedAt: DateTime.now(),
          ),
        ],
        generatedAt: DateTime.now(),
      );

      expect(report.totalFeatures, equals(2));
      expect(report.completedFeatures, equals(1));
      expect(report.overallProgress, equals(0.5));
      expect(report.averageCoverage, closeTo(0.85, 0.001));
    });

    test('featuresByStatus debe agrupar correctamente', () {
      final report = ProjectReport(
        projectName: 'MyApp',
        features: [
          FeatureReport(
            featureName: 'f1',
            status: FeatureStatus.verified,
            components: const [],
            metrics: const FeatureMetrics(),
            generatedAt: DateTime.now(),
          ),
          FeatureReport(
            featureName: 'f2',
            status: FeatureStatus.verified,
            components: const [],
            metrics: const FeatureMetrics(),
            generatedAt: DateTime.now(),
          ),
          FeatureReport(
            featureName: 'f3',
            status: FeatureStatus.planned,
            components: const [],
            metrics: const FeatureMetrics(),
            generatedAt: DateTime.now(),
          ),
        ],
        generatedAt: DateTime.now(),
      );

      final byStatus = report.featuresByStatus;

      expect(byStatus[FeatureStatus.verified]?.length, equals(2));
      expect(byStatus[FeatureStatus.planned]?.length, equals(1));
    });

    test('toMarkdown debe generar markdown valido', () {
      final report = ProjectReport(
        projectName: 'MyAwesomeApp',
        features: [
          FeatureReport(
            featureName: 'auth',
            status: FeatureStatus.verified,
            components: const [],
            metrics: const FeatureMetrics(
              totalComponents: 5,
              completedComponents: 5,
              coverage: 0.95,
            ),
            generatedAt: DateTime.now(),
          ),
        ],
        generatedAt: DateTime(2024, 6, 15),
        version: '1.0.0',
      );

      final markdown = report.toMarkdown();

      expect(markdown, contains('# Project Report: MyAwesomeApp'));
      expect(markdown, contains('1.0.0'));
      expect(markdown, contains('auth'));
      expect(markdown, contains('🎯'));
    });

    test('debe serializar y deserializar', () {
      final original = ProjectReport(
        projectName: 'TestProject',
        features: [
          FeatureReport(
            featureName: 'feature1',
            status: FeatureStatus.implemented,
            components: const [],
            metrics: const FeatureMetrics(),
            generatedAt: DateTime(2024, 1, 1),
          ),
        ],
        generatedAt: DateTime(2024, 6, 15),
        version: '2.0.0',
      );

      final json = original.toJson();
      final restored = ProjectReport.fromJson(json);

      expect(restored.projectName, equals(original.projectName));
      expect(restored.features.length, equals(1));
      expect(restored.version, equals(original.version));
    });
  });
}
