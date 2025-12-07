# Changelog

Todos los cambios notables de este proyecto seran documentados en este archivo.

El formato esta basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [Unreleased]

### Agregado

#### Detección Automática de Contexto (Fase 2)
- **Modelos de Contexto**
  - `FeatureContext` - Contexto completo de una feature (id, status, paths, documents)
  - `FeaturePaths` - Paths a documentos de feature (spec, plan, tasks, research, etc.)
  - `FeatureDocuments` - Flags de existencia de documentos
  - `SddFeatureStatus` - Estado de feature en flujo SDD (none → specified → planned → readyToImplement → implementing → implemented → verified)
  - `ProjectContext` - Contexto completo del proyecto
  - `GitContext` - Estado del repositorio git
  - `ProjectInfo` - Información del proyecto (type, stateManagement, platforms)
  - `ProjectQualityMetrics` - Métricas de calidad (testFileCount, libFileCount, testRatio)
  - `ProjectType` - Tipos de proyecto (flutterApp, dartPackage, dartCli, flutterPlugin)

- **ContextDetector Service**
  - `detectFullContext()` - Detecta contexto completo ejecutando scripts bash
  - `detectCurrentFeature()` - Detecta solo la feature actual
  - `checkPrerequisites()` - Verifica prerequisitos para un paso del flujo
  - `validateSpec()` - Valida calidad de especificación con score y findings
  - `getNextFeatureNumber()` - Obtiene siguiente número de feature disponible
  - `PrerequisitesResult`, `SpecValidationResult`, `SpecFinding` - Resultados tipados

- **Comando CLI `dfspec context`**
  - `dfspec context` - Muestra contexto completo con colores ANSI
  - `dfspec context --json` - Salida JSON estructurada
  - `dfspec context --feature=001-auth` - Override de feature
  - `dfspec context check` - Verifica prerequisitos
  - `dfspec context check --require-spec --require-plan` - Verifica documentos específicos
  - `dfspec context validate` - Valida spec con score 0-100
  - `dfspec context validate --strict` - Modo estricto (falla con warnings)
  - `dfspec context next` - Muestra siguiente número de feature

- **Tests**
  - 46 tests nuevos para modelos (FeatureContext, ProjectContext)
  - Tests de serialización JSON, igualdad con Equatable
  - Tests de lógica de negocio (inferredStatus, canPlan, canImplement)

#### Scripts de Automatización (Fase 1 - Inspirado en spec-kit)
- `scripts/bash/common.sh` - Funciones compartidas para todos los scripts
  - Utilidades de output (die, warn, info, success, debug)
  - Utilidades JSON (json_success, json_error, json_escape)
  - Validaciones (require_git_repo, require_dfspec_config, require_file)
  - Git utilities (get_current_branch, get_git_root, has_uncommitted_changes)
  - Feature utilities (get_next_feature_number, format_feature_name, detect_current_feature)
- `scripts/bash/check-prerequisites.sh` - Verificación de prerequisitos
  - Opciones: `--json`, `--paths-only`, `--require-spec`, `--require-plan`, `--require-tasks`
  - Retorna JSON con paths, feature detectada, documentos disponibles
- `scripts/bash/detect-context.sh` - Detección completa de contexto
  - Secciones: project, git, feature, documents, quality
  - Opciones: `--json`, `--summary`, `--feature=NAME`
- `scripts/bash/create-new-feature.sh` - Creación de nuevas features
  - Auto-incrementa número de feature desde branches y directorios
  - Crea branch git, directorio, spec.md desde template
  - Opciones: `--no-branch`, `--no-template`, `--number=NNN`
- `scripts/bash/setup-plan.sh` - Configuración de entorno de planificación
  - Crea plan.md con Pre-Implementation Gates, diagramas Mermaid
  - Archivos auxiliares: research.md, data-model.md, contracts/
  - Opciones: `--with-research`, `--with-datamodel`, `--with-contracts`, `--full`
- `scripts/bash/validate-spec.sh` - Validación de calidad de specs
  - Detecta: [NEEDS CLARIFICATION], TODOs, adjetivos vagos, secciones vacías
  - Valida: User Stories con criterios, requisitos verificables
  - Retorna: score 0-100, findings por severidad (CRITICAL, WARNING, INFO)
  - Opciones: `--json`, `--strict`, `--feature=NAME`

