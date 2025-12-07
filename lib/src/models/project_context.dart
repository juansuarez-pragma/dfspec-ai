import 'package:dfspec/src/models/feature_context.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Tipo de proyecto Dart/Flutter.
enum ProjectType {
  /// Aplicación Flutter con UI.
  flutterApp,

  /// Paquete/librería Dart reutilizable.
  dartPackage,

  /// Aplicación de línea de comandos.
  dartCli,

  /// Plugin Flutter con código nativo.
  flutterPlugin,

  /// Tipo desconocido.
  unknown,
}

/// Estado del repositorio git.
@immutable
class GitContext extends Equatable {
  /// Crea contexto git.
  const GitContext({
    required this.isGitRepo,
    required this.currentBranch,
    required this.gitRoot,
    required this.hasUncommittedChanges,
    required this.remoteUrl,
  });

  /// Crea contexto git vacío (no es repo git).
  const GitContext.empty()
      : isGitRepo = false,
        currentBranch = '',
        gitRoot = '',
        hasUncommittedChanges = false,
        remoteUrl = '';

  /// Crea desde JSON (output de scripts bash).
  factory GitContext.fromJson(Map<String, dynamic> json) {
    return GitContext(
      isGitRepo: json['is_git_repo'] as bool? ?? false,
      currentBranch: json['current_branch'] as String? ?? '',
      gitRoot: json['git_root'] as String? ?? '',
      hasUncommittedChanges: json['has_uncommitted_changes'] as bool? ?? false,
      remoteUrl: json['remote_url'] as String? ?? '',
    );
  }

  /// Si estamos en un repositorio git.
  final bool isGitRepo;

  /// Nombre del branch actual.
  final String currentBranch;

  /// Ruta raíz del repositorio.
  final String gitRoot;

  /// Si hay cambios sin commitear.
  final bool hasUncommittedChanges;

  /// URL del remote origin.
  final String remoteUrl;

  @override
  List<Object?> get props => [
        isGitRepo,
        currentBranch,
        gitRoot,
        hasUncommittedChanges,
        remoteUrl,
      ];

  /// Convierte a Map para serialización JSON.
  Map<String, dynamic> toJson() => {
        'is_git_repo': isGitRepo,
        'current_branch': currentBranch,
        'git_root': gitRoot,
        'has_uncommitted_changes': hasUncommittedChanges,
        'remote_url': remoteUrl,
      };
}

/// Información del proyecto.
@immutable
class ProjectInfo extends Equatable {
  /// Crea información de proyecto.
  const ProjectInfo({
    required this.name,
    required this.type,
    required this.stateManagement,
    required this.hasDfspecConfig,
    required this.hasPubspec,
    required this.hasConstitution,
    required this.platforms,
  });

  /// Crea información de proyecto vacía.
  const ProjectInfo.empty()
      : name = '',
        type = ProjectType.unknown,
        stateManagement = '',
        hasDfspecConfig = false,
        hasPubspec = false,
        hasConstitution = false,
        platforms = const [];

