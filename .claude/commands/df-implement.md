---
description: Implementa codigo siguiendo TDD estricto
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion, mcp__dart__create_project, mcp__dart__pub, mcp__dart__run_tests, mcp__dart__analyze_files, mcp__dart__dart_format, mcp__dart__add_roots
---

# Comando: df-implement

Eres un agente de implementacion para Flutter/Dart con TDD estricto.

## Tarea
Implementa: $ARGUMENTS

## Proceso Obligatorio

### FASE 0: Verificacion de Prerequisitos

**IMPORTANTE:** Todos los archivos (dfspec.yaml, specs, plans) estan en el PROYECTO DESTINO, no en dfspec.

1. **Leer dfspec.yaml DEL PROYECTO DESTINO** (`[project.path]/dfspec.yaml`) para obtener:
   - `project.type`
   - `project.platforms`
   - `project.state_management`
   - `project.path`
   - `project.configured`
   - `project.name`

2. **Verificar que exista especificacion y plan EN EL PROYECTO DESTINO:**
   - Debe existir `[project.path]/docs/specs/features/[nombre].spec.md`
   - Debe existir `[project.path]/docs/specs/plans/[nombre].plan.md`
   - Si no existen → Indicar que ejecute `/df-spec` y `/df-plan` primero

### FASE 1: Creacion de Proyecto (Si no existe)

**Verificar si el proyecto existe:**
- Comprobar si existe `pubspec.yaml` en `project.path`

**Si NO existe el proyecto:**

1. **Usar MCP tool para crear proyecto:**

   Para `flutter_app`:
   ```
   mcp__dart__create_project:
     projectType: flutter
     directory: [project.name]
     root: [project.path padre]
     platform: [project.platforms]
     template: app
   ```

   Para `dart_package`:
   ```
   mcp__dart__create_project:
     projectType: dart
     directory: [project.name]
     root: [project.path padre]
     template: package
   ```

   Para `dart_cli`:
   ```
   mcp__dart__create_project:
     projectType: dart
     directory: [project.name]
     root: [project.path padre]
     template: console
   ```

2. **Registrar root en MCP:**
   ```
   mcp__dart__add_roots:
     roots: [{ uri: "file://[project.path]", name: "[project.name]" }]
   ```

3. **Crear estructura de directorios Clean Architecture:**
   ```bash
   mkdir -p lib/src/core/error
   mkdir -p lib/src/core/constants
   mkdir -p lib/src/core/network
   mkdir -p lib/src/domain/entities
   mkdir -p lib/src/domain/repositories
   mkdir -p lib/src/domain/usecases
   mkdir -p lib/src/data/models
   mkdir -p lib/src/data/datasources
   mkdir -p lib/src/data/repositories
   mkdir -p test/unit/core
   mkdir -p test/unit/domain
   mkdir -p test/unit/data
   mkdir -p test/fixtures
   ```

   Si es `flutter_app`, agregar:
   ```bash
   mkdir -p lib/src/presentation/pages
   mkdir -p lib/src/presentation/widgets
   mkdir -p lib/src/presentation/[state_management]  # bloc, providers, etc
   mkdir -p test/widget
   ```

### FASE 2: Instalacion de Dependencias

1. **Leer dependencias del plan** en `[project.path]/docs/specs/plans/[nombre].plan.md`

2. **Instalar dependencias usando MCP:**
   ```
   mcp__dart__pub:
     command: add
     packageNames: [lista de dependencias]
     roots: [{ root: "file://[project.path]" }]
   ```

3. **Instalar dev_dependencies:**
   ```
   mcp__dart__pub:
     command: add
     packageNames: ["dev:mocktail", "dev:test", ...]
     roots: [{ root: "file://[project.path]" }]
   ```

### FASE 3: Implementacion TDD

**Leer el plan** para obtener orden de implementacion.

**Para cada archivo en el plan, seguir ciclo TDD:**

#### 3.1 RED - Escribir test que falla

1. Leer criterios de completitud del plan para el archivo
2. Crear archivo de test en `test/unit/[capa]/[nombre]_test.dart`
3. Escribir tests que definen el comportamiento esperado
4. Ejecutar test para verificar que falla:
   ```
   mcp__dart__run_tests:
     roots: [{ root: "file://[project.path]", paths: ["test/unit/..."] }]
   ```

#### 3.2 GREEN - Implementar minimo codigo

1. Crear archivo de implementacion en `lib/src/[capa]/[nombre].dart`
2. Escribir el codigo minimo para pasar el test
3. Ejecutar test para verificar que pasa:
   ```
   mcp__dart__run_tests:
     roots: [{ root: "file://[project.path]", paths: ["test/unit/..."] }]
   ```

#### 3.3 REFACTOR - Mejorar codigo

1. Aplicar principios SOLID
2. Mejorar nombres y estructura
3. Verificar que tests siguen pasando
4. Ejecutar analisis estatico:
   ```
   mcp__dart__analyze_files:
     roots: [{ root: "file://[project.path]" }]
   ```

### FASE 4: Checkpoints de Verificacion

**Despues de cada capa (core, domain, data, presentation):**

1. Ejecutar todos los tests de la capa:
   ```
   mcp__dart__run_tests:
     roots: [{ root: "file://[project.path]", paths: ["test/unit/[capa]/"] }]
   ```

2. Ejecutar analisis estatico:
   ```
   mcp__dart__analyze_files:
     roots: [{ root: "file://[project.path]", paths: ["lib/src/[capa]/"] }]
   ```

3. Formatear codigo:
   ```
   mcp__dart__dart_format:
     roots: [{ root: "file://[project.path]" }]
   ```

4. Verificar criterios del plan antes de continuar

### FASE 5: Verificacion Final

1. **Ejecutar todos los tests:**
   ```
   mcp__dart__run_tests:
     roots: [{ root: "file://[project.path]" }]
   ```

2. **Ejecutar analisis completo:**
   ```
   mcp__dart__analyze_files:
     roots: [{ root: "file://[project.path]" }]
   ```

3. **Verificar contra criterios de aceptacion:**
   - Leer CA de la especificacion
   - Mapear cada CA a tests existentes
   - Confirmar que todos pasan

4. **Actualizar dfspec.yaml DEL PROYECTO DESTINO** (`[project.path]/dfspec.yaml`):
   - Cambiar status de la feature a `implemented`

## Principios de Implementacion

- **Clean Architecture**: Separacion estricta de capas
  - Domain no depende de Data ni Presentation
  - Data implementa interfaces de Domain
  - Presentation usa UseCases de Domain

- **SOLID**:
  - Single Responsibility: Cada clase una responsabilidad
  - Open/Closed: Abierto a extension, cerrado a modificacion
  - Liskov Substitution: Subtipos sustituibles
  - Interface Segregation: Interfaces especificas
  - Dependency Inversion: Depender de abstracciones

- **DRY**: Sin duplicacion de logica

- **Null Safety**: Uso correcto de tipos nullable

## Output

1. Proyecto creado (si no existia)
2. Dependencias instaladas
3. Codigo implementado siguiendo TDD
4. Todos los tests pasando
5. Cero errores de analisis estatico
6. `dfspec.yaml` actualizado con status `implemented`

## Siguiente Paso

Indicar al usuario:
```
Implementacion completada.

Tests: [X] pasando
Analisis: [0] errores

Para verificar contra la especificacion:
/df-verify [nombre-feature]

Para ejecutar la aplicacion:
[comando segun tipo de proyecto]
```
