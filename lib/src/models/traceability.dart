import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Tipo de artefacto en el flujo SDD.
enum ArtifactType {
  /// Requisito funcional o no funcional.
  requirement('REQ'),

  /// User Story.
  userStory('US'),

  /// Criterio de aceptación.
  acceptanceCriteria('AC'),

  /// Tarea de implementación.
  task('TASK'),

  /// Archivo de test.
  test('TEST'),

  /// Archivo de código fuente.
  sourceCode('CODE');

  const ArtifactType(this.prefix);

  /// Prefijo para IDs.
  final String prefix;
}

/// Estado de cobertura de un artefacto.
enum CoverageStatus {
  /// Completamente cubierto (tiene todos los links esperados).
  covered,

  /// Parcialmente cubierto (faltan algunos links).
  partial,

  /// Sin cobertura (huérfano).
  orphan,

  /// No aplica (artefacto terminal).
  notApplicable,
}

/// Representa un artefacto trazable en el flujo SDD.
@immutable
class TraceableArtifact {
  /// Crea un artefacto trazable.
  const TraceableArtifact({
    required this.id,
    required this.type,
    required this.title,
    required this.sourcePath,
    this.lineNumber,
    this.metadata = const {},
  });

  /// ID único del artefacto (ej: REQ-001, US-001, AC-001).
  final String id;

  /// Tipo de artefacto.
  final ArtifactType type;

  /// Título o descripción corta.
  final String title;

  /// Path al archivo fuente.
  final String sourcePath;

  /// Número de línea donde se define (opcional).
  final int? lineNumber;

  /// Metadatos adicionales.
  final Map<String, dynamic> metadata;

  /// Ubicación completa para reportes.
  String get location =>
      lineNumber != null ? '$sourcePath:$lineNumber' : sourcePath;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TraceableArtifact &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;

  @override
  String toString() => '${type.prefix}-$id: $title';

  /// Convierte a Map para serialización JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'source_path': sourcePath,
        if (lineNumber != null) 'line_number': lineNumber,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

/// Representa un link de trazabilidad entre dos artefactos.
@immutable
class TraceabilityLink {
  /// Crea un link de trazabilidad.
  const TraceabilityLink({
    required this.source,
    required this.target,
    this.linkType = LinkType.implements,
    this.isVerified = false,
    this.notes,
  });

  /// Artefacto origen.
  final TraceableArtifact source;

  /// Artefacto destino.
  final TraceableArtifact target;

  /// Tipo de relación.
  final LinkType linkType;

  /// Si el link ha sido verificado.
  final bool isVerified;

  /// Notas adicionales.
  final String? notes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TraceabilityLink &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          target == other.target &&
          linkType == other.linkType;

  @override
  int get hashCode => source.hashCode ^ target.hashCode ^ linkType.hashCode;

  /// Convierte a Map para serialización JSON.
  Map<String, dynamic> toJson() => {
        'source': source.toJson(),
        'target': target.toJson(),
        'link_type': linkType.name,
        'is_verified': isVerified,
        if (notes != null) 'notes': notes,
      };
}

/// Tipo de relación entre artefactos.
enum LinkType {
  /// El source implementa el target.
  implements,

  /// El source prueba el target.
  tests,

  /// El source deriva del target.
  derivesFrom,

  /// El source satisface el target.
  satisfies,

  /// El source refina el target.
  refines,
}

/// Representa la matriz completa de trazabilidad.
@immutable
class TraceabilityMatrix {
  /// Crea una matriz de trazabilidad.
  const TraceabilityMatrix({
    required this.featureId,
    required this.artifacts,
    required this.links,
    required this.generatedAt,
  });

  /// Crea una matriz vacía.
  factory TraceabilityMatrix.empty(String featureId) => TraceabilityMatrix(
        featureId: featureId,
        artifacts: const [],
        links: const [],
        generatedAt: DateTime.now(),
      );

  /// ID de la feature analizada.
  final String featureId;

