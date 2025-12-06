import 'package:dfspec/dfspec.dart';
import 'package:test/test.dart';

void main() {
  group('AgentCategory', () {
    test('tiene 4 categorias', () {
      expect(AgentCategory.values.length, equals(4));
    });

    test('cada categoria tiene displayName y description', () {
      for (final cat in AgentCategory.values) {
        expect(cat.displayName, isNotEmpty);
        expect(cat.description, isNotEmpty);
      }
    });
  });

  group('AgentConfig', () {
    const testAgent = AgentConfig(
      id: 'test-agent',
      name: 'Test Agent',
      description: 'Un agente de prueba',
      category: AgentCategory.implementation,
      capabilities: ['Testing', 'TDD', 'Unit Tests'],
      slashCommand: 'test-cmd',
      dependsOn: ['other-agent'],
      tools: ['Read', 'Write'],
    );

    test('almacena propiedades correctamente', () {
      expect(testAgent.id, equals('test-agent'));
      expect(testAgent.name, equals('Test Agent'));
      expect(testAgent.category, equals(AgentCategory.implementation));
      expect(testAgent.slashCommand, equals('test-cmd'));
    });

    test('hasCapability encuentra capacidades', () {
      expect(testAgent.hasCapability('testing'), isTrue);
      expect(testAgent.hasCapability('TDD'), isTrue);
      expect(testAgent.hasCapability('unit'), isTrue);
    });

    test('hasCapability es case-insensitive', () {
      expect(testAgent.hasCapability('TESTING'), isTrue);
      expect(testAgent.hasCapability('tdd'), isTrue);
    });

    test('hasCapability retorna false para capacidades inexistentes', () {
      expect(testAgent.hasCapability('security'), isFalse);
    });

    test('toJson serializa correctamente', () {
      final json = testAgent.toJson();

      expect(json['id'], equals('test-agent'));
      expect(json['name'], equals('Test Agent'));
      expect(json['category'], equals('implementation'));
      expect(json['capabilities'], contains('Testing'));
      expect(json['dependsOn'], contains('other-agent'));
      expect(json['tools'], contains('Read'));
    });

    test('toString retorna formato esperado', () {
      expect(testAgent.toString(), equals('AgentConfig(test-agent)'));
    });
  });
}
