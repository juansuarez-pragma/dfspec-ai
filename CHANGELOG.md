# Changelog

Todos los cambios notables de este proyecto seran documentados en este archivo.

El formato esta basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [Unreleased]

### Cambiado

#### Arquitectura: Agentes como Single Source of Truth
- **BREAKING**: Los agentes (`agents/*.md`) son ahora la fuente única de verdad
- Eliminado `slash_command_templates.dart` - templates generados dinámicamente
- `AgentLoader` carga definiciones desde archivos markdown con YAML frontmatter
- `AgentParser` parsea frontmatter YAML de agentes
- `CommandTemplate.fromAgent()` genera templates desde definiciones
- `AgentRegistry` refactorizado para usar `AgentLoader`

#### Performance
- `AgentLoader` convertido de async a sync (evita `avoid_slow_async_io`)
- Métodos `listAvailable()`, `load()`, `loadAll()`, `exists()` ahora síncronos

#### Calidad de Código
- Aplicadas cascade invocations en generadores y comandos
- Agregado language specifier a code blocks en documentación
- Resueltas advertencias de linting (235 tests, 0 errores)

### Agregado

#### Sistema de Invocación Multi-Agente
- `AgentInvoker` - Invoca agentes con el modelo correcto (opus/sonnet/haiku)
- `AgentInvocation` - Representa una invocación lista para ejecutar
- Soporte para invocaciones paralelas y pipelines secuenciales
- Protocolo de invocación documentado en `dforchestrator.md`

#### Agentes
- Agente `dfspec` - Crear/analizar especificaciones (antes solo command)
- Agente `dfstatus` - Estado del proyecto (antes solo command)
- Campo `model` en frontmatter YAML (opus, sonnet, haiku)

#### Documentación
- Documentación de arquitectura en README.md
- Diagrama de flujo de datos
- Sección de estructura del proyecto
- Tabla de agentes con modelos recomendados
- Ejemplo de invocación multi-agente

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
