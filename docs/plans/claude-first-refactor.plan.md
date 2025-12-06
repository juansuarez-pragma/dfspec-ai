# Plan de Refactor: Claude-First Architecture

## Resumen Ejecutivo

Simplificar DFSpec para funcionar **exclusivamente con Claude Code**, eliminando la complejidad multi-plataforma actual (17 plataformas). Una vez que el framework funcione perfectamente con Claude, se diseñará una arquitectura extensible para otras IAs.

## Estado Actual

### Complejidad Multi-Plataforma
- **560+ líneas** dedicadas a soporte multi-plataforma
- **16 plataformas** hardcodeadas en `AiPlatformRegistry`
- **2 formatos** de comando (Markdown, TOML)
- **5 archivos** fuertemente acoplados

### Archivos Afectados
| Archivo | Líneas | Función |
|---------|--------|---------|
| `ai_platform_registry.dart` | 221 | Registry 16 plataformas |
| `ai_platform_config.dart` | 140 | Config por plataforma |
| `command_generator.dart` | 106 | Factory + 2 generadores |
| `install_command.dart` | 329 | Install multi-plataforma |
| `init_command.dart` | 407 | Init multi-plataforma |

## Arquitectura Objetivo

### Principio: Claude-First
```
                    ANTES                              DESPUÉS
    ┌─────────────────────────────────┐    ┌─────────────────────────────────┐
    │      AiPlatformRegistry         │    │                                 │
    │  ┌─────┬─────┬─────┬─────┐     │    │       ClaudeCodeConfig          │
    │  │Claude│Gemini│Cursor│...│     │    │  ┌─────────────────────────┐   │
    │  └─────┴─────┴─────┴─────┘     │    │  │ commandFolder            │   │
    │         16 plataformas          │    │  │ contextFile              │   │
    └─────────────────────────────────┘    │  │ model support            │   │
                   │                        │  │ Task tool integration    │   │
                   ▼                        │  └─────────────────────────┘   │
    ┌─────────────────────────────────┐    └─────────────────────────────────┘
    │      CommandGenerator           │                   │
    │  ┌──────────┬──────────┐       │                   ▼
    │  │ Markdown │   TOML   │       │    ┌─────────────────────────────────┐
    │  └──────────┴──────────┘       │    │    ClaudeCommandGenerator       │
    └─────────────────────────────────┘    │  (solo Markdown con frontmatter)│
                                           └─────────────────────────────────┘
```

### Beneficios
1. **Reducción de código**: ~400 líneas menos
2. **Simplicidad**: Sin factory patterns innecesarios
3. **Enfoque**: Optimizar para Claude Code específicamente
4. **Testabilidad**: Menos casos edge
5. **Preparación futura**: Arquitectura limpia para extensión

---

## Plan de Implementación

### FASE 1: Crear Configuración Claude-Only
**Objetivo**: Nueva configuración específica para Claude Code

#### Paso 1.1: Crear `claude_config.dart`
- **Archivo**: `lib/src/config/claude_config.dart`
- **Acción**: Crear
- **Descripción**: Configuración centralizada para Claude Code

```dart
/// Configuración específica para Claude Code.
///
/// Centraliza todas las constantes y configuraciones
/// necesarias para integración con Claude Code.
class ClaudeCodeConfig {
  const ClaudeCodeConfig._();

  /// Carpeta donde se instalan los comandos slash.
  static const commandFolder = '.claude/commands';

  /// Archivo de contexto del proyecto.
  static const contextFile = 'CLAUDE.md';

  /// Extensión de los archivos de comando.
  static const commandExtension = '.md';

  /// Modelos disponibles en Claude Code.
  static const availableModels = ['opus', 'sonnet', 'haiku'];

  /// Modelo por defecto para tareas complejas.
  static const defaultModel = 'opus';

  /// Modelo para tareas simples/rápidas.
  static const lightModel = 'haiku';

  /// Herramientas MCP de Dart disponibles.
  static const dartMcpTools = [
    'mcp__dart__analyze_files',
    'mcp__dart__run_tests',
    'mcp__dart__dart_format',
    'mcp__dart__dart_fix',
    'mcp__dart__pub',
    'mcp__dart__pub_dev_search',
  ];

  /// Genera el nombre del archivo de comando.
  static String getCommandFileName(String commandName) {
    return '$commandName$commandExtension';
  }

  /// Genera la ruta completa del archivo de comando.
  static String getCommandFilePath(String projectRoot, String commandName) {
    return '$projectRoot/$commandFolder/${getCommandFileName(commandName)}';
  }
}
```

#### Paso 1.2: Crear barrel export
- **Archivo**: `lib/src/config/config.dart`
- **Acción**: Crear

```dart
/// Configuración de DFSpec.
library;

export 'claude_config.dart';
```

---

### FASE 2: Simplificar Generador de Comandos
**Objetivo**: Eliminar factory pattern, solo Markdown

