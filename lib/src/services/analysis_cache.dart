/// Sistema de cache para análisis de código en DFSpec.
///
/// Este módulo proporciona cache de resultados de análisis
/// para mejorar el rendimiento en operaciones repetidas.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

/// Entrada de cache.
@immutable
class CacheEntry<T> {
  /// Crea una entrada de cache.
  const CacheEntry({
    required this.key,
    required this.value,
    required this.hash,
    required this.timestamp,
    this.ttl,
  });

  /// Clave de la entrada.
  final String key;

  /// Valor cacheado.
  final T value;

  /// Hash del contenido original.
  final String hash;

  /// Timestamp de creación.
  final DateTime timestamp;

  /// Time-to-live (opcional).
  final Duration? ttl;

  /// Si la entrada ha expirado.
  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().difference(timestamp) > ttl!;
  }

  /// Crea desde JSON.
  factory CacheEntry.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) valueFromJson,
  ) {
    return CacheEntry<T>(
      key: json['key'] as String,
      value: valueFromJson(json['value']),
      hash: json['hash'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      ttl: json['ttl_ms'] != null
          ? Duration(milliseconds: json['ttl_ms'] as int)
          : null,
    );
  }

  /// Convierte a JSON.
  Map<String, dynamic> toJson(dynamic Function(T) valueToJson) => {
        'key': key,
        'value': valueToJson(value),
        'hash': hash,
        'timestamp': timestamp.toIso8601String(),
        if (ttl != null) 'ttl_ms': ttl!.inMilliseconds,
      };
}

/// Cache de análisis en memoria.
class AnalysisCache {
  /// Crea un cache de análisis.
  AnalysisCache({
    this.maxEntries = 1000,
    this.defaultTtl = const Duration(hours: 1),
  });

  /// Máximo de entradas en cache.
  final int maxEntries;

  /// TTL por defecto.
  final Duration defaultTtl;

  /// Entradas del cache.
  final Map<String, CacheEntry<dynamic>> _cache = {};

  /// Estadísticas de hits/misses.
  int _hits = 0;
  int _misses = 0;

  /// Número de hits.
  int get hits => _hits;

  /// Número de misses.
  int get misses => _misses;

  /// Tasa de acierto.
  double get hitRate => (_hits + _misses) > 0 ? _hits / (_hits + _misses) : 0.0;

  /// Número de entradas actuales.
  int get size => _cache.length;

  /// Obtiene un valor del cache.
  T? get<T>(String key, String currentHash) {
    final entry = _cache[key];

    if (entry == null) {
      _misses++;
      return null;
    }

    if (entry.isExpired || entry.hash != currentHash) {
      _cache.remove(key);
      _misses++;
      return null;
    }

    _hits++;
    return entry.value as T;
  }

  /// Guarda un valor en el cache.
  void set<T>(String key, T value, String hash, {Duration? ttl}) {
    // Limpiar si excede el límite
    if (_cache.length >= maxEntries) {
      _evictOldest();
    }

    _cache[key] = CacheEntry<T>(
      key: key,
      value: value,
      hash: hash,
      timestamp: DateTime.now(),
      ttl: ttl ?? defaultTtl,
    );
  }

  /// Invalida una entrada específica.
  void invalidate(String key) {
    _cache.remove(key);
  }

  /// Invalida entradas que coinciden con un patrón.
  void invalidatePattern(String pattern) {
    final regex = RegExp(pattern);
    _cache.removeWhere((key, _) => regex.hasMatch(key));
  }

  /// Limpia todo el cache.
  void clear() {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  /// Limpia entradas expiradas.
  void cleanExpired() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }

  /// Evicta la entrada más antigua.
  void _evictOldest() {
    if (_cache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _cache.entries) {
      if (oldestTime == null || entry.value.timestamp.isBefore(oldestTime)) {
        oldestTime = entry.value.timestamp;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _cache.remove(oldestKey);
    }
  }

  /// Genera resumen de estadísticas.
  String getStats() {
    return '''
Cache Statistics:
  Entries: $size / $maxEntries
  Hits: $hits
  Misses: $misses
  Hit Rate: ${(hitRate * 100).toStringAsFixed(1)}%
''';
  }
}

/// Cache persistente en disco.
class PersistentCache {
  /// Crea un cache persistente.
  PersistentCache({
    required this.cacheDir,
    this.maxSizeMB = 100,
  });

