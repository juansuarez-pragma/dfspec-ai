# CLAUDE.md

Este archivo proporciona instrucciones a Claude Code cuando trabaja con proyectos que usan DFSpec.

## Descripcion

DFSpec es un toolkit de Spec-Driven Development (SDD) especializado en Dart/Flutter. Transforma especificaciones en implementaciones de alta calidad siguiendo TDD estricto y Clean Architecture.

## Comandos Disponibles

### Flujo Principal

| Comando | Uso | Descripcion |
|---------|-----|-------------|
| `/df-spec <feature>` | Crear spec | Define QUE construir |
| `/df-plan <feature>` | Crear plan | Define COMO construir |
| `/df-implement <feature>` | Implementar | TDD: Red → Green → Refactor |
| `/df-verify <feature>` | Verificar | Valida implementacion vs spec |
| `/df-status` | Estado | Dashboard del proyecto |

### Calidad

| Comando | Enfoque |
|---------|---------|
| `/df-test` | Testing (unit, widget, integration) |
| `/df-review` | SOLID, Clean Architecture |
| `/df-security` | OWASP Mobile Top 10 |
| `/df-performance` | 60fps, memory leaks |
| `/df-quality` | Complejidad, code smells |
| `/df-docs` | Effective Dart |
| `/df-deps` | Dependencias seguras |
| `/df-orchestrate` | Pipeline de agentes |

## Principios Obligatorios

### Clean Architecture

```
lib/src/
├── domain/          # Entidades, interfaces, usecases
├── data/            # Models, datasources, repositories impl
├── presentation/    # Pages, widgets, providers
└── core/            # Constants, theme, network, utils
```

**Regla de dependencias:**
- Domain NO importa Data ni Presentation
- Data importa Domain
- Presentation importa Domain

### TDD Estricto

1. **RED**: Test que falla primero
2. **GREEN**: Codigo minimo para pasar
3. **REFACTOR**: Mejorar sin romper tests

Cada `lib/src/X.dart` requiere `test/unit/X_test.dart`

### Entidades Inmutables

```dart
class City extends Equatable {
  const City({required this.id, required this.name});
  final int id;
  final String name;
  @override
  List<Object?> get props => [id, name];
}
```

### Separacion Modelo-Entidad

```dart
// Data: conoce JSON
class CityModel {
  factory CityModel.fromJson(Map<String, dynamic> json) => ...
  City toEntity() => City(id: id, name: name);
}

// Domain: NO conoce JSON
class City extends Equatable { ... }
```

## State Management

Usar el patron definido en `dfspec.yaml`:

### Riverpod (Recomendado)

```dart
final selectedCityProvider = NotifierProvider<SelectedCityNotifier, City?>(
  SelectedCityNotifier.new,
);

final citySearchProvider = FutureProvider.family<List<City>, String>(
  (ref, query) => ref.watch(searchCitiesProvider)(query: query),
);
```

### BLoC

```dart
class CitySearchBloc extends Bloc<CitySearchEvent, CitySearchState> {
  on<SearchRequested>(_onSearch);
}
```

## Herramientas MCP Disponibles

- `mcp__dart__analyze_files` - Analisis estatico
- `mcp__dart__run_tests` - Ejecutar tests
- `mcp__dart__dart_format` - Formatear codigo
- `mcp__dart__dart_fix` - Aplicar fixes
- `mcp__dart__pub` - Comandos pub (get, add, outdated)
- `mcp__dart__pub_dev_search` - Buscar paquetes

## Umbrales de Calidad

| Metrica | Objetivo |
|---------|----------|
| Cobertura tests | >85% |
| Complejidad ciclomatica | <10 |
| Complejidad cognitiva | <8 |
| LOC por archivo | <400 |
| Frame budget | <16ms |

## Estructura de Especificaciones

```
docs/specs/
├── features/
│   └── <feature>.spec.md    # Requisitos y CA
└── plans/
    └── <feature>.plan.md    # Arquitectura y orden TDD
```

## Configuracion del Proyecto

```yaml
# dfspec.yaml
project:
  name: mi-app
  type: flutter_app
  platforms: [web, android, ios]
  state_management: riverpod

features:
  mi-feature:
    status: planned  # planned → implemented → verified
```

## Patron de Tests

```dart
test('debe retornar ciudades cuando query es valido', () async {
  // Arrange
  when(() => repo.search('Madrid')).thenAnswer((_) async => [city]);

  // Act
  final result = await usecase(query: 'Madrid');

  // Assert
  expect(result, equals([city]));
});
```

## Referencias

- [Constitucion](memory/constitution.md) - Principios inmutables
- [Metodologia SDD](docs/spec-driven-flutter.md) - Flujo completo
- [README](README.md) - Documentacion principal
