---
description: Genera reportes de estado del proyecto
allowed-tools: Read, Write, Bash, Glob, Grep
---

# Comando: df-report

Eres un generador de reportes para proyectos DFSpec.

## Tarea
Genera reporte de: $ARGUMENTS

## Tipos de Reporte

### 1. Estado del Proyecto (project)
Reporte completo del estado actual del proyecto.

### 2. Feature Especifica (feature=XXX)
Reporte detallado de una feature.

### 3. Trazabilidad (trace)
Matriz de trazabilidad en formato exportable.

### 4. Calidad (quality)
Metricas de calidad de codigo.

### 5. Cobertura (coverage)
Reporte de cobertura de tests.

## Proceso

### 1. Recopilar Datos

```bash
# Contexto del proyecto
dart run dfspec context --json > /tmp/context.json

# Trazabilidad (si aplica)
dart run dfspec trace --all --format=json > /tmp/trace.json

# Metricas de calidad
dart run dfspec quality analyze --format=json > /tmp/quality.json

# Tests
dart test --coverage=coverage
```

### 2. Generar Reporte segun Tipo

#### Reporte de Proyecto

Crear `reports/project-report.md`:

```markdown
# Reporte del Proyecto: [nombre]

**Generado:** [fecha]
**Branch:** [branch actual]

## Resumen Ejecutivo

| Metrica | Valor | Estado |
|---------|-------|--------|
| Features | X total | - |
| Cobertura Tests | XX% | OK/WARN |
| Issues Criticos | X | OK/FAIL |
| Quality Score | XX/100 | OK/WARN |

## Features

| ID | Nombre | Estado | Cobertura |
|----|--------|--------|-----------|
| 001 | auth | implemented | 85% |
| 002 | user | planned | - |

## Trazabilidad

| Tipo | Total | Cubiertos | Huerfanos |
|------|-------|-----------|-----------|
| REQ | X | X | X |
| US | X | X | X |
| AC | X | X | X |
| TASK | X | X | X |
| CODE | X | X | X |
| TEST | X | X | X |

## Issues Pendientes

### Criticos
- [ISSUE-001] Descripcion

### Warnings
- [ISSUE-002] Descripcion

## Recomendaciones

1. Accion recomendada 1
2. Accion recomendada 2
```

#### Reporte de Feature

Crear `reports/feature-[id]-report.md`:

```markdown
# Reporte Feature: [id] - [nombre]

**Estado:** [status]
**Ultima Actualizacion:** [fecha]

## Documentos

- [x] Especificacion (spec.md)
- [x] Plan (plan.md)
- [ ] Tareas (tasks.md)
- [ ] Checklist (checklist.md)

## User Stories

| ID | Titulo | ACs | Implementado |
|----|--------|-----|--------------|
| US-001 | Login | 3 | Si |
| US-002 | Logout | 2 | No |

## Criterios de Aceptacion

| AC | User Story | Estado | Test |
|----|------------|--------|------|
| AC-001 | US-001 | Passed | auth_test.dart:45 |
| AC-002 | US-001 | Pending | - |

## Archivos Implementados

### Domain Layer
- lib/src/domain/entities/user.dart
- lib/src/domain/repositories/auth_repository.dart

### Data Layer
- lib/src/data/models/user_model.dart
- lib/src/data/repositories/auth_repository_impl.dart

### Presentation Layer
- lib/src/presentation/pages/login_page.dart

## Tests

| Archivo | Tests | Passed | Failed |
|---------|-------|--------|--------|
| auth_test.dart | 10 | 10 | 0 |
| user_test.dart | 5 | 5 | 0 |

## Metricas

- Cobertura: XX%
- Complejidad promedio: X
- LOC totales: XXX

## Pendientes

1. [ ] Completar AC-002
2. [ ] Agregar tests de integracion
```

### 3. Formatos de Salida

Soportar multiples formatos:

1. **Markdown** (default)
   - `reports/[tipo]-report.md`

2. **HTML**
   - `reports/[tipo]-report.html`
   - Incluir CSS para visualizacion

3. **JSON**
   - `reports/[tipo]-report.json`
   - Datos estructurados para integracion

4. **PDF** (requiere herramienta externa)
   - Convertir Markdown a PDF

## Comandos CLI

```bash
# Reporte de proyecto
dart run dfspec report --project

# Reporte de feature especifica
dart run dfspec report --feature=001-auth

# Exportar en formato especifico
dart run dfspec report --feature=001-auth --format=html

# Guardar en ubicacion custom
dart run dfspec report --project --output=docs/reports/

# Modo CI (salida JSON a stdout)
dart run dfspec report --project --format=json
```

## Template HTML

Para reportes HTML, usar este template base:

```html
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Reporte DFSpec</title>
  <style>
    body { font-family: system-ui; margin: 2rem; max-width: 1200px; }
    table { border-collapse: collapse; width: 100%; margin: 1rem 0; }
    th, td { border: 1px solid #ddd; padding: 0.75rem; text-align: left; }
    th { background: #f5f5f5; }
    .status-ok { color: #28a745; }
    .status-warn { color: #ffc107; }
    .status-fail { color: #dc3545; }
    .metric { font-size: 2rem; font-weight: bold; }
    .card { border: 1px solid #ddd; border-radius: 8px; padding: 1rem; margin: 1rem 0; }
  </style>
</head>
<body>
  <!-- Contenido del reporte -->
</body>
</html>
```

## Integracion con Trace

Para reportes de trazabilidad, usar:

```bash
# Exportar matriz completa
dart run dfspec trace --all --export=reports/traceability-matrix.html

# Solo issues
dart run dfspec trace --all --issues-only --format=json > reports/issues.json
```

## Output

Al finalizar:
1. Ruta del reporte generado
2. Resumen de metricas clave
3. Issues criticos encontrados (si aplica)
4. Sugerencias de mejora
