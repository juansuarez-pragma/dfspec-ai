import 'package:dfspec/src/commands/trace_command.dart';
import 'package:test/test.dart';

void main() {
  group('TraceCommand', () {
    late TraceCommand command;

    setUp(() {
      command = TraceCommand();
    });

    group('command properties', () {
      test('tiene nombre correcto', () {
        expect(command.name, equals('trace'));
      });

      test('tiene descripción', () {
        expect(command.description, isNotEmpty);
        expect(command.description, contains('trazabilidad'));
      });

      test('tiene invocation personalizado', () {
        expect(command.invocation, contains('dfspec trace'));
        expect(command.invocation, contains('<feature-id>'));
      });
    });

    group('argParser options', () {
      test('tiene flag --all', () {
        expect(command.argParser.options, contains('all'));
        final allOption = command.argParser.options['all']!;
        expect(allOption.abbr, equals('a'));
        expect(allOption.negatable, isFalse);
      });

      test('tiene option --format', () {
        expect(command.argParser.options, contains('format'));
        final formatOption = command.argParser.options['format']!;
        expect(formatOption.abbr, equals('f'));
        expect(formatOption.defaultsTo, equals('summary'));
        expect(formatOption.allowed, containsAll(['summary', 'matrix', 'json', 'markdown']));
      });

      test('tiene option --export', () {
        expect(command.argParser.options, contains('export'));
        final exportOption = command.argParser.options['export']!;
        expect(exportOption.abbr, equals('e'));
      });

      test('tiene flag --orphans-only', () {
        expect(command.argParser.options, contains('orphans-only'));
        final orphansOption = command.argParser.options['orphans-only']!;
        expect(orphansOption.negatable, isFalse);
      });

      test('tiene flag --issues-only', () {
        expect(command.argParser.options, contains('issues-only'));
        final issuesOption = command.argParser.options['issues-only']!;
        expect(issuesOption.negatable, isFalse);
      });

      test('tiene option --severity', () {
        expect(command.argParser.options, contains('severity'));
        final severityOption = command.argParser.options['severity']!;
        expect(severityOption.defaultsTo, equals('all'));
        expect(severityOption.allowed, containsAll(['all', 'critical', 'warning', 'info']));
      });

      test('tiene flag --ci', () {
        expect(command.argParser.options, contains('ci'));
        final ciOption = command.argParser.options['ci']!;
        expect(ciOption.negatable, isFalse);
      });
    });

    group('argument parsing', () {
      test('parsea --all flag correctamente', () {
        final results = command.argParser.parse(['--all']);
        expect(results['all'], isTrue);
      });

      test('parsea -a abbreviation correctamente', () {
        final results = command.argParser.parse(['-a']);
        expect(results['all'], isTrue);
      });

      test('parsea --format option correctamente', () {
        final results = command.argParser.parse(['--format=json']);
        expect(results['format'], equals('json'));
      });

      test('parsea -f abbreviation para format', () {
        final results = command.argParser.parse(['-f', 'matrix']);
        expect(results['format'], equals('matrix'));
      });

      test('parsea --export option correctamente', () {
        final results = command.argParser.parse(['--export=report.html']);
        expect(results['export'], equals('report.html'));
      });

      test('parsea -e abbreviation para export', () {
        final results = command.argParser.parse(['-e', 'output.json']);
        expect(results['export'], equals('output.json'));
      });

      test('parsea --orphans-only flag', () {
        final results = command.argParser.parse(['--orphans-only']);
        expect(results['orphans-only'], isTrue);
      });

      test('parsea --issues-only flag', () {
        final results = command.argParser.parse(['--issues-only']);
        expect(results['issues-only'], isTrue);
      });

      test('parsea --severity option', () {
        final results = command.argParser.parse(['--severity=critical']);
        expect(results['severity'], equals('critical'));
      });

      test('parsea --ci flag', () {
        final results = command.argParser.parse(['--ci']);
        expect(results['ci'], isTrue);
      });

      test('parsea múltiples opciones juntas', () {
        final results = command.argParser.parse([
          '--all',
          '--format=json',
          '--severity=warning',
          '--ci',
        ]);
        expect(results['all'], isTrue);
        expect(results['format'], equals('json'));
        expect(results['severity'], equals('warning'));
        expect(results['ci'], isTrue);
      });

      test('parsea argumentos rest (feature-id)', () {
        final results = command.argParser.parse(['001-auth']);
        expect(results.rest, equals(['001-auth']));
      });

      test('parsea feature-id con opciones', () {
        final results = command.argParser.parse([
          '001-auth',
          '--format=matrix',
          '--ci',
        ]);
        expect(results.rest, equals(['001-auth']));
        expect(results['format'], equals('matrix'));
        expect(results['ci'], isTrue);
      });
    });

    group('defaults', () {
      test('all default es false', () {
        final results = command.argParser.parse([]);
        expect(results['all'], isFalse);
      });

      test('format default es summary', () {
        final results = command.argParser.parse([]);
        expect(results['format'], equals('summary'));
      });

      test('export default es null', () {
        final results = command.argParser.parse([]);
        expect(results['export'], isNull);
      });

      test('orphans-only default es false', () {
        final results = command.argParser.parse([]);
        expect(results['orphans-only'], isFalse);
      });

      test('issues-only default es false', () {
        final results = command.argParser.parse([]);
        expect(results['issues-only'], isFalse);
      });

      test('severity default es all', () {
        final results = command.argParser.parse([]);
        expect(results['severity'], equals('all'));
      });

      test('ci default es false', () {
        final results = command.argParser.parse([]);
        expect(results['ci'], isFalse);
      });
    });

    group('format option validation', () {
      test('acepta summary', () {
        expect(
          () => command.argParser.parse(['--format=summary']),
          returnsNormally,
        );
      });

      test('acepta matrix', () {
        expect(
          () => command.argParser.parse(['--format=matrix']),
          returnsNormally,
        );
      });

      test('acepta json', () {
        expect(
          () => command.argParser.parse(['--format=json']),
          returnsNormally,
        );
      });

      test('acepta markdown', () {
        expect(
          () => command.argParser.parse(['--format=markdown']),
          returnsNormally,
        );
      });

      test('rechaza formato inválido', () {
        expect(
          () => command.argParser.parse(['--format=invalid']),
          throwsFormatException,
        );
      });
    });

    group('severity option validation', () {
      test('acepta all', () {
        expect(
          () => command.argParser.parse(['--severity=all']),
          returnsNormally,
        );
      });

      test('acepta critical', () {
        expect(
          () => command.argParser.parse(['--severity=critical']),
          returnsNormally,
        );
      });

      test('acepta warning', () {
        expect(
          () => command.argParser.parse(['--severity=warning']),
          returnsNormally,
        );
      });

      test('acepta info', () {
        expect(
          () => command.argParser.parse(['--severity=info']),
          returnsNormally,
        );
      });

      test('rechaza severidad inválida', () {
        expect(
          () => command.argParser.parse(['--severity=debug']),
          throwsFormatException,
        );
      });
    });

    group('error handling', () {
      test('lanza excepción para opciones no reconocidas', () {
        expect(
          () => command.argParser.parse(['--unknown']),
          throwsFormatException,
        );
      });

      test('lanza excepción para valor faltante en option', () {
        expect(
          () => command.argParser.parse(['--export']),
          throwsFormatException,
        );
      });

      test('acepta múltiples feature-ids en rest', () {
        final results = command.argParser.parse(['001-auth', '002-user']);
        expect(results.rest.length, equals(2));
        expect(results.rest, containsAll(['001-auth', '002-user']));
      });
    });

    group('combinaciones de flags', () {
      test('--all con --ci', () {
        final results = command.argParser.parse(['--all', '--ci']);
        expect(results['all'], isTrue);
        expect(results['ci'], isTrue);
      });

      test('--orphans-only con --format=json', () {
        final results = command.argParser.parse([
          '--orphans-only',
          '--format=json',
        ]);
        expect(results['orphans-only'], isTrue);
        expect(results['format'], equals('json'));
      });

      test('--issues-only con --severity=critical', () {
        final results = command.argParser.parse([
          '--issues-only',
          '--severity=critical',
        ]);
        expect(results['issues-only'], isTrue);
        expect(results['severity'], equals('critical'));
      });

      test('exportar con formato específico', () {
        final results = command.argParser.parse([
          '--export=report.html',
          '--all',
        ]);
        expect(results['export'], equals('report.html'));
        expect(results['all'], isTrue);
      });

      test('CI mode con severidad filtrada', () {
        final results = command.argParser.parse([
          '001-auth',
          '--ci',
          '--severity=critical',
        ]);
        expect(results.rest, equals(['001-auth']));
        expect(results['ci'], isTrue);
        expect(results['severity'], equals('critical'));
      });
    });

    group('help text', () {
      test('descripción contiene información sobre trazabilidad', () {
        expect(command.description, contains('trazabilidad'));
      });

      test('argParser tiene ayuda para --all', () {
        final help = command.argParser.options['all']!.help;
        expect(help, isNotNull);
        expect(help, contains('todas'));
      });

      test('argParser tiene ayuda para --format', () {
        final help = command.argParser.options['format']!.help;
        expect(help, isNotNull);
        expect(help, contains('salida'));
      });

      test('argParser tiene ayuda para --export', () {
        final help = command.argParser.options['export']!.help;
        expect(help, isNotNull);
        expect(help, contains('Exportar'));
      });

      test('argParser tiene ayuda para --ci', () {
        final help = command.argParser.options['ci']!.help;
        expect(help, isNotNull);
        expect(help, contains('CI'));
      });
    });
  });

  group('Export file extensions', () {
    test('reconoce extensión .json', () {
      const path = 'report.json';
      final extension = path.split('.').last.toLowerCase();
      expect(extension, equals('json'));
    });

    test('reconoce extensión .html', () {
      const path = 'report.html';
      final extension = path.split('.').last.toLowerCase();
      expect(extension, equals('html'));
    });

    test('reconoce extensión .md', () {
      const path = 'report.md';
      final extension = path.split('.').last.toLowerCase();
      expect(extension, equals('md'));
    });

    test('maneja paths con múltiples puntos', () {
      const path = 'my.report.file.json';
      final extension = path.split('.').last.toLowerCase();
      expect(extension, equals('json'));
    });

    test('maneja extensión uppercase', () {
      const path = 'REPORT.JSON';
      final extension = path.split('.').last.toLowerCase();
      expect(extension, equals('json'));
    });
  });
}
