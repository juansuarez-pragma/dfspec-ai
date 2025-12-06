import 'package:dfspec/dfspec.dart';
import 'package:test/test.dart';

void main() {
  group('SlashCommandTemplates', () {
    test('available contiene 13 comandos', () {
      expect(SlashCommandTemplates.available.length, equals(13));
    });

    test('essential contiene 5 comandos basicos', () {
      expect(SlashCommandTemplates.essential.length, equals(5));
      expect(SlashCommandTemplates.essential, contains('df-spec'));
      expect(SlashCommandTemplates.essential, contains('df-plan'));
      expect(SlashCommandTemplates.essential, contains('df-implement'));
      expect(SlashCommandTemplates.essential, contains('df-test'));
      expect(SlashCommandTemplates.essential, contains('df-verify'));
    });

    test('essential es subconjunto de available', () {
      for (final cmd in SlashCommandTemplates.essential) {
        expect(
          SlashCommandTemplates.available,
          contains(cmd),
          reason: '$cmd deberia estar en available',
        );
      }
    });

    test('getInfo retorna descripcion para comandos validos', () {
      final info = SlashCommandTemplates.getInfo('df-spec');

      expect(info, isA<Map<String, String>>());
      expect(info['description'], isNotNull);
      expect(info['description'], isNotEmpty);
    });

    test('getInfo retorna mensaje por defecto para comandos invalidos', () {
      final info = SlashCommandTemplates.getInfo('comando-inexistente');

      expect(info['description'], equals('Sin descripcion'));
    });

    test('getTemplate retorna contenido para comandos validos', () {
      final template = SlashCommandTemplates.getTemplate('df-spec');

      expect(template, contains('---'));
      expect(template, contains('description:'));
      expect(template, contains('allowed-tools:'));
      expect(template, contains(r'$ARGUMENTS'));
    });

    test('getTemplate retorna mensaje de error para comandos invalidos', () {
      final template = SlashCommandTemplates.getTemplate('invalido');

      expect(template, equals('# Comando no encontrado'));
    });

    test('todos los comandos tienen template valido', () {
      for (final cmd in SlashCommandTemplates.available) {
        final template = SlashCommandTemplates.getTemplate(cmd);

        expect(
          template,
          isNot(equals('# Comando no encontrado')),
          reason: '$cmd deberia tener template',
        );
        expect(
          template,
          contains('---'),
          reason: '$cmd deberia tener frontmatter',
        );
      }
    });

    test('todos los comandos tienen info', () {
      for (final cmd in SlashCommandTemplates.available) {
        final info = SlashCommandTemplates.getInfo(cmd);

        expect(
          info['description'],
          isNot(equals('Sin descripcion')),
          reason: '$cmd deberia tener descripcion',
        );
      }
    });
  });
}
