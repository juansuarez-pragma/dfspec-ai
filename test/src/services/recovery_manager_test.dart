import 'dart:io';

import 'package:dfspec/src/models/recovery_point.dart';
import 'package:dfspec/src/services/recovery_manager.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late RecoveryManager manager;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('recovery_test_');
    manager = RecoveryManager(projectRoot: tempDir.path);
    await manager.initialize();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('RecoveryManager', () {
    group('initialize', () {
      test('debe crear directorio de recovery si no existe', () async {
        final recoveryDir = Directory('${tempDir.path}/.dfspec/recovery');
        expect(await recoveryDir.exists(), isTrue);
      });

      test('debe cargar cadenas existentes', () async {
        // Crear una cadena y guardarla
        await manager.createManualCheckpoint(
          feature: 'test-feature',
          component: 'test-component',
          filePaths: [],
        );

        // Crear nuevo manager y cargar
        final newManager = RecoveryManager(projectRoot: tempDir.path);
        await newManager.initialize();

        expect(newManager.features, contains('test-feature'));
      });
    });

    group('getChain', () {
      test('debe retornar cadena vacia para feature nueva', () {
        final chain = manager.getChain('new-feature');

        expect(chain.feature, equals('new-feature'));
        expect(chain.points, isEmpty);
      });

      test('debe retornar cadena existente', () async {
        await manager.createManualCheckpoint(
          feature: 'existing-feature',
          component: 'component',
          filePaths: [],
        );

        final chain = manager.getChain('existing-feature');

        expect(chain.points.length, equals(1));
      });
    });

    group('createGreenCheckpoint', () {
      test('debe crear checkpoint con estado estable', () async {
        final point = await manager.createGreenCheckpoint(
          feature: 'city-search',
          component: 'SearchCities usecase',
          filePaths: [],
          testResults: const [
            RecoveryTestResult(
              testPath: 'test/search_cities_test.dart',
              passed: 5,
              total: 5,
            ),
          ],
        );

        expect(point.type, equals(RecoveryType.greenTest));
        expect(point.status, equals(RecoveryStatus.stable));
        expect(point.isGreen, isTrue);
      });

      test('debe crear checkpoint failing si tests fallan', () async {
        final point = await manager.createGreenCheckpoint(
          feature: 'city-search',
          component: 'SearchCities usecase',
          filePaths: [],
          testResults: const [
            RecoveryTestResult(
              testPath: 'test/search_cities_test.dart',
              passed: 3,
              total: 5,
              failures: ['test1 failed', 'test2 failed'],
            ),
          ],
        );

        expect(point.status, equals(RecoveryStatus.failing));
      });
    });

    group('createPreRefactorCheckpoint', () {
      test('debe crear checkpoint pre-refactor', () async {
        final point = await manager.createPreRefactorCheckpoint(
          feature: 'city-search',
          component: 'SearchCities',
          filePaths: [],
          testResults: const [
            RecoveryTestResult(
              testPath: 'test.dart',
              passed: 5,
              total: 5,
            ),
          ],
        );

        expect(point.type, equals(RecoveryType.preRefactor));
        expect(point.description, contains('Pre-refactor'));
      });
    });

    group('createComponentCheckpoint', () {
      test('debe crear checkpoint de componente', () async {
        final point = await manager.createComponentCheckpoint(
          feature: 'city-search',
          component: 'CityEntity',
          filePaths: [],
          testResults: const [
            RecoveryTestResult(
              testPath: 'test.dart',
              passed: 10,
              total: 10,
            ),
          ],
        );

        expect(point.type, equals(RecoveryType.componentComplete));
        expect(point.description, contains('Component complete'));
      });
    });

    group('createMilestoneCheckpoint', () {
      test('debe crear checkpoint milestone', () async {
        final point = await manager.createMilestoneCheckpoint(
          feature: 'city-search',
          component: 'Domain Layer',
          filePaths: [],
          testResults: const [
            RecoveryTestResult(
              testPath: 'test.dart',
              passed: 50,
              total: 50,
            ),
          ],
          description: 'Domain layer completed',
        );

        expect(point.type, equals(RecoveryType.milestone));
        expect(point.description, equals('Domain layer completed'));
      });
    });

    group('createManualCheckpoint', () {
      test('debe crear checkpoint manual', () async {
        final point = await manager.createManualCheckpoint(
          feature: 'city-search',
          component: 'debugging',
          filePaths: [],
          description: 'Before big change',
        );

        expect(point.type, equals(RecoveryType.manual));
        expect(point.description, equals('Before big change'));
      });
    });

    group('file state capture', () {
      test('debe capturar estado de archivos existentes', () async {
        // Crear archivo de prueba
        final testFile = File('${tempDir.path}/lib/test.dart');
        await testFile.parent.create(recursive: true);
        await testFile.writeAsString('void main() {}');

        final point = await manager.createManualCheckpoint(
          feature: 'test',
          component: 'test',
          filePaths: ['lib/test.dart'],
        );

        expect(point.files.length, equals(1));
        expect(point.files.first.exists, isTrue);
        expect(point.files.first.hash, isNotEmpty);
      });

      test('debe capturar archivo inexistente', () async {
        final point = await manager.createManualCheckpoint(
          feature: 'test',
          component: 'test',
          filePaths: ['lib/nonexistent.dart'],
        );

        expect(point.files.length, equals(1));
        expect(point.files.first.exists, isFalse);
      });
    });

    group('recovery chain management', () {
      test('debe mantener cadena de puntos', () async {
        await manager.createGreenCheckpoint(
          feature: 'test',
          component: 'c1',
          filePaths: [],
          testResults: const [],
        );

        await manager.createGreenCheckpoint(
          feature: 'test',
          component: 'c2',
          filePaths: [],
          testResults: const [],
        );

        await manager.createGreenCheckpoint(
          feature: 'test',
          component: 'c3',
          filePaths: [],
          testResults: const [],
        );

        final chain = manager.getChain('test');

        expect(chain.points.length, equals(3));
        expect(chain.points[0].component, equals('c1'));
        expect(chain.points[2].component, equals('c3'));
      });

      test('debe establecer parentId correctamente', () async {
        final point1 = await manager.createGreenCheckpoint(
          feature: 'test',
          component: 'c1',
          filePaths: [],
          testResults: const [],
        );

        final point2 = await manager.createGreenCheckpoint(
          feature: 'test',
          component: 'c2',
          filePaths: [],
          testResults: const [],
        );

        expect(point2.parentId, equals(point1.id));
      });
    });

    group('recoverToLastStable', () {
      test('debe fallar si no hay puntos estables', () async {
        final result = await manager.recoverToLastStable('nonexistent');

        expect(result.success, isFalse);
        expect(result.message, contains('No hay puntos estables'));
      });
    });

    group('recoverToPoint', () {
      test('debe fallar para punto inexistente', () async {
        await manager.createManualCheckpoint(
          feature: 'test',
          component: 'c1',
          filePaths: [],
        );

        final result = await manager.recoverToPoint('test', 'nonexistent');

        expect(result.success, isFalse);
        expect(result.message, contains('no encontrado'));
      });
    });

    group('generateReport', () {
      test('debe generar reporte vacio si no hay cadenas', () {
        final report = manager.generateReport();

        expect(report, contains('Recovery Status Report'));
        expect(report, contains('No recovery chains found'));
      });

      test('debe incluir todas las cadenas en reporte', () async {
        await manager.createManualCheckpoint(
          feature: 'feature-1',
          component: 'c1',
          filePaths: [],
        );

        await manager.createManualCheckpoint(
          feature: 'feature-2',
          component: 'c2',
          filePaths: [],
        );

        final report = manager.generateReport();

        expect(report, contains('feature-1'));
        expect(report, contains('feature-2'));
      });
    });

    group('features', () {
      test('debe listar todas las features', () async {
        await manager.createManualCheckpoint(
          feature: 'f1',
          component: 'c',
          filePaths: [],
        );
        await manager.createManualCheckpoint(
          feature: 'f2',
          component: 'c',
          filePaths: [],
        );
        await manager.createManualCheckpoint(
          feature: 'f3',
          component: 'c',
          filePaths: [],
        );

        expect(manager.features, containsAll(['f1', 'f2', 'f3']));
      });
    });
  });

  group('RecoveryResult', () {
    test('success debe crear resultado exitoso', () {
      final result = RecoveryResult.success(
        'Recovered successfully',
        restoredFiles: ['file1.dart', 'file2.dart'],
      );

      expect(result.success, isTrue);
      expect(result.restoredFiles.length, equals(2));
      expect(result.errors, isEmpty);
    });

    test('partial debe crear resultado parcial', () {
      final result = RecoveryResult.partial(
        'Partial recovery',
        restoredFiles: ['file1.dart'],
        errors: ['file2.dart failed'],
      );

      expect(result.success, isFalse);
      expect(result.restoredFiles.length, equals(1));
      expect(result.errors.length, equals(1));
    });

    test('failed debe crear resultado fallido', () {
      final result = RecoveryResult.failed('Recovery failed');

      expect(result.success, isFalse);
      expect(result.restoredFiles, isEmpty);
      expect(result.errors, isEmpty);
    });

    test('toString debe mostrar icono segun estado', () {
      final success = RecoveryResult.success('OK', restoredFiles: []);
      final failed = RecoveryResult.failed('Error');

      expect(success.toString(), contains('✓'));
      expect(failed.toString(), contains('✗'));
    });
  });
}
