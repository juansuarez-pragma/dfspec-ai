import 'dart:io';

import 'package:dfspec/src/models/documentation_spec.dart';
import 'package:dfspec/src/services/documentation_generator.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late DocumentationGenerator generator;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('docs_test_');
    generator = DocumentationGenerator(projectRoot: tempDir.path);

    // Crear estructura básica
    await Directory('${tempDir.path}/lib/src/domain').create(recursive: true);
    await Directory('${tempDir.path}/lib/src/data').create(recursive: true);
    await Directory('${tempDir.path}/docs').create(recursive: true);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('DocumentationGenerator', () {
    group('generate', () {
      test('debe generar documento desde spec', () async {
        const spec = DocumentationSpec(
          type: DocumentationType.readme,
          title: 'Test Project',
          description: 'A test project.',
          sections: [
            DocumentSection(title: 'Uso', content: 'Ejemplo'),
          ],
          outputPath: 'docs/TEST.md',
        );

        final result = await generator.generate(spec);

        expect(result.outputPath, equals('docs/TEST.md'));
        expect(result.content, contains('# Test Project'));

        // Verificar que el archivo fue creado
        final file = File('${tempDir.path}/${result.outputPath}');
        expect(await file.exists(), isTrue);
      });

      test('debe crear directorios necesarios', () async {
        const spec = DocumentationSpec(
          type: DocumentationType.specification,
          title: 'Deep Spec',
          outputPath: 'docs/specs/features/deep/nested/spec.md',
        );

        final result = await generator.generate(spec);

        final file = File('${tempDir.path}/${result.outputPath}');
        expect(await file.exists(), isTrue);
      });
    });

    group('generateFeatureReadme', () {
      test('debe generar README de feature', () async {
        // Crear archivos de feature
        await File('${tempDir.path}/lib/src/domain/city_entity.dart')
            .writeAsString('''
class CityEntity {
  final int id;
  final String name;
}
''');

        final result = await generator.generateFeatureReadme(
          featureName: 'city',
          description: 'Feature de ciudades',
        );

        expect(result.content, contains('Feature: city'));
        expect(result.outputPath, contains('city'));
      });
    });

    group('generateArchitecture', () {
      test('debe generar documentacion de arquitectura', () async {
        // Crear archivos en capas
        await File('${tempDir.path}/lib/src/domain/entity.dart')
            .writeAsString('class Entity {}');
        await File('${tempDir.path}/lib/src/data/model.dart')
            .writeAsString('class Model {}');

        final result = await generator.generateArchitecture();

        expect(result.content, contains('Clean Architecture'));
        expect(result.content, contains('Domain'));
        expect(result.content, contains('Data'));
      });

      test('debe usar nombre del proyecto si existe pubspec', () async {
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: my_awesome_project
version: 1.0.0
''');

        await File('${tempDir.path}/lib/src/domain/test.dart')
            .writeAsString('class Test {}');

        final result = await generator.generateArchitecture();

        expect(result.content, contains('my_awesome_project'));
      });
    });

    group('generateChangelog', () {
      test('debe generar entrada de changelog', () async {
        final result = await generator.generateChangelog(
          version: '1.2.0',
          added: ['Feature X'],
          fixed: ['Bug Y'],
          append: false,
        );

        expect(result.content, contains('[1.2.0]'));
        expect(result.content, contains('Feature X'));
        expect(result.content, contains('Bug Y'));
      });

      test('debe append a changelog existente', () async {
        // Crear changelog existente
        await File('${tempDir.path}/CHANGELOG.md').writeAsString('''
# Changelog

## [1.0.0] - 2024-01-01

### Added
- Initial release
''');

        final result = await generator.generateChangelog(
          version: '1.1.0',
          added: ['New feature'],
        );

        expect(result.content, contains('[1.1.0]'));
        expect(result.content, contains('[1.0.0]'));
        expect(result.content, contains('New feature'));
        expect(result.content, contains('Initial release'));
      });
    });

    group('generateFeatureSpec', () {
      test('debe generar especificacion de feature', () async {
        final result = await generator.generateFeatureSpec(
          featureName: 'user-auth',
          description: 'Autenticación',
          acceptanceCriteria: [
            'Login funciona',
            'Logout funciona',
          ],
        );

        expect(result.content, contains('user-auth'));
        expect(result.content, contains('Criterios de Aceptación'));
        expect(result.content, contains('Login funciona'));
      });
    });

    group('generateImplementationPlan', () {
      test('debe generar plan de implementacion', () async {
        final result = await generator.generateImplementationPlan(
          featureName: 'search',
          steps: const [
            ImplementationStep(
              name: 'Entity',
              description: 'Crear entidad',
              files: ['lib/entity.dart'],
              tests: ['test/entity_test.dart'],
            ),
          ],
        );

        expect(result.content, contains('search'));
        expect(result.content, contains('Paso 1: Entity'));
        expect(result.content, contains('TDD'));
      });
    });

    group('generateApiDoc', () {
      test('debe agregar documentacion faltante', () async {
        await File('${tempDir.path}/lib/src/domain/entity.dart')
            .writeAsString('''
class MyEntity {
  final int id;
  const MyEntity(this.id);
  int calculate() => id * 2;
}
''');

        final content =
            await generator.generateApiDoc('lib/src/domain/entity.dart');

        expect(content, contains('///'));
      });

      test('debe lanzar error si archivo no existe', () async {
        expect(
          () => generator.generateApiDoc('nonexistent.dart'),
          throwsA(isA<FileSystemException>()),
        );
      });
    });

    group('verifyDocumentation', () {
      test('debe verificar documentacion', () async {
        await File('${tempDir.path}/lib/src/domain/documented.dart')
            .writeAsString('''
/// Documented class.
class Documented {
  /// Field.
  final int value;
  /// Constructor.
  const Documented(this.value);
}
''');

        await File('${tempDir.path}/lib/src/domain/undocumented.dart')
            .writeAsString('''
class Undocumented {
  final int value;
  const Undocumented(this.value);
}
''');

        final report = await generator.verifyDocumentation();

        expect(report.filesAnalyzed, equals(2));
        expect(report.issues, isNotEmpty);
        expect(report.issues.any((i) => i.name == 'Undocumented'), isTrue);
      });

      test('debe calcular cobertura correctamente', () async {
        await File('${tempDir.path}/lib/src/domain/partial.dart')
            .writeAsString('''
/// Documented.
class Documented {}

class Undocumented {}
''');

        final report = await generator.verifyDocumentation();

        expect(report.coverage, lessThan(1.0));
        expect(report.coverage, greaterThan(0.0));
      });

      test('debe generar resumen', () async {
        await File('${tempDir.path}/lib/src/domain/test.dart')
            .writeAsString('class Test {}');

        final report = await generator.verifyDocumentation();
        final summary = report.toSummary();

        expect(summary, contains('Reporte de Documentación'));
        expect(summary, contains('Cobertura'));
        expect(summary, contains('%'));
      });
    });
  });

  group('DocumentationIssue', () {
    test('toString debe formatear correctamente', () {
      const issue = DocumentationIssue(
        path: 'lib/entity.dart',
        line: 10,
        type: 'class',
        name: 'Entity',
        message: 'Sin documentación',
      );

      expect(
        issue.toString(),
        equals('lib/entity.dart:10 - class Entity: Sin documentación'),
      );
    });
  });

  group('DocumentationReport', () {
    test('meetsThreshold debe verificar umbral 80%', () {
      const passing = DocumentationReport(
        filesAnalyzed: 5,
        documented: 85,
        total: 100,
        issues: [],
      );

      const failing = DocumentationReport(
        filesAnalyzed: 5,
        documented: 70,
        total: 100,
        issues: [],
      );

      expect(passing.meetsThreshold, isTrue);
      expect(failing.meetsThreshold, isFalse);
    });

    test('coverage debe ser 1.0 si total es 0', () {
      const report = DocumentationReport(
        filesAnalyzed: 0,
        documented: 0,
        total: 0,
        issues: [],
      );

      expect(report.coverage, equals(1.0));
    });
  });
}
