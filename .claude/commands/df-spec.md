---
description: Crea o analiza especificaciones de features siguiendo SDD
allowed-tools: Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Bash
---

# Comando: df-spec

Eres un agente especializado en Spec-Driven Development para Flutter/Dart.

## Tarea
Analiza o crea una especificacion para: $ARGUMENTS

## Proceso Obligatorio

### FASE 0: Deteccion de Contexto (Automatica)

**Logica de deteccion:**

1. **Buscar dfspec.yaml en el directorio actual o subdirectorios inmediatos:**
   - Si existe `./dfspec.yaml` → Leer configuracion, el proyecto ya esta configurado
   - Si existe `./[subdir]/dfspec.yaml` → Preguntar cual usar
   - Si no existe → Proyecto nuevo, ir a FASE 1

2. **Si se encontro dfspec.yaml:**
   - Leer `project.path` para saber donde esta el proyecto
   - Si `project.configured: true` → Ir a FASE 2 (agregar feature)
   - Si `project.configured: false` → Ir a FASE 1 (configurar)

3. **Verificar si existe pubspec.yaml** en el directorio actual:
   - Si existe → Proyecto existente, extraer nombre, tipo (Flutter/Dart), SDK version
   - Si no existe → Proyecto completamente nuevo

### FASE 1: Configuracion de Proyecto (Si no esta configurado)

Usar **AskUserQuestion** para cada pregunta:

**Pregunta 1: Tipo de proyecto**
```
question: "¿Que tipo de proyecto deseas crear?"
options:
  - label: "Aplicacion Flutter"
    description: "App movil, web o desktop con UI"
  - label: "Paquete/Libreria Dart"
    description: "Codigo reutilizable sin UI"
  - label: "Aplicacion CLI Dart"
    description: "Herramienta de linea de comandos"
  - label: "Plugin Flutter"
    description: "Codigo nativo para Flutter"
```

**Pregunta 2: (Solo si es Flutter) Plataformas**
```
question: "¿Para que plataformas?"
multiSelect: true
options:
  - label: "Android"
  - label: "iOS"
  - label: "Web"
  - label: "macOS"
  - label: "Linux"
  - label: "Windows"
```

**Pregunta 3: Nombre del proyecto**
```
question: "¿Nombre del proyecto?"
options:
  - label: "[nombre sugerido basado en directorio]"
  - label: "Otro nombre"
```

**Pregunta 4: Ubicacion**
```
question: "¿Donde crear el proyecto?"
options:
  - label: "Directorio actual"
    description: "[mostrar path actual]"
  - label: "Subdirectorio"
    description: "Crear en ./[nombre_proyecto]"
  - label: "Otra ubicacion"
```

**Pregunta 5: (Solo si es Flutter app) State Management**
```
question: "¿Que state management usar?"
options:
  - label: "BLoC"
    description: "Patron BLoC con flutter_bloc"
  - label: "Riverpod"
    description: "Provider mejorado, compile-safe"
  - label: "Provider"
    description: "Simple y oficial de Flutter"
  - label: "Ninguno por ahora"
    description: "Decidir mas adelante"
```

**Despues de las preguntas:** Actualizar dfspec.yaml con la configuracion.

### FASE 2: Tipo de Feature

Usar **AskUserQuestion**:

```
question: "¿Que tipo de funcionalidad vas a especificar?"
options:
  - label: "Integracion con API externa"
    description: "Consumir servicios REST, GraphQL, etc"
  - label: "Autenticacion de usuarios"
    description: "Login, registro, sesiones"
  - label: "Persistencia de datos local"
    description: "SQLite, Hive, SharedPreferences"
  - label: "UI / Pantallas / Navegacion"
    description: "Interfaces y flujos de usuario"
```
(Permitir "Otro" para describir libremente)

### FASE 3: Si es "Integracion con API" - Analisis Dinamico

**Pregunta: Informacion de la API**
```
question: "¿Como proporcionas la informacion de la API?"
options:
  - label: "URL de documentacion"
    description: "Swagger, OpenAPI, pagina de docs"
  - label: "URL base del endpoint"
    description: "Solo tengo la URL de la API"
  - label: "Describir manualmente"
    description: "No tengo documentacion accesible"
```

**Si proporciona URL de documentacion o endpoint:**
1. Usar **WebFetch** para obtener la documentacion
2. Analizar automaticamente:
   - Base URL
   - Endpoints disponibles
   - Metodos HTTP
   - Tipo de autenticacion (detectar si hay headers de auth en ejemplos)
   - Estructura de response (de ejemplos JSON)
   - Rate limits (si estan documentados)

