import 'package:dfspec/src/parsers/agent_parser.dart';
import 'package:test/test.dart';

void main() {
  group('AgentDefinition', () {
    test('debe crear instancia con todos los campos requeridos', () {
      const agent = AgentDefinition(
        id: 'dfplanner',
        name: 'dfplanner',
        description: 'Arquitecto de soluciones',
        model: 'opus',
        tools: ['Read', 'Glob', 'WebSearch'],
        content: '# Agente dfplanner',
        slashCommand: 'df-plan',
      );

      expect(agent.id, equals('dfplanner'));
      expect(agent.name, equals('dfplanner'));
      expect(agent.description, equals('Arquitecto de soluciones'));
      expect(agent.model, equals('opus'));
      expect(agent.tools, equals(['Read', 'Glob', 'WebSearch']));
      expect(agent.content, equals('# Agente dfplanner'));
      expect(agent.slashCommand, equals('df-plan'));
    });

    test('debe tener valores por defecto correctos', () {
      const agent = AgentDefinition(
        id: 'test',
        name: 'test',
        description: 'Test agent',
        content: 'Content',
        slashCommand: 'df-test',
      );

      expect(agent.model, isNull);
      expect(agent.tools, isEmpty);
    });

    test('debe serializar a JSON correctamente', () {
      const agent = AgentDefinition(
        id: 'dfplanner',
        name: 'dfplanner',
        description: 'Arquitecto',
        model: 'opus',
        tools: ['Read', 'Write'],
        content: '# Content',
        slashCommand: 'df-plan',
      );

      final json = agent.toJson();

      expect(json['id'], equals('dfplanner'));
      expect(json['name'], equals('dfplanner'));
      expect(json['description'], equals('Arquitecto'));
      expect(json['model'], equals('opus'));
      expect(json['tools'], equals(['Read', 'Write']));
      expect(json['slashCommand'], equals('df-plan'));
    });
  });

  group('AgentParser', () {
    late AgentParser parser;

    setUp(() {
      parser = AgentParser();
    });

    group('parse', () {
      test('debe parsear agente con YAML frontmatter completo', () {
        const markdown = '''
---
name: dfplanner
description: >
  Arquitecto de soluciones especializado en Dart/Flutter.
model: opus
tools:
  - Read
  - Glob
  - Grep
  - WebSearch
---

# Agente dfplanner - Arquitecto

<role>
Eres un arquitecto de software senior.
</role>
''';

        final agent = parser.parse(markdown, 'dfplanner');

        expect(agent.id, equals('dfplanner'));
        expect(agent.name, equals('dfplanner'));
        expect(agent.description, contains('Arquitecto de soluciones'));
        expect(agent.model, equals('opus'));
        expect(agent.tools, containsAll(['Read', 'Glob', 'Grep', 'WebSearch']));
        expect(agent.content, contains('# Agente dfplanner'));
        expect(agent.content, contains('<role>'));
      });

      test('debe extraer slashCommand del nombre del agente', () {
        const markdown = '''
---
name: dfimplementer
description: Desarrollador TDD
model: opus
tools:
  - Read
  - Write
---

# Content
''';

        final agent = parser.parse(markdown, 'dfimplementer');

        expect(agent.slashCommand, equals('df-implement'));
      });

      test('debe manejar description multilinea', () {
        const markdown = '''
---
name: dftest
description: >
  Especialista en testing.
  Genera tests unitarios,
  de widgets e integracion.
model: sonnet
tools:
  - Read
---

# Content
''';

        final agent = parser.parse(markdown, 'dftest');

        expect(agent.description, contains('Especialista en testing'));
      });

      test('debe manejar agente sin model', () {
        const markdown = '''
---
name: dfstatus
description: Muestra estado del proyecto
tools:
  - Read
  - Glob
---

# Content
''';

        final agent = parser.parse(markdown, 'dfstatus');

        expect(agent.model, isNull);
        expect(agent.tools, equals(['Read', 'Glob']));
      });

      test('debe manejar agente sin tools', () {
        const markdown = '''
---
name: dfspec
description: Crea especificaciones
model: opus
---

# Content
''';

        final agent = parser.parse(markdown, 'dfspec');

        expect(agent.tools, isEmpty);
      });

      test('debe lanzar excepcion si falta frontmatter', () {
        const markdown = '''
# Agente sin frontmatter

Solo contenido markdown.
''';

        expect(
          () => parser.parse(markdown, 'invalid'),
          throwsA(isA<AgentParseException>()),
        );
      });

      test('debe lanzar excepcion si falta name en frontmatter', () {
        const markdown = '''
---
description: Sin nombre
---

# Content
''';

        expect(
          () => parser.parse(markdown, 'invalid'),
          throwsA(isA<AgentParseException>()),
        );
      });

      test('debe lanzar excepcion si falta description', () {
        const markdown = '''
---
name: test
---

# Content
''';

        expect(
          () => parser.parse(markdown, 'test'),
          throwsA(isA<AgentParseException>()),
        );
      });
    });

    group('mapAgentNameToSlashCommand', () {
      test('debe mapear nombres de agentes a comandos slash', () {
        expect(parser.mapAgentNameToSlashCommand('dfplanner'), equals('df-plan'));
        expect(parser.mapAgentNameToSlashCommand('dfimplementer'), equals('df-implement'));
        expect(parser.mapAgentNameToSlashCommand('dftest'), equals('df-test'));
        expect(parser.mapAgentNameToSlashCommand('dfsolid'), equals('df-review'));
        expect(parser.mapAgentNameToSlashCommand('dfsecurity'), equals('df-security'));
        expect(parser.mapAgentNameToSlashCommand('dfperformance'), equals('df-performance'));
        expect(parser.mapAgentNameToSlashCommand('dfdocumentation'), equals('df-docs'));
        expect(parser.mapAgentNameToSlashCommand('dfcodequality'), equals('df-quality'));
        expect(parser.mapAgentNameToSlashCommand('dfdependencies'), equals('df-deps'));
        expect(parser.mapAgentNameToSlashCommand('dforchestrator'), equals('df-orchestrate'));
        expect(parser.mapAgentNameToSlashCommand('dfverifier'), equals('df-verify'));
        expect(parser.mapAgentNameToSlashCommand('dfspec'), equals('df-spec'));
        expect(parser.mapAgentNameToSlashCommand('dfstatus'), equals('df-status'));
      });

      test('debe manejar nombres desconocidos con prefijo df-', () {
        expect(parser.mapAgentNameToSlashCommand('dfcustom'), equals('df-custom'));
        expect(parser.mapAgentNameToSlashCommand('dfnew'), equals('df-new'));
      });
    });

    group('extractFrontmatter', () {
      test('debe extraer frontmatter YAML', () {
        const markdown = '''
---
name: test
description: Test
---

Content here
''';

        final (yaml, content) = parser.extractFrontmatter(markdown);

        expect(yaml, contains('name: test'));
        expect(yaml, contains('description: Test'));
        expect(content.trim(), equals('Content here'));
      });

      test('debe retornar null si no hay frontmatter', () {
        const markdown = '# Just content';

        final (yaml, content) = parser.extractFrontmatter(markdown);

        expect(yaml, isNull);
        expect(content, equals(markdown));
      });
    });
  });
}
