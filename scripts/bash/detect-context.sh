#!/usr/bin/env bash
# ==============================================================================
# DFSpec - Detect Context
# ==============================================================================
# Detecta el contexto completo del proyecto DFSpec incluyendo:
# - Estado del repositorio git
# - Feature actual y su estado
# - Documentos disponibles
# - Configuración del proyecto
# - Estado de quality gates
#
# Uso:
#   ./detect-context.sh [opciones]
#
# Opciones:
#   --json              Salida en formato JSON (default)
#   --summary           Salida resumida para humanos
#   --feature=NAME      Especificar feature (override auto-detección)
#   --include-content   Incluir contenido de spec/plan en salida
#   --help              Mostrar ayuda
#
# Salida JSON:
#   {
#     "status": "success",
#     "data": {
#       "project": { ... },
#       "git": { ... },
#       "feature": { ... },
#       "documents": { ... },
#       "quality": { ... }
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
OUTPUT_SUMMARY=false
FEATURE_OVERRIDE=""
INCLUDE_CONTENT=false

# ==============================================================================
# PARSING DE ARGUMENTOS
# ==============================================================================

show_help() {
    cat << 'EOF'
DFSpec - Detect Context

Detecta el contexto completo del proyecto DFSpec.

USO:
    ./detect-context.sh [opciones]

OPCIONES:
    --json              Salida en formato JSON (default)
    --summary           Salida resumida legible
    --feature=NAME      Especificar feature (override auto-detección)
    --include-content   Incluir contenido de documentos
    --help              Mostrar esta ayuda

EJEMPLOS:
    # Detectar contexto completo
    ./detect-context.sh --json

    # Ver resumen legible
    ./detect-context.sh --summary

    # Contexto de feature específica
    ./detect-context.sh --feature=001-auth --include-content

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
                OUTPUT_SUMMARY=false
                shift
                ;;
            --summary)
                OUTPUT_SUMMARY=true
                OUTPUT_JSON=false
                shift
                ;;
            --feature=*)
                FEATURE_OVERRIDE="${1#*=}"
                shift
                ;;
            --include-content)
                INCLUDE_CONTENT=true
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
# FUNCIONES DE DETECCIÓN
# ==============================================================================

detect_project_info() {
    local project_name=""
    local project_type=""
    local state_management=""

    if [[ -f "$DFSPEC_CONFIG_FILE" ]]; then
        project_name=$(yaml_get_value "project_name" || yaml_get_value "name" || echo "")
        project_type=$(yaml_get_value "type" || echo "")
        state_management=$(yaml_get_value "state_management" || echo "")
    fi

    # Si no hay dfspec.yaml, intentar desde pubspec.yaml
    if [[ -z "$project_name" ]] && [[ -f "pubspec.yaml" ]]; then
        project_name=$(yaml_get_value "name" "pubspec.yaml" || echo "")
    fi

    cat << EOF
    "name": "$(json_escape "$project_name")",
    "type": "$(json_escape "$project_type")",
    "state_management": "$(json_escape "$state_management")",
    "has_dfspec_config": $(if [[ -f "$DFSPEC_CONFIG_FILE" ]]; then echo "true"; else echo "false"; fi),
    "has_pubspec": $(if [[ -f "pubspec.yaml" ]]; then echo "true"; else echo "false"; fi),
    "has_constitution": $(if [[ -f "memory/constitution.md" ]]; then echo "true"; else echo "false"; fi)
EOF
}

detect_git_info() {
    local is_git_repo=false
    local current_branch=""
    local git_root=""
    local has_uncommitted=false
    local remote_url=""

    if git rev-parse --git-dir > /dev/null 2>&1; then
        is_git_repo=true
        current_branch=$(get_current_branch)
        git_root=$(get_git_root)
        has_uncommitted=$(if has_uncommitted_changes; then echo "true"; else echo "false"; fi)
        remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    fi

    cat << EOF
    "is_git_repo": $is_git_repo,
    "current_branch": "$(json_escape "$current_branch")",
    "git_root": "$(json_escape "$git_root")",
    "has_uncommitted_changes": $has_uncommitted,
    "remote_url": "$(json_escape "$remote_url")"
EOF
}

