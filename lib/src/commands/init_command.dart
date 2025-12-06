import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dfspec/src/config/claude_config.dart';
import 'package:dfspec/src/models/models.dart';
import 'package:dfspec/src/utils/utils.dart';

/// Comando para inicializar un proyecto con estructura DFSpec.
///
/// Crea la estructura de directorios y archivos necesarios
/// para trabajar con Spec-Driven Development usando Claude Code.
///
/// Uso:
/// ```bash
/// dfspec init [nombre_proyecto]
/// dfspec init --force          # Sobrescribe existente
/// dfspec init --minimal        # Solo estructura minima
/// ```
class InitCommand extends Command<int> {
  /// Crea una nueva instancia del comando init.
  InitCommand() {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Sobrescribe archivos existentes.',
        negatable: false,
      )
      ..addFlag(
        'minimal',
        abbr: 'm',
        help: 'Crea solo la estructura minima.',
        negatable: false,
      )
      ..addFlag(
        'with-context',
        help: 'Genera archivo CLAUDE.md con instrucciones.',
        defaultsTo: true,
      );
  }

  @override
  String get name => 'init';

  @override
  String get description =>
      'Inicializa un proyecto con estructura DFSpec para Claude Code.';

  @override
  String get invocation => 'dfspec init [nombre_proyecto]';

  final Logger _logger = const Logger();

  @override
  Future<int> run() async {
    final force = argResults!['force'] as bool;
    final minimal = argResults!['minimal'] as bool;
    final withContext = argResults!['with-context'] as bool;

    // Obtener nombre del proyecto
    final projectName = argResults!.rest.isNotEmpty
        ? argResults!.rest.first
        : FileUtils.getCurrentDirectoryName();

    _logger.title('Inicializando proyecto DFSpec: $projectName');

    try {
      // Verificar si ya existe configuracion
      final existingConfig = await DfspecConfig.load(Directory.current.path);
      if (existingConfig != null && !force) {
        _logger.warning(
          'El proyecto ya esta inicializado. '
          'Usa --force para reinicializar.',
        );
        return 1;
      }

      // Crear estructura de directorios
      await _createDirectoryStructure(minimal: minimal);

      // Crear archivo de configuracion
      await _createConfigFile(projectName);

      // Crear archivos base
      await _createBaseFiles(minimal: minimal);

      // Crear archivo CLAUDE.md
      if (withContext) {
        await _createClaudeContext();
      }

      _logger
        ..blank()
        ..success('Proyecto inicializado correctamente!')
        ..blank()
        ..info('Configurado para Claude Code:')
        ..item('Comandos: ${ClaudeCodeConfig.commandFolder}')
        ..item('Contexto: ${ClaudeCodeConfig.contextFile}')
        ..blank()
        ..info('Proximos pasos:')
        ..item('Ejecuta: dfspec install')
        ..item('Crea tu primera especificacion en specs/')
        ..item('Usa /df-spec en Claude Code para comenzar');

      return 0;
    } catch (e) {
      _logger.error('Error al inicializar: $e');
      return 1;
    }
  }

  Future<void> _createDirectoryStructure({required bool minimal}) async {
    _logger.info('Creando estructura de directorios...');

    final directories = [
      'specs',
      'specs/features',
      ClaudeCodeConfig.commandFolder,
    ];

    if (!minimal) {
      directories.addAll([
        'specs/architecture',
        'specs/security',
        'specs/performance',
        'docs/decisions',
      ]);
    }

    for (final dir in directories) {
      final created = await FileUtils.ensureDirectory(
        FileUtils.resolvePath(dir),
      );
      if (created) {
        _logger.item(dir, prefix: '  +');
      }
    }
  }

  Future<void> _createConfigFile(String projectName) async {
    _logger.info('Creando archivo de configuracion...');

    final configPath = FileUtils.resolvePath('dfspec.yaml');
    final configContent = _generateConfig(projectName);
    await FileUtils.writeFile(configPath, configContent, overwrite: true);
    _logger.item('dfspec.yaml', prefix: '  +');
  }

  String _generateConfig(String projectName) {
    return '''
# DFSpec Configuration
# Generado automaticamente

project:
  name: $projectName
  configured: true

# Configuracion de Claude Code
claude:
  commandFolder: ${ClaudeCodeConfig.commandFolder}
  contextFile: ${ClaudeCodeConfig.contextFile}
  defaultModel: ${ClaudeCodeConfig.defaultModel}

# Features del proyecto
features: {}

# Umbrales de calidad
quality:
  testCoverage: 85
  cyclomaticComplexity: 10
  cognitiveComplexity: 8
  maxLinesPerFile: 400
''';
  }

  Future<void> _createBaseFiles({required bool minimal}) async {
    _logger.info('Creando archivos base...');

    // README para specs
    await FileUtils.writeFile(
      FileUtils.resolvePath('specs/README.md'),
      _specsReadme,
    );
    _logger.item('specs/README.md', prefix: '  +');

    // Template de especificacion
    await FileUtils.writeFile(
      FileUtils.resolvePath('specs/features/.gitkeep'),
      '',
    );

    if (!minimal) {
      // Plantilla de especificacion de ejemplo
      await FileUtils.writeFile(
        FileUtils.resolvePath('specs/features/ejemplo.spec.md'),
        _exampleSpec,
      );
      _logger.item('specs/features/ejemplo.spec.md', prefix: '  +');
    }
  }

  Future<void> _createClaudeContext() async {
    _logger.info('Creando archivo de contexto CLAUDE.md...');

    final contextPath = FileUtils.resolvePath(ClaudeCodeConfig.contextFile);
    await FileUtils.writeFile(contextPath, _claudeContext);
    _logger.item(ClaudeCodeConfig.contextFile, prefix: '  +');
  }

  static const String _claudeContext = '''
# CLAUDE.md

Este archivo proporciona instrucciones a Claude Code cuando trabaja con DFSpec.

## Descripcion

DFSpec es un toolkit de Spec-Driven Development (SDD) especializado en Dart/Flutter.
Transforma especificaciones en implementaciones de alta calidad siguiendo TDD estricto
y Clean Architecture.

## Comandos Disponibles

### Flujo Principal

| Comando | Uso | Descripcion |
|---------|-----|-------------|
| `/df-spec <feature>` | Crear spec | Define QUE construir |
| `/df-plan <feature>` | Crear plan | Define COMO construir |
| `/df-implement <feature>` | Implementar | TDD: Red -> Green -> Refactor |
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
specs/
├── features/
│   └── <feature>.spec.md    # Requisitos y CA
└── architecture/
    └── <decision>.md        # ADRs
```
''';

  static const String _specsReadme = '''
# Especificaciones del Proyecto

Este directorio contiene las especificaciones del proyecto siguiendo
la metodologia Spec-Driven Development (SDD).

## Estructura

```
specs/
├── features/        # Especificaciones de funcionalidades
├── architecture/    # Decisiones arquitectonicas
├── security/        # Requisitos de seguridad
└── performance/     # Requisitos de rendimiento
```

## Como crear una especificacion

1. Crea un archivo `.spec.md` en el directorio apropiado
2. Usa el template proporcionado o ejecuta `/df-spec` en Claude Code
3. Define claramente los requisitos y criterios de aceptacion

## Convenciones

- Usa nombres descriptivos: `autenticacion-oauth.spec.md`
- Incluye siempre criterios de aceptacion medibles
- Referencia las dependencias entre especificaciones
''';

  static const String _exampleSpec = '''
# Especificacion: Ejemplo de Feature

## Resumen
Breve descripcion de la funcionalidad.

## Contexto
Por que es necesaria esta funcionalidad y como encaja en el sistema.

## Requisitos Funcionales

### RF-01: Nombre del Requisito
- Descripcion detallada
- Comportamiento esperado

## Requisitos No Funcionales

### RNF-01: Rendimiento
- Tiempo de respuesta < 100ms

### RNF-02: Seguridad
- Validacion de inputs
- Sanitizacion de datos

## Criterios de Aceptacion

- [ ] Criterio 1: Descripcion
- [ ] Criterio 2: Descripcion
- [ ] Criterio 3: Descripcion

## Dependencias
- Ninguna

## Notas Tecnicas
Consideraciones de implementacion.
''';
}