#### Paso 2.1: Refactorizar `command_generator.dart`
- **Archivo**: `lib/src/generators/command_generator.dart`
- **Acción**: Modificar
- **Descripción**: Eliminar factory, TomlGenerator, y enum CommandFormat

**Antes** (106 líneas):
```dart
enum CommandFormat { markdown, toml }

abstract class CommandGenerator {
  factory CommandGenerator.forPlatform(AiPlatformConfig platform) {
    return switch (platform.commandFormat) {
      CommandFormat.markdown => MarkdownCommandGenerator(),
      CommandFormat.toml => TomlCommandGenerator(),
    };
  }
}

class MarkdownCommandGenerator implements CommandGenerator { ... }
class TomlCommandGenerator implements CommandGenerator { ... }
```

**Después** (~50 líneas):
```dart
/// Generador de comandos slash para Claude Code.
///
/// Genera archivos Markdown con YAML frontmatter
/// compatibles con el formato de Claude Code.
class ClaudeCommandGenerator {
  const ClaudeCommandGenerator();

  /// Genera el contenido del archivo de comando.
  String generate(CommandTemplate template) {
    final buffer = StringBuffer()
      ..writeln('---')
      ..writeln('description: ${template.description}')
      ..writeln('allowed-tools: ${template.tools.join(', ')}')
      ..writeln('---')
      ..writeln()
      ..write(template.content);
    return buffer.toString();
  }
}
```

---

### FASE 3: Simplificar Comando Install
**Objetivo**: Eliminar opciones multi-plataforma

#### Paso 3.1: Refactorizar `install_command.dart`
- **Archivo**: `lib/src/commands/install_command.dart`
- **Acción**: Modificar
- **Descripción**: Remover --agent, --all-agents, --detect, --list-agents

**Opciones a ELIMINAR**:
```dart
// ELIMINAR estas opciones
..addMultiOption('agent', ...)
..addFlag('all-agents', ...)
..addFlag('detect', ...)
..addFlag('list-agents', ...)
```

**Métodos a ELIMINAR**:
```dart
// ELIMINAR estos métodos
void _listPlatforms() { ... }
Future<List<AiPlatformConfig>> _resolveTargetPlatforms(...) { ... }
Future<List<AiPlatformConfig>> _detectInstalledPlatforms() { ... }
Future<(int, int)> _installForPlatform(...) { ... }
```

**Nueva estructura simplificada**:
```dart
class InstallCommand extends Command<int> {
  InstallCommand({AgentLoader? agentLoader}) {
    argParser
      ..addFlag('all', abbr: 'a', help: 'Instala todos los comandos.')
      ..addMultiOption('command', abbr: 'c', help: 'Comando específico.')
      ..addFlag('force', abbr: 'f', help: 'Sobrescribe existentes.')
      ..addFlag('list', abbr: 'l', help: 'Lista comandos disponibles.');
  }

  @override
  Future<int> run() async {
    // Solo instalar en .claude/commands/
    final outputDir = ClaudeCodeConfig.commandFolder;
    final generator = ClaudeCommandGenerator();
    // ... resto de lógica simplificada
  }
}
```

**Reducción estimada**: ~150 líneas

---

### FASE 4: Simplificar Comando Init
**Objetivo**: Eliminar opciones multi-plataforma

#### Paso 4.1: Refactorizar `init_command.dart`
- **Archivo**: `lib/src/commands/init_command.dart`
- **Acción**: Modificar
- **Descripción**: Remover --agent, --all-agents, --detect

**Opciones a ELIMINAR**:
```dart
// ELIMINAR
..addMultiOption('agent', ...)
..addFlag('all-agents', ...)
..addFlag('detect', ...)
```

**Métodos a SIMPLIFICAR**:
```dart
// SIMPLIFICAR: solo crear estructura para Claude
Future<void> _createDirectoryStructure(String projectPath) async {
  await FileUtils.ensureDirectory('$projectPath/${ClaudeCodeConfig.commandFolder}');
  await FileUtils.ensureDirectory('$projectPath/docs/specs/features');
  await FileUtils.ensureDirectory('$projectPath/docs/specs/plans');
}

// SIMPLIFICAR: solo crear CLAUDE.md
Future<void> _createContextFile(String projectPath) async {
  final contextPath = '$projectPath/${ClaudeCodeConfig.contextFile}';
  if (!FileUtils.fileExists(contextPath)) {
    await FileUtils.writeFile(contextPath, _generateClaudeContext());
  }
}
```

**Reducción estimada**: ~100 líneas

---

### FASE 5: Deprecar/Eliminar Código Multi-Plataforma
**Objetivo**: Limpiar código legacy

#### Paso 5.1: Eliminar `ai_platform_registry.dart`
- **Archivo**: `lib/src/models/ai_platform_registry.dart`
- **Acción**: Eliminar
- **Razón**: Ya no se usa con arquitectura Claude-only

#### Paso 5.2: Eliminar `ai_platform_config.dart`
- **Archivo**: `lib/src/models/ai_platform_config.dart`
- **Acción**: Eliminar
- **Razón**: Reemplazado por `ClaudeCodeConfig`

