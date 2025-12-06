# Constitucion DFSpec

Principios inmutables que rigen toda generacion de codigo con DFSpec.

> Estos articulos NO son negociables. Cualquier implementacion que los viole sera rechazada.

---

## Articulo I: Clean Architecture

Toda feature debe implementarse siguiendo Clean Architecture con separacion estricta de capas.

```
lib/src/
├── domain/          # Capa interna - NO depende de nada externo
│   ├── entities/    # Objetos de negocio inmutables
│   ├── repositories/# Interfaces (contratos)
│   └── usecases/    # Logica de negocio
├── data/            # Implementaciones de domain
│   ├── models/      # DTOs con fromJson/toEntity
│   ├── datasources/ # Acceso a datos (API, DB, Cache)
│   └── repositories/# Implementan interfaces de domain
├── presentation/    # UI y state management
│   ├── pages/       # Pantallas
│   ├── widgets/     # Componentes reutilizables
│   └── providers/   # State management
└── core/            # Compartido entre capas
    ├── constants/   # Valores constantes
    ├── theme/       # Estilos y colores
    ├── network/     # Cliente HTTP
    └── utils/       # Utilidades generales
```

**Regla de Dependencias:**
- Domain NO importa Data ni Presentation
- Data importa Domain (para implementar interfaces)
- Presentation importa Domain (para usar entidades y usecases)
- Core puede ser importado por cualquier capa

---

## Articulo II: Test-Driven Development

Todo codigo de produccion DEBE tener su test correspondiente escrito ANTES.

### Ciclo Obligatorio

```
1. RED    → Escribir test que falla
2. GREEN  → Escribir codigo minimo para pasar
3. REFACTOR → Mejorar sin romper tests
```

### Correspondencia 1:1

| Produccion | Test |
|------------|------|
| `lib/src/domain/entities/city.dart` | `test/unit/domain/city_test.dart` |
| `lib/src/data/models/city_model.dart` | `test/unit/data/city_model_test.dart` |
| `lib/src/presentation/widgets/city_search.dart` | `test/widget/city_search_test.dart` |

### Patron AAA

```dart
test('debe retornar lista de ciudades cuando query es valido', () async {
  // Arrange
  final mockRepository = MockCityRepository();
  when(() => mockRepository.search('Madrid')).thenAnswer((_) async => [city]);

  // Act
  final result = await usecase(query: 'Madrid');

  // Assert
  expect(result, equals([city]));
});
```

---

## Articulo III: Entidades Inmutables

Todas las entidades de dominio DEBEN ser inmutables usando Equatable.

```dart
import 'package:equatable/equatable.dart';

class City extends Equatable {
  const City({
    required this.id,
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String name;
  final String country;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [id, name, country, latitude, longitude];
}
```

**Prohibido:**
- Setters
- Campos mutables
- Modificacion de estado interno

---

## Articulo IV: Separacion Modelo-Entidad

Los modelos de datos (DTOs) DEBEN ser distintos de las entidades de dominio.

```dart
// DATA: Modelo (conoce JSON)
class CityModel {
  final int id;
  final String name;
  final String country;
  final double latitude;
  final double longitude;

  factory CityModel.fromJson(Map<String, dynamic> json) => CityModel(
    id: json['id'],
    name: json['name'],
    country: json['country'] ?? json['country_code'],
    latitude: json['latitude'],
    longitude: json['longitude'],
  );

  City toEntity() => City(
    id: id,
    name: name,
    country: country,
    latitude: latitude,
    longitude: longitude,
  );
}

// DOMAIN: Entidad (NO conoce JSON)
class City extends Equatable {
  // ... solo logica de negocio
}
```

---

## Articulo V: Interfaces en Domain

Los repositorios en Domain son INTERFACES (abstractas). Las implementaciones van en Data.

```dart
// domain/repositories/city_repository.dart
abstract class CityRepository {
  Future<List<City>> searchCities({required String query});
}

// data/repositories/city_repository_impl.dart
class CityRepositoryImpl implements CityRepository {
  CityRepositoryImpl({required this.datasource});

  final GeocodingDatasource datasource;

  @override
  Future<List<City>> searchCities({required String query}) async {
    final models = await datasource.search(query);
    return models.map((m) => m.toEntity()).toList();
  }
}
```

---

## Articulo VI: UseCases Atomicos

Cada UseCase tiene UNA sola responsabilidad y UN metodo `call()`.

