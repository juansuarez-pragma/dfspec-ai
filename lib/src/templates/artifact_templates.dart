import 'package:dfspec/src/models/spec_template.dart';

/// Templates de artefactos para generacion de especificaciones.
class ArtifactTemplates {
  const ArtifactTemplates._();

  /// Obtiene el template para un tipo de especificacion.
  static SpecTemplate getTemplate(SpecType type) {
    switch (type) {
      case SpecType.feature:
        return _featureTemplate;
      case SpecType.architecture:
        return _architectureTemplate;
      case SpecType.security:
        return _securityTemplate;
      case SpecType.performance:
        return _performanceTemplate;
      case SpecType.api:
        return _apiTemplate;
      case SpecType.plan:
        return _planTemplate;
    }
  }

  /// Lista todos los templates disponibles.
  static List<SpecTemplate> get all => [
    _featureTemplate,
    _architectureTemplate,
    _securityTemplate,
    _performanceTemplate,
    _apiTemplate,
    _planTemplate,
  ];

  static const _featureTemplate = SpecTemplate(
    type: SpecType.feature,
    name: 'Feature Specification',
    variables: {
      'title': 'Nombre de la Feature',
      'feature_id': '001',
      'date': '',
      'author': '',
      'version': '1.0',
    },
    content: _featureContent,
  );

  static const _architectureTemplate = SpecTemplate(
    type: SpecType.architecture,
    name: 'Architecture Decision Record',
    variables: {
      'title': 'Titulo de la Decision',
      'date': '',
      'status': 'proposed',
      'deciders': '',
    },
    content: _architectureContent,
  );

  static const _securityTemplate = SpecTemplate(
    type: SpecType.security,
    name: 'Security Specification',
    variables: {
      'title': 'Nombre del Componente',
      'date': '',
      'risk_level': 'medium',
    },
    content: _securityContent,
  );

  static const _performanceTemplate = SpecTemplate(
    type: SpecType.performance,
    name: 'Performance Specification',
    variables: {
      'title': 'Nombre del Componente',
      'date': '',
      'target_fps': '60',
    },
    content: _performanceContent,
  );

  static const _apiTemplate = SpecTemplate(
    type: SpecType.api,
    name: 'API Contract',
    variables: {'title': 'Nombre de la API', 'version': '1.0.0', 'date': ''},
    content: _apiContent,
  );

  static const _planTemplate = SpecTemplate(
    type: SpecType.plan,
    name: 'Implementation Plan',
    variables: {'title': 'Nombre de la Feature', 'spec_ref': '', 'date': ''},
    content: _planContent,
  );

  // ============================================================
  // CONTENIDOS DE TEMPLATES
  // ============================================================

