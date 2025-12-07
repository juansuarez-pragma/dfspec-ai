import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Prioridad de una User Story.
///
/// - [p1]: MVP - Funcionalidad core, debe estar en primera entrega
/// - [p2]: Importante - Segunda iteracion
/// - [p3]: Nice-to-have - Puede esperar
enum Priority {
  /// MVP - Funcionalidad core, debe estar en primera entrega.
  p1('P1', 'MVP'),

  /// Importante - Segunda iteracion.
  p2('P2', 'Important'),

  /// Nice-to-have - Puede esperar.
  p3('P3', 'Nice-to-have');

  const Priority(this.code, this.label);

  /// Codigo corto (P1, P2, P3).
  final String code;

  /// Etiqueta descriptiva.
  final String label;

  /// Parsea una prioridad desde string.
  ///
  /// Acepta formatos: "P1", "p1", "MVP", "P1 - MVP", etc.
  static Priority? tryParse(String value) {
    final normalized = value.toUpperCase().trim();

    if (normalized.contains('P1') || normalized.contains('MVP')) {
      return Priority.p1;
    }
    if (normalized.contains('P2') || normalized.contains('IMPORTANT')) {
      return Priority.p2;
    }
    if (normalized.contains('P3') || normalized.contains('NICE')) {
      return Priority.p3;
    }

    return null;
  }

  @override
  String toString() => '$code - $label';
}

/// Criterio de aceptacion en formato Given/When/Then.
@immutable
class AcceptanceCriteria {
  /// Crea un criterio de aceptacion.
  const AcceptanceCriteria({
    required this.id,
    required this.given,
    required this.when,
    required this.then,
    this.isCompleted = false,
  });

  /// Crea un criterio desde un mapa.
  factory AcceptanceCriteria.fromMap(Map<String, dynamic> map) {
    return AcceptanceCriteria(
      id: map['id'] as String? ?? '',
      given: map['given'] as String? ?? '',
      when: map['when'] as String? ?? '',
      then: map['then'] as String? ?? '',
      isCompleted: map['is_completed'] as bool? ?? false,
    );
  }

  /// Identificador unico (AC-001, AC-002, etc.).
  final String id;

  /// Condicion inicial (Given).
  final String given;

  /// Accion del usuario (When).
  final String when;

  /// Resultado esperado (Then).
  final String then;

  /// Si el criterio ha sido verificado.
  final bool isCompleted;

  /// Convierte a mapa.
  Map<String, dynamic> toMap() => {
        'id': id,
        'given': given,
        'when': when,
        'then': then,
        'is_completed': isCompleted,
      };

  /// Genera formato Gherkin.
  String toGherkin() => '''
Given $given
When $when
Then $then''';

