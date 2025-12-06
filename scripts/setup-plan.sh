#!/usr/bin/env bash
# Initialize plan.md from spec.md
# Usage: ./setup-plan.sh [OPTIONS]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

#==============================================================================
# Parse Arguments
#==============================================================================

JSON_MODE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            JSON_MODE=true
            shift
            ;;
        --help|-h)
            cat <<EOF
Usage: $0 [OPTIONS]

Initialize plan.md from the current feature's spec.md.

OPTIONS:
  --json        Output in JSON format
  --help, -h    Show this help

EXAMPLES:
  $0
  $0 --json
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

if ! check_dart_project "$REPO_ROOT"; then
    log_error "Not a Dart project (pubspec.yaml not found)"
    exit 1
fi

CURRENT_BRANCH=$(get_current_branch)

if ! check_feature_branch "$CURRENT_BRANCH"; then
    exit 1
fi

FEATURE_DIR="$REPO_ROOT/specs/$CURRENT_BRANCH"
SPEC_FILE="$FEATURE_DIR/spec.md"
PLAN_FILE="$FEATURE_DIR/plan.md"

#==============================================================================
# Validate Spec Exists
#==============================================================================

if [[ ! -f "$SPEC_FILE" ]]; then
    log_error "Spec file not found: $SPEC_FILE"
    log_info "Run create-feature.sh first or create spec.md manually"
    exit 1
fi

#==============================================================================
# Create Plan from Template or Spec
#==============================================================================

mkdir -p "$FEATURE_DIR"

TEMPLATE="$REPO_ROOT/templates/specs/plan.template.md"
FEATURE_NUM=$(get_feature_number "$CURRENT_BRANCH")

if [[ -f "$TEMPLATE" ]]; then
    cp "$TEMPLATE" "$PLAN_FILE"
    log_info "Copied plan template"
else
    # Extract feature name from spec
    FEATURE_NAME=$(head -n 5 "$SPEC_FILE" | grep -E "^#" | head -1 | sed 's/^#[[:space:]]*//' | sed 's/^Especificacion:[[:space:]]*//')

    # Count requirements in spec
    REQ_COUNT=$(grep -cE "^###[[:space:]]+RF-" "$SPEC_FILE" 2>/dev/null || echo "0")

    cat > "$PLAN_FILE" <<EOF
# Plan de Implementacion: $FEATURE_NAME

## Metadata
- Feature: $CURRENT_BRANCH
- Spec: $SPEC_FILE
- Estado: draft
- Fecha: $(date +%Y-%m-%d)

## Resumen Tecnico

[Descripcion de alto nivel de la implementacion]

## Arquitectura

### Clean Architecture Mapping
- **Domain:** [Entities, Use Cases, Repository Interfaces]
- **Data:** [Models, DataSources, Repository Impl]
- **Presentation:** [Pages, Widgets, Providers/BLoC]

## Fases de Implementacion

### Fase 1: Setup
- [ ] Crear estructura de directorios
- [ ] Agregar dependencias necesarias

### Fase 2: Domain Layer
- [ ] Crear entidades
- [ ] Definir repository interfaces
- [ ] Implementar use cases

### Fase 3: Data Layer
- [ ] Crear models con fromJson/toJson
- [ ] Implementar datasources
- [ ] Implementar repositories

### Fase 4: Presentation Layer
- [ ] Crear providers/bloc
- [ ] Implementar pages
- [ ] Crear widgets

## Dependencias

## Notas Tecnicas

## Riesgos y Mitigaciones
EOF
    log_info "Created plan from spec ($REQ_COUNT requirements found)"
fi

#==============================================================================
# Output
#==============================================================================

if $JSON_MODE; then
    REQ_COUNT=$(grep -cE "^###[[:space:]]+RF-" "$SPEC_FILE" 2>/dev/null || echo "0")
    cat <<EOF
{"FEATURE_SPEC":"$SPEC_FILE","IMPL_PLAN":"$PLAN_FILE","FEATURE_DIR":"$FEATURE_DIR","BRANCH":"$CURRENT_BRANCH","REQUIREMENTS_FOUND":$REQ_COUNT}
EOF
else
    log_success "Plan initialized: $PLAN_FILE"
    echo ""
    echo "FEATURE_SPEC: $SPEC_FILE"
    echo "IMPL_PLAN: $PLAN_FILE"
    echo "FEATURE_DIR: $FEATURE_DIR"
    echo "BRANCH: $CURRENT_BRANCH"
    echo ""
    log_info "Next: Edit $PLAN_FILE or run /df-plan"
fi
