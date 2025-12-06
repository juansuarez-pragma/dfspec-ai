import 'package:args/command_runner.dart';
import 'package:dfspec/src/loaders/agent_loader.dart';
import 'package:dfspec/src/models/models.dart';
import 'package:dfspec/src/utils/utils.dart';

/// Comando para listar y gestionar agentes DFSpec.
///
/// Muestra informacion sobre los agentes especializados
/// disponibles en el ecosistema df*.
///
/// Uso:
/// ```bash
/// dfspec agents              # Lista todos los agentes
/// dfspec agents --info=dftest  # Info detallada de un agente
/// dfspec agents --category=quality  # Filtra por categoria
/// ```
class AgentsCommand extends Command<int> {
  /// Crea una nueva instancia del comando agents.
  AgentsCommand({AgentLoader? agentLoader})
      : _agentLoader = agentLoader ?? AgentLoader() {
    argParser
      ..addOption(
        'info',
        abbr: 'i',
        help: 'Muestra informacion detallada de un agente.',
      )
      ..addOption(
        'category',
        abbr: 'c',
        help: 'Filtra agentes por categoria.',
        allowed: AgentCategory.values.map((c) => c.name).toList(),
      )
      ..addOption(
        'capability',
        help: 'Busca agentes con una capacidad especifica.',
      )
      ..addFlag(
        'json',
        help: 'Salida en formato JSON.',
        negatable: false,
      );
  }

  final AgentLoader _agentLoader;
  late AgentRegistry _registry;

  @override
  String get name => 'agents';

  @override
  String get description =>
      'Lista y muestra informacion de los agentes DFSpec.';

  @override
  String get invocation => 'dfspec agents [--info=agente]';

  final Logger _logger = const Logger();

  @override
  Future<int> run() async {
    // Inicializar el registry
    _registry = AgentRegistry(loader: _agentLoader)..initialize();

    final infoAgent = argResults!['info'] as String?;
    final categoryFilter = argResults!['category'] as String?;
    final capabilityFilter = argResults!['capability'] as String?;
    final jsonOutput = argResults!['json'] as bool;

    // Modo info detallada
    if (infoAgent != null) {
      return _showAgentInfo(infoAgent, jsonOutput: jsonOutput);
    }

    // Obtener agentes filtrados
    var agents = _registry.all;

    if (categoryFilter != null) {
      final category = AgentCategory.values.firstWhere(
        (c) => c.name == categoryFilter,
      );
      agents = _registry.byCategory(category);
    }

    if (capabilityFilter != null) {
      agents = agents
          .where((a) => a.hasCapability(capabilityFilter))
          .toList();
    }

    if (jsonOutput) {
      return _outputJson(agents);
    }

    return _showAgentsList(agents);
  }

  int _showAgentInfo(String agentId, {required bool jsonOutput}) {
    final agent = _registry.getAgent(agentId);

    if (agent == null) {
      _logger..error('Agente no encontrado: $agentId')
      ..info('Usa "dfspec agents" para ver agentes disponibles.');
      return 1;
    }

    if (jsonOutput) {
      _logger.write(_formatJson(agent.toJson()));
      return 0;
    }

    _logger..title(agent.name)
    ..write('ID: ${agent.id}')
    ..write('Categoria: ${agent.category.displayName}')
    ..write('Comando: /${agent.slashCommand}')
    ..blank()
    ..write(agent.description)
    ..blank()

    ..write('Capacidades:');
    for (final cap in agent.capabilities) {
      _logger.item(cap);
    }

    if (agent.dependsOn.isNotEmpty) {
      _logger..blank()
      ..write('Depende de:');
      for (final dep in agent.dependsOn) {
        _logger.item(dep);
      }
    }

    if (agent.tools.isNotEmpty) {
      _logger..blank()
      ..write('Herramientas:')
      ..write('  ${agent.tools.join(', ')}');
    }

    return 0;
  }

  int _showAgentsList(List<AgentConfig> agents) {
    _logger..title('Agentes DFSpec Disponibles')
    ..write('${agents.length} agentes especializados\n');

    // Agrupar por categoria
    for (final category in AgentCategory.values) {
      final categoryAgents = agents
          .where((a) => a.category == category)
          .toList();

      if (categoryAgents.isEmpty) continue;

      _logger.write('\n${category.displayName}:');

      for (final agent in categoryAgents) {
        _logger..write('  ${agent.id.padRight(18)} /${agent.slashCommand}')
        ..write('    ${_truncate(agent.description, 60)}');
      }
    }

    _logger..blank()
    ..info('Usa --info=<agente> para ver detalles.');

    return 0;
  }

  int _outputJson(List<AgentConfig> agents) {
    final data = agents.map((a) => a.toJson()).toList();
    _logger.write(_formatJson(data));
    return 0;
  }

  String _formatJson(dynamic data) {
    // Simple JSON formatting
    final buffer = StringBuffer();
    _writeJson(buffer, data, 0);
    return buffer.toString();
  }

  void _writeJson(StringBuffer buffer, dynamic data, int indent) {
    final pad = '  ' * indent;

    if (data is Map) {
      buffer.writeln('{');
      final entries = data.entries.toList();
      for (var i = 0; i < entries.length; i++) {
        buffer.write('$pad  "${entries[i].key}": ');
        _writeJson(buffer, entries[i].value, indent + 1);
        if (i < entries.length - 1) buffer.write(',');
        buffer.writeln();
      }
      buffer.write('$pad}');
    } else if (data is List) {
      if (data.isEmpty) {
        buffer.write('[]');
      } else if (data.first is String) {
        buffer.write('[${data.map((e) => '"$e"').join(', ')}]');
      } else {
        buffer.writeln('[');
        for (var i = 0; i < data.length; i++) {
          buffer.write('$pad  ');
          _writeJson(buffer, data[i], indent + 1);
          if (i < data.length - 1) buffer.write(',');
          buffer.writeln();
        }
        buffer.write('$pad]');
      }
    } else if (data is String) {
      buffer.write('"$data"');
    } else {
      buffer.write(data);
    }
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
}
