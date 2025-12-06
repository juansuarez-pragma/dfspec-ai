import 'package:dfspec/dfspec.dart';
import 'package:test/test.dart';

void main() {
  group('SpecType', () {
    test('tiene 6 tipos de especificacion', () {
      expect(SpecType.values.length, equals(6));
    });

    test('fromString retorna tipo correcto', () {
      expect(SpecType.fromString('feature'), equals(SpecType.feature));
      expect(SpecType.fromString('architecture'), equals(SpecType.architecture));
      expect(SpecType.fromString('security'), equals(SpecType.security));
      expect(SpecType.fromString('performance'), equals(SpecType.performance));
      expect(SpecType.fromString('api'), equals(SpecType.api));
      expect(SpecType.fromString('plan'), equals(SpecType.plan));
    });

    test('fromString retorna null para tipo invalido', () {
      expect(SpecType.fromString('invalido'), isNull);
    });

    test('cada tipo tiene value y description', () {
      for (final type in SpecType.values) {
        expect(type.value, isNotEmpty);
        expect(type.description, isNotEmpty);
      }
    });
  });

  group('SpecTemplate', () {
    test('render reemplaza variables', () {
      const template = SpecTemplate(
        type: SpecType.feature,
        name: 'Test',
        content: 'Titulo: {{title}}, Autor: {{author}}',
        variables: {'title': 'Default', 'author': 'Unknown'},
      );

      final result = template.render({'title': 'Mi Feature', 'author': 'Juan'});

      expect(result, equals('Titulo: Mi Feature, Autor: Juan'));
    });

    test('render usa valores por defecto', () {
      const template = SpecTemplate(
        type: SpecType.feature,
        name: 'Test',
        content: 'Titulo: {{title}}',
        variables: {'title': 'Default'},
      );

      final result = template.render({});

      expect(result, equals('Titulo: Default'));
    });

    test('suggestedFilename genera nombre correcto', () {
      const template = SpecTemplate(
        type: SpecType.feature,
        name: 'Test',
        content: '',
      );

      expect(
        template.suggestedFilename('Mi Nueva Feature'),
        equals('mi-nueva-feature.feature.md'),
      );
    });

    test('suggestedFilename sanitiza caracteres especiales', () {
      const template = SpecTemplate(
        type: SpecType.architecture,
        name: 'Test',
        content: '',
      );

      expect(
        template.suggestedFilename(r'Feature con !@#$%^&*()'),
        equals('feature-con.architecture.md'),
      );
    });

    test('suggestedDirectory retorna directorio correcto', () {
      expect(
        const SpecTemplate(
          type: SpecType.feature,
          name: 'T',
          content: '',
        ).suggestedDirectory(),
        equals('specs/features'),
      );

      expect(
        const SpecTemplate(
          type: SpecType.architecture,
          name: 'T',
          content: '',
        ).suggestedDirectory(),
        equals('docs/decisions'),
      );

      expect(
        const SpecTemplate(
          type: SpecType.security,
          name: 'T',
          content: '',
        ).suggestedDirectory(),
        equals('specs/security'),
      );
    });
  });
}
