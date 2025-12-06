import 'package:dfspec/src/models/constitutional_gate.dart';
import 'package:test/test.dart';

void main() {
  group('GateSeverity', () {
    test('debe tener labels correctos', () {
      expect(GateSeverity.critical.label, equals('Rechazado'));
      expect(GateSeverity.warning.label, equals('Advertencia'));
      expect(GateSeverity.info.label, equals('Sugerencia'));
    });
  });

  group('GateResult', () {
    test('debe crear resultado exitoso con factory', () {
      final result = GateResult.passed('test-gate', message: 'OK');

      expect(result.gateId, equals('test-gate'));
      expect(result.status, equals(GateStatus.passed));
      expect(result.message, equals('OK'));
      expect(result.isPassed, isTrue);
      expect(result.isFailed, isFalse);
    });

    test('debe crear resultado fallido con factory', () {
      final result = GateResult.failed(
        'test-gate',
        message: 'Violacion detectada',
        details: ['Linea 10: import invalido'],
        location: 'lib/src/domain/test.dart',
      );

      expect(result.gateId, equals('test-gate'));
      expect(result.status, equals(GateStatus.failed));
      expect(result.message, equals('Violacion detectada'));
      expect(result.details, contains('Linea 10: import invalido'));
      expect(result.location, equals('lib/src/domain/test.dart'));
      expect(result.isPassed, isFalse);
      expect(result.isFailed, isTrue);
    });

    test('debe crear resultado warning con factory', () {
      final result = GateResult.warning(
        'test-gate',
        message: 'Posible violacion',
        details: ['Revisar manualmente'],
      );

      expect(result.status, equals(GateStatus.warning));
      expect(result.isPassed, isFalse);
      expect(result.isFailed, isFalse);
    });

    test('toString debe incluir icono segun status', () {
      final passed = GateResult.passed('test');
      final failed = GateResult.failed('test', message: 'error');
      final warning = GateResult.warning('test', message: 'warn');
      const notApplicable = GateResult(
        gateId: 'test',
        status: GateStatus.notApplicable,
      );

      expect(passed.toString(), contains('✓'));
      expect(failed.toString(), contains('✗'));
      expect(warning.toString(), contains('⚠'));
      expect(notApplicable.toString(), contains('○'));
    });
  });

  group('ConstitutionalGate', () {
    test('debe crear gate con todos los campos', () {
      const gate = ConstitutionalGate(
        id: 'clean-architecture',
        articleNumber: 'I',
        name: 'Clean Architecture',
        description: 'Separacion de capas',
        severity: GateSeverity.critical,
        rules: ['Domain no importa data'],
        checkPatterns: [r'abstract class'],
        violationPatterns: [r"import.*'/data/'"],
      );

      expect(gate.id, equals('clean-architecture'));
      expect(gate.articleNumber, equals('I'));
      expect(gate.name, equals('Clean Architecture'));
      expect(gate.severity, equals(GateSeverity.critical));
      expect(gate.rules, isNotEmpty);
      expect(gate.checkPatterns, isNotEmpty);
      expect(gate.violationPatterns, isNotEmpty);
    });

    test('debe tener valores por defecto vacios', () {
      const gate = ConstitutionalGate(
        id: 'test',
        articleNumber: 'XI',
        name: 'Test Gate',
        description: 'Test',
        severity: GateSeverity.info,
      );

      expect(gate.rules, isEmpty);
      expect(gate.checkPatterns, isEmpty);
      expect(gate.violationPatterns, isEmpty);
    });

    test('toJson debe serializar correctamente', () {
      const gate = ConstitutionalGate(
        id: 'test-gate',
        articleNumber: 'II',
        name: 'Test',
        description: 'Description',
        severity: GateSeverity.warning,
        rules: ['Rule 1'],
      );

      final json = gate.toJson();

      expect(json['id'], equals('test-gate'));
      expect(json['articleNumber'], equals('II'));
      expect(json['name'], equals('Test'));
      expect(json['severity'], equals('warning'));
      expect(json['rules'], contains('Rule 1'));
    });

    test('toString debe incluir articulo y nombre', () {
      const gate = ConstitutionalGate(
        id: 'test',
        articleNumber: 'III',
        name: 'Test Gate',
        description: 'Test',
        severity: GateSeverity.critical,
      );

      expect(gate.toString(), equals('Gate(III: Test Gate)'));
    });
  });

  group('ConstitutionalReport', () {
    test('debe crear reporte con resultados', () {
      final results = [
        GateResult.passed('gate-1'),
        GateResult.failed('gate-2', message: 'Error'),
        GateResult.warning('gate-3', message: 'Warning'),
      ];

      final report = ConstitutionalReport(
        results: results,
        timestamp: DateTime(2024, 1, 15),
        context: 'test.dart',
      );

      expect(report.results.length, equals(3));
      expect(report.passed.length, equals(1));
      expect(report.failed.length, equals(1));
      expect(report.warnings.length, equals(1));
      expect(report.context, equals('test.dart'));
    });

    test('allPassed debe ser true solo si no hay fallos', () {
      final withFailure = ConstitutionalReport(
        results: [
          GateResult.passed('gate-1'),
          GateResult.failed('gate-2', message: 'Error'),
        ],
        timestamp: DateTime.now(),
      );

      final withoutFailure = ConstitutionalReport(
        results: [
          GateResult.passed('gate-1'),
          GateResult.warning('gate-2', message: 'Warn'),
        ],
        timestamp: DateTime.now(),
      );

      expect(withFailure.allPassed, isFalse);
      expect(withoutFailure.allPassed, isTrue);
    });

    test('passRate debe calcular porcentaje correctamente', () {
      final report = ConstitutionalReport(
        results: [
          GateResult.passed('gate-1'),
          GateResult.passed('gate-2'),
          GateResult.failed('gate-3', message: 'Error'),
          const GateResult(gateId: 'gate-4', status: GateStatus.notApplicable),
        ],
        timestamp: DateTime.now(),
      );

      // 2 passed / 3 applicable = 0.666...
      expect(report.passRate, closeTo(0.666, 0.01));
    });

    test('passRate debe ser 1.0 para reporte vacio', () {
      final report = ConstitutionalReport.empty();

      expect(report.passRate, equals(1.0));
    });

    test('toSummary debe generar markdown valido', () {
      final report = ConstitutionalReport(
        results: [
          GateResult.passed('gate-1', message: 'OK'),
          GateResult.failed(
            'gate-2',
            message: 'Error',
            details: ['Detalle 1'],
          ),
        ],
        timestamp: DateTime(2024, 1, 15),
        context: 'feature-test',
      );

      final summary = report.toSummary();

      expect(summary, contains('## Reporte Constitucional'));
      expect(summary, contains('**Contexto:** feature-test'));
      expect(summary, contains('✓ Pasados'));
      expect(summary, contains('✗ Fallidos'));
      expect(summary, contains('### Violaciones'));
      expect(summary, contains('Detalle 1'));
    });
  });

  group('ConstitutionalGates', () {
    test('debe tener 11 gates predefinidos', () {
      expect(ConstitutionalGates.all.length, equals(11));
    });

    test('gates criticos deben ser 6', () {
      final critical = ConstitutionalGates.critical;

      expect(critical.length, equals(6));
      expect(
        critical.every((g) => g.severity == GateSeverity.critical),
        isTrue,
      );
    });

    test('gates deben tener articulos I-XI', () {
      final articles =
          ConstitutionalGates.all.map((g) => g.articleNumber).toList();

      expect(articles, containsAll(['I', 'II', 'III', 'IV', 'V', 'VI']));
      expect(articles, containsAll(['VII', 'VIII', 'IX', 'X', 'XI']));
    });

    test('byId debe encontrar gate por identificador', () {
      final gate = ConstitutionalGates.byId('clean-architecture');

      expect(gate, isNotNull);
      expect(gate!.name, equals('Clean Architecture'));
      expect(gate.articleNumber, equals('I'));
    });

    test('byId debe retornar null para id inexistente', () {
      final gate = ConstitutionalGates.byId('nonexistent');

      expect(gate, isNull);
    });

    test('byArticle debe encontrar gate por numero', () {
      final gate = ConstitutionalGates.byArticle('II');

      expect(gate, isNotNull);
      expect(gate!.id, equals('tdd'));
    });

    test('byArticle debe retornar null para articulo inexistente', () {
      final gate = ConstitutionalGates.byArticle('XII');

      expect(gate, isNull);
    });

    group('gates especificos', () {
      test('cleanArchitecture debe tener patrones de violacion', () {
        final gate = ConstitutionalGates.cleanArchitecture;

        expect(gate.id, equals('clean-architecture'));
        expect(gate.violationPatterns, isNotEmpty);
        expect(gate.severity, equals(GateSeverity.critical));
      });

      test('tdd debe tener reglas de correspondencia', () {
        final gate = ConstitutionalGates.tdd;

        expect(gate.id, equals('tdd'));
        expect(gate.rules, contains('Ciclo RED-GREEN-REFACTOR'));
      });

      test('immutableEntities debe detectar setters', () {
        final gate = ConstitutionalGates.immutableEntities;

        expect(gate.id, equals('immutable-entities'));
        expect(
          gate.violationPatterns.any((p) => p.contains('set')),
          isTrue,
        );
      });

      test('errorHandling debe detectar Exception generica', () {
        final gate = ConstitutionalGates.errorHandling;

        expect(
          gate.violationPatterns.any((p) => p.contains('Exception')),
          isTrue,
        );
      });
    });
  });
}
