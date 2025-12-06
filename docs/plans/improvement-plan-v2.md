# Plan de Mejoras DFSpec v2.0

## Analisis Comparativo: DFSpec-IA vs Spec-Kit

### Estado Actual de DFSpec-IA

| Componente | Estado | Descripcion |
|------------|--------|-------------|
| CLI | Completo | 4 comandos (init, install, generate, agents) |
| Agentes | 18 | Especializados con YAML frontmatter |
| Tests | 217+ | 100% passing |
| CI/CD | Activo | GitHub Actions (PRs a main) |
| Scripts | 6 | Automatizacion bash |
| Documentacion | Completa | README, CLAUDE.md, constitution.md |

### Fortalezas de Spec-Kit a Adoptar

| Feature | Spec-Kit | DFSpec-IA Actual | Prioridad |
|---------|----------|------------------|-----------|
| Handoffs automaticos | Si | No | ALTA |
| Constitutional gates | Si (validacion) | Parcial (solo doc) | ALTA |
| User Story decomposition | P1/P2/P3 | No | ALTA |
| Cross-artifact analysis | /speckit.analyze | /df-analyze basico | MEDIA |
| Branch auto-numbering | Si | Parcial | MEDIA |
| Interactive CLI | Flechas + seleccion | No | MEDIA |
| Multi-agent support | 17 agentes | Solo Claude | BAJA |
| PowerShell scripts | Si | Solo bash | BAJA |

---

## Plan de Mejoras por Fases

### FASE 1: Handoffs Automaticos (Prioridad ALTA)

**Objetivo**: Permitir transiciones automaticas entre comandos /df-*

**Implementacion**:

1. **Agregar campo `handoffs` en YAML frontmatter de agentes**:
```yaml
---
name: dfspec
description: Especialista en Especificaciones
model: opus
tools: [Read, Write, Glob, Grep, WebSearch]
handoffs:
  - label: "Crear Plan"
    command: /df-plan
    auto: false
  - label: "Clarificar"
    command: /df-clarify
    auto: false
---
```

2. **Modificar AgentParser para parsear handoffs**

3. **Modificar ClaudeCommandGenerator para incluir sugerencias de siguiente paso**

4. **Flujo completo con handoffs**:
```
/df-spec "Auth feature"
    |-- Genera spec.md
    |-- Sugiere: "Siguiente: /df-plan para crear plan de implementacion"
    v
/df-plan
    |-- Genera plan.md
    |-- Sugiere: "/df-tasks para desglosar tareas"
    v
/df-tasks
    |-- Genera tasks.md
    |-- Sugiere: "/df-implement para comenzar TDD"
    v
/df-implement
    |-- Implementa codigo
    |-- Sugiere: "/df-verify para validar"
```

**Archivos a modificar**:
- `lib/src/parsers/agent_parser.dart`
- `lib/src/models/agent_config.dart`
- `lib/src/generators/command_generator.dart`
- `agents/*.md` (agregar handoffs)

**Estimacion**: 15 archivos modificados

---

### FASE 2: Constitutional Gates (Prioridad ALTA)

**Objetivo**: Validar principios de constitution.md antes de cada fase

**Implementacion**:

1. **Crear ConstitutionValidator**:
```dart
class ConstitutionValidator {
  final String constitutionPath;

  Future<ValidationResult> validate({
    required String artifactPath,
    required ValidationPhase phase,
  });

  List<ConstitutionViolation> checkCleanArchitecture(String code);
  List<ConstitutionViolation> checkTddCompliance(String testPath);
  List<ConstitutionViolation> checkImmutableEntities(String code);
}
```

2. **Agregar gates en agentes**:
```yaml
---
name: dfimplementer
gates:
  - type: constitution
    check: clean_architecture
    severity: blocking
  - type: constitution
    check: tdd_compliance
    severity: warning
---
```

3. **Integrar validacion en flujo**:
- Antes de /df-implement: Validar que plan sigue Clean Architecture
- Durante /df-implement: Validar TDD (test antes de codigo)
- Antes de /df-verify: Validar cobertura >85%

