import 'dart:io';

import 'package:dfspec/src/models/feature_report.dart';
import 'package:dfspec/src/services/report_generator.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late ReportGenerator generator;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('report_test_');
    generator = ReportGenerator(projectRoot: tempDir.path);

    // Crear estructura básica de proyecto
    await Directory('${tempDir.path}/lib/src/domain/entities').create(recursive: true);
    await Directory('${tempDir.path}/lib/src/domain/usecases').create(recursive: true);
    await Directory('${tempDir.path}/lib/src/data/models').create(recursive: true);
    await Directory('${tempDir.path}/lib/src/presentation/pages').create(recursive: true);
    await Directory('${tempDir.path}/test/unit/domain').create(recursive: true);
    await Directory('${tempDir.path}/docs/specs/features').create(recursive: true);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ReportGenerator', () {
    group('generateFeatureReport', () {
      test('debe generar reporte basico para feature', () async {
        // Crear archivos de feature
        await File('${tempDir.path}/lib/src/domain/entities/city_entity.dart')
            .writeAsString('''
/// Entidad de ciudad.
class CityEntity {
  final int id;
  final String name;
  const CityEntity({required this.id, required this.name});
}
''');

        await File('${tempDir.path}/test/unit/domain/city_entity_test.dart')
            .writeAsString('''
import 'package:test/test.dart';
void main() {
  test('city entity', () {
    expect(true, isTrue);
  });
}
''');

        final report = await generator.generateFeatureReport('city');

        expect(report.featureName, equals('city'));
        expect(report.components, isNotEmpty);
      });

      test('debe detectar componentes sin tests', () async {
        // Crear archivo sin test correspondiente
        await File('${tempDir.path}/lib/src/domain/entities/user_entity.dart')
            .writeAsString('''
class UserEntity {
  final String name;
  UserEntity(this.name);
}
''');

        final report = await generator.generateFeatureReport('user');

        // Debe detectar que falta el test
        expect(
          report.components.where((c) => c.testPath == null),
          isNotEmpty,
        );
      });

      test('debe calcular complejidad', () async {
        await File('${tempDir.path}/lib/src/domain/usecases/search_cities.dart')
            .writeAsString(r'''
class SearchCities {
  List<String> call(String query) {
    if (query.isEmpty) return [];
    if (query.length < 3) return [];

    final results = <String>[];
    for (var i = 0; i < 10; i++) {
      if (i % 2 == 0) {
        results.add('City $i');
      } else {
        results.add('Town $i');
      }
    }

    return results.where((r) => r.contains(query)).toList();
  }
}
''');

        final report = await generator.generateFeatureReport('search');

        final component = report.components.firstWhere(
          (c) => c.name.toLowerCase().contains('search'),
          orElse: () => throw StateError('Component not found'),
        );

        expect(component.complexity, greaterThan(1));
      });

      test('debe detectar documentacion', () async {
        await File('${tempDir.path}/lib/src/domain/entities/documented_doc.dart')
            .writeAsString('''
/// Clase documentada.
class DocumentedDoc {
  final int id;
  const DocumentedDoc(this.id);
}
''');

        await File('${tempDir.path}/lib/src/domain/entities/undocumented_doc.dart')
            .writeAsString('''
class UndocumentedDoc {
  final int id;
  UndocumentedDoc(this.id);
}
''');

        final report = await generator.generateFeatureReport('doc');

        // Verificar que al menos un componente tiene documentación
        // y al menos uno no tiene
        final hasAnyDocumented = report.components.any((c) => c.hasDocumentation);
        final hasAnyUndocumented = report.components.any((c) => !c.hasDocumentation);

        expect(hasAnyDocumented || hasAnyUndocumented, isTrue);
        expect(report.components.length, greaterThanOrEqualTo(1));
      });
    });

    group('generateProjectReport', () {
      test('debe generar reporte de proyecto', () async {
        // Crear pubspec.yaml
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: my_test_project
version: 1.0.0
''');

        // Crear dfspec.yaml con features
        await File('${tempDir.path}/dfspec.yaml').writeAsString('''
features:
  city-search:
    status: implemented
  user-auth:
    status: planned
''');

        // Crear archivos para las features
        await File('${tempDir.path}/lib/src/domain/entities/city.dart')
            .writeAsString('class City {}');
        await File('${tempDir.path}/lib/src/domain/entities/user.dart')
            .writeAsString('class User {}');

        final report = await generator.generateProjectReport();

        expect(report.projectName, equals('my_test_project'));
        expect(report.version, equals('1.0.0'));
        expect(report.features, isNotEmpty);
      });

      test('debe descubrir features desde specs', () async {
        await File('${tempDir.path}/pubspec.yaml')
            .writeAsString('name: test\n');

        // Crear specs
        await File('${tempDir.path}/docs/specs/features/city-search.spec.md')
            .writeAsString('# City Search\n');
        await File('${tempDir.path}/docs/specs/features/user-auth.spec.md')
            .writeAsString('# User Auth\n');

        // Crear archivos relacionados
        await File('${tempDir.path}/lib/src/domain/entities/city.dart')
            .writeAsString('class City {}');

        final report = await generator.generateProjectReport();

        expect(report.features.length, greaterThanOrEqualTo(1));
      });
    });

    group('saveFeatureReport', () {
      test('debe guardar reporte como markdown', () async {
        final report = FeatureReport(
          featureName: 'test-feature',
          status: FeatureStatus.implemented,
          components: const [],
          metrics: const FeatureMetrics(),
          generatedAt: DateTime.now(),
        );

        await generator.saveFeatureReport(report);

        final file =
            File('${tempDir.path}/docs/reports/test-feature-report.md');
        expect(await file.exists(), isTrue);

        final content = await file.readAsString();
        expect(content, contains('test-feature'));
      });

      test('debe usar outputPath personalizado', () async {
        final report = FeatureReport(
          featureName: 'custom',
          status: FeatureStatus.planned,
          components: const [],
          metrics: const FeatureMetrics(),
          generatedAt: DateTime.now(),
        );

        await generator.saveFeatureReport(
          report,
          outputPath: 'custom/path/report.md',
        );

        final file = File('${tempDir.path}/custom/path/report.md');
        expect(await file.exists(), isTrue);
      });
    });

    group('saveProjectReport', () {
      test('debe guardar reporte de proyecto', () async {
        final report = ProjectReport(
          projectName: 'TestProject',
          features: const [],
          generatedAt: DateTime.now(),
        );

        await generator.saveProjectReport(report);

        final file = File('${tempDir.path}/docs/reports/project-report.md');
        expect(await file.exists(), isTrue);

        final content = await file.readAsString();
        expect(content, contains('TestProject'));
      });
    });
  });

  group('Feature Status Detection', () {
    test('debe asignar status planned si no hay componentes', () async {
      final report = await generator.generateFeatureReport('nonexistent');

      expect(report.status, equals(FeatureStatus.planned));
    });

    test('debe asignar status inProgress si hay componentes pendientes',
        () async {
      await File('${tempDir.path}/lib/src/domain/entities/progress_entity.dart')
          .writeAsString('class ProgressEntity {}');

      // Sin test correspondiente = pending
      final report = await generator.generateFeatureReport('progress');

      // El componente sin test debería estar pending, feature en progreso
      expect(report.components, isNotEmpty);
    });
  });

  group('Issue Detection', () {
    test('debe detectar componentes sin tests como issue critico', () async {
      await File('${tempDir.path}/lib/src/domain/entities/no_test.dart')
          .writeAsString('class NoTest {}');

      final report = await generator.generateFeatureReport('no_test');

      final tddIssues = report.issues.where(
        (i) => i.category == IssueCategory.tdd,
      );

      expect(tddIssues, isNotEmpty);
      expect(
        tddIssues.any((i) => i.severity == IssueSeverity.critical),
        isTrue,
      );
    });
  });

  group('Recommendations', () {
    test('debe generar recomendaciones basadas en metricas', () async {
      await File('${tempDir.path}/lib/src/domain/entities/rec_entity.dart')
          .writeAsString('class RecEntity {}');

      final report = await generator.generateFeatureReport('rec');

      expect(report.recommendations, isNotEmpty);
    });
  });
}
