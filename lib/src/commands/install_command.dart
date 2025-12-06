import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dfspec/src/config/claude_config.dart';
import 'package:dfspec/src/generators/command_generator.dart';
import 'package:dfspec/src/loaders/agent_loader.dart';
import 'package:dfspec/src/models/models.dart';
import 'package:dfspec/src/parsers/agent_parser.dart';
import 'package:dfspec/src/utils/utils.dart';
import 'package:path/path.dart' as p;

/// Comando para instalar comandos slash de DFSpec en Claude Code.
///
/// Genera comandos directamente desde los archivos de agentes en `agents/`.
///
/// Uso:
/// ```bash
/// dfspec install           # Instala comandos esenciales
/// dfspec install --all     # Instala todos los comandos
/// dfspec install -c df-plan -c df-test  # Comandos especificos
/// dfspec install --force   # Sobrescribe existentes
/// dfspec install --list    # Lista comandos disponibles
/// ```
class InstallCommand extends Command<int> {
  /// Crea una nueva instancia del comando install.
  InstallCommand({AgentLoader? agentLoader})
      : _agentLoader = agentLoader ?? AgentLoader() {
    argParser
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
      );
  }

  final AgentLoader _agentLoader;

  @override
  String get name => 'install';

  @override
  String get description => 'Instala comandos slash de DFSpec para Claude Code.';

  @override
  String get invocation => 'dfspec install [--all] [--command=nombre]';

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

    _logger.title('Instalando comandos slash para Claude Code');

    // Instalar comandos
    final (installed, skipped) = await _installCommands(
      commands: toInstall,
      commandToAgent: commandToAgent,
      force: force,
    );

    _logger
      ..blank()
      ..success('Instalados: $installed, Omitidos: $skipped');

    return 0;
  }

  /// Instala los comandos en .claude/commands/.
  Future<(int installed, int skipped)> _installCommands({
    required List<String> commands,
    required Map<String, AgentDefinition> commandToAgent,
    required bool force,
  }) async {
    final outputDir = ClaudeCodeConfig.getCommandFolderPath(
      Directory.current.path,
    );
    await FileUtils.ensureDirectory(outputDir);

    const generator = ClaudeCommandGenerator();
    var installed = 0;
    var skipped = 0;

    for (final cmd in commands) {
      final fileName = ClaudeCodeConfig.getCommandFileName(cmd);
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
