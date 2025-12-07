#!/usr/bin/env bash
# ==============================================================================
# DFSpec - Funciones Comunes
# ==============================================================================
# Funciones compartidas por todos los scripts de DFSpec.
# Este archivo debe ser sourced, no ejecutado directamente.
#
# Uso: source "$(dirname "$0")/common.sh"
# ==============================================================================

set -euo pipefail

# ==============================================================================
# CONSTANTES
# ==============================================================================

readonly DFSPEC_VERSION="0.1.0"
readonly DFSPEC_CONFIG_FILE="dfspec.yaml"
readonly DFSPEC_DIR=".dfspec"
readonly SPECS_DIR="specs"
readonly FEATURES_DIR="specs/features"
readonly PLANS_DIR="specs/plans"
readonly CLAUDE_COMMANDS_DIR=".claude/commands"

# Colores ANSI
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

# ==============================================================================
# UTILIDADES DE OUTPUT
# ==============================================================================

# Imprime mensaje de error y sale
# Uso: die "mensaje de error"
die() {
    echo -e "${RED}ERROR:${RESET} $1" >&2
    exit 1
}

# Imprime mensaje de warning
# Uso: warn "mensaje de advertencia"
warn() {
    echo -e "${YELLOW}WARNING:${RESET} $1" >&2
}

# Imprime mensaje de info
# Uso: info "mensaje informativo"
info() {
    echo -e "${BLUE}INFO:${RESET} $1" >&2
}

# Imprime mensaje de éxito
# Uso: success "mensaje de éxito"
success() {
    echo -e "${GREEN}✓${RESET} $1" >&2
}

# Imprime mensaje de debug (solo si DEBUG=true)
# Uso: debug "mensaje de debug"
debug() {
    if [[ "${DFSPEC_DEBUG:-false}" == "true" ]]; then
        echo -e "${CYAN}DEBUG:${RESET} $1" >&2
    fi
}

# ==============================================================================
# UTILIDADES JSON
# ==============================================================================

# Genera respuesta JSON de éxito
# Uso: json_success '{"key": "value"}'
json_success() {
    local data="${1:-{}}"
    echo "{\"status\": \"success\", \"data\": $data}"
}

# Genera respuesta JSON de error
# Uso: json_error "mensaje de error" "código"
json_error() {
    local message="$1"
    local code="${2:-UNKNOWN_ERROR}"
    echo "{\"status\": \"error\", \"error\": {\"code\": \"$code\", \"message\": \"$message\"}}"
}

# Escapa string para JSON
# Uso: escaped=$(json_escape "string con \"comillas\"")
json_escape() {
    local string="$1"
    string="${string//\\/\\\\}"
    string="${string//\"/\\\"}"
    string="${string//$'\n'/\\n}"
    string="${string//$'\r'/\\r}"
    string="${string//$'\t'/\\t}"
    echo "$string"
}

# ==============================================================================
# VALIDACIONES
# ==============================================================================

# Verifica si estamos en un repositorio git
# Uso: require_git_repo
require_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        die "No estás en un repositorio git"
    fi
}

# Verifica si existe dfspec.yaml
# Uso: require_dfspec_config
require_dfspec_config() {
    if [[ ! -f "$DFSPEC_CONFIG_FILE" ]]; then
        die "No se encontró $DFSPEC_CONFIG_FILE. Ejecuta 'dfspec init' primero."
    fi
}

# Verifica si existe un directorio
# Uso: require_directory "path/to/dir" "Descripción"
require_directory() {
    local dir="$1"
    local description="${2:-directorio}"
    if [[ ! -d "$dir" ]]; then
        die "No se encontró $description: $dir"
    fi
}

# Verifica si existe un archivo
# Uso: require_file "path/to/file" "Descripción"
require_file() {
    local file="$1"
    local description="${2:-archivo}"
    if [[ ! -f "$file" ]]; then
        die "No se encontró $description: $file"
    fi
}

# Verifica si un comando está disponible
# Uso: require_command "git" "Git"
require_command() {
    local cmd="$1"
    local name="${2:-$cmd}"
    if ! command -v "$cmd" &> /dev/null; then
        die "$name no está instalado o no está en el PATH"
    fi
}

# ==============================================================================
# GIT UTILITIES
# ==============================================================================

# Obtiene el nombre de la rama actual
# Uso: branch=$(get_current_branch)
get_current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null || echo ""
}

# Obtiene la raíz del repositorio git
# Uso: root=$(get_git_root)
get_git_root() {
    git rev-parse --show-toplevel 2>/dev/null || echo ""
}

# Verifica si hay cambios sin commitear
# Uso: if has_uncommitted_changes; then ...
has_uncommitted_changes() {
    [[ -n "$(git status --porcelain 2>/dev/null)" ]]
}

# Lista todas las ramas remotas
# Uso: branches=$(list_remote_branches)
list_remote_branches() {
    git ls-remote --heads origin 2>/dev/null | awk '{print $2}' | sed 's|refs/heads/||'
}

