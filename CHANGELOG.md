# Changelog

Todos los cambios notables de este proyecto seran documentados en este archivo.

El formato esta basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [Unreleased]

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
- Plan de refactor documentado en `docs/plans/claude-first-refactor.plan.md`
- Preparación para futura extensión multi-plataforma documentada

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
