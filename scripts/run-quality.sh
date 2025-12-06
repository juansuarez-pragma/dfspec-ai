#!/usr/bin/env bash
# Run all quality checks for Dart/Flutter project
# Usage: ./run-quality.sh [OPTIONS]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

#==============================================================================
# Parse Arguments
#==============================================================================

JSON_MODE=false
QUICK_MODE=false
FIX_MODE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            JSON_MODE=true
            shift
            ;;
        --quick)
            QUICK_MODE=true
            shift
            ;;
        --fix)
            FIX_MODE=true
            shift
            ;;
        --help|-h)
            cat <<EOF
Usage: $0 [OPTIONS]

Run all quality checks for Dart/Flutter project.

OPTIONS:
  --json        Output in JSON format
  --quick       Only run analyze and format (skip tests)
  --fix         Apply automatic fixes (dart fix, dart format)
  --help, -h    Show this help

EXAMPLES:
  $0                # Run all checks
  $0 --quick        # Only analyze and format
  $0 --fix          # Apply fixes and run checks
  $0 --json         # JSON output
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
cd "$REPO_ROOT"

if ! check_dart_project "$REPO_ROOT"; then
    log_error "Not a Dart project (pubspec.yaml not found)"
    exit 1
fi

PROJECT_TYPE=$(get_project_type)

# Results
ANALYZE_PASSED=false
ANALYZE_ERRORS=0
ANALYZE_WARNINGS=0
ANALYZE_INFOS=0

FORMAT_PASSED=false
FORMAT_FILES=0

TEST_PASSED=false
TEST_TOTAL=0
TEST_PASSED_COUNT=0
TEST_FAILED=0

OUTDATED_COUNT=0

#==============================================================================
# Apply Fixes (if requested)
#==============================================================================

if $FIX_MODE; then
    if ! $JSON_MODE; then
        echo "[0/4] Applying fixes..."
    fi

    # Run dart fix
    if is_flutter_project "$REPO_ROOT"; then
        dart fix --apply lib/ test/ 2>/dev/null || true
    else
        dart fix --apply 2>/dev/null || true
    fi

    # Run dart format
    dart format . 2>/dev/null || true

    if ! $JSON_MODE; then
        echo "  ✓ Fixes applied"
        echo ""
    fi
fi

#==============================================================================
# Run Analyze
#==============================================================================

if ! $JSON_MODE; then
    echo "[1/4] Running dart analyze..."
fi

ANALYZE_OUTPUT=""
if is_flutter_project "$REPO_ROOT"; then
    ANALYZE_OUTPUT=$(flutter analyze 2>&1) || true
else
    ANALYZE_OUTPUT=$(dart analyze 2>&1) || true
fi

# Parse analyze output
if echo "$ANALYZE_OUTPUT" | grep -qE "No issues found|0 issues found"; then
    ANALYZE_PASSED=true
else
    ANALYZE_ERRORS=$(echo "$ANALYZE_OUTPUT" | grep -cE "error •|error -" 2>/dev/null | tr -d '\n' || echo "0")
    ANALYZE_WARNINGS=$(echo "$ANALYZE_OUTPUT" | grep -cE "warning •|warning -" 2>/dev/null | tr -d '\n' || echo "0")
    ANALYZE_INFOS=$(echo "$ANALYZE_OUTPUT" | grep -cE "info •|info -" 2>/dev/null | tr -d '\n' || echo "0")
    # Ensure numeric values
    ANALYZE_ERRORS=${ANALYZE_ERRORS:-0}
    ANALYZE_WARNINGS=${ANALYZE_WARNINGS:-0}
    ANALYZE_INFOS=${ANALYZE_INFOS:-0}
    [[ $ANALYZE_ERRORS -eq 0 ]] && ANALYZE_PASSED=true
fi

if ! $JSON_MODE; then
    if $ANALYZE_PASSED; then
        echo "  ✓ No issues found"
    else
        echo "  ✗ Found: $ANALYZE_ERRORS errors, $ANALYZE_WARNINGS warnings, $ANALYZE_INFOS infos"
    fi
fi

#==============================================================================
# Run Format Check
#==============================================================================

if ! $JSON_MODE; then
    echo "[2/4] Running dart format..."
fi

FORMAT_OUTPUT=$(dart format --set-exit-if-changed --output=none . 2>&1) && FORMAT_PASSED=true || FORMAT_PASSED=false

# Count files needing format
FORMAT_FILES=$(echo "$FORMAT_OUTPUT" | grep -cE "^Changed" 2>/dev/null | tr -d '\n' || echo "0")
FORMAT_FILES=${FORMAT_FILES:-0}

# If no output or exit was 0, format passed
if [[ -z "$FORMAT_OUTPUT" ]] || [[ "$FORMAT_PASSED" == "true" ]]; then
    FORMAT_PASSED=true
    FORMAT_FILES=0
fi

if ! $JSON_MODE; then
    if [[ "$FORMAT_PASSED" == "true" ]]; then
        echo "  ✓ All files formatted correctly"
    else
        echo "  ✗ $FORMAT_FILES files need formatting"
    fi
fi

#==============================================================================
# Run Tests (unless --quick)
#==============================================================================

