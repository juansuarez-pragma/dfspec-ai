import 'package:dfspec/dfspec.dart';
import 'package:test/test.dart';

void main() {
  group('InitCommand', () {
    late InitCommand command;

    setUp(() {
      command = InitCommand();
    });

    test('tiene el nombre correcto', () {
      expect(command.name, equals('init'));
    });

    test('tiene descripcion', () {
      expect(command.description, isNotEmpty);
      expect(command.description, contains('Inicializa'));
    });

    test('tiene invocation correcta', () {
      expect(command.invocation, contains('dfspec init'));
    });

    group('flags existentes', () {
      test('soporta flag --force', () {
        expect(command.argParser.options.containsKey('force'), isTrue);
      });

      test('soporta flag --minimal', () {
        expect(command.argParser.options.containsKey('minimal'), isTrue);
      });

      test('flag --force tiene abreviatura -f', () {
        final option = command.argParser.options['force']!;
        expect(option.abbr, equals('f'));
      });

      test('flag --minimal tiene abreviatura -m', () {
        final option = command.argParser.options['minimal']!;
        expect(option.abbr, equals('m'));
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

      test('valores permitidos incluyen todas las plataformas', () {
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

      test('soporta flag --all-agents', () {
        expect(command.argParser.options.containsKey('all-agents'), isTrue);
      });

      test('soporta flag --with-context', () {
        expect(command.argParser.options.containsKey('with-context'), isTrue);
      });
    });
  });
}