detect_feature_info() {
    local feature_id=""
    local feature_number=""
    local feature_name=""
    local feature_status="none"

    # Determinar feature
    if [[ -n "$FEATURE_OVERRIDE" ]]; then
        feature_id="$FEATURE_OVERRIDE"
    else
        feature_id=$(detect_current_feature)
    fi

    if [[ -n "$feature_id" ]]; then
        feature_number=$(extract_feature_number "$feature_id")
        feature_name="${feature_id#*-}"  # Remover número del inicio

        # Determinar estado
        local spec_exists=false
        local plan_exists=false
        local tasks_exists=false

        [[ -f "$FEATURES_DIR/$feature_id/spec.md" ]] && spec_exists=true
        [[ -f "$PLANS_DIR/$feature_id.plan.md" ]] && plan_exists=true
        [[ -f "$FEATURES_DIR/$feature_id/tasks.md" ]] && tasks_exists=true

        if [[ "$tasks_exists" == true ]]; then
            feature_status="ready_to_implement"
        elif [[ "$plan_exists" == true ]]; then
            feature_status="planned"
        elif [[ "$spec_exists" == true ]]; then
            feature_status="specified"
        else
            feature_status="new"
        fi
    fi

    cat << EOF
    "id": "$(json_escape "$feature_id")",
    "number": "$(json_escape "$feature_number")",
    "name": "$(json_escape "$feature_name")",
    "status": "$(json_escape "$feature_status")",
    "next_available_number": "$(get_next_feature_number)"
EOF
}

detect_documents_info() {
    local feature_id="$1"
    local spec_path=""
    local plan_path=""
    local tasks_path=""
    local research_path=""
    local checklist_path=""

    if [[ -n "$feature_id" ]]; then
        spec_path="$FEATURES_DIR/$feature_id/spec.md"
        plan_path="$PLANS_DIR/$feature_id.plan.md"
        tasks_path="$FEATURES_DIR/$feature_id/tasks.md"
        research_path="$FEATURES_DIR/$feature_id/research.md"
        checklist_path="$FEATURES_DIR/$feature_id/checklist.md"
    fi

    # Construir lista de documentos disponibles
    local docs_json="["
    local first=true

    if [[ -n "$feature_id" ]]; then
        if [[ -f "$spec_path" ]]; then
            [[ "$first" != true ]] && docs_json+=","
            docs_json+="\"spec.md\""
            first=false
        fi
        if [[ -f "$plan_path" ]]; then
            [[ "$first" != true ]] && docs_json+=","
            docs_json+="\"plan.md\""
            first=false
        fi
        if [[ -f "$tasks_path" ]]; then
            [[ "$first" != true ]] && docs_json+=","
            docs_json+="\"tasks.md\""
            first=false
        fi
        if [[ -f "$research_path" ]]; then
            [[ "$first" != true ]] && docs_json+=","
            docs_json+="\"research.md\""
            first=false
        fi
        if [[ -f "$checklist_path" ]]; then
            [[ "$first" != true ]] && docs_json+=","
            docs_json+="\"checklist.md\""
            first=false
        fi
    fi
    docs_json+="]"

    cat << EOF
    "paths": {
      "spec": "$(json_escape "$spec_path")",
      "plan": "$(json_escape "$plan_path")",
      "tasks": "$(json_escape "$tasks_path")",
      "research": "$(json_escape "$research_path")",
      "checklist": "$(json_escape "$checklist_path")"
    },
    "exists": {
      "spec": $(if [[ -f "$spec_path" ]]; then echo "true"; else echo "false"; fi),
      "plan": $(if [[ -f "$plan_path" ]]; then echo "true"; else echo "false"; fi),
      "tasks": $(if [[ -f "$tasks_path" ]]; then echo "true"; else echo "false"; fi),
      "research": $(if [[ -f "$research_path" ]]; then echo "true"; else echo "false"; fi),
      "checklist": $(if [[ -f "$checklist_path" ]]; then echo "true"; else echo "false"; fi)
    },
    "available": $docs_json
EOF
}

