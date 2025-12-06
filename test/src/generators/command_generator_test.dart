import 'package:dfspec/src/generators/command_generator.dart';
import 'package:dfspec/src/models/ai_platform_config.dart';
import 'package:dfspec/src/parsers/agent_parser.dart';
import 'package:test/test.dart';

void main() {
  group('CommandTemplate', () {
    test('debe crear instancia con todos los campos', () {
      const template = CommandTemplate(
        name: 'df-spec',
        description: 'Crea especificaciones',
        tools: ['Read', 'Write', 'Glob'],
        content: 'Contenido del comando',
      );

      expect(template.name, equals('df-spec'));
      expect(template.description, equals('Crea especificaciones'));
      expect(template.tools, equals(['Read', 'Write', 'Glob']));
      expect(template.content, equals('Contenido del comando'));
    });

    test('fromAgent debe crear template desde AgentDefinition', () {
      const agent = AgentDefinition(
        id: 'dfplanner',
        name: 'dfplanner',
        description: 'Arquitecto de soluciones',
        content: '# Agente dfplanner\n\nContenido completo.',
        slashCommand: 'df-plan',
        model: 'opus',
        tools: ['Read', 'Glob', 'Grep'],
      );

      final template = CommandTemplate.fromAgent(agent);

      expect(template.name, equals('df-plan'));
      expect(template.description, equals('Arquitecto de soluciones'));
      expect(template.tools, equals(['Read', 'Glob', 'Grep']));
      expect(template.content, equals('# Agente dfplanner\n\nContenido completo.'));
    });

    test('fromAgent debe manejar agente sin tools', () {
      const agent = AgentDefinition(
        id: 'dfstatus',
        name: 'dfstatus',
        description: 'Muestra estado del proyecto',
        content: '# Status',
        slashCommand: 'df-status',
      );

      final template = CommandTemplate.fromAgent(agent);

      expect(template.tools, isEmpty);
    });
  });

  group('CommandGenerator', () {
    group('forPlatform factory', () {
      test('debe retornar MarkdownCommandGenerator para formato markdown', () {
        const config = AiPlatformConfig(
          id: 'claude',
          name: 'Claude Code',
          commandFolder: '.claude/commands/',
          commandFormat: CommandFormat.markdown,
        );

        final generator = CommandGenerator.forPlatform(config);
        expect(generator, isA<MarkdownCommandGenerator>());
      });

      test('debe retornar TomlCommandGenerator para formato toml', () {
        const config = AiPlatformConfig(
          id: 'gemini',
          name: 'Gemini CLI',
          commandFolder: '.gemini/commands/',
          commandFormat: CommandFormat.toml,
        );

        final generator = CommandGenerator.forPlatform(config);
        expect(generator, isA<TomlCommandGenerator>());
      });
    });
  });

  group('MarkdownCommandGenerator', () {
    late MarkdownCommandGenerator generator;

    setUp(() {
      generator = MarkdownCommandGenerator();
    });

    test('debe generar formato markdown con frontmatter', () {
      const template = CommandTemplate(
        name: 'df-spec',
        description: 'Crea especificaciones de features',
        tools: ['Read', 'Write', 'Glob'],
        content: '# Comando df-spec\n\nContenido del prompt.',
      );

      final output = generator.generate(template);

      expect(output, contains('---'));
      expect(output, contains('description: Crea especificaciones de features'));
      expect(output, contains('allowed-tools: Read, Write, Glob'));
      expect(output, contains('# Comando df-spec'));
      expect(output, contains('Contenido del prompt.'));
    });

    test('debe manejar lista vacia de tools', () {
      const template = CommandTemplate(
        name: 'df-status',
        description: 'Muestra estado',
        tools: [],
        content: 'Contenido',
      );

      final output = generator.generate(template);

      expect(output, contains('allowed-tools:'));
    });

    test('debe preservar formato multilinea del contenido', () {
      const template = CommandTemplate(
        name: 'test',
        description: 'Test',
        tools: [],
        content: '''
Linea 1
Linea 2
Linea 3''',
      );

      final output = generator.generate(template);

      expect(output, contains('Linea 1'));
      expect(output, contains('Linea 2'));
      expect(output, contains('Linea 3'));
    });
  });

  group('TomlCommandGenerator', () {
    late TomlCommandGenerator generator;

    setUp(() {
      generator = TomlCommandGenerator();
    });

    test('debe generar formato TOML valido', () {
      const template = CommandTemplate(
        name: 'df-spec',
        description: 'Crea especificaciones de features',
        tools: ['Read', 'Write', 'Glob'],
        content: 'Contenido del prompt.',
      );

      final output = generator.generate(template);

      expect(output, contains('[command]'));
      expect(output, contains('name = "df-spec"'));
      expect(output, contains('description = "Crea especificaciones de features"'));
      expect(output, contains('tools = ["Read", "Write", "Glob"]'));
      expect(output, contains('[prompt]'));
      expect(output, contains('content = """'));
      expect(output, contains('Contenido del prompt.'));
      expect(output, contains('"""'));
    });

    test('debe escapar comillas en descripcion', () {
      const template = CommandTemplate(
        name: 'test',
        description: 'Descripcion con "comillas"',
        tools: [],
        content: 'Contenido',
      );

      final output = generator.generate(template);

      expect(output, contains(r'description = "Descripcion con \"comillas\""'));
    });

    test('debe manejar contenido multilinea', () {
      const template = CommandTemplate(
        name: 'test',
        description: 'Test',
        tools: [],
        content: '''
Linea 1
Linea 2
Linea 3''',
      );

      final output = generator.generate(template);

      expect(output, contains('"""'));
      expect(output, contains('Linea 1'));
      expect(output, contains('Linea 2'));
    });

    test('debe generar array vacio para tools vacios', () {
      const template = CommandTemplate(
        name: 'test',
        description: 'Test',
        tools: [],
        content: 'Contenido',
      );

      final output = generator.generate(template);

      expect(output, contains('tools = []'));
    });
  });
}
