import 'package:meta/meta.dart';

/// Tipo de documentación a generar.
enum DocumentationType {
  /// Documentación de API (dartdoc).
  api('API'),

  /// README de proyecto/feature.
  readme('README'),

  /// Changelog de versiones.
  changelog('Changelog'),

  /// Guía de contribución.
  contributing('Contributing'),

  /// Documentación de arquitectura.
  architecture('Arquitectura'),

  /// Documentación de especificación.
  specification('Especificación'),

  /// Documentación de plan de implementación.
  implementationPlan('Plan');

  const DocumentationType(this.label);
  final String label;
}

/// Sección de un documento.
@immutable
class DocumentSection {
  /// Crea una sección.
  const DocumentSection({
    required this.title,
    required this.content,
    this.level = 2,
    this.subsections = const [],
  });

  /// Título de la sección.
  final String title;

  /// Contenido markdown.
  final String content;

  /// Nivel de heading (1-6).
  final int level;

  /// Subsecciones.
  final List<DocumentSection> subsections;

  /// Genera markdown de la sección.
  String toMarkdown() {
    final buffer = StringBuffer();
    final heading = '#' * level;

    buffer.writeln('$heading $title');
    buffer.writeln();

    if (content.isNotEmpty) {
      buffer.writeln(content);
      buffer.writeln();
    }

    for (final sub in subsections) {
      buffer.writeln(sub.toMarkdown());
    }

    return buffer.toString();
  }

  /// Crea desde JSON.
  factory DocumentSection.fromJson(Map<String, dynamic> json) {
    return DocumentSection(
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      level: json['level'] as int? ?? 2,
      subsections: (json['subsections'] as List<dynamic>?)
              ?.map((s) => DocumentSection.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Convierte a JSON.
  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'level': level,
        if (subsections.isNotEmpty)
          'subsections': subsections.map((s) => s.toJson()).toList(),
      };
}

/// Especificación de documentación a generar.
@immutable
class DocumentationSpec {
  /// Crea una especificación.
  const DocumentationSpec({
    required this.type,
    required this.title,
    this.description,
    this.sections = const [],
    this.metadata = const {},
    this.outputPath,
  });

  /// Tipo de documentación.
  final DocumentationType type;

  /// Título del documento.
  final String title;

  /// Descripción breve.
  final String? description;

  /// Secciones del documento.
  final List<DocumentSection> sections;

  /// Metadata adicional (autor, fecha, versión, etc).
  final Map<String, dynamic> metadata;

  /// Ruta de salida sugerida.
  final String? outputPath;

  /// Genera el documento completo en markdown.
  String generate() {
    final buffer = StringBuffer();

    // Título principal
    buffer.writeln('# $title');
    buffer.writeln();

    // Descripción
    if (description != null && description!.isNotEmpty) {
      buffer.writeln(description);
      buffer.writeln();
    }

    // Metadata como badges o info
    if (metadata.isNotEmpty) {
      if (metadata.containsKey('version')) {
        buffer.writeln('**Versión:** ${metadata['version']}');
      }
      if (metadata.containsKey('author')) {
        buffer.writeln('**Autor:** ${metadata['author']}');
      }
      if (metadata.containsKey('date')) {
        buffer.writeln('**Fecha:** ${metadata['date']}');
      }
      buffer.writeln();
    }

    // Secciones
    for (final section in sections) {
      buffer.writeln(section.toMarkdown());
    }

    return buffer.toString();
  }

  /// Crea desde JSON.
  factory DocumentationSpec.fromJson(Map<String, dynamic> json) {
    return DocumentationSpec(
      type: DocumentationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => DocumentationType.readme,
      ),
      title: json['title'] as String,
      description: json['description'] as String?,
      sections: (json['sections'] as List<dynamic>?)
              ?.map((s) => DocumentSection.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ?? const {},
      outputPath: json['outputPath'] as String?,
    );
  }

  /// Convierte a JSON.
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'title': title,
        if (description != null) 'description': description,
        if (sections.isNotEmpty)
          'sections': sections.map((s) => s.toJson()).toList(),
        if (metadata.isNotEmpty) 'metadata': metadata,
        if (outputPath != null) 'outputPath': outputPath,
      };
}

/// Resultado de generación de documentación.
@immutable
class DocumentationResult {
  /// Crea un resultado.
  const DocumentationResult({
    required this.spec,
    required this.content,
    required this.outputPath,
    this.warnings = const [],
  });

  /// Especificación usada.
  final DocumentationSpec spec;

  /// Contenido generado.
  final String content;

  /// Ruta donde se guardó.
  final String outputPath;

  /// Advertencias durante generación.
  final List<String> warnings;

  /// Si tuvo advertencias.
  bool get hasWarnings => warnings.isNotEmpty;

  /// Líneas del documento.
  int get lineCount => content.split('\n').length;

