#!/usr/bin/env bash
# ==============================================================================
# DFSpec - Create New Feature
# ==============================================================================
# Crea una nueva feature con estructura completa:
# - Directorio en specs/features/
# - Branch git con número auto-incrementado
# - Archivo spec.md inicial desde template
# - Actualiza dfspec.yaml con la nueva feature
#
# Uso:
#   ./create-new-feature.sh <nombre-feature> [opciones]
#
# Opciones:
#   --json              Salida en formato JSON (default)
#   --no-branch         No crear branch git
#   --no-template       No crear spec.md desde template
#   --number=NNN        Especificar número de feature
#   --help              Mostrar ayuda
#
# Salida JSON:
#   {
#     "status": "success",
#     "data": {
#       "feature_id": "001-mi-feature",
#       "feature_number": "001",
#       "feature_name": "mi-feature",
#       "branch_name": "001-mi-feature",
#       "feature_dir": "specs/features/001-mi-feature",
#       "spec_path": "specs/features/001-mi-feature/spec.md",
#       "created": ["directory", "branch", "spec.md"]
#     }
#   }
# ==============================================================================

set -euo pipefail

# Cargar funciones comunes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ==============================================================================
# CONFIGURACIÓN
# ==============================================================================

OUTPUT_JSON=true
CREATE_BRANCH=true
CREATE_TEMPLATE=true
FEATURE_NUMBER=""
FEATURE_NAME=""

# ==============================================================================
# PARSING DE ARGUMENTOS
# ==============================================================================

show_help() {
    cat << 'EOF'
DFSpec - Create New Feature

Crea una nueva feature con estructura completa.

USO:
    ./create-new-feature.sh <nombre-feature> [opciones]

ARGUMENTOS:
    <nombre-feature>    Nombre de la feature (se convertirá a kebab-case)

OPCIONES:
    --json              Salida en formato JSON (default)
    --no-branch         No crear branch git
    --no-template       No crear spec.md desde template
    --number=NNN        Especificar número de feature manualmente
    --help              Mostrar esta ayuda

EJEMPLOS:
    # Crear feature con auto-número
    ./create-new-feature.sh "User Authentication"

    # Crear con número específico
    ./create-new-feature.sh "User Auth" --number=005

    # Solo crear directorio (sin branch ni template)
    ./create-new-feature.sh "Quick Fix" --no-branch --no-template

COMPORTAMIENTO:
    1. Detecta el siguiente número de feature disponible
    2. Crea directorio specs/features/NNN-nombre-feature/
    3. Crea branch git NNN-nombre-feature
    4. Genera spec.md inicial desde template
    5. Actualiza dfspec.yaml con la nueva feature
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                OUTPUT_JSON=true
                shift
                ;;
            --no-branch)
                CREATE_BRANCH=false
                shift
                ;;
            --no-template)
                CREATE_TEMPLATE=false
                shift
                ;;
            --number=*)
                FEATURE_NUMBER="${1#*=}"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            -*)
                die "Opción desconocida: $1. Usa --help para ver opciones."
                ;;
            *)
                if [[ -z "$FEATURE_NAME" ]]; then
                    FEATURE_NAME="$1"
                else
                    die "Solo se espera un nombre de feature. Usa comillas para nombres con espacios."
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$FEATURE_NAME" ]]; then
        die "Se requiere el nombre de la feature. Uso: ./create-new-feature.sh <nombre>"
    fi
}

# ==============================================================================
# FUNCIONES PRINCIPALES
# ==============================================================================

create_feature_directory() {
    local feature_id="$1"
    local feature_dir="$FEATURES_DIR/$feature_id"

    if [[ -d "$feature_dir" ]]; then
        warn "El directorio ya existe: $feature_dir"
        return 1
    fi

    mkdir -p "$feature_dir"
    debug "Directorio creado: $feature_dir"
    return 0
}

create_git_branch() {
    local branch_name="$1"

    # Verificar que estamos en un repo git
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        warn "No estás en un repositorio git, omitiendo creación de branch"
        return 1
    fi

    # Verificar si el branch ya existe
    if git show-ref --verify --quiet "refs/heads/$branch_name" 2>/dev/null; then
        warn "El branch ya existe: $branch_name"
        return 1
    fi

    # Crear y cambiar al nuevo branch
    git checkout -b "$branch_name" > /dev/null 2>&1
    debug "Branch creado: $branch_name"
    return 0
}

