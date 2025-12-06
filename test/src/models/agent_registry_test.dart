import 'package:dfspec/dfspec.dart';
import 'package:test/test.dart';

void main() {
  group('AgentRegistry', () {
    test('all retorna 11 agentes', () {
      expect(AgentRegistry.all.length, equals(11));
    });

    test('allIds retorna 11 IDs', () {
      expect(AgentRegistry.allIds.length, equals(11));
    });

    test('contiene todos los agentes df*', () {
      final ids = AgentRegistry.allIds;

      expect(ids, contains('dforchestrator'));
      expect(ids, contains('dfplanner'));
      expect(ids, contains('dfsolid'));
      expect(ids, contains('dfsecurity'));
      expect(ids, contains('dfdependencies'));
      expect(ids, contains('dfimplementer'));
      expect(ids, contains('dftest'));
      expect(ids, contains('dfcodequality'));
      expect(ids, contains('dfperformance'));
      expect(ids, contains('dfdocumentation'));
      expect(ids, contains('dfverifier'));
    });

    test('getAgent retorna agente correcto', () {
      final agent = AgentRegistry.getAgent('dftest');

      expect(agent, isNotNull);
      expect(agent!.id, equals('dftest'));
      expect(agent.name, equals('DF Test'));
    });

    test('getAgent retorna null para agente inexistente', () {
      expect(AgentRegistry.getAgent('invalido'), isNull);
    });

    test('exists verifica existencia de agentes', () {
      expect(AgentRegistry.exists('dftest'), isTrue);
      expect(AgentRegistry.exists('invalido'), isFalse);
    });

    test('byCategory filtra correctamente', () {
      final qualityAgents = AgentRegistry.byCategory(AgentCategory.quality);

      expect(qualityAgents.length, greaterThan(0));
      for (final agent in qualityAgents) {
        expect(agent.category, equals(AgentCategory.quality));
      }
    });

    test('withCapability encuentra agentes por capacidad', () {
      final tddAgents = AgentRegistry.withCapability('TDD');

      expect(tddAgents.length, greaterThan(0));
      expect(tddAgents.any((a) => a.id == 'dfimplementer'), isTrue);
    });

    test('todos los agentes tienen slash command', () {
      for (final agent in AgentRegistry.all) {
        expect(agent.slashCommand, isNotEmpty);
        expect(agent.slashCommand, startsWith('df-'));
      }
    });

    test('todos los agentes tienen capacidades', () {
      for (final agent in AgentRegistry.all) {
        expect(agent.capabilities, isNotEmpty);
      }
    });

    test('todos los agentes tienen herramientas', () {
      for (final agent in AgentRegistry.all) {
        expect(agent.tools, isNotEmpty);
      }
    });

    test('agentes tienen dependencias validas', () {
      for (final agent in AgentRegistry.all) {
        for (final dep in agent.dependsOn) {
          expect(
            AgentRegistry.exists(dep),
            isTrue,
            reason: '${agent.id} depende de $dep que no existe',
          );
        }
      }
    });
  });
}
