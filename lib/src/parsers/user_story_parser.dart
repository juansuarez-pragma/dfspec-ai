import 'package:dfspec/src/models/user_story.dart';

/// Parser para extraer User Stories desde texto Markdown.
class UserStoryParser {
  /// Patron para detectar inicio de User Story.
  ///
  /// Formato: `### US-001: Titulo (Priority: P1)`
  static final _storyHeaderPattern = RegExp(
    r'###\s+(US-\d+):\s+(.+?)\s*\(Priority:\s*(P[123](?:\s*-\s*[\w-]+)?)\)',
    caseSensitive: false,
  );

  /// Patron para formato "Como [rol]".
  static final _asAPattern = RegExp(
    r'\*\*Como\*\*\s+(.+)',
    caseSensitive: false,
  );

  /// Patron para formato "Quiero [funcionalidad]".
  static final _iWantPattern = RegExp(
    r'\*\*Quiero\*\*\s+(.+)',
    caseSensitive: false,
  );

  /// Patron para formato "Para [beneficio]".
  static final _soThatPattern = RegExp(
    r'\*\*Para\*\*\s+(.+)',
    caseSensitive: false,
  );

  /// Patron para criterio de aceptacion.
  /// Formato: - [ ] AC-001: Given X When Y Then Z
  static final _criteriaPattern = RegExp(
    r'-\s*\[[\sx]?\]\s*(AC-\d+):\s*(.+)',
    caseSensitive: false,
  );

  /// Patron para Given/When/Then en una linea.
  static final _gherkinInlinePattern = RegExp(
    r'Given\s+(.+?)\s+When\s+(.+?)\s+Then\s+(.+)',
    caseSensitive: false,
  );

  /// Patron para requisitos relacionados (FR-XXX).
  static final _requirementPattern = RegExp(r'FR-\d+');

  /// Patron para test independiente.
  static final _testIndependentPattern = RegExp(
    r'####\s*Test\s+Independiente\s*\n(Si|No)\s*-?\s*(.*)',
    caseSensitive: false,
  );

  /// Parsea todas las User Stories de un documento Markdown.
  UserStoryCollection parse(String content) {
    final stories = <UserStory>[];
    final sections = _splitIntoStorySections(content);

    for (final section in sections) {
      final story = _parseStorySection(section);
      if (story != null) {
        stories.add(story);
      }
    }

    return UserStoryCollection(stories);
  }

  /// Parsea una sola User Story desde texto.
  UserStory? parseOne(String content) {
    return _parseStorySection(content);
  }

  /// Divide el contenido en secciones por User Story.
  List<String> _splitIntoStorySections(String content) {
    final sections = <String>[];
    final lines = content.split('\n');
    final buffer = StringBuffer();
    var inStory = false;

    for (final line in lines) {
      if (_storyHeaderPattern.hasMatch(line)) {
        if (inStory && buffer.isNotEmpty) {
          sections.add(buffer.toString());
          buffer.clear();
        }
        inStory = true;
      }

      if (inStory) {
        buffer.writeln(line);
      }
    }

    if (buffer.isNotEmpty) {
      sections.add(buffer.toString());
    }

    return sections;
  }

  /// Parsea una seccion individual de User Story.
  UserStory? _parseStorySection(String section) {
    // Extraer header
    final headerMatch = _storyHeaderPattern.firstMatch(section);
    if (headerMatch == null) return null;

    final id = headerMatch.group(1)!;
    final title = headerMatch.group(2)!.trim();
    final priorityStr = headerMatch.group(3)!;
    final priority = Priority.tryParse(priorityStr) ?? Priority.p2;

    // Extraer As A / I Want / So That
    final asAMatch = _asAPattern.firstMatch(section);
    final iWantMatch = _iWantPattern.firstMatch(section);
    final soThatMatch = _soThatPattern.firstMatch(section);

    final asA = asAMatch?.group(1)?.trim() ?? '';
    final iWant = iWantMatch?.group(1)?.trim() ?? '';
    final soThat = soThatMatch?.group(1)?.trim() ?? '';

    // Extraer criterios de aceptacion
    final criteria = _parseCriteria(section);

    // Extraer requisitos relacionados
    final requirements = _requirementPattern
        .allMatches(section)
        .map((m) => m.group(0)!)
        .toSet()
        .toList();

    // Extraer testabilidad independiente
    final testMatch = _testIndependentPattern.firstMatch(section);
    final testReason = testMatch?.group(2)?.trim();
    final testValue = testMatch?.group(1)?.toLowerCase();

    return UserStory(
      id: id,
      title: title,
      priority: priority,
      asA: asA,
      iWant: iWant,
      soThat: soThat,
      acceptanceCriteria: criteria,
      isIndependentlyTestable: testValue == 'si',
      testabilityReason: testReason?.isNotEmpty ?? false ? testReason : null,
      relatedRequirements: requirements,
    );
  }

