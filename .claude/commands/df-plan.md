---
description: Genera plan de implementacion desde especificacion
allowed-tools: Read, Write, Edit, Glob, Grep, Task, AskUserQuestion
---

# Comando: df-plan

Eres un agente de planificacion para proyectos Flutter/Dart.

## Tarea
Genera un plan de implementacion para: $ARGUMENTS

## Proceso Obligatorio

### FASE 1: Lectura de Configuracion

**IMPORTANTE:** Todos los archivos (dfspec.yaml, specs, plans) estan en el PROYECTO DESTINO, no en dfspec.

1. **Leer dfspec.yaml DEL PROYECTO DESTINO** (`[project.path]/dfspec.yaml`) para obtener:
   - `project.type`: Tipo de proyecto (flutter_app, dart_package, dart_cli, flutter_plugin)
   - `project.platforms`: Plataformas objetivo
   - `project.state_management`: State management elegido
   - `project.path`: Ubicacion del proyecto
   - `project.configured`: Si el proyecto ya esta configurado

2. **Verificar que el proyecto este configurado:**
   - Si `project.configured: false` → Indicar al usuario que ejecute `/df-spec` primero
   - Si `project.configured: true` → Continuar

3. **Leer la especificacion** en `[project.path]/docs/specs/features/[nombre].spec.md`:
   - Extraer tipo de feature
   - Extraer requisitos funcionales y no funcionales
   - Extraer criterios de aceptacion
   - Si es API: extraer URL, endpoints, auth, response structure

### FASE 2: Analisis de Arquitectura segun Tipo de Proyecto

**Para flutter_app:**
```
lib/
├── src/
│   ├── core/              # Utilities, constants, errors
│   ├── domain/            # Entities, repositories (interfaces), usecases
│   ├── data/              # Models, datasources, repository implementations
│   └── presentation/      # UI (widgets, pages, [state_management])
└── main.dart
```

**Para dart_package:**
```
lib/
├── src/
│   ├── core/
│   ├── domain/
│   └── data/
└── [package_name].dart    # Public API exports
```

**Para dart_cli:**
```
bin/
└── main.dart              # Entry point
lib/
├── src/
│   ├── commands/          # CLI commands
│   ├── core/
│   └── services/
└── [cli_name].dart
```

### FASE 3: Determinar Dependencias segun Contexto

**Dependencias base por tipo de proyecto:**

| Tipo | Dependencias Base |
|------|-------------------|
| flutter_app | flutter, [state_management_package] |
| dart_package | (ninguna obligatoria) |
| dart_cli | args |
| flutter_plugin | flutter, plugin_platform_interface |

**Dependencias por tipo de feature:**

| Feature | Dependencias |
|---------|--------------|
| API Integration | http o dio, equatable |
| Auth | (depende del provider) |
| Local Storage | hive o sqflite o shared_preferences |
| UI/Navigation | go_router o auto_route (Flutter) |

**Dependencias por state management:**

| State Mgmt | Dependencias |
|------------|--------------|
| bloc | flutter_bloc, equatable |
| riverpod | flutter_riverpod, riverpod_annotation |
| provider | provider |
| none | (ninguna) |

**Dependencias por opcion de implementacion:**

| Opcion | Dependencias |
|--------|--------------|
| Cache con TTL | (en memoria o hive) |
| Error handling funcional | dartz o fpdart |
| Offline support | connectivity_plus, hive |

### FASE 4: Generacion del Plan

Generar archivo en el PROYECTO DESTINO: `[project.path]/docs/specs/plans/[nombre-feature].plan.md` con:

1. **Metadata del Plan**
   - Feature ID
   - Tipo de proyecto
   - Plataformas
   - State management

2. **Diagrama de Arquitectura (Mermaid)**
   - Ajustado segun tipo de proyecto
   - Incluir capa de presentation si es flutter_app
   - Incluir state management si aplica

3. **Lista de Archivos a Crear**
   - Organizados por capa (core, domain, data, presentation)
   - Indicar complejidad (S/M/L)
   - Indicar dependencias entre archivos

4. **Orden de Implementacion TDD**
   - Ordenar por dependencias (core primero, luego domain, data, presentation)
   - Para cada archivo:
     - Test file path
     - Implementation file path
     - Criterios de completitud

5. **Dependencias de Paquetes**
   - Lista completa de dependencias para pubspec.yaml
   - Separar dependencies y dev_dependencies
   - Comando de instalacion

6. **Checkpoints de Verificacion**
   - Despues de cada capa
   - Comandos para verificar (tests, analyze)
   - Criterios de paso

7. **Consideraciones por Plataforma** (si es Flutter)
   - Configuraciones especificas por plataforma
   - Permisos necesarios (Android manifest, iOS Info.plist)

### FASE 5: Verificacion del Plan

Antes de guardar, verificar:
- [ ] Todos los requisitos funcionales tienen archivos asignados
- [ ] Todos los criterios de aceptacion tienen tests mapeados
- [ ] Las dependencias son consistentes con el tipo de proyecto
- [ ] El orden de implementacion respeta dependencias

## Output

1. Generar `[project.path]/docs/specs/plans/[nombre-feature].plan.md`
2. Actualizar `[project.path]/dfspec.yaml`:
   - Cambiar status de la feature a `planned`

## Siguiente Paso

Indicar al usuario:
```
Plan generado en [project.path]/docs/specs/plans/[nombre].plan.md

Para implementar, ejecutar:
/df-implement [nombre-feature]
```
