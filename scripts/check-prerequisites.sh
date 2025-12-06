#!/usr/bin/env bash
# Validate prerequisites for DFSpec workflow
# Usage: ./check-prerequisites.sh [OPTIONS]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

#==============================================================================
# Parse Arguments
#==============================================================================

JSON_MODE=false
CHECK_IMPLEMENT=false
PATHS_ONLY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            JSON_MODE=true
            shift
            ;;
        --implement)
            CHECK_IMPLEMENT=true
            shift
            ;;
        --paths-only)
            PATHS_ONLY=true
            shift
            ;;
        --help|-h)
            cat <<EOF
Usage: $0 [OPTIONS]

Validate prerequisites for DFSpec workflow commands.

OPTIONS:
  --json        Output in JSON format
  --implement   Check prerequisites for /df-implement (requires tasks.md)
  --paths-only  Only output paths, no validation
  --help, -h    Show this help

EXAMPLES:
  $0                    # Check for /df-tasks
  $0 --implement        # Check for /df-implement
  $0 --json             # JSON output
EOF
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

#==============================================================================
# Setup
#==============================================================================

REPO_ROOT=$(get_repo_root)
CURRENT_BRANCH=$(get_current_branch)
FEATURE_DIR="$REPO_ROOT/specs/$CURRENT_BRANCH"
SPEC_FILE="$FEATURE_DIR/spec.md"
PLAN_FILE="$FEATURE_DIR/plan.md"
TASKS_FILE="$FEATURE_DIR/tasks.md"

IS_DART_PROJECT=false
IS_FLUTTER_PROJECT=false
HAS_GIT=false

check_dart_project "$REPO_ROOT" && IS_DART_PROJECT=true
is_flutter_project "$REPO_ROOT" && IS_FLUTTER_PROJECT=true
has_git && HAS_GIT=true

SPEC_EXISTS=false
PLAN_EXISTS=false
TASKS_EXISTS=false

[[ -f "$SPEC_FILE" ]] && SPEC_EXISTS=true
[[ -f "$PLAN_FILE" ]] && PLAN_EXISTS=true
[[ -f "$TASKS_FILE" ]] && TASKS_EXISTS=true

#==============================================================================
# Paths Only Mode
#==============================================================================

if $PATHS_ONLY; then
    eval "$(get_feature_paths)"
    exit 0
fi

#==============================================================================
# Validation
#==============================================================================

ERRORS=()
WARNINGS=()
AVAILABLE_DOCS=()

# Check Dart project
if [[ "$IS_DART_PROJECT" != "true" ]]; then
    ERRORS+=("Not a Dart project (pubspec.yaml not found)")
fi

# Check feature branch format
if [[ ! "$CURRENT_BRANCH" =~ ^[0-9]{3}- ]]; then
    WARNINGS+=("Not on a feature branch: $CURRENT_BRANCH")
fi

# Check spec exists
if [[ "$SPEC_EXISTS" == "true" ]]; then
    AVAILABLE_DOCS+=("spec.md")
else
    ERRORS+=("spec.md not found in $FEATURE_DIR")
fi

# Check plan exists
if [[ "$PLAN_EXISTS" == "true" ]]; then
    AVAILABLE_DOCS+=("plan.md")
else
    if $CHECK_IMPLEMENT; then
        ERRORS+=("plan.md not found - run /df-plan first")
    else
        WARNINGS+=("plan.md not found")
    fi
fi

# Check tasks exists (only for --implement)
if $CHECK_IMPLEMENT; then
    if [[ "$TASKS_EXISTS" == "true" ]]; then
        AVAILABLE_DOCS+=("tasks.md")
    else
        ERRORS+=("tasks.md not found - run /df-tasks first")
    fi
fi

#==============================================================================
# Output
#==============================================================================

if $JSON_MODE; then
    # Build available docs JSON array
    DOCS_JSON="["
    for i in "${!AVAILABLE_DOCS[@]}"; do
        [[ $i -gt 0 ]] && DOCS_JSON+=","
        DOCS_JSON+="\"${AVAILABLE_DOCS[$i]}\""
    done
    DOCS_JSON+="]"

    VALID="true"
    [[ ${#ERRORS[@]} -gt 0 ]] && VALID="false"

    cat <<EOF
{"FEATURE_DIR":"$FEATURE_DIR","SPEC_EXISTS":$SPEC_EXISTS,"PLAN_EXISTS":$PLAN_EXISTS,"TASKS_EXISTS":$TASKS_EXISTS,"IS_DART_PROJECT":$IS_DART_PROJECT,"IS_FLUTTER_PROJECT":$IS_FLUTTER_PROJECT,"HAS_GIT":"$HAS_GIT","CURRENT_BRANCH":"$CURRENT_BRANCH","VALID":$VALID,"AVAILABLE_DOCS":$DOCS_JSON}
EOF
else
    echo "DFSpec Prerequisites Check"
    echo "=========================="
    echo ""
    echo "Project:"
    check_file "$REPO_ROOT/pubspec.yaml" "pubspec.yaml (Dart project)"
    [[ "$IS_FLUTTER_PROJECT" == "true" ]] && echo "  ✓ Flutter project" || echo "  ✓ Dart project"
    echo ""
    echo "Feature: $CURRENT_BRANCH"
    check_dir "$FEATURE_DIR" "Feature directory"
    check_file "$SPEC_FILE" "spec.md"
    check_file "$PLAN_FILE" "plan.md"
    check_file "$TASKS_FILE" "tasks.md"
    echo ""

    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        echo "Errors:"
        for err in "${ERRORS[@]}"; do
            log_error "$err"
        done
        echo ""
    fi

    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo "Warnings:"
        for warn in "${WARNINGS[@]}"; do
            log_warning "$warn"
        done
        echo ""
    fi

    if [[ ${#ERRORS[@]} -eq 0 ]]; then
        log_success "All prerequisites met"
    else
        exit 1
    fi
fi
