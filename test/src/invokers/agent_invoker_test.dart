import 'dart:io';

import 'package:dfspec/src/invokers/agent_invoker.dart';
import 'package:dfspec/src/loaders/agent_loader.dart';
import 'package:dfspec/src/utils/exceptions.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('AgentInvoker', () {
    late AgentInvoker invoker;
    late String testAgentsPath;

    setUp(() async {
      // Crear directorio temporal con agentes de prueba
      final tempDir = await Directory.systemTemp.createTemp('dfspec_invoker_');
      testAgentsPath = tempDir.path;

      // Crear agente dfplanner de prueba
      await File(p.join(testAgentsPath, 'dfplanner.md')).writeAsString('''
---
name: dfplanner
description: Arquitecto de soluciones especializado en Flutter
model: opus
tools:
  - Read
  - Glob
  - WebSearch
---

# Agente dfplanner

<role>
Eres un arquitecto de software senior.
</role>

<responsibilities>
1. Investigar el codebase
2. Diseñar arquitectura
3. Generar planes TDD
</responsibilities>
''');

      // Crear agente dfstatus de prueba (usa haiku)
      await File(p.join(testAgentsPath, 'dfstatus.md')).writeAsString('''
---
name: dfstatus
description: Monitor de estado del proyecto
model: haiku
tools:
  - Read
  - Glob
---

# Agente dfstatus

Muestra el estado actual del proyecto.
''');

      // Crear agente sin modelo especificado
      await File(p.join(testAgentsPath, 'dftest.md')).writeAsString('''
---
name: dftest
description: Especialista en testing
tools:
  - Read
  - Write
---

# Agente dftest

Crea y ejecuta tests.
''');

      invoker = AgentInvoker(
        loader: AgentLoader(agentsPath: testAgentsPath),
      );
    });

    tearDown(() async {
      final dir = Directory(testAgentsPath);
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });

    group('createInvocation', () {
      test('debe crear invocacion con modelo correcto del agente', () {
        final invocation = invoker.createInvocation(
          agentId: 'dfplanner',
          task: 'Diseña sistema de favoritos',
        );

        expect(invocation.agentId, equals('dfplanner'));
        expect(invocation.model, equals('opus'));
        expect(invocation.tools, containsAll(['Read', 'Glob', 'WebSearch']));
      });

      test('debe usar modelo haiku para dfstatus', () {
        final invocation = invoker.createInvocation(
          agentId: 'dfstatus',
          task: 'Muestra estado del proyecto',
        );

        expect(invocation.model, equals('haiku'));
      });

      test('debe usar modelo default cuando agente no lo especifica', () {
        final invocation = invoker.createInvocation(
          agentId: 'dftest',
          task: 'Crea tests unitarios',
        );

        expect(invocation.model, equals('sonnet'));
      });

      test('debe permitir override de modelo', () {
        final invocation = invoker.createInvocation(
          agentId: 'dfplanner',
          task: 'Tarea simple',
          overrideModel: 'haiku',
        );

        expect(invocation.model, equals('haiku'));
      });

      test('debe incluir tarea en el prompt', () {
        final invocation = invoker.createInvocation(
          agentId: 'dfplanner',
          task: 'Diseña sistema de favoritos',
        );

        expect(invocation.prompt, contains('TAREA ASIGNADA'));
        expect(invocation.prompt, contains('Diseña sistema de favoritos'));
      });

      test('debe incluir contenido del agente en el prompt', () {
        final invocation = invoker.createInvocation(
          agentId: 'dfplanner',
          task: 'Cualquier tarea',
        );

        expect(invocation.prompt, contains('Agente dfplanner'));
        expect(invocation.prompt, contains('arquitecto de software senior'));
      });

      test('debe incluir contexto cuando se proporciona', () {
        final invocation = invoker.createInvocation(
          agentId: 'dfplanner',
          task: 'Diseña arquitectura',
          context: {
            'project': 'mi-app',
            'architecture': 'Clean Architecture',
          },
        );

        expect(invocation.prompt, contains('CONTEXTO'));
        expect(invocation.prompt, contains('project'));
        expect(invocation.prompt, contains('mi-app'));
        expect(invocation.prompt, contains('Clean Architecture'));
      });

      test('debe generar descripcion corta', () {
        final invocation = invoker.createInvocation(
          agentId: 'dfplanner',
          task: 'Diseña sistema de favoritos para productos del catalogo',
        );

        expect(invocation.description, startsWith('Planning:'));
        expect(invocation.description.length, lessThanOrEqualTo(80));
      });

      test('debe lanzar excepcion para agente inexistente', () {
        expect(
          () => invoker.createInvocation(
            agentId: 'agente_falso',
            task: 'Cualquier tarea',
          ),
          throwsA(isA<AgentNotFoundException>()),
        );
      });
    });

    group('toTaskToolParams', () {
      test('debe generar parametros validos para Task tool', () {
        final invocation = invoker.createInvocation(
          agentId: 'dfplanner',
          task: 'Diseña sistema',
        );

        final params = invocation.toTaskToolParams();

        expect(params['subagent_type'], equals('general-purpose'));
        expect(params['model'], equals('opus'));
        expect(params['description'], isNotEmpty);
        expect(params['prompt'], isNotEmpty);
      });
    });

    group('toInstructionText', () {
      test('debe generar instrucciones legibles', () {
        final invocation = invoker.createInvocation(
          agentId: 'dfplanner',
          task: 'Diseña sistema',
        );

        final text = invocation.toInstructionText();

        expect(text, contains('Invocar Agente: dfplanner'));
        expect(text, contains('Task'));
        expect(text, contains('model: "opus"'));
      });
    });

    group('createParallelInvocations', () {
      test('debe crear multiples invocaciones', () {
        final invocations = invoker.createParallelInvocations(
          agentIds: ['dfplanner', 'dfstatus'],
          task: 'Analiza el proyecto',
        );

        expect(invocations.length, equals(2));
        expect(invocations[0].agentId, equals('dfplanner'));
        expect(invocations[0].model, equals('opus'));
        expect(invocations[1].agentId, equals('dfstatus'));
        expect(invocations[1].model, equals('haiku'));
      });
    });

    group('createPipelineInvocations', () {
      test('debe crear invocaciones con informacion de pipeline', () {
        final invocations = invoker.createPipelineInvocations(
          agentIds: ['dfplanner', 'dftest'],
          initialTask: 'Implementa feature X',
        );

        expect(invocations.length, equals(2));

        // Primera invocacion
        expect(invocations[0].prompt, contains('paso 1 de 2'));
        expect(invocations[0].prompt, contains('dftest'));

        // Segunda invocacion
        expect(invocations[1].prompt, contains('paso 2 de 2'));
        expect(invocations[1].prompt, contains('último'));
      });
    });

    group('getRecommendedModel', () {
      test('debe retornar modelo del agente', () {
        expect(invoker.getRecommendedModel('dfplanner'), equals('opus'));
        expect(invoker.getRecommendedModel('dfstatus'), equals('haiku'));
      });

      test('debe retornar null para agente inexistente', () {
        expect(invoker.getRecommendedModel('fake'), isNull);
      });
    });

    group('listAgentsWithModels', () {
      test('debe listar todos los agentes con sus modelos', () {
        final agents = invoker.listAgentsWithModels();

        expect(agents['dfplanner'], equals('opus'));
        expect(agents['dfstatus'], equals('haiku'));
        expect(agents['dftest'], equals('sonnet')); // default
      });
    });

    group('invalidateCache', () {
      test('debe limpiar cache', () {
        // Cargar agente en cache
        invoker.createInvocation(agentId: 'dfplanner', task: 'test');

        // Invalidar cache
        invoker.invalidateCache();

        // Deberia recargar (no hay forma directa de verificar, pero no debe fallar)
        final invocation = invoker.createInvocation(
          agentId: 'dfplanner',
          task: 'test again',
        );

        expect(invocation.agentId, equals('dfplanner'));
      });
    });
  });

  group('AgentInvoker con agentes reales', () {
    late AgentInvoker invoker;

    setUp(() {
      final projectRoot = Directory.current.path;
      final agentsPath = p.join(projectRoot, 'agents');
      invoker = AgentInvoker(
        loader: AgentLoader(agentsPath: agentsPath),
      );
    });

    test('debe cargar dfplanner real con modelo opus', () {
      final invocation = invoker.createInvocation(
        agentId: 'dfplanner',
        task: 'Test con agente real',
      );

      expect(invocation.model, equals('opus'));
      expect(invocation.prompt, contains('Arquitecto'));
    });

    test('debe cargar dfstatus real con modelo haiku', () {
      final invocation = invoker.createInvocation(
        agentId: 'dfstatus',
        task: 'Test con agente real',
      );

      expect(invocation.model, equals('haiku'));
    });

    test('debe listar todos los 13 agentes con modelos', () {
      final agents = invoker.listAgentsWithModels();

      expect(agents.length, greaterThanOrEqualTo(13));
      expect(agents.keys, containsAll([
        'dfplanner',
        'dfimplementer',
        'dftest',
        'dfsolid',
        'dfsecurity',
        'dfperformance',
        'dfcodequality',
        'dfdocumentation',
        'dfdependencies',
        'dforchestrator',
        'dfverifier',
        'dfspec',
        'dfstatus',
      ]));
    });

    test('todos los agentes excepto dfstatus usan opus', () {
      final agents = invoker.listAgentsWithModels();

      for (final entry in agents.entries) {
        if (entry.key == 'dfstatus') {
          expect(entry.value, equals('haiku'),
              reason: 'dfstatus debe usar haiku');
        } else {
          expect(entry.value, equals('opus'),
              reason: '${entry.key} debe usar opus');
        }
      }
    });
  });
}