  /// Crea desde JSON (output de scripts bash).
  factory ProjectInfo.fromJson(Map<String, dynamic> json) {
    return ProjectInfo(
      name: json['name'] as String? ?? '',
      type: _parseProjectType(json['type'] as String? ?? ''),
      stateManagement: json['state_management'] as String? ?? '',
      hasDfspecConfig: json['has_dfspec_config'] as bool? ?? false,
      hasPubspec: json['has_pubspec'] as bool? ?? false,
      hasConstitution: json['has_constitution'] as bool? ?? false,
      platforms: (json['platforms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  /// Nombre del proyecto.
  final String name;

  /// Tipo de proyecto.
  final ProjectType type;

  /// State management usado (riverpod, bloc, provider, etc).
  final String stateManagement;

  /// Si existe dfspec.yaml.
  final bool hasDfspecConfig;

  /// Si existe pubspec.yaml.
  final bool hasPubspec;

  /// Si existe constitution.md.
  final bool hasConstitution;

  /// Plataformas soportadas (android, ios, web, etc).
  final List<String> platforms;

  /// Si el proyecto está configurado con DFSpec.
  bool get isConfigured => hasDfspecConfig;

  /// Si es un proyecto Flutter.
  bool get isFlutter =>
      type == ProjectType.flutterApp || type == ProjectType.flutterPlugin;

  /// Si es un proyecto Dart puro.
  bool get isDartOnly =>
      type == ProjectType.dartPackage || type == ProjectType.dartCli;

  @override
  List<Object?> get props => [
        name,
        type,
        stateManagement,
        hasDfspecConfig,
        hasPubspec,
        hasConstitution,
        platforms,
      ];

  /// Convierte a Map para serialización JSON.
  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.name,
        'state_management': stateManagement,
        'has_dfspec_config': hasDfspecConfig,
        'has_pubspec': hasPubspec,
        'has_constitution': hasConstitution,
        'platforms': platforms,
        'is_configured': isConfigured,
        'is_flutter': isFlutter,
        'is_dart_only': isDartOnly,
      };

  static ProjectType _parseProjectType(String type) {
    switch (type.toLowerCase()) {
      case 'flutter_app':
      case 'flutterapp':
        return ProjectType.flutterApp;
      case 'dart_package':
      case 'dartpackage':
      case 'package':
        return ProjectType.dartPackage;
      case 'dart_cli':
      case 'dartcli':
      case 'cli':
      case 'console':
        return ProjectType.dartCli;
      case 'flutter_plugin':
      case 'flutterplugin':
      case 'plugin':
        return ProjectType.flutterPlugin;
      default:
        return ProjectType.unknown;
    }
  }
}

/// Métricas de calidad del proyecto (conteo de archivos).
///
/// Diferente de `QualityMetrics` en quality_metrics.dart que es para métricas detalladas.
@immutable
class ProjectQualityMetrics extends Equatable {
  /// Crea métricas de calidad.
  const ProjectQualityMetrics({
    required this.hasTests,
    required this.testFileCount,
    required this.hasLib,
    required this.libFileCount,
    required this.hasRecoveryPoints,
    required this.recoveryChainCount,
  });

  /// Crea métricas vacías.
  const ProjectQualityMetrics.empty()
      : hasTests = false,
        testFileCount = 0,
        hasLib = false,
        libFileCount = 0,
        hasRecoveryPoints = false,
        recoveryChainCount = 0;

  /// Crea desde JSON (output de scripts bash).
  factory ProjectQualityMetrics.fromJson(Map<String, dynamic> json) {
    return ProjectQualityMetrics(
      hasTests: json['has_tests'] as bool? ?? false,
      testFileCount: json['test_file_count'] as int? ?? 0,
      hasLib: json['has_lib'] as bool? ?? false,
      libFileCount: json['lib_file_count'] as int? ?? 0,
      hasRecoveryPoints: json['has_recovery_points'] as bool? ?? false,
      recoveryChainCount: json['recovery_chain_count'] as int? ?? 0,
    );
  }

  /// Si hay directorio de tests.
  final bool hasTests;

  /// Cantidad de archivos de test.
  final int testFileCount;

  /// Si hay directorio lib.
  final bool hasLib;

  /// Cantidad de archivos en lib.
  final int libFileCount;

  /// Si hay recovery points.
  final bool hasRecoveryPoints;

  /// Cantidad de cadenas de recovery.
  final int recoveryChainCount;

  /// Ratio aproximado de tests por archivo de código.
  double get testRatio =>
      libFileCount > 0 ? testFileCount / libFileCount : 0.0;

  @override
  List<Object?> get props => [
        hasTests,
        testFileCount,
        hasLib,
        libFileCount,
        hasRecoveryPoints,
        recoveryChainCount,
      ];

  /// Convierte a Map para serialización JSON.
  Map<String, dynamic> toJson() => {
        'has_tests': hasTests,
        'test_file_count': testFileCount,
        'has_lib': hasLib,
        'lib_file_count': libFileCount,
        'has_recovery_points': hasRecoveryPoints,
        'recovery_chain_count': recoveryChainCount,
        'test_ratio': testRatio,
      };
}

/// Contexto completo del proyecto y feature actual.
@immutable
class ProjectContext extends Equatable {
  /// Crea contexto de proyecto.
  const ProjectContext({
    required this.project,
    required this.git,
    required this.feature,
    required this.quality,
    required this.nextFeatureNumber,
  });

  /// Crea contexto vacío.
  const ProjectContext.empty()
      : project = const ProjectInfo.empty(),
        git = const GitContext.empty(),
        feature = const FeatureContext.empty(),
        quality = const ProjectQualityMetrics.empty(),
        nextFeatureNumber = '001';

  /// Crea desde JSON completo (output de detect-context.sh).
  factory ProjectContext.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    final projectJson = data['project'] as Map<String, dynamic>? ?? {};
    final gitJson = data['git'] as Map<String, dynamic>? ?? {};
    final featureJson = data['feature'] as Map<String, dynamic>? ?? {};
    final qualityJson = data['quality'] as Map<String, dynamic>? ?? {};
    final documentsJson = data['documents'] as Map<String, dynamic>? ?? {};

    // Combinar feature con documents para FeatureContext
    final featureWithDocs = Map<String, dynamic>.from(featureJson);
    if (documentsJson.isNotEmpty) {
      featureWithDocs['documents'] = documentsJson['exists'];
    }

    return ProjectContext(
      project: ProjectInfo.fromJson(projectJson),
      git: GitContext.fromJson(gitJson),
      feature: FeatureContext.fromJson(featureWithDocs),
      quality: ProjectQualityMetrics.fromJson(qualityJson),
      nextFeatureNumber:
          featureJson['next_available_number'] as String? ?? '001',
    );
  }

  /// Información del proyecto.
  final ProjectInfo project;

  /// Estado del repositorio git.
  final GitContext git;

  /// Feature actual detectada.
  final FeatureContext feature;

  /// Métricas de calidad.
  final ProjectQualityMetrics quality;

  /// Siguiente número de feature disponible.
  final String nextFeatureNumber;

  /// Si hay un proyecto válido.
  bool get hasProject => project.hasPubspec || project.hasDfspecConfig;

  /// Si hay una feature activa.
  bool get hasActiveFeature => feature.hasFeature;

  /// Si el proyecto necesita inicialización.
  bool get needsInit => !project.hasDfspecConfig;

  /// Si el proyecto necesita crear una feature.
  bool get needsFeature => !feature.hasFeature;

  /// Mensaje de estado resumido.
  String get statusMessage {
    if (!hasProject) {
      return 'No se detectó proyecto. Ejecuta "dfspec init" primero.';
    }
    if (needsInit) {
      return 'Proyecto detectado pero sin DFSpec. Ejecuta "dfspec init".';
    }
    if (needsFeature) {
      return 'DFSpec configurado. Crea una feature con /df-spec.';
    }
    return 'Feature activa: ${feature.id} (${feature.status.name})';
  }

  @override
  List<Object?> get props => [
        project,
        git,
        feature,
        quality,
        nextFeatureNumber,
      ];

  /// Convierte a Map para serialización JSON.
  Map<String, dynamic> toJson() => {
        'project': project.toJson(),
        'git': git.toJson(),
        'feature': feature.toJson(),
        'quality': quality.toJson(),
        'next_feature_number': nextFeatureNumber,
        'has_project': hasProject,
        'has_active_feature': hasActiveFeature,
        'needs_init': needsInit,
        'needs_feature': needsFeature,
        'status_message': statusMessage,
      };
}
