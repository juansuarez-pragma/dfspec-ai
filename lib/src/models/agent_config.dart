import 'package:meta/meta.dart';

/// Categoria de un agente DFSpec.
enum AgentCategory {
  /// Agentes de orquestacion y planificacion.
  orchestration('Orquestacion', 'Coordinacion y planificacion de tareas'),

  /// Agentes de calidad de codigo.
  quality('Calidad', 'Revision y mejora de codigo'),

  /// Agentes de implementacion.
  implementation('Implementacion', 'Desarrollo y testing'),

  /// Agentes de documentacion.
  documentation('Documentacion', 'Generacion de documentacion');

  const AgentCategory(this.displayName, this.description);

  /// Nombre para mostrar.
  final String displayName;

  /// Descripcion de la categoria.
  final String description;
}

/// Configuracion de un agente DFSpec.
///
/// Representa un agente especializado del ecosistema df*
/// con su configuracion y capacidades.
@immutable
class AgentConfig {
  /// Crea una nueva configuracion de agente.
  const AgentConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.capabilities,
    required this.slashCommand,
    this.dependsOn = const [],
    this.tools = const [],
  });

  /// Identificador unico del agente (ej: dforchestrator).
  final String id;

  /// Nombre descriptivo del agente.
  final String name;

  /// Descripcion de lo que hace el agente.
  final String description;

  /// Categoria del agente.
  final AgentCategory category;

  /// Lista de capacidades del agente.
  final List<String> capabilities;

  /// Comando slash asociado.
  final String slashCommand;

  /// Agentes de los que depende.
  final List<String> dependsOn;

  /// Herramientas que puede usar.
  final List<String> tools;

  /// Verifica si el agente tiene una capacidad especifica.
  bool hasCapability(String capability) {
    return capabilities.any(
      (c) => c.toLowerCase().contains(capability.toLowerCase()),
    );
  }

  /// Convierte a mapa para serializacion.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'capabilities': capabilities,
      'slashCommand': slashCommand,
      'dependsOn': dependsOn,
      'tools': tools,
    };
  }

  @override
  String toString() => 'AgentConfig($id)';
}
