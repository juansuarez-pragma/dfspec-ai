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
}
