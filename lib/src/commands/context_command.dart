import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:dfspec/src/models/feature_context.dart';
import 'package:dfspec/src/models/project_context.dart';
import 'package:dfspec/src/services/context_detector.dart';
import 'package:dfspec/src/utils/logger.dart';

/// Comando para detectar y mostrar el contexto del proyecto.
///
/// Uso:
/// ```bash
/// dfspec context                    # Muestra contexto completo
/// dfspec context --json             # Salida JSON
/// dfspec context --feature=001-auth # Override de feature
/// dfspec context check              # Verifica prerequisitos
/// dfspec context validate           # Valida spec actual
/// ```
class ContextCommand extends Command<int> {
  /// Crea el comando context.
  ContextCommand() {
    argParser
      ..addFlag(
        'json',
        abbr: 'j',
        help: 'Salida en formato JSON',
        negatable: false,
      )
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'Override de feature (ej: 001-auth)',
      );

    addSubcommand(_CheckSubcommand());
    addSubcommand(_ValidateSubcommand());
    addSubcommand(_NextSubcommand());
  }

  @override
  String get name => 'context';

  @override
  String get description => 'Detecta y muestra el contexto del proyecto';

  @override
  Future<int> run() async {
    final jsonOutput = argResults?['json'] as bool? ?? false;
    final featureOverride = argResults?['feature'] as String?;
    const logger = Logger();

    try {
      final detector = ContextDetector();
      final context = await detector.detectFullContext(
        featureOverride: featureOverride,
      );

      if (jsonOutput) {
        stdout.writeln(
          const JsonEncoder.withIndent('  ').convert(context.toJson()),
        );
      } else {
        _printContext(context, logger);
      }

      return 0;
    } on ContextDetectionException catch (e) {
      logger.error('Error detectando contexto: ${e.message}');
      return 1;
    } catch (e) {
      logger.error('Error inesperado: $e');
      return 1;
    }
  }

  void _printContext(ProjectContext context, Logger logger) {
    // Códigos ANSI para colores
    const reset = '\x1B[0m';
    const cyan = '\x1B[36m';
    const green = '\x1B[32m';
    const yellow = '\x1B[33m';
    const red = '\x1B[31m';

    stdout.writeln();
    logger.info('DFSpec Context');
    stdout.writeln('═' * 50);
    stdout.writeln();

    // Project
    stdout.writeln('${cyan}Proyecto:$reset');
    if (context.project.name.isNotEmpty) {
      stdout.writeln('  Nombre: ${context.project.name}');
    }
    stdout.writeln('  Tipo: ${context.project.type.name}');
    if (context.project.stateManagement.isNotEmpty) {
      stdout.writeln('  State Management: ${context.project.stateManagement}');
    }
    if (context.project.platforms.isNotEmpty) {
      stdout.writeln('  Plataformas: ${context.project.platforms.join(', ')}');
    }
    stdout.writeln(
      '  dfspec.yaml: ${_statusIcon(context.project.hasDfspecConfig, green, red)}',
    );
    stdout.writeln(
      '  pubspec.yaml: ${_statusIcon(context.project.hasPubspec, green, red)}',
    );
    stdout.writeln(
      '  constitution.md: ${_statusIcon(context.project.hasConstitution, green, red)}',
    );
    stdout.writeln();

    // Git
    stdout.writeln('${cyan}Git:$reset');
    if (context.git.isGitRepo) {
      stdout.writeln('  Branch: ${context.git.currentBranch}');
      stdout.writeln(
        '  Cambios sin commit: ${_statusIcon(!context.git.hasUncommittedChanges, green, red, invert: true)}',
      );
      if (context.git.remoteUrl.isNotEmpty) {
        stdout.writeln('  Remote: ${context.git.remoteUrl}');
      }
    } else {
      stdout.writeln('  ${yellow}No es un repositorio git$reset');
    }
    stdout.writeln();

    // Feature
    stdout.writeln('${cyan}Feature Actual:$reset');
    if (context.feature.hasFeature) {
      stdout.writeln('  ID: ${context.feature.id}');
      stdout.writeln('  Número: ${context.feature.number}');
      stdout.writeln('  Estado: ${_formatStatus(context.feature.status)}');
      stdout.writeln('  Documentos:');
      for (final doc in context.feature.documents.availableDocuments) {
        stdout.writeln('    $green✓$reset $doc');
      }
      stdout.writeln();
      stdout.writeln('  Acciones disponibles:');
      if (!context.feature.documents.specExists) {
        stdout.writeln('    → /df-spec para crear especificación');
      } else if (!context.feature.documents.planExists) {
        stdout.writeln('    → /df-plan para crear plan');
      } else if (!context.feature.documents.tasksExists) {
        stdout.writeln('    → /df-tasks para crear tareas');
      } else {
        stdout.writeln('    → /df-implement para implementar');
      }
    } else {
      stdout.writeln('  ${yellow}Ninguna feature detectada$reset');
      stdout.writeln(
        '  Siguiente número disponible: ${context.nextFeatureNumber}',
      );
      stdout.writeln('  → /df-spec para crear nueva feature');
    }
    stdout.writeln();

    // Quality
    stdout.writeln('${cyan}Métricas:$reset');
    stdout.writeln('  Tests: ${context.quality.testFileCount} archivos');
    stdout.writeln('  Código: ${context.quality.libFileCount} archivos');
    if (context.quality.testRatio > 0) {
      stdout.writeln(
        '  Ratio test/código: ${context.quality.testRatio.toStringAsFixed(2)}',
      );
    }
    if (context.quality.hasRecoveryPoints) {
      stdout.writeln(
        '  Recovery chains: ${context.quality.recoveryChainCount}',
      );
    }
    stdout.writeln();

    // Status message
    stdout.writeln('─' * 50);
    stdout.writeln(context.statusMessage);
    stdout.writeln();
  }

  String _statusIcon(
    bool status,
    String goodColor,
    String badColor, {
    bool invert = false,
  }) {
    const reset = '\x1B[0m';
    final isGood = invert ? !status : status;
    return isGood ? '$goodColor✓$reset' : '$badColor✗$reset';
  }

  String _formatStatus(SddFeatureStatus status) {
    const reset = '\x1B[0m';
    const gray = '\x1B[90m';
    const blue = '\x1B[34m';
    const cyan = '\x1B[36m';
    const yellow = '\x1B[33m';
    const green = '\x1B[32m';

    switch (status) {
      case SddFeatureStatus.none:
        return '${gray}none$reset';
      case SddFeatureStatus.specified:
        return '${blue}specified$reset';
      case SddFeatureStatus.planned:
        return '${cyan}planned$reset';
      case SddFeatureStatus.readyToImplement:
        return '${yellow}ready to implement$reset';
      case SddFeatureStatus.implementing:
        return '${yellow}implementing$reset';
      case SddFeatureStatus.implemented:
        return '${green}implemented$reset';
      case SddFeatureStatus.verified:
        return '${green}verified ✓$reset';
    }
  }
}

