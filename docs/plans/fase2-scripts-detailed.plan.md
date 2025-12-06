# Fase 2: Scripts de Automatización - Plan Detallado

## Análisis de spec-kit

spec-kit tiene 5 scripts principales en Bash:

| Script | Líneas | Función |
|--------|--------|---------|
| `common.sh` | 157 | Funciones compartidas (paths, branch, validaciones) |
| `create-new-feature.sh` | 298 | Crear feature con branch y estructura |
| `setup-plan.sh` | 62 | Inicializar plan desde spec |
| `check-prerequisites.sh` | 167 | Validar prerrequisitos del workflow |
| `update-agent-context.sh` | 800 | Actualizar CLAUDE.md con info del proyecto |

**Total: ~1,484 líneas de Bash**

---

## Diseño para DFSpec

### Principios de Diseño

1. **Solo Bash** (no PowerShell) - Claude Code corre en Unix-like environments
2. **Dart/Flutter específico** - Comandos nativos del ecosistema
3. **Integración con MCP tools** - Usar herramientas disponibles
4. **Simplicidad** - Solo lo necesario, sin over-engineering

### Scripts Propuestos

```
scripts/
├── common.sh                 # Funciones compartidas
├── create-feature.sh         # Crear nueva feature
├── validate-spec.sh          # Validar especificación
├── setup-plan.sh             # Inicializar plan
├── run-quality.sh            # Ejecutar checks de calidad
└── check-prerequisites.sh    # Validar prerrequisitos
```

---

## Script 1: `common.sh`

### Propósito
Funciones compartidas para todos los scripts. Adaptado de spec-kit pero simplificado para Dart/Flutter.

### Funciones

```bash
# Funciones de paths
get_repo_root()           # Obtener raíz del repo
get_current_branch()      # Obtener branch actual o DFSPEC_FEATURE
get_feature_number()      # Extraer número de feature (001, 002, etc.)

# Funciones de validación
has_git()                 # Verificar si es repo git
check_feature_branch()    # Validar formato de branch
check_dart_project()      # Verificar pubspec.yaml existe
check_flutter_project()   # Verificar si es Flutter (flutter: sdk)

# Funciones de paths de feature
get_feature_dir()         # specs/NNN-feature-name/
get_spec_file()           # specs/NNN-feature-name/spec.md
get_plan_file()           # specs/NNN-feature-name/plan.md
get_tasks_file()          # specs/NNN-feature-name/tasks.md

# Funciones de output
log_info()                # INFO: mensaje
log_success()             # ✓ mensaje
log_error()               # ERROR: mensaje (stderr)
log_warning()             # WARNING: mensaje

# Funciones de Dart/Flutter
get_project_type()        # flutter_app | dart_package | cli
get_state_management()    # Detectar riverpod/bloc/provider
run_dart_analyze()        # dart analyze con formato
run_dart_test()           # dart/flutter test
```

### Diferencias con spec-kit

| spec-kit | DFSpec | Razón |
|----------|--------|-------|
| `find_feature_dir_by_prefix()` | Simplificado | Solo Claude, menos casos edge |
| 17 agent paths | Solo CLAUDE.md | Claude-first |
| `get_commands_for_language()` | `get_dart_commands()` | Solo Dart/Flutter |
| PowerShell equivalents | No incluir | Claude Code es Unix |

---

## Script 2: `create-feature.sh`

### Propósito
Crear una nueva feature con estructura completa. Equivalente a `create-new-feature.sh` de spec-kit.

### Uso

```bash
./scripts/create-feature.sh "Implementar autenticación OAuth"
./scripts/create-feature.sh --name "auth-oauth" "Implementar autenticación OAuth"
./scripts/create-feature.sh --number 5 "Mi feature"
./scripts/create-feature.sh --json "Feature description"
```

### Opciones

| Flag | Descripción |
|------|-------------|
| `--json` | Output en formato JSON |
| `--name <name>` | Nombre corto para branch (2-4 palabras) |
| `--number <N>` | Número de feature manual |
| `--no-branch` | No crear branch git |
| `--help` | Mostrar ayuda |

### Flujo

```
1. Parsear argumentos
2. Determinar repo root
3. Calcular siguiente número de feature
   - Revisar specs/ existentes
   - Revisar branches git (local + remote)
   - Tomar el mayor + 1
4. Generar nombre de branch
   - Filtrar stop words
   - Limpiar caracteres especiales
   - Formato: NNN-short-name
5. Crear branch git (si aplica)
6. Crear estructura:
   specs/
   └── NNN-feature-name/
       ├── spec.md        # Copiado de templates/specs/feature.spec.md
       ├── plan.md        # Vacío (se llena con /df-plan)
       └── tasks.md       # Vacío (se llena con /df-tasks)
7. Output resultado
```