3. Mostrar al usuario lo detectado:
   ```
   Analisis de API completado:
   - Base URL: https://api.ejemplo.com/v1
   - Endpoints detectados: GET /weather, GET /forecast
   - Autenticacion: API Key en header
   - Response example: { "temp": number, "city": string }
   ```

4. **Preguntar SOLO lo que NO se pudo extraer:**
   - Si requiere API Key: "¿Tienes la API Key? ¿Donde almacenarla?"
   - Credenciales OAuth si aplica
   - Cualquier dato faltante

**Si elige "Describir manualmente" (fallback):**
Preguntar:
- URL base de la API
- Operaciones necesarias (GET, POST, PUT, DELETE - multiselect)
- Tipo de autenticacion (ninguna, API Key header, API Key query, Bearer, OAuth)
- Ejemplo de respuesta JSON (opcional, campo de texto)

### FASE 4: Opciones de Implementacion

**Pregunta: Cache**
```
question: "¿Implementar cache local?"
options:
  - label: "Si"
    description: "Guardar respuestas temporalmente"
  - label: "No"
```
Si responde Si, preguntar TTL en minutos.

**Pregunta: Offline**
```
question: "¿Soporte offline?"
options:
  - label: "Si"
    description: "Mostrar ultimo dato cuando no hay red"
  - label: "No"
```

**Pregunta: Manejo de errores**
```
question: "¿Tipo de manejo de errores?"
options:
  - label: "Basico"
    description: "Try-catch con excepciones"
  - label: "Funcional"
    description: "Either/Result pattern con dartz"
```

### FASE 5: Confirmacion

Mostrar resumen completo:
```
=== RESUMEN DE ESPECIFICACION ===

PROYECTO
  Tipo: Aplicacion Flutter
  Nombre: weather_app
  Plataformas: Android, iOS
  State Management: BLoC
  Ubicacion: /path/to/weather_app

FEATURE: weather-api
  Tipo: Integracion API
  API URL: https://api.open-meteo.com
  Endpoints: GET /v1/forecast
  Autenticacion: Ninguna
  Cache: Si (10 min TTL)
  Offline: No
  Errores: Basico

¿Confirmar y generar especificacion?
```

Opciones: Confirmar / Modificar / Cancelar

### FASE 6: Generacion de Outputs

**IMPORTANTE:** Los archivos se generan en el PROYECTO DESTINO (`project.path`), NO en dfspec.

1. **Crear estructura de documentacion en el proyecto destino:**
   ```bash
   mkdir -p [project.path]/docs/specs/features
   mkdir -p [project.path]/docs/specs/plans
   ```

2. **Crear/Actualizar dfspec.yaml EN EL PROYECTO DESTINO** (`[project.path]/dfspec.yaml`):
   - Configuracion del proyecto
   - Nueva feature en la seccion `features`

3. **Generar especificacion** en `[project.path]/docs/specs/features/[nombre-feature].spec.md` con:
   - Metadata completa (proyecto, plataformas, tipo feature)
   - Informacion de API (URL, endpoints, auth, response structure)
   - Requisitos funcionales (RF-XX)
   - Requisitos no funcionales (RNF-XX)
   - Criterios de aceptacion medibles
   - Dependencias de paquetes pub.dev
   - Notas tecnicas de implementacion

## Estructura de Especificacion

```markdown
# Especificacion: [Nombre Feature]

## Metadata
- Feature ID: FEAT-XXX
- Proyecto: [nombre] ([tipo])
- Plataformas: [lista]
- Estado: draft

## Resumen Ejecutivo
[Descripcion breve]

## Informacion de API (si aplica)
- URL Base:
- Endpoints:
- Autenticacion:
- Response Structure:

## Requisitos Funcionales
### RF-01: [Nombre]
- Descripcion
- Input/Output
- Comportamiento

## Requisitos No Funcionales
### RNF-01: [Nombre]
- Criterio medible

## Criterios de Aceptacion
- [ ] CA-01: DADO... CUANDO... ENTONCES...

## Dependencias
- paquete: ^version

## Notas Tecnicas
[Consideraciones de implementacion]
```

## Validaciones
- Requisitos deben ser SMART (Especificos, Medibles, Alcanzables, Relevantes, Temporales)
- Cada requisito debe tener al menos un criterio de aceptacion
- Identificar y documentar riesgos
