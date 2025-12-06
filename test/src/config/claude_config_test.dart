import 'package:dfspec/src/config/claude_config.dart';
import 'package:test/test.dart';

void main() {
  group('ClaudeCodeConfig', () {
    group('constantes de rutas', () {
      test('commandFolder debe ser .claude/commands', () {
        expect(ClaudeCodeConfig.commandFolder, equals('.claude/commands'));
      });

      test('contextFile debe ser CLAUDE.md', () {
        expect(ClaudeCodeConfig.contextFile, equals('CLAUDE.md'));
      });

      test('commandExtension debe ser .md', () {
        expect(ClaudeCodeConfig.commandExtension, equals('.md'));
      });
    });

    group('modelos', () {
      test('availableModels debe contener opus, sonnet, haiku', () {
        expect(
          ClaudeCodeConfig.availableModels,
          containsAll(['opus', 'sonnet', 'haiku']),
        );
      });

      test('defaultModel debe ser opus', () {
        expect(ClaudeCodeConfig.defaultModel, equals('opus'));
      });

      test('lightModel debe ser haiku', () {
        expect(ClaudeCodeConfig.lightModel, equals('haiku'));
      });

      test('balancedModel debe ser sonnet', () {
        expect(ClaudeCodeConfig.balancedModel, equals('sonnet'));
      });

      test('isValidModel debe retornar true para modelos validos', () {
        expect(ClaudeCodeConfig.isValidModel('opus'), isTrue);
        expect(ClaudeCodeConfig.isValidModel('sonnet'), isTrue);
        expect(ClaudeCodeConfig.isValidModel('haiku'), isTrue);
      });

      test('isValidModel debe retornar false para modelos invalidos', () {
        expect(ClaudeCodeConfig.isValidModel('gpt-4'), isFalse);
        expect(ClaudeCodeConfig.isValidModel('gemini'), isFalse);
        expect(ClaudeCodeConfig.isValidModel('invalid'), isFalse);
      });

      test('getModelForComplexity debe retornar modelo correcto', () {
        expect(ClaudeCodeConfig.getModelForComplexity('high'), equals('opus'));
        expect(
          ClaudeCodeConfig.getModelForComplexity('medium'),
          equals('sonnet'),
        );
        expect(ClaudeCodeConfig.getModelForComplexity('low'), equals('haiku'));
      });

      test('getModelForComplexity debe ser case-insensitive', () {
        expect(ClaudeCodeConfig.getModelForComplexity('HIGH'), equals('opus'));
        expect(ClaudeCodeConfig.getModelForComplexity('Medium'), equals('sonnet'));
        expect(ClaudeCodeConfig.getModelForComplexity('LOW'), equals('haiku'));
      });

      test('getModelForComplexity debe retornar default para valor desconocido', () {
        expect(ClaudeCodeConfig.getModelForComplexity('unknown'), equals('opus'));
      });
    });

    group('herramientas MCP', () {
      test('dartMcpTools debe contener herramientas de Dart', () {
        expect(
          ClaudeCodeConfig.dartMcpTools,
          containsAll([
            'mcp__dart__analyze_files',
            'mcp__dart__run_tests',
            'mcp__dart__dart_format',
            'mcp__dart__pub',
          ]),
        );
      });

      test('coreTools debe contener herramientas basicas', () {
        expect(
          ClaudeCodeConfig.coreTools,
          containsAll(['Read', 'Write', 'Edit', 'Glob', 'Grep', 'Bash', 'Task']),
        );
      });
    });

    group('Task tool params', () {
      test('taskSubagentType debe ser general-purpose', () {
        expect(ClaudeCodeConfig.taskSubagentType, equals('general-purpose'));
      });

      test('createTaskParams debe generar parametros correctos', () {
        final params = ClaudeCodeConfig.createTaskParams(
          model: 'opus',
          description: 'Test task',
          prompt: 'Test prompt content',
        );

        expect(params['subagent_type'], equals('general-purpose'));
        expect(params['model'], equals('opus'));
        expect(params['description'], equals('Test task'));
        expect(params['prompt'], equals('Test prompt content'));
      });

      test('createTaskParams debe usar default para modelo invalido', () {
        final params = ClaudeCodeConfig.createTaskParams(
          model: 'gpt-4',
          description: 'Test',
          prompt: 'Test',
        );

        expect(params['model'], equals('opus'));
      });
    });

    group('utilidades de rutas', () {
      test('getCommandFileName debe agregar extension si falta', () {
        expect(
          ClaudeCodeConfig.getCommandFileName('df-plan'),
          equals('df-plan.md'),
        );
      });

      test('getCommandFileName no debe duplicar extension', () {
        expect(
          ClaudeCodeConfig.getCommandFileName('df-plan.md'),
          equals('df-plan.md'),
        );
      });

      test('getCommandFilePath debe generar ruta completa', () {
        final path = ClaudeCodeConfig.getCommandFilePath(
          '/proyecto',
          'df-plan',
        );

        expect(path, contains('.claude/commands'));
        expect(path, contains('df-plan.md'));
      });

      test('getCommandFolderPath debe generar ruta de carpeta', () {
        final path = ClaudeCodeConfig.getCommandFolderPath('/proyecto');

        expect(path, endsWith('.claude/commands'));
      });

      test('getContextFilePath debe generar ruta de CLAUDE.md', () {
        final path = ClaudeCodeConfig.getContextFilePath('/proyecto');

        expect(path, endsWith('CLAUDE.md'));
      });
    });

    group('frontmatter', () {
      test('generateFrontmatter debe generar YAML valido', () {
        final frontmatter = ClaudeCodeConfig.generateFrontmatter(
          description: 'Test command',
          tools: ['Read', 'Write'],
        );

        expect(frontmatter, startsWith('---\n'));
        expect(frontmatter, contains('description: Test command'));
        expect(frontmatter, contains('allowed-tools: Read, Write'));
        expect(frontmatter, endsWith('---\n'));
      });

      test('generateFrontmatter debe manejar lista de tools vacia', () {
        final frontmatter = ClaudeCodeConfig.generateFrontmatter(
          description: 'Test',
          tools: [],
        );

        expect(frontmatter, contains('allowed-tools: '));
      });
    });
  });
}