  /// Palabras del documento.
  int get wordCount =>
      content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
}

/// Templates de documentación predefinidos.
class DocumentationTemplates {
  DocumentationTemplates._();

  /// Template para README de feature.
  static DocumentationSpec featureReadme({
    required String featureName,
    required String description,
    List<String> useCases = const [],
    List<String> components = const [],
  }) {
    return DocumentationSpec(
      type: DocumentationType.readme,
      title: 'Feature: $featureName',
      description: description,
      sections: [
        DocumentSection(
          title: 'Descripción',
          content: description,
        ),
        if (useCases.isNotEmpty)
          DocumentSection(
            title: 'Casos de Uso',
            content: useCases.map((uc) => '- $uc').join('\n'),
          ),
        if (components.isNotEmpty)
          DocumentSection(
            title: 'Componentes',
            content: components.map((c) => '- `$c`').join('\n'),
          ),
        const DocumentSection(
          title: 'Instalación',
          content: 'Ver documentación principal del proyecto.',
        ),
        const DocumentSection(
          title: 'Uso',
          content: '```dart\n// TODO: Agregar ejemplo de uso\n```',
        ),
      ],
      outputPath: 'docs/features/$featureName/README.md',
    );
  }

  /// Template para documentación de arquitectura.
  static DocumentationSpec architecture({
    required String projectName,
    String? description,
    Map<String, String> layers = const {},
  }) {
    final layerSections = layers.entries.map((e) {
      return DocumentSection(
        title: e.key,
        content: e.value,
        level: 3,
      );
    }).toList();

    return DocumentationSpec(
      type: DocumentationType.architecture,
      title: 'Arquitectura: $projectName',
      description: description ?? 'Documentación de arquitectura del proyecto.',
      sections: [
        const DocumentSection(
          title: 'Visión General',
          content: '''
Este proyecto sigue Clean Architecture con las siguientes capas:

```
lib/src/
├── domain/          # Entidades, interfaces, usecases
├── data/            # Models, datasources, repositories impl
├── presentation/    # Pages, widgets, providers
└── core/            # Constants, theme, network, utils
```
''',
        ),
        if (layerSections.isNotEmpty)
          DocumentSection(
            title: 'Capas',
            content: '',
            subsections: layerSections,
          ),
        const DocumentSection(
          title: 'Dependencias',
          content: '''
**Regla de dependencias:**
- Domain NO importa Data ni Presentation
- Data importa Domain
- Presentation importa Domain
- Core puede ser importado por cualquier capa
''',
        ),
      ],
      outputPath: 'docs/ARCHITECTURE.md',
    );
  }

  /// Template para changelog.
  static DocumentationSpec changelog({
    required String version,
    required DateTime date,
    List<String> added = const [],
    List<String> changed = const [],
    List<String> fixed = const [],
    List<String> removed = const [],
  }) {
    final sections = <DocumentSection>[];

    if (added.isNotEmpty) {
      sections.add(DocumentSection(
        title: 'Added',
        content: added.map((a) => '- $a').join('\n'),
        level: 3,
      ));
    }
    if (changed.isNotEmpty) {
      sections.add(DocumentSection(
        title: 'Changed',
        content: changed.map((c) => '- $c').join('\n'),
        level: 3,
      ));
    }
    if (fixed.isNotEmpty) {
      sections.add(DocumentSection(
        title: 'Fixed',
        content: fixed.map((f) => '- $f').join('\n'),
        level: 3,
      ));
    }
    if (removed.isNotEmpty) {
      sections.add(DocumentSection(
        title: 'Removed',
        content: removed.map((r) => '- $r').join('\n'),
        level: 3,
      ));
    }

    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return DocumentationSpec(
      type: DocumentationType.changelog,
      title: 'Changelog',
      sections: [
        DocumentSection(
          title: '[$version] - $dateStr',
          content: '',
          subsections: sections,
        ),
      ],
      outputPath: 'CHANGELOG.md',
    );
  }

  /// Template para especificación de feature.
  static DocumentationSpec featureSpec({
    required String featureName,
    required String description,
    required List<String> acceptanceCriteria,
    List<String> outOfScope = const [],
    Map<String, dynamic> metadata = const {},
  }) {
    return DocumentationSpec(
      type: DocumentationType.specification,
      title: 'Especificación: $featureName',
      description: description,
      metadata: {
        'status': 'draft',
        'date': DateTime.now().toIso8601String().split('T').first,
        ...metadata,
      },
      sections: [
        DocumentSection(
          title: 'Descripción',
          content: description,
        ),
        DocumentSection(
          title: 'Criterios de Aceptación',
          content: acceptanceCriteria
              .asMap()
              .entries
              .map((e) => '${e.key + 1}. ${e.value}')
              .join('\n'),
        ),
        if (outOfScope.isNotEmpty)
          DocumentSection(
            title: 'Fuera de Alcance',
            content: outOfScope.map((o) => '- $o').join('\n'),
          ),
        const DocumentSection(
          title: 'Notas Técnicas',
          content: '_Por definir durante la implementación._',
        ),
      ],
      outputPath: 'docs/specs/features/$featureName.spec.md',
    );
  }