#### Integración Scripts en Slash Commands
- `/df-spec` - Integrado con detect-context.sh, create-new-feature.sh, validate-spec.sh
- `/df-plan` - Integrado con check-prerequisites.sh, setup-plan.sh
- `/df-implement` - Integrado con check-prerequisites.sh (--require-spec --require-plan)
- Todos los comandos documentan scripts en frontmatter YAML

#### Tests de Scripts
- `test/scripts/scripts_test.dart` - 21 tests de integración para scripts
  - Verificación de existencia y ejecutabilidad
  - Validación de salida JSON
  - Tests de funciones comunes (json_escape, format_feature_name)
  - Tests de integración entre scripts

#### Comandos CLI para Servicios
- `dfspec verify` - Verificación constitucional con quality gates
  - Soporta: `--all`, `--gate=<tdd|architecture|coverage|complexity|docs>`
  - Modos: `--strict`, `--ci`, `--threshold`
- `dfspec quality` - Análisis de calidad de código
  - Subcomandos: `analyze`, `complexity`, `docs`
  - Formatos: markdown, json, summary
- `dfspec report` - Generación de reportes
  - Soporta: `--feature`, `--project`, `--format`, `--save`
- `dfspec docs` - Gestión de documentación
  - Subcomandos: `verify`, `generate`
  - Tipos: readme, changelog, architecture, spec, plan
- `dfspec cache` - Control del cache de análisis
  - Subcomandos: `stats`, `clear`, `prune`
- `dfspec recovery` - Sistema de recovery points
  - Subcomandos: `create`, `list`, `restore`, `report`, `prune`

#### UX Mejorada
- `Spinner` - Animación de spinner para operaciones largas
  - 9 estilos: dots, line, dots2, circle, arrows, clock, bar, bounce, simple
  - Métodos: `success()`, `fail()`, `warn()`, `info()`
- `ProgressBar` - Barra de progreso animada
  - Métodos: `update()`, `increment()`, `complete()`, `fail()`
- `TaskRunner` - Ejecutor de tareas múltiples con progreso
  - Reporte de éxito/fallo por tarea
  - Resumen final

#### Templates Mejorados
- Template de Feature actualizado con:
  - Sección de User Stories (formato estándar)
  - Criterios de aceptación con DADO/CUANDO/ENTONCES
  - Matriz de trazabilidad
  - Definition of Done (DoD)
  - Diagrama de relaciones (Mermaid)
  - Wireframes ASCII
- Template de Plan actualizado con User Stories

#### Handoffs Bidireccionales
- Todos los comandos slash ahora documentan:
  - **Entradas**: qué comandos pueden invocar este comando
  - **Salidas**: qué comandos este puede invocar
- Pipeline de orquestación documentado en `/df-orchestrate`

#### Tests de Integración
- Tests para integración comando-servicio
- 675 tests totales pasando

### Breaking Changes

#### Arquitectura Claude-First
- **BREAKING**: Eliminado soporte multi-plataforma (17 plataformas → solo Claude Code)
- **BREAKING**: Eliminadas opciones CLI: `--agent`, `--all-agents`, `--detect`, `--list-agents`
- **BREAKING**: Eliminados archivos `ai_platform_registry.dart` y `ai_platform_config.dart`
- `dfspec init` ahora solo crea estructura para Claude Code (`.claude/commands/`, `CLAUDE.md`)
- `dfspec install` ahora solo instala en `.claude/commands/`

### Cambiado

#### Simplificación de Arquitectura
- `ClaudeCodeConfig` - Nueva configuración centralizada para Claude Code
- `ClaudeCommandGenerator` - Generador único (eliminados factory pattern y TOML)
- `InstallCommand` simplificado de 329 a 203 líneas (-126 líneas)
- `InitCommand` simplificado de 407 a 379 líneas
- Reducción neta de ~700 líneas de código

#### Arquitectura: Agentes como Single Source of Truth
- Los agentes (`agents/*.md`) son la fuente única de verdad
- `AgentLoader` carga definiciones desde archivos markdown con YAML frontmatter
- `AgentParser` parsea frontmatter YAML de agentes
- `CommandTemplate.fromAgent()` genera templates desde definiciones
- `AgentRegistry` refactorizado para usar `AgentLoader`

#### Performance
- `AgentLoader` convertido de async a sync (evita `avoid_slow_async_io`)
- Métodos `listAvailable()`, `load()`, `loadAll()`, `exists()` ahora síncronos