### Output JSON

```json
{
  "BRANCH_NAME": "001-auth-oauth",
  "FEATURE_DIR": "/project/specs/001-auth-oauth",
  "SPEC_FILE": "/project/specs/001-auth-oauth/spec.md",
  "FEATURE_NUM": "001"
}
```

### Diferencias con spec-kit

| spec-kit | DFSpec | Razón |
|----------|--------|-------|
| 298 líneas | ~150 líneas | Simplificado |
| GitHub branch limit 244 | Mantener | Buena práctica |
| `SPECIFY_FEATURE` env | `DFSPEC_FEATURE` env | Branding |

---

## Script 3: `validate-spec.sh`

### Propósito
Validar que una especificación cumple con los estándares de calidad. **Nuevo script** - spec-kit no tiene equivalente directo.

### Uso

```bash
./scripts/validate-spec.sh                    # Validar spec de feature actual
./scripts/validate-spec.sh specs/001-auth/    # Validar spec específica
./scripts/validate-spec.sh --json             # Output JSON
```

### Validaciones

```
1. Estructura del archivo
   - [ ] Tiene sección "## Resumen"
   - [ ] Tiene sección "## Requisitos Funcionales"
   - [ ] Tiene sección "## Criterios de Aceptacion"

2. Contenido de requisitos
   - [ ] Al menos 1 requisito funcional (RF-XXX)
   - [ ] Cada RF tiene descripción
   - [ ] No hay más de 3 [NEEDS CLARIFICATION]

3. Criterios de aceptación
   - [ ] Al menos 1 criterio (CA-XXX)
   - [ ] Formato DADO/CUANDO/ENTONCES o Given/When/Then

4. Validaciones Dart/Flutter específicas
   - [ ] Si menciona packages, existen en pub.dev
   - [ ] Si menciona APIs, tiene Base URL
   - [ ] Si es UI, tiene sección de diseño
```

### Output

```
Validating: specs/001-auth-oauth/spec.md

Structure:
  ✓ Has summary section
  ✓ Has functional requirements
  ✓ Has acceptance criteria

Requirements:
  ✓ Found 5 functional requirements
  ✓ All requirements have descriptions
  ⚠ Found 2 [NEEDS CLARIFICATION] items

Acceptance Criteria:
  ✓ Found 8 acceptance criteria
  ✓ All criteria follow Given/When/Then format

Result: PASS (1 warning)
```

### Output JSON

```json
{
  "file": "specs/001-auth-oauth/spec.md",
  "valid": true,
  "warnings": 1,
  "errors": 0,
  "checks": {
    "has_summary": true,
    "has_requirements": true,
    "has_criteria": true,
    "requirements_count": 5,
    "clarifications_count": 2,
    "criteria_count": 8
  }
}
```

---

## Script 4: `setup-plan.sh`

### Propósito
Inicializar plan.md desde spec.md. Equivalente simplificado de spec-kit.

### Uso

```bash
./scripts/setup-plan.sh                # Setup plan para feature actual
./scripts/setup-plan.sh --json         # Output JSON
```

### Flujo

```
1. Validar que existe spec.md
2. Copiar template de plan
3. Extraer info de spec.md:
   - Nombre de feature
   - Requisitos funcionales (para mapear a tareas)
   - Dependencias mencionadas
4. Pre-llenar plan.md con:
   - Metadata (fecha, branch, status)
   - Lista de RFs como placeholders de secciones
5. Output resultado
```

### Output JSON

```json
{
  "FEATURE_SPEC": "/project/specs/001-auth/spec.md",
  "IMPL_PLAN": "/project/specs/001-auth/plan.md",
  "FEATURE_DIR": "/project/specs/001-auth",
  "BRANCH": "001-auth-oauth",
  "REQUIREMENTS_FOUND": 5
}
```

---

## Script 5: `run-quality.sh`

### Propósito
Ejecutar todos los checks de calidad de Dart/Flutter. **Nuevo script** específico para DFSpec.

### Uso

```bash
./scripts/run-quality.sh              # Ejecutar todos los checks
./scripts/run-quality.sh --quick      # Solo analyze y format
./scripts/run-quality.sh --fix        # Aplicar fixes automáticos
./scripts/run-quality.sh --json       # Output JSON
```

### Checks Ejecutados

```
1. dart analyze
   - Errores, warnings, infos
   - Exit code indica severidad

2. dart format --set-exit-if-changed
   - Verificar formato consistente
   - Con --fix: aplicar formato

3. dart test (si hay tests)
   - Ejecutar suite completo
   - Reportar cobertura si disponible

4. Métricas de complejidad (opcional)
   - LOC por archivo
   - Archivos > 400 líneas

5. Dependencias (opcional)
   - dart pub outdated
   - Verificar versiones
```