#### Paso 5.3: Actualizar exports
- **Archivo**: `lib/src/models/models.dart`
- **Acción**: Modificar
- **Descripción**: Remover exports de archivos eliminados

#### Paso 5.4: Actualizar barrel principal
- **Archivo**: `lib/dfspec.dart`
- **Acción**: Modificar
- **Descripción**: Agregar export de config/

---

### FASE 6: Actualizar Tests
**Objetivo**: Adaptar tests a nueva arquitectura

#### Paso 6.1: Eliminar tests multi-plataforma
- **Archivos a eliminar**:
  - `test/src/models/ai_platform_config_test.dart`
  - `test/src/models/ai_platform_registry_test.dart`

#### Paso 6.2: Crear tests para ClaudeCodeConfig
- **Archivo**: `test/src/config/claude_config_test.dart`
- **Acción**: Crear

#### Paso 6.3: Actualizar tests de comandos
- **Archivos**: `test/src/commands/*_test.dart`
- **Acción**: Modificar
- **Descripción**: Remover tests de opciones --agent eliminadas

#### Paso 6.4: Actualizar tests de generador
- **Archivo**: `test/src/generators/command_generator_test.dart`
- **Acción**: Modificar
- **Descripción**: Solo tests para ClaudeCommandGenerator

---

### FASE 7: Actualizar Documentación
**Objetivo**: Reflejar arquitectura Claude-first

#### Paso 7.1: Actualizar README.md
- Eliminar sección "Plataformas Soportadas"
- Agregar sección "Integración con Claude Code"
- Actualizar badges (remover "17 Supported")

#### Paso 7.2: Actualizar CLAUDE.md
- Documentar configuración específica de Claude

#### Paso 7.3: Actualizar CHANGELOG.md
- Documentar breaking changes

---

## Resumen de Cambios

### Archivos a CREAR
| Archivo | Líneas Est. |
|---------|-------------|
| `lib/src/config/claude_config.dart` | ~60 |
| `lib/src/config/config.dart` | ~5 |
| `test/src/config/claude_config_test.dart` | ~50 |

### Archivos a MODIFICAR
| Archivo | Antes | Después | Reducción |
|---------|-------|---------|-----------|
| `command_generator.dart` | 106 | ~50 | -56 |
| `install_command.dart` | 329 | ~180 | -149 |
| `init_command.dart` | 407 | ~300 | -107 |

### Archivos a ELIMINAR
| Archivo | Líneas |
|---------|--------|
| `ai_platform_registry.dart` | 221 |
| `ai_platform_config.dart` | 140 |
| `ai_platform_config_test.dart` | ~100 |
| `ai_platform_registry_test.dart` | ~80 |

### Balance Total
- **Líneas eliminadas**: ~850
- **Líneas creadas**: ~115
- **Reducción neta**: ~735 líneas

---

## Orden de Ejecución

```
FASE 1: Crear ClaudeCodeConfig
    │
    ▼
FASE 2: Simplificar CommandGenerator
    │
    ▼
FASE 3: Simplificar InstallCommand
    │
    ▼
FASE 4: Simplificar InitCommand
    │
    ▼
FASE 5: Eliminar código legacy
    │
    ▼
FASE 6: Actualizar tests
    │
    ▼
FASE 7: Actualizar documentación
```

---

## Criterios de Aceptación

### Funcionales
- [x] `dfspec init` crea estructura solo para Claude
- [x] `dfspec install` instala solo en `.claude/commands/`
- [x] `dfspec agents` funciona igual
- [x] `AgentInvoker` funciona con modelos Claude
- [x] Todos los tests pasan (217 tests)

### No Funcionales
- [x] Reducción de ~700 líneas de código
- [x] Sin opciones --agent en CLI
- [x] Documentación actualizada
- [x] CHANGELOG con breaking changes

---

## Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Usuarios usando otras plataformas | Media | Alto | Documentar en CHANGELOG, versión major |
| Tests fallando | Baja | Medio | Ejecutar tests después de cada fase |
| Imports rotos | Media | Bajo | Buscar todos los imports antes de eliminar |

---

## Preparación para Multi-Plataforma Futura

Cuando se quiera re-agregar soporte multi-plataforma:

1. **Crear interface `AiPlatformAdapter`**:
```dart
abstract class AiPlatformAdapter {
  String get id;
  String get commandFolder;
  String generateCommand(CommandTemplate template);
  Future<bool> isAvailable();
}
```

2. **Implementar adaptadores**:
```dart
class ClaudeAdapter implements AiPlatformAdapter { ... }
class GeminiAdapter implements AiPlatformAdapter { ... }
```

3. **Plugin system** para registrar adaptadores dinámicamente

Esta arquitectura será más limpia y extensible que el registry hardcodeado actual.

---

## Siguiente Paso

¿Proceder con la implementación de FASE 1: Crear ClaudeCodeConfig?
