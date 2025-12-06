#!/usr/bin/env bash
# Validate spec.md quality and structure
# Usage: ./validate-spec.sh [OPTIONS] [SPEC_DIR]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

#==============================================================================
# Parse Arguments
#==============================================================================

JSON_MODE=false
SPEC_DIR=""
ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            JSON_MODE=true
            shift
            ;;
        --help|-h)
            cat <<EOF
Usage: $0 [OPTIONS] [SPEC_DIR]

Validate spec.md quality and structure.

OPTIONS:
  --json        Output in JSON format
  --help, -h    Show this help

ARGUMENTS:
  SPEC_DIR      Path to feature directory (default: current feature)

EXAMPLES:
  $0                           # Validate current feature's spec
  $0 specs/001-auth/           # Validate specific spec
  $0 --json                    # JSON output
EOF
            exit 0
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

#==============================================================================
# Setup
#==============================================================================

REPO_ROOT=$(get_repo_root)

if [[ ${#ARGS[@]} -gt 0 ]]; then
    SPEC_DIR="${ARGS[0]}"
    # Handle relative paths
    if [[ ! "$SPEC_DIR" = /* ]]; then
        SPEC_DIR="$REPO_ROOT/$SPEC_DIR"
    fi
else
    CURRENT_BRANCH=$(get_current_branch)
    SPEC_DIR="$REPO_ROOT/specs/$CURRENT_BRANCH"
fi

SPEC_FILE="$SPEC_DIR/spec.md"

if [[ ! -f "$SPEC_FILE" ]]; then
    log_error "Spec file not found: $SPEC_FILE"
    exit 1
fi

#==============================================================================
# Validation Checks
#==============================================================================

ERRORS=0
WARNINGS=0

# Structure checks
HAS_SUMMARY=false
HAS_REQUIREMENTS=false
HAS_CRITERIA=false
HAS_NFR=false

grep -qE "^##[[:space:]]+Resumen" "$SPEC_FILE" && HAS_SUMMARY=true
grep -qE "^##[[:space:]]+Requisitos Funcionales" "$SPEC_FILE" && HAS_REQUIREMENTS=true
grep -qE "^##[[:space:]]+Criterios de Aceptacion" "$SPEC_FILE" && HAS_CRITERIA=true
grep -qE "^##[[:space:]]+Requisitos No Funcionales" "$SPEC_FILE" && HAS_NFR=true

# Count requirements
REQ_COUNT=$(grep -cE "^###[[:space:]]+RF-[0-9]+" "$SPEC_FILE" 2>/dev/null | tr -d '\n' || echo "0")
REQ_COUNT=${REQ_COUNT:-0}

# Count acceptance criteria
CRITERIA_COUNT=$(grep -cE "^-[[:space:]]+\[" "$SPEC_FILE" 2>/dev/null | tr -d '\n' || echo "0")
CRITERIA_COUNT=${CRITERIA_COUNT:-0}
CRITERIA_COUNT2=$(grep -cE "^###[[:space:]]+CA-[0-9]+" "$SPEC_FILE" 2>/dev/null | tr -d '\n' || echo "0")
CRITERIA_COUNT2=${CRITERIA_COUNT2:-0}
[[ $CRITERIA_COUNT2 -gt $CRITERIA_COUNT ]] && CRITERIA_COUNT=$CRITERIA_COUNT2

# Count clarifications needed
CLARIFICATIONS=$(grep -cE "\[NEEDS CLARIFICATION" "$SPEC_FILE" 2>/dev/null | tr -d '\n' || echo "0")
CLARIFICATIONS=${CLARIFICATIONS:-0}

# Check Given/When/Then format
GWT_COUNT=$(grep -ciE "(DADO|GIVEN|CUANDO|WHEN|ENTONCES|THEN)" "$SPEC_FILE" 2>/dev/null | tr -d '\n' || echo "0")
GWT_COUNT=${GWT_COUNT:-0}

# Check requirements have descriptions
EMPTY_REQ=0
while IFS= read -r line; do
    if [[ "$line" =~ ^###[[:space:]]+RF- ]]; then
        # Check if next non-empty line has content
        :
    fi
done < "$SPEC_FILE"

#==============================================================================
# Evaluate Results
#==============================================================================

# Structure errors
[[ "$HAS_SUMMARY" != "true" ]] && ((ERRORS++))
[[ "$HAS_REQUIREMENTS" != "true" ]] && ((ERRORS++))
[[ "$HAS_CRITERIA" != "true" ]] && ((ERRORS++))

# Content warnings
[[ $REQ_COUNT -eq 0 ]] && ((ERRORS++))
[[ $CRITERIA_COUNT -eq 0 ]] && ((WARNINGS++))
[[ $CLARIFICATIONS -gt 3 ]] && ((WARNINGS++))
[[ "$HAS_NFR" != "true" ]] && ((WARNINGS++))

VALID="true"
[[ $ERRORS -gt 0 ]] && VALID="false"

#==============================================================================
# Output
#==============================================================================

if $JSON_MODE; then
    cat <<EOF
{"file":"$SPEC_FILE","valid":$VALID,"warnings":$WARNINGS,"errors":$ERRORS,"checks":{"has_summary":$HAS_SUMMARY,"has_requirements":$HAS_REQUIREMENTS,"has_criteria":$HAS_CRITERIA,"has_nfr":$HAS_NFR,"requirements_count":$REQ_COUNT,"clarifications_count":$CLARIFICATIONS,"criteria_count":$CRITERIA_COUNT,"gwt_count":$GWT_COUNT}}
EOF
else
    echo "Validating: $SPEC_FILE"
    echo ""
    echo "Structure:"
    [[ "$HAS_SUMMARY" == "true" ]] && echo "  ✓ Has summary section" || echo "  ✗ Missing summary section"
    [[ "$HAS_REQUIREMENTS" == "true" ]] && echo "  ✓ Has functional requirements" || echo "  ✗ Missing functional requirements"
    [[ "$HAS_CRITERIA" == "true" ]] && echo "  ✓ Has acceptance criteria" || echo "  ✗ Missing acceptance criteria"
    [[ "$HAS_NFR" == "true" ]] && echo "  ✓ Has non-functional requirements" || echo "  ⚠ Missing non-functional requirements"
    echo ""
    echo "Requirements:"
    if [[ $REQ_COUNT -gt 0 ]]; then
        echo "  ✓ Found $REQ_COUNT functional requirements"
    else
        echo "  ✗ No functional requirements found (RF-XXX)"
    fi
    if [[ $CLARIFICATIONS -eq 0 ]]; then
        echo "  ✓ No pending clarifications"
    elif [[ $CLARIFICATIONS -le 3 ]]; then
        echo "  ⚠ Found $CLARIFICATIONS [NEEDS CLARIFICATION] items"
    else
        echo "  ⚠ Found $CLARIFICATIONS [NEEDS CLARIFICATION] items (consider resolving)"
    fi
    echo ""
    echo "Acceptance Criteria:"
    if [[ $CRITERIA_COUNT -gt 0 ]]; then
        echo "  ✓ Found $CRITERIA_COUNT acceptance criteria"
    else
        echo "  ⚠ No acceptance criteria found"
    fi
    if [[ $GWT_COUNT -gt 0 ]]; then
        echo "  ✓ Uses Given/When/Then format"
    else
        echo "  ⚠ Consider using DADO/CUANDO/ENTONCES format"
    fi
    echo ""

    if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
        log_success "Result: PASS"
    elif [[ $ERRORS -eq 0 ]]; then
        log_success "Result: PASS ($WARNINGS warnings)"
    else
        log_error "Result: FAIL ($ERRORS errors, $WARNINGS warnings)"
        exit 1
    fi
fi
