---
description: Genera desglose de tareas desde plan de implementacion
allowed-tools: Read, Write, Glob, Grep
---

# Comando: df-tasks

Eres un agente especializado en descomponer planes en tareas ejecutables.

## Tarea
Genera desglose de tareas para: $ARGUMENTS

## Proceso Obligatorio

### FASE 1: Cargar Contexto

1. **Identificar feature:**
   - Si $ARGUMENTS tiene nombre → usar ese
   - Si vacio → detectar via DFSPEC_FEATURE o branch

2. **Validar prerrequisitos:**
   ```bash
   ./scripts/check-prerequisites.sh --json
   ```
   - SPEC_EXISTS debe ser true
   - PLAN_EXISTS debe ser true

3. **Cargar documentos:**
   - Read: specs/[feature]/spec.md
   - Read: specs/[feature]/plan.md

### FASE 2: Extraer Entregables

**De spec.md:**
- Lista todos los RF-XX
- Lista todos los RNF-XX
- Identifica entidades mencionadas

**De plan.md:**
- Extrae fases definidas
- Extrae archivos mencionados
- Identifica dependencias entre fases

### FASE 3: Analizar Estructura Existente

```
Glob: lib/src/**/*.dart → archivos existentes
Glob: test/**/*_test.dart → tests existentes
```

Determinar:
- Que archivos ya existen
- Que archivos deben crearse
- Que archivos deben modificarse

### FASE 4: Generar Tareas

Para cada fase del plan, crear tareas atomicas:

**Reglas de descomposicion:**
1. Una tarea = un entregable concreto
2. Incluir test + codigo en la misma tarea (TDD)
3. Maximo 2 horas por tarea (L)
4. Marcar [P] las paralelizables

**Estructura de tarea:**
```markdown
### TASK-[NNN]: [Titulo descriptivo]
- **Fase:** [N] - [Nombre]
- **Requisito:** RF-XX
- **Complejidad:** S | M | L
- **Parallelizable:** [P] (si aplica)
- **Archivos:**
  - `path/to/file.dart` (crear|modificar)
  - `test/path/to/file_test.dart` (crear)
- **Criterio de completitud:**
  - [ ] Test escrito y falla (RED)
  - [ ] Codigo implementado (GREEN)
  - [ ] dart analyze sin errores
- **Dependencias:** TASK-XXX (si aplica)
```

**Guia de complejidad:**
| Size | Tiempo | Ejemplos |
|------|--------|----------|
| S | 15-30 min | Entidad simple, model, interface |
| M | 30-60 min | Use case, repository impl, widget |
| L | 1-2 hrs | Page completa, datasource, bloc |

### FASE 5: Identificar Paralelizacion

**Pueden ser paralelas [P]:**
- Entidades independientes
- Tests de diferentes modulos
- UI components sin dependencia de datos
- Documentacion

**NO pueden ser paralelas:**
- Repository impl → depende de interface
- Use case → depende de repository
- Widget → depende de provider
- Test → depende de codigo

### FASE 6: Generar Diagrama de Ejecucion

```
TASK-001 ─┬─> TASK-003 ──> TASK-005
          │      [P]
TASK-002 ─┴─> TASK-004 ──> TASK-006
                 [P]
```

### FASE 7: Escribir tasks.md

Crear `specs/[feature]/tasks.md`:

```markdown
# Tasks: [Nombre Feature]

## Metadata
- Feature: [branch]
- Generado: [fecha]
- Total tareas: [N]
- Estimacion: [X]S + [Y]M + [Z]L
- Tareas paralelizables: [N]

## Resumen por Fase

| Fase | Tareas | Paralelas | Complejidad |
|------|--------|-----------|-------------|
| 1. Setup | 2 | 2 | 2S |
| 2. Domain | 4 | 2 | 2S, 2M |
| 3. Data | 3 | 1 | 1S, 1M, 1L |
| 4. Presentation | 4 | 2 | 2M, 2L |
| **Total** | **13** | **7** | **5S, 5M, 3L** |

---

## Fase 1: Setup

### TASK-001: Crear estructura de directorios [P]
- **Requisito:** Setup
- **Complejidad:** S
- **Archivos:**
  - `lib/src/features/[feature]/` (crear)
  - `lib/src/features/[feature]/domain/` (crear)
  - `lib/src/features/[feature]/data/` (crear)
  - `lib/src/features/[feature]/presentation/` (crear)
- **Criterio de completitud:**
  - [ ] Directorios creados
  - [ ] Estructura Clean Architecture

### TASK-002: Agregar dependencias [P]
- **Requisito:** Setup
- **Complejidad:** S
- **Archivos:**
  - `pubspec.yaml` (modificar)
- **Criterio de completitud:**
  - [ ] Dependencias en pubspec.yaml
  - [ ] dart pub get exitoso

---

## Fase 2: Domain Layer

### TASK-003: Crear entidad [Entity] + test
- **Requisito:** RF-01
- **Complejidad:** S
- **Archivos:**
  - `lib/src/domain/entities/[entity].dart` (crear)
  - `test/unit/domain/entities/[entity]_test.dart` (crear)
- **Criterio de completitud:**
  - [ ] Entidad inmutable con Equatable
  - [ ] Test de igualdad pasa
  - [ ] dart analyze OK

...

---

## Orden de Ejecucion

```
Fase 1: TASK-001, TASK-002 [paralelas]
           ↓
Fase 2: TASK-003 ──> TASK-004, TASK-005 [paralelas] ──> TASK-006
           ↓
Fase 3: TASK-007 ──> TASK-008, TASK-009 [paralelas]
           ↓
Fase 4: TASK-010 ──> TASK-011 ──> TASK-012, TASK-013 [paralelas]
```

## Notas
- Seguir TDD: test primero, luego codigo
- Tareas [P] pueden ejecutarse simultaneamente
- Ejecutar `dart analyze` despues de cada tarea
```

## Restricciones
- SIEMPRE seguir TDD (test en cada tarea de codigo)
- SIEMPRE incluir paths completos
- MAXIMO 20 tareas por feature
- NUNCA crear tareas > L (subdividir)
- SIEMPRE mapear a requisitos RF-XX
- SIEMPRE incluir criterio de completitud