**Archivos nuevos**:
- `lib/src/validators/constitution_validator.dart`
- `lib/src/validators/validators.dart`
- `lib/src/models/validation_result.dart`

**Archivos a modificar**:
- `lib/src/parsers/agent_parser.dart`
- `lib/src/models/agent_config.dart`
- `agents/dfimplementer.md`
- `agents/dfverifier.md`

---

### FASE 3: User Story Decomposition (Prioridad ALTA)

**Objetivo**: Organizar tareas por User Stories con prioridades P1/P2/P3

**Implementacion**:

1. **Actualizar template de spec**:
```markdown
## User Stories

### US-001: [Titulo] (Priority: P1 - MVP)
**Como** [rol]
**Quiero** [funcionalidad]
**Para** [beneficio]

#### Criterios de Aceptacion
- [ ] AC-001: Given/When/Then
- [ ] AC-002: Given/When/Then

#### Test Independiente
Este US puede probarse de forma aislada porque...
```

2. **Actualizar template de tasks**:
```markdown
## Phase 1: Setup (Foundational)
- [ ] T001 Create project structure

## Phase 2: US-001 (P1 - MVP)
- [ ] T010 [P] [US-001] Create User entity
- [ ] T011 [P] [US-001] Create UserRepository interface
- [ ] T012 [US-001] Implement UserRepositoryImpl

## Phase 3: US-002 (P2)
- [ ] T020 [P] [US-002] Create Product entity
```

3. **Agregar modelo UserStory**:
```dart
class UserStory {
  final String id;           // US-001
  final String title;
  final Priority priority;   // P1, P2, P3
  final String asA;          // rol
  final String iWant;        // funcionalidad
  final String soThat;       // beneficio
  final List<AcceptanceCriteria> criteria;
  final bool isIndependentlyTestable;
}
```

**Archivos nuevos**:
- `lib/src/models/user_story.dart`
- `lib/src/models/acceptance_criteria.dart`
- `lib/src/parsers/user_story_parser.dart`

**Archivos a modificar**:
- `templates/specs/feature.spec.md`
- `agents/dfspec.md`
- `agents/dftasks.md`

---

### FASE 4: Cross-Artifact Consistency Analysis (Prioridad MEDIA)

**Objetivo**: Mejorar /df-analyze para detectar inconsistencias entre spec, plan, tasks y codigo

**Implementacion**:

1. **Crear ConsistencyAnalyzer**:
```dart
class ConsistencyAnalyzer {
  Future<ConsistencyReport> analyze({
    required String specPath,
    required String planPath,
    required String tasksPath,
    String? codePath,
  });

  List<Inconsistency> findMissingRequirements();
  List<Inconsistency> findOrphanedTasks();
  List<Inconsistency> findUntestedCode();
  CoverageMatrix buildCoverageMatrix();
}

class Inconsistency {
  final String id;
  final Severity severity;  // CRITICAL, HIGH, MEDIUM, LOW
  final String artifact1;
  final String artifact2;
  final String description;
  final String suggestion;
}
```

2. **Generar matriz de cobertura**:
```
Requirement -> User Story -> Task -> Test -> Code
FR-001      -> US-001     -> T010 -> test_user.dart -> user.dart
FR-002      -> US-001     -> T011 -> (MISSING)      -> (MISSING)
```

3. **Reportes por severidad**:
- CRITICAL: Requisito sin implementacion
- HIGH: Codigo sin test
- MEDIUM: Task sin mapeo a US
- LOW: Documentacion desactualizada

**Archivos nuevos**:
- `lib/src/analyzers/consistency_analyzer.dart`
- `lib/src/analyzers/coverage_matrix.dart`
- `lib/src/models/inconsistency.dart`
- `lib/src/models/consistency_report.dart`

**Archivos a modificar**:
- `agents/dfanalyzer.md`
- `.claude/commands/df-analyze.md`

---

