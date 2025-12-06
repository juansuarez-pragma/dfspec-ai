import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dfspec/src/models/models.dart';
import 'package:dfspec/src/utils/utils.dart';

/// Comando para inicializar un proyecto con estructura DFSpec.
///
/// Crea la estructura de directorios y archivos necesarios
/// para trabajar con Spec-Driven Development en multiples
/// plataformas de IA.
///
/// Uso:
/// ```bash
/// dfspec init [nombre_proyecto]
/// dfspec init --agent claude --agent gemini
/// dfspec init --all-agents
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
      // Opciones multi-agente
      ..addMultiOption(
        'agent',
        help: 'Plataforma(s) de IA a configurar. '
            'Opciones: ${AiPlatformRegistry.allIds.join(", ")}',
        allowed: AiPlatformRegistry.allIds,
      )
      ..addFlag(
        'all-agents',
        help: 'Configura todas las plataformas soportadas.',
        negatable: false,
      )
      ..addFlag(
        'with-context',
        help: 'Genera archivos de contexto (CLAUDE.md, GEMINI.md, etc.).',
        defaultsTo: true,
      );
  }

  @override
  String get name => 'init';

  @override
  String get description =>
      'Inicializa un proyecto con estructura DFSpec para Spec-Driven Development.';

  @override
  String get invocation => 'dfspec init [nombre_proyecto] [--agent=claude]';

  final Logger _logger = const Logger();

  @override
  Future<int> run() async {
    final force = argResults!['force'] as bool;
    final minimal = argResults!['minimal'] as bool;
    final agents = argResults!['agent'] as List<String>;
    final allAgents = argResults!['all-agents'] as bool;
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

      // Determinar plataformas destino
      final targetPlatforms = _resolveTargetPlatforms(
        agents: agents,
        allAgents: allAgents,
      );

      // Crear estructura de directorios
      await _createDirectoryStructure(
        minimal: minimal,
        platforms: targetPlatforms,
      );

      // Crear archivo de configuracion
      await _createConfigFile(projectName, targetPlatforms);

      // Crear archivos base
      await _createBaseFiles(minimal: minimal);

      // Crear archivos de contexto
      if (withContext) {
        await _createContextFiles(targetPlatforms);
      }

      _logger
        ..blank()
        ..success('Proyecto inicializado correctamente!')
        ..blank()
        ..info('Plataformas configuradas:');

      for (final platform in targetPlatforms) {
        _logger.item('${platform.name} (${platform.commandFolder})');
      }

      _logger
        ..blank()
        ..info('Proximos pasos:')
        ..item('Ejecuta: dfspec install')
        ..item('Crea tu primera especificacion en specs/')
        ..item('Usa /df-spec en tu agente de IA para comenzar');

      return 0;
    } catch (e) {
      _logger.error('Error al inicializar: $e');
      return 1;
    }
  }

  /// Resuelve las plataformas destino basado en los argumentos.
  List<AiPlatformConfig> _resolveTargetPlatforms({
    required List<String> agents,
    required bool allAgents,
  }) {
    if (allAgents) {
      return AiPlatformRegistry.all;
    }

    if (agents.isNotEmpty) {
      return agents.map((id) => AiPlatformRegistry.getPlatform(id)!).toList();
    }

    // Default: solo Claude
    return [AiPlatformRegistry.defaultPlatform];
  }

  Future<void> _createDirectoryStructure({
    required bool minimal,
    required List<AiPlatformConfig> platforms,
  }) async {
    _logger.info('Creando estructura de directorios...');

    final directories = [
      'specs',
      'specs/features',
    ];

    // Agregar carpetas de comandos para cada plataforma
    for (final platform in platforms) {
      directories.add(platform.commandFolder);
    }

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

  Future<void> _createConfigFile(
    String projectName,
    List<AiPlatformConfig> platforms,
  ) async {
    _logger.info('Creando archivo de configuracion...');

    final config = DfspecConfig.defaults(projectName);
    final configPath = FileUtils.resolvePath('dfspec.yaml');

    // Agregar plataformas al config
    final configContent = _generateConfigWithPlatforms(config, platforms);
    await FileUtils.writeFile(configPath, configContent, overwrite: true);
    _logger.item('dfspec.yaml', prefix: '  +');
  }

  String _generateConfigWithPlatforms(
    DfspecConfig config,
    List<AiPlatformConfig> platforms,
  ) {
    final buffer = StringBuffer()
      ..writeln('# DFSpec Configuration')
      ..writeln('# Generado automaticamente')
      ..writeln()
      ..writeln('project:')
      ..writeln('  name: ${config.projectName}')
      ..writeln('  configured: true')
      ..writeln()
      ..writeln('# Plataformas de IA configuradas')
      ..writeln('platforms:');

    for (final platform in platforms) {
      buffer
        ..writeln('  - id: ${platform.id}')
        ..writeln('    name: ${platform.name}')
        ..writeln('    commandFolder: ${platform.commandFolder}');
    }

    buffer
      ..writeln()
      ..writeln('# Features del proyecto')
      ..writeln('features: {}')
      ..writeln()
      ..writeln('# Umbrales de calidad')
      ..writeln('quality:')
      ..writeln('  testCoverage: 85')
      ..writeln('  cyclomaticComplexity: 10')
      ..writeln('  cognitiveComplexity: 8')
      ..writeln('  maxLinesPerFile: 400');

    return buffer.toString();
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

  Future<void> _createContextFiles(List<AiPlatformConfig> platforms) async {
    _logger.info('Creando archivos de contexto...');

    for (final platform in platforms) {
      if (platform.contextFile != null) {
        final contextPath = FileUtils.resolvePath(platform.contextFile!);
        final content = _generateContextFile(platform);
        await FileUtils.writeFile(contextPath, content);
        _logger.item(platform.contextFile!, prefix: '  +');
      }
    }
  }

  String _generateContextFile(AiPlatformConfig platform) {
    return '''
# ${platform.name.toUpperCase()} Instructions

Este archivo proporciona instrucciones a ${platform.name} cuando trabaja con DFSpec.

## Descripcion

DFSpec es un toolkit de Spec-Driven Development (SDD) especializado en Dart/Flutter.
Transforma especificaciones en implementaciones de alta calidad siguiendo TDD estricto
y Clean Architecture.

## Comandos Disponibles

| Comando | Uso | Descripcion |
|---------|-----|-------------|
| `/df-spec <feature>` | Crear spec | Define QUE construir |
| `/df-plan <feature>` | Crear plan | Define COMO construir |
| `/df-implement <feature>` | Implementar | TDD: Red -> Green -> Refactor |
| `/df-verify <feature>` | Verificar | Valida implementacion vs spec |
| `/df-status` | Estado | Dashboard del proyecto |
| `/df-test` | Testing | unit, widget, integration |
| `/df-review` | Revision | SOLID, Clean Architecture |
| `/df-security` | Seguridad | OWASP Mobile Top 10 |
| `/df-performance` | Performance | 60fps, memory leaks |
| `/df-quality` | Calidad | Complejidad, code smells |
| `/df-docs` | Documentacion | Effective Dart |
| `/df-deps` | Dependencias | Dependencias seguras |
| `/df-orchestrate` | Pipeline | Orquestacion de agentes |

## Principios Obligatorios

### Clean Architecture

```
lib/src/
├── domain/          # Entidades, interfaces, usecases
├── data/            # Models, datasources, repositories impl
├── presentation/    # Pages, widgets, providers
└── core/            # Constants, theme, network, utils
```

### TDD Estricto

1. **RED**: Test que falla primero
2. **GREEN**: Codigo minimo para pasar
3. **REFACTOR**: Mejorar sin romper tests

### Umbrales de Calidad

| Metrica | Objetivo |
|---------|----------|
| Cobertura tests | >85% |
| Complejidad ciclomatica | <10 |
| Complejidad cognitiva | <8 |
| LOC por archivo | <400 |
| Frame budget | <16ms |
''';
  }

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
2. Usa el template proporcionado o ejecuta `/df-spec` en tu agente de IA
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
