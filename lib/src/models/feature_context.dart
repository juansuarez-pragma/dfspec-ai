import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Estado de una feature en el flujo SDD.
///
/// Diferente de `FeatureStatus` en feature_report.dart que es para reportes.
enum SddFeatureStatus {
  /// Feature nueva, sin documentos
  none,

  /// Solo existe spec.md
  specified,

  /// Existe spec.md y plan.md
  planned,

  /// Tiene tasks.md, lista para implementar
  readyToImplement,

  /// En proceso de implementación
  implementing,

  /// Implementación completada
  implemented,

  /// Verificada contra spec
  verified,
}

/// Paths de documentos de una feature.
@immutable
class FeaturePaths extends Equatable {
  /// Crea paths de feature.
  const FeaturePaths({
    required this.featureDir,
    required this.spec,
    required this.plan,
    required this.tasks,
    required this.research,
    required this.checklist,
    required this.dataModel,
  });

  /// Crea paths vacíos.
  const FeaturePaths.empty()
      : featureDir = '',
        spec = '',
        plan = '',
        tasks = '',
        research = '',
        checklist = '',
        dataModel = '';

  /// Crea paths desde un feature ID.
  factory FeaturePaths.fromFeatureId(String featureId) {
    final featureDir = 'specs/features/$featureId';
    return FeaturePaths(
      featureDir: featureDir,
      spec: '$featureDir/spec.md',
      plan: 'specs/plans/$featureId.plan.md',
      tasks: '$featureDir/tasks.md',
      research: '$featureDir/research.md',
      checklist: '$featureDir/checklist.md',
      dataModel: '$featureDir/data-model.md',
    );
  }

  /// Directorio de la feature.
  final String featureDir;

  /// Path al archivo spec.md.
  final String spec;

  /// Path al archivo plan.md.
  final String plan;

  /// Path al archivo tasks.md.
  final String tasks;

  /// Path al archivo research.md.
  final String research;

  /// Path al archivo checklist.md.
  final String checklist;

  /// Path al archivo data-model.md.
  final String dataModel;

  @override
  List<Object?> get props => [
        featureDir,
        spec,
        plan,
        tasks,
        research,
        checklist,
        dataModel,
      ];

  /// Convierte a Map para serialización JSON.
  Map<String, dynamic> toJson() => {
        'feature_dir': featureDir,
        'spec': spec,
        'plan': plan,
        'tasks': tasks,
        'research': research,
        'checklist': checklist,
        'data_model': dataModel,
      };
}

/// Documentos existentes de una feature.
@immutable
class FeatureDocuments extends Equatable {
  /// Crea documentos de feature.
  const FeatureDocuments({
    required this.specExists,
    required this.planExists,
    required this.tasksExists,
    required this.researchExists,
    required this.checklistExists,
    required this.dataModelExists,
  });

  /// Crea documentos vacíos (ninguno existe).
  const FeatureDocuments.empty()
      : specExists = false,
        planExists = false,
        tasksExists = false,
        researchExists = false,
        checklistExists = false,
        dataModelExists = false;

  /// Si existe spec.md.
  final bool specExists;

  /// Si existe plan.md.
  final bool planExists;

  /// Si existe tasks.md.
  final bool tasksExists;

  /// Si existe research.md.
  final bool researchExists;

  /// Si existe checklist.md.
  final bool checklistExists;

  /// Si existe data-model.md.
  final bool dataModelExists;

  /// Lista de documentos disponibles.
  List<String> get availableDocuments {
    final docs = <String>[];
    if (specExists) docs.add('spec.md');
    if (planExists) docs.add('plan.md');
    if (tasksExists) docs.add('tasks.md');
    if (researchExists) docs.add('research.md');
    if (checklistExists) docs.add('checklist.md');
    if (dataModelExists) docs.add('data-model.md');
    return docs;
  }

  /// Determina el estado basado en documentos existentes.
  SddFeatureStatus get inferredStatus {
    if (!specExists) return SddFeatureStatus.none;
    if (!planExists) return SddFeatureStatus.specified;
    if (!tasksExists) return SddFeatureStatus.planned;
    return SddFeatureStatus.readyToImplement;
  }

