import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dfspec/src/generators/command_generator.dart';
import 'package:dfspec/src/loaders/agent_loader.dart';
import 'package:dfspec/src/models/models.dart';
import 'package:dfspec/src/parsers/agent_parser.dart';
import 'package:dfspec/src/utils/utils.dart';
import 'package:path/path.dart' as p;

/// Comando para instalar comandos slash en multiples plataformas de IA.
///
/// Genera comandos directamente desde los archivos de agentes en `agents/`.
///
/// Uso:
/// ```bash
/// dfspec install [--all] [--command=nombre] [--agent=claude]
/// dfspec install --agent claude --agent gemini
/// dfspec install --all-agents
/// dfspec install --detect
/// ```
class InstallCommand extends Command<int> {
  /// Crea una nueva instancia del comando install.
  InstallCommand({AgentLoader? agentLoader})
      : _agentLoader = agentLoader ?? AgentLoader() {
    argParser
      // Opciones de comandos
      ..addFlag(
        'all',
        abbr: 'a',
        help: 'Instala todos los comandos disponibles.',
        negatable: false,
      )
      ..addMultiOption(
        'command',
        abbr: 'c',
        help: 'Comando especifico a instalar.',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Sobrescribe comandos existentes.',
        negatable: false,
      )
      ..addFlag(
        'list',
        abbr: 'l',
        help: 'Lista los comandos disponibles sin instalar.',
        negatable: false,
      )
      // Opciones multi-agente
      ..addMultiOption(
        'agent',
        help: 'Plataforma(s) de IA destino. '
            'Opciones: ${AiPlatformRegistry.allIds.join(", ")}',
        allowed: AiPlatformRegistry.allIds,
      )
      ..addFlag(
        'all-agents',
        help: 'Instala para todas las plataformas soportadas.',
        negatable: false,
      )
      ..addFlag(
        'detect',
        abbr: 'd',
        help: 'Auto-detecta plataformas instaladas en el sistema.',
        negatable: false,
      )
      ..addFlag(
        'list-agents',
        help: 'Lista las plataformas de IA soportadas.',
        negatable: false,
      );
  }

  final AgentLoader _agentLoader;

  @override
  String get name => 'install';

  @override
  String get description =>
      'Instala comandos slash de DFSpec para plataformas de IA.';

  @override
  String get invocation =>
      'dfspec install [--all] [--command=nombre] [--agent=claude]';

  final Logger _logger = const Logger();

  /// Comandos esenciales por defecto.
  static const List<String> _essentialCommands = [
    'df-spec',
    'df-plan',
    'df-implement',
    'df-test',
    'df-verify',
    'df-status',
  ];

  @override
  Future<int> run() async {
    final all = argResults!['all'] as bool;
    final commands = argResults!['command'] as List<String>;
    final force = argResults!['force'] as bool;
    final listOnly = argResults!['list'] as bool;
    final agents = argResults!['agent'] as List<String>;
    final allAgents = argResults!['all-agents'] as bool;
    final detect = argResults!['detect'] as bool;
    final listAgents = argResults!['list-agents'] as bool;

    // Modo lista de agentes/plataformas
    if (listAgents) {
      _listPlatforms();
      return 0;
    }

    // Cargar agentes desde archivos
    final agentDefinitions = _agentLoader.loadAll();
    if (agentDefinitions.isEmpty) {
      _logger.error(
        'No se encontraron agentes en ${_agentLoader.agentsPath}',
      );
      return 1;
    }

    // Crear mapa de comando -> agente
    final commandToAgent = <String, AgentDefinition>{};
    for (final agent in agentDefinitions) {
      commandToAgent[agent.slashCommand] = agent;
    }

    final availableCommands = commandToAgent.keys.toList()..sort();

    // Modo lista de comandos
    if (listOnly) {
      _logger.title('Comandos slash disponibles');
      for (final cmd in availableCommands) {
        final agent = commandToAgent[cmd]!;
        _logger.item('$cmd - ${_truncate(agent.description, 60)}');
      }
      return 0;
    }

    // Validar configuracion
    final config = await DfspecConfig.load(Directory.current.path);
    if (config == null) {
      _logger.error(
        'No se encontro dfspec.yaml. Ejecuta "dfspec init" primero.',
      );
      return 1;
    }

    // Determinar plataformas destino
    final targetPlatforms = await _resolveTargetPlatforms(
      agents: agents,
      allAgents: allAgents,
      detect: detect,
    );

    if (targetPlatforms.isEmpty) {
      _logger
        ..error('No se encontraron plataformas de IA.')
        ..info('Usa --agent para especificar una plataforma.');
      return 1;
    }

    // Determinar comandos a instalar
    List<String> toInstall;
    if (all) {
      toInstall = availableCommands;
    } else if (commands.isNotEmpty) {
      // Validar que los comandos existan
      for (final cmd in commands) {
        if (!commandToAgent.containsKey(cmd)) {
          _logger
            ..error('Comando desconocido: $cmd')
            ..info('Usa --list para ver los comandos disponibles.');
          return 1;
        }
      }
      toInstall = commands;
    } else {
      // Instalar comandos esenciales por defecto
      toInstall = _essentialCommands
          .where(commandToAgent.containsKey)
          .toList();
    }

    _logger.title('Instalando comandos slash');

    var totalInstalled = 0;
    var totalSkipped = 0;

    // Instalar para cada plataforma
    for (final platform in targetPlatforms) {
      final (installed, skipped) = await _installForPlatform(
        platform: platform,
        commands: toInstall,
        commandToAgent: commandToAgent,
        force: force,
      );
      totalInstalled += installed;
      totalSkipped += skipped;
    }

    _logger
      ..blank()
      ..success(
        'Instalados: $totalInstalled, Omitidos: $totalSkipped '
        '(${targetPlatforms.length} plataformas)',
      );

    return 0;
  }