#### Calidad de Código
- Aplicadas cascade invocations en generadores y comandos
- Resueltas advertencias de linting (217 tests, 0 errores)

### Agregado

#### Configuración Claude Code
- `ClaudeCodeConfig` - Configuración centralizada para Claude Code
  - Modelos: opus, sonnet, haiku
  - Herramientas MCP de Dart
  - Parámetros para Task tool
  - Generación de frontmatter YAML

#### Sistema de Invocación Multi-Agente
- `AgentInvoker` - Invoca agentes con el modelo correcto (opus/sonnet/haiku)
- `AgentInvocation` - Representa una invocación lista para ejecutar
- Soporte para invocaciones paralelas y pipelines secuenciales
- Protocolo de invocación documentado en `dforchestrator.md`

#### Agentes
- Agente `dfspec` - Crear/analizar especificaciones (antes solo command)
- Agente `dfstatus` - Estado del proyecto (antes solo command)
- Campo `model` en frontmatter YAML (opus, sonnet, haiku)

### Eliminado

- `AiPlatformRegistry` - Registry de 17 plataformas
- `AiPlatformConfig` - Configuración por plataforma
- `TomlCommandGenerator` - Generador formato TOML
- `CommandFormat` enum - Ya no necesario
- `CommandGenerator` factory pattern - Reemplazado por `ClaudeCommandGenerator`
- Tests de plataformas múltiples

### Documentación
- README.md actualizado para arquitectura Claude-first
- Reconocimiento a spec-kit agregado en README y ACKNOWLEDGMENTS.md
- Documentación de metodología SDD actualizada

## [0.1.0] - 2024-12-06

### Agregado

#### CLI Core
- Comando `dfspec init` - Inicializa proyecto con estructura DFSpec
- Comando `dfspec install` - Instala slash commands en `.claude/commands/`
- Comando `dfspec generate` - Genera especificaciones desde templates
- Comando `dfspec agents` - Lista y consulta agentes disponibles
- `DfspecCommandRunner` - Orquestador de comandos CLI

#### Slash Commands (13)
- `/df-spec` - Crear/analizar especificaciones de features
- `/df-plan` - Generar plan de implementacion
- `/df-implement` - Implementar con TDD estricto
- `/df-verify` - Verificar implementacion vs spec
- `/df-status` - Estado del proyecto
- `/df-test` - Testing (unit, widget, integration)
- `/df-review` - Revision SOLID y Clean Architecture
- `/df-security` - Analisis OWASP Mobile Top 10
- `/df-performance` - Optimizacion 60fps
- `/df-quality` - Complejidad y code smells
- `/df-docs` - Documentacion Effective Dart
- `/df-deps` - Gestion de dependencias
- `/df-orchestrate` - Pipeline de agentes

#### Agentes (13)
- `dforchestrator` - Coordinacion de agentes
- `dfplanner` - Arquitecto de soluciones
- `dfimplementer` - Desarrollador TDD
- `dftest` - Especialista en testing
- `dfverifier` - Auditor de completitud
- `dfsolid` - Guardian SOLID
- `dfsecurity` - Guardian de seguridad
- `dfperformance` - Auditor de performance
- `dfcodequality` - Analista de calidad
- `dfdocumentation` - Documentacion
- `dfdependencies` - Gestion de dependencias
- `dfspec` - Analista de especificaciones
- `dfstatus` - Monitor de estado

#### Generadores
- `SpecGenerator` - Motor de generacion de especificaciones
- 6 tipos de template: feature, architecture, security, performance, api, plan

#### Modelos
- `DfspecConfig` - Configuracion del proyecto
- `SpecTemplate` - Template de especificacion
- `AgentConfig` - Configuracion de agente
- `AgentRegistry` - Registro de agentes

#### Utilidades
- `FileUtils` - Operaciones de archivos
- `Logger` - Logger con colores ANSI
- `DfspecException` - Excepciones personalizadas

#### Documentacion
- `README.md` - Guia principal
- `CLAUDE.md` - Instrucciones para Claude Code
- `docs/spec-driven-flutter.md` - Metodologia SDD
- `memory/constitution.md` - Principios inmutables
- Templates de especificaciones

### Inspiracion

Este proyecto esta inspirado en [spec-kit](https://github.com/github/spec-kit) de GitHub, adaptado especificamente para el ecosistema Dart/Flutter.