  @override
  List<Object?> get props => [
        specExists,
        planExists,
        tasksExists,
        researchExists,
        checklistExists,
        dataModelExists,
      ];

  /// Convierte a Map para serialización JSON.
  Map<String, dynamic> toJson() => {
        'spec': specExists,
        'plan': planExists,
        'tasks': tasksExists,
        'research': researchExists,
        'checklist': checklistExists,
        'data_model': dataModelExists,
      };
}

/// Contexto completo de una feature.
@immutable
class FeatureContext extends Equatable {
  /// Crea contexto de feature.
  const FeatureContext({
    required this.id,
    required this.number,
    required this.name,
    required this.status,
    required this.branchName,
    required this.paths,
    required this.documents,
  });

  /// Crea contexto vacío (sin feature detectada).
  const FeatureContext.empty()
      : id = '',
        number = '',
        name = '',
        status = SddFeatureStatus.none,
        branchName = '',
        paths = const FeaturePaths.empty(),
        documents = const FeatureDocuments.empty();

  /// Crea contexto desde JSON (output de scripts bash).
  factory FeatureContext.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final number = json['number'] as String? ?? '';
    final name = json['name'] as String? ?? '';
    final statusStr = json['status'] as String? ?? 'none';
    final branchName = json['branch_name'] as String? ?? '';

    final paths = id.isNotEmpty
        ? FeaturePaths.fromFeatureId(id)
        : const FeaturePaths.empty();

    final docsJson = json['documents'] as Map<String, dynamic>?;
    final documents = docsJson != null
        ? FeatureDocuments(
            specExists: docsJson['spec'] as bool? ?? false,
            planExists: docsJson['plan'] as bool? ?? false,
            tasksExists: docsJson['tasks'] as bool? ?? false,
            researchExists: docsJson['research'] as bool? ?? false,
            checklistExists: docsJson['checklist'] as bool? ?? false,
            dataModelExists: docsJson['data_model'] as bool? ?? false,
          )
        : const FeatureDocuments.empty();

    return FeatureContext(
      id: id,
      number: number,
      name: name,
      status: _parseStatus(statusStr),
      branchName: branchName,
      paths: paths,
      documents: documents,
    );
  }

  /// ID completo de la feature (ej: "001-auth-feature").
  final String id;

  /// Número de la feature (ej: "001").
  final String number;

  /// Nombre de la feature sin número (ej: "auth-feature").
  final String name;

  /// Estado actual de la feature.
  final SddFeatureStatus status;

  /// Nombre del branch git asociado.
  final String branchName;

  /// Paths a los documentos de la feature.
  final FeaturePaths paths;

  /// Documentos existentes.
  final FeatureDocuments documents;

  /// Si hay una feature detectada.
  bool get hasFeature => id.isNotEmpty;

  /// Si la feature está lista para planificar (tiene spec).
  bool get canPlan => documents.specExists;

  /// Si la feature está lista para implementar (tiene spec y plan).
  bool get canImplement => documents.specExists && documents.planExists;

  /// Si la feature está lista para verificar (implementada).
  bool get canVerify => status == SddFeatureStatus.implemented;

  @override
  List<Object?> get props => [
        id,
        number,
        name,
        status,
        branchName,
        paths,
        documents,
      ];

  /// Convierte a Map para serialización JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'name': name,
        'status': status.name,
        'branch_name': branchName,
        'has_feature': hasFeature,
        'can_plan': canPlan,
        'can_implement': canImplement,
        'can_verify': canVerify,
        'paths': paths.toJson(),
        'documents': documents.toJson(),
        'available_documents': documents.availableDocuments,
      };

  static SddFeatureStatus _parseStatus(String status) {
    switch (status) {
      case 'specified':
        return SddFeatureStatus.specified;
      case 'planned':
        return SddFeatureStatus.planned;
      case 'ready_to_implement':
        return SddFeatureStatus.readyToImplement;
      case 'implementing':
        return SddFeatureStatus.implementing;
      case 'implemented':
        return SddFeatureStatus.implemented;
      case 'verified':
        return SddFeatureStatus.verified;
      default:
        return SddFeatureStatus.none;
    }
  }
}