  /// Copia con modificaciones.
  AcceptanceCriteria copyWith({
    String? id,
    String? given,
    String? when,
    String? then,
    bool? isCompleted,
  }) {
    return AcceptanceCriteria(
      id: id ?? this.id,
      given: given ?? this.given,
      when: when ?? this.when,
      then: then ?? this.then,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcceptanceCriteria &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          given == other.given &&
          when == other.when &&
          then == other.then;

  @override
  int get hashCode => Object.hash(id, given, when, then);

  @override
  String toString() => 'AcceptanceCriteria($id)';
}

/// User Story siguiendo formato estandar.
@immutable
class UserStory {
  /// Crea una User Story.
  const UserStory({
    required this.id,
    required this.title,
    required this.priority,
    required this.asA,
    required this.iWant,
    required this.soThat,
    this.acceptanceCriteria = const [],
    this.isIndependentlyTestable = true,
    this.testabilityReason,
    this.relatedRequirements = const [],
    this.tasks = const [],
  });

  /// Crea una User Story desde un mapa.
  factory UserStory.fromMap(Map<String, dynamic> map) {
    final criteriaList = (map['acceptance_criteria'] as List<dynamic>?)
            ?.map((e) => AcceptanceCriteria.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];

    return UserStory(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      priority: Priority.tryParse(map['priority'] as String? ?? '') ??
          Priority.p2,
      asA: map['as_a'] as String? ?? '',
      iWant: map['i_want'] as String? ?? '',
      soThat: map['so_that'] as String? ?? '',
      acceptanceCriteria: criteriaList,
      isIndependentlyTestable:
          map['is_independently_testable'] as bool? ?? true,
      testabilityReason: map['testability_reason'] as String?,
      relatedRequirements:
          (map['related_requirements'] as List<dynamic>?)?.cast<String>() ??
              [],
      tasks: (map['tasks'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Identificador unico (US-001, US-002, etc.).
  final String id;

  /// Titulo descriptivo.
  final String title;

  /// Prioridad (P1-MVP, P2, P3).
  final Priority priority;

  /// Rol del usuario (formato "Como <rol>").
  final String asA;

  /// Funcionalidad deseada (formato "Quiero <funcionalidad>").
  final String iWant;

  /// Beneficio esperado (formato "Para <beneficio>").
  final String soThat;

  /// Lista de criterios de aceptacion.
  final List<AcceptanceCriteria> acceptanceCriteria;

  /// Si puede probarse de forma independiente.
  final bool isIndependentlyTestable;

  /// Razon de testabilidad independiente.
  final String? testabilityReason;

  /// IDs de requisitos funcionales relacionados (FR-001, FR-002).
  final List<String> relatedRequirements;

  /// IDs de tareas asociadas (T001, T002).
  final List<String> tasks;

  /// Verifica si es MVP (P1).
  bool get isMvp => priority == Priority.p1;

  /// Cuenta criterios completados.
  int get completedCriteriaCount =>
      acceptanceCriteria.where((c) => c.isCompleted).length;

  /// Porcentaje de completitud.
  double get completionPercentage => acceptanceCriteria.isEmpty
      ? 0.0
      : completedCriteriaCount / acceptanceCriteria.length;

  /// Verifica si todos los criterios estan completos.
  bool get isFullyAccepted =>
      acceptanceCriteria.isNotEmpty &&
      acceptanceCriteria.every((c) => c.isCompleted);

  /// Convierte a mapa.
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'priority': priority.code,
        'as_a': asA,
        'i_want': iWant,
        'so_that': soThat,
        'acceptance_criteria': acceptanceCriteria.map((c) => c.toMap()).toList(),
        'is_independently_testable': isIndependentlyTestable,
        'testability_reason': testabilityReason,
        'related_requirements': relatedRequirements,
        'tasks': tasks,
      };

  /// Genera formato de User Story estandar.
  String toStoryFormat() => '''
### $id: $title (Priority: ${priority.code})

**Como** $asA
**Quiero** $iWant
**Para** $soThat

#### Criterios de Aceptacion
${acceptanceCriteria.map((c) => '- [ ] ${c.id}: ${c.toGherkin()}').join('\n')}

#### Test Independiente
${isIndependentlyTestable ? 'Si - ${testabilityReason ?? 'Puede probarse de forma aislada'}' : 'No - Requiere dependencias'}
''';

  /// Copia con modificaciones.
  UserStory copyWith({
    String? id,
    String? title,
    Priority? priority,
    String? asA,
    String? iWant,
    String? soThat,
    List<AcceptanceCriteria>? acceptanceCriteria,
    bool? isIndependentlyTestable,
    String? testabilityReason,
    List<String>? relatedRequirements,
    List<String>? tasks,
  }) {
    return UserStory(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      asA: asA ?? this.asA,
      iWant: iWant ?? this.iWant,
      soThat: soThat ?? this.soThat,
      acceptanceCriteria: acceptanceCriteria ?? this.acceptanceCriteria,
      isIndependentlyTestable:
          isIndependentlyTestable ?? this.isIndependentlyTestable,
      testabilityReason: testabilityReason ?? this.testabilityReason,
      relatedRequirements: relatedRequirements ?? this.relatedRequirements,
      tasks: tasks ?? this.tasks,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          priority == other.priority;

  @override
  int get hashCode => Object.hash(id, title, priority);

  @override
  String toString() => 'UserStory($id: $title [${priority.code}])';
}

/// Coleccion de User Stories con utilidades.
@immutable
class UserStoryCollection {
  /// Crea una coleccion de User Stories.
  const UserStoryCollection(this.stories);

  /// Crea una coleccion desde una lista de mapas.
  factory UserStoryCollection.fromList(List<Map<String, dynamic>> list) {
    return UserStoryCollection(list.map(UserStory.fromMap).toList());
  }

  /// Lista de User Stories.
  final List<UserStory> stories;

  /// Obtiene stories MVP (P1).
  List<UserStory> get mvpStories =>
      stories.where((s) => s.priority == Priority.p1).toList();

  /// Obtiene stories P2.
  List<UserStory> get p2Stories =>
      stories.where((s) => s.priority == Priority.p2).toList();

  /// Obtiene stories P3.
  List<UserStory> get p3Stories =>
      stories.where((s) => s.priority == Priority.p3).toList();

  /// Agrupa stories por prioridad.
  Map<Priority, List<UserStory>> get byPriority => groupBy(
        stories,
        (UserStory s) => s.priority,
      );

  /// Cuenta total de criterios de aceptacion.
  int get totalCriteria =>
      stories.fold(0, (sum, s) => sum + s.acceptanceCriteria.length);

  /// Cuenta criterios completados.
  int get completedCriteria =>
      stories.fold(0, (sum, s) => sum + s.completedCriteriaCount);

  /// Porcentaje de completitud global.
  double get overallCompletion =>
      totalCriteria == 0 ? 0.0 : completedCriteria / totalCriteria;

  /// Busca story por ID.
  UserStory? findById(String id) =>
      stories.firstWhereOrNull((s) => s.id == id);

  /// Obtiene stories relacionadas a un requisito.
  List<UserStory> findByRequirement(String requirementId) =>
      stories.where((s) => s.relatedRequirements.contains(requirementId)).toList();

  /// Verifica si el MVP esta completo.
  bool get isMvpComplete => mvpStories.every((s) => s.isFullyAccepted);

  /// Convierte a lista de mapas.
  List<Map<String, dynamic>> toList() => stories.map((s) => s.toMap()).toList();

  @override
  String toString() =>
      'UserStoryCollection(${stories.length} stories, MVP: ${mvpStories.length})';
}