### FASE 5: CLI Interactivo (Prioridad MEDIA)

**Objetivo**: Mejorar UX del CLI con seleccion interactiva

**Implementacion**:

1. **Agregar dependencia**:
```yaml
dependencies:
  interact: ^2.0.0  # O similar para Dart
```

2. **Crear InteractivePrompt**:
```dart
class InteractivePrompt {
  Future<String> select({
    required String prompt,
    required List<String> options,
    String? defaultValue,
  });

  Future<bool> confirm(String message);

  Future<String> input(String prompt, {String? defaultValue});
}
```

3. **Mejorar init command**:
```
$ dfspec init

? Nombre del proyecto: mi-app
? Tipo de proyecto:
  > Flutter App
    Flutter Package
    Dart CLI
    Dart Package
? State management:
  > Riverpod
    BLoC
    Provider
    GetX
? Plataformas:
  [x] Android
  [x] iOS
  [ ] Web
  [ ] Desktop

Creando proyecto mi-app...
```

**Archivos nuevos**:
- `lib/src/ui/interactive_prompt.dart`
- `lib/src/ui/spinner.dart`
- `lib/src/ui/progress_bar.dart`

**Archivos a modificar**:
- `lib/src/commands/init_command.dart`
- `pubspec.yaml`

---

### FASE 6: Branch Auto-Numbering Mejorado (Prioridad MEDIA)

**Objetivo**: Auto-detectar siguiente numero de feature

**Implementacion**:

1. **Mejorar FeatureNumbering**:
```dart
class FeatureNumbering {
  /// Escanea todas las fuentes para encontrar el siguiente numero
  Future<int> getNextFeatureNumber() async {
    final sources = await Future.wait([
      _scanRemoteBranches(),
      _scanLocalBranches(),
      _scanSpecsDirectory(),
      _scanPlansDirectory(),
    ]);

    final allNumbers = sources.expand((s) => s).toSet();
    return _findNextAvailable(allNumbers);
  }

  /// Genera nombre de branch
  String generateBranchName(int number, String shortName) {
    return '${number.toString().padLeft(3, '0')}-$shortName';
  }
}
```

2. **Integrar en create-feature.sh**:
```bash
# Auto-detect next number
NEXT_NUM=$(dfspec feature --next-number)
BRANCH_NAME=$(dfspec feature --generate-name "$NEXT_NUM" "$SHORT_NAME")
```

**Archivos nuevos**:
- `lib/src/utils/feature_numbering.dart`

**Archivos a modificar**:
- `lib/src/commands/generate_command.dart`
- `scripts/create-feature.sh`

---

### FASE 7: JSON Output para Scripts (Prioridad MEDIA)

**Objetivo**: Todos los scripts generan JSON parseables por Claude

**Implementacion**:

1. **Estandarizar output JSON**:
```json
{
  "success": true,
  "feature_number": "001",
  "branch_name": "001-auth-oauth",
  "spec_file": "/absolute/path/to/spec.md",
  "plan_file": "/absolute/path/to/plan.md",
  "created_files": [
    "/path/to/file1.dart",
    "/path/to/file2.dart"
  ],
  "next_steps": [
    {"command": "/df-plan", "description": "Create implementation plan"}
  ]
}
```

2. **Actualizar todos los scripts**:
- `create-feature.sh --json`
- `validate-spec.sh --json`
- `run-quality.sh --json`
- `setup-plan.sh --json`

**Archivos a modificar**:
- `scripts/*.sh` (todos)

---

### FASE 8: Checklist Integrado en Templates (Prioridad BAJA)

**Objetivo**: Templates con checklists de validacion automatica

**Implementacion**:

1. **Agregar checklist al final de cada template**:
```markdown
---
## Checklist de Validacion (Auto-generado)

### Completitud
- [ ] Todos los requisitos funcionales tienen ID (FR-XXX)
- [ ] Todas las User Stories tienen prioridad (P1/P2/P3)
- [ ] Cada US tiene criterios de aceptacion
- [ ] No hay [NEEDS CLARIFICATION] sin resolver

### Calidad
- [ ] Requisitos son SMART (Specific, Measurable, Achievable, Relevant, Time-bound)
- [ ] No hay ambiguedades
- [ ] Scope esta bien definido

### Trazabilidad
- [ ] FR -> US mapping completo
- [ ] US -> AC mapping completo
```