  /// Parsea los criterios de aceptacion de una seccion.
  List<AcceptanceCriteria> _parseCriteria(String section) {
    final criteria = <AcceptanceCriteria>[];
    final matches = _criteriaPattern.allMatches(section);

    for (final match in matches) {
      final id = match.group(1)!;
      final content = match.group(2)!.trim();

      // Intentar parsear formato Gherkin inline
      final gherkinMatch = _gherkinInlinePattern.firstMatch(content);

      if (gherkinMatch != null) {
        criteria.add(AcceptanceCriteria(
          id: id,
          given: gherkinMatch.group(1)!.trim(),
          when: gherkinMatch.group(2)!.trim(),
          then: gherkinMatch.group(3)!.trim(),
        ));
      } else {
        // Si no es formato Gherkin, usar contenido como descripcion
        criteria.add(AcceptanceCriteria(
          id: id,
          given: content,
          when: '',
          then: '',
        ));
      }
    }

    return criteria;
  }

  /// Valida que una User Story tenga todos los campos requeridos.
  List<String> validate(UserStory story) {
    final errors = <String>[];

    if (story.id.isEmpty) {
      errors.add('ID es requerido');
    }
    if (story.title.isEmpty) {
      errors.add('Titulo es requerido');
    }
    if (story.asA.isEmpty) {
      errors.add('Campo "Como" es requerido');
    }
    if (story.iWant.isEmpty) {
      errors.add('Campo "Quiero" es requerido');
    }
    if (story.soThat.isEmpty) {
      errors.add('Campo "Para" es requerido');
    }
    if (story.acceptanceCriteria.isEmpty) {
      errors.add('Al menos un criterio de aceptacion es requerido');
    }

    for (final criteria in story.acceptanceCriteria) {
      if (criteria.given.isEmpty) {
        errors.add('Criterio ${criteria.id}: Given es requerido');
      }
      if (criteria.when.isEmpty) {
        errors.add('Criterio ${criteria.id}: When es requerido');
      }
      if (criteria.then.isEmpty) {
        errors.add('Criterio ${criteria.id}: Then es requerido');
      }
    }

    return errors;
  }

  /// Valida una coleccion completa de User Stories.
  Map<String, List<String>> validateCollection(UserStoryCollection collection) {
    final errors = <String, List<String>>{};

    // Validar cada story
    for (final story in collection.stories) {
      final storyErrors = validate(story);
      if (storyErrors.isNotEmpty) {
        errors[story.id] = storyErrors;
      }
    }

    // Validar que haya al menos una MVP (P1)
    if (collection.mvpStories.isEmpty) {
      errors['_collection'] = ['Al menos una User Story debe ser P1 (MVP)'];
    }

    // Validar IDs unicos
    final ids = collection.stories.map((s) => s.id).toList();
    final duplicates = ids.where((id) => ids.where((i) => i == id).length > 1).toSet();
    if (duplicates.isNotEmpty) {
      errors['_collection'] = [
        ...errors['_collection'] ?? [],
        'IDs duplicados: ${duplicates.join(', ')}',
      ];
    }

    return errors;
  }

  /// Genera Markdown desde una coleccion de User Stories.
  String toMarkdown(UserStoryCollection collection) {
    final buffer = StringBuffer()..writeln('## User Stories\n');

    // Agrupar por prioridad
    final byPriority = collection.byPriority;

    for (final priority in Priority.values) {
      final stories = byPriority[priority] ?? [];
      if (stories.isEmpty) continue;

      buffer.writeln('### ${priority.code} - ${priority.label}\n');

      for (final story in stories) {
        buffer
          ..writeln(story.toStoryFormat())
          ..writeln();
      }
    }

    return buffer.toString();
  }

  /// Genera resumen de User Stories.
  String generateSummary(UserStoryCollection collection) {
    final buffer = StringBuffer()
      ..writeln('## Resumen de User Stories\n')
      ..writeln('| ID | Titulo | Prioridad | Criterios | Completitud |')
      ..writeln('|----|--------|-----------|-----------|-------------|');

    for (final story in collection.stories) {
      final completion = (story.completionPercentage * 100).toStringAsFixed(0);
      buffer.writeln(
        '| ${story.id} | ${story.title} | ${story.priority.code} | '
        '${story.acceptanceCriteria.length} | $completion% |',
      );
    }

    buffer
      ..writeln()
      ..writeln('**MVP Stories**: ${collection.mvpStories.length}')
      ..writeln('**Total Criterios**: ${collection.totalCriteria}')
      ..writeln(
        '**Completitud Global**: '
        '${(collection.overallCompletion * 100).toStringAsFixed(0)}%',
      );

    return buffer.toString();
  }
}