detect_quality_info() {
    local has_tests=false
    local has_lib=false
    local test_count=0
    local lib_count=0

    # Contar archivos
    if [[ -d "test" ]]; then
        has_tests=true
        test_count=$(find test -name "*_test.dart" 2>/dev/null | wc -l | tr -d ' ')
    fi

    if [[ -d "lib" ]]; then
        has_lib=true
        lib_count=$(find lib -name "*.dart" 2>/dev/null | wc -l | tr -d ' ')
    fi

    # Verificar recovery points
    local has_recovery=false
    local recovery_count=0
    if [[ -d ".dfspec/recovery" ]]; then
        has_recovery=true
        recovery_count=$(find .dfspec/recovery -name "*.chain.json" 2>/dev/null | wc -l | tr -d ' ')
    fi

    cat << EOF
    "has_tests": $has_tests,
    "test_file_count": $test_count,
    "has_lib": $has_lib,
    "lib_file_count": $lib_count,
    "has_recovery_points": $has_recovery,
    "recovery_chain_count": $recovery_count
EOF
}

# ==============================================================================
# OUTPUT FUNCTIONS
# ==============================================================================

output_json() {
    local feature_id
    if [[ -n "$FEATURE_OVERRIDE" ]]; then
        feature_id="$FEATURE_OVERRIDE"
    else
        feature_id=$(detect_current_feature)
    fi

    cat << EOF
{
  "status": "success",
  "data": {
    "project": {
$(detect_project_info)
    },
    "git": {
$(detect_git_info)
    },
    "feature": {
$(detect_feature_info)
    },
    "documents": {
$(detect_documents_info "$feature_id")
    },
    "quality": {
$(detect_quality_info)
    }
  }
}
EOF
}

output_summary() {
    local feature_id
    if [[ -n "$FEATURE_OVERRIDE" ]]; then
        feature_id="$FEATURE_OVERRIDE"
    else
        feature_id=$(detect_current_feature)
    fi

    echo -e "${BOLD}DFSpec Context Summary${RESET}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Project
    echo -e "${CYAN}Project:${RESET}"
    if [[ -f "$DFSPEC_CONFIG_FILE" ]]; then
        local name=$(yaml_get_value "project_name" || yaml_get_value "name" || echo "N/A")
        echo "  Name: $name"
        echo "  Config: dfspec.yaml ✓"
    else
        echo "  Config: dfspec.yaml ✗ (run 'dfspec init')"
    fi
    echo ""

    # Git
    echo -e "${CYAN}Git:${RESET}"
    if git rev-parse --git-dir > /dev/null 2>&1; then
        echo "  Branch: $(get_current_branch)"
        if has_uncommitted_changes; then
            echo -e "  Status: ${YELLOW}uncommitted changes${RESET}"
        else
            echo -e "  Status: ${GREEN}clean${RESET}"
        fi
    else
        echo -e "  ${RED}Not a git repository${RESET}"
    fi
    echo ""

    # Feature
    echo -e "${CYAN}Feature:${RESET}"
    if [[ -n "$feature_id" ]]; then
        echo "  ID: $feature_id"
        echo "  Docs:"
        [[ -f "$FEATURES_DIR/$feature_id/spec.md" ]] && echo -e "    ${GREEN}✓${RESET} spec.md"
        [[ -f "$PLANS_DIR/$feature_id.plan.md" ]] && echo -e "    ${GREEN}✓${RESET} plan.md"
        [[ -f "$FEATURES_DIR/$feature_id/tasks.md" ]] && echo -e "    ${GREEN}✓${RESET} tasks.md"
    else
        echo "  No feature detected"
        echo "  Next number: $(get_next_feature_number)"
    fi
    echo ""

    # Quality
    echo -e "${CYAN}Quality:${RESET}"
    if [[ -d "test" ]]; then
        local test_count=$(find test -name "*_test.dart" 2>/dev/null | wc -l | tr -d ' ')
        echo "  Tests: $test_count files"
    fi
    if [[ -d ".dfspec/recovery" ]]; then
        local recovery_count=$(find .dfspec/recovery -name "*.chain.json" 2>/dev/null | wc -l | tr -d ' ')
        echo "  Recovery chains: $recovery_count"
    fi
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    parse_args "$@"

    debug "Detectando contexto..."
    debug "FEATURE_OVERRIDE=$FEATURE_OVERRIDE"
    debug "INCLUDE_CONTENT=$INCLUDE_CONTENT"

    if [[ "$OUTPUT_SUMMARY" == true ]]; then
        output_summary
    else
        output_json
    fi
}

main "$@"