  static const String _featureContent = '''
# Especificacion: {{title}}

> **Feature ID:** FEAT-{{feature_id}}
> **Version:** {{version}}
> **Fecha:** {{date}}
> **Autor:** {{author}}
> **Estado:** draft

## Resumen Ejecutivo

[Descripcion breve de la funcionalidad en 2-3 oraciones]

## Contexto

### Problema
[Que problema resuelve esta feature]

### Justificacion de Negocio
[Por que es necesaria esta solucion - valor para el usuario/negocio]

### Alcance
- **Incluye:** [Lista de lo que SI incluye]
- **Excluye:** [Lista de lo que NO incluye]

## User Stories

### US-01: [Titulo de la Historia]
**Como** [rol de usuario]
**Quiero** [accion/funcionalidad]
**Para** [beneficio/valor]

**Criterios de Aceptacion:**
- [ ] **DADO** [contexto inicial] **CUANDO** [accion] **ENTONCES** [resultado esperado]
- [ ] **DADO** [contexto inicial] **CUANDO** [accion] **ENTONCES** [resultado esperado]

**Prioridad:** Alta/Media/Baja
**Estimacion:** S/M/L/XL

---

### US-02: [Titulo de la Historia]
**Como** [rol de usuario]
**Quiero** [accion/funcionalidad]
**Para** [beneficio/valor]

**Criterios de Aceptacion:**
- [ ] **DADO** [contexto inicial] **CUANDO** [accion] **ENTONCES** [resultado esperado]

**Prioridad:** Alta/Media/Baja
**Estimacion:** S/M/L/XL

## Requisitos Funcionales

### RF-01: [Nombre del Requisito]
**Descripcion:** [Descripcion detallada]
**User Story:** US-01

**Criterios:**
- [ ] [Criterio especifico y medible]
- [ ] [Criterio especifico y medible]

### RF-02: [Nombre del Requisito]
**Descripcion:** [Descripcion detallada]
**User Story:** US-02

**Criterios:**
- [ ] [Criterio especifico y medible]

## Requisitos No Funcionales

### RNF-01: Rendimiento
- Tiempo de respuesta < 100ms
- Renderizado a 60fps
- Frame budget < 16ms

### RNF-02: Seguridad
- Validacion de todos los inputs
- Sanitizacion de datos de usuario
- No almacenar datos sensibles sin encriptar

### RNF-03: Accesibilidad
- Soporte para lectores de pantalla (Semantics)
- Contraste minimo AA (4.5:1)
- Touch targets >= 48x48

### RNF-04: Mantenibilidad
- Cobertura de tests >= 85%
- Complejidad ciclomatica < 10
- Documentacion de API publica

## Casos de Uso

### CU-01: [Nombre del Caso de Uso]
**Actor:** [Usuario/Sistema]
**User Story:** US-01
**Precondiciones:** [Estado inicial requerido]

**Flujo Principal:**
1. [Paso 1]
2. [Paso 2]
3. [Paso 3]

**Flujos Alternativos:**
- **FA-01:** [Variacion del flujo]
- **FA-02:** [Otra variacion]

**Flujos de Excepcion:**
- **FE-01:** [Manejo de error]

**Postcondiciones:** [Estado final esperado]

## Modelo de Datos

### Entidades de Dominio

```dart
/// [Descripcion de la entidad]
class EntityName extends Equatable {
  const EntityName({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
```

### Diagrama de Relaciones

```mermaid
erDiagram
    ENTITY1 ||--o{ ENTITY2 : contains
    ENTITY1 {
        string id PK
        string name
    }
    ENTITY2 {
        string id PK
        string entity1_id FK
    }
```

## Interfaces de Usuario

### Pantalla: [Nombre]
- **Proposito:** [Descripcion]
- **User Story:** US-01
- **Componentes:** [Lista de widgets]
- **Interacciones:** [Eventos de usuario]
- **Estados:** [Loading, Error, Empty, Success]

### Wireframe (ASCII)
```
+---------------------------+
|  [Header/AppBar]          |
+---------------------------+
|                           |
|  [Contenido principal]    |
|                           |
|  [Lista/Grid/Form]        |
|                           |
+---------------------------+
|  [Bottom Navigation]      |
+---------------------------+
```

## Dependencias

### Internas
- [Modulos del proyecto que se usaran]

### Externas (pub.dev)
| Paquete | Version | Proposito |
|---------|---------|-----------|
| [paquete] | ^X.Y.Z | [Para que se usa] |

## Matriz de Trazabilidad

| User Story | Requisitos | Casos de Uso | Tests |
|------------|------------|--------------|-------|
| US-01 | RF-01, RNF-01 | CU-01 | T-01, T-02 |
| US-02 | RF-02, RNF-02 | CU-02 | T-03 |

## Criterios de Aceptacion Globales

- [ ] **CA-01:** Todos los User Stories implementados
- [ ] **CA-02:** Cobertura de tests >= 85%
- [ ] **CA-03:** Cero errores de lint (dart analyze)
- [ ] **CA-04:** Performance: 60fps en dispositivo low-end
- [ ] **CA-05:** Accesibilidad: funciona con TalkBack/VoiceOver

## Riesgos y Mitigaciones

| ID | Riesgo | Probabilidad | Impacto | Mitigacion |
|----|--------|-------------|---------|------------|
| R-01 | [Riesgo 1] | Alta/Media/Baja | Alto/Medio/Bajo | [Estrategia] |
| R-02 | [Riesgo 2] | Alta/Media/Baja | Alto/Medio/Bajo | [Estrategia] |

## Definition of Done (DoD)

- [ ] Codigo implementado siguiendo Clean Architecture
- [ ] Tests unitarios escritos (TDD)
- [ ] Code review aprobado
- [ ] Documentacion actualizada
- [ ] Sin warnings de lint
- [ ] Quality gates pasando
- [ ] Criterios de aceptacion verificados

## Notas Tecnicas

[Consideraciones de implementacion, decisiones tecnicas, trade-offs, etc.]

## Referencias

- [Link a documentacion externa]
- [Link a diseños/mockups]
- [Link a APIs relacionadas]

---
*Generado con DFSpec - Spec-Driven Development para Flutter/Dart*
''';

