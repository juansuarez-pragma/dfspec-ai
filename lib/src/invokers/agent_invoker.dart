import 'package:dfspec/src/loaders/agent_loader.dart';
import 'package:dfspec/src/parsers/agent_parser.dart';
import 'package:dfspec/src/utils/exceptions.dart';
import 'package:meta/meta.dart';

/// Representa una invocación de agente lista para ejecutar.
///
/// Contiene toda la información necesaria para que Claude Code
/// invoque el agente con el modelo y herramientas correctas.
@immutable
class AgentInvocation {
  const AgentInvocation({
    required this.agentId,
    required this.model,
    required this.prompt,
    required this.tools,
    required this.description,
  });

  /// ID del agente a invocar.
  final String agentId;

  /// Modelo a usar (opus, sonnet, haiku).
  final String model;

  /// Prompt completo incluyendo system prompt del agente + tarea.
  final String prompt;

  /// Herramientas permitidas para este agente.
  final List<String> tools;

  /// Descripción corta de la tarea (para Task tool).
  final String description;

  /// Genera la instrucción para Claude Code Task tool.
  ///
  /// Retorna un mapa con los parámetros para invocar Task tool.
  Map<String, dynamic> toTaskToolParams() {
    return {
      'subagent_type': 'general-purpose',
      'model': model,
      'description': description,
      'prompt': prompt,
    };
  }

  /// Genera instrucciones legibles para el orquestador.
  String toInstructionText() {
    final buffer = StringBuffer()
      ..writeln('## Invocar Agente: $agentId')
      ..writeln()
      ..writeln('Usa la herramienta **Task** con estos parámetros:')
      ..writeln()
      ..writeln('```')
      ..writeln('subagent_type: "general-purpose"')
      ..writeln('model: "$model"')
      ..writeln('description: "$description"')
      ..writeln('prompt: <ver abajo>')
      ..writeln('```')
      ..writeln()
      ..writeln('### Prompt del agente')
      ..writeln()
      ..writeln('```')
      ..writeln(prompt)
      ..writeln('```');

    return buffer.toString();
  }

  @override
  String toString() => 'AgentInvocation($agentId, model: $model)';
}

/// Genera invocaciones de agentes con sus modelos y prompts correctos.
///
/// Permite al orquestador (o cualquier otro agente) invocar agentes
/// especializados con la configuración correcta definida en agents/*.md.
///
/// Ejemplo:
/// ```dart
/// final invoker = AgentInvoker();
/// final invocation = invoker.createInvocation(
///   agentId: 'dfplanner',
///   task: 'Diseña la arquitectura para sistema de favoritos',
///   context: {'project': 'mi-app', 'architecture': 'clean'},
/// );
///
/// // Usar con Claude Code Task tool
/// print(invocation.toTaskToolParams());
/// ```
class AgentInvoker {
  /// Crea un nuevo invoker.
  ///
  /// [loader] es opcional, por defecto usa AgentLoader estándar.
  AgentInvoker({AgentLoader? loader}) : _loader = loader ?? AgentLoader();

  final AgentLoader _loader;

  /// Cache de definiciones cargadas.
  final Map<String, AgentDefinition> _cache = {};

  /// Modelos válidos para Claude Code.
  static const validModels = ['opus', 'sonnet', 'haiku'];

  /// Modelo por defecto si no se especifica.
  static const defaultModel = 'sonnet';

  /// Crea una invocación para un agente específico.
  ///
  /// [agentId] es el ID del agente (ej: 'dfplanner').
  /// [task] es la descripción de la tarea a realizar.
  /// [context] es información adicional de contexto (opcional).
  /// [overrideModel] permite sobrescribir el modelo del agente.
  ///
  /// Throws [AgentNotFoundException] si el agente no existe.
  AgentInvocation createInvocation({
    required String agentId,
    required String task,
    Map<String, dynamic>? context,
    String? overrideModel,
  }) {
    final definition = _getDefinition(agentId);

    if (definition == null) {
      throw AgentNotFoundException(agentId);
    }

    final model = _resolveModel(definition.model, overrideModel);
    final prompt = _buildPrompt(definition, task, context);
    final description = _buildDescription(agentId, task);

    return AgentInvocation(
      agentId: agentId,
      model: model,
      prompt: prompt,
      tools: definition.tools,
      description: description,
    );
  }