  /// Template para plan de implementación.
  static DocumentationSpec implementationPlan({
    required String featureName,
    required List<ImplementationStep> steps,
    Map<String, dynamic> metadata = const {},
  }) {
    final stepSections = steps.asMap().entries.map((e) {
      final step = e.value;
      return DocumentSection(
        title: 'Paso ${e.key + 1}: ${step.name}',
        content: '''
**Descripción:** ${step.description}

**Archivos:**
${step.files.map((f) => '- `$f`').join('\n')}

**Tests:**
${step.tests.map((t) => '- `$t`').join('\n')}

**Dependencias:** ${step.dependencies.isEmpty ? 'Ninguna' : step.dependencies.join(', ')}
''',
        level: 3,
      );
    }).toList();

    return DocumentationSpec(
      type: DocumentationType.implementationPlan,
      title: 'Plan de Implementación: $featureName',
      metadata: {
        'status': 'pending',
        'date': DateTime.now().toIso8601String().split('T').first,
        ...metadata,
      },
      sections: [
        const DocumentSection(
          title: 'Resumen',
          content: 'Este plan sigue el ciclo TDD: RED → GREEN → REFACTOR',
        ),
        DocumentSection(
          title: 'Pasos de Implementación',
          content: '',
          subsections: stepSections,
        ),
        const DocumentSection(
          title: 'Verificación',
          content: '''
Al completar cada paso:
1. Ejecutar tests: `dart test`
2. Analizar código: `dart analyze`
3. Formatear: `dart format .`
''',
        ),
      ],
      outputPath: 'docs/specs/plans/$featureName.plan.md',
    );
  }
}

/// Paso de implementación para un plan.
@immutable
class ImplementationStep {
  /// Crea un paso.
  const ImplementationStep({
    required this.name,
    required this.description,
    this.files = const [],
    this.tests = const [],
    this.dependencies = const [],
  });

  /// Nombre del paso.
  final String name;

  /// Descripción.
  final String description;

  /// Archivos a crear/modificar.
  final List<String> files;

  /// Tests a crear.
  final List<String> tests;

  /// Dependencias de otros pasos.
  final List<String> dependencies;
}

/// API documentation para una clase/función.
@immutable
class ApiDocumentation {
  /// Crea documentación de API.
  const ApiDocumentation({
    required this.name,
    required this.type,
    required this.description,
    this.parameters = const [],
    this.returns,
    this.throws = const [],
    this.examples = const [],
    this.seeAlso = const [],
  });

  /// Nombre del elemento.
  final String name;

  /// Tipo (class, method, property, etc).
  final String type;

  /// Descripción.
  final String description;

  /// Parámetros (para métodos/funciones).
  final List<ApiParameter> parameters;

  /// Tipo de retorno.
  final String? returns;

  /// Excepciones que puede lanzar.
  final List<String> throws;

  /// Ejemplos de uso.
  final List<String> examples;

  /// Referencias a otros elementos.
  final List<String> seeAlso;

  /// Genera dartdoc.
  String toDartDoc() {
    final buffer = StringBuffer();

    buffer.writeln('/// $description');

    if (parameters.isNotEmpty) {
      buffer.writeln('///');
      for (final param in parameters) {
        buffer.writeln('/// [${param.name}] ${param.description}');
      }
    }

    if (returns != null) {
      buffer.writeln('///');
      buffer.writeln('/// Returns $returns');
    }

    if (throws.isNotEmpty) {
      buffer.writeln('///');
      for (final t in throws) {
        buffer.writeln('/// Throws $t');
      }
    }

    if (examples.isNotEmpty) {
      buffer.writeln('///');
      buffer.writeln('/// Example:');
      buffer.writeln('/// ```dart');
      for (final example in examples) {
        buffer.writeln('/// $example');
      }
      buffer.writeln('/// ```');
    }

    if (seeAlso.isNotEmpty) {
      buffer.writeln('///');
      buffer.writeln('/// See also:');
      for (final ref in seeAlso) {
        buffer.writeln('/// - [$ref]');
      }
    }

    return buffer.toString();
  }
}

/// Parámetro de API.
@immutable
class ApiParameter {
  /// Crea un parámetro.
  const ApiParameter({
    required this.name,
    required this.type,
    required this.description,
    this.isRequired = true,
    this.defaultValue,
  });

  /// Nombre del parámetro.
  final String name;

  /// Tipo del parámetro.
  final String type;

  /// Descripción.
  final String description;

  /// Si es requerido.
  final bool isRequired;

  /// Valor por defecto.
  final String? defaultValue;
}
