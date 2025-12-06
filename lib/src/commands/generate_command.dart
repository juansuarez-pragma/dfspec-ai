import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dfspec/src/generators/generators.dart';
import 'package:dfspec/src/models/models.dart';
import 'package:dfspec/src/utils/utils.dart';

/// Comando para generar especificaciones.
///
/// Crea archivos de especificacion basados en templates.
///
/// Uso:
/// ```bash
/// dfspec generate feature "Mi Feature"
/// dfspec generate --type=architecture "Nombre Decision"
/// ```
class GenerateCommand extends Command<int> {
  /// Crea una nueva instancia del comando generate.
  GenerateCommand() {
    argParser
      ..addOption(
        'type',
        abbr: 't',
        help: 'Tipo de especificacion a generar.',
        allowed: SpecType.values.map((t) => t.value).toList(),
        defaultsTo: SpecType.feature.value,
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Directorio de salida personalizado.',
      )
      ..addOption(
        'author',
        abbr: 'a',
        help: 'Autor de la especificacion.',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Sobrescribe archivos existentes.',
        negatable: false,
      )
      ..addFlag(
        'list',
        abbr: 'l',
        help: 'Lista los tipos de especificacion disponibles.',
        negatable: false,
      );
  }

  @override
  String get name => 'generate';

  @override
  List<String> get aliases => ['gen', 'g'];

  @override
  String get description => 'Genera archivos de especificacion desde templates.';

  @override
  String get invocation => 'dfspec generate [tipo] <nombre>';

  final Logger _logger = const Logger();

  @override
  Future<int> run() async {
    final listOnly = argResults!['list'] as bool;

    // Modo lista
    if (listOnly) {
      _logger.title('Tipos de especificacion disponibles');
      for (final type in SpecType.values) {
        _logger.item('${type.value} - ${type.description}');
      }
      return 0;
    }

    // Obtener tipo y nombre
    final typeArg = argResults!['type'] as String;
    final force = argResults!['force'] as bool;
    final customOutput = argResults!['output'] as String?;
    final author = argResults!['author'] as String?;

    // El nombre puede venir como argumento posicional o como parte de rest
    if (argResults!.rest.isEmpty) {
      _logger..error('Debe proporcionar un nombre para la especificacion.')
      ..info('Uso: dfspec generate [tipo] <nombre>')
      ..info('Ejemplo: dfspec generate feature "Autenticacion OAuth"');
      return 1;
    }

    // Determinar tipo y nombre
    SpecType? type;
    String name;

    // Si el primer argumento es un tipo valido, usarlo
    final firstArg = argResults!.rest.first;
    final maybeType = SpecType.fromString(firstArg);

    if (maybeType != null) {
      type = maybeType;
      if (argResults!.rest.length < 2) {
        _logger.error('Debe proporcionar un nombre para la especificacion.');
        return 1;
      }
      name = argResults!.rest.skip(1).join(' ');
    } else {
      type = SpecType.fromString(typeArg);
      name = argResults!.rest.join(' ');
    }

    if (type == null) {
      _logger..error('Tipo de especificacion invalido: $typeArg')
      ..info('Usa --list para ver los tipos disponibles.');
      return 1;
    }

    _logger..title('Generando especificacion')
    ..info('Tipo: ${type.description}')
    ..info('Nombre: $name');

    // Preparar variables
    final variables = <String, String>{};
    if (author != null) {
      variables['author'] = author;
    }

    // Generar especificacion
    final generator = SpecGenerator(baseDir: Directory.current.path);
    final result = await generator.generate(
      type: type,
      name: name,
      variables: variables,
      overwrite: force,
      customDir: customOutput,
    );

    if (!result.isSuccess) {
      _logger.error(result.error ?? 'Error desconocido');
      return 1;
    }

    _logger.blank();
    if (result.overwritten) {
      _logger.warning('Archivo sobrescrito: ${result.filePath}');
    } else {
      _logger.success('Archivo creado: ${result.filePath}');
    }

    _logger..blank()
    ..info('Proximos pasos:')
    ..item('Edita el archivo con los detalles de tu especificacion')
    ..item('Usa /df-spec en Claude Code para completar la especificacion');

    return 0;
  }
}
