import 'package:dfspec/src/models/agent_config.dart';

/// Registro de todos los agentes DFSpec disponibles.
///
/// Contiene la configuracion de los 11 agentes especializados
/// del ecosistema df* para desarrollo Flutter/Dart.
class AgentRegistry {
  const AgentRegistry._();

  /// Obtiene un agente por su ID.
  static AgentConfig? getAgent(String id) {
    return _agents[id];
  }

  /// Lista todos los agentes disponibles.
  static List<AgentConfig> get all => _agents.values.toList();

  /// Lista agentes por categoria.
  static List<AgentConfig> byCategory(AgentCategory category) {
    return all.where((a) => a.category == category).toList();
  }

  /// Lista IDs de todos los agentes.
  static List<String> get allIds => _agents.keys.toList();

  /// Verifica si un agente existe.
  static bool exists(String id) => _agents.containsKey(id);

  /// Obtiene agentes que tienen una capacidad especifica.
  static List<AgentConfig> withCapability(String capability) {
    return all.where((a) => a.hasCapability(capability)).toList();
  }

  /// Mapa de agentes por ID.
  static const Map<String, AgentConfig> _agents = {
    'dforchestrator': _dforchestrator,
    'dfplanner': _dfplanner,
    'dfsolid': _dfsolid,
    'dfsecurity': _dfsecurity,
    'dfdependencies': _dfdependencies,
    'dfimplementer': _dfimplementer,
    'dftest': _dftest,
    'dfcodequality': _dfcodequality,
    'dfperformance': _dfperformance,
    'dfdocumentation': _dfdocumentation,
    'dfverifier': _dfverifier,
  };

  // ============================================================
  // DEFINICIONES DE AGENTES
  // ============================================================

  static const _dforchestrator = AgentConfig(
    id: 'dforchestrator',
    name: 'DF Orchestrator',
    description: 'Orquestador principal que coordina todos los agentes '
        'especializados y gestiona el flujo de trabajo completo.',
    category: AgentCategory.orchestration,
    slashCommand: 'df-orchestrate',
    capabilities: [
      'Coordinacion de agentes',
      'Gestion de flujo de trabajo',
      'Priorizacion de tareas',
      'Resolucion de conflictos',
      'Seguimiento de progreso',
    ],
    tools: ['Task', 'TodoWrite', 'Read', 'Glob', 'Grep'],
  );

  static const _dfplanner = AgentConfig(
    id: 'dfplanner',
    name: 'DF Planner',
    description: 'Especialista en planificacion y diseno arquitectonico. '
        'Genera planes de implementacion siguiendo Clean Architecture.',
    category: AgentCategory.orchestration,
    slashCommand: 'df-plan',
    capabilities: [
      'Analisis de requisitos',
      'Diseno de arquitectura',
      'Generacion de planes TDD',
      'Estimacion de complejidad',
      'Identificacion de dependencias',
    ],
    dependsOn: ['dforchestrator'],
    tools: ['Read', 'Write', 'Glob', 'Grep', 'WebSearch'],
  );

  static const _dfsolid = AgentConfig(
    id: 'dfsolid',
    name: 'DF SOLID',
    description: 'Guardian de principios SOLID y Clean Architecture. '
        'Revisa y mejora la estructura del codigo.',
    category: AgentCategory.quality,
    slashCommand: 'df-review',
    capabilities: [
      'Validacion SOLID',
      'Clean Architecture',
      'Patrones de diseno',
      'Refactoring',
      'Code smells detection',
    ],
    tools: ['Read', 'Glob', 'Grep'],
  );

  static const _dfsecurity = AgentConfig(
    id: 'dfsecurity',
    name: 'DF Security',
    description: 'Especialista en seguridad movil. Analiza vulnerabilidades '
        'siguiendo OWASP Mobile Top 10.',
    category: AgentCategory.quality,
    slashCommand: 'df-security',
    capabilities: [
      'OWASP Mobile Top 10',
      'Analisis STRIDE',
      'Validacion de inputs',
      'Seguridad de datos',
      'Autenticacion/Autorizacion',
    ],
    tools: ['Read', 'Glob', 'Grep', 'WebSearch'],
  );

