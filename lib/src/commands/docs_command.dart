import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dfspec/src/models/documentation_spec.dart';
import 'package:dfspec/src/services/documentation_generator.dart';
import 'package:dfspec/src/utils/logger.dart';

/// Comando para gestión de documentación.
///
/// Uso:
/// ```bash
/// dfspec docs verify
/// dfspec docs verify --threshold=85
/// dfspec docs generate --type=readme --feature=city-search
/// dfspec docs generate --type=changelog --version=1.2.0
/// dfspec docs generate --type=architecture
/// ```
class DocsCommand extends Command<int> {
  /// Crea el comando docs.
  DocsCommand() {
    addSubcommand(_VerifySubcommand());
    addSubcommand(_GenerateSubcommand());
  }

  @override
  String get name => 'docs';

  @override
  String get description => 'Gestiona documentación del proyecto.';

  @override
  String get invocation => 'dfspec docs <subcomando>';
}

/// Subcomando para verificar documentación.
class _VerifySubcommand extends Command<int> {
  _VerifySubcommand() {
    argParser
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Ruta específica a verificar.',
      )
      ..addOption(
        'threshold',
        abbr: 't',
        defaultsTo: '80',
        help: 'Porcentaje mínimo de cobertura.',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Muestra todos los issues encontrados.',
        negatable: false,
      );
  }

  @override
  String get name => 'verify';

  @override
  String get description => 'Verifica cobertura de documentación.';

  @override
  Future<int> run() async {
    const logger = Logger();
    final path = argResults!['path'] as String?;
    final threshold = int.parse(argResults!['threshold'] as String);
    final verbose = argResults!['verbose'] as bool;

    logger.info('Verificando documentación...');

    try {
      final generator = DocumentationGenerator(
        projectRoot: Directory.current.path,
      );

      final paths = path != null ? [path] : null;
      final report = await generator.verifyDocumentation(paths: paths);

      // Mostrar resumen
      logger.blank();
      logger.title('Reporte de Documentación');
      logger.blank();
      logger.write('Archivos analizados: ${report.filesAnalyzed}');
      logger.write(
        'Cobertura: ${(report.coverage * 100).toStringAsFixed(1)}% '
        '(${report.documented}/${report.total})',
      );
      logger.blank();

      // Mostrar issues
      if (report.issues.isNotEmpty) {
        logger.section('Issues Encontrados');

        final issuesToShow = verbose ? report.issues : report.issues.take(10);
        for (final issue in issuesToShow) {
          logger.warning('$issue');
        }

        if (!verbose && report.issues.length > 10) {
          logger.info('... y ${report.issues.length - 10} más');
          logger.info('Use --verbose para ver todos');
        }
      }

      // Evaluar resultado
      logger.blank();
      final coveragePercent = report.coverage * 100;

      if (coveragePercent >= threshold) {
        logger.success(
          'Documentación OK: ${coveragePercent.toStringAsFixed(1)}% '
          '(umbral: $threshold%)',
        );
        return 0;
      } else {
        logger.error(
          'Documentación insuficiente: ${coveragePercent.toStringAsFixed(1)}% '
          '(umbral: $threshold%)',
        );
        return 1;
      }
    } catch (e) {
      logger.error('Error verificando documentación: $e');
      return 1;
    }
  }
}

/// Subcomando para generar documentación.
class _GenerateSubcommand extends Command<int> {
  _GenerateSubcommand() {
    argParser
      ..addOption(
        'type',
        abbr: 't',
        allowed: ['readme', 'changelog', 'architecture', 'spec', 'plan'],
        help: 'Tipo de documentación a generar.',
        mandatory: true,
      )
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'Nombre de la feature (para readme, spec, plan).',
      )
      ..addOption(
        'version',
        abbr: 'v',
        help: 'Versión (para changelog).',
      )
      ..addOption(
        'description',
        abbr: 'd',
        help: 'Descripción breve.',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Ruta de salida personalizada.',
      );
  }

  @override
  String get name => 'generate';

  @override
  String get description => 'Genera documentación automáticamente.';

  @override
  Future<int> run() async {
    const logger = Logger();
    final type = argResults!['type'] as String;
    final feature = argResults!['feature'] as String?;
    final version = argResults!['version'] as String?;
    final description = argResults!['description'] as String?;
    final output = argResults!['output'] as String?;

    try {
      final generator = DocumentationGenerator(
        projectRoot: Directory.current.path,
      );

      DocumentationResult result;

      switch (type) {
        case 'readme':
          if (feature == null) {
            logger.error('--feature es requerido para tipo readme');
            return 1;
          }
          result = await generator.generateFeatureReadme(
            featureName: feature,
            description: description,
          );

        case 'changelog':
          if (version == null) {
            logger.error('--version es requerido para tipo changelog');
            return 1;
          }
          result = await generator.generateChangelog(
            version: version,
            added: description != null ? [description] : [],
          );

        case 'architecture':
          result = await generator.generateArchitecture();

        case 'spec':
          if (feature == null) {
            logger.error('--feature es requerido para tipo spec');
            return 1;
          }
          result = await generator.generateFeatureSpec(
            featureName: feature,
            description: description ?? 'Feature $feature',
            acceptanceCriteria: ['Criterio por definir'],
          );

        case 'plan':
          if (feature == null) {
            logger.error('--feature es requerido para tipo plan');
            return 1;
          }
          result = await generator.generateImplementationPlan(
            featureName: feature,
            steps: [
              ImplementationStep(
                name: 'Setup',
                description: 'Configuración inicial del proyecto',
                files: ['lib/src/domain/$feature.dart'],
                tests: ['test/unit/${feature}_test.dart'],
              ),
            ],
          );

        default:
          logger.error('Tipo no soportado: $type');
          return 1;
      }

      // Si hay output personalizado, mover archivo
      if (output != null) {
        final sourceFile = File(
          '${Directory.current.path}/${result.outputPath}',
        );
        final targetFile = File(output);

        await targetFile.parent.create(recursive: true);
        await sourceFile.copy(output);
        await sourceFile.delete();

        logger.success('Documentación generada en: $output');
      } else {
        logger.success('Documentación generada en: ${result.outputPath}');
      }

      // Mostrar preview
      logger.blank();
      logger.info('Preview (primeras 20 líneas):');
      logger.separator();
      final preview = result.content.split('\n').take(20).join('\n');
      logger.write(preview);
      if (result.content.split('\n').length > 20) {
        logger.info('...');
      }

      return 0;
    } catch (e) {
      logger.error('Error generando documentación: $e');
      return 1;
    }
  }
}
