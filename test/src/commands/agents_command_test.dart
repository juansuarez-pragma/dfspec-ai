import 'package:dfspec/dfspec.dart';
import 'package:test/test.dart';

void main() {
  group('AgentsCommand', () {
    late AgentsCommand command;

    setUp(() {
      command = AgentsCommand();
    });

    test('tiene el nombre correcto', () {
      expect(command.name, equals('agents'));
    });

    test('tiene descripcion', () {
      expect(command.description, isNotEmpty);
      expect(command.description, contains('agentes'));
    });

    test('soporta option --info', () {
      expect(command.argParser.options.containsKey('info'), isTrue);
    });

    test('soporta option --category', () {
      expect(command.argParser.options.containsKey('category'), isTrue);
    });

    test('--category tiene valores permitidos', () {
      final option = command.argParser.options['category']!;
      expect(option.allowed, contains('orchestration'));
      expect(option.allowed, contains('quality'));
      expect(option.allowed, contains('implementation'));
      expect(option.allowed, contains('documentation'));
    });

    test('soporta option --capability', () {
      expect(command.argParser.options.containsKey('capability'), isTrue);
    });

    test('soporta flag --json', () {
      expect(command.argParser.options.containsKey('json'), isTrue);
    });

    test('--info tiene abreviatura -i', () {
      final option = command.argParser.options['info']!;
      expect(option.abbr, equals('i'));
    });

    test('--category tiene abreviatura -c', () {
      final option = command.argParser.options['category']!;
      expect(option.abbr, equals('c'));
    });
  });
}
