import 'package:dfspec/src/config/claude_config.dart';
import 'package:dfspec/src/parsers/agent_parser.dart';
import 'package:meta/meta.dart';

/// Template de un comando slash con su contenido.
///
/// Representa la informacion necesaria para generar un archivo
/// de comando slash para Claude Code.
@immutable
class CommandTemplate {
  /// Crea un nuevo template de comando.
  const CommandTemplate({
    required this.name,
    required this.description,
    required this.tools,
    required this.content,
    this.handoffs = const [],
  });

  /// Crea un template desde una definicion de agente.
  factory CommandTemplate.fromAgent(AgentDefinition agent) {
    return CommandTemplate(
      name: agent.slashCommand,
      description: agent.description,
      tools: agent.tools,
      content: agent.content,
      handoffs: agent.handoffs,
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

  /// Lista de handoffs a otros comandos.
  final List<AgentHandoff> handoffs;

  /// Verifica si tiene handoffs definidos.
  bool get hasHandoffs => handoffs.isNotEmpty;
}

/// Generador de comandos slash para Claude Code.
///
/// Genera archivos Markdown con YAML frontmatter compatibles
/// con el formato de comandos de Claude Code CLI.
///
/// Formato generado:
/// ```markdown
/// ---
/// description: Descripcion del comando
/// allowed-tools: Read, Write, Glob
/// ---
///
/// [Contenido del comando]
///
/// ## Handoffs
/// - /df-plan: Crear plan de implementacion
/// ```
///
/// Ejemplo:
/// ```dart
/// final generator = ClaudeCommandGenerator();
/// final template = CommandTemplate(
///   name: 'df-plan',
///   description: 'Genera plan de implementacion',
///   tools: ['Read', 'Glob', 'WebSearch'],
///   content: '# Agente dfplanner\n...',
///   handoffs: [AgentHandoff(command: '/df-implement', label: 'Implementar')],
/// );
/// final content = generator.generate(template);
/// ```
class ClaudeCommandGenerator {
  /// Crea una instancia del generador.
  const ClaudeCommandGenerator();

  /// Genera el contenido del archivo de comando.
  ///
  /// [template] contiene la informacion del comando a generar.
  /// Retorna el contenido Markdown con frontmatter YAML.
  String generate(CommandTemplate template) {
    final frontmatter = ClaudeCodeConfig.generateFrontmatter(
      description: template.description,
      tools: template.tools,
    );

    final buffer = StringBuffer()
      ..write(frontmatter)
      ..writeln()
      ..write(template.content);

    // Agregar seccion de handoffs si existen
    if (template.hasHandoffs) {
      buffer
        ..writeln()
        ..writeln()
        ..write(_generateHandoffsSection(template.handoffs));
    }

    return buffer.toString();
  }

  /// Genera la seccion de handoffs en formato Markdown.
  String _generateHandoffsSection(List<AgentHandoff> handoffs) {
    final buffer = StringBuffer()
      ..writeln('## Siguientes Pasos Sugeridos')
      ..writeln()
      ..writeln('Al completar esta tarea, considera ejecutar:')
      ..writeln();

    for (final handoff in handoffs) {
      final autoPrefix = handoff.auto ? '**[AUTO]** ' : '';
      buffer.write('- $autoPrefix`/${handoff.command}`: ${handoff.label}');
      if (handoff.description != null && handoff.description!.isNotEmpty) {
        buffer.write(' - ${handoff.description}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