  static const _dfdependencies = AgentConfig(
    id: 'dfdependencies',
    name: 'DF Dependencies',
    description: 'Gestor de dependencias. Analiza, actualiza y optimiza '
        'las dependencias del proyecto.',
    category: AgentCategory.quality,
    slashCommand: 'df-deps',
    capabilities: [
      'Analisis de dependencias',
      'Deteccion de vulnerabilidades',
      'Actualizacion segura',
      'Optimizacion de imports',
      'Licencias compatibles',
    ],
    tools: ['Read', 'Bash', 'WebFetch', 'WebSearch'],
  );

  static const _dfimplementer = AgentConfig(
    id: 'dfimplementer',
    name: 'DF Implementer',
    description: 'Implementador TDD. Escribe codigo siguiendo el ciclo '
        'Red-Green-Refactor estrictamente.',
    category: AgentCategory.implementation,
    slashCommand: 'df-implement',
    capabilities: [
      'TDD estricto',
      'Clean Code',
      'Null Safety',
      'Error handling',
      'Codigo idiomatico Dart',
    ],
    dependsOn: ['dfplanner', 'dftest'],
    tools: ['Read', 'Write', 'Edit', 'Bash', 'Glob', 'Grep'],
  );

  static const _dftest = AgentConfig(
    id: 'dftest',
    name: 'DF Test',
    description: 'Especialista en testing. Genera tests unitarios, '
        'de widgets e integracion con alta cobertura.',
    category: AgentCategory.implementation,
    slashCommand: 'df-test',
    capabilities: [
      'Unit testing',
      'Widget testing',
      'Integration testing',
      'Mocking con Mocktail',
      'Cobertura de codigo',
    ],
    tools: ['Read', 'Write', 'Edit', 'Bash', 'Glob'],
  );

  static const _dfcodequality = AgentConfig(
    id: 'dfcodequality',
    name: 'DF Code Quality',
    description: 'Analista de calidad. Aplica linting estricto y '
        'mejores practicas de Dart/Flutter.',
    category: AgentCategory.quality,
    slashCommand: 'df-quality',
    capabilities: [
      'Linting estricto',
      'Very Good Analysis',
      'Dart best practices',
      'Flutter best practices',
      'Formateo de codigo',
    ],
    tools: ['Read', 'Edit', 'Bash', 'Glob', 'Grep'],
  );

  static const _dfperformance = AgentConfig(
    id: 'dfperformance',
    name: 'DF Performance',
    description: 'Optimizador de rendimiento. Asegura 60fps y '
        'uso eficiente de recursos.',
    category: AgentCategory.quality,
    slashCommand: 'df-performance',
    capabilities: [
      'Optimizacion 60fps',
      'Memory profiling',
      'Widget optimization',
      'Build optimization',
      'Lazy loading',
    ],
    tools: ['Read', 'Edit', 'Glob', 'Grep'],
  );

  static const _dfdocumentation = AgentConfig(
    id: 'dfdocumentation',
    name: 'DF Documentation',
    description: 'Generador de documentacion. Crea dartdocs, ADRs '
        'y documentacion tecnica.',
    category: AgentCategory.documentation,
    slashCommand: 'df-docs',
    capabilities: [
      'Dartdoc comments',
      'ADR generation',
      'README files',
      'API documentation',
      'Diagramas Mermaid',
    ],
    tools: ['Read', 'Write', 'Glob'],
  );

  static const _dfverifier = AgentConfig(
    id: 'dfverifier',
    name: 'DF Verifier',
    description: 'Verificador de implementacion. Valida que el codigo '
        'cumple con las especificaciones.',
    category: AgentCategory.orchestration,
    slashCommand: 'df-verify',
    capabilities: [
      'Verificacion vs spec',
      'Validacion de criterios',
      'Reporte de cumplimiento',
      'Gap analysis',
      'Recomendaciones',
    ],
    dependsOn: ['dftest'],
    tools: ['Read', 'Glob', 'Grep', 'Bash'],
  );
}