  /// Lista todas las plataformas soportadas.
  void _listPlatforms() {
    _logger
      ..title('Plataformas de IA soportadas')
      ..info('CLI-Based (requieren instalacion):');
    for (final platform in AiPlatformRegistry.cliRequired) {
      final cliInfo =
          platform.cliCommand != null ? ' (cli: ${platform.cliCommand})' : '';
      _logger.item('${platform.id} - ${platform.name}$cliInfo');
    }

    _logger
      ..blank()
      ..info('IDE-Based (integradas en IDE):');
    for (final platform in AiPlatformRegistry.ideBased) {
      _logger.item('${platform.id} - ${platform.name}');
    }
  }

  /// Resuelve las plataformas destino basado en los argumentos.
  Future<List<AiPlatformConfig>> _resolveTargetPlatforms({
    required List<String> agents,
    required bool allAgents,
    required bool detect,
  }) async {
    if (allAgents) {
      return AiPlatformRegistry.all;
    }

    if (detect) {
      return _detectInstalledPlatforms();
    }

    if (agents.isNotEmpty) {
      return agents.map((id) => AiPlatformRegistry.getPlatform(id)!).toList();
    }

    // Default: solo Claude
    return [AiPlatformRegistry.defaultPlatform];
  }

  /// Detecta plataformas instaladas en el sistema.
  Future<List<AiPlatformConfig>> _detectInstalledPlatforms() async {
    final detected = <AiPlatformConfig>[];

    _logger.info('Detectando plataformas instaladas...');

    for (final platform in AiPlatformRegistry.all) {
      final available = await platform.isCliAvailable();
      if (available) {
        detected.add(platform);
        _logger.item('${platform.name} detectado', prefix: '  +');
      }
    }

    if (detected.isEmpty) {
      // Si no detecta ninguna, usar Claude por defecto
      _logger.warning('No se detectaron plataformas. Usando Claude por defecto.');
      return [AiPlatformRegistry.defaultPlatform];
    }

    return detected;
  }

  /// Instala comandos para una plataforma especifica.
  Future<(int installed, int skipped)> _installForPlatform({
    required AiPlatformConfig platform,
    required List<String> commands,
    required Map<String, AgentDefinition> commandToAgent,
    required bool force,
  }) async {
    _logger
      ..blank()
      ..info('Instalando para ${platform.name}...');

    final outputDir = FileUtils.resolvePath(platform.commandFolder);
    await FileUtils.ensureDirectory(outputDir);

    final generator = CommandGenerator.forPlatform(platform);
    var installed = 0;
    var skipped = 0;

    for (final cmd in commands) {
      final fileName = platform.getCommandFileName(cmd);
      final filePath = p.join(outputDir, fileName);
      final exists = FileUtils.fileExists(filePath);

      if (exists && !force) {
        _logger.item('$cmd (ya existe, usa --force)', prefix: '  -');
        skipped++;
        continue;
      }

      // Obtener agente y generar template
      final agent = commandToAgent[cmd]!;
      final template = CommandTemplate.fromAgent(agent);

      final content = generator.generate(template);
      await FileUtils.writeFile(filePath, content, overwrite: true);
      _logger.item(fileName, prefix: '  +');
      installed++;
    }

    return (installed, skipped);
  }

  /// Trunca un string a una longitud maxima.
  String _truncate(String text, int maxLength) {
    final singleLine = text.replaceAll('\n', ' ').trim();
    if (singleLine.length <= maxLength) return singleLine;
    return '${singleLine.substring(0, maxLength - 3)}...';
  }
}
