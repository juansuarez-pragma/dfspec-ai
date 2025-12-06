import 'package:dfspec/src/models/ai_platform_config.dart';
import 'package:dfspec/src/models/ai_platform_registry.dart';
import 'package:test/test.dart';

void main() {
  group('AiPlatformRegistry', () {
    group('platforms', () {
      test('debe contener plataformas CLI-based', () {
        expect(AiPlatformRegistry.platforms, contains('claude'));
        expect(AiPlatformRegistry.platforms, contains('gemini'));
        expect(AiPlatformRegistry.platforms, contains('cursor'));
        expect(AiPlatformRegistry.platforms, contains('codex'));
        expect(AiPlatformRegistry.platforms, contains('qwen'));
        expect(AiPlatformRegistry.platforms, contains('amazonq'));
      });

      test('debe contener plataformas IDE-based', () {
        expect(AiPlatformRegistry.platforms, contains('copilot'));
        expect(AiPlatformRegistry.platforms, contains('windsurf'));
        expect(AiPlatformRegistry.platforms, contains('kilocode'));
        expect(AiPlatformRegistry.platforms, contains('roo'));
      });

      test('debe tener al menos 10 plataformas', () {
        expect(AiPlatformRegistry.platforms.length, greaterThanOrEqualTo(10));
      });
    });

    group('getPlatform', () {
      test('debe retornar plataforma existente', () {
        final claude = AiPlatformRegistry.getPlatform('claude');
        expect(claude, isNotNull);
        expect(claude!.id, equals('claude'));
        expect(claude.name, equals('Claude Code'));
      });

      test('debe retornar null para plataforma inexistente', () {
        final unknown = AiPlatformRegistry.getPlatform('unknown');
        expect(unknown, isNull);
      });
    });

    group('all', () {
      test('debe retornar lista de todas las plataformas', () {
        final all = AiPlatformRegistry.all;
        expect(all, isNotEmpty);
        expect(all.length, equals(AiPlatformRegistry.platforms.length));
      });

      test('todas las plataformas deben tener id unico', () {
        final ids = AiPlatformRegistry.all.map((p) => p.id).toList();
        expect(ids.toSet().length, equals(ids.length));
      });
    });

    group('allIds', () {
      test('debe retornar lista de IDs', () {
        final ids = AiPlatformRegistry.allIds;
        expect(ids, contains('claude'));
        expect(ids, contains('gemini'));
      });
    });

    group('exists', () {
      test('debe retornar true para plataforma existente', () {
        expect(AiPlatformRegistry.exists('claude'), isTrue);
        expect(AiPlatformRegistry.exists('gemini'), isTrue);
      });

      test('debe retornar false para plataforma inexistente', () {
        expect(AiPlatformRegistry.exists('unknown'), isFalse);
      });
    });

    group('cliRequired', () {
      test('debe retornar solo plataformas que requieren CLI', () {
        final cliPlatforms = AiPlatformRegistry.cliRequired;
        for (final platform in cliPlatforms) {
          expect(platform.requiresCli, isTrue);
        }
        expect(cliPlatforms.any((p) => p.id == 'claude'), isTrue);
        expect(cliPlatforms.any((p) => p.id == 'gemini'), isTrue);
      });
    });

    group('ideBased', () {
      test('debe retornar solo plataformas IDE-based', () {
        final idePlatforms = AiPlatformRegistry.ideBased;
        for (final platform in idePlatforms) {
          expect(platform.requiresCli, isFalse);
        }
        expect(idePlatforms.any((p) => p.id == 'copilot'), isTrue);
        expect(idePlatforms.any((p) => p.id == 'windsurf'), isTrue);
      });
    });

    group('byFormat', () {
      test('debe filtrar por formato markdown', () {
        final mdPlatforms = AiPlatformRegistry.byFormat(CommandFormat.markdown);
        for (final platform in mdPlatforms) {
          expect(platform.commandFormat, equals(CommandFormat.markdown));
        }
        expect(mdPlatforms.any((p) => p.id == 'claude'), isTrue);
      });

      test('debe filtrar por formato toml', () {
        final tomlPlatforms = AiPlatformRegistry.byFormat(CommandFormat.toml);
        for (final platform in tomlPlatforms) {
          expect(platform.commandFormat, equals(CommandFormat.toml));
        }
        expect(tomlPlatforms.any((p) => p.id == 'gemini'), isTrue);
      });
    });

    group('defaultPlatform', () {
      test('debe retornar Claude como default', () {
        final defaultPlatform = AiPlatformRegistry.defaultPlatform;
        expect(defaultPlatform.id, equals('claude'));
      });
    });

    group('configuraciones especificas', () {
      test('Claude debe tener configuracion correcta', () {
        final claude = AiPlatformRegistry.getPlatform('claude')!;
        expect(claude.commandFolder, equals('.claude/commands/'));
        expect(claude.commandFormat, equals(CommandFormat.markdown));
        expect(claude.contextFile, equals('CLAUDE.md'));
        expect(claude.requiresCli, isTrue);
        expect(claude.cliCommand, equals('claude'));
      });

      test('Gemini debe usar formato TOML', () {
        final gemini = AiPlatformRegistry.getPlatform('gemini')!;
        expect(gemini.commandFolder, equals('.gemini/commands/'));
        expect(gemini.commandFormat, equals(CommandFormat.toml));
        expect(gemini.contextFile, equals('GEMINI.md'));
        expect(gemini.requiresCli, isTrue);
        expect(gemini.cliCommand, equals('gemini'));
      });

      test('Copilot no debe requerir CLI', () {
        final copilot = AiPlatformRegistry.getPlatform('copilot')!;
        expect(copilot.commandFolder, equals('.github/agents/'));
        expect(copilot.requiresCli, isFalse);
      });

      test('Cursor debe tener .cursorrules como contextFile', () {
        final cursor = AiPlatformRegistry.getPlatform('cursor')!;
        expect(cursor.contextFile, equals('.cursorrules'));
      });
    });
  });
}
