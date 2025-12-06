import 'package:dfspec/src/models/agent_config.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

/// Excepcion lanzada cuando falla el parseo de un agente.
class AgentParseException implements Exception {
  const AgentParseException(this.message);
  final String message;

  @override
  String toString() => 'AgentParseException: $message';
}

/// Representa un handoff a otro comando/agente.
///
/// Los handoffs permiten sugerir automaticamente el siguiente paso
/// despues de completar una tarea.
@immutable
class AgentHandoff {
  /// Crea un handoff con los campos requeridos.
  const AgentHandoff({
    required this.command,
    required this.label,
    this.description,
    this.auto = false,
  });

  /// Crea desde un mapa YAML.
  factory AgentHandoff.fromYaml(Map<dynamic, dynamic> yaml) {
    return AgentHandoff(
      command: yaml['command'] as String? ?? '',
      label: yaml['label'] as String? ?? '',
      description: yaml['description'] as String?,
      auto: yaml['auto'] as bool? ?? false,
    );
  }

  /// Comando slash destino (ej: /df-plan).
  final String command;

  /// Etiqueta para mostrar (ej: "Crear plan de implementacion").
  final String label;

  /// Descripcion opcional del handoff.
  final String? description;

  /// Si el handoff debe sugerirse automaticamente.
  final bool auto;

  /// Convierte a mapa.
  Map<String, dynamic> toJson() => {
        'command': command,
        'label': label,
        if (description != null) 'description': description,
        'auto': auto,
      };

  @override
  String toString() => 'AgentHandoff($command: $label)';
}

/// Definicion completa de un agente DFSpec.
///
/// Representa un agente parseado desde un archivo .md con YAML frontmatter.
@immutable
class AgentDefinition {
  const AgentDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.content,
    required this.slashCommand,
    this.model,
    this.tools = const [],
    this.handoffs = const [],
  });

  /// Identificador unico del agente (nombre del archivo sin extension).
  final String id;

  /// Nombre del agente desde el frontmatter.
  final String name;

  /// Descripcion del agente.
  final String description;

  /// Modelo recomendado (opus, sonnet, haiku).
  final String? model;

  /// Lista de herramientas permitidas.
  final List<String> tools;

  /// Lista de handoffs a otros comandos.
  final List<AgentHandoff> handoffs;

  /// Contenido completo del agente (sin frontmatter).
  final String content;

  /// Comando slash asociado (ej: df-plan).
  final String slashCommand;

  /// Verifica si tiene handoffs definidos.
  bool get hasHandoffs => handoffs.isNotEmpty;

  /// Obtiene handoffs automaticos.
  List<AgentHandoff> get autoHandoffs =>
      handoffs.where((h) => h.auto).toList();

  /// Convierte a mapa para serializacion.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      if (model != null) 'model': model,
      'tools': tools,
      if (handoffs.isNotEmpty) 'handoffs': handoffs.map((h) => h.toJson()).toList(),
      'slashCommand': slashCommand,
    };
  }

  /// Convierte a AgentConfig para compatibilidad con el sistema existente.
  AgentConfig toAgentConfig() {
    return AgentConfig(
      id: id,
      name: _formatName(name),
      description: description,
      category: _inferCategory(id),
      capabilities: _extractCapabilities(content),
      slashCommand: slashCommand,
      tools: tools,
    );
  }

  /// Formatea el nombre para mostrar (ej: dfplanner -> DF Planner).
  static String _formatName(String name) {
    if (name.startsWith('df')) {
      final rest = name.substring(2);
      final capitalized = rest[0].toUpperCase() + rest.substring(1);
      return 'DF $capitalized';
    }
    return name;
  }

  /// Infiere la categoria basandose en el ID del agente.
  static AgentCategory _inferCategory(String id) {
    const orchestrationAgents = ['dforchestrator', 'dfplanner', 'dfverifier'];
    const implementationAgents = ['dfimplementer', 'dftest'];
    const documentationAgents = ['dfdocumentation'];
    // quality es el default para el resto

    if (orchestrationAgents.contains(id)) return AgentCategory.orchestration;
    if (implementationAgents.contains(id)) return AgentCategory.implementation;
    if (documentationAgents.contains(id)) return AgentCategory.documentation;
    return AgentCategory.quality;
  }

  /// Extrae capacidades del contenido del agente.
  static List<String> _extractCapabilities(String content) {
    final capabilities = <String>[];

    // Buscar secciones de responsabilidades o capacidades
    final responsibilitiesMatch = RegExp(
      r'<responsibilities>([\s\S]*?)</responsibilities>',
    ).firstMatch(content);

    if (responsibilitiesMatch != null) {
      final text = responsibilitiesMatch.group(1)!;
      // Extraer items numerados o con guiones
      final items = RegExp(r'^\s*(?:\d+\.|[-*])\s*(.+)$', multiLine: true)
          .allMatches(text)
          .map((m) => m.group(1)!.trim())
          .where((s) => s.isNotEmpty)
          .take(5) // Limitar a 5 capacidades
          .toList();
      capabilities.addAll(items);
    }

    // Si no encontramos responsabilidades, buscar patrones generales
    if (capabilities.isEmpty) {
      final generalCapabilities = <String>[];

      if (content.contains('TDD') || content.contains('test')) {
        generalCapabilities.add('Testing');
      }
      if (content.contains('Clean Architecture')) {
        generalCapabilities.add('Clean Architecture');
      }
      if (content.contains('SOLID')) {
        generalCapabilities.add('SOLID principles');
      }
      if (content.contains('OWASP')) {
        generalCapabilities.add('Security analysis');
      }
      if (content.contains('performance') || content.contains('60fps')) {
        generalCapabilities.add('Performance optimization');
      }

      capabilities.addAll(generalCapabilities);
    }

    return capabilities.isEmpty ? ['Specialized agent'] : capabilities;
  }

  @override
  String toString() => 'AgentDefinition($id: $name)';
}

