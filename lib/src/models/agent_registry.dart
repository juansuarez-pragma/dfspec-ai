import 'package:dfspec/src/loaders/agent_loader.dart';
import 'package:dfspec/src/models/agent_config.dart';
import 'package:dfspec/src/parsers/agent_parser.dart';

/// Registro dinamico de agentes DFSpec.
///
/// Carga agentes desde archivos .md en el directorio `agents/`.
/// Proporciona acceso sincrono a los agentes.
class AgentRegistry {
  /// Crea un registro con el loader especificado.
  AgentRegistry({AgentLoader? loader}) : _loader = loader ?? AgentLoader();

  final AgentLoader _loader;

  /// Cache de agentes cargados.
  Map<String, AgentDefinition>? _cache;

  /// Indica si el registro ha sido inicializado.
  bool get isInitialized => _cache != null;

  /// Inicializa el registro cargando todos los agentes.
  ///
  /// Debe llamarse antes de usar metodos que requieren cache.
  void initialize() {
    if (_cache != null) return;

    final agents = _loader.loadAll();
    _cache = {for (final agent in agents) agent.id: agent};
  }

  /// Obtiene un agente por su ID.
  ///
  /// Requiere que [initialize] haya sido llamado primero.
  AgentConfig? getAgent(String id) {
    _ensureInitialized();
    final definition = _cache![id];
    return definition?.toAgentConfig();
  }

  /// Obtiene la definicion completa de un agente.
  AgentDefinition? getDefinition(String id) {
    _ensureInitialized();
    return _cache![id];
  }

  /// Lista todos los agentes disponibles como AgentConfig.
  List<AgentConfig> get all {
    _ensureInitialized();
    return _cache!.values.map((d) => d.toAgentConfig()).toList();
  }

  /// Lista todas las definiciones de agentes.
  List<AgentDefinition> get allDefinitions {
    _ensureInitialized();
    return _cache!.values.toList();
  }

  /// Lista IDs de todos los agentes.
  List<String> get allIds {
    _ensureInitialized();
    return _cache!.keys.toList();
  }

  /// Verifica si un agente existe.
  bool exists(String id) {
    _ensureInitialized();
    return _cache!.containsKey(id);
  }

  /// Lista agentes por categoria.
  List<AgentConfig> byCategory(AgentCategory category) {
    return all.where((a) => a.category == category).toList();
  }

  /// Obtiene agentes que tienen una capacidad especifica.
  List<AgentConfig> withCapability(String capability) {
    return all.where((a) => a.hasCapability(capability)).toList();
  }

  /// Carga un agente directamente (no requiere initialize).
  AgentConfig? loadAgent(String id) {
    final definition = _loader.load(id);
    return definition?.toAgentConfig();
  }

  /// Carga la definicion completa de un agente.
  AgentDefinition? loadDefinition(String id) {
    return _loader.load(id);
  }

  /// Carga todos los agentes.
  List<AgentConfig> loadAll() {
    final definitions = _loader.loadAll();
    return definitions.map((d) => d.toAgentConfig()).toList();
  }

  /// Invalida el cache para recargar agentes.
  void invalidateCache() {
    _cache = null;
  }

  void _ensureInitialized() {
    if (_cache == null) {
      throw StateError(
        'AgentRegistry no inicializado. Llama initialize() primero.',
      );
    }
  }
}

/// Instancia global del registro para uso estatico.
///
/// Debe inicializarse con [initializeGlobalRegistry] antes de usar.
AgentRegistry? _globalRegistry;

/// Inicializa el registro global.
void initializeGlobalRegistry({String? agentsPath}) {
  _globalRegistry = AgentRegistry(
    loader: agentsPath != null ? AgentLoader(agentsPath: agentsPath) : null,
  );
  _globalRegistry!.initialize();
}

/// Obtiene el registro global.
///
/// Lanza error si no ha sido inicializado.
AgentRegistry get globalRegistry {
  if (_globalRegistry == null) {
    throw StateError(
      'Registro global no inicializado. Llama initializeGlobalRegistry() primero.',
    );
  }
  return _globalRegistry!;
}

/// Verifica si el registro global esta inicializado.
bool get isGlobalRegistryInitialized => _globalRegistry?.isInitialized ?? false;
