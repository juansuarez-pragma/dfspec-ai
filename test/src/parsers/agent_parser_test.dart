import 'package:dfspec/src/parsers/agent_parser.dart';
import 'package:test/test.dart';

void main() {
  group('AgentHandoff', () {
    test('debe crear instancia con todos los campos', () {
      const handoff = AgentHandoff(
        command: 'df-plan',
        label: 'Crear plan',
        description: 'Genera plan de implementacion',
        auto: true,
      );

      expect(handoff.command, equals('df-plan'));
      expect(handoff.label, equals('Crear plan'));
      expect(handoff.description, equals('Genera plan de implementacion'));
      expect(handoff.auto, isTrue);
    });

    test('debe tener auto como false por defecto', () {
      const handoff = AgentHandoff(
        command: 'df-test',
        label: 'Ejecutar tests',
      );

      expect(handoff.auto, isFalse);
      expect(handoff.description, isNull);
    });

    test('debe crear desde mapa YAML', () {
      final yaml = <dynamic, dynamic>{
        'command': 'df-implement',
        'label': 'Implementar',
        'description': 'Iniciar TDD',
        'auto': true,
      };

      final handoff = AgentHandoff.fromYaml(yaml);

      expect(handoff.command, equals('df-implement'));
      expect(handoff.label, equals('Implementar'));
      expect(handoff.description, equals('Iniciar TDD'));
      expect(handoff.auto, isTrue);
    });

    test('debe manejar valores faltantes en fromYaml', () {
      final yaml = <dynamic, dynamic>{
        'command': 'df-test',
        'label': 'Test',
      };

      final handoff = AgentHandoff.fromYaml(yaml);

      expect(handoff.command, equals('df-test'));
      expect(handoff.label, equals('Test'));
      expect(handoff.description, isNull);
      expect(handoff.auto, isFalse);
    });

    test('debe convertir a JSON correctamente', () {
      const handoff = AgentHandoff(
        command: 'df-verify',
        label: 'Verificar',
        description: 'Validar implementacion',
        auto: true,
      );

      final json = handoff.toJson();

      expect(json['command'], equals('df-verify'));
      expect(json['label'], equals('Verificar'));
      expect(json['description'], equals('Validar implementacion'));
      expect(json['auto'], isTrue);
    });

    test('debe omitir description null en toJson', () {
      const handoff = AgentHandoff(
        command: 'df-test',
        label: 'Test',
      );

      final json = handoff.toJson();

      expect(json.containsKey('description'), isFalse);
    });
  });

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
      expect(agent.handoffs, isEmpty);
    });

    test('debe crear instancia con handoffs', () {
      const handoffs = [
        AgentHandoff(command: 'df-plan', label: 'Plan', auto: true),
        AgentHandoff(command: 'df-test', label: 'Test'),
      ];

      const agent = AgentDefinition(
        id: 'dfspec',
        name: 'dfspec',
        description: 'Spec agent',
        content: 'Content',
        slashCommand: 'df-spec',
        handoffs: handoffs,
      );

      expect(agent.handoffs.length, equals(2));
      expect(agent.hasHandoffs, isTrue);
    });

    test('hasHandoffs debe retornar false si no hay handoffs', () {
      const agent = AgentDefinition(
        id: 'test',
        name: 'test',
        description: 'Test',
        content: 'Content',
        slashCommand: 'df-test',
      );

      expect(agent.hasHandoffs, isFalse);
    });

    test('autoHandoffs debe filtrar solo handoffs automaticos', () {
      const handoffs = [
        AgentHandoff(command: 'df-plan', label: 'Plan', auto: true),
        AgentHandoff(command: 'df-test', label: 'Test'),
        AgentHandoff(command: 'df-verify', label: 'Verify', auto: true),
      ];

      const agent = AgentDefinition(
        id: 'dfspec',
        name: 'dfspec',
        description: 'Spec agent',
        content: 'Content',
        slashCommand: 'df-spec',
        handoffs: handoffs,
      );

      final autoHandoffs = agent.autoHandoffs;

      expect(autoHandoffs.length, equals(2));
      expect(autoHandoffs[0].command, equals('df-plan'));
      expect(autoHandoffs[1].command, equals('df-verify'));
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

      test('debe parsear agente con handoffs', () {
        const markdown = '''
---
name: dfspec
description: Especialista en especificaciones
model: opus
tools:
  - Read
  - Write
handoffs:
  - command: df-plan
    label: Crear plan de implementacion
    description: Genera arquitectura y orden TDD
    auto: true
  - command: df-status
    label: Ver estado
---

# Content
''';

        final agent = parser.parse(markdown, 'dfspec');

        expect(agent.handoffs.length, equals(2));
        expect(agent.hasHandoffs, isTrue);

        final firstHandoff = agent.handoffs[0];
        expect(firstHandoff.command, equals('df-plan'));
        expect(firstHandoff.label, equals('Crear plan de implementacion'));
        expect(firstHandoff.description, equals('Genera arquitectura y orden TDD'));
        expect(firstHandoff.auto, isTrue);

        final secondHandoff = agent.handoffs[1];
        expect(secondHandoff.command, equals('df-status'));
        expect(secondHandoff.label, equals('Ver estado'));
        expect(secondHandoff.description, isNull);
        expect(secondHandoff.auto, isFalse);
      });

      test('debe manejar agente sin handoffs', () {
        const markdown = '''
---
name: dftest
description: Testing agent
model: opus
tools:
  - Read
---

# Content
''';

        final agent = parser.parse(markdown, 'dftest');

        expect(agent.handoffs, isEmpty);
        expect(agent.hasHandoffs, isFalse);
      });
    });

    group('mapAgentNameToSlashCommand', () {
      test('debe mapear nombres de agentes a comandos slash', () {
        expect(
          parser.mapAgentNameToSlashCommand('dfplanner'),
          equals('df-plan'),
        );
        expect(
          parser.mapAgentNameToSlashCommand('dfimplementer'),
          equals('df-implement'),
        );
        expect(parser.mapAgentNameToSlashCommand('dftest'), equals('df-test'));
        expect(
          parser.mapAgentNameToSlashCommand('dfsolid'),
          equals('df-review'),
        );
        expect(
          parser.mapAgentNameToSlashCommand('dfsecurity'),
          equals('df-security'),
        );
        expect(
          parser.mapAgentNameToSlashCommand('dfperformance'),
          equals('df-performance'),
        );
        expect(
          parser.mapAgentNameToSlashCommand('dfdocumentation'),
          equals('df-docs'),
        );
        expect(
          parser.mapAgentNameToSlashCommand('dfcodequality'),
          equals('df-quality'),
        );
        expect(
          parser.mapAgentNameToSlashCommand('dfdependencies'),
          equals('df-deps'),
        );
        expect(
          parser.mapAgentNameToSlashCommand('dforchestrator'),
          equals('df-orchestrate'),
        );
        expect(
          parser.mapAgentNameToSlashCommand('dfverifier'),
          equals('df-verify'),
        );
        expect(parser.mapAgentNameToSlashCommand('dfspec'), equals('df-spec'));
        expect(
          parser.mapAgentNameToSlashCommand('dfstatus'),
          equals('df-status'),
        );
      });

      test('debe manejar nombres desconocidos con prefijo df-', () {
        expect(
          parser.mapAgentNameToSlashCommand('dfcustom'),
          equals('df-custom'),
        );
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
