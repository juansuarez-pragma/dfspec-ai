#!/usr/bin/env bash
# Common functions for DFSpec scripts
# Dart/Flutter specific utilities

set -e

#==============================================================================
# Path Functions
#==============================================================================

get_repo_root() {
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
    else
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        (cd "$script_dir/.." && pwd)
    fi
}

get_current_branch() {
    if [[ -n "${DFSPEC_FEATURE:-}" ]]; then
        echo "$DFSPEC_FEATURE"
        return
    fi

    if git rev-parse --abbrev-ref HEAD >/dev/null 2>&1; then
        git rev-parse --abbrev-ref HEAD
        return
    fi

    # Fallback: find latest feature in specs/
    local repo_root=$(get_repo_root)
    local specs_dir="$repo_root/specs"

    if [[ -d "$specs_dir" ]]; then
        local latest=""
        local highest=0

        for dir in "$specs_dir"/*; do
            if [[ -d "$dir" ]]; then
                local dirname=$(basename "$dir")
                if [[ "$dirname" =~ ^([0-9]{3})- ]]; then
                    local num=$((10#${BASH_REMATCH[1]}))
                    if [[ $num -gt $highest ]]; then
                        highest=$num
                        latest=$dirname
                    fi
                fi
            fi
        done

        if [[ -n "$latest" ]]; then
            echo "$latest"
            return
        fi
    fi

    echo "main"
}

get_feature_number() {
    local branch="$1"
    if [[ "$branch" =~ ^([0-9]{3})- ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo ""
    fi
}

get_feature_dir() {
    local repo_root=$(get_repo_root)
    local branch=$(get_current_branch)
    echo "$repo_root/specs/$branch"
}

get_feature_paths() {
    local repo_root=$(get_repo_root)
    local branch=$(get_current_branch)
    local feature_dir="$repo_root/specs/$branch"
    local has_git="false"

    has_git && has_git="true"

    cat <<EOF
REPO_ROOT='$repo_root'
CURRENT_BRANCH='$branch'
HAS_GIT='$has_git'
FEATURE_DIR='$feature_dir'
SPEC_FILE='$feature_dir/spec.md'
PLAN_FILE='$feature_dir/plan.md'
TASKS_FILE='$feature_dir/tasks.md'
EOF
}

#==============================================================================
# Validation Functions
#==============================================================================

has_git() {
    git rev-parse --show-toplevel >/dev/null 2>&1
}

check_feature_branch() {
    local branch="$1"
    if [[ ! "$branch" =~ ^[0-9]{3}- ]]; then
        log_error "Not on a feature branch. Current: $branch"
        log_info "Feature branches should be: NNN-feature-name (e.g., 001-auth-oauth)"
        return 1
    fi
    return 0
}

check_dart_project() {
    local repo_root="${1:-$(get_repo_root)}"
    [[ -f "$repo_root/pubspec.yaml" ]]
}

is_flutter_project() {
    local repo_root="${1:-$(get_repo_root)}"
    grep -q "flutter:" "$repo_root/pubspec.yaml" 2>/dev/null
}

get_project_type() {
    local repo_root="${1:-$(get_repo_root)}"
    local pubspec="$repo_root/pubspec.yaml"

    if [[ ! -f "$pubspec" ]]; then
        echo "unknown"
        return
    fi

    if grep -q "flutter:" "$pubspec" 2>/dev/null; then
        if grep -q "plugin:" "$pubspec" 2>/dev/null; then
            echo "flutter_plugin"
        elif grep -q "flutter_test:" "$pubspec" 2>/dev/null; then
            echo "flutter_app"
        else
            echo "flutter_app"
        fi
    else
        if grep -q "executables:" "$pubspec" 2>/dev/null; then
            echo "dart_cli"
        else
            echo "dart_package"
        fi
    fi
}

#==============================================================================
# Logging Functions
#==============================================================================

log_info() {
    echo "INFO: $1"
}

log_success() {
    echo "✓ $1"
}

log_error() {
    echo "ERROR: $1" >&2
}

log_warning() {
    echo "⚠ $1" >&2
}

#==============================================================================
# Dart/Flutter Command Functions
#==============================================================================

run_analyze() {
    local repo_root="${1:-$(get_repo_root)}"
    cd "$repo_root"

    if is_flutter_project "$repo_root"; then
        flutter analyze
    else
        dart analyze
    fi
}

run_test() {
    local repo_root="${1:-$(get_repo_root)}"
    cd "$repo_root"

    if is_flutter_project "$repo_root"; then
        flutter test "$@"
    else
        dart test "$@"
    fi
}

run_format() {
    local repo_root="${1:-$(get_repo_root)}"
    cd "$repo_root"
    dart format "$@" .
}

run_pub_get() {
    local repo_root="${1:-$(get_repo_root)}"
    cd "$repo_root"

    if is_flutter_project "$repo_root"; then
        flutter pub get
    else
        dart pub get
    fi
}

#==============================================================================
# Utility Functions
#==============================================================================

get_highest_feature_number() {
    local specs_dir="$1"
    local highest=0

    if [[ -d "$specs_dir" ]]; then
        for dir in "$specs_dir"/*; do
            [[ -d "$dir" ]] || continue
            local dirname=$(basename "$dir")
            if [[ "$dirname" =~ ^([0-9]{3})- ]]; then
                local num=$((10#${BASH_REMATCH[1]}))
                if [[ $num -gt $highest ]]; then
                    highest=$num
                fi
            fi
        done
    fi

    echo "$highest"
}

get_highest_from_branches() {
    local highest=0
    local branches=$(git branch -a 2>/dev/null || echo "")

    if [[ -n "$branches" ]]; then
        while IFS= read -r branch; do
            local clean=$(echo "$branch" | sed 's/^[* ]*//; s|^remotes/[^/]*/||')
            if [[ "$clean" =~ ^([0-9]{3})- ]]; then
                local num=$((10#${BASH_REMATCH[1]}))
                if [[ $num -gt $highest ]]; then
                    highest=$num
                fi
            fi
        done <<< "$branches"
    fi

    echo "$highest"
}

clean_branch_name() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/-\+/-/g; s/^-//; s/-$//'
}

check_file() {
    [[ -f "$1" ]] && echo "  ✓ $2" || echo "  ✗ $2"
}

check_dir() {
    [[ -d "$1" && -n $(ls -A "$1" 2>/dev/null) ]] && echo "  ✓ $2" || echo "  ✗ $2"
}