  /// Todos los artefactos encontrados.
  final List<TraceableArtifact> artifacts;

  /// Links de trazabilidad.
  final List<TraceabilityLink> links;

  /// Fecha de generación.
  final DateTime generatedAt;

  /// Obtiene artefactos por tipo.
  List<TraceableArtifact> byType(ArtifactType type) =>
      artifacts.where((a) => a.type == type).toList();

  /// Obtiene todos los requisitos.
  List<TraceableArtifact> get requirements => byType(ArtifactType.requirement);

  /// Obtiene todas las user stories.
  List<TraceableArtifact> get userStories => byType(ArtifactType.userStory);

  /// Obtiene todos los criterios de aceptación.
  List<TraceableArtifact> get acceptanceCriteria =>
      byType(ArtifactType.acceptanceCriteria);

  /// Obtiene todas las tareas.
  List<TraceableArtifact> get tasks => byType(ArtifactType.task);

  /// Obtiene todos los tests.
  List<TraceableArtifact> get tests => byType(ArtifactType.test);

  /// Obtiene todo el código fuente.
  List<TraceableArtifact> get sourceCode => byType(ArtifactType.sourceCode);

  /// Obtiene links salientes de un artefacto.
  List<TraceabilityLink> linksFrom(TraceableArtifact artifact) =>
      links.where((l) => l.source == artifact).toList();

  /// Obtiene links entrantes a un artefacto.
  List<TraceabilityLink> linksTo(TraceableArtifact artifact) =>
      links.where((l) => l.target == artifact).toList();

  /// Encuentra un artefacto por ID.
  TraceableArtifact? findById(String id) =>
      artifacts.firstWhereOrNull((a) => a.id == id);

  /// Verifica si un artefacto está cubierto.
  CoverageStatus getCoverageStatus(TraceableArtifact artifact) {
    final outgoing = linksFrom(artifact);
    final incoming = linksTo(artifact);

    // Código fuente: debe tener tests
    if (artifact.type == ArtifactType.sourceCode) {
      final hasTests =
          incoming.any((l) => l.source.type == ArtifactType.test);
      return hasTests ? CoverageStatus.covered : CoverageStatus.orphan;
    }

    // Tests: deben probar algo
    if (artifact.type == ArtifactType.test) {
      return outgoing.isNotEmpty
          ? CoverageStatus.covered
          : CoverageStatus.orphan;
    }

    // User Stories: deben tener ACs y Tasks
    if (artifact.type == ArtifactType.userStory) {
      final hasACs = outgoing.any(
        (l) => l.target.type == ArtifactType.acceptanceCriteria,
      );
      final hasTasks =
          outgoing.any((l) => l.target.type == ArtifactType.task);

      if (hasACs && hasTasks) return CoverageStatus.covered;
      if (hasACs || hasTasks) return CoverageStatus.partial;
      return CoverageStatus.orphan;
    }

    // Requisitos: deben tener User Stories
    if (artifact.type == ArtifactType.requirement) {
      final hasStories =
          outgoing.any((l) => l.target.type == ArtifactType.userStory);
      return hasStories ? CoverageStatus.covered : CoverageStatus.orphan;
    }

    // ACs y Tasks: verificar implementación
    if (artifact.type == ArtifactType.acceptanceCriteria ||
        artifact.type == ArtifactType.task) {
      final hasCode =
          outgoing.any((l) => l.target.type == ArtifactType.sourceCode);
      final hasTests =
          outgoing.any((l) => l.target.type == ArtifactType.test);

      if (hasCode && hasTests) return CoverageStatus.covered;
      if (hasCode || hasTests) return CoverageStatus.partial;
      return CoverageStatus.orphan;
    }

    return CoverageStatus.notApplicable;
  }

  /// Obtiene artefactos huérfanos (sin cobertura).
  List<TraceableArtifact> get orphanArtifacts => artifacts
      .where((a) => getCoverageStatus(a) == CoverageStatus.orphan)
      .toList();

