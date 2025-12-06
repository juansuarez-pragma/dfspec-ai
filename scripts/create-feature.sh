#!/usr/bin/env bash
# Create a new feature with branch and spec structure
# Usage: ./create-feature.sh [OPTIONS] <description>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

#==============================================================================
# Parse Arguments
#==============================================================================

JSON_MODE=false
SHORT_NAME=""
BRANCH_NUMBER=""
NO_BRANCH=false
ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            JSON_MODE=true
            shift
            ;;
        --name)
            SHORT_NAME="$2"
            shift 2
            ;;
        --number)
            BRANCH_NUMBER="$2"
            shift 2
            ;;
        --no-branch)
            NO_BRANCH=true
            shift
            ;;
        --help|-h)
            cat <<EOF
Usage: $0 [OPTIONS] <feature_description>

Create a new feature with branch and spec structure.

OPTIONS:
  --json              Output in JSON format
  --name <name>       Custom short name for branch (2-4 words)
  --number <N>        Specify feature number manually
  --no-branch         Don't create git branch
  --help, -h          Show this help

EXAMPLES:
  $0 "Add user authentication"
  $0 --name "auth-oauth" "Implement OAuth2 authentication"
  $0 --number 5 --json "My feature"
EOF
            exit 0
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

FEATURE_DESCRIPTION="${ARGS[*]}"
if [[ -z "$FEATURE_DESCRIPTION" ]]; then
    log_error "Feature description required"
    echo "Usage: $0 [OPTIONS] <feature_description>" >&2
    exit 1
fi

#==============================================================================
# Setup
#==============================================================================

REPO_ROOT=$(get_repo_root)

if ! check_dart_project "$REPO_ROOT"; then
    log_error "Not a Dart project (pubspec.yaml not found)"
    exit 1
fi

cd "$REPO_ROOT"

SPECS_DIR="$REPO_ROOT/specs"
mkdir -p "$SPECS_DIR"

HAS_GIT=false
if has_git; then
    HAS_GIT=true
fi

#==============================================================================
# Generate Branch Name
#==============================================================================

generate_short_name() {
    local desc="$1"
    local stop_words="^(i|a|an|the|to|for|of|in|on|at|by|with|from|is|are|was|were|be|been|have|has|had|do|does|will|would|should|could|can|may|must|this|that|my|your|our|want|need|add|get|set|crear|implementar|agregar|para|con|del|los|las|una|uno)$"

    local clean=$(echo "$desc" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]/ /g')
    local words=()

    for word in $clean; do
        [[ -z "$word" ]] && continue
        if ! echo "$word" | grep -qiE "$stop_words"; then
            if [[ ${#word} -ge 3 ]]; then
                words+=("$word")
            fi
        fi
    done

    local result=""
    local count=0
    local max=3
    [[ ${#words[@]} -eq 4 ]] && max=4

    for word in "${words[@]}"; do
        [[ $count -ge $max ]] && break
        [[ -n "$result" ]] && result="$result-"
        result="$result$word"
        ((count++))
    done

    echo "$result"
}

if [[ -n "$SHORT_NAME" ]]; then
    BRANCH_SUFFIX=$(clean_branch_name "$SHORT_NAME")
else
    BRANCH_SUFFIX=$(generate_short_name "$FEATURE_DESCRIPTION")
fi

if [[ -z "$BRANCH_SUFFIX" ]]; then
    BRANCH_SUFFIX=$(clean_branch_name "$FEATURE_DESCRIPTION" | cut -d'-' -f1-3)
fi

#==============================================================================
# Determine Feature Number
#==============================================================================

if [[ -z "$BRANCH_NUMBER" ]]; then
    HIGHEST_SPEC=$(get_highest_feature_number "$SPECS_DIR")

    if [[ "$HAS_GIT" == "true" ]]; then
        git fetch --all --prune 2>/dev/null || true
        HIGHEST_BRANCH=$(get_highest_from_branches)

        if [[ $HIGHEST_BRANCH -gt $HIGHEST_SPEC ]]; then
            BRANCH_NUMBER=$((HIGHEST_BRANCH + 1))
        else
            BRANCH_NUMBER=$((HIGHEST_SPEC + 1))
        fi
    else
        BRANCH_NUMBER=$((HIGHEST_SPEC + 1))
    fi
fi

FEATURE_NUM=$(printf "%03d" "$((10#$BRANCH_NUMBER))")
BRANCH_NAME="${FEATURE_NUM}-${BRANCH_SUFFIX}"

#==============================================================================
# Create Branch
#==============================================================================

if [[ "$HAS_GIT" == "true" && "$NO_BRANCH" == "false" ]]; then
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME" 2>/dev/null; then
        log_warning "Branch $BRANCH_NAME already exists, switching to it"
        git checkout "$BRANCH_NAME"
    else
        git checkout -b "$BRANCH_NAME"
    fi
else
    if [[ "$NO_BRANCH" == "false" ]]; then
        log_warning "Git not available, skipping branch creation"
    fi
fi

#==============================================================================
# Create Feature Structure
#==============================================================================

FEATURE_DIR="$SPECS_DIR/$BRANCH_NAME"
mkdir -p "$FEATURE_DIR"

SPEC_FILE="$FEATURE_DIR/spec.md"
PLAN_FILE="$FEATURE_DIR/plan.md"
TASKS_FILE="$FEATURE_DIR/tasks.md"

# Copy spec template if exists
TEMPLATE="$REPO_ROOT/templates/specs/feature.spec.md"
if [[ -f "$TEMPLATE" ]]; then
    cp "$TEMPLATE" "$SPEC_FILE"
else
    cat > "$SPEC_FILE" <<EOF
# Especificacion: $FEATURE_DESCRIPTION

## Metadata
- Feature ID: FEAT-$FEATURE_NUM
- Branch: $BRANCH_NAME
- Estado: draft
- Fecha: $(date +%Y-%m-%d)

## Resumen
$FEATURE_DESCRIPTION

## Requisitos Funcionales

### RF-01: [Nombre del requisito]
- Descripcion:
- Input:
- Output:

## Requisitos No Funcionales

### RNF-01: Performance
- Tiempo de respuesta < 100ms

## Criterios de Aceptacion

- [ ] **CA-01:** DADO [contexto] CUANDO [accion] ENTONCES [resultado]

## Dependencias

## Notas Tecnicas
EOF
fi

# Create empty plan and tasks files
touch "$PLAN_FILE"
touch "$TASKS_FILE"

# Set environment variable
export DFSPEC_FEATURE="$BRANCH_NAME"

#==============================================================================
# Output
#==============================================================================

if $JSON_MODE; then
    cat <<EOF
{"BRANCH_NAME":"$BRANCH_NAME","FEATURE_DIR":"$FEATURE_DIR","SPEC_FILE":"$SPEC_FILE","FEATURE_NUM":"$FEATURE_NUM","PROJECT_TYPE":"$(get_project_type)"}
EOF
else
    log_success "Feature created: $BRANCH_NAME"
    echo ""
    echo "BRANCH_NAME: $BRANCH_NAME"
    echo "FEATURE_DIR: $FEATURE_DIR"
    echo "SPEC_FILE: $SPEC_FILE"
    echo "FEATURE_NUM: $FEATURE_NUM"
    echo "PROJECT_TYPE: $(get_project_type)"
    echo ""
    log_info "Next: Edit $SPEC_FILE or run /df-spec"
fi
