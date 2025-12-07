#!/usr/bin/env bash
# ==============================================================================
# DFSpec - Validate Spec
# ==============================================================================
# Valida la calidad de una especificación detectando:
# - Marcadores [NEEDS CLARIFICATION] sin resolver
# - Secciones vacías o incompletas
# - User Stories sin criterios de aceptación
# - Requisitos sin criterios verificables
# - Ambigüedades comunes
#
# Uso:
#   ./validate-spec.sh [opciones]
#
# Opciones:
#   --json              Salida en formato JSON (default)
#   --feature=NAME      Especificar feature (override auto-detección)
#   --strict            Modo estricto (falla con warnings)
#   --help              Mostrar ayuda
#
# Salida JSON:
#   {
#     "status": "success",
#     "data": {
#       "feature_id": "001-auth",
#       "spec_path": "...",
#       "validation": {
#         "passed": true,
#         "score": 85,
#         "findings": [...]
#       }
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
FEATURE_OVERRIDE=""
STRICT_MODE=false

# Patrones de detección
NEEDS_CLARIFICATION_PATTERN='\[NEEDS CLARIFICATION\]'
TODO_PATTERN='\[TODO\]|\[TBD\]|\[PENDING\]|TODO:|FIXME:'
VAGUE_ADJECTIVES='simple|fácil|rápido|eficiente|robusto|escalable|flexible|intuitivo|amigable|moderno'
EMPTY_SECTION_PATTERN='^\s*$'
PLACEHOLDER_PATTERN='\[.*\]|\.\.\.|xxx|TBD|N/A'

# ==============================================================================
# PARSING DE ARGUMENTOS
# ==============================================================================

show_help() {
    cat << 'EOF'
DFSpec - Validate Spec

Valida la calidad de una especificación.

USO:
    ./validate-spec.sh [opciones]

OPCIONES:
    --json              Salida en formato JSON (default)
    --feature=NAME      Especificar feature (override auto-detección)
    --strict            Modo estricto (falla con warnings)
    --help              Mostrar esta ayuda

VALIDACIONES:
    1. Marcadores [NEEDS CLARIFICATION] sin resolver
    2. Secciones vacías o incompletas
    3. User Stories sin criterios de aceptación
    4. Requisitos sin criterios verificables
    5. Adjetivos vagos sin métricas
    6. Placeholders sin completar
    7. TODOs pendientes

SEVERIDADES:
    - CRITICAL: Bloquea implementación
    - WARNING: Debería resolverse
    - INFO: Sugerencia de mejora

EJEMPLOS:
    # Validar feature actual
    ./validate-spec.sh --json

    # Validar feature específica en modo estricto
    ./validate-spec.sh --feature=001-auth --strict
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                OUTPUT_JSON=true
                shift
                ;;
            --feature=*)
                FEATURE_OVERRIDE="${1#*=}"
                shift
                ;;
            --strict)
                STRICT_MODE=true
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
# FUNCIONES DE VALIDACIÓN
# ==============================================================================

# Arrays para almacenar findings
declare -a FINDINGS_CRITICAL
declare -a FINDINGS_WARNING
declare -a FINDINGS_INFO

add_finding() {
    local severity="$1"
    local code="$2"
    local message="$3"
    local line="${4:-0}"

    local finding="{\"severity\": \"$severity\", \"code\": \"$code\", \"message\": \"$(json_escape "$message")\", \"line\": $line}"

    case "$severity" in
        CRITICAL)
            FINDINGS_CRITICAL+=("$finding")
            ;;
        WARNING)
            FINDINGS_WARNING+=("$finding")
            ;;
        INFO)
            FINDINGS_INFO+=("$finding")
            ;;
    esac
}

check_needs_clarification() {
    local spec_path="$1"
    local count
    local line_numbers

    count=$(grep -c -E "$NEEDS_CLARIFICATION_PATTERN" "$spec_path" 2>/dev/null || echo "0")

    if [[ "$count" -gt 0 ]]; then
        line_numbers=$(grep -n -E "$NEEDS_CLARIFICATION_PATTERN" "$spec_path" | head -5 | cut -d: -f1 | tr '\n' ',' | sed 's/,$//')
        add_finding "CRITICAL" "SPEC001" "Encontrados $count marcadores [NEEDS CLARIFICATION] sin resolver (líneas: $line_numbers)" 0
    fi
}

