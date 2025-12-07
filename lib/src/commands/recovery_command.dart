import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dfspec/src/services/recovery_manager.dart';
import 'package:dfspec/src/utils/logger.dart';

/// Comando para gestión de puntos de recuperación.
///
/// Uso:
/// ```bash
/// dfspec recovery create --feature=city-search --component=entity --message="Pre-refactor"
/// dfspec recovery list
/// dfspec recovery list --feature=city-search
/// dfspec recovery restore --feature=city-search
/// dfspec recovery restore --feature=city-search --id=abc123
/// dfspec recovery report
/// ```
class RecoveryCommand extends Command<int> {
  /// Crea el comando recovery.
  RecoveryCommand() {
    addSubcommand(_CreateSubcommand());
    addSubcommand(_ListSubcommand());
    addSubcommand(_RestoreSubcommand());
    addSubcommand(_ReportSubcommand());
    addSubcommand(_PruneSubcommand());
  }

  @override
  String get name => 'recovery';

  @override
  String get description => 'Gestiona puntos de recuperación TDD.';

  @override
  String get invocation => 'dfspec recovery <subcomando>';
}

/// Subcomando para crear punto de recuperación.
class _CreateSubcommand extends Command<int> {
  _CreateSubcommand() {
    argParser
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'Nombre de la feature.',
        mandatory: true,
      )
      ..addOption(
        'component',
        abbr: 'c',
        help: 'Nombre del componente (entity, usecase, etc.).',
        mandatory: true,
      )
      ..addOption(
        'message',
        abbr: 'm',
        help: 'Mensaje descriptivo.',
        defaultsTo: 'Manual checkpoint',
      )
      ..addMultiOption(
        'files',
        help: 'Archivos a incluir en el checkpoint.',
      );
  }

  @override
  String get name => 'create';

  @override
  String get description => 'Crea un punto de recuperación manual.';

  @override
  Future<int> run() async {
    const logger = Logger();
    final feature = argResults!['feature'] as String;
    final component = argResults!['component'] as String;
    final message = argResults!['message'] as String;
    final files = argResults!['files'] as List<String>;

    logger.info('Creando punto de recuperación para: $feature/$component');

    try {
      final manager = RecoveryManager(projectRoot: Directory.current.path);
      await manager.initialize();

      // Si no se especificaron archivos, buscar en lib/src
      final filePaths = files.isNotEmpty
          ? files
          : await _findFeatureFiles(feature, component);

      final point = await manager.createManualCheckpoint(
        feature: feature,
        component: component,
        filePaths: filePaths,
        description: message,
      );

      logger.success('Punto de recuperación creado');
      logger.blank();
      logger.panel(
        'Recovery Point',
        '''
ID: ${point.id}
Feature: ${point.feature}
Component: ${point.component}
Tipo: ${point.type.label}
Estado: ${point.status.label}
Archivos: ${point.files.length}
Creado: ${point.timestamp.toIso8601String()}
''',
      );

      return 0;
    } catch (e) {
      logger.error('Error creando punto de recuperación: $e');
      return 1;
    }
  }

  Future<List<String>> _findFeatureFiles(String feature, String component) async {
    final files = <String>[];
    final projectRoot = Directory.current.path;

    // Buscar en lib/src
    final libDir = Directory('$projectRoot/lib/src');
    if (await libDir.exists()) {
      await for (final entity in libDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final relativePath = entity.path.replaceFirst('$projectRoot/', '');
          if (relativePath.contains(feature) || relativePath.contains(component)) {
            files.add(relativePath);
          }
        }
      }
    }

    // Buscar tests correspondientes
    final testDir = Directory('$projectRoot/test');
    if (await testDir.exists()) {
      await for (final entity in testDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('_test.dart')) {
          final relativePath = entity.path.replaceFirst('$projectRoot/', '');
          if (relativePath.contains(feature) || relativePath.contains(component)) {
            files.add(relativePath);
          }
        }
      }
    }

    return files;
  }
}

/// Subcomando para listar puntos de recuperación.
class _ListSubcommand extends Command<int> {
  _ListSubcommand() {
    argParser.addOption(
      'feature',
      abbr: 'f',
      help: 'Filtrar por feature.',
    );
  }

  @override
  String get name => 'list';

  @override
  String get description => 'Lista puntos de recuperación.';

  @override
  Future<int> run() async {
    const logger = Logger();
    final feature = argResults!['feature'] as String?;

    try {
      final manager = RecoveryManager(projectRoot: Directory.current.path);
      await manager.initialize();

      final features = feature != null ? [feature] : manager.features;

      if (features.isEmpty) {
        logger.info('No hay puntos de recuperación');
        return 0;
      }

      logger.title('Puntos de Recuperación');
      logger.blank();

      for (final f in features) {
        final chain = manager.getChain(f);
        logger.write(chain.toSummary());
        logger.blank();
      }

      return 0;
    } catch (e) {
      logger.error('Error listando puntos: $e');
      return 1;
    }
  }
}

