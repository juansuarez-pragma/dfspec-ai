import 'package:meta/meta.dart';

/// Severidad de una violacion constitucional.
enum GateSeverity {
  /// Violacion critica - el codigo sera rechazado.
  critical('Rechazado'),

  /// Advertencia - requiere justificacion para continuar.
  warning('Advertencia'),

  /// Informativo - sugerencia de mejora.
  info('Sugerencia');

  const GateSeverity(this.label);

  /// Etiqueta para mostrar.
  final String label;
}

/// Estado del resultado de validacion de un gate.
enum GateStatus {
  /// Gate paso correctamente.
  passed,

  /// Gate fallo.
  failed,

  /// Gate paso con advertencias.
  warning,

  /// Gate no aplica al contexto actual.
  notApplicable,
}

/// Resultado de la validacion de un gate individual.
@immutable
class GateResult {
  /// Crea un resultado de validacion.
  const GateResult({
    required this.gateId,
    required this.status,
    this.message,
    this.details = const [],
    this.location,
  });

  /// Crea un resultado exitoso.
  factory GateResult.passed(String gateId, {String? message}) {
    return GateResult(
      gateId: gateId,
      status: GateStatus.passed,
      message: message,
    );
  }

  /// Crea un resultado fallido.
  factory GateResult.failed(
    String gateId, {
    required String message,
    List<String> details = const [],
    String? location,
  }) {
    return GateResult(
      gateId: gateId,
      status: GateStatus.failed,
      message: message,
      details: details,
      location: location,
    );
  }

  /// Crea un resultado con advertencia.
  factory GateResult.warning(
    String gateId, {
    required String message,
    List<String> details = const [],
  }) {
    return GateResult(
      gateId: gateId,
      status: GateStatus.warning,
      message: message,
      details: details,
    );
  }

  /// ID del gate evaluado.
  final String gateId;

  /// Estado del resultado.
  final GateStatus status;

  /// Mensaje descriptivo.
  final String? message;

  /// Detalles adicionales (ubicaciones, sugerencias).
  final List<String> details;

  /// Ubicacion del archivo/linea donde se detecto el problema.
  final String? location;

  /// Verifica si el resultado es exitoso.
  bool get isPassed => status == GateStatus.passed;

  /// Verifica si el resultado fallo.
  bool get isFailed => status == GateStatus.failed;

  @override
  String toString() {
    final statusIcon = switch (status) {
      GateStatus.passed => '✓',
      GateStatus.failed => '✗',
      GateStatus.warning => '⚠',
      GateStatus.notApplicable => '○',
    };
    return '$statusIcon [$gateId] ${message ?? status.name}';
  }
}

/// Definicion de un gate constitucional.
///
/// Representa una regla de la constitucion que debe validarse
/// durante el proceso de desarrollo.
@immutable
class ConstitutionalGate {
  /// Crea un gate constitucional.
  const ConstitutionalGate({
    required this.id,
    required this.articleNumber,
    required this.name,
    required this.description,
    required this.severity,
    this.rules = const [],
    this.checkPatterns = const [],
    this.violationPatterns = const [],
  });

  /// Identificador unico del gate (ej: 'clean-architecture').
  final String id;

  /// Numero del articulo en la constitucion (I, II, III...).
  final String articleNumber;

  /// Nombre corto del gate.
  final String name;

  /// Descripcion completa de lo que valida.
  final String description;

  /// Severidad de las violaciones.
  final GateSeverity severity;

  /// Reglas especificas a validar.
  final List<String> rules;

  /// Patrones regex que indican conformidad.
  final List<String> checkPatterns;

  /// Patrones regex que indican violacion.
  final List<String> violationPatterns;

  /// Convierte a mapa.
  Map<String, dynamic> toJson() => {
        'id': id,
        'articleNumber': articleNumber,
        'name': name,
        'description': description,
        'severity': severity.name,
        'rules': rules,
        'checkPatterns': checkPatterns,
        'violationPatterns': violationPatterns,
      };

  @override
  String toString() => 'Gate($articleNumber: $name)';
}

/// Coleccion de resultados de validacion constitucional.
@immutable
class ConstitutionalReport {
  /// Crea un reporte de validacion.
  const ConstitutionalReport({
    required this.results,
    required this.timestamp,
    this.context,
  });

  /// Crea un reporte vacio.
  factory ConstitutionalReport.empty() {
    return ConstitutionalReport(
      results: const [],
      timestamp: DateTime.now(),
    );
  }

  /// Lista de resultados de cada gate.
  final List<GateResult> results;

  /// Marca temporal de la validacion.
  final DateTime timestamp;

  /// Contexto adicional (nombre de feature, archivo, etc).
  final String? context;

  /// Obtiene resultados exitosos.
  List<GateResult> get passed =>
      results.where((r) => r.status == GateStatus.passed).toList();

