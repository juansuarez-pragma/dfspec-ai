import 'package:args/command_runner.dart';
import 'package:dfspec/src/commands/agents_command.dart';
import 'package:dfspec/src/commands/generate_command.dart';
import 'package:dfspec/src/commands/init_command.dart';
import 'package:dfspec/src/commands/install_command.dart';

/// CommandRunner principal para DFSpec CLI.
///
/// Gestiona todos los subcomandos disponibles:
/// - init: Inicializa un proyecto con estructura DFSpec
/// - install: Instala comandos slash en .claude/commands/
/// - generate: Genera especificaciones desde templates
/// - agents: Lista y muestra informacion de agentes
class DfspecCommandRunner extends CommandRunner<int> {
  /// Crea una nueva instancia del CommandRunner.
  DfspecCommandRunner()
    : super(
        'dfspec',
        'Spec-Driven Development para Flutter/Dart.\n\n'
            'Herramienta CLI que implementa desarrollo guiado por '
            'especificaciones con agentes especializados y TDD estricto.',
      ) {
    // Flag global para version
    argParser.addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Muestra la version de DFSpec.',
    );

    // Comandos disponibles
    addCommand(AgentsCommand());
    addCommand(GenerateCommand());
    addCommand(InitCommand());
    addCommand(InstallCommand());
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final results = parse(args);

      // Manejar --version
      if (results['version'] == true) {
        // Necesario para salida CLI - no hay alternativa en este contexto
        // ignore: avoid_print
        print('dfspec version 0.1.0');
        return 0;
      }

      return await runCommand(results) ?? 0;
    } on UsageException catch (e) {
      // Necesario para mostrar errores de uso al usuario
      // ignore: avoid_print
      print(e);
      return 64; // Codigo de error estandar para uso incorrecto
    }
  }
}
