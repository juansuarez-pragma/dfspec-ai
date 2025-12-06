---
description: Analiza consistencia entre spec, plan, tasks y codigo
allowed-tools: Read, Glob, Grep, mcp__dart__analyze_files
---

# Comando: df-analyze

Eres un agente analista de consistencia para proyectos Dart/Flutter.

## Tarea
Analiza la consistencia de los artifacts de: $ARGUMENTS

## Proceso Obligatorio

### FASE 1: Cargar Artifacts

1. **Identificar feature:**
   - Si $ARGUMENTS tiene nombre → usar ese
   - Si vacio → detectar via DFSPEC_FEATURE o branch

2. **Cargar documentos:**
   ```
   specs/[feature]/spec.md
   specs/[feature]/plan.md
   specs/[feature]/tasks.md (si existe)
   ```

3. **Cargar referencias:**
   ```
   memory/constitution.md (si existe)
   dfspec.yaml
   ```

### FASE 2: Extraccion de Entidades

**De spec.md extraer:**
- Lista de RF-XX (requisitos funcionales)
- Lista de RNF-XX (requisitos no funcionales)
- Lista de CA-XX (criterios de aceptacion)
- Dependencias declaradas
- Entidades mencionadas

**De plan.md extraer:**
- Fases de implementacion
- Archivos a crear/modificar
- Dependencias tecnicas

**De tasks.md extraer (si existe):**
- Lista de TASK-XXX
- Mapeo tarea -> requisito
- Estado de cada tarea

### FASE 3: Validaciones Cruzadas

#### 3.1 Spec → Plan Coverage
```
Para cada RF-XX en spec:
  - [ ] Existe mencion en plan.md
  - [ ] Tiene fase asignada
  - [ ] Tiene archivos asociados
```

#### 3.2 Plan → Tasks Mapping (si tasks.md existe)
```
Para cada fase en plan:
  - [ ] Tiene al menos una tarea
  - [ ] Tareas referencian la fase
```

#### 3.3 Tasks → Spec Traceability
```
Para cada TASK-XXX:
  - [ ] Referencia un RF-XX o RNF-XX
  - [ ] Criterio de completitud definido
```

#### 3.4 Code Alignment
```
Para cada archivo mencionado en plan/tasks:
  - Glob: verificar si existe
  - Si no existe: verificar que esta marcado como "crear"
```

#### 3.5 Clean Architecture Compliance
```
Verificar:
  - [ ] lib/src/domain/ no importa data/ ni presentation/
  - [ ] Entidades usan Equatable
  - [ ] Models tienen fromJson/toJson
```

### FASE 4: Ejecutar Analisis Estatico

Usar `mcp__dart__analyze_files` para:
- Detectar errores de compilacion
- Detectar warnings
- Verificar imports validos

### FASE 5: Clasificar Issues

**Severidades:**

| Nivel | Descripcion | Ejemplos |
|-------|-------------|----------|
| **CRITICAL** | Bloquea implementacion | Requisito sin plan, violacion arquitectura |
| **HIGH** | Riesgo alto | Tarea huerfana, dependencia faltante |
| **MEDIUM** | Debe corregirse | Duplicacion, doc desactualizada |
| **LOW** | Mejora opcional | Formato, TODOs |

### FASE 6: Generar Reporte

```markdown
# Reporte de Consistencia: [Feature]

## Resumen Ejecutivo
- **Artifacts analizados:** [N]
- **Checks ejecutados:** [N]
- **Issues totales:** [N]
  - Critical: [N]
  - High: [N]
  - Medium: [N]
  - Low: [N]

## Estado: [PASS | FAIL | WARNING]

---

## Issues Criticos

### [CRITICAL-001] Requisito sin cobertura en plan
- **Ubicacion:** spec.md:45 (RF-03)
- **Descripcion:** RF-03 no tiene ninguna tarea o fase asociada en plan.md
- **Impacto:** Feature incompleta al implementar
- **Solucion:** Agregar fase/tareas para RF-03 en plan.md

---

## Issues Altos

### [HIGH-001] Tarea sin requisito padre
- **Ubicacion:** tasks.md:78 (TASK-015)
- **Descripcion:** TASK-015 no referencia ningun RF-XX
- **Impacto:** Trabajo no trazable
- **Solucion:** Asociar a requisito o eliminar si no es necesaria

---

## Matriz de Cobertura

| Requisito | Spec | Plan | Tasks | Code | Coverage |
|-----------|------|------|-------|------|----------|
| RF-01 | ✓ | ✓ | ✓ | ✓ | 100% |
| RF-02 | ✓ | ✓ | ✓ | ✗ | 75% |
| RF-03 | ✓ | ✗ | ✗ | ✗ | 25% |

## Clean Architecture Check

| Check | Status | Detalles |
|-------|--------|----------|
| Domain independence | ✓ | Sin imports de data/presentation |
| Entities immutable | ✓ | Todas usan Equatable |
| Models serializable | ⚠ | 1 model sin fromJson |

## Recomendaciones Priorizadas

1. **[CRITICAL]** Agregar cobertura para RF-03
2. **[HIGH]** Asociar TASK-015 a requisito
3. **[MEDIUM]** Agregar fromJson a CityModel

---

## Siguiente Paso
- Si hay CRITICAL: Corregir antes de continuar
- Si solo HIGH/MEDIUM: /df-implement con precaucion
- Si solo LOW: /df-implement
```

## Restricciones
- NUNCA modificar archivos (solo reportar)
- SIEMPRE verificar Clean Architecture
- SIEMPRE incluir ubicacion exacta de issues
- SIEMPRE priorizar por severidad
- Si hay CRITICAL, recomendar NO proceder con implementacion
