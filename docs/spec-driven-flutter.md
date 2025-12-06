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
        ↓
    Plan (plan.md)
        ↓
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
        ↓
    Test (RED)
        ↓
    Implementacion (GREEN)
        ↓
    Refactor
        ↓
    CA-01 Verificado ✓
```

### 4. Clean Architecture Obligatoria

Toda implementacion debe seguir Clean Architecture:

```
┌─────────────────────────────────────────┐
│           Presentation                  │
│    (Pages, Widgets, Providers)          │
├─────────────────────────────────────────┤
│             Domain                      │
│   (Entities, Repositories, UseCases)    │
├─────────────────────────────────────────┤
│              Data                       │
│  (Models, DataSources, Repositories)    │
├─────────────────────────────────────────┤
│              Core                       │
│    (Constants, Theme, Utils, Network)   │
└─────────────────────────────────────────┘
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
```
/df-spec "Busqueda de ciudades con geocoding API"
```

**Output:** `docs/specs/features/<feature>.spec.md`
```markdown
# Especificacion: Busqueda de Ciudades

## Metadata
- Feature ID: FEAT-001
- Tipo: api_integration
- Estado: specified

## Requisitos Funcionales

### RF-01: Buscar ciudad por nombre
- Input: String (min 2 caracteres)
- Output: Lista de ciudades con coordenadas
- Comportamiento: Debounce 500ms

## Criterios de Aceptacion
- [ ] CA-01: DADO query "Madrid" CUANDO busco ENTONCES retorna ciudades
- [ ] CA-02: DADO query "M" CUANDO busco ENTONCES no hace request

## API
- URL: https://geocoding-api.open-meteo.com
- Endpoint: /v1/search
- Auth: None
```

### Fase 2: Planificacion (`/df-plan`)

Lee la especificacion y genera un plan de implementacion tecnico.

**Input:** Feature especificada
```
/df-plan busqueda-ciudades
```

**Output:** `docs/specs/plans/<feature>.plan.md`
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
   → flutter test → FAIL

2. Implementar (GREEN)
   lib/src/domain/entities/city.dart
   → flutter test → PASS

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
Status: VERIFIED ✓

Requisitos Funcionales: 3/3 (100%)
Criterios Aceptacion: 5/5 (100%)
Tests: 15 passing
Cobertura: 92%
```

## Artefactos Generados

### Por Feature

```
proyecto/
├── docs/
│   └── specs/
│       ├── features/
│       │   └── busqueda-ciudades.spec.md
│       └── plans/
│           └── busqueda-ciudades.plan.md
├── lib/
│   └── src/
│       ├── domain/
│       │   ├── entities/city.dart
│       │   ├── repositories/city_repository.dart
│       │   └── usecases/search_cities.dart
│       ├── data/
│       │   ├── models/city_model.dart
│       │   ├── datasources/geocoding_datasource.dart
│       │   └── repositories/city_repository_impl.dart
│       └── presentation/
│           ├── providers/city_providers.dart
│           └── widgets/city_search.dart
└── test/
    └── unit/
        ├── domain/
        │   ├── city_test.dart
        │   └── search_cities_test.dart
        └── data/
            ├── city_model_test.dart
            └── city_repository_test.dart
```

### Configuracion del Proyecto

```yaml
# dfspec.yaml
project:
  name: mi-app
  type: flutter_app
  platforms: [web, android, ios]
  state_management: riverpod
  path: /ruta/al/proyecto

directories:
  docs_dir: docs/specs

features:
  busqueda-ciudades:
    type: api_integration
    status: verified  # planned → implemented → verified
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
├── unit/           # Logica de negocio
├── widget/         # Widgets aislados
├── integration/    # Flujos completos
└── golden/         # Snapshots visuales
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

## Ejemplo Completo

Ver [docs/examples/weather-app.md](examples/weather-app.md) para un walkthrough completo de una aplicacion del clima construida con DFSpec.

## Recursos

- [Constitucion DFSpec](../memory/constitution.md) - Principios inmutables
- [Referencia de Comandos](commands/) - Documentacion de cada comando
- [Agentes](agents/) - Documentacion de los 11 agentes
