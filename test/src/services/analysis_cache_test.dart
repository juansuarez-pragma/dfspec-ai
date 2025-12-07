import 'dart:io';

import 'package:dfspec/src/services/analysis_cache.dart';
import 'package:test/test.dart';

void main() {
  group('CacheEntry', () {
    test('debe crear entrada basica', () {
      final entry = CacheEntry<String>(
        key: 'test-key',
        value: 'test-value',
        hash: 'abc123',
        timestamp: DateTime.now(),
      );

      expect(entry.key, equals('test-key'));
      expect(entry.value, equals('test-value'));
      expect(entry.hash, equals('abc123'));
      expect(entry.isExpired, isFalse);
    });

    test('isExpired debe verificar TTL', () {
      final expiredEntry = CacheEntry<String>(
        key: 'expired',
        value: 'value',
        hash: 'hash',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ttl: const Duration(hours: 1),
      );

      final validEntry = CacheEntry<String>(
        key: 'valid',
        value: 'value',
        hash: 'hash',
        timestamp: DateTime.now(),
        ttl: const Duration(hours: 1),
      );

      expect(expiredEntry.isExpired, isTrue);
      expect(validEntry.isExpired, isFalse);
    });

    test('entrada sin TTL nunca expira', () {
      final entry = CacheEntry<String>(
        key: 'no-ttl',
        value: 'value',
        hash: 'hash',
        timestamp: DateTime.now().subtract(const Duration(days: 365)),
      );

      expect(entry.isExpired, isFalse);
    });

    test('debe serializar y deserializar', () {
      final original = CacheEntry<Map<String, dynamic>>(
        key: 'test',
        value: const {'data': 'value'},
        hash: 'hash123',
        timestamp: DateTime(2024, 6, 15, 10, 30),
        ttl: const Duration(hours: 2),
      );

      final json = original.toJson((v) => v);
      final restored = CacheEntry<Map<String, dynamic>>.fromJson(
        json,
        (v) => v as Map<String, dynamic>,
      );

      expect(restored.key, equals(original.key));
      expect(restored.value, equals(original.value));
      expect(restored.hash, equals(original.hash));
      expect(restored.ttl?.inHours, equals(2));
    });
  });

  group('AnalysisCache', () {
    late AnalysisCache cache;

    setUp(() {
      cache = AnalysisCache(maxEntries: 10);
    });

    test('debe almacenar y recuperar valores', () {
      cache.set('key1', 'value1', 'hash1');

      final result = cache.get<String>('key1', 'hash1');

      expect(result, equals('value1'));
    });

    test('debe retornar null para key inexistente', () {
      final result = cache.get<String>('nonexistent', 'hash');

      expect(result, isNull);
    });

    test('debe invalidar si hash cambia', () {
      cache.set('key', 'value', 'hash1');

      final result = cache.get<String>('key', 'hash2');

      expect(result, isNull);
    });

    test('debe rastrear hits y misses', () {
      cache.set('key', 'value', 'hash');

      cache.get<String>('key', 'hash'); // hit
      cache.get<String>('key', 'hash'); // hit
      cache.get<String>('nonexistent', 'hash'); // miss

      expect(cache.hits, equals(2));
      expect(cache.misses, equals(1));
      expect(cache.hitRate, closeTo(0.67, 0.01));
    });

    test('debe evictar entradas mas antiguas cuando excede limite', () {
      final smallCache = AnalysisCache(maxEntries: 3);

      smallCache.set('key1', 'value1', 'hash1');
      smallCache.set('key2', 'value2', 'hash2');
      smallCache.set('key3', 'value3', 'hash3');
      smallCache.set('key4', 'value4', 'hash4');

      expect(smallCache.size, equals(3));
      // key1 debería haber sido evictada
      expect(smallCache.get<String>('key1', 'hash1'), isNull);
    });

    test('invalidate debe eliminar entrada especifica', () {
      cache.set('key1', 'value1', 'hash1');
      cache.set('key2', 'value2', 'hash2');

      cache.invalidate('key1');

      expect(cache.get<String>('key1', 'hash1'), isNull);
      expect(cache.get<String>('key2', 'hash2'), equals('value2'));
    });

    test('invalidatePattern debe eliminar entradas coincidentes', () {
      cache.set('feature-city', 'value1', 'hash1');
      cache.set('feature-user', 'value2', 'hash2');
      cache.set('other-key', 'value3', 'hash3');

      cache.invalidatePattern('^feature-');

      expect(cache.get<String>('feature-city', 'hash1'), isNull);
      expect(cache.get<String>('feature-user', 'hash2'), isNull);
      expect(cache.get<String>('other-key', 'hash3'), equals('value3'));
    });

    test('clear debe limpiar todo', () {
      cache.set('key1', 'value1', 'hash1');
      cache.set('key2', 'value2', 'hash2');

      cache.clear();

      expect(cache.size, equals(0));
      expect(cache.hits, equals(0));
      expect(cache.misses, equals(0));
    });

    test('cleanExpired debe eliminar entradas expiradas', () async {
      final shortTtlCache = AnalysisCache(
        maxEntries: 10,
        defaultTtl: const Duration(milliseconds: 50),
      );

      shortTtlCache.set('short', 'value', 'hash');
      shortTtlCache.set('long', 'value', 'hash',
          ttl: const Duration(hours: 1));

      // Esperar a que expire
      await Future<void>.delayed(const Duration(milliseconds: 100));

      shortTtlCache.cleanExpired();

      expect(shortTtlCache.get<String>('short', 'hash'), isNull);
      expect(shortTtlCache.get<String>('long', 'hash'), equals('value'));
    });

    test('getStats debe retornar estadisticas', () {
      cache.set('key', 'value', 'hash');
      cache.get<String>('key', 'hash');

      final stats = cache.getStats();

      expect(stats, contains('Entries: 1'));
      expect(stats, contains('Hits: 1'));
    });
  });

  group('PersistentCache', () {
    late Directory tempDir;
    late PersistentCache cache;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cache_test_');
      cache = PersistentCache(cacheDir: tempDir.path);
      await cache.initialize();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('debe almacenar y recuperar valores', () async {
      await cache.set(
        'test-key',
        {'data': 'value'},
        'hash123',
        (v) => v,
      );

      final result = await cache.get<Map<String, dynamic>>(
        'test-key',
        'hash123',
        (json) => json,
      );

      expect(result, isNotNull);
      expect(result!['data'], equals('value'));
    });

    test('debe persistir en disco', () async {
      await cache.set('persistent', {'test': true}, 'hash', (v) => v);

      // Crear nueva instancia del cache
      final newCache = PersistentCache(cacheDir: tempDir.path);
      await newCache.initialize();

      final result = await newCache.get<Map<String, dynamic>>(
        'persistent',
        'hash',
        (json) => json,
      );

      expect(result, isNotNull);
      expect(result!['test'], equals(true));
    });

    test('debe invalidar por hash incorrecto', () async {
      await cache.set('key', {'v': 1}, 'hash1', (v) => v);

      final result = await cache.get<Map<String, dynamic>>(
        'key',
        'hash2', // Hash diferente
        (json) => json,
      );

      expect(result, isNull);
    });

    test('invalidate debe eliminar del disco', () async {
      await cache.set('to-delete', {'x': 1}, 'hash', (v) => v);
      await cache.invalidate('to-delete');

      final result = await cache.get<Map<String, dynamic>>(
        'to-delete',
        'hash',
        (json) => json,
      );

      expect(result, isNull);

      // Verificar que el archivo fue eliminado
      final files = await tempDir.list().toList();
      expect(files.where((f) => f.path.contains('to-delete')), isEmpty);
    });

    test('clear debe limpiar todo el cache', () async {
      await cache.set('key1', {'a': 1}, 'h1', (v) => v);
      await cache.set('key2', {'b': 2}, 'h2', (v) => v);

      await cache.clear();

      final files = await tempDir.list().where((f) => f.path.endsWith('.json')).toList();
      expect(files, isEmpty);
    });

    test('computeContentHash debe generar hash consistente', () {
      final hash1 = cache.computeContentHash('test content');
      final hash2 = cache.computeContentHash('test content');
      final hash3 = cache.computeContentHash('different content');

      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(hash3)));
    });

    test('computeFileHash debe calcular hash de archivo', () async {
      final testFile = File('${tempDir.path}/test.txt');
      await testFile.writeAsString('test content');

      final hash = await cache.computeFileHash(testFile.path);

      expect(hash, isNotEmpty);
      expect(hash.length, equals(64)); // SHA-256 = 64 hex chars
    });

    test('getStats debe retornar estadisticas', () async {
      await cache.set('key1', {'a': 1}, 'h1', (v) => v);
      await cache.set('key2', {'b': 2}, 'h2', (v) => v);

      final stats = await cache.getStats();

      expect(stats.diskEntries, equals(2));
      expect(stats.diskSizeBytes, greaterThan(0));
    });
  });

  group('BatchProcessor', () {
    late BatchProcessor processor;

    setUp(() {
      processor = BatchProcessor(batchSize: 3, parallelism: 2);
    });

    test('debe procesar items en batch', () async {
      final items = [1, 2, 3, 4, 5, 6, 7];

      final results = await processor.process<int, int>(
        items,
        (item) async => item * 2,
      );

      expect(results, equals([2, 4, 6, 8, 10, 12, 14]));
    });

    test('debe manejar lista vacia', () async {
      final results = await processor.process<int, int>(
        [],
        (item) async => item * 2,
      );

      expect(results, isEmpty);
    });

    test('processStream debe generar stream de resultados', () async {
      final items = [1, 2, 3];

      final results = await processor
          .processStream<int, int>(items, (item) async => item * 10)
          .toList();

      expect(results, equals([10, 20, 30]));
    });

    test('debe respetar tamaño de batch', () async {
      var batchCount = 0;
      final items = List.generate(10, (i) => i);

      await processor.process<int, int>(
        items,
        (item) async {
          if (item % 3 == 0) batchCount++;
          return item;
        },
      );

      // Con batch size 3 y 10 items, deberían ser 4 batches
      expect(batchCount, equals(4));
    });
  });

  group('CacheStats', () {
    test('debe calcular diskSizeMB correctamente', () {
      const stats = CacheStats(
        memoryEntries: 10,
        memoryHits: 100,
        memoryMisses: 20,
        memoryHitRate: 0.83,
        diskEntries: 50,
        diskSizeBytes: 10 * 1024 * 1024, // 10 MB
      );

      expect(stats.diskSizeMB, equals(10.0));
    });

    test('toString debe formatear correctamente', () {
      const stats = CacheStats(
        memoryEntries: 5,
        memoryHits: 50,
        memoryMisses: 10,
        memoryHitRate: 0.833,
        diskEntries: 20,
        diskSizeBytes: 1024 * 1024,
      );

      final str = stats.toString();

      expect(str, contains('Entries: 5'));
      expect(str, contains('Hits: 50'));
      expect(str, contains('83.3%'));
      expect(str, contains('1.00 MB'));
    });
  });
}