check_todos() {
    local spec_path="$1"
    local count

    count=$(grep -c -E "$TODO_PATTERN" "$spec_path" 2>/dev/null || echo "0")

    if [[ "$count" -gt 0 ]]; then
        add_finding "WARNING" "SPEC002" "Encontrados $count marcadores TODO/TBD/PENDING sin resolver" 0
    fi
}

check_vague_adjectives() {
    local spec_path="$1"
    local matches

    matches=$(grep -o -E -i "\b($VAGUE_ADJECTIVES)\b" "$spec_path" 2>/dev/null | sort | uniq -c | sort -rn | head -5)

    if [[ -n "$matches" ]]; then
        local adjective_list
        adjective_list=$(echo "$matches" | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//')
        add_finding "WARNING" "SPEC003" "Adjetivos vagos sin métricas: $adjective_list. Considera agregar criterios medibles." 0
    fi
}

check_empty_sections() {
    local spec_path="$1"
    local in_section=false
    local section_name=""
    local section_start=0
    local line_num=0
    local empty_count=0

    while IFS= read -r line; do
        ((line_num++))

        # Detectar inicio de sección
        if [[ "$line" =~ ^##[[:space:]] ]]; then
            # Si estábamos en una sección y estaba vacía
            if [[ "$in_section" == true ]] && [[ "$empty_count" -gt 3 ]]; then
                add_finding "WARNING" "SPEC004" "Sección '$section_name' parece estar vacía o incompleta" "$section_start"
            fi

            section_name="${line#\#\# }"
            section_start=$line_num
            in_section=true
            empty_count=0
        elif [[ "$in_section" == true ]]; then
            # Contar líneas vacías o con solo placeholders
            if [[ -z "${line// /}" ]] || [[ "$line" =~ $PLACEHOLDER_PATTERN ]]; then
                ((empty_count++))
            else
                empty_count=0
            fi
        fi
    done < "$spec_path"
}

check_user_stories() {
    local spec_path="$1"
    local us_count
    local ac_count

    # Contar User Stories
    us_count=$(grep -c -E "^###[[:space:]]+US-[0-9]+" "$spec_path" 2>/dev/null || echo "0")

    # Contar criterios de aceptación
    ac_count=$(grep -c -E "(DADO|CUANDO|ENTONCES|Given|When|Then)" "$spec_path" 2>/dev/null || echo "0")

    if [[ "$us_count" -gt 0 ]] && [[ "$ac_count" -eq 0 ]]; then
        add_finding "CRITICAL" "SPEC005" "User Stories sin criterios de aceptación (DADO/CUANDO/ENTONCES)" 0
    elif [[ "$us_count" -gt 0 ]] && [[ "$ac_count" -lt "$us_count" ]]; then
        add_finding "WARNING" "SPEC006" "Algunas User Stories pueden carecer de criterios de aceptación completos" 0
    fi

    if [[ "$us_count" -eq 0 ]]; then
        add_finding "INFO" "SPEC007" "No se encontraron User Stories formales (US-XX)" 0
    fi
}

check_requirements() {
    local spec_path="$1"
    local fr_count
    local testable_count

    # Contar requisitos funcionales
    fr_count=$(grep -c -E "^###[[:space:]]+FR-[0-9]+" "$spec_path" 2>/dev/null || echo "0")

    # Contar requisitos con criterios testeables
    testable_count=$(grep -c -E "Criterios de Aceptación:|Acceptance Criteria:" "$spec_path" 2>/dev/null || echo "0")

    if [[ "$fr_count" -gt 0 ]] && [[ "$testable_count" -lt "$fr_count" ]]; then
        add_finding "WARNING" "SPEC008" "Algunos requisitos funcionales carecen de criterios de aceptación explícitos" 0
    fi

    if [[ "$fr_count" -eq 0 ]]; then
        add_finding "INFO" "SPEC009" "No se encontraron requisitos funcionales formales (FR-XX)" 0
    fi
}

check_success_criteria() {
    local spec_path="$1"

    if ! grep -q -E "Criterios de Éxito|Success Criteria|Métricas" "$spec_path" 2>/dev/null; then
        add_finding "WARNING" "SPEC010" "No se encontró sección de Criterios de Éxito/Métricas" 0
    fi
}

check_out_of_scope() {
    local spec_path="$1"

    if ! grep -q -E "Fuera de Alcance|Out of Scope|No incluye" "$spec_path" 2>/dev/null; then
        add_finding "INFO" "SPEC011" "Considera agregar sección 'Fuera de Alcance' para delimitar el scope" 0
    fi
}

check_domain_entities() {
    local spec_path="$1"

    if ! grep -q -E "class.*extends Equatable|Entidades del Dominio|Domain Entities" "$spec_path" 2>/dev/null; then
        add_finding "INFO" "SPEC012" "Considera documentar las entidades del dominio en la especificación" 0
    fi
}

calculate_score() {
    local critical_count=${#FINDINGS_CRITICAL[@]}
    local warning_count=${#FINDINGS_WARNING[@]}
    local info_count=${#FINDINGS_INFO[@]}

    # Score base 100, restar por findings
    local score=100
    score=$((score - critical_count * 20))
    score=$((score - warning_count * 5))
    score=$((score - info_count * 1))

    # Mínimo 0
    if [[ $score -lt 0 ]]; then
        score=0
    fi

    echo "$score"
}

# ==============================================================================
# OUTPUT
# ==============================================================================

output_result() {
    local feature_id="$1"
    local spec_path="$2"

    local critical_count=${#FINDINGS_CRITICAL[@]}
    local warning_count=${#FINDINGS_WARNING[@]}
    local info_count=${#FINDINGS_INFO[@]}

    local score
    score=$(calculate_score)

    local passed="true"
    if [[ "$critical_count" -gt 0 ]]; then
        passed="false"
    elif [[ "$STRICT_MODE" == true ]] && [[ "$warning_count" -gt 0 ]]; then
        passed="false"
    fi

    # Construir array de findings
    local all_findings="["
    local first=true

    for finding in "${FINDINGS_CRITICAL[@]:-}"; do
        [[ -z "$finding" ]] && continue
        [[ "$first" != true ]] && all_findings+=","
        all_findings+="$finding"
        first=false
    done

    for finding in "${FINDINGS_WARNING[@]:-}"; do
        [[ -z "$finding" ]] && continue
        [[ "$first" != true ]] && all_findings+=","
        all_findings+="$finding"
        first=false
    done

    for finding in "${FINDINGS_INFO[@]:-}"; do
        [[ -z "$finding" ]] && continue
        [[ "$first" != true ]] && all_findings+=","
        all_findings+="$finding"
        first=false
    done

    all_findings+="]"

    cat << EOF
{
  "status": "success",
  "data": {
    "feature_id": "$(json_escape "$feature_id")",
    "spec_path": "$(json_escape "$spec_path")",
    "validation": {
      "passed": $passed,
      "score": $score,
      "counts": {
        "critical": $critical_count,
        "warning": $warning_count,
        "info": $info_count
      },
      "findings": $all_findings
    }
  }
}
EOF
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    parse_args "$@"

    # Inicializar arrays
    FINDINGS_CRITICAL=()
    FINDINGS_WARNING=()
    FINDINGS_INFO=()

    # Detectar feature
    local feature_id
    if [[ -n "$FEATURE_OVERRIDE" ]]; then
        feature_id="$FEATURE_OVERRIDE"
    else
        feature_id=$(detect_current_feature)
    fi

    if [[ -z "$feature_id" ]]; then
        json_error "No se detectó feature actual. Usa --feature=NAME" "NO_FEATURE"
        exit 1
    fi

    local spec_path="$FEATURES_DIR/$feature_id/spec.md"

    if [[ ! -f "$spec_path" ]]; then
        json_error "No se encontró spec.md: $spec_path" "SPEC_NOT_FOUND"
        exit 1
    fi

    debug "Validando spec: $spec_path"

    # Ejecutar validaciones
    check_needs_clarification "$spec_path"
    check_todos "$spec_path"
    check_vague_adjectives "$spec_path"
    check_empty_sections "$spec_path"
    check_user_stories "$spec_path"
    check_requirements "$spec_path"
    check_success_criteria "$spec_path"
    check_out_of_scope "$spec_path"
    check_domain_entities "$spec_path"

    # Output
    output_result "$feature_id" "$spec_path"

    # Exit code basado en resultado
    local critical_count=${#FINDINGS_CRITICAL[@]}
    local warning_count=${#FINDINGS_WARNING[@]}

    if [[ "$critical_count" -gt 0 ]]; then
        exit 1
    elif [[ "$STRICT_MODE" == true ]] && [[ "$warning_count" -gt 0 ]]; then
        exit 1
    fi

    exit 0
}

main "$@"