  /// Obtiene resultados fallidos.
  List<GateResult> get failed =>
      results.where((r) => r.status == GateStatus.failed).toList();

  /// Obtiene advertencias.
  List<GateResult> get warnings =>
      results.where((r) => r.status == GateStatus.warning).toList();

  /// Verifica si todos los gates pasaron.
  bool get allPassed => failed.isEmpty;

  /// Verifica si hay errores criticos.
  bool get hasCriticalFailures => failed.isNotEmpty;

  /// Porcentaje de gates exitosos.
  double get passRate {
    if (results.isEmpty) return 1;
    final applicable =
        results.where((r) => r.status != GateStatus.notApplicable).length;
    if (applicable == 0) return 1;
    return passed.length / applicable;
  }

  /// Genera resumen en formato texto.
  String toSummary() {
    final buffer = StringBuffer()
      ..writeln('## Reporte Constitucional')
      ..writeln()
      ..writeln(
        '**Fecha:** ${timestamp.toIso8601String().split('T').first}',
      );

    if (context != null) {
      buffer.writeln('**Contexto:** $context');
    }

    buffer
      ..writeln()
      ..writeln('### Resumen')
      ..writeln()
      ..writeln('| Estado | Cantidad |')
      ..writeln('|--------|----------|')
      ..writeln('| ✓ Pasados | ${passed.length} |')
      ..writeln('| ✗ Fallidos | ${failed.length} |')
      ..writeln('| ⚠ Advertencias | ${warnings.length} |')
      ..writeln()
      ..writeln('**Tasa de cumplimiento:** ${(passRate * 100).toStringAsFixed(0)}%');

    if (failed.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Violaciones')
        ..writeln();

      for (final result in failed) {
        buffer.writeln('- $result');
        for (final detail in result.details) {
          buffer.writeln('  - $detail');
        }
      }
    }

    if (warnings.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Advertencias')
        ..writeln();

      for (final result in warnings) {
        buffer.writeln('- $result');
      }
    }

    return buffer.toString();
  }

  @override
  String toString() =>
      'ConstitutionalReport(passed: ${passed.length}, failed: ${failed.length})';
}

/// Gates constitucionales predefinidos basados en la constitucion DFSpec.
class ConstitutionalGates {
  ConstitutionalGates._();

  /// Gate I: Clean Architecture.
  static const cleanArchitecture = ConstitutionalGate(
    id: 'clean-architecture',
    articleNumber: 'I',
    name: 'Clean Architecture',
    description: 'Separacion estricta de capas: domain, data, presentation',
    severity: GateSeverity.critical,
    rules: [
      'Domain NO importa Data ni Presentation',
      'Data importa Domain (para implementar interfaces)',
      'Presentation importa Domain (para usar entidades y usecases)',
    ],
    violationPatterns: [
      r"import\s+'package:[^']+/data/",
      r"import\s+'package:[^']+/presentation/",
    ],
  );

  /// Gate II: Test-Driven Development.
  static const tdd = ConstitutionalGate(
    id: 'tdd',
    articleNumber: 'II',
    name: 'Test-Driven Development',
    description: 'Todo codigo de produccion debe tener test correspondiente',
    severity: GateSeverity.critical,
    rules: [
      'Ciclo RED-GREEN-REFACTOR',
      'Correspondencia 1:1 entre archivos lib y test',
      'Patron AAA (Arrange-Act-Assert)',
    ],
  );

  /// Gate III: Entidades Inmutables.
  static const immutableEntities = ConstitutionalGate(
    id: 'immutable-entities',
    articleNumber: 'III',
    name: 'Entidades Inmutables',
    description: 'Entidades de dominio deben ser inmutables con Equatable',
    severity: GateSeverity.critical,
    rules: [
      'Usar Equatable para igualdad por valor',
      'Prohibido: setters, campos mutables',
      'Todos los campos deben ser final',
    ],
    checkPatterns: [
      r'extends\s+Equatable',
      r'final\s+\w+\s+\w+;',
    ],
    violationPatterns: [
      r'set\s+\w+\s*\(',
      r'^\s+\w+\s+\w+;', // Campo no final
    ],
  );

  /// Gate IV: Separacion Modelo-Entidad.
  static const modelEntitySeparation = ConstitutionalGate(
    id: 'model-entity-separation',
    articleNumber: 'IV',
    name: 'Separacion Modelo-Entidad',
    description: 'Modelos (DTOs) separados de entidades de dominio',
    severity: GateSeverity.critical,
    rules: [
      'Modelos en data/models con fromJson/toJson',
      'Entidades en domain/entities sin conocimiento de JSON',
      'Metodo toEntity() en modelos',
    ],
    checkPatterns: [
      r'toEntity\(\)',
      r'fromJson\(',
    ],
    violationPatterns: [
      r'fromJson\(.*\)\s*{[^}]*extends\s+Equatable',
    ],
  );

