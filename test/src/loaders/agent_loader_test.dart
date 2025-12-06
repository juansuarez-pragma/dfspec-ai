import 'dart:io';

import 'package:dfspec/src/loaders/agent_loader.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('AgentLoader', () {
    late AgentLoader loader;
    late String testAgentsPath;

    setUp(() async {
      // Crear directorio temporal con agentes de prueba
      final tempDir = await Directory.systemTemp.createTemp('dfspec_test_');
      testAgentsPath = tempDir.path;

      // Crear agentes de prueba
      await File(p.join(testAgentsPath, 'dfplanner.md')).writeAsString('''
---
name: dfplanner
description: Arquitecto de soluciones
model: opus
tools:
  - Read
  - Glob
---

# Agente dfplanner
Contenido del agente.
''');

      await File(p.join(testAgentsPath, 'dftest.md')).writeAsString('''
---
name: dftest
description: Especialista en testing
model: sonnet
tools:
  - Read
  - Write
---

# Agente dftest
''');

      loader = AgentLoader(agentsPath: testAgentsPath);
    });

    tearDown(() async {
      // Limpiar directorio temporal
      final dir = Directory(testAgentsPath);
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });

    group('listAvailable', () {
      test('debe listar agentes disponibles', () {
        final agents = loader.listAvailable();

        expect(agents, containsAll(['dfplanner', 'dftest']));
        expect(agents.length, equals(2));
      });

      test('debe retornar lista vacia si no hay agentes', () async {
        final emptyDir = await Directory.systemTemp.createTemp('empty_');
        final emptyLoader = AgentLoader(agentsPath: emptyDir.path);

        final agents = emptyLoader.listAvailable();

        expect(agents, isEmpty);

        await emptyDir.delete();
      });
    });

    group('load', () {
      test('debe cargar un agente existente', () {
        final agent = loader.load('dfplanner');

        expect(agent, isNotNull);
        expect(agent!.id, equals('dfplanner'));
        expect(agent.name, equals('dfplanner'));
        expect(agent.description, equals('Arquitecto de soluciones'));
        expect(agent.model, equals('opus'));
        expect(agent.tools, containsAll(['Read', 'Glob']));
        expect(agent.slashCommand, equals('df-plan'));
      });

      test('debe retornar null para agente inexistente', () {
        final agent = loader.load('nonexistent');

        expect(agent, isNull);
      });

      test('debe manejar nombre con o sin extension .md', () {
        final agent1 = loader.load('dfplanner');
        final agent2 = loader.load('dfplanner.md');

        expect(agent1, isNotNull);
        expect(agent2, isNotNull);
        expect(agent1!.id, equals(agent2!.id));
      });
    });

    group('loadAll', () {
      test('debe cargar todos los agentes', () {
        final agents = loader.loadAll();

        expect(agents.length, equals(2));
        expect(agents.map((a) => a.id), containsAll(['dfplanner', 'dftest']));
      });

      test('debe retornar lista vacia si directorio no existe', () {
        final invalidLoader = AgentLoader(agentsPath: '/nonexistent/path');

        final agents = invalidLoader.loadAll();

        expect(agents, isEmpty);
      });
    });

    group('exists', () {
      test('debe retornar true para agente existente', () {
        expect(loader.exists('dfplanner'), isTrue);
        expect(loader.exists('dftest'), isTrue);
      });

      test('debe retornar false para agente inexistente', () {
        expect(loader.exists('nonexistent'), isFalse);
      });
    });

    group('getAgentPath', () {
      test('debe retornar path correcto', () {
        final path = loader.getAgentPath('dfplanner');

        expect(path, equals(p.join(testAgentsPath, 'dfplanner.md')));
      });
    });
  });

  group('AgentLoader con agentes reales', () {
    late AgentLoader loader;

    setUp(() {
      // Usar el directorio real de agentes del proyecto
      final projectRoot = Directory.current.path;
      final agentsPath = p.join(projectRoot, 'agents');
      loader = AgentLoader(agentsPath: agentsPath);
    });

    test('debe cargar dfplanner.md real', () {
      final agent = loader.load('dfplanner');

      expect(agent, isNotNull);
      expect(agent!.name, equals('dfplanner'));
      expect(agent.slashCommand, equals('df-plan'));
      expect(agent.tools, isNotEmpty);
      expect(agent.content, contains('Arquitecto'));
    });

    test('debe cargar dfimplementer.md real', () {
      final agent = loader.load('dfimplementer');

      expect(agent, isNotNull);
      expect(agent!.name, equals('dfimplementer'));
      expect(agent.slashCommand, equals('df-implement'));
      expect(agent.tools, contains('Read'));
      expect(agent.tools, contains('Write'));
    });

    test('debe cargar todos los 13 agentes reales', () {
      final agents = loader.loadAll();

      expect(agents.length, greaterThanOrEqualTo(13));

      final agentIds = agents.map((a) => a.id).toList();
      expect(
        agentIds,
        containsAll([
          'dfplanner',
          'dfimplementer',
          'dftest',
          'dfsolid',
          'dfsecurity',
          'dfperformance',
          'dfdocumentation',
          'dfcodequality',
          'dfdependencies',
          'dforchestrator',
          'dfverifier',
          'dfspec',
          'dfstatus',
        ]),
      );
    });
  });
}
