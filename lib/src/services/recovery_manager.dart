import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dfspec/src/models/recovery_point.dart';

/// Gestor de recovery points para TDD.
///
/// Permite crear checkpoints después de tests verdes y recuperar
/// el estado si algo falla durante el desarrollo.
class RecoveryManager {
  /// Crea un recovery manager.
  RecoveryManager({
    required this.projectRoot,
    String? recoveryDir,
  }) : recoveryDir = recoveryDir ?? '$projectRoot/.dfspec/recovery';

  /// Directorio raíz del proyecto.
  final String projectRoot;

  /// Directorio donde se guardan los recovery points.
  final String recoveryDir;

  /// Cadenas de recovery en memoria (cache).
  final Map<String, RecoveryChain> _chains = {};

  /// Inicializa el manager y carga cadenas existentes.
  Future<void> initialize() async {
    final dir = Directory(recoveryDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Cargar cadenas existentes
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.chain.json')) {
        try {
          final content = await entity.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final chain = RecoveryChain.fromJson(json);
          _chains[chain.feature] = chain;
        } catch (_) {
          // Ignorar archivos corruptos
        }
      }
    }
  }

  /// Obtiene la cadena de una feature, creándola si no existe.
  RecoveryChain getChain(String feature) {
    return _chains[feature] ?? RecoveryChain.empty(feature);
  }

  /// Lista todas las features con recovery chains.
  List<String> get features => _chains.keys.toList();

  /// Crea un checkpoint después de un test verde.
  Future<RecoveryPoint> createGreenCheckpoint({
    required String feature,
    required String component,
    required List<String> filePaths,
    required List<RecoveryTestResult> testResults,
    String? description,
  }) async {
    return _createCheckpoint(
      feature: feature,
      component: component,
      type: RecoveryType.greenTest,
      filePaths: filePaths,
      testResults: testResults,
      description: description,
    );
  }

  /// Crea un checkpoint antes de refactoring.
  Future<RecoveryPoint> createPreRefactorCheckpoint({
    required String feature,
    required String component,
    required List<String> filePaths,
    required List<RecoveryTestResult> testResults,
    String? description,
  }) async {
    return _createCheckpoint(
      feature: feature,
      component: component,
      type: RecoveryType.preRefactor,
      filePaths: filePaths,
      testResults: testResults,
      description: description ?? 'Pre-refactor checkpoint',
    );
  }

  /// Crea un checkpoint de componente completo.
  Future<RecoveryPoint> createComponentCheckpoint({
    required String feature,
    required String component,
    required List<String> filePaths,
    required List<RecoveryTestResult> testResults,
    String? description,
  }) async {
    return _createCheckpoint(
      feature: feature,
      component: component,
      type: RecoveryType.componentComplete,
      filePaths: filePaths,
      testResults: testResults,
      description: description ?? 'Component complete: $component',
    );
  }

  /// Crea un checkpoint de milestone.
  Future<RecoveryPoint> createMilestoneCheckpoint({
    required String feature,
    required String component,
    required List<String> filePaths,
    required List<RecoveryTestResult> testResults,
    required String description,
  }) async {
    return _createCheckpoint(
      feature: feature,
      component: component,
      type: RecoveryType.milestone,
      filePaths: filePaths,
      testResults: testResults,
      description: description,
    );
  }

  /// Crea un checkpoint manual.
  Future<RecoveryPoint> createManualCheckpoint({
    required String feature,
    required String component,
    required List<String> filePaths,
    List<RecoveryTestResult>? testResults,
    String? description,
  }) async {
    return _createCheckpoint(
      feature: feature,
      component: component,
      type: RecoveryType.manual,
      filePaths: filePaths,
      testResults: testResults ?? [],
      description: description ?? 'Manual checkpoint',
    );
  }

  /// Implementación interna de creación de checkpoint.
  Future<RecoveryPoint> _createCheckpoint({
    required String feature,
    required String component,
    required RecoveryType type,
    required List<String> filePaths,
    required List<RecoveryTestResult> testResults,
    String? description,
  }) async {
    final chain = getChain(feature);
    final id = _generateId();

    // Capturar estado de archivos
    final files = await _captureFileStates(filePaths);

    // Determinar estado basado en tests
    final allPassed = testResults.isEmpty ||
        testResults.every((t) => t.allPassed);

    final status = allPassed ? RecoveryStatus.stable : RecoveryStatus.failing;

    final point = RecoveryPoint(
      id: id,
      feature: feature,
      component: component,
      type: type,
      status: status,
      timestamp: DateTime.now(),
      files: files,
      testResults: testResults,
      description: description,
      parentId: chain.lastPoint?.id,
    );

    // Guardar contenido de archivos si es checkpoint importante
    if (type.retentionPriority >= 3) {
      await _saveFileContents(point);
    }

    // Actualizar cadena
    final newChain = chain.addPoint(point);
    _chains[feature] = newChain;
    await _saveChain(newChain);

    return point;
  }

  /// Recupera al último punto estable.
  Future<RecoveryResult> recoverToLastStable(String feature) async {
    final chain = getChain(feature);
    final stablePoint = chain.lastStablePoint;

    if (stablePoint == null) {
      return RecoveryResult.failed(
        'No hay puntos estables para recuperar en feature: $feature',
      );
    }

    return recoverToPoint(feature, stablePoint.id);
  }

  /// Recupera a un punto específico.
  Future<RecoveryResult> recoverToPoint(String feature, String pointId) async {
    final chain = getChain(feature);
    final point = chain.points.where((p) => p.id == pointId).firstOrNull;

    if (point == null) {
      return RecoveryResult.failed(
        'Punto de recuperación no encontrado: $pointId',
      );
    }

    final restoredFiles = <String>[];
    final errors = <String>[];

    for (final fileState in point.files) {
      try {
        final restored = await _restoreFile(point, fileState);
        if (restored) {
          restoredFiles.add(fileState.path);
        }
      } catch (e) {
        errors.add('Error restaurando ${fileState.path}: $e');
      }
    }

    // Invalidar puntos posteriores
    final newChain = chain.invalidateAfter(pointId);
    _chains[feature] = newChain;
    await _saveChain(newChain);

    if (errors.isNotEmpty) {
      return RecoveryResult.partial(
        'Recuperación parcial a ${point.component}',
        restoredFiles: restoredFiles,
        errors: errors,
      );
    }

    return RecoveryResult.success(
      'Recuperado a ${point.component} (${point.type.label})',
      restoredFiles: restoredFiles,
      point: point,
    );
  }

  /// Limpia puntos antiguos manteniendo solo los importantes.
  Future<int> pruneOldPoints({
    required String feature,
    int keepStable = 5,
    int keepMilestones = 10,
    Duration maxAge = const Duration(days: 7),
  }) async {
    final chain = getChain(feature);
    final cutoff = DateTime.now().subtract(maxAge);
    var pruned = 0;

    final pointsToKeep = <RecoveryPoint>[];
    var stableKept = 0;
    var milestonesKept = 0;

    // Recorrer desde el más reciente
    for (final point in chain.points.reversed) {
      final isRecent = point.timestamp.isAfter(cutoff);
      final isMilestone = point.type == RecoveryType.milestone;
      final isStable = point.status == RecoveryStatus.stable;

      var keep = false;

      if (isRecent) {
        keep = true;
      } else if (isMilestone && milestonesKept < keepMilestones) {
        keep = true;
        milestonesKept++;
      } else if (isStable && stableKept < keepStable) {
        keep = true;
        stableKept++;
      }

      if (keep) {
        pointsToKeep.insert(0, point);
      } else {
        // Eliminar archivos guardados
        await _deletePointFiles(point);
        pruned++;
      }
    }

    if (pruned > 0) {
      final newChain = RecoveryChain(
        feature: feature,
        points: pointsToKeep,
        currentPointId: chain.currentPointId,
      );
      _chains[feature] = newChain;
      await _saveChain(newChain);
    }

    return pruned;
  }

  /// Captura el estado actual de los archivos.
  Future<List<RecoveryFileState>> _captureFileStates(
    List<String> paths,
  ) async {
    final states = <RecoveryFileState>[];

    for (final path in paths) {
      final fullPath = path.startsWith('/') ? path : '$projectRoot/$path';
      final file = File(fullPath);

      if (await file.exists()) {
        final content = await file.readAsString();
        final hash = sha256.convert(utf8.encode(content)).toString();
        final relativePath = _relativePath(fullPath);

        states.add(RecoveryFileState(
          path: relativePath,
          hash: hash,
          exists: true,
          // Solo guardar contenido inline si es pequeño
          content: content.length < 10000 ? content : null,
        ));
      } else {
        states.add(RecoveryFileState(
          path: _relativePath(fullPath),
          hash: '',
          exists: false,
        ));
      }
    }

    return states;
  }

  /// Guarda el contenido de archivos de un punto.
  Future<void> _saveFileContents(RecoveryPoint point) async {
    final pointDir = Directory('$recoveryDir/${point.feature}/${point.id}');
    if (!await pointDir.exists()) {
      await pointDir.create(recursive: true);
    }

    for (final fileState in point.files) {
      if (fileState.exists && fileState.content == null) {
        // Leer y guardar contenido
        final sourcePath = '$projectRoot/${fileState.path}';
        final sourceFile = File(sourcePath);

        if (await sourceFile.exists()) {
          final destPath = '${pointDir.path}/${fileState.hash}';
          await sourceFile.copy(destPath);
        }
      }
    }
  }

  /// Restaura un archivo desde un punto de recovery.
  Future<bool> _restoreFile(
    RecoveryPoint point,
    RecoveryFileState fileState,
  ) async {
    final destPath = '$projectRoot/${fileState.path}';
    final destFile = File(destPath);

    if (!fileState.exists) {
      // El archivo no existía en ese punto, eliminarlo
      if (await destFile.exists()) {
        await destFile.delete();
      }
      return true;
    }

    // Intentar restaurar desde contenido inline
    if (fileState.content != null) {
      await destFile.parent.create(recursive: true);
      await destFile.writeAsString(fileState.content!);
      return true;
    }

    // Intentar restaurar desde archivo guardado
    final savedPath = '$recoveryDir/${point.feature}/${point.id}/${fileState.hash}';
    final savedFile = File(savedPath);

    if (await savedFile.exists()) {
      await destFile.parent.create(recursive: true);
      await savedFile.copy(destPath);
      return true;
    }

    return false;
  }

  /// Elimina archivos guardados de un punto.
  Future<void> _deletePointFiles(RecoveryPoint point) async {
    final pointDir = Directory('$recoveryDir/${point.feature}/${point.id}');
    if (await pointDir.exists()) {
      await pointDir.delete(recursive: true);
    }
  }

  /// Guarda una cadena a disco.
  Future<void> _saveChain(RecoveryChain chain) async {
    final file = File('$recoveryDir/${chain.feature}.chain.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(chain.toJson()),
    );
  }

  /// Genera un ID único.
  String _generateId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toRadixString(36);
    final random = now.microsecond.toRadixString(36).padLeft(4, '0');
    return '$timestamp-$random';
  }

  /// Convierte ruta absoluta a relativa.
  String _relativePath(String path) {
    if (path.startsWith(projectRoot)) {
      return path.substring(projectRoot.length + 1);
    }
    return path;
  }

  /// Genera reporte de estado de recovery.
  String generateReport() {
    final buffer = StringBuffer();
    buffer.writeln('# Recovery Status Report');
    buffer.writeln();
    buffer.writeln('**Generated:** ${DateTime.now().toIso8601String()}');
    buffer.writeln('**Project:** $projectRoot');
    buffer.writeln();

    if (_chains.isEmpty) {
      buffer.writeln('*No recovery chains found*');
      return buffer.toString();
    }

    for (final chain in _chains.values) {
      buffer.writeln(chain.toSummary());
      buffer.writeln();
    }

    return buffer.toString();
  }
}

