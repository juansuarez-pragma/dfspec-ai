import 'package:path/path.dart' as p;

/// Configuracion especifica para Claude Code.
///
/// Centraliza todas las constantes y configuraciones necesarias
/// para la integracion con Claude Code CLI.
///
/// Esta clase es el punto central de configuracion para DFSpec
/// cuando opera con Claude Code. Incluye:
/// - Rutas de carpetas y archivos
/// - Modelos disponibles y sus usos recomendados
/// - Herramientas MCP de Dart
/// - Configuracion de Task tool para invocacion de agentes
///
/// Ejemplo:
/// ```dart
/// // Obtener ruta de comando
/// final path = ClaudeCodeConfig.getCommandFilePath('/mi-proyecto', 'df-plan');
/// // => '/mi-proyecto/.claude/commands/df-plan.md'
///
/// // Verificar modelo valido
/// if (ClaudeCodeConfig.isValidModel('opus')) {
///   print('Modelo valido');
/// }
/// ```
class ClaudeCodeConfig {
  const ClaudeCodeConfig._();

  // ═══════════════════════════════════════════════════════════════════════════
  // RUTAS Y ARCHIVOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Carpeta donde se instalan los comandos slash.
  static const commandFolder = '.claude/commands';

  /// Archivo de contexto del proyecto para Claude Code.
  static const contextFile = 'CLAUDE.md';

  /// Extension de los archivos de comando.
  static const commandExtension = '.md';

  // ═══════════════════════════════════════════════════════════════════════════
  // MODELOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Modelos disponibles en Claude Code Task tool.
  ///
  /// - `opus`: Modelo mas potente, para tareas complejas de razonamiento
  /// - `sonnet`: Balance entre capacidad y velocidad
  /// - `haiku`: Modelo rapido y economico para tareas simples
  static const availableModels = ['opus', 'sonnet', 'haiku'];

  /// Modelo por defecto para tareas complejas (arquitectura, implementacion).
  static const defaultModel = 'opus';

  /// Modelo para tareas simples y rapidas (status, listados).
  static const lightModel = 'haiku';

  /// Modelo balanceado para tareas intermedias.
  static const balancedModel = 'sonnet';

  /// Verifica si un modelo es valido.
  static bool isValidModel(String model) => availableModels.contains(model);

  /// Obtiene el modelo recomendado segun la complejidad de la tarea.
  ///
  /// [complexity] puede ser 'high', 'medium', o 'low'.
  static String getModelForComplexity(String complexity) {
    return switch (complexity.toLowerCase()) {
      'high' => defaultModel,
      'medium' => balancedModel,
      'low' => lightModel,
      _ => defaultModel,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERRAMIENTAS MCP
  // ═══════════════════════════════════════════════════════════════════════════

  /// Herramientas MCP de Dart disponibles en Claude Code.
  static const dartMcpTools = [
    'mcp__dart__analyze_files',
    'mcp__dart__run_tests',
    'mcp__dart__dart_format',
    'mcp__dart__dart_fix',
    'mcp__dart__pub',
    'mcp__dart__pub_dev_search',
    'mcp__dart__create_project',
    'mcp__dart__list_devices',
    'mcp__dart__launch_app',
    'mcp__dart__hot_reload',
    'mcp__dart__hot_restart',
  ];

  /// Herramientas basicas de Claude Code (siempre disponibles).
  static const coreTools = [
    'Read',
    'Write',
    'Edit',
    'Glob',
    'Grep',
    'Bash',
    'Task',
    'WebSearch',
    'WebFetch',
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // TASK TOOL (Invocacion de Sub-Agentes)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tipo de sub-agente para invocacion via Task tool.
  ///
  /// Usamos 'general-purpose' porque los agentes DFSpec son prompts
  /// personalizados, no tipos de agente predefinidos de Claude Code.
  static const taskSubagentType = 'general-purpose';

  /// Genera los parametros para invocar un agente via Task tool.
  ///
  /// [model] es el modelo a usar (opus, sonnet, haiku).
  /// [description] es una descripcion corta de la tarea (3-5 palabras).
  /// [prompt] es el prompt completo incluyendo system prompt del agente.
  ///
  /// Ejemplo:
  /// ```dart
  /// final params = ClaudeCodeConfig.createTaskParams(
  ///   model: 'opus',
  ///   description: 'Planning: Design auth system',
  ///   prompt: '[agent content]\n---\nTask: Design authentication...',
  /// );
  /// ```
  static Map<String, dynamic> createTaskParams({
    required String model,
    required String description,
    required String prompt,
  }) {
    return {
      'subagent_type': taskSubagentType,
      'model': isValidModel(model) ? model : defaultModel,
      'description': description,
      'prompt': prompt,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILIDADES DE RUTAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Genera el nombre del archivo de comando.
  ///
  /// [commandName] es el nombre del comando (ej: 'df-plan').
  /// Retorna el nombre con extension (ej: 'df-plan.md').
  static String getCommandFileName(String commandName) {
    final name = commandName.endsWith(commandExtension)
        ? commandName
        : '$commandName$commandExtension';
    return name;
  }

  /// Genera la ruta completa del archivo de comando.
  ///
  /// [projectRoot] es la raiz del proyecto.
  /// [commandName] es el nombre del comando (ej: 'df-plan').
  static String getCommandFilePath(String projectRoot, String commandName) {
    return p.join(projectRoot, commandFolder, getCommandFileName(commandName));
  }

  /// Genera la ruta de la carpeta de comandos.
  static String getCommandFolderPath(String projectRoot) {
    return p.join(projectRoot, commandFolder);
  }

  /// Genera la ruta del archivo de contexto.
  static String getContextFilePath(String projectRoot) {
    return p.join(projectRoot, contextFile);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FRONTMATTER
  // ═══════════════════════════════════════════════════════════════════════════

  /// Genera el frontmatter YAML para un comando slash.
  ///
  /// [description] es la descripcion del comando.
  /// [tools] es la lista de herramientas permitidas.
  static String generateFrontmatter({
    required String description,
    required List<String> tools,
  }) {
    final buffer = StringBuffer()
      ..writeln('---')
      ..writeln('description: $description')
      ..writeln('allowed-tools: ${tools.join(', ')}')
      ..writeln('---');
    return buffer.toString();
  }
}
