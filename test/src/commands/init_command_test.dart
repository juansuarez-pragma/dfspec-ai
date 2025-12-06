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

      test('soporta flag --with-context', () {
        expect(command.argParser.options.containsKey('with-context'), isTrue);
      });

      test('flag --with-context tiene default true', () {
        final option = command.argParser.options['with-context']!;
        expect(option.defaultsTo, isTrue);
      });
    });

    group('arquitectura Claude-first', () {
      test('no soporta option --agent (eliminado)', () {
        expect(command.argParser.options.containsKey('agent'), isFalse);
      });

      test('no soporta flag --all-agents (eliminado)', () {
        expect(command.argParser.options.containsKey('all-agents'), isFalse);
      });
    });
  });
}
