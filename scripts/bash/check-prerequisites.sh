#!/usr/bin/env bash
# ==============================================================================
# DFSpec - Check Prerequisites
# ==============================================================================
# Verifica prerequisitos y retorna información del contexto actual.
#
# Uso:
#   ./check-prerequisites.sh [opciones]
#
# Opciones:
#   --json              Salida en formato JSON (default)
#   --paths-only        Solo retornar paths
#   --require-spec      Requiere que exista spec.md
#   --require-plan      Requiere que exista plan.md
#   --require-tasks     Requiere que exista tasks.md
#   --include-tasks     Incluir contenido de tasks.md en salida
#   --feature=NAME      Especificar feature (override auto-detección)
#   --help              Mostrar ayuda
#
# Salida JSON:
#   {
#     "status": "success",
#     "data": {
#       "git_root": "/path/to/repo",
#       "current_branch": "001-feature-name",
#       "feature_id": "001-feature-name",
#       "feature_number": "001",
#       "paths": {
#         "feature_dir": "specs/features/001-feature-name",
#         "spec": "specs/features/001-feature-name/spec.md",
#         "plan": "specs/plans/001-feature-name.plan.md",
#         "tasks": "specs/features/001-feature-name/tasks.md"
#       },
#       "available_docs": ["spec.md", "plan.md"],
#       "dfspec_config": true
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
PATHS_ONLY=false
REQUIRE_SPEC=false
REQUIRE_PLAN=false
REQUIRE_TASKS=false
INCLUDE_TASKS=false
FEATURE_OVERRIDE=""

# ==============================================================================
# PARSING DE ARGUMENTOS
# ==============================================================================

show_help() {
    cat << 'EOF'
DFSpec - Check Prerequisites

Verifica prerequisitos y retorna información del contexto actual.

USO:
    ./check-prerequisites.sh [opciones]

OPCIONES:
    --json              Salida en formato JSON (default)
    --paths-only        Solo retornar paths relevantes
    --require-spec      Falla si no existe spec.md
    --require-plan      Falla si no existe plan.md
    --require-tasks     Falla si no existe tasks.md
    --include-tasks     Incluir contenido de tasks.md en salida
    --feature=NAME      Especificar feature (override auto-detección)
    --help              Mostrar esta ayuda

EJEMPLOS:
    # Verificar contexto básico
    ./check-prerequisites.sh --json

    # Requerir spec y plan existentes
    ./check-prerequisites.sh --require-spec --require-plan

    # Especificar feature manualmente
    ./check-prerequisites.sh --feature=001-auth

VARIABLES DE ENTORNO:
    DFSPEC_FEATURE      Override para feature actual
    DFSPEC_DEBUG        Habilitar debug output (true/false)
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                OUTPUT_JSON=true
                shift
                ;;
            --paths-only)
                PATHS_ONLY=true
                shift
                ;;
            --require-spec)
                REQUIRE_SPEC=true
                shift
                ;;
            --require-plan)
                REQUIRE_PLAN=true
                shift
                ;;
            --require-tasks)
                REQUIRE_TASKS=true
                shift
                ;;
            --include-tasks)
                INCLUDE_TASKS=true
                shift
                ;;
            --feature=*)
                FEATURE_OVERRIDE="${1#*=}"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                die "Opción desconocida: $1. Usa --help para ver opciones."
                ;;
        esac
    done
}

# ==============================================================================
# FUNCIONES PRINCIPALES
# ==============================================================================

check_git() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        json_error "No estás en un repositorio git" "NOT_GIT_REPO"
        exit 1
    fi
}

