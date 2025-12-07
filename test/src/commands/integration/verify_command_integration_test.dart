import 'dart:io';
import 'package:dfspec/dfspec.dart';
import 'package:test/test.dart';

void main() {
  group('VerifyCommand Integration', () {
    late VerifyCommand command;

    setUp(() {
      command = VerifyCommand();
    });

    group('command configuration', () {
      test('tiene el nombre correcto', () {
        expect(command.name, equals('verify'));
      });

      test('tiene descripcion', () {
        expect(command.description, isNotEmpty);
        expect(command.description.toLowerCase(), contains('verifica'));
      });

      test('soporta flag --all', () {
        expect(command.argParser.options.containsKey('all'), isTrue);
        final option = command.argParser.options['all']!;
        expect(option.abbr, equals('a'));
      });

      test('soporta option --gate con valores permitidos', () {
        expect(command.argParser.options.containsKey('gate'), isTrue);
        final option = command.argParser.options['gate']!;
        expect(option.abbr, equals('g'));
        expect(option.allowed, containsAll([
          'tdd',
          'architecture',
          'coverage',
          'complexity',
          'docs',
        ]));
      });

      test('soporta option --threshold', () {
        expect(command.argParser.options.containsKey('threshold'), isTrue);
        final option = command.argParser.options['threshold']!;
        expect(option.abbr, equals('t'));
      });

      test('soporta flag --strict', () {
        expect(command.argParser.options.containsKey('strict'), isTrue);
      });

      test('soporta flag --ci', () {
        expect(command.argParser.options.containsKey('ci'), isTrue);
      });
    });

    group('service integration points', () {
      test('puede acceder a ConstitutionalValidator', () {
        const validator = ConstitutionalValidator();
        expect(validator, isNotNull);
      });

      test('puede acceder a QualityAnalyzer', () {
        final analyzer = QualityAnalyzer(projectRoot: Directory.current.path);
        expect(analyzer, isNotNull);
      });

      test('QualityAnalyzer puede analizar complejidad', () async {
        final analyzer = QualityAnalyzer(projectRoot: Directory.current.path);
        // Verificar que el metodo existe y es invocable
        expect(analyzer.analyzeComplexity, isA<Function>());
      });

      test('QualityAnalyzer puede analizar documentacion', () async {
        final analyzer = QualityAnalyzer(projectRoot: Directory.current.path);
        // Verificar que el metodo existe y es invocable
        expect(analyzer.analyzeDocumentation, isA<Function>());
      });

      test('ConstitutionalValidator puede validar codigo', () {
        const validator = ConstitutionalValidator();
        const sampleCode = '''
class Example {
  void method() {
    print('hello');
  }
}
''';
        final report = validator.validate(
          content: sampleCode,
          filePath: 'example.dart',
        );
        expect(report, isA<ConstitutionalReport>());
        expect(report.results, isA<List<GateResult>>());
      });
    });
  });

  group('QualityCommand Integration', () {
    late QualityCommand command;

    setUp(() {
      command = QualityCommand();
    });

    test('tiene subcomandos', () {
      expect(command.subcommands, isNotEmpty);
    });

    test('tiene subcomando analyze', () {
      expect(command.subcommands.containsKey('analyze'), isTrue);
    });

    test('tiene subcomando complexity', () {
      expect(command.subcommands.containsKey('complexity'), isTrue);
    });

    test('tiene subcomando docs', () {
      expect(command.subcommands.containsKey('docs'), isTrue);
    });
  });

  group('ReportCommand Integration', () {
    late ReportCommand command;

    setUp(() {
      command = ReportCommand();
    });

    test('tiene el nombre correcto', () {
      expect(command.name, equals('report'));
    });

    test('soporta option --feature', () {
      expect(command.argParser.options.containsKey('feature'), isTrue);
    });

    test('soporta flag --project', () {
      expect(command.argParser.options.containsKey('project'), isTrue);
    });

    test('soporta option --format', () {
      expect(command.argParser.options.containsKey('format'), isTrue);
      final option = command.argParser.options['format']!;
      expect(option.allowed, containsAll(['json', 'markdown']));
    });

    test('soporta flag --save', () {
      expect(command.argParser.options.containsKey('save'), isTrue);
    });

    test('puede acceder a ReportGenerator', () {
      final generator = ReportGenerator(projectRoot: Directory.current.path);
      expect(generator, isNotNull);
    });
  });

  group('DocsCommand Integration', () {
    late DocsCommand command;

    setUp(() {
      command = DocsCommand();
    });

    test('tiene subcomandos', () {
      expect(command.subcommands, isNotEmpty);
    });

    test('tiene subcomando verify', () {
      expect(command.subcommands.containsKey('verify'), isTrue);
    });

    test('tiene subcomando generate', () {
      expect(command.subcommands.containsKey('generate'), isTrue);
    });

    test('puede acceder a DocumentationGenerator', () {
      final generator = DocumentationGenerator(
        projectRoot: Directory.current.path,
      );
      expect(generator, isNotNull);
    });
  });

  group('CacheCommand Integration', () {
    late CacheCommand command;

    setUp(() {
      command = CacheCommand();
    });

    test('tiene subcomandos', () {
      expect(command.subcommands, isNotEmpty);
    });

    test('tiene subcomando stats', () {
      expect(command.subcommands.containsKey('stats'), isTrue);
    });

    test('tiene subcomando clear', () {
      expect(command.subcommands.containsKey('clear'), isTrue);
    });

    test('puede acceder a AnalysisCache', () {
      final cache = AnalysisCache();
      expect(cache, isNotNull);
    });

    test('AnalysisCache tiene propiedades de estadisticas', () {
      final cache = AnalysisCache();
      expect(cache.hits, greaterThanOrEqualTo(0));
      expect(cache.misses, greaterThanOrEqualTo(0));
      expect(cache.size, greaterThanOrEqualTo(0));
      expect(cache.hitRate, greaterThanOrEqualTo(0.0));
    });
  });

  group('RecoveryCommand Integration', () {
    late RecoveryCommand command;

    setUp(() {
      command = RecoveryCommand();
    });

    test('tiene subcomandos', () {
      expect(command.subcommands, isNotEmpty);
    });

    test('tiene subcomando create', () {
      expect(command.subcommands.containsKey('create'), isTrue);
    });

    test('tiene subcomando list', () {
      expect(command.subcommands.containsKey('list'), isTrue);
    });

    test('tiene subcomando restore', () {
      expect(command.subcommands.containsKey('restore'), isTrue);
    });

    test('tiene subcomando report', () {
      expect(command.subcommands.containsKey('report'), isTrue);
    });

    test('tiene subcomando prune', () {
      expect(command.subcommands.containsKey('prune'), isTrue);
    });

    test('puede acceder a RecoveryManager', () {
      final manager = RecoveryManager(projectRoot: Directory.current.path);
      expect(manager, isNotNull);
    });

    test('RecoveryManager puede crear chain', () {
      final manager = RecoveryManager(projectRoot: Directory.current.path);
      final chain = manager.getChain('test-feature');
      expect(chain, isNotNull);
      expect(chain.points, isA<List<RecoveryPoint>>());
    });
  });
}
