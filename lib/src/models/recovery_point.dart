import 'package:meta/meta.dart';

/// Estado de un recovery point.
enum RecoveryStatus {
  /// Punto creado, aún no validado.
  pending('Pendiente'),

  /// Tests pasando en este punto.
  stable('Estable'),

  /// Tests fallando, necesita recovery.
  failing('Fallando'),

  /// Recuperado desde un punto anterior.
  recovered('Recuperado'),

  /// Punto invalidado (cambios incompatibles).
  invalidated('Invalidado');

  const RecoveryStatus(this.label);
  final String label;
}

/// Tipo de recovery point.
enum RecoveryType {
  /// Checkpoint automático después de test verde.
  greenTest('Test Verde'),

  /// Checkpoint manual solicitado.
  manual('Manual'),

  /// Checkpoint antes de refactor.
  preRefactor('Pre-Refactor'),

  /// Checkpoint después de completar un componente.
  componentComplete('Componente Completo'),

  /// Checkpoint de milestone (varios componentes).
  milestone('Milestone');

  const RecoveryType(this.label);
  final String label;

  /// Prioridad de retención (mayor = más importante mantener).
  int get retentionPriority {
    switch (this) {
      case RecoveryType.milestone:
        return 5;
      case RecoveryType.componentComplete:
        return 4;
      case RecoveryType.manual:
        return 3;
      case RecoveryType.preRefactor:
        return 2;
      case RecoveryType.greenTest:
        return 1;
    }
  }
}

/// Información de un archivo en un recovery point.
@immutable
class RecoveryFileState {
  /// Crea el estado de un archivo.
  const RecoveryFileState({
    required this.path,
    required this.hash,
    required this.exists,
    this.content,
  });

  /// Ruta relativa del archivo.
  final String path;

  /// Hash SHA-256 del contenido.
  final String hash;

  /// Si el archivo existe.
  final bool exists;

  /// Contenido del archivo (opcional, para archivos pequeños).
  final String? content;

  /// Crea desde JSON.
  factory RecoveryFileState.fromJson(Map<String, dynamic> json) {
    return RecoveryFileState(
      path: json['path'] as String,
      hash: json['hash'] as String,
      exists: json['exists'] as bool? ?? true,
      content: json['content'] as String?,
    );
  }

  /// Convierte a JSON.
  Map<String, dynamic> toJson() => {
        'path': path,
        'hash': hash,
        'exists': exists,
        if (content != null) 'content': content,
      };

  @override
  String toString() => 'FileState($path, ${exists ? hash.substring(0, 8) : "deleted"})';
}

/// Resultado de test en un recovery point.
@immutable
class RecoveryTestResult {
  /// Crea un resultado de test.
  const RecoveryTestResult({
    required this.testPath,
    required this.passed,
    required this.total,
    this.failures = const [],
    this.duration,
  });

  /// Ruta del archivo de test.
  final String testPath;

  /// Número de tests que pasaron.
  final int passed;

  /// Total de tests ejecutados.
  final int total;

  /// Lista de tests fallidos (si hay).
  final List<String> failures;

  /// Duración de ejecución.
  final Duration? duration;

  /// Si todos los tests pasaron.
  bool get allPassed => passed == total;

  /// Porcentaje de éxito.
  double get successRate => total > 0 ? passed / total : 1.0;