/// Subcomando para verificar prerequisitos.
class _CheckSubcommand extends Command<int> {
  _CheckSubcommand() {
    argParser
      ..addFlag(
        'json',
        abbr: 'j',
        help: 'Salida en formato JSON',
        negatable: false,
      )
      ..addFlag(
        'require-spec',
        help: 'Requiere que exista spec.md',
        negatable: false,
      )
      ..addFlag(
        'require-plan',
        help: 'Requiere que exista plan.md',
        negatable: false,
      )
      ..addFlag(
        'require-tasks',
        help: 'Requiere que exista tasks.md',
        negatable: false,
      )
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'Override de feature',
      );
  }

  @override
  String get name => 'check';

  @override
  String get description => 'Verifica prerequisitos para un paso del flujo';

  @override
  Future<int> run() async {
    final jsonOutput = argResults?['json'] as bool? ?? false;
    final requireSpec = argResults?['require-spec'] as bool? ?? false;
    final requirePlan = argResults?['require-plan'] as bool? ?? false;
    final requireTasks = argResults?['require-tasks'] as bool? ?? false;
    final featureOverride = argResults?['feature'] as String?;
    const logger = Logger();

    try {
      final detector = ContextDetector();
      final result = await detector.checkPrerequisites(
        requireSpec: requireSpec,
        requirePlan: requirePlan,
        requireTasks: requireTasks,
        featureOverride: featureOverride,
      );

      if (jsonOutput) {
        stdout.writeln(
          const JsonEncoder.withIndent('  ').convert(result.toJson()),
        );
      } else {
        if (result.passed) {
          logger.success('Prerequisitos verificados');
          stdout.writeln('Feature: ${result.featureId}');
          stdout.writeln(
            'Documentos disponibles: ${result.availableDocuments.join(', ')}',
          );
        } else {
          logger.error('Prerequisitos no cumplidos');
          if (result.errorMessage != null) {
            stdout.writeln('Error: ${result.errorMessage}');
          }
        }
      }

      return result.passed ? 0 : 1;
    } catch (e) {
      logger.error('Error: $e');
      return 1;
    }
  }
}

