#!/usr/bin/env bash
# ==============================================================================
# DFSpec - Setup Plan
# ==============================================================================
# Configura el entorno para crear un plan de implementación:
# - Verifica que exista spec.md
# - Crea directorio de plan si no existe
# - Crea archivos auxiliares (research.md, data-model.md, etc.)
# - Genera plan.md inicial desde template
#
# Uso:
#   ./setup-plan.sh [opciones]
#
# Opciones:
#   --json              Salida en formato JSON (default)
#   --feature=NAME      Especificar feature (override auto-detección)
#   --with-research     Crear research.md
#   --with-datamodel    Crear data-model.md
#   --with-contracts    Crear directorio contracts/
#   --full              Crear todos los archivos auxiliares
#   --help              Mostrar ayuda
#
# Salida JSON:
#   {
#     "status": "success",
#     "data": {
#       "feature_id": "001-auth",
#       "plan_path": "specs/plans/001-auth.plan.md",
#       "spec_path": "specs/features/001-auth/spec.md",
#       "created": ["plan.md", "research.md"],
#       "spec_content_summary": "..."
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
WITH_RESEARCH=false
WITH_DATAMODEL=false
WITH_CONTRACTS=false
FULL_SETUP=false

# ==============================================================================
# PARSING DE ARGUMENTOS
# ==============================================================================

show_help() {
    cat << 'EOF'
DFSpec - Setup Plan

Configura el entorno para crear un plan de implementación.

USO:
    ./setup-plan.sh [opciones]

OPCIONES:
    --json              Salida en formato JSON (default)
    --feature=NAME      Especificar feature (override auto-detección)
    --with-research     Crear research.md para investigación técnica
    --with-datamodel    Crear data-model.md para entidades
    --with-contracts    Crear directorio contracts/ para APIs
    --full              Crear todos los archivos auxiliares
    --help              Mostrar esta ayuda

EJEMPLOS:
    # Setup básico (solo plan.md)
    ./setup-plan.sh --json

    # Setup completo con todos los auxiliares
    ./setup-plan.sh --full

    # Para feature específica
    ./setup-plan.sh --feature=001-auth --with-research

ARCHIVOS GENERADOS:
    specs/plans/NNN-feature.plan.md     Plan de implementación
    specs/features/NNN-feature/
        research.md                      Investigación técnica
        data-model.md                    Modelo de datos
        contracts/                       Contratos de API
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
            --with-research)
                WITH_RESEARCH=true
                shift
                ;;
            --with-datamodel)
                WITH_DATAMODEL=true
                shift
                ;;
            --with-contracts)
                WITH_CONTRACTS=true
                shift
                ;;
            --full)
                FULL_SETUP=true
                WITH_RESEARCH=true
                WITH_DATAMODEL=true
                WITH_CONTRACTS=true
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

get_spec_summary() {
    local spec_path="$1"
    local max_lines=50

    if [[ ! -f "$spec_path" ]]; then
        echo ""
        return
    fi

    # Extraer resumen ejecutivo y user stories
    head -n "$max_lines" "$spec_path" | grep -v "^#" | grep -v "^-" | head -20 | tr '\n' ' ' | cut -c1-500
}

