import 'dart:io';

import 'package:dfspec/src/models/quality_metrics.dart';
import 'package:dfspec/src/services/quality_analyzer.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late QualityAnalyzer analyzer;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('quality_test_');
    analyzer = QualityAnalyzer(projectRoot: tempDir.path);

    // Crear estructura básica
    await Directory('${tempDir.path}/lib/src').create(recursive: true);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('QualityAnalyzer', () {
    group('analyze', () {
      test('debe retornar reporte vacio si no hay archivos', () async {
        final report = await analyzer.analyze();

        expect(report.metrics, isEmpty);
      });

      test('debe analizar archivos Dart', () async {
        // Crear archivo de prueba
        await File('${tempDir.path}/lib/src/test.dart').writeAsString('''
/// Test class.
class TestClass {
  /// Field.
  final int value;

  /// Constructor.
  const TestClass(this.value);

  /// Method.
  int calculate() {
    return value * 2;
  }
}
''');

        final report = await analyzer.analyze();

        expect(report.metrics, isNotEmpty);
        expect(report.projectName, isNull);
      });

      test('debe excluir archivos generados', () async {
        // Crear archivos normal y generado
        await File('${tempDir.path}/lib/src/model.dart').writeAsString('''
class Model {}
''');
        await File('${tempDir.path}/lib/src/model.g.dart').writeAsString('''
// GENERATED CODE
class ModelGenerated {}
''');
        await File('${tempDir.path}/lib/src/model.freezed.dart').writeAsString('''
// GENERATED CODE
class ModelFreezed {}
''');

        final report = await analyzer.analyze();

        // Verificar que las métricas no incluyen archivos generados
        expect(report.metrics, isNotEmpty);
        for (final metric in report.metrics) {
          for (final detail in metric.details) {
            expect(detail, isNot(contains('.g.dart')));
            expect(detail, isNot(contains('.freezed.dart')));
          }
        }
      });

      test('debe analizar paths especificos', () async {
        await Directory('${tempDir.path}/lib/src/domain').create();
        await Directory('${tempDir.path}/lib/src/data').create();

        await File('${tempDir.path}/lib/src/domain/entity.dart').writeAsString('''
class Entity {}
''');
        await File('${tempDir.path}/lib/src/data/model.dart').writeAsString('''
class Model {}
''');

        final report = await analyzer.analyze(
          paths: ['lib/src/domain'],
        );

        // Solo debería analizar archivos en domain
        expect(report.metrics, isNotEmpty);
      });
    });

    group('analyzeComplexity', () {
      test('debe retornar metricas de complejidad', () async {
        await File('${tempDir.path}/lib/src/complex.dart').writeAsString('''
class Complex {
  int process(int x) {
    if (x > 0) {
      if (x > 10) {
        return x * 2;
      } else {
        return x + 1;
      }
    } else {
      return 0;
    }
  }
}
''');

        final report = await analyzer.analyzeComplexity();

        expect(report.context, equals('complexity'));
        expect(
          report.metrics.any(
            (m) => m.id == 'cyclomatic-complexity' || m.id == 'lines-per-file',
          ),
          isTrue,
        );
      });
    });

    group('analyzeDocumentation', () {
      test('debe retornar metrica de documentacion', () async {
        await File('${tempDir.path}/lib/src/documented.dart').writeAsString('''
/// Documented class.
class Documented {
  /// Documented field.
  final int value;

  /// Documented constructor.
  const Documented(this.value);
}
''');

        final report = await analyzer.analyzeDocumentation();

        expect(report.context, equals('documentation'));
        expect(
          report.metrics.any((m) => m.id == 'documentation'),
          isTrue,
        );
      });

      test('debe detectar elementos sin documentar', () async {
        await File('${tempDir.path}/lib/src/undocumented.dart').writeAsString('''
class Undocumented {
  final int value;
  const Undocumented(this.value);
  int calculate() => value * 2;
}
''');

        final report = await analyzer.analyzeDocumentation();
        final docMetric = report.metrics.firstWhere(
          (m) => m.id == 'documentation',
        );

        expect(docMetric.details, isNotEmpty);
      });
    });

    group('lines metric', () {
      test('debe detectar archivos grandes', () async {
        // Crear archivo con muchas líneas
        final lines = List.generate(500, (i) => '// Line $i').join('\n');
        await File('${tempDir.path}/lib/src/large.dart').writeAsString('''
class Large {
$lines
}
''');

        final report = await analyzer.analyze();
        final linesMetric = report.metrics.firstWhere(
          (m) => m.id == 'lines-per-file',
        );

        expect(linesMetric.details, isNotEmpty);
        expect(linesMetric.details.first, contains('large.dart'));
      });
    });

    group('complexity metric', () {
      test('debe detectar metodos complejos', () async {
        await File('${tempDir.path}/lib/src/complex_method.dart').writeAsString('''
class ComplexMethod {
  int veryComplex(int a, int b, int c) {
    if (a > 0) {
      if (b > 0) {
        if (c > 0) {
          while (a > 0) {
            for (var i = 0; i < b; i++) {
              if (i % 2 == 0) {
                a--;
              } else if (i % 3 == 0) {
                b--;
              } else {
                c--;
              }
            }
          }
          return a + b + c;
        }
      }
    }
    return 0;
  }
}
''');

        final report = await analyzer.analyzeComplexity();
        final complexityMetric = report.metrics.firstWhere(
          (m) => m.id == 'cyclomatic-complexity',
        );

        // Archivo complejo debería tener complejidad >= 5
        expect(complexityMetric.value, greaterThanOrEqualTo(5));
      });
    });

    group('project name extraction', () {
      test('debe extraer nombre del pubspec', () async {
        await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: my_test_project
version: 1.0.0
''');

        await File('${tempDir.path}/lib/src/test.dart').writeAsString('''
class Test {}
''');

        final report = await analyzer.analyze();

        expect(report.projectName, equals('my_test_project'));
      });
    });
  });

  group('Metrics integration', () {
    test('reporte debe tener todas las categorias necesarias', () async {
      await File('${tempDir.path}/lib/src/sample.dart').writeAsString('''
/// Sample class.
class Sample {
  /// Value.
  final int value;

  /// Constructor.
  const Sample(this.value);

  /// Calculate method.
  int calculate(int x) {
    if (x > 0) {
      return value * x;
    }
    return value;
  }
}
''');

      final report = await analyzer.analyze();

      expect(report.metrics, isNotEmpty);

      // Verificar que hay métricas
      final categories = report.metrics.map((m) => m.category).toSet();
      expect(categories, isNotEmpty);
    });

    test('overallScore debe reflejar calidad del codigo', () async {
      // Código bien documentado y simple
      await File('${tempDir.path}/lib/src/good.dart').writeAsString('''
/// Good class.
class Good {
  /// Value field.
  final int value;

  /// Creates a Good instance.
  const Good(this.value);

  /// Returns doubled value.
  int double() => value * 2;
}
''');

      final report = await analyzer.analyze();

      // Código simple y documentado debería tener buen score
      expect(report.overallScore, greaterThan(50));
    });
  });
}
