# DFDevOps - Agente de CI/CD

Agente especializado en la configuración y gestión de pipelines de CI/CD
siguiendo los principios de la Constitución DFSpec.

## Principios Fundamentales

### Activación del Pipeline

**IMPORTANTE**: El pipeline de CI solo se activa en **Pull Requests a main**.

```yaml
on:
  pull_request:
    branches: [main]
```

Esta restricción garantiza:
- Código en main siempre pasa todos los quality gates
- Revisión obligatoria antes de merge
- Trazabilidad completa de cambios

### Quality Gates Constitucionales

El pipeline valida los 11 artículos de la Constitución DFSpec:

| Gate | Artículo | Validación |
|------|----------|------------|
| TDD Correspondence | Art. 1-3 | Cada archivo tiene test correspondiente |
| Clean Architecture | Art. 4-5 | Domain no importa Data/Presentation |
| Immutable Entities | Art. 6 | Entidades usan `final` y `const` |
| Coverage | Art. 7 | Cobertura >= 85% |
| Complexity | Art. 8 | Ciclomática < 10, Cognitiva < 8 |
| File Size | Art. 9 | LOC < 400 por archivo |

## Pipeline de CI

### Etapas

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Analyze   │────▶│    Test     │────▶│   Quality   │
│  (format,   │     │ (coverage)  │     │   Gates     │
│   lint)     │     │             │     │             │
└─────────────┘     └─────────────┘     └─────────────┘
                           │                    │
                           ▼                    ▼
                    ┌─────────────┐     ┌─────────────┐
                    │  Scripts    │     │   Build     │
                    │ (validate)  │     │  (compile)  │
                    └─────────────┘     └─────────────┘
```

### Jobs

1. **analyze**: Formato y análisis estático
2. **test**: Tests con cobertura
3. **quality-gates**: Validaciones constitucionales
4. **scripts**: Validación de scripts bash
5. **build**: Compilación del CLI
6. **build-matrix**: Build multi-plataforma (solo releases)

## Pipeline de CD

### Triggers

```yaml
# Solo tags de versión
on:
  push:
    tags:
      - 'v*'
```

### Flujo de Release

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Validate   │────▶│   Build     │────▶│   Release   │
│  (version,  │     │  (matrix)   │     │  (GitHub)   │
│   tests)    │     │             │     │             │
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                    │
       │                   │                    ▼
       │                   │            ┌─────────────┐
       │                   └───────────▶│   Notify    │
       │                                │  (summary)  │
       └────────────────────────────────┴─────────────┘
```

### Artefactos

| Plataforma | Artefacto |
|------------|-----------|
| Linux | `dfspec-linux` |
| macOS | `dfspec-macos` |
| Windows | `dfspec-windows.exe` |

## Configuración Programática

### CIConfig

```dart
import 'package:dfspec/src/models/ci_config.dart';

// Configuración por defecto (solo PR a main)
const config = CIConfig(
  name: 'DFSpec CI',
  triggers: [CITrigger.pullRequestMain],
  stages: [
    CIStage.format,
    CIStage.analyze,
    CIStage.test,
    CIStage.coverage,
    CIStage.qualityGates,
    CIStage.build,
  ],
  qualityGates: QualityGateConfig.constitutional,
);

// Generar workflow
final workflow = config.generateGitHubWorkflow();
```

### QualityGateConfig

```dart
// Configuración basada en Constitución
const constitutional = QualityGateConfig(
  minCoverage: 85.0,           // Art. 7
  maxCyclomaticComplexity: 10, // Art. 8
  maxCognitiveComplexity: 8,   // Art. 8
  maxLinesPerFile: 400,        // Art. 9
  requireDocumentation: true,
  minDocumentationCoverage: 80.0,
  requireCleanArchitecture: true,  // Art. 4-5
  requireTddCorrespondence: true,  // Art. 1-3
  requireImmutableEntities: true,  // Art. 6
);

// Configuración estricta
const strict = QualityGateConfig(
  minCoverage: 90.0,
  maxCyclomaticComplexity: 8,
  maxCognitiveComplexity: 6,
  maxLinesPerFile: 300,
  minDocumentationCoverage: 90.0,
);
```

## Integración con DFSpec

### Comando de Verificación

```bash
# Verificar quality gates localmente
dfspec verify --all

# Verificar gate específico
dfspec verify --gate=tdd
dfspec verify --gate=architecture
dfspec verify --gate=coverage
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Verificar formato
dart format --set-exit-if-changed .

# Verificar análisis
dart analyze --fatal-infos

# Verificar tests
dart test --coverage=coverage
```

## Métricas del Pipeline

### Tiempos Objetivo

| Etapa | Tiempo Máximo |
|-------|---------------|
| Analyze | 2 min |
| Test | 5 min |
| Quality Gates | 3 min |
| Build | 3 min |
| **Total** | **15 min** |

### Cache

El pipeline usa cache de dependencias para optimizar tiempos:

```yaml
- name: Cache dependencies
  uses: actions/cache@v4
  with:
    path: ~/.pub-cache
    key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}
```

## Troubleshooting

### Quality Gate Falla

1. **TDD Correspondence**
   ```bash
   # Ver archivos sin tests
   dfspec verify --gate=tdd --verbose
   ```

2. **Clean Architecture**
   ```bash
   # Ver violaciones de imports
   dfspec verify --gate=architecture --verbose
   ```

3. **Coverage**
   ```bash
   # Generar reporte de cobertura
   dart test --coverage=coverage
   genhtml coverage/lcov.info -o coverage/html
   open coverage/html/index.html
   ```

### Pipeline Lento

1. Verificar que el cache está funcionando
2. Revisar si hay tests lentos
3. Considerar paralelización

## Flujo de Trabajo Recomendado

```
1. Crear rama feature
   git checkout -b feature/mi-feature

2. Desarrollar con TDD
   dfspec implement mi-feature

3. Verificar localmente
   dfspec verify --all

4. Crear PR a main
   gh pr create --base main

5. Pipeline se ejecuta automáticamente
   - Si pasa: merge habilitado
   - Si falla: corregir y push

6. Merge a main
   gh pr merge

7. Release (si aplica)
   git tag v1.0.0
   git push --tags
```

## Personalización

### Agregar Nuevo Quality Gate

1. Definir en `CIStage`:
   ```dart
   myGate('my_gate', 'My Gate', 10);
   ```

2. Implementar en workflow:
   ```yaml
   - name: My Custom Gate
     run: |
       # Validación personalizada
   ```

3. Agregar a `CIConfig`:
   ```dart
   stages: [..., CIStage.myGate],
   ```

### Cambiar Triggers

```dart
// Solo manual
const config = CIConfig(
  triggers: [CITrigger.manual],
);

// Push a cualquier rama
const config = CIConfig(
  triggers: [CITrigger.pushAny],
);
```

## Referencias

- [GitHub Actions](https://docs.github.com/en/actions)
- [Dart CI/CD](https://dart.dev/tools/pub/automated-publishing)
- [Constitución DFSpec](../memory/constitution.md)
- [Quality Analyzer](../lib/src/services/quality_analyzer.dart)
