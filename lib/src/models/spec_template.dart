import 'package:meta/meta.dart';

/// Tipos de especificacion disponibles.
enum SpecType {
  /// Especificacion de feature/funcionalidad.
  feature('feature', 'Especificacion de funcionalidad'),

  /// Especificacion de arquitectura.
  architecture('architecture', 'Decision de arquitectura (ADR)'),

  /// Especificacion de seguridad.
  security('security', 'Requisitos de seguridad'),

  /// Especificacion de rendimiento.
  performance('performance', 'Requisitos de rendimiento'),

  /// Especificacion de API.
  api('api', 'Contrato de API'),

  /// Plan de implementacion.
  plan('plan', 'Plan de implementacion');

  const SpecType(this.value, this.description);

  /// Valor string del tipo.
  final String value;

  /// Descripcion del tipo.
  final String description;

  /// Obtiene el tipo desde un string.
  static SpecType? fromString(String value) {
    for (final type in SpecType.values) {
      if (type.value == value) {
        return type;
      }
    }
    return null;
  }
}

/// Template de especificacion.
///
/// Representa un template que puede ser usado para generar
/// diferentes tipos de documentos de especificacion.
@immutable
class SpecTemplate {
  /// Crea un nuevo template.
  const SpecTemplate({
    required this.type,
    required this.name,
    required this.content,
    this.variables = const {},
  });

  /// Tipo de especificacion.
  final SpecType type;

  /// Nombre del template.
  final String name;

  /// Contenido del template con placeholders.
  final String content;

  /// Variables disponibles en el template.
  final Map<String, String> variables;

  /// Genera el contenido reemplazando variables.
  String render(Map<String, String> values) {
    var result = content;

    // Reemplazar variables del template
    for (final entry in variables.entries) {
      final placeholder = '{{${entry.key}}}';
      final value = values[entry.key] ?? entry.value;
      result = result.replaceAll(placeholder, value);
    }

    // Reemplazar variables proporcionadas
    for (final entry in values.entries) {
      final placeholder = '{{${entry.key}}}';
      result = result.replaceAll(placeholder, entry.value);
    }

    return result;
  }

  /// Obtiene el nombre de archivo sugerido.
  String suggestedFilename(String name) {
    final sanitized = name
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    return '$sanitized.${type.value}.md';
  }

  /// Obtiene el directorio sugerido.
  String suggestedDirectory() {
    switch (type) {
      case SpecType.feature:
        return 'specs/features';
      case SpecType.architecture:
        return 'docs/decisions';
      case SpecType.security:
        return 'specs/security';
      case SpecType.performance:
        return 'specs/performance';
      case SpecType.api:
        return 'specs/api';
      case SpecType.plan:
        return 'specs/plans';
    }
  }
}
