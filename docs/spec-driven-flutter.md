# Spec-Driven Development para Flutter

## Introduccion

Spec-Driven Development (SDD) es una metodologia que invierte el flujo tradicional de desarrollo de software. En lugar de escribir codigo y documentar despues, **las especificaciones son la fuente primaria de verdad** y el codigo es simplemente su expresion en un lenguaje de programacion.

> *"Las especificaciones no sirven al codigo—el codigo sirve a las especificaciones."*

DFSpec adapta esta metodologia especificamente para el ecosistema **Dart/Flutter**, integrando patrones y practicas que son estandar en la comunidad.

## Principios Fundamentales

### 1. Especificaciones como Lingua Franca

La especificacion es el artefacto primario de comunicacion. Todos los stakeholders—desarrolladores, diseñadores, QA, producto—trabajan sobre el mismo documento.

```
Especificacion (spec.md)
        |
    Plan (plan.md)
        |
    Codigo (lib/, test/)
```

### 2. Especificaciones Ejecutables

Las especificaciones deben ser lo suficientemente precisas para generar sistemas funcionales. Esto significa:

- **Criterios de aceptacion** claros y verificables
- **Requisitos funcionales** con inputs/outputs definidos
- **Contratos de API** especificados
- **Modelos de datos** documentados

### 3. TDD como Puente

El Test-Driven Development es el mecanismo que conecta especificaciones con implementacion:

```
Criterio de Aceptacion (CA-01)
        |
    Test (RED)
        |
    Implementacion (GREEN)
        |
    Refactor
        |
    CA-01 Verificado
```

### 4. Clean Architecture Obligatoria

Toda implementacion debe seguir Clean Architecture:

```
lib/src/
  domain/          # Entidades, Repositories (interfaces), UseCases
  data/            # Models, DataSources, Repositories (impl)
  presentation/    # Pages, Widgets, Providers
  core/            # Constants, Theme, Utils, Network
```

### 5. Refinamiento Continuo

La validacion ocurre permanentemente, no como una compuerta unica al final:

- `/df-spec` valida completitud de especificacion
- `/df-plan` valida coherencia arquitectonica
- `/df-implement` valida TDD estricto
- `/df-verify` valida implementacion vs spec

## Flujo de Trabajo SDD

### Fase 1: Especificacion (`/df-spec`)

Transforma una idea en una especificacion estructurada.

**Input:** Descripcion de feature
```bash
/df-spec "Busqueda de ciudades con geocoding API"
```

**Output:** `specs/features/NNN-feature/spec.md`

```markdown
# Especificacion: Busqueda de Ciudades

## Metadata
- Feature ID: 001-busqueda-ciudades
- Status: specified

## User Stories

### US-001: Buscar ciudad por nombre (Priority: P1)
**Como** usuario
**Quiero** buscar ciudades por nombre
**Para** encontrar el clima de mi ubicacion

#### Criterios de Aceptacion
- CA-001: DADO query "Madrid" CUANDO busco ENTONCES retorna ciudades
- CA-002: DADO query "M" CUANDO busco ENTONCES no hace request (min 2 chars)

## Requisitos Funcionales

### RF-001: Buscar ciudad por nombre
- Input: String (min 2 caracteres)
- Output: Lista de ciudades con coordenadas
- Comportamiento: Debounce 500ms

## API
- URL: https://geocoding-api.open-meteo.com
- Endpoint: /v1/search
```

### Fase 2: Planificacion (`/df-plan`)

Lee la especificacion y genera un plan de implementacion tecnico.

**Input:** Feature especificada
```bash
/df-plan busqueda-ciudades
```

**Output:** `specs/plans/NNN-feature.plan.md`

```markdown
# Plan de Implementacion: Busqueda de Ciudades

## Arquitectura
[Diagrama Mermaid]

## Archivos a Crear (Orden TDD)

### Domain (3 archivos)
1. lib/src/domain/entities/city.dart
2. lib/src/domain/repositories/city_repository.dart
3. lib/src/domain/usecases/search_cities.dart

### Data (3 archivos)
4. lib/src/data/models/city_model.dart
5. lib/src/data/datasources/geocoding_datasource.dart
6. lib/src/data/repositories/city_repository_impl.dart

### Presentation (2 archivos)
7. lib/src/presentation/providers/city_providers.dart
8. lib/src/presentation/widgets/city_search.dart

## Checkpoints
- CP-1: Domain completo (tests pasando)
- CP-2: Data completo (tests pasando)
- CP-3: Presentation completo (app funcional)
```

### Fase 3: Implementacion (`/df-implement`)

Implementa siguiendo el plan con TDD estricto.

**Ciclo por cada archivo:**

```
1. Crear test (RED)
   test/unit/domain/city_test.dart
   -> dart test -> FAIL

2. Implementar (GREEN)
   lib/src/domain/entities/city.dart
   -> dart test -> PASS

3. Refactor
   Mejorar codigo manteniendo tests verdes

4. Siguiente archivo...
```

