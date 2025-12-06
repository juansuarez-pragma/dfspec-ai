import 'package:dfspec/dfspec.dart';
import 'package:test/test.dart';

void main() {
  group('ArtifactTemplates', () {
    test('all contiene 6 templates', () {
      expect(ArtifactTemplates.all.length, equals(6));
    });

    test('getTemplate retorna template para cada tipo', () {
      for (final type in SpecType.values) {
        final template = ArtifactTemplates.getTemplate(type);

        expect(template.type, equals(type));
        expect(template.content, isNotEmpty);
        expect(template.name, isNotEmpty);
      }
    });

    test('template feature tiene estructura correcta', () {
      final template = ArtifactTemplates.getTemplate(SpecType.feature);

      expect(template.content, contains('# Especificacion'));
      expect(template.content, contains('## Resumen'));
      expect(template.content, contains('## Requisitos Funcionales'));
      expect(template.content, contains('## Criterios de Aceptacion'));
      expect(template.content, contains('{{title}}'));
    });

    test('template architecture tiene estructura ADR', () {
      final template = ArtifactTemplates.getTemplate(SpecType.architecture);

      expect(template.content, contains('# ADR:'));
      expect(template.content, contains('## Contexto'));
      expect(template.content, contains('## Decision'));
      expect(template.content, contains('## Consecuencias'));
      expect(template.content, contains('{{status}}'));
    });

    test('template security tiene OWASP', () {
      final template = ArtifactTemplates.getTemplate(SpecType.security);

      expect(template.content, contains('OWASP'));
      expect(template.content, contains('STRIDE'));
      expect(template.content, contains('{{risk_level}}'));
    });

    test('template performance tiene metricas', () {
      final template = ArtifactTemplates.getTemplate(SpecType.performance);

      expect(template.content, contains('60fps'));
      expect(template.content, contains('Frame time'));
      expect(template.content, contains('{{target_fps}}'));
    });

    test('template api tiene estructura de contrato', () {
      final template = ArtifactTemplates.getTemplate(SpecType.api);

      expect(template.content, contains('Endpoints'));
      expect(template.content, contains('Response'));
      expect(template.content, contains('{{version}}'));
    });

    test('template plan tiene estructura TDD', () {
      final template = ArtifactTemplates.getTemplate(SpecType.plan);

      expect(template.content, contains('## Arquitectura'));
      expect(template.content, contains('TDD'));
      expect(template.content, contains('Domain Layer'));
      expect(template.content, contains('{{spec_ref}}'));
    });

    test('todos los templates tienen footer DFSpec', () {
      for (final template in ArtifactTemplates.all) {
        expect(
          template.content,
          contains('Generado con DFSpec'),
          reason: '${template.name} deberia tener footer',
        );
      }
    });
  });
}