  /// Directorio del cache.
  final String cacheDir;

  /// Tamaño máximo en MB.
  final int maxSizeMB;

  /// Cache en memoria como buffer.
  final AnalysisCache _memoryCache = AnalysisCache(maxEntries: 100);

  /// Inicializa el cache.
  Future<void> initialize() async {
    final dir = Directory(cacheDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// Calcula el hash de un archivo.
  Future<String> computeFileHash(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return '';
    }
    final content = await file.readAsBytes();
    return sha256.convert(content).toString();
  }

  /// Calcula el hash de un contenido.
  String computeContentHash(String content) {
    return sha256.convert(utf8.encode(content)).toString();
  }

  /// Obtiene un valor del cache.
  Future<T?> get<T>(
    String key,
    String currentHash,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    // Primero buscar en memoria
    final memoryValue = _memoryCache.get<T>(key, currentHash);
    if (memoryValue != null) {
      return memoryValue;
    }

    // Buscar en disco
    final cacheFile = File('$cacheDir/${_sanitizeKey(key)}.json');
    if (!await cacheFile.exists()) {
      return null;
    }

    try {
      final content = await cacheFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      final entry = CacheEntry<Map<String, dynamic>>.fromJson(json, (v) => v as Map<String, dynamic>);

      if (entry.isExpired || entry.hash != currentHash) {
        await cacheFile.delete();
        return null;
      }

      final value = fromJson(entry.value);

      // Guardar en memoria para acceso rápido
      _memoryCache.set(key, value, currentHash);

      return value;
    } catch (_) {
      return null;
    }
  }

  /// Guarda un valor en el cache.
  Future<void> set<T>(
    String key,
    T value,
    String hash,
    Map<String, dynamic> Function(T) toJson, {
    Duration? ttl,
  }) async {
    // Guardar en memoria
    _memoryCache.set(key, value, hash, ttl: ttl);

    // Guardar en disco
    final entry = CacheEntry<Map<String, dynamic>>(
      key: key,
      value: toJson(value),
      hash: hash,
      timestamp: DateTime.now(),
      ttl: ttl ?? const Duration(days: 7),
    );

    final cacheFile = File('$cacheDir/${_sanitizeKey(key)}.json');
    await cacheFile.writeAsString(jsonEncode(entry.toJson((v) => v)));

    // Verificar tamaño del cache
    await _checkCacheSize();
  }

  /// Invalida una entrada.
  Future<void> invalidate(String key) async {
    _memoryCache.invalidate(key);

    final cacheFile = File('$cacheDir/${_sanitizeKey(key)}.json');
    if (await cacheFile.exists()) {
      await cacheFile.delete();
    }
  }

  /// Limpia todo el cache.
  Future<void> clear() async {
    _memoryCache.clear();

    final dir = Directory(cacheDir);
    if (await dir.exists()) {
      await for (final file in dir.list()) {
        if (file is File && file.path.endsWith('.json')) {
          await file.delete();
        }
      }
    }
  }

  /// Limpia entradas expiradas.
  Future<void> cleanExpired() async {
    _memoryCache.cleanExpired();

    final dir = Directory(cacheDir);
    if (!await dir.exists()) return;

    await for (final file in dir.list()) {
      if (file is File && file.path.endsWith('.json')) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final timestamp = DateTime.parse(json['timestamp'] as String);
          final ttlMs = json['ttl_ms'] as int?;

          if (ttlMs != null) {
            final ttl = Duration(milliseconds: ttlMs);
            if (DateTime.now().difference(timestamp) > ttl) {
              await file.delete();
            }
          }
        } catch (_) {
          // Eliminar archivos corruptos
          await file.delete();
        }
      }
    }
  }