/// Resultado de una operación de recovery.
class RecoveryResult {
  /// Crea un resultado.
  const RecoveryResult._({
    required this.success,
    required this.message,
    this.restoredFiles = const [],
    this.errors = const [],
    this.point,
  });

  /// Recovery exitoso.
  factory RecoveryResult.success(
    String message, {
    required List<String> restoredFiles,
    RecoveryPoint? point,
  }) {
    return RecoveryResult._(
      success: true,
      message: message,
      restoredFiles: restoredFiles,
      point: point,
    );
  }

  /// Recovery parcial (algunos errores).
  factory RecoveryResult.partial(
    String message, {
    required List<String> restoredFiles,
    required List<String> errors,
  }) {
    return RecoveryResult._(
      success: false,
      message: message,
      restoredFiles: restoredFiles,
      errors: errors,
    );
  }

  /// Recovery fallido.
  factory RecoveryResult.failed(String message) {
    return RecoveryResult._(
      success: false,
      message: message,
    );
  }

  /// Si fue exitoso.
  final bool success;

  /// Mensaje descriptivo.
  final String message;

  /// Archivos restaurados.
  final List<String> restoredFiles;

  /// Errores encontrados.
  final List<String> errors;

  /// Punto al que se recuperó.
  final RecoveryPoint? point;

  @override
  String toString() {
    final icon = success ? '✓' : '✗';
    return 'RecoveryResult($icon $message, ${restoredFiles.length} files)';
  }
}