/// Subcomando para restaurar punto de recuperación.
class _RestoreSubcommand extends Command<int> {
  _RestoreSubcommand() {
    argParser
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'Feature a restaurar.',
        mandatory: true,
      )
      ..addOption(
        'id',
        help: 'ID específico del punto (por defecto: último estable).',
      )
      ..addFlag(
        'dry-run',
        help: 'Muestra qué se restauraría sin hacer cambios.',
        negatable: false,
      );
  }

  @override
  String get name => 'restore';

  @override
  String get description => 'Restaura un punto de recuperación.';

  @override
  Future<int> run() async {
    const logger = Logger();
    final feature = argResults!['feature'] as String;
    final id = argResults!['id'] as String?;
    final dryRun = argResults!['dry-run'] as bool;

    try {
      final manager = RecoveryManager(projectRoot: Directory.current.path);
      await manager.initialize();

      final chain = manager.getChain(feature);

      if (chain.points.isEmpty) {
        logger.error('No hay puntos de recuperación para: $feature');
        return 1;
      }

      // Determinar punto a restaurar
      final targetPoint = id != null
          ? chain.points.firstWhere(
              (p) => p.id == id || p.id.startsWith(id),
              orElse: () => throw Exception('Punto no encontrado: $id'),
            )
          : chain.lastStablePoint;

      if (targetPoint == null) {
        logger.error('No hay puntos estables para restaurar');
        return 1;
      }

      logger.info('Punto encontrado: ${targetPoint.id}');
      logger.info('Componente: ${targetPoint.component}');
      logger.info('Archivos: ${targetPoint.files.length}');

      if (dryRun) {
        logger.blank();
        logger.section('Archivos a restaurar (dry-run)');
        for (final file in targetPoint.files) {
          final action = file.exists ? 'restaurar' : 'eliminar';
          logger.item('${file.path} ($action)');
        }
        return 0;
      }

      final result = await manager.recoverToPoint(feature, targetPoint.id);

      if (result.success) {
        logger.success(result.message);
        logger.info('Archivos restaurados: ${result.restoredFiles.length}');
      } else {
        logger.warning(result.message);
        if (result.errors.isNotEmpty) {
          for (final error in result.errors) {
            logger.error('  - $error');
          }
        }
        return 1;
      }

      return 0;
    } catch (e) {
      logger.error('Error restaurando: $e');
      return 1;
    }
  }
}

/// Subcomando para generar reporte de recovery.
class _ReportSubcommand extends Command<int> {
  @override
  String get name => 'report';

  @override
  String get description => 'Genera reporte de estado de recovery.';

  @override
  Future<int> run() async {
    const logger = Logger();

    try {
      final manager = RecoveryManager(projectRoot: Directory.current.path);
      await manager.initialize();

      final report = manager.generateReport();
      // ignore: avoid_print
      print(report);

      return 0;
    } catch (e) {
      logger.error('Error generando reporte: $e');
      return 1;
    }
  }
}

/// Subcomando para limpiar puntos antiguos.
class _PruneSubcommand extends Command<int> {
  _PruneSubcommand() {
    argParser
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'Feature específica a limpiar.',
        mandatory: true,
      )
      ..addOption(
        'keep-stable',
        defaultsTo: '5',
        help: 'Número de puntos estables a mantener.',
      )
      ..addOption(
        'max-age',
        defaultsTo: '7',
        help: 'Máxima antigüedad en días.',
      );
  }

  @override
  String get name => 'prune';

  @override
  String get description => 'Limpia puntos de recuperación antiguos.';

  @override
  Future<int> run() async {
    const logger = Logger();
    final feature = argResults!['feature'] as String;
    final keepStable = int.parse(argResults!['keep-stable'] as String);
    final maxAgeDays = int.parse(argResults!['max-age'] as String);

    try {
      final manager = RecoveryManager(projectRoot: Directory.current.path);
      await manager.initialize();

      final pruned = await manager.pruneOldPoints(
        feature: feature,
        keepStable: keepStable,
        maxAge: Duration(days: maxAgeDays),
      );

      if (pruned > 0) {
        logger.success('Eliminados $pruned puntos antiguos');
      } else {
        logger.info('No hay puntos para eliminar');
      }

      return 0;
    } catch (e) {
      logger.error('Error limpiando puntos: $e');
      return 1;
    }
  }
}
