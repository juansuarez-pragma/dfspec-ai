import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dfspec/src/models/models.dart';
import 'package:dfspec/src/utils/utils.dart';

/// Comando para inicializar un proyecto con estructura DFSpec.
///
/// Crea la estructura de directorios y archivos necesarios
/// para trabajar con Spec-Driven Development.
///
/// Uso:
/// ```bash
/// dfspec init [nombre_proyecto]
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
      );
  }

  @override
  String get name => 'init';

  @override
  String get description =>
      'Inicializa un proyecto con estructura DFSpec para Spec-Driven Development.';

  @override
  String get invocation => 'dfspec init [nombre_proyecto]';

  final Logger _logger = const Logger();

  @override
  Future<int> run() async {
    final force = argResults!['force'] as bool;
    final minimal = argResults!['minimal'] as bool;

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

      _logger..blank()
      ..success('Proyecto inicializado correctamente!')
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
      '.claude/commands',
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

    final config = DfspecConfig.defaults(projectName);
    final configPath = FileUtils.resolvePath('dfspec.yaml');

    await FileUtils.writeFile(configPath, config.toYaml(), overwrite: true);
    _logger.item('dfspec.yaml', prefix: '  +');
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

    // .gitkeep para .claude/commands
    await FileUtils.writeFile(
      FileUtils.resolvePath('.claude/commands/.gitkeep'),
      '',
    );
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
