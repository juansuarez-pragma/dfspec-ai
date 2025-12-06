import 'dart:io';

import 'package:dfspec/dfspec.dart';
import 'package:test/test.dart';

void main() {
  group('SpecGenerator', () {
    late Directory tempDir;
    late SpecGenerator generator;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('dfspec_test_');
      generator = SpecGenerator(baseDir: tempDir.path);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('genera especificacion feature correctamente', () async {
      final result = await generator.generate(
        type: SpecType.feature,
        name: 'Mi Feature',
      );

      expect(result.isSuccess, isTrue);
      expect(result.filePath, isNotNull);
      expect(result.type, equals(SpecType.feature));

      final file = File(result.filePath!);
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      expect(content, contains('Mi Feature'));
      expect(content, contains('Requisitos Funcionales'));
    });

    test('genera ADR correctamente', () async {
      final result = await generator.generate(
        type: SpecType.architecture,
        name: 'Usar Riverpod',
        variables: {'status': 'accepted'},
      );

      expect(result.isSuccess, isTrue);

      final file = File(result.filePath!);
      final content = file.readAsStringSync();
      expect(content, contains('Usar Riverpod'));
      expect(content, contains('accepted'));
    });

    test('no sobrescribe sin force', () async {
      // Primera generacion
      await generator.generate(
        type: SpecType.feature,
        name: 'Test',
      );

      // Segunda generacion sin force
      final result = await generator.generate(
        type: SpecType.feature,
        name: 'Test',
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, contains('ya existe'));
    });

    test('sobrescribe con force', () async {
      // Primera generacion
      await generator.generate(
        type: SpecType.feature,
        name: 'Test',
      );

      // Segunda generacion con force
      final result = await generator.generate(
        type: SpecType.feature,
        name: 'Test',
        overwrite: true,
      );

      expect(result.isSuccess, isTrue);
      expect(result.overwritten, isTrue);
    });

    test('genera en directorio personalizado', () async {
      final result = await generator.generate(
        type: SpecType.feature,
        name: 'Custom',
        customDir: 'custom/path',
      );

      expect(result.isSuccess, isTrue);
      expect(result.filePath, contains('custom/path'));
    });

    test('incluye fecha en el contenido', () async {
      final result = await generator.generate(
        type: SpecType.feature,
        name: 'Con Fecha',
      );

      final file = File(result.filePath!);
      final content = file.readAsStringSync();
      final now = DateTime.now();
      expect(content, contains('${now.year}'));
    });

    test('generateMultiple genera varios tipos', () async {
      final results = await generator.generateMultiple(
        types: [SpecType.feature, SpecType.security],
        name: 'Multi Test',
      );

      expect(results.length, equals(2));
      expect(results.every((r) => r.isSuccess), isTrue);
    });

    test('listExisting retorna archivos existentes', () async {
      await generator.generate(type: SpecType.feature, name: 'Uno');
      await generator.generate(type: SpecType.feature, name: 'Dos');

      final existing = generator.listExisting(SpecType.feature);

      expect(existing.length, equals(2));
      expect(existing, contains('uno.feature.md'));
      expect(existing, contains('dos.feature.md'));
    });

    test('genera todos los tipos de especificacion', () async {
      for (final type in SpecType.values) {
        final result = await generator.generate(
          type: type,
          name: 'Test ${type.value}',
        );

        expect(
          result.isSuccess,
          isTrue,
          reason: 'Fallo al generar ${type.value}',
        );
      }
    });
  });

  group('GenerationResult', () {
    test('success tiene valores correctos', () {
      const result = GenerationResult.success(
        filePath: '/path/to/file.md',
        type: SpecType.feature,
      );

      expect(result.isSuccess, isTrue);
      expect(result.filePath, equals('/path/to/file.md'));
      expect(result.error, isNull);
    });

    test('failure tiene valores correctos', () {
      const result = GenerationResult.failure(
        error: 'Algo fallo',
        type: SpecType.feature,
      );

      expect(result.isSuccess, isFalse);
      expect(result.filePath, isNull);
      expect(result.error, equals('Algo fallo'));
    });
  });
}