# Lista todas las ramas locales
# Uso: branches=$(list_local_branches)
list_local_branches() {
    git branch --format='%(refname:short)' 2>/dev/null
}

# ==============================================================================
# FEATURE UTILITIES
# ==============================================================================

# Extrae el número de feature de un nombre de branch
# Uso: num=$(extract_feature_number "001-auth-feature")
extract_feature_number() {
    local branch="$1"
    echo "$branch" | grep -oE '^[0-9]+' || echo ""
}

# Genera el siguiente número de feature disponible
# Uso: next=$(get_next_feature_number)
get_next_feature_number() {
    local max_num=0
    local num

    # Buscar en ramas locales
    while IFS= read -r branch; do
        num=$(extract_feature_number "$branch")
        if [[ -n "$num" ]] && [[ "$num" =~ ^[0-9]+$ ]]; then
            num=$((10#$num))  # Forzar base 10
            if [[ $num -gt $max_num ]]; then
                max_num=$num
            fi
        fi
    done < <(list_local_branches)

    # Buscar en ramas remotas
    while IFS= read -r branch; do
        num=$(extract_feature_number "$branch")
        if [[ -n "$num" ]] && [[ "$num" =~ ^[0-9]+$ ]]; then
            num=$((10#$num))
            if [[ $num -gt $max_num ]]; then
                max_num=$num
            fi
        fi
    done < <(list_remote_branches)

    # Buscar en directorios de features existentes
    if [[ -d "$FEATURES_DIR" ]]; then
        for dir in "$FEATURES_DIR"/*; do
            if [[ -d "$dir" ]]; then
                num=$(extract_feature_number "$(basename "$dir")")
                if [[ -n "$num" ]] && [[ "$num" =~ ^[0-9]+$ ]]; then
                    num=$((10#$num))
                    if [[ $num -gt $max_num ]]; then
                        max_num=$num
                    fi
                fi
            fi
        done
    fi

    printf "%03d" $((max_num + 1))
}

# Formatea nombre de feature (kebab-case)
# Uso: name=$(format_feature_name "Mi Feature Name")
format_feature_name() {
    local name="$1"
    echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//'
}

# Detecta la feature actual desde el branch
# Uso: feature=$(detect_current_feature)
detect_current_feature() {
    # Primero verificar variable de entorno
    if [[ -n "${DFSPEC_FEATURE:-}" ]]; then
        echo "$DFSPEC_FEATURE"
        return
    fi

    # Luego intentar desde el branch actual
    local branch
    branch=$(get_current_branch)

    if [[ -n "$branch" ]] && [[ "$branch" =~ ^[0-9]+-.*$ ]]; then
        echo "$branch"
        return
    fi

    echo ""
}

# ==============================================================================
# PATH UTILITIES
# ==============================================================================

# Obtiene paths de una feature
# Uso: eval "$(get_feature_paths "001-auth")"
# Disponibles: FEATURE_DIR, SPEC_PATH, PLAN_PATH, TASKS_PATH
get_feature_paths() {
    local feature_id="$1"
    local feature_dir="$FEATURES_DIR/$feature_id"

    echo "FEATURE_DIR=\"$feature_dir\""
    echo "SPEC_PATH=\"$feature_dir/spec.md\""
    echo "PLAN_PATH=\"$PLANS_DIR/$feature_id.plan.md\""
    echo "TASKS_PATH=\"$feature_dir/tasks.md\""
    echo "RESEARCH_PATH=\"$feature_dir/research.md\""
    echo "CHECKLIST_PATH=\"$feature_dir/checklist.md\""
}

# Lista documentos disponibles para una feature
# Uso: docs=$(list_feature_docs "001-auth")
list_feature_docs() {
    local feature_id="$1"
    local feature_dir="$FEATURES_DIR/$feature_id"
    local docs=()

    [[ -f "$feature_dir/spec.md" ]] && docs+=("spec.md")
    [[ -f "$PLANS_DIR/$feature_id.plan.md" ]] && docs+=("plan.md")
    [[ -f "$feature_dir/tasks.md" ]] && docs+=("tasks.md")
    [[ -f "$feature_dir/research.md" ]] && docs+=("research.md")
    [[ -f "$feature_dir/checklist.md" ]] && docs+=("checklist.md")
    [[ -f "$feature_dir/data-model.md" ]] && docs+=("data-model.md")

    printf '%s\n' "${docs[@]}"
}

# ==============================================================================
# YAML UTILITIES (básico, sin dependencias externas)
# ==============================================================================

# Lee un valor simple de dfspec.yaml
# Uso: value=$(yaml_get_value "project_name")
yaml_get_value() {
    local key="$1"
    local file="${2:-$DFSPEC_CONFIG_FILE}"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    grep "^$key:" "$file" | head -1 | sed "s/^$key:[[:space:]]*//" | sed 's/^"//' | sed 's/"$//' | sed "s/^'//" | sed "s/'$//"
}

# ==============================================================================
# INITIALIZATION CHECK
# ==============================================================================

# Verifica que common.sh fue sourced correctamente
_dfspec_common_loaded=true