### Output

```
DFSpec Quality Check
====================

[1/4] Running dart analyze...
  ✓ No issues found

[2/4] Running dart format...
  ✓ All files formatted correctly

[3/4] Running dart test...
  ✓ 217 tests passed

[4/4] Checking dependencies...
  ⚠ 2 packages have updates available

Summary:
  ✓ Analysis: PASS
  ✓ Format: PASS
  ✓ Tests: PASS (217/217)
  ⚠ Dependencies: 2 updates available

Overall: PASS
```

### Output JSON

```json
{
  "analyze": {"passed": true, "errors": 0, "warnings": 0},
  "format": {"passed": true, "files_checked": 47},
  "test": {"passed": true, "total": 217, "passed": 217, "failed": 0},
  "dependencies": {"outdated": 2},
  "overall": "PASS"
}
```

---

## Script 6: `check-prerequisites.sh`

### Propósito
Validar prerrequisitos del workflow. Adaptado de spec-kit.

### Uso

```bash
./scripts/check-prerequisites.sh              # Validar para tasks
./scripts/check-prerequisites.sh --implement  # Validar para implementación
./scripts/check-prerequisites.sh --paths-only # Solo mostrar paths
./scripts/check-prerequisites.sh --json       # Output JSON
```

### Validaciones

```
Para /df-tasks:
  - [ ] Existe spec.md
  - [ ] Existe plan.md

Para /df-implement:
  - [ ] Existe spec.md
  - [ ] Existe plan.md
  - [ ] Existe tasks.md

Para todos:
  - [ ] Es proyecto Dart/Flutter válido
  - [ ] pubspec.yaml existe
  - [ ] dfspec.yaml existe (opcional pero recomendado)
```

### Output JSON

```json
{
  "FEATURE_DIR": "/project/specs/001-auth",
  "SPEC_EXISTS": true,
  "PLAN_EXISTS": true,
  "TASKS_EXISTS": false,
  "IS_DART_PROJECT": true,
  "IS_FLUTTER_PROJECT": true,
  "AVAILABLE_DOCS": ["spec.md", "plan.md"]
}
```

---

## Resumen de Implementación

### Archivos a Crear

| Archivo | Líneas Est. | Prioridad |
|---------|-------------|-----------|
| `scripts/common.sh` | ~120 | Alta |
| `scripts/create-feature.sh` | ~150 | Alta |
| `scripts/validate-spec.sh` | ~100 | Media |
| `scripts/setup-plan.sh` | ~60 | Alta |
| `scripts/run-quality.sh` | ~120 | Media |
| `scripts/check-prerequisites.sh` | ~80 | Alta |
| **Total** | **~630 líneas** | |

### Comparación con spec-kit

| Aspecto | spec-kit | DFSpec |
|---------|----------|--------|
| Scripts | 5 | 6 |
| Líneas totales | ~1,484 | ~630 |
| Soporte PowerShell | Sí | No |
| Agentes soportados | 17 | 1 (Claude) |
| Lenguajes | Genérico | Dart/Flutter |

### Orden de Implementación

1. **`common.sh`** - Base para todos los demás
2. **`create-feature.sh`** - Crear features
3. **`setup-plan.sh`** - Inicializar planes
4. **`check-prerequisites.sh`** - Validar workflow
5. **`validate-spec.sh`** - Validar specs
6. **`run-quality.sh`** - Checks de calidad

---

## Integración con Comandos Slash

Los scripts se invocan desde los comandos slash via frontmatter:

```yaml
# En .claude/commands/df-spec.md
---
description: Crea especificaciones de features siguiendo SDD
scripts:
  sh: scripts/create-feature.sh --json "{ARGS}"
---
```

### Mapping de Scripts a Comandos

| Comando | Script Principal |
|---------|------------------|
| `/df-spec` | `create-feature.sh` |
| `/df-plan` | `setup-plan.sh` |
| `/df-tasks` | `check-prerequisites.sh` |
| `/df-implement` | `check-prerequisites.sh --implement` |
| `/df-verify` | `validate-spec.sh` |
| `/df-quality` | `run-quality.sh` |

---

## Tests para Scripts

Cada script tendrá tests básicos:

```bash
# test/scripts/test-common.sh
test_get_repo_root() {
  result=$(source scripts/common.sh && get_repo_root)
  assert_not_empty "$result"
}

test_check_dart_project() {
  result=$(source scripts/common.sh && check_dart_project)
  assert_equals "0" "$?"
}
```

---

## Próximos Pasos

Una vez aprobado este plan:

1. Implementar `common.sh`
2. Implementar cada script en orden
3. Probar manualmente
4. Integrar con comandos slash
5. Documentar en README

¿Proceder con la implementación?