2. **Comando para validar checklist**:
```bash
dfspec validate spec.md --checklist
```

---

### FASE 9: Mejor Manejo de Errores (Prioridad BAJA)

**Objetivo**: Mensajes de error utiles con sugerencias

**Implementacion**:

1. **Crear ErrorHandler mejorado**:
```dart
class DfspecError extends Error {
  final String code;           // AGENT_NOT_FOUND
  final String message;        // Human-readable
  final String? suggestion;    // Como resolver
  final String? documentation; // Link a docs

  @override
  String toString() => '''
Error: $message
Codigo: $code
${suggestion != null ? 'Sugerencia: $suggestion' : ''}
${documentation != null ? 'Documentacion: $documentation' : ''}
''';
}
```

2. **Catalog de errores**:
```dart
class ErrorCatalog {
  static DfspecError agentNotFound(String id) => DfspecError(
    code: 'AGENT_NOT_FOUND',
    message: 'Agente "$id" no encontrado',
    suggestion: 'Ejecuta "dfspec agents" para ver agentes disponibles',
    documentation: 'https://github.com/juansuarez-pragma/dfspec-ai#agentes',
  );
}
```

---

## Resumen de Prioridades

| Fase | Nombre | Prioridad | Complejidad | Impacto |
|------|--------|-----------|-------------|---------|
| 1 | Handoffs Automaticos | ALTA | Media | Alto |
| 2 | Constitutional Gates | ALTA | Alta | Alto |
| 3 | User Story Decomposition | ALTA | Media | Alto |
| 4 | Cross-Artifact Analysis | MEDIA | Alta | Medio |
| 5 | CLI Interactivo | MEDIA | Media | Medio |
| 6 | Branch Auto-Numbering | MEDIA | Baja | Medio |
| 7 | JSON Output Scripts | MEDIA | Baja | Medio |
| 8 | Checklist Templates | BAJA | Baja | Bajo |
| 9 | Mejor Manejo Errores | BAJA | Baja | Medio |

---

## Orden de Implementacion Recomendado

### Sprint 1 (Fases 1-3) - Core SDD Improvements
1. Fase 3: User Story Decomposition (base para las demas)
2. Fase 1: Handoffs Automaticos
3. Fase 2: Constitutional Gates

### Sprint 2 (Fases 4-6) - Analysis & UX
4. Fase 4: Cross-Artifact Analysis
5. Fase 7: JSON Output Scripts
6. Fase 6: Branch Auto-Numbering

### Sprint 3 (Fases 7-9) - Polish
7. Fase 5: CLI Interactivo
8. Fase 8: Checklist Templates
9. Fase 9: Mejor Manejo Errores

---

## Metricas de Exito

| Metrica | Actual | Objetivo |
|---------|--------|----------|
| Comandos con handoffs | 0/17 | 17/17 |
| Templates con US format | 0 | 100% |
| Scripts con JSON output | 2/6 | 6/6 |
| Constitutional gates | 0 | 5+ |
| Tests | 217 | 280+ |
| Cobertura | ~80% | >90% |

---

## Notas Tecnicas

### Compatibilidad
- Mantener backward compatibility con proyectos existentes
- Nuevos campos YAML opcionales (handoffs, gates)
- Migration path documentado

### Testing
- Cada fase incluye tests unitarios
- Tests de integracion para flujos completos
- Golden tests para output de comandos

### Documentacion
- Actualizar README con nuevas features
- Actualizar CLAUDE.md con nuevos comandos
- Crear guia de migracion v1 -> v2

---

*Documento generado: 2024-12-06*
*Version del plan: 2.0*
*Autor: Claude Code Analysis*
