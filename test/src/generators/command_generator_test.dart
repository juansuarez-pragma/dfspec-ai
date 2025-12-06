import 'package:dfspec/src/generators/command_generator.dart';
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
      expect(
        template.content,
        equals('# Agente dfplanner\n\nContenido completo.'),
      );
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

    test('fromAgent debe incluir handoffs', () {
      const handoffs = [
        AgentHandoff(command: 'df-plan', label: 'Crear plan', auto: true),
        AgentHandoff(command: 'df-test', label: 'Ejecutar tests'),
      ];

      const agent = AgentDefinition(
        id: 'dfspec',
        name: 'dfspec',
        description: 'Crea especificaciones',
        content: '# Agente dfspec',
        slashCommand: 'df-spec',
        handoffs: handoffs,
      );

      final template = CommandTemplate.fromAgent(agent);

      expect(template.handoffs.length, equals(2));
      expect(template.hasHandoffs, isTrue);
      expect(template.handoffs[0].command, equals('df-plan'));
      expect(template.handoffs[1].command, equals('df-test'));
    });

    test('hasHandoffs debe retornar false si no hay handoffs', () {
      const template = CommandTemplate(
        name: 'df-test',
        description: 'Test',
        tools: [],
        content: 'Contenido',
      );

      expect(template.hasHandoffs, isFalse);
    });
  });

  group('ClaudeCommandGenerator', () {
    late ClaudeCommandGenerator generator;

    setUp(() {
      generator = const ClaudeCommandGenerator();
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
      expect(
        output,
        contains('description: Crea especificaciones de features'),
      );
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

    test('debe generar frontmatter YAML valido', () {
      const template = CommandTemplate(
        name: 'df-plan',
        description: 'Genera plan de implementacion',
        tools: ['Read', 'Glob', 'WebSearch'],
        content: '# Agente dfplanner',
      );

      final output = generator.generate(template);

      // Verificar estructura del frontmatter
      expect(output, startsWith('---\n'));
      expect(output.indexOf('---'), equals(0));
      // Segundo --- debe existir despues del primero
      expect(output.indexOf('---', 4), greaterThan(0));
    });

    test('debe separar frontmatter del contenido con linea vacia', () {
      const template = CommandTemplate(
        name: 'test',
        description: 'Test',
        tools: ['Read'],
        content: 'Contenido',
      );

      final output = generator.generate(template);

      // El frontmatter termina con --- y luego hay una linea vacia
      expect(output, contains('---\n\n'));
    });

    test('debe manejar descripcion con caracteres especiales', () {
      const template = CommandTemplate(
        name: 'test',
        description: 'Descripcion: con dos puntos y "comillas"',
        tools: [],
        content: 'Contenido',
      );

      final output = generator.generate(template);

      expect(
        output,
        contains('description: Descripcion: con dos puntos y "comillas"'),
      );
    });

    test('debe incluir seccion de handoffs cuando existen', () {
      const handoffs = [
        AgentHandoff(
          command: 'df-plan',
          label: 'Crear plan',
          description: 'Genera arquitectura',
          auto: true,
        ),
        AgentHandoff(
          command: 'df-test',
          label: 'Ejecutar tests',
        ),
      ];

      const template = CommandTemplate(
        name: 'df-spec',
        description: 'Crea especificaciones',
        tools: ['Read', 'Write'],
        content: '# Contenido',
        handoffs: handoffs,
      );

      final output = generator.generate(template);

      expect(output, contains('## Siguientes Pasos Sugeridos'));
      expect(output, contains('Al completar esta tarea, considera ejecutar:'));
      expect(output, contains('**[AUTO]** `/df-plan`: Crear plan'));
      expect(output, contains('Genera arquitectura'));
      expect(output, contains('`/df-test`: Ejecutar tests'));
    });

    test('no debe incluir seccion de handoffs si no hay', () {
      const template = CommandTemplate(
        name: 'df-test',
        description: 'Test',
        tools: ['Read'],
        content: '# Contenido',
      );

      final output = generator.generate(template);

      expect(output, isNot(contains('## Siguientes Pasos Sugeridos')));
    });

    test('debe formatear handoff sin descripcion', () {
      const handoffs = [
        AgentHandoff(
          command: 'df-status',
          label: 'Ver estado',
        ),
      ];

      const template = CommandTemplate(
        name: 'df-spec',
        description: 'Spec',
        tools: [],
        content: '# Content',
        handoffs: handoffs,
      );

      final output = generator.generate(template);

      expect(output, contains('`/df-status`: Ver estado'));
      // No debe tener el " - " seguido de descripcion
      expect(output, isNot(contains('Ver estado - ')));
    });

    test('debe marcar handoffs automaticos con [AUTO]', () {
      const handoffs = [
        AgentHandoff(command: 'df-plan', label: 'Plan', auto: true),
        AgentHandoff(command: 'df-test', label: 'Test'),
      ];

      const template = CommandTemplate(
        name: 'df-spec',
        description: 'Spec',
        tools: [],
        content: '# Content',
        handoffs: handoffs,
      );

      final output = generator.generate(template);

      expect(output, contains('**[AUTO]** `/df-plan`'));
      expect(output, isNot(contains('**[AUTO]** `/df-test`')));
    });
  });
}
