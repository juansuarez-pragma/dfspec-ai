import 'package:dfspec/src/models/documentation_spec.dart';
import 'package:test/test.dart';

void main() {
  group('DocumentationType', () {
    test('debe tener labels correctos', () {
      expect(DocumentationType.api.label, equals('API'));
      expect(DocumentationType.readme.label, equals('README'));
      expect(DocumentationType.changelog.label, equals('Changelog'));
      expect(DocumentationType.architecture.label, equals('Arquitectura'));
      expect(DocumentationType.specification.label, equals('Especificación'));
      expect(DocumentationType.implementationPlan.label, equals('Plan'));
    });
  });

  group('DocumentSection', () {
    test('debe crear seccion con contenido', () {
      const section = DocumentSection(
        title: 'Introducción',
        content: 'Este es el contenido.',
      );

      expect(section.title, equals('Introducción'));
      expect(section.content, equals('Este es el contenido.'));
      expect(section.level, equals(2));
    });

    test('debe generar markdown correcto', () {
      const section = DocumentSection(
        title: 'Instalación',
        content: 'Ejecutar `dart pub get`.',
      );

      final markdown = section.toMarkdown();

      expect(markdown, contains('## Instalación'));
      expect(markdown, contains('Ejecutar `dart pub get`.'));
    });

    test('debe generar subsecciones', () {
      const section = DocumentSection(
        title: 'Principal',
        content: 'Contenido principal.',
        subsections: [
          DocumentSection(
            title: 'Sub 1',
            content: 'Contenido sub 1.',
            level: 3,
          ),
          DocumentSection(
            title: 'Sub 2',
            content: 'Contenido sub 2.',
            level: 3,
          ),
        ],
      );

      final markdown = section.toMarkdown();

      expect(markdown, contains('## Principal'));
      expect(markdown, contains('### Sub 1'));
      expect(markdown, contains('### Sub 2'));
    });

    test('debe serializar y deserializar', () {
      const original = DocumentSection(
        title: 'Test',
        content: 'Content',
        level: 3,
      );

      final json = original.toJson();
      final restored = DocumentSection.fromJson(json);

      expect(restored.title, equals(original.title));
      expect(restored.content, equals(original.content));
      expect(restored.level, equals(original.level));
    });
  });

  group('DocumentationSpec', () {
    test('debe crear especificacion completa', () {
      const spec = DocumentationSpec(
        type: DocumentationType.readme,
        title: 'Mi Proyecto',
        description: 'Un proyecto genial.',
        sections: [
          DocumentSection(title: 'Uso', content: 'Ejemplo de uso.'),
        ],
        metadata: {'version': '1.0.0'},
        outputPath: 'README.md',
      );

      expect(spec.type, equals(DocumentationType.readme));
      expect(spec.title, equals('Mi Proyecto'));
      expect(spec.sections.length, equals(1));
    });

    test('debe generar documento completo', () {
      const spec = DocumentationSpec(
        type: DocumentationType.readme,
        title: 'Test Project',
        description: 'A test project.',
        metadata: {'version': '1.0.0', 'author': 'Test'},
        sections: [
          DocumentSection(title: 'Instalación', content: 'npm install'),
          DocumentSection(title: 'Uso', content: 'npm start'),
        ],
      );

      final content = spec.generate();

      expect(content, contains('# Test Project'));
      expect(content, contains('A test project.'));
      expect(content, contains('**Versión:** 1.0.0'));
      expect(content, contains('## Instalación'));
      expect(content, contains('## Uso'));
    });

    test('debe serializar y deserializar', () {
      const original = DocumentationSpec(
        type: DocumentationType.architecture,
        title: 'Arquitectura',
        description: 'Descripción',
        outputPath: 'docs/ARCH.md',
      );

      final json = original.toJson();
      final restored = DocumentationSpec.fromJson(json);

      expect(restored.type, equals(original.type));
      expect(restored.title, equals(original.title));
      expect(restored.outputPath, equals(original.outputPath));
    });
  });

  group('DocumentationResult', () {
    test('debe calcular estadisticas correctamente', () {
      const spec = DocumentationSpec(
        type: DocumentationType.readme,
        title: 'Test',
      );

      const result = DocumentationResult(
        spec: spec,
        content: 'Line 1\nLine 2\nLine 3\nWord1 Word2 Word3 Word4',
        outputPath: 'README.md',
      );

      expect(result.lineCount, equals(4));
      expect(result.wordCount, greaterThan(0));
      expect(result.hasWarnings, isFalse);
    });

    test('debe detectar warnings', () {
      const spec = DocumentationSpec(
        type: DocumentationType.readme,
        title: 'Test',
      );

      const result = DocumentationResult(
        spec: spec,
        content: 'Content',
        outputPath: 'README.md',
        warnings: ['Warning 1', 'Warning 2'],
      );

      expect(result.hasWarnings, isTrue);
      expect(result.warnings.length, equals(2));
    });
  });

  group('DocumentationTemplates', () {
    group('featureReadme', () {
      test('debe generar README de feature', () {
        final spec = DocumentationTemplates.featureReadme(
          featureName: 'city-search',
          description: 'Búsqueda de ciudades',
          useCases: ['Buscar', 'Seleccionar'],
          components: ['CityEntity', 'SearchCities'],
        );

        expect(spec.type, equals(DocumentationType.readme));
        expect(spec.title, contains('city-search'));
        expect(spec.outputPath, contains('city-search'));

        final content = spec.generate();
        expect(content, contains('Búsqueda de ciudades'));
        expect(content, contains('Buscar'));
        expect(content, contains('`CityEntity`'));
      });
    });

    group('architecture', () {
      test('debe generar documentacion de arquitectura', () {
        final spec = DocumentationTemplates.architecture(
          projectName: 'MyApp',
          layers: {
            'Domain': 'Entidades y casos de uso',
            'Data': 'Implementaciones',
          },
        );

        expect(spec.type, equals(DocumentationType.architecture));

        final content = spec.generate();
        expect(content, contains('MyApp'));
        expect(content, contains('Clean Architecture'));
        expect(content, contains('Domain'));
        expect(content, contains('Data'));
      });
    });

    group('changelog', () {
      test('debe generar entrada de changelog', () {
        final spec = DocumentationTemplates.changelog(
          version: '1.2.0',
          date: DateTime(2024, 6, 15),
          added: ['Feature A', 'Feature B'],
          fixed: ['Bug X'],
          changed: ['Behavior Y'],
        );

        expect(spec.type, equals(DocumentationType.changelog));

        final content = spec.generate();
        expect(content, contains('[1.2.0]'));
        expect(content, contains('2024-06-15'));
        expect(content, contains('### Added'));
        expect(content, contains('Feature A'));
        expect(content, contains('### Fixed'));
        expect(content, contains('Bug X'));
      });
    });

    group('featureSpec', () {
      test('debe generar especificacion de feature', () {
        final spec = DocumentationTemplates.featureSpec(
          featureName: 'user-auth',
          description: 'Autenticación de usuarios',
          acceptanceCriteria: [
            'Usuario puede registrarse',
            'Usuario puede iniciar sesión',
          ],
          outOfScope: ['OAuth'],
        );

        expect(spec.type, equals(DocumentationType.specification));

        final content = spec.generate();
        expect(content, contains('user-auth'));
        expect(content, contains('Criterios de Aceptación'));
        expect(content, contains('1. Usuario puede registrarse'));
        expect(content, contains('Fuera de Alcance'));
        expect(content, contains('OAuth'));
      });
    });

    group('implementationPlan', () {
      test('debe generar plan de implementacion', () {
        final spec = DocumentationTemplates.implementationPlan(
          featureName: 'city-search',
          steps: const [
            ImplementationStep(
              name: 'Entity',
              description: 'Crear entidad City',
              files: ['lib/src/domain/entities/city.dart'],
              tests: ['test/unit/domain/city_test.dart'],
            ),
            ImplementationStep(
              name: 'Repository',
              description: 'Crear repositorio',
              files: ['lib/src/domain/repositories/city_repository.dart'],
              tests: ['test/unit/domain/city_repository_test.dart'],
              dependencies: ['Entity'],
            ),
          ],
        );

        expect(spec.type, equals(DocumentationType.implementationPlan));

        final content = spec.generate();
        expect(content, contains('city-search'));
        expect(content, contains('Paso 1: Entity'));
        expect(content, contains('Paso 2: Repository'));
        expect(content, contains('TDD: RED → GREEN → REFACTOR'));
      });
    });
  });

  group('ImplementationStep', () {
    test('debe crear paso con todos los campos', () {
      const step = ImplementationStep(
        name: 'Setup',
        description: 'Initial setup',
        files: ['file1.dart', 'file2.dart'],
        tests: ['test1.dart'],
        dependencies: ['Dep1'],
      );

      expect(step.name, equals('Setup'));
      expect(step.files.length, equals(2));
      expect(step.tests.length, equals(1));
      expect(step.dependencies.length, equals(1));
    });
  });

  group('ApiDocumentation', () {
    test('debe generar dartdoc basico', () {
      const apiDoc = ApiDocumentation(
        name: 'calculate',
        type: 'method',
        description: 'Calcula el resultado.',
      );

      final dartdoc = apiDoc.toDartDoc();

      expect(dartdoc, contains('/// Calcula el resultado.'));
    });

    test('debe generar dartdoc con parametros', () {
      const apiDoc = ApiDocumentation(
        name: 'add',
        type: 'method',
        description: 'Suma dos números.',
        parameters: [
          ApiParameter(
            name: 'a',
            type: 'int',
            description: 'Primer número',
          ),
          ApiParameter(
            name: 'b',
            type: 'int',
            description: 'Segundo número',
          ),
        ],
        returns: 'la suma de a y b',
      );

      final dartdoc = apiDoc.toDartDoc();

      expect(dartdoc, contains('/// [a] Primer número'));
      expect(dartdoc, contains('/// [b] Segundo número'));
      expect(dartdoc, contains('/// Returns la suma de a y b'));
    });

    test('debe generar dartdoc con ejemplos', () {
      const apiDoc = ApiDocumentation(
        name: 'greet',
        type: 'method',
        description: 'Saluda al usuario.',
        examples: [
          "final greeting = greet('Juan');",
          "print(greeting); // 'Hola Juan'",
        ],
      );

      final dartdoc = apiDoc.toDartDoc();

      expect(dartdoc, contains('/// Example:'));
      expect(dartdoc, contains('/// ```dart'));
      expect(dartdoc, contains("/// final greeting = greet('Juan');"));
    });

    test('debe generar dartdoc con throws y seeAlso', () {
      const apiDoc = ApiDocumentation(
        name: 'readFile',
        type: 'method',
        description: 'Lee un archivo.',
        throws: ['FileNotFoundException si el archivo no existe'],
        seeAlso: ['writeFile', 'deleteFile'],
      );

      final dartdoc = apiDoc.toDartDoc();

      expect(dartdoc, contains('/// Throws FileNotFoundException'));
      expect(dartdoc, contains('/// See also:'));
      expect(dartdoc, contains('/// - [writeFile]'));
    });
  });

  group('ApiParameter', () {
    test('debe crear parametro requerido', () {
      const param = ApiParameter(
        name: 'id',
        type: 'int',
        description: 'ID del elemento',
      );

      expect(param.isRequired, isTrue);
      expect(param.defaultValue, isNull);
    });

    test('debe crear parametro opcional con default', () {
      const param = ApiParameter(
        name: 'limit',
        type: 'int',
        description: 'Límite de resultados',
        isRequired: false,
        defaultValue: '10',
      );

      expect(param.isRequired, isFalse);
      expect(param.defaultValue, equals('10'));
    });
  });
}
