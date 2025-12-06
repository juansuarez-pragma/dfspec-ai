import 'package:dfspec/src/models/ai_platform_config.dart';

/// Registro de todas las plataformas de IA soportadas por DFSpec.
///
/// Contiene la configuracion de cada plataforma de IA donde se pueden
/// instalar los comandos slash de DFSpec.
class AiPlatformRegistry {
  const AiPlatformRegistry._();

  /// Obtiene una plataforma por su ID.
  static AiPlatformConfig? getPlatform(String id) {
    return _platforms[id];
  }

  /// Lista todas las plataformas disponibles.
  static List<AiPlatformConfig> get all => _platforms.values.toList();

  /// Lista IDs de todas las plataformas.
  static List<String> get allIds => _platforms.keys.toList();

  /// Mapa de plataformas disponibles.
  static Map<String, AiPlatformConfig> get platforms => _platforms;

  /// Verifica si una plataforma existe.
  static bool exists(String id) => _platforms.containsKey(id);

  /// Plataformas que requieren CLI instalado.
  static List<AiPlatformConfig> get cliRequired =>
      all.where((p) => p.requiresCli).toList();

  /// Plataformas basadas en IDE (no requieren CLI).
  static List<AiPlatformConfig> get ideBased =>
      all.where((p) => !p.requiresCli).toList();

  /// Filtra plataformas por formato de comando.
  static List<AiPlatformConfig> byFormat(CommandFormat format) =>
      all.where((p) => p.commandFormat == format).toList();

  /// Plataforma por defecto (Claude Code).
  static AiPlatformConfig get defaultPlatform => _platforms['claude']!;

  // ============================================================
  // DEFINICIONES DE PLATAFORMAS
  // ============================================================

  static const Map<String, AiPlatformConfig> _platforms = {
    // ==================== CLI-BASED ====================

    'claude': AiPlatformConfig(
      id: 'claude',
      name: 'Claude Code',
      commandFolder: '.claude/commands/',
      commandFormat: CommandFormat.markdown,
      contextFile: 'CLAUDE.md',
      installUrl: 'https://claude.ai/code',
      requiresCli: true,
      cliCommand: 'claude',
    ),

    'gemini': AiPlatformConfig(
      id: 'gemini',
      name: 'Gemini CLI',
      commandFolder: '.gemini/commands/',
      commandFormat: CommandFormat.toml,
      contextFile: 'GEMINI.md',
      installUrl: 'https://ai.google.dev/gemini-api/docs/cli',
      requiresCli: true,
      cliCommand: 'gemini',
    ),

    'cursor': AiPlatformConfig(
      id: 'cursor',
      name: 'Cursor',
      commandFolder: '.cursor/commands/',
      commandFormat: CommandFormat.markdown,
      contextFile: '.cursorrules',
      installUrl: 'https://cursor.sh',
      requiresCli: true,
      cliCommand: 'cursor-agent',
    ),

    'codex': AiPlatformConfig(
      id: 'codex',
      name: 'OpenAI Codex CLI',
      commandFolder: '.codex/commands/',
      commandFormat: CommandFormat.markdown,
      contextFile: 'AGENTS.md',
      installUrl: 'https://github.com/openai/codex',
      requiresCli: true,
      cliCommand: 'codex',
    ),

    'qwen': AiPlatformConfig(
      id: 'qwen',
      name: 'Qwen Code',
      commandFolder: '.qwen/commands/',
      commandFormat: CommandFormat.toml,
      contextFile: 'QWEN.md',
      installUrl: 'https://github.com/QwenLM/Qwen',
      requiresCli: true,
      cliCommand: 'qwen',
    ),

    'amazonq': AiPlatformConfig(
      id: 'amazonq',
      name: 'Amazon Q Developer',
      commandFolder: '.amazonq/prompts/',
      commandFormat: CommandFormat.markdown,
      contextFile: 'AMAZONQ.md',
      installUrl: 'https://aws.amazon.com/q/developer/',
      requiresCli: true,
      cliCommand: 'q',
    ),

    'opencode': AiPlatformConfig(
      id: 'opencode',
      name: 'opencode',
      commandFolder: '.opencode/commands/',
      commandFormat: CommandFormat.markdown,
      contextFile: 'OPENCODE.md',
      installUrl: 'https://github.com/opencode-ai/opencode',
      requiresCli: true,
      cliCommand: 'opencode',
    ),

    'amp': AiPlatformConfig(
      id: 'amp',
      name: 'Amp',
      commandFolder: '.amp/commands/',
      commandFormat: CommandFormat.markdown,
      contextFile: 'AMP.md',
      installUrl: 'https://ampcode.com',
      requiresCli: true,
      cliCommand: 'amp',
    ),

    'shai': AiPlatformConfig(
      id: 'shai',
      name: 'SHAI',
      commandFolder: '.shai/commands/',
      commandFormat: CommandFormat.markdown,
      contextFile: 'SHAI.md',
      requiresCli: true,
      cliCommand: 'shai',
    ),

    'codebuddy': AiPlatformConfig(
      id: 'codebuddy',
      name: 'CodeBuddy',
      commandFolder: '.codebuddy/commands/',
      commandFormat: CommandFormat.markdown,
      contextFile: 'CODEBUDDY.md',
      requiresCli: true,
      cliCommand: 'codebuddy',
    ),

    'qoder': AiPlatformConfig(
      id: 'qoder',
      name: 'Qoder',
      commandFolder: '.qoder/commands/',
      commandFormat: CommandFormat.markdown,
      contextFile: 'QODER.md',
      requiresCli: true,
      cliCommand: 'qoder',
    ),

    'auggie': AiPlatformConfig(
      id: 'auggie',
      name: 'Auggie CLI',
      commandFolder: '.auggie/commands/',
      commandFormat: CommandFormat.markdown,
      contextFile: 'AUGGIE.md',
      requiresCli: true,
      cliCommand: 'auggie',
    ),

    // ==================== IDE-BASED ====================

    'copilot': AiPlatformConfig(
      id: 'copilot',
      name: 'GitHub Copilot',
      commandFolder: '.github/agents/',
      commandFormat: CommandFormat.markdown,
      contextFile: 'COPILOT.md',
      installUrl: 'https://github.com/features/copilot',
    ),

    'windsurf': AiPlatformConfig(
      id: 'windsurf',
      name: 'Windsurf',
      commandFolder: '.windsurf/workflows/',
      commandFormat: CommandFormat.markdown,
      contextFile: '.windsurfrules',
      installUrl: 'https://windsurf.ai',
    ),

    'kilocode': AiPlatformConfig(
      id: 'kilocode',
      name: 'Kilo Code',
      commandFolder: '.kilo/commands/',
      commandFormat: CommandFormat.markdown,
      contextFile: 'KILO.md',
    ),

    'roo': AiPlatformConfig(
      id: 'roo',
      name: 'Roo Code',
      commandFolder: '.roo/commands/',
      commandFormat: CommandFormat.markdown,
      contextFile: 'ROO.md',
    ),

    'bob': AiPlatformConfig(
      id: 'bob',
      name: 'IBM Bob',
      commandFolder: '.bob/commands/',
      commandFormat: CommandFormat.markdown,
      contextFile: 'BOB.md',
    ),
  };
}
