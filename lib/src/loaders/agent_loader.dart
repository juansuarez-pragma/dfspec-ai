import 'dart:io';

import 'package:dfspec/src/parsers/agent_parser.dart';
import 'package:path/path.dart' as p;

/// Cargador de agentes desde el sistema de archivos.
///
/// Lee y parsea archivos de agentes desde el directorio `agents/`.
class AgentLoader {
  /// Crea un nuevo loader con la ruta especificada.
  ///
  /// Si no se especifica [agentsPath], usa el directorio `agents/`
  /// relativo al directorio actual.
  AgentLoader({String? agentsPath})
    : _agentsPath = agentsPath ?? p.join(Directory.current.path, 'agents'),
      _parser = AgentParser();

  final String _agentsPath;
  final AgentParser _parser;

  /// Ruta al directorio de agentes.
  String get agentsPath => _agentsPath;

  /// Lista los nombres de agentes disponibles.
  List<String> listAvailable() {
    final dir = Directory(_agentsPath);

    if (!dir.existsSync()) {
      return [];
    }

    return dir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.md'))
        .map((file) => p.basenameWithoutExtension(file.path))
        .toList();
  }

  /// Carga un agente por su nombre.
  ///
  /// [agentName] puede ser con o sin extension .md.
  /// Retorna null si el agente no existe.
  AgentDefinition? load(String agentName) {
    final normalizedName = agentName.endsWith('.md')
        ? agentName.substring(0, agentName.length - 3)
        : agentName;

    final filePath = getAgentPath(normalizedName);
    final file = File(filePath);

    if (!file.existsSync()) {
      return null;
    }

    try {
      final content = file.readAsStringSync();
      return _parser.parse(content, normalizedName);
    } catch (e) {
      // Log error pero retornar null para no interrumpir el flujo
      return null;
    }
  }

  /// Carga todos los agentes disponibles.
  List<AgentDefinition> loadAll() {
    final agentNames = listAvailable();
    final agents = <AgentDefinition>[];

    for (final name in agentNames) {
      final agent = load(name);
      if (agent != null) {
        agents.add(agent);
      }
    }

    return agents;
  }

  /// Verifica si un agente existe.
  bool exists(String agentName) {
    final normalizedName = agentName.endsWith('.md')
        ? agentName.substring(0, agentName.length - 3)
        : agentName;

    final file = File(getAgentPath(normalizedName));
    return file.existsSync();
  }

  /// Obtiene la ruta completa a un archivo de agente.
  String getAgentPath(String agentName) {
    final normalizedName = agentName.endsWith('.md')
        ? agentName.substring(0, agentName.length - 3)
        : agentName;

    return p.join(_agentsPath, '$normalizedName.md');
  }
}