get_context() {
    local git_root
    local current_branch
    local feature_id
    local feature_number
    local has_dfspec_config

    git_root=$(get_git_root)
    current_branch=$(get_current_branch)

    # Determinar feature
    if [[ -n "$FEATURE_OVERRIDE" ]]; then
        feature_id="$FEATURE_OVERRIDE"
    else
        feature_id=$(detect_current_feature)
    fi

    # Extraer número de feature
    feature_number=$(extract_feature_number "$feature_id")

    # Verificar dfspec.yaml
    if [[ -f "$DFSPEC_CONFIG_FILE" ]]; then
        has_dfspec_config=true
    else
        has_dfspec_config=false
    fi

    # Construir paths
    local feature_dir=""
    local spec_path=""
    local plan_path=""
    local tasks_path=""
    local research_path=""
    local checklist_path=""

    if [[ -n "$feature_id" ]]; then
        feature_dir="$FEATURES_DIR/$feature_id"
        spec_path="$feature_dir/spec.md"
        plan_path="$PLANS_DIR/$feature_id.plan.md"
        tasks_path="$feature_dir/tasks.md"
        research_path="$feature_dir/research.md"
        checklist_path="$feature_dir/checklist.md"
    fi

    # Verificar requisitos
    if [[ "$REQUIRE_SPEC" == true ]] && [[ -n "$spec_path" ]] && [[ ! -f "$spec_path" ]]; then
        json_error "No se encontró spec.md: $spec_path" "SPEC_NOT_FOUND"
        exit 1
    fi

    if [[ "$REQUIRE_PLAN" == true ]] && [[ -n "$plan_path" ]] && [[ ! -f "$plan_path" ]]; then
        json_error "No se encontró plan.md: $plan_path" "PLAN_NOT_FOUND"
        exit 1
    fi

    if [[ "$REQUIRE_TASKS" == true ]] && [[ -n "$tasks_path" ]] && [[ ! -f "$tasks_path" ]]; then
        json_error "No se encontró tasks.md: $tasks_path" "TASKS_NOT_FOUND"
        exit 1
    fi

    # Listar documentos disponibles
    local available_docs="[]"
    if [[ -n "$feature_id" ]]; then
        local docs=()
        [[ -f "$spec_path" ]] && docs+=("\"spec.md\"")
        [[ -f "$plan_path" ]] && docs+=("\"plan.md\"")
        [[ -f "$tasks_path" ]] && docs+=("\"tasks.md\"")
        [[ -f "$research_path" ]] && docs+=("\"research.md\"")
        [[ -f "$checklist_path" ]] && docs+=("\"checklist.md\"")

        if [[ ${#docs[@]} -gt 0 ]]; then
            available_docs="[$(IFS=,; echo "${docs[*]}")]"
        fi
    fi

    # Construir salida JSON
    if [[ "$PATHS_ONLY" == true ]]; then
        cat << EOF
{
  "status": "success",
  "data": {
    "FEATURE_DIR": "$(json_escape "$feature_dir")",
    "FEATURE_SPEC": "$(json_escape "$spec_path")",
    "FEATURE_PLAN": "$(json_escape "$plan_path")",
    "FEATURE_TASKS": "$(json_escape "$tasks_path")",
    "BRANCH_NAME": "$(json_escape "$current_branch")"
  }
}
EOF
    else
        local tasks_content=""
        if [[ "$INCLUDE_TASKS" == true ]] && [[ -f "$tasks_path" ]]; then
            tasks_content=$(json_escape "$(cat "$tasks_path")")
        fi

        cat << EOF
{
  "status": "success",
  "data": {
    "git_root": "$(json_escape "$git_root")",
    "current_branch": "$(json_escape "$current_branch")",
    "feature_id": "$(json_escape "$feature_id")",
    "feature_number": "$(json_escape "$feature_number")",
    "has_dfspec_config": $has_dfspec_config,
    "paths": {
      "feature_dir": "$(json_escape "$feature_dir")",
      "spec": "$(json_escape "$spec_path")",
      "plan": "$(json_escape "$plan_path")",
      "tasks": "$(json_escape "$tasks_path")",
      "research": "$(json_escape "$research_path")",
      "checklist": "$(json_escape "$checklist_path")"
    },
    "available_docs": $available_docs$(if [[ "$INCLUDE_TASKS" == true ]] && [[ -n "$tasks_content" ]]; then echo ",
    \"tasks_content\": \"$tasks_content\""; fi)
  }
}
EOF
    fi
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    parse_args "$@"

    debug "Verificando prerequisitos..."
    debug "PATHS_ONLY=$PATHS_ONLY"
    debug "REQUIRE_SPEC=$REQUIRE_SPEC"
    debug "REQUIRE_PLAN=$REQUIRE_PLAN"
    debug "FEATURE_OVERRIDE=$FEATURE_OVERRIDE"

    check_git
    get_context
}

main "$@"