  /// Gate V: Interfaces en Domain.
  static const domainInterfaces = ConstitutionalGate(
    id: 'domain-interfaces',
    articleNumber: 'V',
    name: 'Interfaces en Domain',
    description: 'Repositorios en domain son interfaces abstractas',
    severity: GateSeverity.critical,
    rules: [
      'domain/repositories contiene clases abstractas',
      'Implementaciones van en data/repositories',
    ],
    checkPatterns: [
      r'abstract\s+class\s+\w+Repository',
      r'implements\s+\w+Repository',
    ],
  );

  /// Gate VI: UseCases Atomicos.
  static const atomicUseCases = ConstitutionalGate(
    id: 'atomic-usecases',
    articleNumber: 'VI',
    name: 'UseCases Atomicos',
    description: 'Cada UseCase tiene una sola responsabilidad',
    severity: GateSeverity.critical,
    rules: [
      'Un metodo call() por UseCase',
      'Single Responsibility Principle',
    ],
    checkPatterns: [
      r'Future<[^>]+>\s+call\(',
      r'class\s+\w+\s*{[^}]*call\([^}]*}',
    ],
  );

  /// Gate VII: State Management Consistente.
  static const stateManagement = ConstitutionalGate(
    id: 'state-management',
    articleNumber: 'VII',
    name: 'State Management',
    description: 'Usar un solo patron definido en dfspec.yaml',
    severity: GateSeverity.warning,
    rules: [
      'Riverpod: Notifier/AsyncNotifier para estado',
      'BLoC: Eventos y estados tipados',
      'No mezclar patrones',
    ],
  );

  /// Gate VIII: Manejo de Errores.
  static const errorHandling = ConstitutionalGate(
    id: 'error-handling',
    articleNumber: 'VIII',
    name: 'Manejo de Errores',
    description: 'Usar excepciones tipadas para errores esperados',
    severity: GateSeverity.warning,
    rules: [
      'Excepciones tipadas (ServerException, NetworkException, etc)',
      'No usar Exception generica',
    ],
    checkPatterns: [
      r'class\s+\w+Exception\s+implements\s+Exception',
    ],
    violationPatterns: [
      r'throw\s+Exception\(',
    ],
  );

  /// Gate IX: Cobertura Minima.
  static const minimumCoverage = ConstitutionalGate(
    id: 'minimum-coverage',
    articleNumber: 'IX',
    name: 'Cobertura Minima',
    description: 'Mantener cobertura de tests >85%',
    severity: GateSeverity.warning,
    rules: [
      'Domain: >95%',
      'Data: >90%',
      'Presentation: >80%',
      'Widgets: >70%',
    ],
  );

  /// Gate X: Performance Flutter.
  static const flutterPerformance = ConstitutionalGate(
    id: 'flutter-performance',
    articleNumber: 'X',
    name: 'Performance Flutter',
    description: 'Respetar frame budget de 16ms',
    severity: GateSeverity.warning,
    rules: [
      'Usar const donde sea posible',
      'Keys en listas',
      'ListView.builder para listas largas',
      'No operaciones pesadas en main thread',
    ],
    checkPatterns: [
      r'const\s+\w+\(',
      r'ListView\.builder\(',
      r'key:\s*ValueKey\(',
    ],
    violationPatterns: [
      r'setState\(\s*\(\)\s*{\s*}\s*\)',
    ],
  );

  /// Gate XI: Documentacion Minima.
  static const minimumDocs = ConstitutionalGate(
    id: 'minimum-docs',
    articleNumber: 'XI',
    name: 'Documentacion Minima',
    description: 'APIs publicas documentadas segun Effective Dart',
    severity: GateSeverity.info,
    rules: [
      'Doc comments (///) en clases publicas',
      'Documentar parametros no obvios',
    ],
    checkPatterns: [
      r'///\s+.+',
    ],
  );

  /// Todos los gates predefinidos.
  static const List<ConstitutionalGate> all = [
    cleanArchitecture,
    tdd,
    immutableEntities,
    modelEntitySeparation,
    domainInterfaces,
    atomicUseCases,
    stateManagement,
    errorHandling,
    minimumCoverage,
    flutterPerformance,
    minimumDocs,
  ];

  /// Gates criticos (deben pasar obligatoriamente).
  static List<ConstitutionalGate> get critical =>
      all.where((g) => g.severity == GateSeverity.critical).toList();

  /// Obtiene gate por ID.
  static ConstitutionalGate? byId(String id) {
    try {
      return all.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Obtiene gate por numero de articulo.
  static ConstitutionalGate? byArticle(String articleNumber) {
    try {
      return all.firstWhere((g) => g.articleNumber == articleNumber);
    } catch (_) {
      return null;
    }
  }
}
