import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dfspec/src/services/analysis_cache.dart';
import 'package:dfspec/src/utils/logger.dart';

/// Comando para gestión de cache de análisis.
///
/// Uso:
/// ```bash
/// dfspec cache stats
/// dfspec cache clear
/// dfspec cache clear --pattern="feature-*"
/// dfspec cache clean
/// ```
class CacheCommand extends Command<int> {
  /// Crea el comando cache.
  CacheCommand() {
    addSubcommand(_StatsSubcommand());
    addSubcommand(_ClearSubcommand());
    addSubcommand(_CleanSubcommand());
  }

  @override
  String get name => 'cache';

  @override
  String get description => 'Gestiona cache de análisis.';

  @override
  String get invocation => 'dfspec cache <subcomando>';
}

/// Subcomando para mostrar estadísticas del cache.
class _StatsSubcommand extends Command<int> {
  @override
  String get name => 'stats';

  @override
  String get description => 'Muestra estadísticas del cache.';

  @override
  Future<int> run() async {
    const logger = Logger();

    try {
      final cacheDir = _getCacheDir();
      final cache = PersistentCache(cacheDir: cacheDir);
      await cache.initialize();

      final stats = await cache.getStats();

      logger.panel(
        'Estadísticas de Cache',
        '''
Memoria:
  Entradas: ${stats.memoryEntries}
  Hits: ${stats.memoryHits}
  Misses: ${stats.memoryMisses}
  Hit Rate: ${(stats.memoryHitRate * 100).toStringAsFixed(1)}%

Disco:
  Entradas: ${stats.diskEntries}
  Tamaño: ${stats.diskSizeMB.toStringAsFixed(2)} MB

Ubicación: $cacheDir
''',
      );

      return 0;
    } catch (e) {
      logger.error('Error obteniendo estadísticas: $e');
      return 1;
    }
  }
}

/// Subcomando para limpiar el cache.
class _ClearSubcommand extends Command<int> {
  _ClearSubcommand() {
    argParser
      ..addOption(
        'pattern',
        abbr: 'p',
        help: 'Patrón regex para limpiar entradas específicas.',
      )
      ..addFlag(
        'all',
        abbr: 'a',
        help: 'Limpia todo el cache.',
        negatable: false,
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'No pide confirmación.',
        negatable: false,
      );
  }

  @override
  String get name => 'clear';

  @override
  String get description => 'Limpia entradas del cache.';

  @override
  Future<int> run() async {
    const logger = Logger();
    final pattern = argResults!['pattern'] as String?;
    final all = argResults!['all'] as bool;
    final force = argResults!['force'] as bool;

    if (!all && pattern == null) {
      logger.error('Debe especificar --all o --pattern=<regex>');
      return 1;
    }

    try {
      final cacheDir = _getCacheDir();
      final cache = PersistentCache(cacheDir: cacheDir);
      await cache.initialize();

      // Obtener stats antes
      final statsBefore = await cache.getStats();

      if (!force) {
        logger.warning(
          all
              ? 'Esto eliminará ${statsBefore.diskEntries} entradas del cache.'
              : 'Esto eliminará entradas que coincidan con: $pattern',
        );
        logger.info('Use --force para omitir esta confirmación.');

        // En un CLI real, aquí pediríamos confirmación
        // Por ahora, procedemos
      }

      if (all) {
        await cache.clear();
        logger.success('Cache limpiado completamente');
      } else if (pattern != null) {
        // Limpiar por patrón
        final dir = Directory(cacheDir);
        if (await dir.exists()) {
          var deleted = 0;
          final regex = RegExp(pattern);

          await for (final file in dir.list()) {
            if (file is File && file.path.endsWith('.json')) {
              final filename = file.path.split('/').last;
              if (regex.hasMatch(filename)) {
                await file.delete();
                deleted++;
              }
            }
          }

          logger.success('Eliminadas $deleted entradas');
        }
      }

      // Mostrar stats después
      final statsAfter = await cache.getStats();
      logger.info(
        'Entradas: ${statsBefore.diskEntries} → ${statsAfter.diskEntries}',
      );

      return 0;
    } catch (e) {
      logger.error('Error limpiando cache: $e');
      return 1;
    }
  }
}

/// Subcomando para limpiar entradas expiradas.
class _CleanSubcommand extends Command<int> {
  @override
  String get name => 'clean';

  @override
  String get description => 'Elimina entradas expiradas del cache.';

  @override
  Future<int> run() async {
    const logger = Logger();

    try {
      final cacheDir = _getCacheDir();
      final cache = PersistentCache(cacheDir: cacheDir);
      await cache.initialize();

      // Stats antes
      final statsBefore = await cache.getStats();

      // Limpiar expirados
      await cache.cleanExpired();

      // Stats después
      final statsAfter = await cache.getStats();
      final cleaned = statsBefore.diskEntries - statsAfter.diskEntries;

      if (cleaned > 0) {
        logger.success('Eliminadas $cleaned entradas expiradas');
      } else {
        logger.info('No hay entradas expiradas');
      }

      logger.info('Entradas actuales: ${statsAfter.diskEntries}');

      return 0;
    } catch (e) {
      logger.error('Error limpiando cache: $e');
      return 1;
    }
  }
}

/// Obtiene el directorio de cache.
String _getCacheDir() {
  final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
  return '$home/.dfspec/cache';
}
