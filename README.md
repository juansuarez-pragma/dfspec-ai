# DFSpec

**Spec-Driven Development para Dart/Flutter**

[![Dart](https://img.shields.io/badge/Dart-%5E3.10.1-blue)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-Compatible-02569B)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Ready-orange)](https://claude.ai/code)

DFSpec es un toolkit que implementa **Spec-Driven Development (SDD)** especializado para proyectos Dart y Flutter. Transforma especificaciones en implementaciones de alta calidad siguiendo TDD estricto y Clean Architecture.

> *"Las especificaciones no sirven al código—el código sirve a las especificaciones."*

## Tabla de Contenidos

- [Que es Spec-Driven Development?](#que-es-spec-driven-development)
- [Inicio Rapido](#inicio-rapido)
- [Comandos](#comandos)
- [Flujo de Trabajo](#flujo-de-trabajo)
- [Agentes Especializados](#agentes-especializados)
- [Principios](#principios)
- [Documentacion](#documentacion)
- [Contribuir](#contribuir)

## Que es Spec-Driven Development?

SDD invierte el desarrollo tradicional: **las especificaciones son la fuente primaria de verdad**, no el código.

| Tradicional | Spec-Driven |
|-------------|-------------|
| Escribir código → documentar después | Especificar → generar código |
| Documentación desactualizada | Spec siempre sincronizada |
| Debugging en código | Debugging en especificación |
| Cambios manuales propagados | Regeneración sistemática |

**DFSpec** adapta esta metodología específicamente para el ecosistema **Dart/Flutter**, integrando:

- **Clean Architecture** como patrón obligatorio
- **TDD estricto** (Red → Green → Refactor)
- **State Management** (Riverpod, BLoC, Provider)
- **11 agentes especializados** para cada fase del desarrollo
- **Herramientas MCP** de Dart integradas

## Inicio Rapido

### Prerequisitos

- [Claude Code](https://claude.ai/code) instalado
- Dart SDK 3.10.1+
- Flutter SDK (para proyectos Flutter)
- Git

### Instalacion

```bash
# 1. Clonar el repositorio
git clone https://github.com/juansuarez-pragma/dfspec-ai.git

# 2. Abrir Claude Code en tu proyecto Flutter/Dart
cd tu-proyecto-flutter
claude

# 3. Los comandos /df-* estan disponibles automaticamente
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

DFSpec proporciona **13 comandos slash** para Claude Code:

### Comandos Core (Flujo Principal)

| Comando | Descripcion | Genera |
|---------|-------------|--------|
| `/df-spec <feature>` | Crear especificacion de feature | `specs/feature.spec.md` |
| `/df-plan <feature>` | Generar plan de implementacion | `specs/feature.plan.md` |
| `/df-implement <feature>` | Implementar con TDD estricto | `lib/`, `test/` |
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

# Genera: docs/specs/features/weather-api.spec.md
# - Requisitos funcionales (RF-01, RF-02...)
# - Requisitos no funcionales
# - Criterios de aceptacion
# - Informacion de API

# 2. Planificar implementacion
/df-plan weather-api

# Genera: docs/specs/plans/weather-api.plan.md
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

DFSpec incluye **11 agentes** especializados en diferentes aspectos del desarrollo Flutter:

| Agente | Rol | Capacidades |
|--------|-----|-------------|
| **dfplanner** | Arquitecto | Diseño de features, arquitectura, state management |
| **dfimplementer** | Desarrollador | TDD estricto, BLoC, Riverpod, Provider |
| **dftest** | QA | Tests unitarios, widget, integracion, golden |
| **dfverifier** | Auditor | Verificacion spec vs implementacion |
| **dfsolid** | Guardian SOLID | Validar principios SOLID, DRY, YAGNI |
| **dfsecurity** | Seguridad | OWASP Mobile Top 10, Platform Channels |
| **dfperformance** | Performance | 60fps, widget rebuilds, memory leaks |
| **dfcodequality** | Calidad | Complejidad ciclomatica/cognitiva |
| **dfdocumentation** | Documentacion | Effective Dart, README |
| **dfdependencies** | Dependencias | pub.dev, slopsquatting, deprecaciones |
| **dforchestrator** | Coordinador | Pipelines de agentes |

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

## Documentacion

- [Spec-Driven Development para Flutter](docs/spec-driven-flutter.md)
- [Guia de Inicio](docs/getting-started.md)
- [Referencia de Comandos](docs/commands/)
- [Documentacion de Agentes](docs/agents/)
- [Arquitectura y Patrones](docs/architecture/)
- [Ejemplos](docs/examples/)

## Contribuir

Las contribuciones son bienvenidas! Por favor lee [CONTRIBUTING.md](CONTRIBUTING.md) antes de enviar un PR.

### Desarrollo Local

```bash
# Clonar
git clone https://github.com/juansuarez-pragma/dfspec-ai.git
cd dfspec-ai

# Instalar dependencias
dart pub get

# Ejecutar tests
dart test

# Analisis estatico
dart analyze
```

## Licencia

MIT License - ver [LICENSE](LICENSE) para detalles.

---

Construido con Claude Code | Inspirado por [spec-kit](https://github.com/github/spec-kit)