**Reglas:**
- NUNCA escribir codigo de produccion sin test primero
- Cada `lib/src/X.dart` requiere `test/unit/X_test.dart`
- Tests en español siguiendo patron AAA (Arrange-Act-Assert)

### Fase 4: Verificacion (`/df-verify`)

Valida que la implementacion cumple la especificacion.

**Verifica:**
- Todos los RF implementados
- Todos los CA cubiertos por tests
- Estructura Clean Architecture correcta
- Tests pasando
- Cobertura >85%

**Output:** Reporte de cumplimiento
```
Feature: busqueda-ciudades
Status: VERIFIED

Requisitos Funcionales: 3/3 (100%)
Criterios Aceptacion: 5/5 (100%)
Tests: 15 passing
Cobertura: 92%
```

## Scripts de Automatizacion

DFSpec incluye scripts bash que retornan JSON estructurado:

```bash
# Detectar contexto del proyecto
./scripts/bash/detect-context.sh --json

# Verificar prerequisitos
./scripts/bash/check-prerequisites.sh --json --require-spec

# Crear nueva feature con branch
./scripts/bash/create-new-feature.sh "Mi Feature" --json

# Validar especificacion (score 0-100)
./scripts/bash/validate-spec.sh --json
```

## Trazabilidad

DFSpec mantiene trazabilidad completa entre artefactos:

```
spec.md          plan.md           codigo            tests
   |                |                 |                |
RF-001 -----> Archivos a crear --> city.dart --> city_test.dart
   |                |                 |                |
US-001 -----> Orden TDD ---------> impl ----------> cobertura
   |                |                 |                |
CA-001 -----> Checkpoint --------> verificacion --> PASS
```

Usar `dfspec trace <feature>` para ver la matriz de trazabilidad.

## Artefactos Generados

### Por Feature

```
proyecto/
  specs/
    features/
      001-busqueda-ciudades/
        spec.md
    plans/
      001-busqueda-ciudades.plan.md
  lib/src/
    domain/
      entities/city.dart
      repositories/city_repository.dart
      usecases/search_cities.dart
    data/
      models/city_model.dart
      datasources/geocoding_datasource.dart
      repositories/city_repository_impl.dart
    presentation/
      providers/city_providers.dart
      widgets/city_search.dart
  test/unit/
    domain/
      city_test.dart
      search_cities_test.dart
    data/
      city_model_test.dart
      city_repository_test.dart
```

### Configuracion del Proyecto

```yaml
# dfspec.yaml
project:
  name: mi-app
  type: flutter_app
  platforms: [web, android, ios]
  state_management: riverpod

features:
  busqueda-ciudades:
    status: verified  # planned -> implemented -> verified
```

## Comparativa: Tradicional vs SDD

| Aspecto | Tradicional | SDD con DFSpec |
|---------|-------------|----------------|
| Inicio | Codigo | Especificacion |
| Documentacion | Despues (si hay tiempo) | Primero (obligatoria) |
| Tests | Despues (si hay tiempo) | Antes (TDD) |
| Arquitectura | Emergente | Planificada |
| Cambios | Propagacion manual | Regeneracion |
| Validacion | Al final | Continua |
| Trazabilidad | Perdida | Completa |

## Beneficios para Flutter

### 1. State Management Consistente

DFSpec asegura uso consistente del state management elegido:

```dart
// Riverpod (recomendado)
final citySearchProvider = FutureProvider.family<List<City>, String>(...);

// BLoC
class CitySearchBloc extends Bloc<CitySearchEvent, CitySearchState> {...}

// Provider
class CitySearchProvider extends ChangeNotifier {...}
```

### 2. Testing Estructurado

```
test/
  unit/           # Logica de negocio
  widget/         # Widgets aislados
  integration/    # Flujos completos
  golden/         # Snapshots visuales
```

### 3. Performance Garantizado

Cada implementacion se valida contra:
- Frame budget <16ms (60fps)
- Sin widget rebuilds innecesarios
- Sin memory leaks
- Optimizacion de imagenes

### 4. Seguridad Integrada

Validacion automatica contra:
- OWASP Mobile Top 10
- Almacenamiento seguro
- Comunicaciones cifradas
- Platform Channels seguros

## Comandos Disponibles

### Flujo Principal
| Comando | Descripcion |
|---------|-------------|
| `/df-spec` | Crear especificacion |
| `/df-plan` | Generar plan tecnico |
| `/df-implement` | Implementar con TDD |
| `/df-verify` | Verificar vs spec |
| `/df-status` | Dashboard del proyecto |

### Calidad
| Comando | Descripcion |
|---------|-------------|
| `/df-test` | Testing especializado |
| `/df-review` | SOLID + Clean Architecture |
| `/df-security` | OWASP Mobile Top 10 |
| `/df-performance` | 60fps, memory leaks |
| `/df-quality` | Complejidad, code smells |

## Recursos

- [Constitucion DFSpec](../memory/constitution.md) - Principios inmutables
- [README principal](../README.md) - Documentacion completa
- [CLAUDE.md](../CLAUDE.md) - Contexto para Claude Code
