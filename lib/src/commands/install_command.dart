import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dfspec/src/models/models.dart';
import 'package:dfspec/src/templates/templates.dart';
import 'package:dfspec/src/utils/utils.dart';
import 'package:path/path.dart' as p;

/// Comando para instalar comandos slash en .claude/commands/.
///
/// Lee los templates de slash commands y los copia al directorio
/// de comandos de Claude Code.
///
/// Uso:
/// ```bash
/// dfspec install [--all] [--command=nombre]
/// ```
class InstallCommand extends Command<int> {
  /// Crea una nueva instancia del comando install.
  InstallCommand() {
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

  @override
  String get name => 'install';

  @override
  String get description =>
      'Instala comandos slash de DFSpec en .claude/commands/.';

  @override
  String get invocation => 'dfspec install [--all] [--command=nombre]';

  final Logger _logger = const Logger();

  @override
  Future<int> run() async {
    final all = argResults!['all'] as bool;
    final commands = argResults!['command'] as List<String>;
    final force = argResults!['force'] as bool;
    final listOnly = argResults!['list'] as bool;

    // Obtener comandos disponibles
    const availableCommands = SlashCommandTemplates.available;

    // Modo lista
    if (listOnly) {
      _logger.title('Comandos slash disponibles');
      for (final cmd in availableCommands) {
        final info = SlashCommandTemplates.getInfo(cmd);
        _logger.item('$cmd - ${info['description']}');
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
        if (!availableCommands.contains(cmd)) {
          _logger..error('Comando desconocido: $cmd')
          ..info('Usa --list para ver los comandos disponibles.');
          return 1;
        }
      }
      toInstall = commands;
    } else {
      // Instalar comandos esenciales por defecto
      toInstall = SlashCommandTemplates.essential;
    }

    _logger.title('Instalando comandos slash');

    final outputDir = FileUtils.resolvePath(config.outputDir);
    await FileUtils.ensureDirectory(outputDir);

    var installed = 0;
    var skipped = 0;

    for (final cmd in toInstall) {
      final filePath = p.join(outputDir, '$cmd.md');
      final exists = FileUtils.fileExists(filePath);

      if (exists && !force) {
        _logger.item('$cmd (ya existe, usa --force)', prefix: '  -');
        skipped++;
        continue;
      }

      final content = SlashCommandTemplates.getTemplate(cmd);
      await FileUtils.writeFile(filePath, content, overwrite: true);
      _logger.item(cmd, prefix: '  +');
      installed++;
    }

    _logger..blank()
    ..success('Instalados: $installed, Omitidos: $skipped');

    if (installed > 0) {
      _logger..blank()
      ..info('Los comandos estan disponibles en Claude Code:');
      for (final cmd in toInstall) {
        if (!FileUtils.fileExists(p.join(outputDir, '$cmd.md')) || force) {
          continue;
        }
        _logger.item('/$cmd');
      }
    }

    return 0;
  }
}
