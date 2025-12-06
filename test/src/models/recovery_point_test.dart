import 'package:dfspec/src/models/recovery_point.dart';
import 'package:test/test.dart';

void main() {
  group('RecoveryStatus', () {
    test('debe tener labels correctos', () {
      expect(RecoveryStatus.pending.label, equals('Pendiente'));
      expect(RecoveryStatus.stable.label, equals('Estable'));
      expect(RecoveryStatus.failing.label, equals('Fallando'));
      expect(RecoveryStatus.recovered.label, equals('Recuperado'));
      expect(RecoveryStatus.invalidated.label, equals('Invalidado'));
    });
  });

  group('RecoveryType', () {
    test('debe tener labels correctos', () {
      expect(RecoveryType.greenTest.label, equals('Test Verde'));
      expect(RecoveryType.manual.label, equals('Manual'));
      expect(RecoveryType.preRefactor.label, equals('Pre-Refactor'));
      expect(RecoveryType.componentComplete.label, equals('Componente Completo'));
      expect(RecoveryType.milestone.label, equals('Milestone'));
    });

    test('debe tener prioridades de retencion correctas', () {
      expect(RecoveryType.greenTest.retentionPriority, equals(1));
      expect(RecoveryType.preRefactor.retentionPriority, equals(2));
      expect(RecoveryType.manual.retentionPriority, equals(3));
      expect(RecoveryType.componentComplete.retentionPriority, equals(4));
      expect(RecoveryType.milestone.retentionPriority, equals(5));
    });

    test('milestone debe tener prioridad mas alta', () {
      for (final type in RecoveryType.values) {
        if (type != RecoveryType.milestone) {
          expect(
            RecoveryType.milestone.retentionPriority,
            greaterThan(type.retentionPriority),
          );
        }
      }
    });
  });

  group('RecoveryFileState', () {
    test('debe crear estado de archivo existente', () {
      const state = RecoveryFileState(
        path: 'lib/src/test.dart',
        hash: 'abc123',
        exists: true,
        content: 'void main() {}',
      );

      expect(state.path, equals('lib/src/test.dart'));
      expect(state.hash, equals('abc123'));
      expect(state.exists, isTrue);
      expect(state.content, equals('void main() {}'));
    });

    test('debe crear estado de archivo eliminado', () {
      const state = RecoveryFileState(
        path: 'lib/src/deleted.dart',
        hash: '',
        exists: false,
      );

      expect(state.exists, isFalse);
      expect(state.content, isNull);
    });

    test('debe serializar a JSON correctamente', () {
      const state = RecoveryFileState(
        path: 'lib/src/test.dart',
        hash: 'abc123',
        exists: true,
        content: 'code',
      );

      final json = state.toJson();

      expect(json['path'], equals('lib/src/test.dart'));
      expect(json['hash'], equals('abc123'));
      expect(json['exists'], isTrue);
      expect(json['content'], equals('code'));
    });

    test('debe deserializar desde JSON', () {
      final json = {
        'path': 'lib/src/test.dart',
        'hash': 'abc123',
        'exists': true,
        'content': 'code',
      };

      final state = RecoveryFileState.fromJson(json);

      expect(state.path, equals('lib/src/test.dart'));
      expect(state.hash, equals('abc123'));
      expect(state.exists, isTrue);
      expect(state.content, equals('code'));
    });

    test('toString debe mostrar informacion resumida', () {
      const existing = RecoveryFileState(
        path: 'lib/test.dart',
        hash: 'abcdefgh12345678',
        exists: true,
      );
      const deleted = RecoveryFileState(
        path: 'lib/deleted.dart',
        hash: '',
        exists: false,
      );

      expect(existing.toString(), contains('abcdefgh'));
      expect(deleted.toString(), contains('deleted'));
    });
  });

  group('RecoveryTestResult', () {
    test('debe crear resultado exitoso', () {
      const result = RecoveryTestResult(
        testPath: 'test/unit/test.dart',
        passed: 10,
        total: 10,
        duration: Duration(seconds: 5),
      );

      expect(result.allPassed, isTrue);
      expect(result.successRate, equals(1.0));
      expect(result.failures, isEmpty);
    });

    test('debe crear resultado con fallos', () {
      const result = RecoveryTestResult(
        testPath: 'test/unit/test.dart',
        passed: 7,
        total: 10,
        failures: ['test1 failed', 'test2 failed', 'test3 failed'],
      );

      expect(result.allPassed, isFalse);
      expect(result.successRate, equals(0.7));
      expect(result.failures.length, equals(3));
    });

    test('successRate debe ser 1.0 para total 0', () {
      const result = RecoveryTestResult(
        testPath: 'test/empty_test.dart',
        passed: 0,
        total: 0,
      );

      expect(result.successRate, equals(1.0));
    });

    test('debe serializar a JSON', () {
      const result = RecoveryTestResult(
        testPath: 'test/unit/test.dart',
        passed: 8,
        total: 10,
        failures: ['fail1'],
        duration: Duration(milliseconds: 500),
      );

      final json = result.toJson();

      expect(json['testPath'], equals('test/unit/test.dart'));
      expect(json['passed'], equals(8));
      expect(json['total'], equals(10));
      expect(json['failures'], contains('fail1'));
      expect(json['durationMs'], equals(500));
    });

    test('debe deserializar desde JSON', () {
      final json = {
        'testPath': 'test/unit/test.dart',
        'passed': 5,
        'total': 5,
        'durationMs': 1000,
      };

      final result = RecoveryTestResult.fromJson(json);

      expect(result.testPath, equals('test/unit/test.dart'));
      expect(result.allPassed, isTrue);
      expect(result.duration, equals(const Duration(seconds: 1)));
    });

    test('toString debe mostrar icono segun resultado', () {
      const passed = RecoveryTestResult(
        testPath: 'test.dart',
        passed: 5,
        total: 5,
      );
      const failed = RecoveryTestResult(
        testPath: 'test.dart',
        passed: 3,
        total: 5,
      );

      expect(passed.toString(), contains('✓'));
      expect(failed.toString(), contains('✗'));
    });
  });

  group('RecoveryPoint', () {
    test('debe crear punto con factory stable', () {
      final point = RecoveryPoint.stable(
        id: 'test-id',
        feature: 'city-search',
        component: 'SearchCities usecase',
        type: RecoveryType.greenTest,
        files: const [
          RecoveryFileState(
            path: 'lib/src/domain/usecases/search_cities.dart',
            hash: 'abc123',
            exists: true,
          ),
        ],
        testResults: const [
          RecoveryTestResult(
            testPath: 'test/unit/domain/usecases/search_cities_test.dart',
            passed: 5,
            total: 5,
          ),
        ],
      );

      expect(point.status, equals(RecoveryStatus.stable));
      expect(point.isGreen, isTrue);
      expect(point.feature, equals('city-search'));
    });

    test('debe crear punto con factory failing', () {
      final point = RecoveryPoint.failing(
        id: 'test-id',
        feature: 'city-search',
        component: 'SearchCities usecase',
        files: const [],
        testResults: const [
          RecoveryTestResult(
            testPath: 'test.dart',
            passed: 3,
            total: 5,
          ),
        ],
      );

      expect(point.status, equals(RecoveryStatus.failing));
      expect(point.isGreen, isFalse);
    });

    test('isGreen debe ser false si no hay test results', () {
      final point = RecoveryPoint(
        id: 'test-id',
        feature: 'test',
        component: 'test',
        type: RecoveryType.manual,
        status: RecoveryStatus.stable,
        timestamp: DateTime.now(),
        files: const [],
        testResults: const [],
      );

      // Sin test results, isGreen es false aunque status sea stable
      expect(point.isGreen, isFalse);
    });

    test('totalTests y passingTests deben sumar correctamente', () {
      final point = RecoveryPoint(
        id: 'test-id',
        feature: 'test',
        component: 'test',
        type: RecoveryType.milestone,
        status: RecoveryStatus.stable,
        timestamp: DateTime.now(),
        files: const [],
        testResults: const [
          RecoveryTestResult(testPath: 'test1.dart', passed: 5, total: 5),
          RecoveryTestResult(testPath: 'test2.dart', passed: 3, total: 5),
          RecoveryTestResult(testPath: 'test3.dart', passed: 10, total: 10),
        ],
      );

      expect(point.totalTests, equals(20));
      expect(point.passingTests, equals(18));
    });

    test('copyWith debe crear copia con cambios', () {
      final original = RecoveryPoint.stable(
        id: 'test-id',
        feature: 'test',
        component: 'test',
        type: RecoveryType.greenTest,
        files: const [],
        testResults: const [],
      );

      final copy = original.copyWith(
        status: RecoveryStatus.invalidated,
        description: 'Nueva descripcion',
      );

      expect(copy.id, equals(original.id));
      expect(copy.status, equals(RecoveryStatus.invalidated));
      expect(copy.description, equals('Nueva descripcion'));
    });

    test('debe serializar y deserializar correctamente', () {
      final original = RecoveryPoint.stable(
        id: 'test-id',
        feature: 'city-search',
        component: 'SearchCities',
        type: RecoveryType.componentComplete,
        files: const [
          RecoveryFileState(path: 'lib/test.dart', hash: 'abc', exists: true),
        ],
        testResults: const [
          RecoveryTestResult(testPath: 'test/test.dart', passed: 5, total: 5),
        ],
        description: 'Test checkpoint',
      );

      final json = original.toJson();
      final restored = RecoveryPoint.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.feature, equals(original.feature));
      expect(restored.component, equals(original.component));
      expect(restored.type, equals(original.type));
      expect(restored.status, equals(original.status));
      expect(restored.files.length, equals(1));
      expect(restored.testResults.length, equals(1));
      expect(restored.description, equals(original.description));
    });

    test('toString debe mostrar icono segun status', () {
      final stable = RecoveryPoint.stable(
        id: 'id1',
        feature: 'f',
        component: 'c',
        type: RecoveryType.greenTest,
        files: const [],
        testResults: const [],
      );

      final failing = RecoveryPoint.failing(
        id: 'id2',
        feature: 'f',
        component: 'c',
        files: const [],
        testResults: const [],
      );

      expect(stable.toString(), contains('✓'));
      expect(failing.toString(), contains('✗'));
    });
  });

  group('RecoveryChain', () {
    test('debe crear cadena vacia', () {
      final chain = RecoveryChain.empty('city-search');

      expect(chain.feature, equals('city-search'));
      expect(chain.points, isEmpty);
      expect(chain.currentPoint, isNull);
      expect(chain.lastStablePoint, isNull);
      expect(chain.isGreen, isTrue);
    });

    test('debe agregar puntos correctamente', () {
      var chain = RecoveryChain.empty('test-feature');

      final point1 = RecoveryPoint.stable(
        id: 'point-1',
        feature: 'test-feature',
        component: 'entity',
        type: RecoveryType.greenTest,
        files: const [],
        testResults: const [
          RecoveryTestResult(testPath: 'test.dart', passed: 1, total: 1),
        ],
      );

      chain = chain.addPoint(point1);

      expect(chain.points.length, equals(1));
      expect(chain.currentPointId, equals('point-1'));
      expect(chain.currentPoint, equals(point1));
    });

    test('lastStablePoint debe retornar ultimo punto estable', () {
      final stablePoint = RecoveryPoint.stable(
        id: 'stable-1',
        feature: 'test',
        component: 'c1',
        type: RecoveryType.greenTest,
        files: const [],
        testResults: const [
          RecoveryTestResult(testPath: 't.dart', passed: 1, total: 1),
        ],
      );

      final failingPoint = RecoveryPoint.failing(
        id: 'failing-1',
        feature: 'test',
        component: 'c2',
        files: const [],
        testResults: const [
          RecoveryTestResult(testPath: 't.dart', passed: 0, total: 1),
        ],
      );

      var chain = RecoveryChain.empty('test');
      chain = chain.addPoint(stablePoint);
      chain = chain.addPoint(failingPoint);

      expect(chain.lastStablePoint, equals(stablePoint));
      expect(chain.lastPoint, equals(failingPoint));
    });

    test('invalidateAfter debe marcar puntos posteriores', () {
      final point1 = RecoveryPoint.stable(
        id: 'p1',
        feature: 'test',
        component: 'c1',
        type: RecoveryType.greenTest,
        files: const [],
        testResults: const [],
      );

      final point2 = RecoveryPoint.stable(
        id: 'p2',
        feature: 'test',
        component: 'c2',
        type: RecoveryType.greenTest,
        files: const [],
        testResults: const [],
      );

      final point3 = RecoveryPoint.stable(
        id: 'p3',
        feature: 'test',
        component: 'c3',
        type: RecoveryType.greenTest,
        files: const [],
        testResults: const [],
      );

      var chain = RecoveryChain.empty('test');
      chain = chain.addPoint(point1);
      chain = chain.addPoint(point2);
      chain = chain.addPoint(point3);

      chain = chain.invalidateAfter('p1');

      expect(chain.points[0].status, equals(RecoveryStatus.stable));
      expect(chain.points[1].status, equals(RecoveryStatus.invalidated));
      expect(chain.points[2].status, equals(RecoveryStatus.invalidated));
      expect(chain.currentPointId, equals('p1'));
    });

    test('stablePoints debe filtrar solo puntos estables', () {
      final stable1 = RecoveryPoint.stable(
        id: 's1',
        feature: 'test',
        component: 'c1',
        type: RecoveryType.greenTest,
        files: const [],
        testResults: const [],
      );

      final failing = RecoveryPoint.failing(
        id: 'f1',
        feature: 'test',
        component: 'c2',
        files: const [],
        testResults: const [],
      );

      final stable2 = RecoveryPoint.stable(
        id: 's2',
        feature: 'test',
        component: 'c3',
        type: RecoveryType.greenTest,
        files: const [],
        testResults: const [],
      );

      var chain = RecoveryChain.empty('test');
      chain = chain.addPoint(stable1);
      chain = chain.addPoint(failing);
      chain = chain.addPoint(stable2);

      expect(chain.stablePoints.length, equals(2));
      expect(chain.stablePoints.map((p) => p.id), containsAll(['s1', 's2']));
    });

    test('debe serializar y deserializar', () {
      final point = RecoveryPoint.stable(
        id: 'p1',
        feature: 'test',
        component: 'c1',
        type: RecoveryType.milestone,
        files: const [],
        testResults: const [],
      );

      var original = RecoveryChain.empty('test');
      original = original.addPoint(point);

      final json = original.toJson();
      final restored = RecoveryChain.fromJson(json);

      expect(restored.feature, equals(original.feature));
      expect(restored.points.length, equals(1));
      expect(restored.currentPointId, equals(original.currentPointId));
    });

    test('toSummary debe generar markdown valido', () {
      final point1 = RecoveryPoint.stable(
        id: 'p1',
        feature: 'test',
        component: 'Entity',
        type: RecoveryType.greenTest,
        files: const [],
        testResults: const [
          RecoveryTestResult(testPath: 't.dart', passed: 5, total: 5),
        ],
      );

      final point2 = RecoveryPoint.stable(
        id: 'p2',
        feature: 'test',
        component: 'UseCase',
        type: RecoveryType.componentComplete,
        files: const [],
        testResults: const [
          RecoveryTestResult(testPath: 't.dart', passed: 10, total: 10),
        ],
      );

      var chain = RecoveryChain.empty('test');
      chain = chain.addPoint(point1);
      chain = chain.addPoint(point2);

      final summary = chain.toSummary();

      expect(summary, contains('## Recovery Chain: test'));
      expect(summary, contains('Entity'));
      expect(summary, contains('UseCase'));
      expect(summary, contains('Test Verde'));
      expect(summary, contains('Componente Completo'));
      expect(summary, contains('Puntos estables'));
    });

    test('toSummary para cadena vacia debe indicarlo', () {
      final chain = RecoveryChain.empty('empty-feature');
      final summary = chain.toSummary();

      expect(summary, contains('Sin puntos de recuperación'));
    });
  });
}