create_plan_template() {
    local feature_id="$1"
    local feature_name="$2"
    local plan_path="$3"
    local spec_path="$4"

    if [[ -f "$plan_path" ]]; then
        warn "El archivo plan.md ya existe: $plan_path"
        return 1
    fi

    # Obtener fecha actual
    local current_date
    current_date=$(date +%Y-%m-%d)

    # Crear plan.md desde template
    cat > "$plan_path" << EOF
# Implementation Plan: ${feature_name}

## Metadata

| Campo | Valor |
|-------|-------|
| Feature | ${feature_id} |
| Spec | ${spec_path} |
| Fecha | ${current_date} |
| Estado | Draft |

---

## Resumen Técnico

[Descripción técnica de 2-3 oraciones sobre cómo se implementará esta feature]

---

## Pre-Implementation Gates

### Gate I: Clean Architecture
- [ ] ¿Domain NO importa Data ni Presentation?
- [ ] ¿Data importa solo Domain?
- [ ] ¿Presentation importa solo Domain?

### Gate II: Test-Driven Development
- [ ] ¿Se seguirá ciclo RED-GREEN-REFACTOR?
- [ ] ¿Cada archivo en lib/ tendrá su correspondiente en test/?

### Gate III: Entidades Inmutables
- [ ] ¿Las entidades usan Equatable?
- [ ] ¿Todos los campos son final?
- [ ] ¿Sin setters públicos?

### Gate IV: Separación Modelo-Entidad
- [ ] ¿Models en data/ con fromJson/toJson?
- [ ] ¿Entities en domain/ sin conocimiento de JSON?

### Constitution Check
- [ ] Todas las decisiones alineadas con constitution.md

---

## Contexto Técnico

| Aspecto | Decisión |
|---------|----------|
| Lenguaje | Dart 3.x |
| Framework | Flutter |
| State Management | [Riverpod / BLoC] |
| Storage | [Local / Remote / Both] |
| Testing | Unit + Widget + Integration |
| Target Platform | [Android / iOS / Web / All] |

---

## Estructura del Proyecto

\`\`\`
lib/src/
├── domain/
│   ├── entities/
│   │   └── [entity].dart
│   ├── repositories/
│   │   └── [repository]_interface.dart
│   └── usecases/
│       └── [usecase].dart
├── data/
│   ├── models/
│   │   └── [entity]_model.dart
│   ├── datasources/
│   │   └── [source]_datasource.dart
│   └── repositories/
│       └── [repository]_impl.dart
└── presentation/
    ├── pages/
    │   └── [page]_page.dart
    ├── widgets/
    │   └── [widget].dart
    └── providers/
        └── [provider].dart
\`\`\`

---

## Componentes a Implementar

### Domain Layer

| Componente | Tipo | Responsabilidad |
|------------|------|-----------------|
| [Entity] | Entity | [Descripción] |
| [Repository] | Interface | [Descripción] |
| [UseCase] | UseCase | [Descripción] |

### Data Layer

| Componente | Tipo | Responsabilidad |
|------------|------|-----------------|
| [Model] | Model | [Descripción] |
| [DataSource] | DataSource | [Descripción] |
| [RepositoryImpl] | Implementation | [Descripción] |

### Presentation Layer

| Componente | Tipo | Responsabilidad |
|------------|------|-----------------|
| [Page] | Page | [Descripción] |
| [Widget] | Widget | [Descripción] |
| [Provider] | Provider | [Descripción] |

---

## Orden de Implementación TDD

### Fase 1: Domain (Contratos)
1. \`domain/entities/[entity].dart\` + test
2. \`domain/repositories/[repo]_interface.dart\`
3. \`domain/usecases/[usecase].dart\` + test

### Fase 2: Data (Implementación)
4. \`data/models/[entity]_model.dart\` + test
5. \`data/datasources/[source]_datasource.dart\` + test
6. \`data/repositories/[repo]_impl.dart\` + test

### Fase 3: Presentation (UI)
7. \`presentation/providers/[provider].dart\` + test
8. \`presentation/widgets/[widget].dart\` + test
9. \`presentation/pages/[page]_page.dart\` + test

### Fase 4: Integration
10. Integration tests
11. Golden tests (si aplica)

---

## Diagrama de Componentes

\`\`\`mermaid
graph TB
    subgraph Presentation
        Page[Page]
        Widget[Widget]
        Provider[Provider]
    end

    subgraph Domain
        UseCase[UseCase]
        Entity[Entity]
        RepoInterface[Repository Interface]
    end

    subgraph Data
        RepoImpl[Repository Impl]
        Model[Model]
        DataSource[DataSource]
    end

    Page --> Provider
    Provider --> UseCase
    UseCase --> RepoInterface
    RepoInterface -.-> RepoImpl
    RepoImpl --> Model
    RepoImpl --> DataSource
    Model --> Entity
\`\`\`

---

## Dependencias Externas

| Paquete | Versión | Propósito |
|---------|---------|-----------|
| [paquete] | ^x.x.x | [Para qué se usa] |

---

## Complexity Tracking

| Violación | Justificación | Ticket |
|-----------|---------------|--------|
| [Si aplica] | [Razón técnica] | [Link] |

---

## Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| [Riesgo 1] | Media | Alto | [Estrategia] |

---

## Definition of Done

- [ ] Todos los componentes implementados
- [ ] Tests unitarios >85% cobertura
- [ ] Tests de widget para UI
- [ ] Tests de integración para flujos críticos
- [ ] Code review aprobado
- [ ] Documentación actualizada
- [ ] Performance validada (<16ms frame budget)
- [ ] Sin errores de linting
EOF

    debug "Plan creado: $plan_path"
    return 0
}

create_research_template() {
    local feature_id="$1"
    local research_path="$2"

    if [[ -f "$research_path" ]]; then
        warn "research.md ya existe"
        return 1
    fi

    local current_date
    current_date=$(date +%Y-%m-%d)

    cat > "$research_path" << EOF
# Technical Research: ${feature_id}

## Fecha: ${current_date}

---

## Preguntas de Investigación

1. [Pregunta técnica 1]
2. [Pregunta técnica 2]
3. [Pregunta técnica 3]

---

## Opciones Evaluadas

### Opción A: [Nombre]

**Pros:**
- [Ventaja 1]
- [Ventaja 2]

**Contras:**
- [Desventaja 1]
- [Desventaja 2]

**Complejidad:** Alta | Media | Baja

### Opción B: [Nombre]

**Pros:**
- [Ventaja 1]

**Contras:**
- [Desventaja 1]

**Complejidad:** Alta | Media | Baja

---

## Decisión

**Opción seleccionada:** [A/B/C]

**Justificación:** [Por qué esta opción es la mejor para este caso]

---

## Recursos Consultados

- [Link 1](url) - [Descripción]
- [Link 2](url) - [Descripción]

---

## Notas Adicionales

[Cualquier información relevante descubierta durante la investigación]
EOF

    debug "Research creado: $research_path"
    return 0
}

create_datamodel_template() {
    local feature_id="$1"
    local datamodel_path="$2"

    if [[ -f "$datamodel_path" ]]; then
        warn "data-model.md ya existe"
        return 1
    fi

    cat > "$datamodel_path" << EOF
# Data Model: ${feature_id}

---

## Entidades

### [EntityName]

\`\`\`dart
/// [Descripción de la entidad]
class EntityName extends Equatable {
  const EntityName({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  /// Identificador único
  final String id;

  /// Nombre de la entidad
  final String name;

  /// Descripción opcional
  final String? description;

  /// Fecha de creación
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, description, createdAt];
}
\`\`\`

**Validaciones:**
- \`id\`: No vacío, formato UUID
- \`name\`: No vacío, máximo 100 caracteres
- \`createdAt\`: No puede ser futuro

---

## Modelos (JSON)

### [EntityName]Model

\`\`\`dart
class EntityNameModel {
  const EntityNameModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory EntityNameModel.fromJson(Map<String, dynamic> json) {
    return EntityNameModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'created_at': createdAt.toIso8601String(),
  };

  EntityName toEntity() => EntityName(
    id: id,
    name: name,
    description: description,
    createdAt: createdAt,
  );
}
\`\`\`

---

## Relaciones

\`\`\`mermaid
erDiagram
    EntityA ||--o{ EntityB : "has many"
    EntityB }o--|| EntityC : "belongs to"
\`\`\`

---

## Validaciones de Negocio

| Entidad | Campo | Regla | Mensaje de Error |
|---------|-------|-------|------------------|
| EntityName | name | No vacío | "El nombre es requerido" |
| EntityName | name | Max 100 chars | "El nombre es muy largo" |
EOF

    debug "Data model creado: $datamodel_path"
    return 0
}

create_contracts_directory() {
    local feature_id="$1"
    local contracts_dir="$FEATURES_DIR/$feature_id/contracts"

    if [[ -d "$contracts_dir" ]]; then
        warn "Directorio contracts/ ya existe"
        return 1
    fi

    mkdir -p "$contracts_dir"

    # Crear archivo de ejemplo
    cat > "$contracts_dir/README.md" << EOF
# API Contracts: ${feature_id}

Este directorio contiene los contratos de API para esta feature.

## Estructura

\`\`\`
contracts/
├── api.yaml          # OpenAPI/Swagger spec
├── graphql/          # GraphQL schemas (si aplica)
└── grpc/             # Protobuf definitions (si aplica)
\`\`\`

## Convenciones

- Usar OpenAPI 3.0+ para REST APIs
- Incluir ejemplos de request/response
- Documentar códigos de error
EOF

    debug "Contracts directory creado: $contracts_dir"
    return 0
}

# ==============================================================================
# OUTPUT
# ==============================================================================

output_result() {
    local feature_id="$1"
    local plan_path="$2"
    local spec_path="$3"
    local created_items="$4"
    local spec_summary="$5"

    cat << EOF
{
  "status": "success",
  "data": {
    "feature_id": "$(json_escape "$feature_id")",
    "paths": {
      "plan": "$(json_escape "$plan_path")",
      "spec": "$(json_escape "$spec_path")"
    },
    "created": [$created_items],
    "spec_exists": $(if [[ -f "$spec_path" ]]; then echo "true"; else echo "false"; fi),
    "spec_summary": "$(json_escape "$spec_summary")"
  }
}
EOF
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    parse_args "$@"

    # Detectar feature
    local feature_id
    if [[ -n "$FEATURE_OVERRIDE" ]]; then
        feature_id="$FEATURE_OVERRIDE"
    else
        feature_id=$(detect_current_feature)
    fi

    if [[ -z "$feature_id" ]]; then
        json_error "No se detectó feature actual. Usa --feature=NAME o crea una feature primero." "NO_FEATURE"
        exit 1
    fi

    debug "Setting up plan for feature: $feature_id"

    # Paths
    local feature_dir="$FEATURES_DIR/$feature_id"
    local spec_path="$feature_dir/spec.md"
    local plan_path="$PLANS_DIR/$feature_id.plan.md"
    local research_path="$feature_dir/research.md"
    local datamodel_path="$feature_dir/data-model.md"

    # Verificar spec existe
    if [[ ! -f "$spec_path" ]]; then
        json_error "No se encontró spec.md para feature: $feature_id. Crea la especificación primero." "SPEC_NOT_FOUND"
        exit 1
    fi

    # Crear directorios necesarios
    mkdir -p "$PLANS_DIR"
    mkdir -p "$feature_dir"

    # Extraer nombre de feature
    local feature_name="${feature_id#*-}"

    # Tracking de lo que se creó
    local created_items=""
    local add_comma=false

    # Crear plan.md
    if create_plan_template "$feature_id" "$feature_name" "$plan_path" "$spec_path"; then
        created_items+="\"plan.md\""
        add_comma=true
    fi

    # Crear research.md si se solicita
    if [[ "$WITH_RESEARCH" == true ]]; then
        if create_research_template "$feature_id" "$research_path"; then
            [[ "$add_comma" == true ]] && created_items+=", "
            created_items+="\"research.md\""
            add_comma=true
        fi
    fi

    # Crear data-model.md si se solicita
    if [[ "$WITH_DATAMODEL" == true ]]; then
        if create_datamodel_template "$feature_id" "$datamodel_path"; then
            [[ "$add_comma" == true ]] && created_items+=", "
            created_items+="\"data-model.md\""
            add_comma=true
        fi
    fi

    # Crear contracts/ si se solicita
    if [[ "$WITH_CONTRACTS" == true ]]; then
        if create_contracts_directory "$feature_id"; then
            [[ "$add_comma" == true ]] && created_items+=", "
            created_items+="\"contracts/\""
        fi
    fi

    # Obtener resumen del spec
    local spec_summary
    spec_summary=$(get_spec_summary "$spec_path")

    # Output
    output_result "$feature_id" "$plan_path" "$spec_path" "$created_items" "$spec_summary"
}

main "$@"