create_spec_template() {
    local feature_id="$1"
    local feature_name="$2"
    local feature_number="$3"
    local spec_path="$FEATURES_DIR/$feature_id/spec.md"

    if [[ -f "$spec_path" ]]; then
        warn "El archivo spec.md ya existe: $spec_path"
        return 1
    fi

    # Obtener fecha actual
    local current_date
    current_date=$(date +%Y-%m-%d)

    # Crear spec.md desde template
    cat > "$spec_path" << EOF
# Feature Specification: ${feature_name}

## Metadata

| Campo | Valor |
|-------|-------|
| Feature ID | ${feature_number} |
| Título | ${feature_name} |
| Fecha | ${current_date} |
| Estado | Draft |
| Autor | [AUTOR] |

---

## Resumen Ejecutivo

[Descripción breve de 2-3 oraciones sobre qué hace esta feature y por qué es importante]

---

## User Stories

### US-01: [Título de la Historia]

**Como** [rol de usuario]
**Quiero** [acción o funcionalidad]
**Para** [beneficio o valor que obtiene]

**Prioridad:** P1 | P2 | P3

**Criterios de Aceptación:**

- [ ] **DADO** [contexto inicial]
      **CUANDO** [acción del usuario]
      **ENTONCES** [resultado esperado]

- [ ] **DADO** [contexto inicial]
      **CUANDO** [acción del usuario]
      **ENTONCES** [resultado esperado]

---

## Requisitos Funcionales

### FR-001: [Nombre del Requisito]

**Descripción:** [Descripción clara del requisito]

**Criterios de Aceptación:**
- [ ] [Criterio verificable 1]
- [ ] [Criterio verificable 2]

**User Stories relacionadas:** US-01

---

## Requisitos No Funcionales

### NFR-001: Performance

- Frame budget: <16ms (60fps)
- Tiempo de respuesta: <200ms para operaciones de red

### NFR-002: Seguridad

- [Requisitos de seguridad específicos]

---

## Entidades del Dominio

\`\`\`dart
/// [Descripción de la entidad]
class [NombreEntidad] extends Equatable {
  const [NombreEntidad]({
    required this.id,
    // ... otros campos
  });

  final String id;
  // ... otros campos

  @override
  List<Object?> get props => [id];
}
\`\`\`

---

## Casos de Borde

| Caso | Comportamiento Esperado |
|------|------------------------|
| [Descripción del caso] | [Cómo debe responder el sistema] |

---

## Criterios de Éxito

| Métrica | Objetivo | Medición |
|---------|----------|----------|
| [Métrica 1] | [Valor objetivo] | [Cómo se medirá] |

---

## Fuera de Alcance

- [Funcionalidad explícitamente NO incluida]

---

## Dependencias

- [ ] [Dependencia 1]
- [ ] [Dependencia 2]

---

## Notas de Clarificación

> [NEEDS CLARIFICATION] Área que requiere clarificación con el cliente/stakeholder

---

## Matriz de Trazabilidad

| User Story | Requisitos | Tests |
|------------|------------|-------|
| US-01 | FR-001 | [Pendiente] |

---

## Definition of Done (DoD)

- [ ] Todos los criterios de aceptación verificados
- [ ] Tests unitarios con cobertura >85%
- [ ] Tests de widget para UI components
- [ ] Documentación API actualizada
- [ ] Code review aprobado
- [ ] Sin errores de linting
- [ ] Performance validada (<16ms frame budget)

---

## Validation Checklist

### Content Quality
- [ ] Sin detalles de implementación
- [ ] Enfocado en valor de usuario
- [ ] Escrito para stakeholders no técnicos

### Requirement Completeness
- [ ] Sin marcadores [NEEDS CLARIFICATION]
- [ ] Requisitos testeables y sin ambigüedad
- [ ] Criterios de éxito medibles
- [ ] Todos los escenarios de aceptación definidos
- [ ] Casos de borde identificados

### Feature Readiness
- [ ] Todos los FR tienen criterios de aceptación
- [ ] User stories cubren flujos principales
- [ ] Scope claramente delimitado
EOF

    debug "Spec creado: $spec_path"
    return 0
}

update_dfspec_config() {
    local feature_id="$1"
    local feature_name="$2"

    if [[ ! -f "$DFSPEC_CONFIG_FILE" ]]; then
        debug "dfspec.yaml no existe, omitiendo actualización"
        return 1
    fi

    # Verificar si la feature ya existe en el config
    if grep -q "^  $feature_id:" "$DFSPEC_CONFIG_FILE" 2>/dev/null; then
        debug "Feature ya existe en dfspec.yaml"
        return 1
    fi

    # Agregar la feature al final del archivo
    # Buscar la sección "features:" y agregar después
    if grep -q "^features:" "$DFSPEC_CONFIG_FILE"; then
        # Crear archivo temporal con la nueva feature
        local temp_file
        temp_file=$(mktemp)

        awk -v feature_id="$feature_id" '
        /^features:/ {
            print
            print "  " feature_id ":"
            print "    status: draft"
            next
        }
        { print }
        ' "$DFSPEC_CONFIG_FILE" > "$temp_file"

        mv "$temp_file" "$DFSPEC_CONFIG_FILE"
        debug "dfspec.yaml actualizado con feature: $feature_id"
        return 0
    else
        debug "Sección 'features:' no encontrada en dfspec.yaml"
        return 1
    fi
}

# ==============================================================================
# OUTPUT
# ==============================================================================

output_result() {
    local feature_id="$1"
    local feature_number="$2"
    local feature_name="$3"
    local branch_name="$4"
    local created_items="$5"

    local feature_dir="$FEATURES_DIR/$feature_id"
    local spec_path="$feature_dir/spec.md"
    local plan_path="$PLANS_DIR/$feature_id.plan.md"

    cat << EOF
{
  "status": "success",
  "data": {
    "feature_id": "$(json_escape "$feature_id")",
    "feature_number": "$(json_escape "$feature_number")",
    "feature_name": "$(json_escape "$feature_name")",
    "branch_name": "$(json_escape "$branch_name")",
    "paths": {
      "feature_dir": "$(json_escape "$feature_dir")",
      "spec": "$(json_escape "$spec_path")",
      "plan": "$(json_escape "$plan_path")"
    },
    "created": [$created_items]
  }
}
EOF
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    parse_args "$@"

    debug "Creando nueva feature: $FEATURE_NAME"

    # Formatear nombre de feature
    local formatted_name
    formatted_name=$(format_feature_name "$FEATURE_NAME")

    # Determinar número de feature
    local feature_number
    if [[ -n "$FEATURE_NUMBER" ]]; then
        feature_number=$(printf "%03d" "$FEATURE_NUMBER")
    else
        feature_number=$(get_next_feature_number)
    fi

    # Construir identificador completo
    local feature_id="${feature_number}-${formatted_name}"
    local branch_name="$feature_id"

    debug "Feature ID: $feature_id"
    debug "Feature Number: $feature_number"

    # Tracking de lo que se creó
    local created_items=""
    local add_comma=false

    # Crear directorio
    if create_feature_directory "$feature_id"; then
        created_items+="\"directory\""
        add_comma=true
    fi

    # Crear branch git
    if [[ "$CREATE_BRANCH" == true ]]; then
        if create_git_branch "$branch_name"; then
            [[ "$add_comma" == true ]] && created_items+=", "
            created_items+="\"branch\""
            add_comma=true
        fi
    fi

    # Crear spec.md
    if [[ "$CREATE_TEMPLATE" == true ]]; then
        if create_spec_template "$feature_id" "$FEATURE_NAME" "$feature_number"; then
            [[ "$add_comma" == true ]] && created_items+=", "
            created_items+="\"spec.md\""
            add_comma=true
        fi
    fi

    # Actualizar dfspec.yaml
    if update_dfspec_config "$feature_id" "$formatted_name"; then
        [[ "$add_comma" == true ]] && created_items+=", "
        created_items+="\"dfspec.yaml\""
    fi

    # Crear directorio de planes si no existe
    mkdir -p "$PLANS_DIR"

    # Output
    output_result "$feature_id" "$feature_number" "$formatted_name" "$branch_name" "$created_items"
}

main "$@"
