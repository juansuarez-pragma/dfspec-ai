import 'package:dfspec/dfspec.dart';
import 'package:test/test.dart';

void main() {
  group('InstallCommand', () {
    late InstallCommand command;

    setUp(() {
      command = InstallCommand();
    });

    test('tiene el nombre correcto', () {
      expect(command.name, equals('install'));
    });

    test('tiene descripcion', () {
      expect(command.description, isNotEmpty);
      expect(command.description, contains('comandos slash'));
    });

    test('tiene invocation correcta', () {
      expect(command.invocation, contains('dfspec install'));
    });

    group('flags existentes', () {
      test('soporta flag --all', () {
        expect(command.argParser.options.containsKey('all'), isTrue);
      });

      test('soporta flag --force', () {
        expect(command.argParser.options.containsKey('force'), isTrue);
      });

      test('soporta flag --list', () {
        expect(command.argParser.options.containsKey('list'), isTrue);
      });

      test('soporta option --command', () {
        expect(command.argParser.options.containsKey('command'), isTrue);
      });

      test('flag --all tiene abreviatura -a', () {
        final option = command.argParser.options['all']!;
        expect(option.abbr, equals('a'));
      });

      test('flag --list tiene abreviatura -l', () {
        final option = command.argParser.options['list']!;
        expect(option.abbr, equals('l'));
      });

      test('option --command permite multiples valores', () {
        final option = command.argParser.options['command']!;
        expect(option.isMultiple, isTrue);
      });
    });

    group('soporte multi-agente', () {
      test('soporta option --agent', () {
        expect(command.argParser.options.containsKey('agent'), isTrue);
      });

      test('option --agent permite multiples valores', () {
        final option = command.argParser.options['agent']!;
        expect(option.isMultiple, isTrue);
      });

      test('option --agent tiene valores permitidos de plataformas', () {
        final option = command.argParser.options['agent']!;
        expect(option.allowed, isNotEmpty);
        expect(option.allowed, contains('claude'));
        expect(option.allowed, contains('gemini'));
        expect(option.allowed, contains('cursor'));
      });

      test('soporta flag --all-agents', () {
        expect(command.argParser.options.containsKey('all-agents'), isTrue);
      });

      test('soporta flag --detect', () {
        expect(command.argParser.options.containsKey('detect'), isTrue);
      });

      test('flag --detect tiene abreviatura -d', () {
        final option = command.argParser.options['detect']!;
        expect(option.abbr, equals('d'));
      });

      test('soporta flag --list-agents', () {
        expect(command.argParser.options.containsKey('list-agents'), isTrue);
      });

      test('valores permitidos de --agent incluyen todas las plataformas', () {
        final option = command.argParser.options['agent']!;
        final allowedIds = option.allowed!;

        for (final id in AiPlatformRegistry.allIds) {
          expect(
            allowedIds,
            contains(id),
            reason: 'Plataforma $id deberia estar en allowed',
          );
        }
      });
    });
  });
}
