import 'package:dfspec/dfspec.dart';
import 'package:test/test.dart';

void main() {
  group('DfspecConfig', () {
    test('crea instancia con valores por defecto', () {
      const config = DfspecConfig(projectName: 'test-project');

      expect(config.projectName, equals('test-project'));
      expect(config.specDir, equals('specs'));
      expect(config.outputDir, equals('.claude/commands'));
      expect(config.templateDir, equals('templates'));
      expect(config.agents, isEmpty);
    });

    test('crea instancia desde YAML', () {
      final yaml = <dynamic, dynamic>{
        'project_name': 'mi-proyecto',
        'spec_dir': 'especificaciones',
        'output_dir': '.claude/cmds',
        'template_dir': 'plantillas',
        'agents': ['dfplanner', 'dftest'],
      };

      final config = DfspecConfig.fromYaml(yaml);

      expect(config.projectName, equals('mi-proyecto'));
      expect(config.specDir, equals('especificaciones'));
      expect(config.outputDir, equals('.claude/cmds'));
      expect(config.templateDir, equals('plantillas'));
      expect(config.agents, equals(['dfplanner', 'dftest']));
    });

    test('usa valores por defecto para campos faltantes en YAML', () {
      final yaml = <dynamic, dynamic>{
        'project_name': 'proyecto',
      };

      final config = DfspecConfig.fromYaml(yaml);

      expect(config.projectName, equals('proyecto'));
      expect(config.specDir, equals('specs'));
      expect(config.outputDir, equals('.claude/commands'));
    });

    test('defaults() incluye todos los agentes', () {
      final config = DfspecConfig.defaults('mi-proyecto');

      expect(config.projectName, equals('mi-proyecto'));
      expect(config.agents, equals(DfspecConfig.defaultAgents));
      expect(config.agents, contains('dforchestrator'));
      expect(config.agents, contains('dftest'));
    });

    test('toYaml() genera formato correcto', () {
      final config = DfspecConfig.defaults('test');
      final yaml = config.toYaml();

      expect(yaml, contains('project_name: test'));
      expect(yaml, contains('spec_dir: specs'));
      expect(yaml, contains('output_dir: .claude/commands'));
      expect(yaml, contains('agents:'));
      expect(yaml, contains('  - dforchestrator'));
    });

    test('defaultAgents tiene 11 agentes', () {
      expect(DfspecConfig.defaultAgents.length, equals(11));
    });
  });
}
