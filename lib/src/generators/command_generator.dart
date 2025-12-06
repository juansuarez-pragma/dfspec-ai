import 'package:dfspec/src/models/ai_platform_config.dart';
import 'package:dfspec/src/parsers/agent_parser.dart';
import 'package:meta/meta.dart';

/// Template de un comando slash con su contenido.
@immutable
class CommandTemplate {
  /// Crea un nuevo template de comando.
  const CommandTemplate({
    required this.name,
    required this.description,
    required this.tools,
    required this.content,
  });

  /// Crea un template desde una definicion de agente.
  factory CommandTemplate.fromAgent(AgentDefinition agent) {
    return CommandTemplate(
      name: agent.slashCommand,
      description: agent.description,
      tools: agent.tools,
      content: agent.content,
    );
  }

  /// Nombre del comando (ej: 'df-spec').
  final String name;

  /// Descripcion breve del comando.
  final String description;

  /// Lista de herramientas permitidas.
  final List<String> tools;

  /// Contenido/prompt del comando.
  final String content;
}

/// Generador de comandos para diferentes formatos.
///
/// Implementa el patron Strategy para generar comandos
/// en diferentes formatos segun la plataforma de IA.
abstract class CommandGenerator {

  /// Factory que retorna el generador apropiado para una plataforma.
  factory CommandGenerator.forPlatform(AiPlatformConfig platform) {
    return switch (platform.commandFormat) {
      CommandFormat.markdown => MarkdownCommandGenerator(),
      CommandFormat.toml => TomlCommandGenerator(),
    };
  }
  /// Genera el contenido del archivo de comando.
  String generate(CommandTemplate template);
}

/// Generador de comandos en formato Markdown.
///
/// Usado por: Claude Code, Cursor, GitHub Copilot, etc.
class MarkdownCommandGenerator implements CommandGenerator {
  @override
  String generate(CommandTemplate template) {
    final buffer = StringBuffer()
      // Frontmatter YAML
      ..writeln('---')
      ..writeln('description: ${template.description}')
      ..writeln('allowed-tools: ${template.tools.join(', ')}')
      ..writeln('---')
      ..writeln()
      // Contenido del comando
      ..write(template.content);

    return buffer.toString();
  }
}

/// Generador de comandos en formato TOML.
///
/// Usado por: Gemini CLI, Qwen Code.
class TomlCommandGenerator implements CommandGenerator {
  @override
  String generate(CommandTemplate template) {
    final buffer = StringBuffer()
      // Seccion [command]
      ..writeln('[command]')
      ..writeln('name = "${template.name}"')
      ..writeln('description = "${_escapeTomlString(template.description)}"')
      ..writeln('tools = [${_formatToolsArray(template.tools)}]')
      ..writeln()
      // Seccion [prompt]
      ..writeln('[prompt]')
      ..writeln('content = """')
      ..writeln(template.content)
      ..writeln('"""');

    return buffer.toString();
  }

  String _escapeTomlString(String value) {
    return value.replaceAll('"', r'\"');
  }

  String _formatToolsArray(List<String> tools) {
    if (tools.isEmpty) return '';
    return tools.map((t) => '"$t"').join(', ');
  }
}