/// Subcomando para validar especificación.
class _ValidateSubcommand extends Command<int> {
  _ValidateSubcommand() {
    argParser
      ..addFlag(
        'json',
        abbr: 'j',
        help: 'Salida en formato JSON',
        negatable: false,
      )
      ..addFlag(
        'strict',
        help: 'Modo estricto (falla con warnings)',
        negatable: false,
      )
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'Override de feature',
      );
  }

  @override
  String get name => 'validate';

  @override
  String get description => 'Valida la calidad de la especificación actual';

  @override
  Future<int> run() async {
    final jsonOutput = argResults?['json'] as bool? ?? false;
    final strict = argResults?['strict'] as bool? ?? false;
    final featureOverride = argResults?['feature'] as String?;
    const logger = Logger();

    // Códigos ANSI
    const reset = '\x1B[0m';
    const red = '\x1B[31m';
    const yellow = '\x1B[33m';
    const green = '\x1B[32m';
    const blue = '\x1B[34m';

    try {
      final detector = ContextDetector();
      final result = await detector.validateSpec(
        featureOverride: featureOverride,
        strict: strict,
      );

      if (jsonOutput) {
        stdout.writeln(
          const JsonEncoder.withIndent('  ').convert(result.toJson()),
        );
      } else {
        stdout.writeln();
        stdout.writeln('Validación de Spec: ${result.featureId}');
        stdout.writeln('─' * 40);
        stdout.writeln();

        // Score
        final scoreColor = result.score >= 80
            ? green
            : result.score >= 60
                ? yellow
                : red;
        stdout.writeln('Score: $scoreColor${result.score}/100$reset');
        stdout.writeln();

        // Counts
        if (result.criticalCount > 0) {
          stdout.writeln('${red}Críticos: ${result.criticalCount}$reset');
        }
        if (result.warningCount > 0) {
          stdout.writeln('${yellow}Warnings: ${result.warningCount}$reset');
        }
        if (result.infoCount > 0) {
          stdout.writeln('${blue}Info: ${result.infoCount}$reset');
        }
        stdout.writeln();

        // Findings
        if (result.findings.isNotEmpty) {
          stdout.writeln('Hallazgos:');
          for (final finding in result.findings) {
            final icon = finding.severity == FindingSeverity.critical
                ? '$red✗$reset'
                : finding.severity == FindingSeverity.warning
                    ? '$yellow⚠$reset'
                    : '$blue ℹ$reset';
            stdout.writeln('  $icon [${finding.code}] ${finding.message}');
          }
          stdout.writeln();
        }

        // Result
        if (result.passed) {
          logger.success('Spec válida');
        } else {
          logger.error('Spec requiere correcciones');
        }
      }

      return result.passed ? 0 : 1;
    } catch (e) {
      logger.error('Error: $e');
      return 1;
    }
  }
}

/// Subcomando para obtener siguiente número de feature.
class _NextSubcommand extends Command<int> {
  _NextSubcommand() {
    argParser.addFlag(
      'json',
      abbr: 'j',
      help: 'Salida en formato JSON',
      negatable: false,
    );
  }

  @override
  String get name => 'next';

  @override
  String get description => 'Muestra el siguiente número de feature disponible';

  @override
  Future<int> run() async {
    final jsonOutput = argResults?['json'] as bool? ?? false;
    const logger = Logger();

    try {
      final detector = ContextDetector();
      final nextNumber = await detector.getNextFeatureNumber();

      if (jsonOutput) {
        stdout.writeln(jsonEncode({'next_feature_number': nextNumber}));
      } else {
        stdout.writeln('Siguiente número de feature: $nextNumber');
      }

      return 0;
    } catch (e) {
      logger.error('Error: $e');
      return 1;
    }
  }
}