  static const String _architectureContent = '''
# ADR: {{title}}

> **Estado:** {{status}}
> **Fecha:** {{date}}
> **Decisores:** {{deciders}}

## Contexto

[Descripcion del contexto tecnico y de negocio que motiva esta decision]

## Problema

[Declaracion clara del problema arquitectonico a resolver]

## Drivers de Decision

- [Driver 1: requisito, restriccion o fuerza]
- [Driver 2: requisito, restriccion o fuerza]
- [Driver 3: requisito, restriccion o fuerza]

## Opciones Consideradas

### Opcion 1: [Nombre]
**Descripcion:** [Breve descripcion]

**Pros:**
- [Ventaja 1]
- [Ventaja 2]

**Contras:**
- [Desventaja 1]
- [Desventaja 2]

### Opcion 2: [Nombre]
**Descripcion:** [Breve descripcion]

**Pros:**
- [Ventaja 1]

**Contras:**
- [Desventaja 1]

## Decision

[Descripcion de la decision tomada y justificacion]

## Consecuencias

### Positivas
- [Consecuencia positiva 1]
- [Consecuencia positiva 2]

### Negativas
- [Consecuencia negativa 1]
- [Trade-off aceptado]

### Neutras
- [Cambio sin valoracion]

## Diagrama

```mermaid
graph TD
    A[Componente A] --> B[Componente B]
    B --> C[Componente C]
```

## Validacion

[Como se validara que la decision fue correcta]

## Referencias

- [Link a documentacion relevante]
- [Link a discusion]

---
*Generado con DFSpec - Spec-Driven Development para Flutter/Dart*
''';

  static const String _securityContent = '''
# Especificacion de Seguridad: {{title}}

> **Fecha:** {{date}}
> **Nivel de Riesgo:** {{risk_level}}

## Resumen

[Descripcion del componente y su superficie de ataque]

## Activos a Proteger

| Activo | Tipo | Sensibilidad |
|--------|------|--------------|
| [Activo 1] | Datos/Proceso/Sistema | Alta/Media/Baja |

## Amenazas Identificadas (STRIDE)

### Spoofing (Suplantacion)
- [ ] [Amenaza identificada]
- **Mitigacion:** [Estrategia]

### Tampering (Manipulacion)
- [ ] [Amenaza identificada]
- **Mitigacion:** [Estrategia]

### Repudiation (Repudio)
- [ ] [Amenaza identificada]
- **Mitigacion:** [Estrategia]

### Information Disclosure (Fuga de Informacion)
- [ ] [Amenaza identificada]
- **Mitigacion:** [Estrategia]

### Denial of Service (Denegacion de Servicio)
- [ ] [Amenaza identificada]
- **Mitigacion:** [Estrategia]

### Elevation of Privilege (Escalada de Privilegios)
- [ ] [Amenaza identificada]
- **Mitigacion:** [Estrategia]

## OWASP Mobile Top 10

### M1: Uso Inapropiado de Plataforma
- [ ] Permisos minimos necesarios
- [ ] APIs de plataforma usadas correctamente

### M2: Almacenamiento Inseguro
- [ ] Datos sensibles encriptados
- [ ] No uso de SharedPreferences para secretos
- [ ] flutter_secure_storage implementado

### M3: Comunicacion Insegura
- [ ] TLS 1.2+ obligatorio
- [ ] Certificate pinning implementado
- [ ] No datos sensibles en URLs

### M4: Autenticacion Insegura
- [ ] Tokens con expiracion
- [ ] Refresh token seguro
- [ ] Biometria como segundo factor

### M5: Criptografia Insuficiente
- [ ] Algoritmos modernos (AES-256, RSA-2048+)
- [ ] Keys no hardcodeadas
- [ ] Gestion segura de keys

## Requisitos de Seguridad

### RS-01: Autenticacion
[Requisito especifico]

### RS-02: Autorizacion
[Requisito especifico]

### RS-03: Encriptacion
[Requisito especifico]

### RS-04: Logging y Auditoria
[Requisito especifico]

## Validacion de Inputs

| Campo | Tipo | Validacion | Sanitizacion |
|-------|------|------------|--------------|
| [campo] | String/Int/etc | [regex/rango] | [escape/strip] |

## Plan de Pruebas de Seguridad

- [ ] Analisis estatico (SAST)
- [ ] Pruebas de penetracion
- [ ] Revision de dependencias

---
*Generado con DFSpec - Spec-Driven Development para Flutter/Dart*
''';

