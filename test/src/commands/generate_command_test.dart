import 'package:dfspec/dfspec.dart';
import 'package:test/test.dart';

void main() {
  group('GenerateCommand', () {
    late GenerateCommand command;

    setUp(() {
      command = GenerateCommand();
    });

    test('tiene el nombre correcto', () {
      expect(command.name, equals('generate'));
    });

    test('tiene aliases', () {
      expect(command.aliases, contains('gen'));
      expect(command.aliases, contains('g'));
    });

    test('tiene descripcion', () {
      expect(command.description, isNotEmpty);
      expect(command.description, contains('especificacion'));
    });

    test('soporta option --type', () {
      expect(command.argParser.options.containsKey('type'), isTrue);
    });

    test('--type tiene valores permitidos', () {
      final option = command.argParser.options['type']!;
      expect(option.allowed, contains('feature'));
      expect(option.allowed, contains('architecture'));
      expect(option.allowed, contains('security'));
      expect(option.allowed, contains('performance'));
      expect(option.allowed, contains('api'));
      expect(option.allowed, contains('plan'));
    });

    test('soporta option --output', () {
      expect(command.argParser.options.containsKey('output'), isTrue);
    });

    test('soporta option --author', () {
      expect(command.argParser.options.containsKey('author'), isTrue);
    });

    test('soporta flag --force', () {
      expect(command.argParser.options.containsKey('force'), isTrue);
    });

    test('soporta flag --list', () {
      expect(command.argParser.options.containsKey('list'), isTrue);
    });

    test('flag --type tiene valor por defecto feature', () {
      final option = command.argParser.options['type']!;
      expect(option.defaultsTo, equals('feature'));
    });
  });
}