```dart
class SearchCities {
  SearchCities(this._repository);

  final CityRepository _repository;

  Future<List<City>> call({required String query}) async {
    if (query.length < 2) {
      throw ArgumentError('Query debe tener minimo 2 caracteres');
    }
    return _repository.searchCities(query: query);
  }
}

// Uso
final cities = await searchCitiesUseCase(query: 'Madrid');
```

---

## Articulo VII: State Management Consistente

El proyecto DEBE usar UN solo patron de state management, definido en `dfspec.yaml`.

### Riverpod (Recomendado)

```dart
// Notifier para estado mutable
class SelectedCityNotifier extends Notifier<City?> {
  @override
  City? build() => null;

  void select(City city) => state = city;
  void clear() => state = null;
}

final selectedCityProvider = NotifierProvider<SelectedCityNotifier, City?>(
  SelectedCityNotifier.new,
);

// FutureProvider para datos async
final citySearchProvider = FutureProvider.family<List<City>, String>(
  (ref, query) async {
    final usecase = ref.watch(searchCitiesProvider);
    return usecase(query: query);
  },
);
```

### BLoC (Alternativa)

```dart
class CitySearchBloc extends Bloc<CitySearchEvent, CitySearchState> {
  CitySearchBloc(this._searchCities) : super(CitySearchInitial()) {
    on<SearchCitiesRequested>(_onSearchRequested);
  }

  final SearchCities _searchCities;

  Future<void> _onSearchRequested(
    SearchCitiesRequested event,
    Emitter<CitySearchState> emit,
  ) async {
    emit(CitySearchLoading());
    try {
      final cities = await _searchCities(query: event.query);
      emit(CitySearchLoaded(cities));
    } catch (e) {
      emit(CitySearchError(e.toString()));
    }
  }
}
```

---

## Articulo VIII: Manejo de Errores

Usar excepciones tipadas para errores esperados.

```dart
// core/error/exceptions.dart
class ServerException implements Exception {
  ServerException(this.message);
  final String message;
}

class NetworkException implements Exception {
  NetworkException(this.message);
  final String message;
}

class CacheException implements Exception {
  CacheException(this.message);
  final String message;
}

// Uso en datasource
Future<List<CityModel>> search(String query) async {
  final response = await client.get(uri);

  if (response.statusCode != 200) {
    throw ServerException('Error ${response.statusCode}');
  }

  return CityModel.listFromJson(jsonDecode(response.body));
}
```

---

## Articulo IX: Cobertura Minima

Todo proyecto DEBE mantener cobertura de tests >85%.

| Capa | Cobertura Minima |
|------|------------------|
| Domain (entities, usecases) | 95% |
| Data (models, repositories) | 90% |
| Presentation (providers) | 80% |
| Widgets | 70% |

---

## Articulo X: Performance Flutter

Todo codigo de UI DEBE respetar el frame budget de 16ms.

### Prohibido

- `setState()` innecesarios
- Builds en cada frame
- Listas sin `ListView.builder`
- Imagenes sin cache/resize
- Operaciones pesadas en main thread

### Obligatorio

```dart
// Usar const donde sea posible
const SizedBox(height: 16);

// Keys en listas
ListView.builder(
  itemBuilder: (context, index) => ListTile(
    key: ValueKey(items[index].id),
    // ...
  ),
);

// Memoizacion con select
final name = ref.watch(cityProvider.select((c) => c?.name));
```

---

## Articulo XI: Documentacion Minima

Todo archivo publico DEBE tener documentacion siguiendo Effective Dart.

```dart
/// Entidad que representa una ciudad.
///
/// Contiene informacion geografica basica incluyendo coordenadas
/// para uso con APIs de geolocalizacion.
class City extends Equatable {
  /// Crea una instancia de [City].
  ///
  /// Todos los parametros son requeridos.
  const City({
    required this.id,
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  /// Identificador unico de la ciudad.
  final int id;

  /// Nombre de la ciudad en idioma local.
  final String name;

  // ...
}
```

---

## Violaciones y Consecuencias

| Violacion | Consecuencia |
|-----------|--------------|
| Codigo sin test | Rechazado |
| Dependencia circular entre capas | Rechazado |
| Entidad mutable | Rechazado |
| Modelo mezclado con entidad | Rechazado |
| Cobertura <85% | Advertencia, requiere justificacion |
| Frame >16ms | Requiere optimizacion |

---

*Estos principios garantizan que todo codigo generado por DFSpec sea de alta calidad, mantenible y escalable.*
