# Plan de Implementacion: {{FEATURE_NAME}}

## Metadata
| Campo | Valor |
|-------|-------|
| Feature ID | {{FEATURE_ID}} |
| Proyecto | {{PROJECT_NAME}} |
| Tipo | {{PROJECT_TYPE}} |
| Plataformas | {{PLATFORMS}} |
| State Management | {{STATE_MANAGEMENT}} |
| Fecha | {{DATE}} |

## Diagrama de Arquitectura

```mermaid
graph TB
    subgraph Presentation
        PAGE[{{Feature}}Page]
        WIDGET[{{Feature}}Widget]
    end

    subgraph Domain
        ENTITY[{{Entity}} Entity]
        REPO_INT[{{Entity}}Repository Interface]
        USECASE[{{UseCase}} UseCase]
    end

    subgraph Data
        MODEL[{{Entity}}Model]
        DS[{{Entity}}RemoteDatasource]
        REPO_IMPL[{{Entity}}RepositoryImpl]
    end

    subgraph Core
        CONSTANTS[Constants]
        NETWORK[ApiClient]
    end

    PAGE --> WIDGET
    USECASE --> REPO_INT
    REPO_IMPL -.-> REPO_INT
    REPO_IMPL --> DS
    MODEL --> ENTITY
```

## Lista de Archivos

### Archivos NUEVOS a Crear

#### Core (si aplica)
| # | Archivo | Complejidad | Descripcion |
|---|---------|-------------|-------------|
| 1 | `lib/src/core/constants/{{feature}}_constants.dart` | S | Constantes |

#### Domain
| # | Archivo | Complejidad | Descripcion |
|---|---------|-------------|-------------|
| 2 | `lib/src/domain/entities/{{entity}}.dart` | S | Entidad |
| 3 | `lib/src/domain/repositories/{{entity}}_repository.dart` | S | Interface |
| 4 | `lib/src/domain/usecases/{{usecase}}.dart` | S | UseCase |

#### Data
| # | Archivo | Complejidad | Descripcion |
|---|---------|-------------|-------------|
| 5 | `lib/src/data/models/{{entity}}_model.dart` | S | Modelo con fromJson |
| 6 | `lib/src/data/datasources/{{entity}}_remote_datasource.dart` | M | Llamadas API |
| 7 | `lib/src/data/repositories/{{entity}}_repository_impl.dart` | S | Implementacion |

#### Presentation
| # | Archivo | Complejidad | Descripcion |
|---|---------|-------------|-------------|
| 8 | `lib/src/presentation/providers/{{feature}}_providers.dart` | M | Providers |
| 9 | `lib/src/presentation/widgets/{{feature}}_widget.dart` | M | Widget principal |

### Archivos EXISTENTES a Modificar
| # | Archivo | Cambios |
|---|---------|---------|
| - | `lib/main.dart` | Integrar nueva feature |

## Orden de Implementacion TDD

### Fase 1: Domain

#### 1.1 {{Entity}} Entity
- **Test:** `test/unit/domain/{{entity}}_test.dart`
- **Impl:** `lib/src/domain/entities/{{entity}}.dart`
- **Criterios:**
  - [ ] Props definidos
  - [ ] Extiende Equatable
  - [ ] Inmutable (const constructor)

#### 1.2 {{UseCase}} UseCase
- **Test:** `test/unit/domain/{{usecase}}_test.dart`
- **Impl:** `lib/src/domain/usecases/{{usecase}}.dart`
- **Criterios:**
  - [ ] Valida parametros
  - [ ] Llama repositorio
  - [ ] Retorna tipo correcto

### Fase 2: Data

#### 2.1 {{Entity}}Model
- **Test:** `test/unit/data/{{entity}}_model_test.dart`
- **Impl:** `lib/src/data/models/{{entity}}_model.dart`
- **Criterios:**
  - [ ] fromJson parsea correctamente
  - [ ] toEntity convierte a entidad

#### 2.2 {{Entity}}RemoteDatasource
- **Test:** `test/unit/data/{{entity}}_datasource_test.dart`
- **Impl:** `lib/src/data/datasources/{{entity}}_remote_datasource.dart`
- **Criterios:**
  - [ ] Construye URL correctamente
  - [ ] Maneja errores HTTP
  - [ ] Retorna lista de modelos

#### 2.3 {{Entity}}RepositoryImpl
- **Test:** `test/unit/data/{{entity}}_repository_test.dart`
- **Impl:** `lib/src/data/repositories/{{entity}}_repository_impl.dart`
- **Criterios:**
  - [ ] Implementa interface
  - [ ] Convierte modelos a entidades

### Fase 3: Presentation

#### 3.1 {{Feature}}Providers
- **Test:** `test/unit/presentation/{{feature}}_providers_test.dart`
- **Impl:** `lib/src/presentation/providers/{{feature}}_providers.dart`
- **Criterios:**
  - [ ] Providers definidos
  - [ ] Estado inicial correcto

#### 3.2 {{Feature}}Widget
- **Test:** `test/widget/{{feature}}_widget_test.dart`
- **Impl:** `lib/src/presentation/widgets/{{feature}}_widget.dart`
- **Criterios:**
  - [ ] Renderiza correctamente
  - [ ] Maneja estados (loading, error, data)

## Checkpoints

### CP-1: Domain Completo
```bash
flutter test test/unit/domain/
```
**Criterio:** Entidad y UseCase funcionan

### CP-2: Data Completo
```bash
flutter test test/unit/data/
```
**Criterio:** Model, Datasource y Repository funcionan

### CP-3: Presentation Completo
```bash
flutter test test/unit/presentation/ test/widget/
```
**Criterio:** Providers y Widgets funcionan

### CP-FINAL: Integracion
```bash
flutter test
flutter run -d chrome
```
**Criterio:** Feature funciona end-to-end

## Mapeo RF -> Archivos

| Requisito | Archivos |
|-----------|----------|
| RF-01 | {{FILES_RF01}} |
| RF-02 | {{FILES_RF02}} |

## Mapeo CA -> Tests

| CA | Test |
|----|------|
| CA-01 | {{TEST_CA01}} |
| CA-02 | {{TEST_CA02}} |

## Riesgos

| Riesgo | Mitigacion |
|--------|------------|
| {{RISK_1}} | {{MITIGATION_1}} |
| {{RISK_2}} | {{MITIGATION_2}} |