if ! $QUICK_MODE; then
    if ! $JSON_MODE; then
        echo "[3/4] Running tests..."
    fi

    # Check if test directory exists
    if [[ -d "$REPO_ROOT/test" ]]; then
        TEST_OUTPUT=""
        if is_flutter_project "$REPO_ROOT"; then
            TEST_OUTPUT=$(flutter test 2>&1) || true
        else
            TEST_OUTPUT=$(dart test 2>&1) || true
        fi

        # Parse test output
        if echo "$TEST_OUTPUT" | grep -qE "All tests passed|tests passed"; then
            TEST_PASSED=true
            TEST_TOTAL=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ tests? passed" | grep -oE "^[0-9]+" || echo "0")
            TEST_PASSED_COUNT=$TEST_TOTAL
        elif echo "$TEST_OUTPUT" | grep -qE "[0-9]+ passed"; then
            # Parse "X passed, Y failed" format
            TEST_PASSED_COUNT=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ passed" | tail -1 | grep -oE "^[0-9]+" || echo "0")
            TEST_FAILED=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ failed" | tail -1 | grep -oE "^[0-9]+" || echo "0")
            TEST_TOTAL=$((TEST_PASSED_COUNT + TEST_FAILED))
            [[ $TEST_FAILED -eq 0 ]] && TEST_PASSED=true
        else
            # No tests or error
            TEST_TOTAL=0
            TEST_PASSED=true
        fi

        if ! $JSON_MODE; then
            if [[ $TEST_TOTAL -eq 0 ]]; then
                echo "  ⚠ No tests found"
            elif $TEST_PASSED; then
                echo "  ✓ $TEST_PASSED_COUNT tests passed"
            else
                echo "  ✗ $TEST_PASSED_COUNT/$TEST_TOTAL tests passed ($TEST_FAILED failed)"
            fi
        fi
    else
        TEST_PASSED=true
        if ! $JSON_MODE; then
            echo "  ⚠ No test directory found"
        fi
    fi
else
    TEST_PASSED=true
    if ! $JSON_MODE; then
        echo "[3/4] Skipping tests (--quick mode)"
    fi
fi

#==============================================================================
# Check Dependencies
#==============================================================================

if ! $JSON_MODE; then
    echo "[4/4] Checking dependencies..."
fi

OUTDATED_OUTPUT=""
if is_flutter_project "$REPO_ROOT"; then
    OUTDATED_OUTPUT=$(flutter pub outdated 2>&1) || true
else
    OUTDATED_OUTPUT=$(dart pub outdated 2>&1) || true
fi

OUTDATED_COUNT=$(echo "$OUTDATED_OUTPUT" | grep -cE "^\w" | head -1 || echo "0")
# Subtract header lines
OUTDATED_COUNT=$((OUTDATED_COUNT > 2 ? OUTDATED_COUNT - 2 : 0))

if ! $JSON_MODE; then
    if [[ $OUTDATED_COUNT -eq 0 ]]; then
        echo "  ✓ All dependencies up to date"
    else
        echo "  ⚠ $OUTDATED_COUNT packages have updates available"
    fi
fi

#==============================================================================
# Summary
#==============================================================================

OVERALL="PASS"
[[ "$ANALYZE_PASSED" != "true" ]] && OVERALL="FAIL"
[[ "$FORMAT_PASSED" != "true" ]] && OVERALL="FAIL"
[[ "$TEST_PASSED" != "true" ]] && OVERALL="FAIL"

if $JSON_MODE; then
    cat <<EOF
{"analyze":{"passed":$ANALYZE_PASSED,"errors":$ANALYZE_ERRORS,"warnings":$ANALYZE_WARNINGS,"infos":$ANALYZE_INFOS},"format":{"passed":$FORMAT_PASSED,"files_to_format":$FORMAT_FILES},"test":{"passed":$TEST_PASSED,"total":$TEST_TOTAL,"passed_count":$TEST_PASSED_COUNT,"failed":$TEST_FAILED},"dependencies":{"outdated":$OUTDATED_COUNT},"overall":"$OVERALL","project_type":"$PROJECT_TYPE"}
EOF
else
    echo ""
    echo "Summary:"
    echo "========"
    [[ "$ANALYZE_PASSED" == "true" ]] && echo "  ✓ Analysis: PASS" || echo "  ✗ Analysis: FAIL"
    [[ "$FORMAT_PASSED" == "true" ]] && echo "  ✓ Format: PASS" || echo "  ✗ Format: FAIL"
    if ! $QUICK_MODE; then
        if [[ $TEST_TOTAL -eq 0 ]]; then
            echo "  ⚠ Tests: N/A (no tests)"
        elif [[ "$TEST_PASSED" == "true" ]]; then
            echo "  ✓ Tests: PASS ($TEST_PASSED_COUNT/$TEST_TOTAL)"
        else
            echo "  ✗ Tests: FAIL ($TEST_PASSED_COUNT/$TEST_TOTAL)"
        fi
    fi
    [[ $OUTDATED_COUNT -eq 0 ]] && echo "  ✓ Dependencies: Up to date" || echo "  ⚠ Dependencies: $OUTDATED_COUNT updates available"
    echo ""

    if [[ "$OVERALL" == "PASS" ]]; then
        log_success "Overall: PASS"
    else
        log_error "Overall: FAIL"
        exit 1
    fi
fi