  /// Crea múltiples invocaciones para ejecución en paralelo.
  ///
  /// Útil cuando el orquestador necesita ejecutar varios agentes
  /// simultáneamente (ej: dfcodequality, dfperformance, dfdocumentation).
  List<AgentInvocation> createParallelInvocations({
    required List<String> agentIds,
    required String task,
    Map<String, dynamic>? context,
  }) {
    return agentIds
        .map(
          (id) => createInvocation(agentId: id, task: task, context: context),
        )
        .toList();
  }

  /// Crea una cadena de invocaciones para pipeline secuencial.
  ///
  /// Cada invocación incluye instrucciones para pasar output
  /// al siguiente agente en la cadena.
  List<AgentInvocation> createPipelineInvocations({
    required List<String> agentIds,
    required String initialTask,
    Map<String, dynamic>? context,
  }) {
    final invocations = <AgentInvocation>[];

    for (var i = 0; i < agentIds.length; i++) {
      final isFirst = i == 0;
      final isLast = i == agentIds.length - 1;
      final agentId = agentIds[i];

      String taskWithPipeline;
      if (isFirst) {
        taskWithPipeline =
            '''
$initialTask

NOTA: Este es el paso ${i + 1} de ${agentIds.length} en el pipeline.
Tu output será usado por el siguiente agente: ${isLast ? 'N/A (último)' : agentIds[i + 1]}.
''';
      } else {
        taskWithPipeline =
            '''
Continúa el trabajo del agente anterior en el pipeline.

Tarea original: $initialTask

NOTA: Este es el paso ${i + 1} de ${agentIds.length} en el pipeline.
${isLast ? 'Eres el último agente - genera el output final.' : 'Tu output será usado por: ${agentIds[i + 1]}'}
''';
      }

      invocations.add(
        createInvocation(
          agentId: agentId,
          task: taskWithPipeline,
          context: context,
        ),
      );
    }

    return invocations;
  }

  /// Obtiene información del modelo recomendado para un agente.
  String? getRecommendedModel(String agentId) {
    return _getDefinition(agentId)?.model;
  }

  /// Lista todos los agentes disponibles con sus modelos.
  Map<String, String> listAgentsWithModels() {
    final agents = _loader.loadAll();
    return {for (final agent in agents) agent.id: agent.model ?? defaultModel};
  }

  /// Invalida el cache para forzar recarga.
  void invalidateCache() {
    _cache.clear();
  }

  // ignore: unused_element - usado internamente
  AgentDefinition? _getDefinition(String agentId) {
    if (_cache.containsKey(agentId)) {
      return _cache[agentId];
    }

    final definition = _loader.load(agentId);
    if (definition != null) {
      _cache[agentId] = definition;
    }
    return definition;
  }

  String _resolveModel(String? agentModel, String? overrideModel) {
    // Override tiene prioridad
    if (overrideModel != null && validModels.contains(overrideModel)) {
      return overrideModel;
    }

    // Modelo del agente
    if (agentModel != null && validModels.contains(agentModel)) {
      return agentModel;
    }

    // Default
    return defaultModel;
  }

  String _buildPrompt(
    AgentDefinition definition,
    String task,
    Map<String, dynamic>? context,
  ) {
    final buffer = StringBuffer()
      // System prompt del agente
      ..writeln(definition.content)
      ..writeln()
      ..writeln('---')
      ..writeln()
      // Tarea específica
      ..writeln('## TAREA ASIGNADA')
      ..writeln()
      ..writeln(task);

    // Contexto adicional si existe
    if (context != null && context.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## CONTEXTO')
        ..writeln();

      for (final entry in context.entries) {
        buffer.writeln('- **${entry.key}**: ${entry.value}');
      }
    }

    return buffer.toString();
  }

  String _buildDescription(String agentId, String task) {
    // Truncar tarea a ~50 chars para descripción corta
    final shortTask = task.length > 50 ? '${task.substring(0, 47)}...' : task;

    // Mapear agentId a nombre legible
    final agentName = switch (agentId) {
      'dfplanner' => 'Planning',
      'dfimplementer' => 'Implementing',
      'dftest' => 'Testing',
      'dfsolid' => 'SOLID review',
      'dfsecurity' => 'Security audit',
      'dfperformance' => 'Performance audit',
      'dfcodequality' => 'Quality analysis',
      'dfdocumentation' => 'Documentation',
      'dfdependencies' => 'Deps validation',
      'dfverifier' => 'Verification',
      'dforchestrator' => 'Orchestrating',
      'dfspec' => 'Spec analysis',
      'dfstatus' => 'Status check',
      _ => agentId,
    };

    return '$agentName: $shortTask';
  }
}