  String _sanitizeKey(String key) {
    return key
        .replaceAll(RegExp(r'[^\w\-.]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  Future<void> _checkCacheSize() async {
    final dir = Directory(cacheDir);
    if (!await dir.exists()) return;

    var totalSize = 0;
    final files = <File, int>{};

    await for (final file in dir.list()) {
      if (file is File && file.path.endsWith('.json')) {
        final size = await file.length();
        totalSize += size;
        files[file] = size;
      }
    }

    final maxBytes = maxSizeMB * 1024 * 1024;
    if (totalSize > maxBytes) {
      // Ordenar por fecha de modificación y eliminar los más antiguos
      final sortedFiles = files.keys.toList()
        ..sort((a, b) {
          final aTime = a.lastModifiedSync();
          final bTime = b.lastModifiedSync();
          return aTime.compareTo(bTime);
        });

      for (final file in sortedFiles) {
        if (totalSize <= maxBytes * 0.8) break; // Reducir al 80%
        totalSize -= files[file]!;
        await file.delete();
      }
    }
  }

  /// Obtiene estadísticas del cache.
  Future<CacheStats> getStats() async {
    final dir = Directory(cacheDir);
    var fileCount = 0;
    var totalSize = 0;

    if (await dir.exists()) {
      await for (final file in dir.list()) {
        if (file is File && file.path.endsWith('.json')) {
          fileCount++;
          totalSize += await file.length();
        }
      }
    }

    return CacheStats(
      memoryEntries: _memoryCache.size,
      memoryHits: _memoryCache.hits,
      memoryMisses: _memoryCache.misses,
      memoryHitRate: _memoryCache.hitRate,
      diskEntries: fileCount,
      diskSizeBytes: totalSize,
    );
  }
}

/// Estadísticas de cache.
@immutable
class CacheStats {
  /// Crea estadísticas de cache.
  const CacheStats({
    required this.memoryEntries,
    required this.memoryHits,
    required this.memoryMisses,
    required this.memoryHitRate,
    required this.diskEntries,
    required this.diskSizeBytes,
  });

  /// Entradas en memoria.
  final int memoryEntries;

  /// Hits en memoria.
  final int memoryHits;

  /// Misses en memoria.
  final int memoryMisses;

  /// Tasa de acierto en memoria.
  final double memoryHitRate;

  /// Entradas en disco.
  final int diskEntries;

  /// Tamaño en disco (bytes).
  final int diskSizeBytes;

  /// Tamaño en MB.
  double get diskSizeMB => diskSizeBytes / (1024 * 1024);

  @override
  String toString() => '''
Cache Statistics:
  Memory:
    Entries: $memoryEntries
    Hits: $memoryHits
    Misses: $memoryMisses
    Hit Rate: ${(memoryHitRate * 100).toStringAsFixed(1)}%
  Disk:
    Entries: $diskEntries
    Size: ${diskSizeMB.toStringAsFixed(2)} MB
''';
}

/// Mixin para agregar cache a servicios de análisis.
mixin CacheableMixin {
  /// Cache en memoria.
  AnalysisCache get cache;

  /// Ejecuta con cache.
  Future<T> cached<T>(
    String key,
    String hash,
    Future<T> Function() compute,
  ) async {
    final cached = cache.get<T>(key, hash);
    if (cached != null) {
      return cached;
    }

    final result = await compute();
    cache.set(key, result, hash);
    return result;
  }
}

/// Procesador de análisis en batch.
class BatchProcessor {
  /// Crea un procesador batch.
  BatchProcessor({
    this.batchSize = 10,
    this.parallelism = 4,
  });

  /// Tamaño del batch.
  final int batchSize;

  /// Nivel de paralelismo.
  final int parallelism;

  /// Procesa items en batch.
  Future<List<R>> process<T, R>(
    List<T> items,
    Future<R> Function(T) processor,
  ) async {
    final results = <R>[];

    for (var i = 0; i < items.length; i += batchSize) {
      final batch = items.skip(i).take(batchSize).toList();

      // Procesar batch en paralelo
      final batchResults = await Future.wait(
        batch.map(processor),
      );

      results.addAll(batchResults);
    }

    return results;
  }

  /// Procesa items en stream.
  Stream<R> processStream<T, R>(
    List<T> items,
    Future<R> Function(T) processor,
  ) async* {
    for (final item in items) {
      yield await processor(item);
    }
  }
}
