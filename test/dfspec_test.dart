import 'package:dfspec/dfspec.dart';
import 'package:test/test.dart';

void main() {
  group('DfspecCommandRunner', () {
    late DfspecCommandRunner runner;

    setUp(() {
      runner = DfspecCommandRunner();
    });

    test('tiene el nombre correcto', () {
      expect(runner.executableName, equals('dfspec'));
    });

    test('tiene la descripcion correcta', () {
      expect(
        runner.description,
        contains('Spec-Driven Development para Flutter/Dart'),
      );
    });

    test('soporta flag --version', () {
      expect(runner.argParser.options.containsKey('version'), isTrue);
    });

    test('tiene todos los comandos registrados', () {
      final commandNames = runner.commands.keys.toList();
      expect(commandNames, contains('agents'));
      expect(commandNames, contains('generate'));
      expect(commandNames, contains('init'));
      expect(commandNames, contains('install'));
    });
  });
}
