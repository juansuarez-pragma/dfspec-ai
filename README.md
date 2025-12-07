# DFSpec

**Spec-Driven Development para Dart/Flutter con Claude Code**

[![CI](https://github.com/juansuarez-pragma/dfspec-ai/actions/workflows/ci.yml/badge.svg)](https://github.com/juansuarez-pragma/dfspec-ai/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/juansuarez-pragma/dfspec-ai/branch/main/graph/badge.svg)](https://codecov.io/gh/juansuarez-pragma/dfspec-ai)
[![Dart](https://img.shields.io/badge/Dart-%5E3.10.1-blue)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-Compatible-02569B)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Optimizado-purple)](https://claude.ai/code)

DFSpec es un toolkit que implementa **Spec-Driven Development (SDD)** especializado para proyectos Dart y Flutter. Transforma especificaciones en implementaciones de alta calidad siguiendo TDD estricto y Clean Architecture.

Optimizado para **Claude Code** con soporte completo para modelos opus, sonnet y haiku.

> *"Las especificaciones no sirven al codigo—el codigo sirve a las especificaciones."*

## Tabla de Contenidos

- [Que es Spec-Driven Development?](#que-es-spec-driven-development)
- [Arquitectura](#arquitectura)
- [Inicio Rapido](#inicio-rapido)
- [Comandos](#comandos)
- [Flujo de Trabajo](#flujo-de-trabajo)
- [Agentes Especializados](#agentes-especializados)
- [Principios](#principios)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Documentacion](#documentacion)
- [Contribuir](#contribuir)
- [Reconocimientos](#reconocimientos)

## Que es Spec-Driven Development?

SDD invierte el desarrollo tradicional: **las especificaciones son la fuente primaria de verdad**, no el codigo.

| Tradicional | Spec-Driven |
|-------------|-------------|
| Escribir codigo → documentar despues | Especificar → generar codigo |
| Documentacion desactualizada | Spec siempre sincronizada |
| Debugging en codigo | Debugging en especificacion |
| Cambios manuales propagados | Regeneracion sistematica |

**DFSpec** adapta esta metodologia especificamente para el ecosistema **Dart/Flutter**, integrando:

- **Clean Architecture** como patron obligatorio
- **TDD estricto** (Red -> Green -> Refactor)
- **State Management** (Riverpod, BLoC, Provider)
- **17 agentes especializados** para cada fase del desarrollo
- **Herramientas MCP** de Dart integradas
- **Soporte de modelos** opus, sonnet, haiku

## Arquitectura

DFSpec usa **agentes como fuente unica de verdad**. Cada agente es un archivo Markdown con YAML frontmatter que define su comportamiento:

```
dfspec-ia/
├── agents/                    # Fuente unica de verdad
│   ├── dfspec.md             # Agente para especificaciones
│   ├── dfplanner.md          # Agente para planificacion
│   ├── dfimplementer.md      # Agente para implementacion TDD
│   ├── dftest.md             # Agente para testing
│   ├── dfverifier.md         # Agente para verificacion
│   └── ...                   # 17 agentes especializados
├── lib/src/
│   ├── config/               # Configuracion Claude Code
│   ├── loaders/              # Carga agentes desde archivos
│   ├── parsers/              # Parsea YAML frontmatter
│   ├── invokers/             # Invocacion multi-agente con modelos
│   ├── generators/           # Genera comandos Markdown
│   └── commands/             # CLI commands
└── test/                     # 1033+ tests
```

### Flujo de Datos

```
agents/*.md → AgentLoader → AgentRegistry → CommandTemplate → ClaudeCommandGenerator → .claude/commands/

Para invocacion multi-agente:
agents/*.md → AgentLoader → AgentInvoker → Task(model, prompt) → Claude Code Task tool
```

### Formato de Agente

```yaml
---
name: dfplanner
description: >
  Arquitecto de soluciones especializado en Clean Architecture...
model: opus
tools:
  - Read
  - Write
  - Glob
  - Grep
---

# Agente dfplanner

<role>
Eres un arquitecto de software...
</role>

<responsibilities>
1. ANALIZAR requisitos
2. DISENAR arquitectura
...
</responsibilities>
```

## Inicio Rapido

### Prerequisitos

- **Dart SDK** 3.10.1+ ([Instalar](https://dart.dev/get-dart))
- **Flutter SDK** (para proyectos Flutter) ([Instalar](https://flutter.dev/docs/get-started/install))
- **Git** ([Instalar](https://git-scm.com/downloads))
- **Claude Code** instalado ([Instalar](https://claude.ai/code))

### Instalacion

```bash
# 1. Clonar DFSpec
git clone https://github.com/juansuarez-pragma/dfspec-ai.git
cd dfspec-ai

# 2. Activar el CLI globalmente
dart pub global activate --source path .

# 3. Ir a tu proyecto Flutter/Dart
cd /path/to/tu-proyecto-flutter

# 4. Inicializar DFSpec
dfspec init

# 5. Instalar comandos slash
dfspec install
```

### Resultado

```
tu-proyecto-flutter/
├── .claude/commands/          # Comandos para Claude Code
│   ├── df-spec.md
│   ├── df-plan.md
│   ├── df-implement.md
│   ├── df-test.md
│   ├── df-verify.md
│   └── df-status.md
├── CLAUDE.md                  # Contexto del proyecto
├── dfspec.yaml                # Configuracion del proyecto
└── specs/                     # Especificaciones
    └── features/
```

### Comandos CLI

```bash
# Inicialización y configuración
dfspec init [nombre]           # Inicializar proyecto
dfspec install                 # Instalar comandos esenciales
dfspec install --all           # Instalar todos los comandos
dfspec install --list          # Listar comandos disponibles
dfspec install --force         # Sobrescribir existentes

# Agentes
dfspec agents                  # Listar agentes disponibles
dfspec agents --info=dftest    # Ver detalles de un agente

# Contexto
dfspec context                 # Mostrar contexto del proyecto
dfspec context --json          # Salida JSON estructurada
dfspec context check           # Verificar prerequisitos
dfspec context validate        # Validar spec con score 0-100
dfspec context next            # Siguiente número de feature

# Trazabilidad
dfspec trace <feature>         # Analizar trazabilidad de feature
dfspec trace --all             # Analizar todas las features
dfspec trace <feature> --format=json   # Salida JSON
dfspec trace <feature> --format=matrix # Ver matriz de links
dfspec trace --export=report.html      # Exportar a HTML
dfspec trace --ci              # Modo CI (falla con issues críticos)
dfspec trace --orphans-only    # Solo artefactos huérfanos
dfspec trace --severity=critical       # Filtrar por severidad
```

### Uso Basico

```bash
# Paso 1: Crear especificacion de feature
/df-spec autenticacion-oauth

# Paso 2: Generar plan de implementacion
/df-plan autenticacion-oauth

# Paso 3: Implementar con TDD
/df-implement autenticacion-oauth

# Paso 4: Verificar contra especificacion
/df-verify autenticacion-oauth
```

## Comandos

DFSpec proporciona **19 comandos slash**:

### Comandos Core (Flujo Principal)

| Comando | Descripcion | Genera |
|---------|-------------|--------|
| `/df-spec <feature>` | Crear especificacion de feature | `specs/NNN-feature/spec.md` |
| `/df-clarify` | Clarificar requisitos ambiguos | Updates `spec.md` |
| `/df-plan <feature>` | Generar plan de implementacion | `specs/NNN-feature/plan.md` |
| `/df-analyze` | Analizar consistencia entre artifacts | Reporte de consistencia |
| `/df-tasks` | Generar desglose de tareas | `specs/NNN-feature/tasks.md` |
| `/df-implement <feature>` | Implementar con TDD estricto | `lib/`, `test/` |
| `/df-checklist` | Generar checklist de calidad | `specs/NNN-feature/checklist.md` |
| `/df-verify <feature>` | Verificar implementacion vs spec | Reporte de cumplimiento |
| `/df-status` | Ver estado del proyecto | Dashboard de features |

### Comandos de Calidad

| Comando | Descripcion | Enfoque |
|---------|-------------|---------|
| `/df-test <feature>` | Generar y ejecutar tests | Unit, Widget, Integration |
| `/df-review` | Revisar codigo | SOLID, Clean Architecture |
| `/df-security` | Analisis de seguridad | OWASP Mobile Top 10 |
| `/df-performance` | Optimizar rendimiento | 60fps, memory leaks |
| `/df-quality` | Analisis de calidad | Complejidad, code smells |
| `/df-docs` | Generar documentacion | Effective Dart |
| `/df-deps` | Gestionar dependencias | pub.dev, slopsquatting |
| `/df-orchestrate` | Orquestar multiples agentes | Pipelines complejos |

### Comandos CLI de Servicios

DFSpec expone servicios programáticos a través del CLI:

```bash
# Verificación constitucional
dfspec verify --all                      # Verificar todos los quality gates
dfspec verify --gate=tdd                 # Verificar gate específico
dfspec verify --gate=coverage --threshold=85
dfspec verify --all --ci                 # Modo CI (falla si no pasa)

# Análisis de calidad
dfspec quality analyze                   # Análisis completo
dfspec quality complexity --max=10       # Solo complejidad
dfspec quality docs --threshold=80       # Solo documentación

# Reportes
dfspec report --project                  # Reporte del proyecto
dfspec report --feature=mi-feature       # Reporte de feature
dfspec report --feature=mi-feature --format=json --save

# Documentación
dfspec docs verify --threshold=80        # Verificar cobertura de docs
dfspec docs generate --type=readme --feature=mi-feature

# Cache
dfspec cache stats                       # Ver estadísticas
dfspec cache clear                       # Limpiar cache

# Recovery Points (checkpoints TDD)
dfspec recovery create --feature=mi-feature --component=domain --message="Domain layer complete"
dfspec recovery list --feature=mi-feature
dfspec recovery restore --feature=mi-feature
dfspec recovery report
```

### Scripts de Automatizacion

DFSpec incluye scripts bash que retornan JSON estructurado para automatizacion:

```bash
# Detectar contexto completo del proyecto
./scripts/bash/detect-context.sh --json
# Retorna: project, git, feature, documents, quality

# Verificar prerequisitos para un paso
./scripts/bash/check-prerequisites.sh --json --require-spec --require-plan
# Retorna: feature_id, paths, available_docs

# Crear nueva feature con branch y spec.md
./scripts/bash/create-new-feature.sh "Mi Feature" --json
# Retorna: feature_id (001-mi-feature), branch_name, paths

# Configurar entorno de planificacion
./scripts/bash/setup-plan.sh --json --full
# Retorna: plan.md, research.md, data-model.md, contracts/

# Validar calidad de especificacion
./scripts/bash/validate-spec.sh --json
# Retorna: score (0-100), findings (CRITICAL, WARNING, INFO)
```

**Variables de Entorno:**
```bash
DFSPEC_FEATURE=001-auth    # Override feature actual
DFSPEC_DEBUG=true          # Habilitar debug output
```

**Output JSON Estandar:**
```json
{
  "status": "success",
  "data": {
    "feature_id": "001-mi-feature",
    "paths": {
      "spec": "specs/features/001-mi-feature/spec.md",
      "plan": "specs/plans/001-mi-feature.plan.md"
    }
  }
}
```

## Flujo de Trabajo

```
┌─────────────────────────────────────────────────────────────────┐
│                    DFSpec Workflow                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  /df-spec          ──→  Especificacion                         │
│  (QUE construir)        Requisitos funcionales, API, CA         │
│                                                                 │
│        ↓                                                        │
│                                                                 │
│  /df-plan          ──→  Plan de Implementacion                 │
│  (COMO construir)       Arquitectura, archivos, orden TDD       │
│                                                                 │
│        ↓                                                        │
│                                                                 │
│  /df-implement     ──→  Codigo + Tests                         │
│  (TDD estricto)         Red → Green → Refactor                 │
│                                                                 │
│        ↓                                                        │
│                                                                 │
│  /df-verify        ──→  Validacion                             │
│  (Completitud)          Spec vs Implementacion                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Ejemplo: Implementar Feature de Clima

<details>
<summary>Ver ejemplo completo</summary>

```bash
# 1. Especificar la feature
/df-spec weather-api

# Genera: specs/features/weather-api.spec.md
# - Requisitos funcionales (RF-01, RF-02...)
# - Requisitos no funcionales
# - Criterios de aceptacion
# - Informacion de API

# 2. Planificar implementacion
/df-plan weather-api

# Genera: specs/plans/weather-api.plan.md
# - Diagrama de arquitectura (Mermaid)
# - Lista de archivos a crear
# - Orden de implementacion TDD
# - Checkpoints de validacion

# 3. Implementar con TDD
/df-implement weather-api

# Genera (en orden TDD):
# - test/unit/domain/weather_test.dart (RED)
# - lib/src/domain/entities/weather.dart (GREEN)
# - test/unit/data/weather_model_test.dart (RED)
# - lib/src/data/models/weather_model.dart (GREEN)
# ... y asi sucesivamente

# 4. Verificar completitud
/df-verify weather-api

# Valida:
# - Todos los RF implementados
# - Todos los CA cubiertos por tests
# - Estructura Clean Architecture correcta
# - Tests pasando
```

</details>

## Agentes Especializados

DFSpec incluye **17 agentes** especializados definidos en la carpeta `agents/`:

### Agentes Core (Flujo Principal)

| Agente | Comando | Modelo | Rol |
|--------|---------|--------|-----|
| **dfspec** | `/df-spec` | opus | Especificador de requisitos |
| **dfclarifier** | `/df-clarify` | sonnet | Clarificador de ambiguedades |
| **dfplanner** | `/df-plan` | opus | Arquitecto de soluciones |
| **dfanalyzer** | `/df-analyze` | opus | Analista de consistencia |
| **dftasks** | `/df-tasks` | opus | Generador de tareas |
| **dfimplementer** | `/df-implement` | opus | Desarrollador TDD |
| **dfchecklist** | `/df-checklist` | sonnet | Generador de checklists |
| **dfverifier** | `/df-verify` | opus | Auditor de completitud |
| **dfstatus** | `/df-status` | haiku | Dashboard y metricas |

### Agentes de Calidad

| Agente | Comando | Modelo | Rol |
|--------|---------|--------|-----|
| **dftest** | `/df-test` | opus | Especialista QA |
| **dfsolid** | `/df-review` | opus | Guardian SOLID |
| **dfsecurity** | `/df-security` | opus | Seguridad OWASP |
| **dfperformance** | `/df-performance` | opus | Auditor 60fps |
| **dfcodequality** | `/df-quality` | opus | Analista de calidad |
| **dfdocumentation** | `/df-docs` | opus | Documentacion |
| **dfdependencies** | `/df-deps` | opus | Gestion dependencias |
| **dforchestrator** | `/df-orchestrate` | opus | Coordinador pipelines |

### Invocacion Multi-Agente

Cuando un agente (como `dforchestrator`) necesita invocar a otro agente, usa el sistema de invocacion con el modelo correcto:

```dart
// El orquestador puede invocar dfplanner con su modelo configurado (opus)
final invoker = AgentInvoker();
final invocation = invoker.createInvocation(
  agentId: 'dfplanner',
  task: 'Diseña arquitectura para sistema de favoritos',
  context: {'architecture': 'Clean Architecture'},
);

// Genera parametros para Claude Code Task tool
print(invocation.toTaskToolParams());
// {subagent_type: "general-purpose", model: "opus", prompt: "..."}
```

El `dforchestrator` tiene documentacion detallada sobre como invocar agentes en pipelines secuenciales o paralelos.

### Agregar un Nuevo Agente

Para agregar un nuevo agente, crea un archivo `agents/dfnuevo.md`:

```yaml
---
name: dfnuevo
description: >
  Descripcion del agente...
model: sonnet
tools:
  - Read
  - Write
  - Glob
---

# Agente dfnuevo

<role>
Tu rol aqui...
</role>

<responsibilities>
1. Responsabilidad 1
2. Responsabilidad 2
</responsibilities>
```

Luego ejecuta `dfspec install --force` para regenerar los comandos.

## Principios

DFSpec se basa en principios inmutables definidos en la [Constitucion](memory/constitution.md):

### Clean Architecture (Obligatorio)

```
lib/
├── src/
│   ├── domain/           # Entidades, interfaces, usecases
│   │   ├── entities/     # Clases inmutables con Equatable
│   │   ├── repositories/ # Interfaces abstractas
│   │   └── usecases/     # Logica de negocio
│   ├── data/             # Implementaciones
│   │   ├── models/       # fromJson, toEntity
│   │   ├── datasources/  # Llamadas a API
│   │   └── repositories/ # Implementan interfaces
│   ├── presentation/     # UI
│   │   ├── pages/
│   │   ├── widgets/
│   │   └── providers/    # State management
│   └── core/             # Compartido
│       ├── constants/
│       ├── theme/
│       └── utils/
```

### TDD Estricto

1. **RED**: Escribir test que falla
2. **GREEN**: Escribir codigo minimo para pasar
3. **REFACTOR**: Mejorar sin romper tests

### Umbrales de Calidad

| Metrica | Objetivo |
|---------|----------|
| Cobertura de tests | >85% |
| Complejidad ciclomatica | <10 |
| Complejidad cognitiva | <8 |
| LOC por archivo | <400 |
| Frame budget Flutter | <16ms |

## Estructura del Proyecto

```
dfspec-ia/
├── agents/                    # Definiciones de agentes (fuente de verdad)
│   ├── dfspec.md             # Analista de especificaciones
│   ├── dfplanner.md          # Arquitecto de soluciones
│   ├── dfimplementer.md      # Desarrollador TDD
│   ├── dftest.md             # Especialista QA
│   ├── dfverifier.md         # Auditor de completitud
│   └── ...                   # 17 agentes especializados
├── lib/
│   ├── dfspec.dart           # Barrel export
│   └── src/
│       ├── commands/         # CLI commands (init, install, agents, generate)
│       ├── config/           # Configuracion Claude Code
│       ├── generators/       # Generadores (comandos, specs)
│       ├── invokers/         # Invocacion multi-agente
│       ├── loaders/          # Cargadores de agentes
│       ├── models/           # Modelos (AgentConfig, DfspecConfig)
│       ├── parsers/          # Parsers (YAML frontmatter)
│       ├── templates/        # Templates de artefactos
│       └── utils/            # Utilidades (Logger, FileUtils)
├── templates/                # Templates de especificaciones
│   └── specs/
│       ├── feature.spec.md   # Template de feature
│       └── plan.template.md  # Template de plan
├── docs/                     # Documentacion
│   ├── spec-driven-flutter.md
│   └── plans/                # Planes de implementacion
├── memory/
│   └── constitution.md       # Principios inmutables
├── test/                     # 1033+ tests
├── bin/
│   └── dfspec.dart           # Entry point del CLI
├── pubspec.yaml
├── CHANGELOG.md
├── CLAUDE.md                 # Contexto para Claude Code
└── README.md
```

## Documentacion

- [Spec-Driven Development para Flutter](docs/spec-driven-flutter.md)
- [Constitucion - Principios Inmutables](memory/constitution.md)

## Contribuir

Las contribuciones son bienvenidas! Por favor lee [CONTRIBUTING.md](CONTRIBUTING.md) antes de enviar un PR.

### Desarrollo Local

```bash
# Clonar
git clone https://github.com/juansuarez-pragma/dfspec-ai.git
cd dfspec-ia

# Instalar dependencias
dart pub get

# Ejecutar tests
dart test

# Analisis estatico
dart analyze

# Formatear codigo
dart format .
```

### Ejecutar Tests Especificos

```bash
# Todos los tests
dart test

# Tests de un archivo
dart test test/src/loaders/agent_loader_test.dart

# Tests con nombre
dart test --name "debe cargar"
```

## Reconocimientos

DFSpec esta profundamente inspirado por el trabajo pionero en **Spec-Driven Development**:

### spec-kit

Este proyecto se basa en la metodologia y conceptos introducidos por [**spec-kit**](https://github.com/github/spec-kit), un toolkit open-source de GitHub que hace que las especificaciones sean ejecutables.

> *"Las especificaciones no son solo documentacion—son la fuente de verdad que genera implementaciones."*

**Creditos principales:**
- **[Den Delimarsky](https://github.com/localden)** - Lider del proyecto spec-kit
- **[John Lam](https://github.com/jflam)** - Investigacion y trabajo fundamental en SDD

spec-kit introduce conceptos clave que DFSpec adapta para el ecosistema Dart/Flutter:

| spec-kit | DFSpec |
|----------|--------|
| `/speckit.constitution` | `memory/constitution.md` |
| `/speckit.specify` | `/df-spec` |
| `/speckit.plan` | `/df-plan` |
| `/speckit.tasks` | `/df-tasks` |
| `/speckit.implement` | `/df-implement` |

### Diferencias con spec-kit

Mientras spec-kit es un toolkit general en Python para cualquier lenguaje, DFSpec:

- **Especializa** en Dart/Flutter con soporte nativo
- **Integra** Clean Architecture como patron obligatorio
- **Extiende** con 17 agentes especializados (calidad, seguridad, performance)
- **Incluye** herramientas MCP de Dart para analisis y testing
- **Implementa** recovery points y constitutional gates

### Licencia

spec-kit esta bajo [MIT License](https://github.com/github/spec-kit/blob/main/LICENSE) © GitHub, Inc.

DFSpec es un proyecto independiente que reconoce y agradece la inspiracion metodologica de spec-kit.

## Licencia

MIT License - ver [LICENSE](LICENSE) para detalles.

---

Construido con Claude Code | Inspirado por [spec-kit](https://github.com/github/spec-kit) de GitHub