  static const String _performanceContent = '''
# Especificacion de Rendimiento: {{title}}

> **Fecha:** {{date}}
> **Target FPS:** {{target_fps}}

## Objetivos de Rendimiento

| Metrica | Objetivo | Critico |
|---------|----------|---------|
| Frame time | < 16ms | < 32ms |
| App startup | < 2s | < 4s |
| Memory footprint | < 100MB | < 200MB |
| Battery drain | < 5%/hr | < 10%/hr |

## Analisis de Componentes

### Componente: [Nombre]
**Tipo:** Widget/Service/Repository

**Metricas actuales:**
- Frame time: [X]ms
- Rebuilds/frame: [N]

**Optimizaciones requeridas:**
- [ ] [Optimizacion 1]
- [ ] [Optimizacion 2]

## Estrategias de Optimizacion

### Renderizado

#### Widgets Const
```dart
// Antes
Widget build(context) => Container(child: Text('Hello'));

// Despues
Widget build(context) => const Text('Hello');
```

#### RepaintBoundary
- [ ] Identificar widgets que cambian frecuentemente
- [ ] Envolver en RepaintBoundary

#### Keys
- [ ] Usar ValueKey para listas con reordenamiento
- [ ] Evitar GlobalKey innecesarias

### Listas y Grids

- [ ] Usar ListView.builder para listas largas
- [ ] Implementar paginacion
- [ ] Lazy loading de imagenes

### Estado

- [ ] Minimizar rebuilds con Selector/Consumer
- [ ] Evitar setState en widgets padre
- [ ] Usar const constructors

### Memoria

- [ ] Dispose de controllers
- [ ] Cache con limite de tamano
- [ ] Evitar closures que capturen contexto

### Red

- [ ] Caching de respuestas HTTP
- [ ] Compresion de payloads
- [ ] Debounce de requests

## Benchmarks Requeridos

| Escenario | Dispositivo | Target |
|-----------|-------------|--------|
| Lista 1000 items | Low-end | 60fps |
| Scroll rapido | Mid-range | 60fps |
| Carga inicial | Low-end | < 3s |

## Herramientas de Medicion

- [ ] Flutter DevTools - Performance
- [ ] Flutter DevTools - Memory
- [ ] Custom PerformanceOverlay
- [ ] Firebase Performance

## Criterios de Aceptacion

- [ ] **CP-01:** Frame time promedio < 16ms
- [ ] **CP-02:** Sin jank visible en scroll
- [ ] **CP-03:** Memory estable (sin leaks)
- [ ] **CP-04:** Startup time < objetivo

---
*Generado con DFSpec - Spec-Driven Development para Flutter/Dart*
''';

  static const String _apiContent = '''
# Contrato de API: {{title}}

> **Version:** {{version}}
> **Fecha:** {{date}}

## Informacion General

- **Base URL:** `https://api.example.com/v1`
- **Autenticacion:** Bearer Token
- **Content-Type:** application/json

## Endpoints

### [Recurso] - [Accion]

**Endpoint:** `[METHOD] /path/{param}`

**Descripcion:** [Que hace este endpoint]

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters:**
| Parametro | Tipo | Requerido | Descripcion |
|-----------|------|-----------|-------------|
| param | string | Si | [Descripcion] |

**Query Parameters:**
| Parametro | Tipo | Default | Descripcion |
|-----------|------|---------|-------------|
| page | int | 1 | Numero de pagina |
| limit | int | 20 | Items por pagina |

**Request Body:**
```json
{
  "field1": "string",
  "field2": 123,
  "nested": {
    "subfield": true
  }
}
```

**Response 200:**
```json
{
  "data": {
    "id": "uuid",
    "field1": "value"
  },
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

**Response 400:**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Campo requerido faltante",
    "details": [
      {"field": "field1", "message": "Es requerido"}
    ]
  }
}
```

**Response 401:**
```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Token invalido o expirado"
  }
}
```

## Modelos de Datos

### Entity
```dart
class Entity {
  final String id;
  final String name;
  final DateTime createdAt;

  factory Entity.fromJson(Map<String, dynamic> json) => Entity(
    id: json['id'] as String,
    name: json['name'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
```

## Codigos de Error

| Codigo | HTTP | Descripcion |
|--------|------|-------------|
| VALIDATION_ERROR | 400 | Datos de entrada invalidos |
| UNAUTHORIZED | 401 | No autenticado |
| FORBIDDEN | 403 | Sin permisos |
| NOT_FOUND | 404 | Recurso no encontrado |
| RATE_LIMITED | 429 | Demasiadas peticiones |
| SERVER_ERROR | 500 | Error interno |

## Rate Limiting

- **Limite:** 100 requests/minuto
- **Header:** `X-RateLimit-Remaining`
- **Reset:** `X-RateLimit-Reset`

## Versionado

- Version en URL: `/v1/`, `/v2/`
- Deprecation header: `Sunset: date`

---
*Generado con DFSpec - Spec-Driven Development para Flutter/Dart*
''';

