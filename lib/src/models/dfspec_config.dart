import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Configuracion del proyecto DFSpec.
///
/// Almacena la configuracion leida desde dfspec.yaml
/// y proporciona valores por defecto.
@immutable
class DfspecConfig {
  /// Crea una nueva configuracion.
  const DfspecConfig({
    required this.projectName,
    this.specDir = 'specs',
    this.outputDir = '.claude/commands',
    this.templateDir = 'templates',
    this.agents = const <String>[],
  });

  /// Crea una configuracion por defecto para un proyecto.
  factory DfspecConfig.defaults(String projectName) {
    return DfspecConfig(
      projectName: projectName,
      agents: defaultAgents,
    );
  }

  /// Crea una configuracion desde un mapa YAML.
  factory DfspecConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    return DfspecConfig(
      projectName: yaml['project_name'] as String? ?? 'unnamed',
      specDir: yaml['spec_dir'] as String? ?? 'specs',
      outputDir: yaml['output_dir'] as String? ?? '.claude/commands',
      templateDir: yaml['template_dir'] as String? ?? 'templates',
      agents: (yaml['agents'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  /// Carga la configuracion desde dfspec.yaml en el directorio dado.
  ///
  /// Retorna null si el archivo no existe.
  static Future<DfspecConfig?> load(String directory) async {
    final configFile = File(p.join(directory, 'dfspec.yaml'));

    if (!configFile.existsSync()) {
      return null;
    }

    final content = await configFile.readAsString();
    final yaml = loadYaml(content) as Map<dynamic, dynamic>?;

    if (yaml == null) {
      return null;
    }

    return DfspecConfig.fromYaml(yaml);
  }

  /// Nombre del proyecto.
  final String projectName;

  /// Directorio donde se almacenan las especificaciones.
  final String specDir;

  /// Directorio de salida para comandos slash generados.
  final String outputDir;

  /// Directorio de templates personalizados.
  final String templateDir;

  /// Lista de agentes habilitados.
  final List<String> agents;

  /// Convierte la configuracion a formato YAML.
  String toYaml() {
    final buffer = StringBuffer()
      ..writeln('# Configuracion DFSpec')
      ..writeln('# Spec-Driven Development para Flutter/Dart')
      ..writeln()
      ..writeln('project_name: $projectName')
      ..writeln()
      ..writeln('# Directorios')
      ..writeln('spec_dir: $specDir')
      ..writeln('output_dir: $outputDir')
      ..writeln('template_dir: $templateDir')
      ..writeln()
      ..writeln('# Agentes habilitados')
      ..writeln('agents:');

    for (final agent in agents) {
      buffer.writeln('  - $agent');
    }

    return buffer.toString();
  }

  /// Lista de agentes disponibles por defecto.
  static const List<String> defaultAgents = [
    'dforchestrator',
    'dfplanner',
    'dfsolid',
    'dfsecurity',
    'dfdependencies',
    'dfimplementer',
    'dftest',
    'dfcodequality',
    'dfperformance',
    'dfdocumentation',
    'dfverifier',
  ];
}
