import 'dart:io';

import 'package:dfspec/src/loaders/agent_loader.dart';
import 'package:dfspec/src/models/agent_config.dart';
import 'package:dfspec/src/models/agent_registry.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('AgentRegistry', () {
    late AgentRegistry registry;
    late String testAgentsPath;

    setUp(() async {
      // Crear directorio temporal con agentes de prueba
      final tempDir = await Directory.systemTemp.createTemp('dfspec_registry_');
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

<responsibilities>
1. ANALIZAR requisitos
2. DISENAR arquitectura
3. GENERAR planes TDD
</responsibilities>

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

<responsibilities>
1. Crear tests unitarios
2. Crear tests de widgets
</responsibilities>

# Agente dftest
''');

      await File(p.join(testAgentsPath, 'dfdocumentation.md')).writeAsString('''
---
name: dfdocumentation
description: Generador de documentacion
model: haiku
tools:
  - Read
  - Write
---

# Agente dfdocumentation
''');

      registry = AgentRegistry(loader: AgentLoader(agentsPath: testAgentsPath));
    });

    tearDown(() async {
      final dir = Directory(testAgentsPath);
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });

    group('initialization', () {
      test('isInitialized debe ser false antes de initialize', () {
        expect(registry.isInitialized, isFalse);
      });

      test('isInitialized debe ser true despues de initialize', () {
        registry.initialize();
        expect(registry.isInitialized, isTrue);
      });

      test('debe lanzar error si se accede sin inicializar', () {
        expect(() => registry.all, throwsStateError);
        expect(() => registry.allIds, throwsStateError);
        expect(() => registry.getAgent('dfplanner'), throwsStateError);
      });
    });

    group('getAgent', () {
      setUp(() {
        registry.initialize();
      });

      test('debe retornar AgentConfig para agente existente', () {
        final agent = registry.getAgent('dfplanner');

        expect(agent, isNotNull);
        expect(agent!.id, equals('dfplanner'));
        expect(agent.name, equals('DF Planner'));
        expect(agent.slashCommand, equals('df-plan'));
      });

      test('debe retornar null para agente inexistente', () {
        final agent = registry.getAgent('nonexistent');
        expect(agent, isNull);
      });
    });

    group('getDefinition', () {
      setUp(() {
        registry.initialize();
      });

      test('debe retornar AgentDefinition con contenido completo', () {
        final definition = registry.getDefinition('dfplanner');

        expect(definition, isNotNull);
        expect(definition!.id, equals('dfplanner'));
        expect(definition.content, contains('Agente dfplanner'));
        expect(definition.model, equals('opus'));
      });
    });

    group('all', () {
      setUp(() {
        registry.initialize();
      });

      test('debe retornar todos los agentes', () {
        final agents = registry.all;

        expect(agents.length, equals(3));
        expect(
          agents.map((a) => a.id),
          containsAll(['dfplanner', 'dftest', 'dfdocumentation']),
        );
      });
    });

    group('allIds', () {
      setUp(() {
        registry.initialize();
      });

      test('debe retornar todos los IDs', () {
        final ids = registry.allIds;

        expect(ids.length, equals(3));
        expect(ids, containsAll(['dfplanner', 'dftest', 'dfdocumentation']));
      });
    });

    group('exists', () {
      setUp(() {
        registry.initialize();
      });

      test('debe retornar true para agente existente', () {
        expect(registry.exists('dfplanner'), isTrue);
      });

      test('debe retornar false para agente inexistente', () {
        expect(registry.exists('nonexistent'), isFalse);
      });
    });

    group('byCategory', () {
      setUp(() {
        registry.initialize();
      });

      test('debe filtrar por categoria orchestration', () {
        final agents = registry.byCategory(AgentCategory.orchestration);

        expect(agents.map((a) => a.id), contains('dfplanner'));
      });

      test('debe filtrar por categoria implementation', () {
        final agents = registry.byCategory(AgentCategory.implementation);

        expect(agents.map((a) => a.id), contains('dftest'));
      });

      test('debe filtrar por categoria documentation', () {
        final agents = registry.byCategory(AgentCategory.documentation);

        expect(agents.map((a) => a.id), contains('dfdocumentation'));
      });
    });

    group('withCapability', () {
      setUp(() {
        registry.initialize();
      });

      test('debe encontrar agentes con capacidad especifica', () {
        final agents = registry.withCapability('arquitectura');

        expect(agents, isNotEmpty);
        expect(agents.any((a) => a.id == 'dfplanner'), isTrue);
      });
    });

    group('direct load methods', () {
      test('loadAgent debe funcionar sin initialize', () {
        final agent = registry.loadAgent('dfplanner');

        expect(agent, isNotNull);
        expect(agent!.id, equals('dfplanner'));
      });

      test('loadDefinition debe funcionar sin initialize', () {
        final definition = registry.loadDefinition('dfplanner');

        expect(definition, isNotNull);
        expect(definition!.content, contains('Agente dfplanner'));
      });

      test('loadAll debe funcionar sin initialize', () {
        final agents = registry.loadAll();

        expect(agents.length, equals(3));
      });
    });

    group('invalidateCache', () {
      test('debe permitir recargar agentes', () {
        registry.initialize();
        expect(registry.isInitialized, isTrue);

        registry.invalidateCache();
        expect(registry.isInitialized, isFalse);

        registry.initialize();
        expect(registry.isInitialized, isTrue);
      });
    });
  });

  group('AgentRegistry con agentes reales', () {
    late AgentRegistry registry;

    setUp(() {
      final projectRoot = Directory.current.path;
      final agentsPath = p.join(projectRoot, 'agents');
      registry = AgentRegistry(loader: AgentLoader(agentsPath: agentsPath))
        ..initialize();
    });

    test('debe cargar todos los 17 agentes', () {
      expect(registry.allIds.length, greaterThanOrEqualTo(17));
    });

    test('debe tener agentes en todas las categorias', () {
      final orchestration = registry.byCategory(AgentCategory.orchestration);
      final implementation = registry.byCategory(AgentCategory.implementation);
      final quality = registry.byCategory(AgentCategory.quality);
      final documentation = registry.byCategory(AgentCategory.documentation);

      expect(orchestration, isNotEmpty);
      expect(implementation, isNotEmpty);
      expect(quality, isNotEmpty);
      expect(documentation, isNotEmpty);
    });

    test('dfplanner debe tener slash command df-plan', () {
      final agent = registry.getAgent('dfplanner');
      expect(agent!.slashCommand, equals('df-plan'));
    });

    test('dfimplementer debe tener slash command df-implement', () {
      final agent = registry.getAgent('dfimplementer');
      expect(agent!.slashCommand, equals('df-implement'));
    });

    test('dfspec debe tener slash command df-spec', () {
      final agent = registry.getAgent('dfspec');
      expect(agent!.slashCommand, equals('df-spec'));
    });

    test('dfstatus debe tener slash command df-status', () {
      final agent = registry.getAgent('dfstatus');
      expect(agent!.slashCommand, equals('df-status'));
    });

    test('todos los agentes tienen slash command', () {
      for (final agent in registry.all) {
        expect(agent.slashCommand, isNotEmpty);
        expect(agent.slashCommand, startsWith('df-'));
      }
    });

    test('todos los agentes tienen capacidades', () {
      for (final agent in registry.all) {
        expect(agent.capabilities, isNotEmpty);
      }
    });

    test('todos los agentes tienen herramientas', () {
      for (final agent in registry.all) {
        expect(agent.tools, isNotEmpty);
      }
    });
  });
}