  /// Crea desde JSON.
  factory RecoveryTestResult.fromJson(Map<String, dynamic> json) {
    return RecoveryTestResult(
      testPath: json['testPath'] as String,
      passed: json['passed'] as int,
      total: json['total'] as int,
      failures: (json['failures'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      duration: json['durationMs'] != null
          ? Duration(milliseconds: json['durationMs'] as int)
          : null,
    );
  }

  /// Convierte a JSON.
  Map<String, dynamic> toJson() => {
        'testPath': testPath,
        'passed': passed,
        'total': total,
        if (failures.isNotEmpty) 'failures': failures,
        if (duration != null) 'durationMs': duration!.inMilliseconds,
      };

  @override
  String toString() =>
      'TestResult($testPath: $passed/$total${allPassed ? " ✓" : " ✗"})';
}

/// Un punto de recuperación en el desarrollo TDD.
@immutable
class RecoveryPoint {
  /// Crea un recovery point.
  const RecoveryPoint({
    required this.id,
    required this.feature,
    required this.component,
    required this.type,
    required this.status,
    required this.timestamp,
    required this.files,
    this.testResults = const [],
    this.description,
    this.parentId,
    this.metadata = const {},
  });

  /// ID único del punto (UUID o timestamp-based).
  final String id;

  /// Feature al que pertenece.
  final String feature;

  /// Componente específico (entity, usecase, etc.).
  final String component;

  /// Tipo de recovery point.
  final RecoveryType type;

  /// Estado actual del punto.
  final RecoveryStatus status;

  /// Timestamp de creación.
  final DateTime timestamp;

  /// Estado de archivos en este punto.
  final List<RecoveryFileState> files;

  /// Resultados de tests en este punto.
  final List<RecoveryTestResult> testResults;

  /// Descripción opcional.
  final String? description;

  /// ID del punto padre (para formar cadena).
  final String? parentId;

  /// Metadata adicional.
  final Map<String, dynamic> metadata;

  /// Si todos los tests pasan en este punto.
  bool get isGreen =>
      testResults.isNotEmpty && testResults.every((t) => t.allPassed);

  /// Total de tests en este punto.
  int get totalTests => testResults.fold(0, (sum, t) => sum + t.total);

  /// Tests pasando en este punto.
  int get passingTests => testResults.fold(0, (sum, t) => sum + t.passed);

  /// Crea un punto estable (tests pasan).
  factory RecoveryPoint.stable({
    required String id,
    required String feature,
    required String component,
    required RecoveryType type,
    required List<RecoveryFileState> files,
    required List<RecoveryTestResult> testResults,
    String? description,
    String? parentId,
  }) {
    return RecoveryPoint(
      id: id,
      feature: feature,
      component: component,
      type: type,
      status: RecoveryStatus.stable,
      timestamp: DateTime.now(),
      files: files,
      testResults: testResults,
      description: description,
      parentId: parentId,
    );
  }

  /// Crea un punto fallando.
  factory RecoveryPoint.failing({
    required String id,
    required String feature,
    required String component,
    required List<RecoveryFileState> files,
    required List<RecoveryTestResult> testResults,
    String? description,
    String? parentId,
  }) {
    return RecoveryPoint(
      id: id,
      feature: feature,
      component: component,
      type: RecoveryType.greenTest,
      status: RecoveryStatus.failing,
      timestamp: DateTime.now(),
      files: files,
      testResults: testResults,
      description: description,
      parentId: parentId,
    );
  }

  /// Crea copia con nuevo estado.
  RecoveryPoint copyWith({
    RecoveryStatus? status,
    List<RecoveryTestResult>? testResults,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return RecoveryPoint(
      id: id,
      feature: feature,
      component: component,
      type: type,
      status: status ?? this.status,
      timestamp: timestamp,
      files: files,
      testResults: testResults ?? this.testResults,
      description: description ?? this.description,
      parentId: parentId,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Crea desde JSON.
  factory RecoveryPoint.fromJson(Map<String, dynamic> json) {
    return RecoveryPoint(
      id: json['id'] as String,
      feature: json['feature'] as String,
      component: json['component'] as String,
      type: RecoveryType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => RecoveryType.manual,
      ),
      status: RecoveryStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => RecoveryStatus.pending,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      files: (json['files'] as List<dynamic>)
          .map((f) => RecoveryFileState.fromJson(f as Map<String, dynamic>))
          .toList(),
      testResults: (json['testResults'] as List<dynamic>?)
              ?.map(
                  (t) => RecoveryTestResult.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      description: json['description'] as String?,
      parentId: json['parentId'] as String?,
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  /// Convierte a JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'feature': feature,
        'component': component,
        'type': type.name,
        'status': status.name,
        'timestamp': timestamp.toIso8601String(),
        'files': files.map((f) => f.toJson()).toList(),
        if (testResults.isNotEmpty)
          'testResults': testResults.map((t) => t.toJson()).toList(),
        if (description != null) 'description': description,
        if (parentId != null) 'parentId': parentId,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  @override
  String toString() {
    final icon = switch (status) {
      RecoveryStatus.stable => '✓',
      RecoveryStatus.failing => '✗',
      RecoveryStatus.recovered => '↺',
      RecoveryStatus.invalidated => '⊘',
      RecoveryStatus.pending => '○',
    };
    return 'RecoveryPoint($icon $feature/$component [${type.label}])';
  }
}

/// Cadena de recovery points para una feature.
@immutable
class RecoveryChain {
  /// Crea una cadena de recovery.
  const RecoveryChain({
    required this.feature,
    required this.points,
    this.currentPointId,
  });

  /// Feature de la cadena.
  final String feature;

  /// Puntos en orden cronológico.
  final List<RecoveryPoint> points;

  /// ID del punto actualmente activo.
  final String? currentPointId;

  /// Punto actual.
  RecoveryPoint? get currentPoint =>
      points.where((p) => p.id == currentPointId).firstOrNull;

  /// Último punto estable.
  RecoveryPoint? get lastStablePoint => points
      .where((p) => p.status == RecoveryStatus.stable)
      .lastOrNull;

  /// Último punto de cualquier tipo.
  RecoveryPoint? get lastPoint => points.lastOrNull;

  /// Si la cadena está en estado verde.
  bool get isGreen => lastPoint?.isGreen ?? true;

  /// Puntos estables disponibles para recovery.
  List<RecoveryPoint> get stablePoints =>
      points.where((p) => p.status == RecoveryStatus.stable).toList();

  /// Crea cadena vacía.
  factory RecoveryChain.empty(String feature) {
    return RecoveryChain(feature: feature, points: const []);
  }

  /// Agrega un punto a la cadena.
  RecoveryChain addPoint(RecoveryPoint point) {
    return RecoveryChain(
      feature: feature,
      points: [...points, point],
      currentPointId: point.id,
    );
  }

  /// Invalida puntos posteriores a un ID.
  RecoveryChain invalidateAfter(String pointId) {
    final index = points.indexWhere((p) => p.id == pointId);
    if (index == -1 || index == points.length - 1) return this;

    final newPoints = [
      ...points.take(index + 1),
      ...points.skip(index + 1).map(
            (p) => p.copyWith(status: RecoveryStatus.invalidated),
          ),
    ];

    return RecoveryChain(
      feature: feature,
      points: newPoints,
      currentPointId: pointId,
    );
  }

  /// Crea desde JSON.
  factory RecoveryChain.fromJson(Map<String, dynamic> json) {
    return RecoveryChain(
      feature: json['feature'] as String,
      points: (json['points'] as List<dynamic>)
          .map((p) => RecoveryPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      currentPointId: json['currentPointId'] as String?,
    );
  }

  /// Convierte a JSON.
  Map<String, dynamic> toJson() => {
        'feature': feature,
        'points': points.map((p) => p.toJson()).toList(),
        if (currentPointId != null) 'currentPointId': currentPointId,
      };

  /// Genera resumen de la cadena.
  String toSummary() {
    final buffer = StringBuffer();
    buffer.writeln('## Recovery Chain: $feature');
    buffer.writeln();

    if (points.isEmpty) {
      buffer.writeln('*Sin puntos de recuperación*');
      return buffer.toString();
    }

    buffer.writeln('| # | Tipo | Componente | Estado | Tests |');
    buffer.writeln('|---|------|------------|--------|-------|');

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final isCurrent = p.id == currentPointId ? '→ ' : '  ';
      final statusIcon = switch (p.status) {
        RecoveryStatus.stable => '✓',
        RecoveryStatus.failing => '✗',
        RecoveryStatus.recovered => '↺',
        RecoveryStatus.invalidated => '⊘',
        RecoveryStatus.pending => '○',
      };
      buffer.writeln(
        '| $isCurrent${i + 1} | ${p.type.label} | ${p.component} | $statusIcon | ${p.passingTests}/${p.totalTests} |',
      );
    }

    final stable = stablePoints.length;
    buffer.writeln();
    buffer.writeln('**Puntos estables:** $stable/${points.length}');

    return buffer.toString();
  }
}
