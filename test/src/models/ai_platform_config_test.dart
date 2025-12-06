import 'package:dfspec/src/models/ai_platform_config.dart';
import 'package:test/test.dart';

void main() {
  group('CommandFormat', () {
    test('debe tener valores markdown y toml', () {
      expect(CommandFormat.values, contains(CommandFormat.markdown));
      expect(CommandFormat.values, contains(CommandFormat.toml));
    });

    test('debe tener extension de archivo correcta', () {
      expect(CommandFormat.markdown.fileExtension, equals('.md'));
      expect(CommandFormat.toml.fileExtension, equals('.toml'));
    });
  });

  group('AiPlatformConfig', () {
    test('debe crear instancia con todos los campos requeridos', () {
      const config = AiPlatformConfig(
        id: 'claude',
        name: 'Claude Code',
        commandFolder: '.claude/commands/',
        commandFormat: CommandFormat.markdown,
      );

      expect(config.id, equals('claude'));
      expect(config.name, equals('Claude Code'));
      expect(config.commandFolder, equals('.claude/commands/'));
      expect(config.commandFormat, equals(CommandFormat.markdown));
    });

    test('debe tener valores por defecto correctos', () {
      const config = AiPlatformConfig(
        id: 'test',
        name: 'Test Agent',
        commandFolder: '.test/',
        commandFormat: CommandFormat.markdown,
      );

      expect(config.contextFile, isNull);
      expect(config.installUrl, isNull);
      expect(config.requiresCli, isFalse);
      expect(config.cliCommand, isNull);
    });

    test('debe aceptar todos los campos opcionales', () {
      const config = AiPlatformConfig(
        id: 'claude',
        name: 'Claude Code',
        commandFolder: '.claude/commands/',
        commandFormat: CommandFormat.markdown,
        contextFile: 'CLAUDE.md',
        installUrl: 'https://claude.ai/code',
        requiresCli: true,
        cliCommand: 'claude',
      );

      expect(config.contextFile, equals('CLAUDE.md'));
      expect(config.installUrl, equals('https://claude.ai/code'));
      expect(config.requiresCli, isTrue);
      expect(config.cliCommand, equals('claude'));
    });

    group('isCliAvailable', () {
      test('debe retornar true si no requiere CLI', () async {
        const config = AiPlatformConfig(
          id: 'copilot',
          name: 'GitHub Copilot',
          commandFolder: '.github/agents/',
          commandFormat: CommandFormat.markdown,
        );

        final available = await config.isCliAvailable();
        expect(available, isTrue);
      });

      test('debe retornar false si requiere CLI pero no tiene cliCommand', () async {
        const config = AiPlatformConfig(
          id: 'test',
          name: 'Test',
          commandFolder: '.test/',
          commandFormat: CommandFormat.markdown,
          requiresCli: true,
        );

        final available = await config.isCliAvailable();
        expect(available, isFalse);
      });
    });

    group('getCommandFileName', () {
      test('debe generar nombre de archivo con extension markdown', () {
        const config = AiPlatformConfig(
          id: 'claude',
          name: 'Claude Code',
          commandFolder: '.claude/commands/',
          commandFormat: CommandFormat.markdown,
        );

        expect(config.getCommandFileName('df-spec'), equals('df-spec.md'));
        expect(config.getCommandFileName('df-plan'), equals('df-plan.md'));
      });

      test('debe generar nombre de archivo con extension toml', () {
        const config = AiPlatformConfig(
          id: 'gemini',
          name: 'Gemini CLI',
          commandFolder: '.gemini/commands/',
          commandFormat: CommandFormat.toml,
        );

        expect(config.getCommandFileName('df-spec'), equals('df-spec.toml'));
        expect(config.getCommandFileName('df-plan'), equals('df-plan.toml'));
      });
    });

    group('getCommandFilePath', () {
      test('debe generar path completo del archivo', () {
        const config = AiPlatformConfig(
          id: 'claude',
          name: 'Claude Code',
          commandFolder: '.claude/commands/',
          commandFormat: CommandFormat.markdown,
        );

        expect(
          config.getCommandFilePath('df-spec'),
          equals('.claude/commands/df-spec.md'),
        );
      });

      test('debe manejar carpetas sin trailing slash', () {
        const config = AiPlatformConfig(
          id: 'gemini',
          name: 'Gemini CLI',
          commandFolder: '.gemini/commands',
          commandFormat: CommandFormat.toml,
        );

        expect(
          config.getCommandFilePath('df-spec'),
          equals('.gemini/commands/df-spec.toml'),
        );
      });
    });

    group('toJson', () {
      test('debe serializar correctamente', () {
        const config = AiPlatformConfig(
          id: 'claude',
          name: 'Claude Code',
          commandFolder: '.claude/commands/',
          commandFormat: CommandFormat.markdown,
          contextFile: 'CLAUDE.md',
          requiresCli: true,
          cliCommand: 'claude',
        );

        final json = config.toJson();

        expect(json['id'], equals('claude'));
        expect(json['name'], equals('Claude Code'));
        expect(json['commandFolder'], equals('.claude/commands/'));
        expect(json['commandFormat'], equals('markdown'));
        expect(json['contextFile'], equals('CLAUDE.md'));
        expect(json['requiresCli'], isTrue);
        expect(json['cliCommand'], equals('claude'));
      });
    });

    group('equality', () {
      test('debe ser igual con mismos valores', () {
        const config1 = AiPlatformConfig(
          id: 'claude',
          name: 'Claude Code',
          commandFolder: '.claude/commands/',
          commandFormat: CommandFormat.markdown,
        );

        const config2 = AiPlatformConfig(
          id: 'claude',
          name: 'Claude Code',
          commandFolder: '.claude/commands/',
          commandFormat: CommandFormat.markdown,
        );

        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('debe ser diferente con distintos valores', () {
        const config1 = AiPlatformConfig(
          id: 'claude',
          name: 'Claude Code',
          commandFolder: '.claude/commands/',
          commandFormat: CommandFormat.markdown,
        );

        const config2 = AiPlatformConfig(
          id: 'gemini',
          name: 'Gemini CLI',
          commandFolder: '.gemini/commands/',
          commandFormat: CommandFormat.toml,
        );

        expect(config1, isNot(equals(config2)));
      });
    });
  });
}