/// Parser de archivos de agentes con YAML frontmatter.
///
/// Parsea archivos .md con el formato:
/// ```yaml
/// ---
/// name: dfplanner
/// description: >
///   Arquitecto de soluciones...
/// model: opus
/// tools:
///   - Read
///   - Glob
/// ---
///
/// # Contenido del agente
/// ```
class AgentParser {
  /// Mapeo de nombres de agentes a comandos slash.
  static const Map<String, String> _agentToCommand = {
    'dfplanner': 'df-plan',
    'dfimplementer': 'df-implement',
    'dftest': 'df-test',
    'dfsolid': 'df-review',
    'dfsecurity': 'df-security',
    'dfperformance': 'df-performance',
    'dfdocumentation': 'df-docs',
    'dfcodequality': 'df-quality',
    'dfdependencies': 'df-deps',
    'dforchestrator': 'df-orchestrate',
    'dfverifier': 'df-verify',
    'dfspec': 'df-spec',
    'dfstatus': 'df-status',
  };

  /// Parsea el contenido de un archivo de agente.
  ///
  /// [markdown] es el contenido completo del archivo.
  /// [agentId] es el identificador del agente (nombre del archivo sin .md).
  AgentDefinition parse(String markdown, String agentId) {
    final (yamlContent, bodyContent) = extractFrontmatter(markdown);

    if (yamlContent == null) {
      throw const AgentParseException(
        'El archivo no contiene YAML frontmatter valido',
      );
    }

    final yaml = loadYaml(yamlContent) as YamlMap?;

    if (yaml == null) {
      throw const AgentParseException('YAML frontmatter vacio o invalido');
    }

    final name = yaml['name'] as String?;
    if (name == null || name.isEmpty) {
      throw const AgentParseException('El frontmatter debe contener "name"');
    }

    final description = _parseDescription(yaml['description']);
    if (description == null || description.isEmpty) {
      throw const AgentParseException(
        'El frontmatter debe contener "description"',
      );
    }

    final model = yaml['model'] as String?;
    final tools = _parseTools(yaml['tools']);
    final handoffs = _parseHandoffs(yaml['handoffs']);
    final slashCommand = mapAgentNameToSlashCommand(name);

    return AgentDefinition(
      id: agentId,
      name: name,
      description: description,
      model: model,
      tools: tools,
      handoffs: handoffs,
      content: bodyContent.trim(),
      slashCommand: slashCommand,
    );
  }

  /// Extrae el frontmatter YAML y el contenido del markdown.
  ///
  /// Retorna una tupla (yamlContent, bodyContent).
  /// Si no hay frontmatter, retorna (null, markdown).
  (String?, String) extractFrontmatter(String markdown) {
    final trimmed = markdown.trim();

    if (!trimmed.startsWith('---')) {
      return (null, markdown);
    }

    // Buscar el segundo '---' que cierra el frontmatter
    final endIndex = trimmed.indexOf('---', 3);
    if (endIndex == -1) {
      return (null, markdown);
    }

    final yamlContent = trimmed.substring(3, endIndex).trim();
    final bodyContent = trimmed.substring(endIndex + 3).trim();

    return (yamlContent, bodyContent);
  }

  /// Mapea el nombre de un agente a su comando slash.
  String mapAgentNameToSlashCommand(String agentName) {
    // Buscar en el mapeo predefinido
    if (_agentToCommand.containsKey(agentName)) {
      return _agentToCommand[agentName]!;
    }

    // Para agentes desconocidos, generar comando con prefijo df-
    if (agentName.startsWith('df')) {
      return 'df-${agentName.substring(2)}';
    }

    return 'df-$agentName';
  }

  /// Parsea la descripcion que puede ser String o multilinea YAML.
  String? _parseDescription(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  /// Parsea la lista de tools del YAML.
  List<String> _parseTools(dynamic value) {
    if (value == null) return [];
    if (value is YamlList) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Parsea la lista de handoffs del YAML.
  List<AgentHandoff> _parseHandoffs(dynamic value) {
    if (value == null) return [];
    if (value is YamlList) {
      return value
          .map((e) => AgentHandoff.fromYaml(e as Map<dynamic, dynamic>))
          .toList();
    }
    if (value is List) {
      return value
          .map((e) => AgentHandoff.fromYaml(e as Map<dynamic, dynamic>))
          .toList();
    }
    return [];
  }
}