  static const String _planContent = '''
# Plan de Implementacion: {{title}}

> **Especificacion:** {{spec_ref}}
> **Fecha:** {{date}}
> **Estado:** draft

## Resumen

[Breve descripcion del plan de implementacion]

## User Stories a Implementar

| ID | Titulo | Prioridad | Estimacion |
|----|--------|-----------|------------|
| US-01 | [Titulo] | Alta | M |
| US-02 | [Titulo] | Media | S |

## Prerequisitos

- [ ] Especificacion aprobada
- [ ] User Stories revisadas con stakeholders
- [ ] Dependencias identificadas
- [ ] Ambiente de desarrollo listo

## Arquitectura

```mermaid
graph TD
    subgraph Presentation
        A[Widget] --> B[Bloc/Cubit]
    end
    subgraph Domain
        B --> C[UseCase]
        C --> D[Repository Interface]
    end
    subgraph Data
        D --> E[Repository Impl]
        E --> F[DataSource]
    end
```

## Estructura de Archivos

```
lib/
├── features/
│   └── [feature_name]/
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       ├── data/
│       │   ├── models/
│       │   ├── datasources/
│       │   └── repositories/
│       └── presentation/
│           ├── bloc/
│           ├── pages/
│           └── widgets/
```

## Tareas de Implementacion

### Fase 1: Domain Layer

#### T-01: Crear Entities
- **Archivo:** `domain/entities/[entity].dart`
- **Complejidad:** S
- **Dependencias:** Ninguna

```dart
// Ejemplo de estructura
class EntityName extends Equatable {
  const EntityName({required this.id});
  final String id;

  @override
  List<Object?> get props => [id];
}
```

#### T-02: Definir Repository Interface
- **Archivo:** `domain/repositories/[repo]_repository.dart`
- **Complejidad:** S
- **Dependencias:** T-01

#### T-03: Crear UseCases
- **Archivo:** `domain/usecases/[action]_usecase.dart`
- **Complejidad:** M
- **Dependencias:** T-02

### Fase 2: Data Layer

#### T-04: Crear Models
- **Archivo:** `data/models/[model]_model.dart`
- **Complejidad:** S
- **Dependencias:** T-01

#### T-05: Implementar DataSource
- **Archivo:** `data/datasources/[source]_datasource.dart`
- **Complejidad:** M
- **Dependencias:** T-04

#### T-06: Implementar Repository
- **Archivo:** `data/repositories/[repo]_repository_impl.dart`
- **Complejidad:** M
- **Dependencias:** T-02, T-05

### Fase 3: Presentation Layer

#### T-07: Crear Bloc/Cubit
- **Archivo:** `presentation/bloc/[feature]_bloc.dart`
- **Complejidad:** M
- **Dependencias:** T-03

#### T-08: Crear Widgets
- **Archivo:** `presentation/widgets/[widget].dart`
- **Complejidad:** M
- **Dependencias:** Ninguna

#### T-09: Crear Pages
- **Archivo:** `presentation/pages/[page]_page.dart`
- **Complejidad:** L
- **Dependencias:** T-07, T-08

### Fase 4: Integracion

#### T-10: Configurar DI
- **Archivo:** `injection.dart`
- **Complejidad:** S
- **Dependencias:** T-06, T-07

#### T-11: Agregar Rutas
- **Archivo:** `router.dart`
- **Complejidad:** S
- **Dependencias:** T-09

## Orden de Ejecucion TDD

```
1. Test Entity -> Impl Entity
2. Test Repository Interface (mock)
3. Test UseCase -> Impl UseCase
4. Test Model -> Impl Model
5. Test DataSource -> Impl DataSource
6. Test Repository -> Impl Repository
7. Test Bloc -> Impl Bloc
8. Widget Test -> Impl Widget
9. Integration Test
```

## Checkpoints de Verificacion

- [ ] **CP-01:** Domain layer completo y testeado
- [ ] **CP-02:** Data layer completo y testeado
- [ ] **CP-03:** Presentation layer completo
- [ ] **CP-04:** Integracion funcional
- [ ] **CP-05:** Tests de integracion pasando

## Riesgos

| Riesgo | Mitigacion |
|--------|------------|
| [Riesgo 1] | [Estrategia] |

---
*Generado con DFSpec - Spec-Driven Development para Flutter/Dart*
''';
}