  /// Obtiene artefactos con cobertura parcial.
  List<TraceableArtifact> get partialArtifacts => artifacts
      .where((a) => getCoverageStatus(a) == CoverageStatus.partial)
      .toList();

  /// Calcula el porcentaje de cobertura total.
  double get coveragePercentage {
    if (artifacts.isEmpty) return 100;

    final applicable = artifacts
        .where((a) => getCoverageStatus(a) != CoverageStatus.notApplicable);
    if (applicable.isEmpty) return 100;

    final covered = applicable
        .where((a) => getCoverageStatus(a) == CoverageStatus.covered)
        .length;

    return (covered / applicable.length) * 100;
  }

  /// Convierte a Map para serialización JSON.
  Map<String, dynamic> toJson() => {
        'feature_id': featureId,
        'generated_at': generatedAt.toIso8601String(),
        'summary': {
          'total_artifacts': artifacts.length,
          'requirements': requirements.length,
          'user_stories': userStories.length,
          'acceptance_criteria': acceptanceCriteria.length,
          'tasks': tasks.length,
          'tests': tests.length,
          'source_files': sourceCode.length,
          'total_links': links.length,
          'coverage_percentage': coveragePercentage.toStringAsFixed(1),
          'orphan_count': orphanArtifacts.length,
          'partial_count': partialArtifacts.length,
        },
        'artifacts': artifacts.map((a) => a.toJson()).toList(),
        'links': links.map((l) => l.toJson()).toList(),
        'orphans': orphanArtifacts.map((a) => a.toJson()).toList(),
        'partial': partialArtifacts.map((a) => a.toJson()).toList(),
      };
}

/// Resultado del análisis de consistencia.
@immutable
class ConsistencyReport {
  /// Crea un reporte de consistencia.
  const ConsistencyReport({
    required this.matrix,
    required this.issues,
    required this.suggestions,
  });

  /// Matriz de trazabilidad analizada.
  final TraceabilityMatrix matrix;

  /// Issues encontrados.
  final List<ConsistencyIssue> issues;

  /// Sugerencias de mejora.
  final List<String> suggestions;

  /// Si el análisis pasó (sin issues críticos).
  bool get passed => !issues.any((i) => i.severity == IssueSeverity.critical);

  /// Score de consistencia (0-100).
  int get score {
    if (issues.isEmpty) return 100;

    var penalty = 0;
    for (final issue in issues) {
      switch (issue.severity) {
        case IssueSeverity.critical:
          penalty += 20;
        case IssueSeverity.warning:
          penalty += 10;
        case IssueSeverity.info:
          penalty += 2;
      }
    }

    return (100 - penalty).clamp(0, 100);
  }

  /// Convierte a Map para serialización JSON.
  Map<String, dynamic> toJson() => {
        'passed': passed,
        'score': score,
        'coverage_percentage': matrix.coveragePercentage.toStringAsFixed(1),
        'issues': issues.map((i) => i.toJson()).toList(),
        'suggestions': suggestions,
        'matrix': matrix.toJson(),
      };
}

/// Issue de consistencia encontrado.
@immutable
class ConsistencyIssue {
  /// Crea un issue de consistencia.
  const ConsistencyIssue({
    required this.code,
    required this.message,
    required this.severity,
    this.artifact,
    this.suggestion,
  });

  /// Código del issue.
  final String code;

  /// Mensaje descriptivo.
  final String message;

  /// Severidad.
  final IssueSeverity severity;

  /// Artefacto relacionado (opcional).
  final TraceableArtifact? artifact;

  /// Sugerencia de corrección.
  final String? suggestion;

  /// Convierte a Map para serialización JSON.
  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        'severity': severity.name,
        if (artifact != null) 'artifact': artifact!.toJson(),
        if (suggestion != null) 'suggestion': suggestion,
      };
}

/// Severidad de un issue.
enum IssueSeverity {
  /// Crítico - debe corregirse.
  critical,

  /// Warning - debería corregirse.
  warning,

  /// Info - sugerencia.
  info,
}
