import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// Formato de los archivos de comandos.
enum CommandFormat {
  /// Formato Markdown (usado por Claude, Cursor, Copilot, etc.)
  markdown('.md'),

  /// Formato TOML (usado por Gemini, Qwen)
  toml('.toml');

  const CommandFormat(this.fileExtension);

  /// Extension de archivo para este formato.
  final String fileExtension;
}

/// Configuracion de una plataforma de IA para comandos slash.
///
/// Representa la configuracion necesaria para generar e instalar
/// comandos slash en diferentes plataformas de IA como Claude Code,
/// Gemini CLI, Cursor, GitHub Copilot, etc.
@immutable
class AiPlatformConfig {
  /// Crea una nueva configuracion de plataforma IA.
  const AiPlatformConfig({
    required this.id,
    required this.name,
    required this.commandFolder,
    required this.commandFormat,
    this.contextFile,
    this.installUrl,
    this.requiresCli = false,
    this.cliCommand,
  });

  /// Identificador unico de la plataforma (ej: 'claude', 'gemini').
  final String id;

  /// Nombre para mostrar (ej: 'Claude Code', 'Gemini CLI').
  final String name;

  /// Carpeta donde se instalan los comandos (ej: '.claude/commands/').
  final String commandFolder;

  /// Formato de los archivos de comandos.
  final CommandFormat commandFormat;

  /// Nombre del archivo de contexto (ej: 'CLAUDE.md', 'GEMINI.md').
  final String? contextFile;

  /// URL de instalacion/documentacion del CLI.
  final String? installUrl;

  /// Si la plataforma requiere un CLI instalado.
  final bool requiresCli;

  /// Comando CLI para verificar instalacion (ej: 'claude', 'gemini').
  final String? cliCommand;

  /// Verifica si el CLI de la plataforma esta disponible.
  ///
  /// Retorna true si:
  /// - La plataforma no requiere CLI, o
  /// - El CLI esta instalado en el sistema
  Future<bool> isCliAvailable() async {
    if (!requiresCli) return true;
    if (cliCommand == null) return false;

    try {
      final result = await Process.run(
        Platform.isWindows ? 'where' : 'which',
        [cliCommand!],
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Genera el nombre de archivo para un comando.
  String getCommandFileName(String commandName) {
    return '$commandName${commandFormat.fileExtension}';
  }

  /// Genera el path completo para un archivo de comando.
  String getCommandFilePath(String commandName) {
    final folder = commandFolder.endsWith('/')
        ? commandFolder.substring(0, commandFolder.length - 1)
        : commandFolder;
    return p.join(folder, getCommandFileName(commandName));
  }

  /// Convierte a mapa para serializacion.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'commandFolder': commandFolder,
      'commandFormat': commandFormat.name,
      if (contextFile != null) 'contextFile': contextFile,
      if (installUrl != null) 'installUrl': installUrl,
      'requiresCli': requiresCli,
      if (cliCommand != null) 'cliCommand': cliCommand,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiPlatformConfig &&
        other.id == id &&
        other.name == name &&
        other.commandFolder == commandFolder &&
        other.commandFormat == commandFormat &&
        other.contextFile == contextFile &&
        other.installUrl == installUrl &&
        other.requiresCli == requiresCli &&
        other.cliCommand == cliCommand;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      commandFolder,
      commandFormat,
      contextFile,
      installUrl,
      requiresCli,
      cliCommand,
    );
  }

  @override
  String toString() => 'AiPlatformConfig($id: $name)';
}
