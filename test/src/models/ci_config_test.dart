import 'package:dfspec/src/models/ci_config.dart';
import 'package:test/test.dart';

void main() {
  group('CITrigger', () {
    test('debe tener ids correctos', () {
      expect(CITrigger.pullRequestMain.id, equals('pull_request_main'));
      expect(CITrigger.pushMain.id, equals('push_main'));
      expect(CITrigger.tagVersion.id, equals('tag_version'));
      expect(CITrigger.manual.id, equals('manual'));
    });

    test('debe tener labels correctos', () {
      expect(CITrigger.pullRequestMain.label, equals('PR a main'));
      expect(CITrigger.tagVersion.label, equals('Tag de versión'));
    });
  });

  group('CIStage', () {
    test('debe tener orden correcto', () {
      expect(CIStage.format.order, equals(1));
      expect(CIStage.analyze.order, equals(2));
      expect(CIStage.test.order, equals(3));
      expect(CIStage.coverage.order, equals(4));
      expect(CIStage.qualityGates.order, equals(5));
      expect(CIStage.build.order, equals(6));
      expect(CIStage.publish.order, equals(7));
    });
  });

  group('StageStatus', () {
    test('debe tener iconos correctos', () {
      expect(StageStatus.pending.icon, equals('⏳'));
      expect(StageStatus.running.icon, equals('🔄'));
      expect(StageStatus.passed.icon, equals('✅'));
      expect(StageStatus.failed.icon, equals('❌'));
      expect(StageStatus.skipped.icon, equals('⏭️'));
    });
  });

  group('StageResult', () {
    test('debe crear resultado con valores correctos', () {
      const result = StageResult(
        stage: CIStage.test,
        status: StageStatus.passed,
        message: 'All tests passed',
        duration: Duration(seconds: 30),
        artifacts: ['coverage.lcov'],
      );

      expect(result.stage, equals(CIStage.test));
      expect(result.status, equals(StageStatus.passed));
      expect(result.isSuccess, isTrue);
      expect(result.isFailed, isFalse);
      expect(result.artifacts, contains('coverage.lcov'));
    });

    test('debe identificar fallo correctamente', () {
      const result = StageResult(
        stage: CIStage.analyze,
        status: StageStatus.failed,
        message: 'Lint errors found',
      );

      expect(result.isSuccess, isFalse);
      expect(result.isFailed, isTrue);
    });

    test('debe serializar y deserializar', () {
      const original = StageResult(
        stage: CIStage.build,
        status: StageStatus.passed,
        message: 'Build completed',
        duration: Duration(minutes: 2),
        artifacts: ['dfspec-linux'],
        logs: ['Compiling...', 'Done'],
      );

      final json = original.toJson();
      final restored = StageResult.fromJson(json);

      expect(restored.stage, equals(original.stage));
      expect(restored.status, equals(original.status));
      expect(restored.message, equals(original.message));
      expect(restored.duration?.inMinutes, equals(2));
      expect(restored.artifacts, equals(original.artifacts));
    });
  });

  group('QualityGateConfig', () {
    test('debe tener valores constitucionales por defecto', () {
      const config = QualityGateConfig();

      expect(config.minCoverage, equals(85.0));
      expect(config.maxCyclomaticComplexity, equals(10));
      expect(config.maxCognitiveComplexity, equals(8));
      expect(config.maxLinesPerFile, equals(400));
      expect(config.requireDocumentation, isTrue);
      expect(config.requireCleanArchitecture, isTrue);
      expect(config.requireTddCorrespondence, isTrue);
      expect(config.requireImmutableEntities, isTrue);
    });

    test('configuracion estricta debe ser mas exigente', () {
      const strict = QualityGateConfig.strict;
      const normal = QualityGateConfig.constitutional;

      expect(strict.minCoverage, greaterThan(normal.minCoverage));
      expect(strict.maxCyclomaticComplexity,
          lessThan(normal.maxCyclomaticComplexity));
      expect(
          strict.maxLinesPerFile, lessThan(normal.maxLinesPerFile));
    });

    test('configuracion relajada debe ser menos exigente', () {
      const relaxed = QualityGateConfig.relaxed;
      const normal = QualityGateConfig.constitutional;

      expect(relaxed.minCoverage, lessThan(normal.minCoverage));
      expect(relaxed.maxCyclomaticComplexity,
          greaterThan(normal.maxCyclomaticComplexity));
      expect(relaxed.requireDocumentation, isFalse);
    });

    test('debe serializar y deserializar', () {
      const original = QualityGateConfig(
        minCoverage: 90,
        maxCyclomaticComplexity: 8,
        requireDocumentation: false,
      );

      final json = original.toJson();
      final restored = QualityGateConfig.fromJson(json);

      expect(restored.minCoverage, equals(90.0));
      expect(restored.maxCyclomaticComplexity, equals(8));
      expect(restored.requireDocumentation, isFalse);
    });
  });

  group('CIConfig', () {
    test('debe tener trigger PR a main por defecto', () {
      const config = CIConfig(name: 'Test CI');

      expect(config.triggers, contains(CITrigger.pullRequestMain));
      expect(config.triggers.length, equals(1));
    });

    test('debe incluir etapas basicas por defecto', () {
      const config = CIConfig(name: 'Test CI');

      expect(config.stages, contains(CIStage.format));
      expect(config.stages, contains(CIStage.analyze));
      expect(config.stages, contains(CIStage.test));
      expect(config.stages, contains(CIStage.coverage));
      expect(config.stages, contains(CIStage.qualityGates));
      expect(config.stages, contains(CIStage.build));
    });

    test('dfspecDefault debe ser multi-plataforma', () {
      const config = CIConfig.dfspecDefault;

      expect(config.platforms, contains('ubuntu-latest'));
      expect(config.platforms, contains('macos-latest'));
      expect(config.platforms, contains('windows-latest'));
      expect(config.dartVersions, contains('stable'));
    });

    test('debe serializar y deserializar', () {
      const original = CIConfig(
        name: 'My CI',
        triggers: [CITrigger.pullRequestMain, CITrigger.pushMain],
        dartVersions: ['stable', '3.0.0'],
        parallelJobs: false,
      );

      final json = original.toJson();
      final restored = CIConfig.fromJson(json);

      expect(restored.name, equals('My CI'));
      expect(restored.triggers.length, equals(2));
      expect(restored.platforms, equals(['ubuntu-latest']));
      expect(restored.dartVersions, equals(['stable', '3.0.0']));
      expect(restored.parallelJobs, isFalse);
    });

    group('generateGitHubWorkflow', () {
      test('debe generar workflow con trigger PR a main', () {
        const config = CIConfig(
          name: 'Test CI',
        );

        final workflow = config.generateGitHubWorkflow();

        expect(workflow, contains('name: Test CI'));
        expect(workflow, contains('pull_request:'));
        expect(workflow, contains('branches: [main]'));
      });

      test('debe generar workflow con trigger de tags', () {
        const config = CIConfig(
          name: 'Release CI',
          triggers: [CITrigger.tagVersion],
        );

        final workflow = config.generateGitHubWorkflow();

        expect(workflow, contains("- 'v*'"));
      });

      test('debe incluir cache cuando esta habilitado', () {
        const config = CIConfig(
          name: 'Test CI',
        );

        final workflow = config.generateGitHubWorkflow();

        expect(workflow, contains('Cache dependencies'));
        expect(workflow, contains('~/.pub-cache'));
      });

      test('debe incluir etapas configuradas', () {
        const config = CIConfig(
          name: 'Test CI',
          stages: [CIStage.format, CIStage.test],
        );

        final workflow = config.generateGitHubWorkflow();

        expect(workflow, contains('format:'));
        expect(workflow, contains('test:'));
        expect(workflow, contains('Verify formatting'));
        expect(workflow, contains('Run tests'));
      });

      test('debe generar workflow con workflow_dispatch para manual', () {
        const config = CIConfig(
          name: 'Manual CI',
          triggers: [CITrigger.manual],
        );

        final workflow = config.generateGitHubWorkflow();

        expect(workflow, contains('workflow_dispatch:'));
      });
    });
  });

  group('PipelineResult', () {
    test('debe calcular exito correctamente', () {
      const config = CIConfig(name: 'Test');
      final result = PipelineResult(
        config: config,
        results: const [
          StageResult(stage: CIStage.format, status: StageStatus.passed),
          StageResult(stage: CIStage.test, status: StageStatus.passed),
          StageResult(stage: CIStage.build, status: StageStatus.skipped),
        ],
        startTime: DateTime(2024, 1, 1, 10),
        endTime: DateTime(2024, 1, 1, 10, 5),
      );

      expect(result.isSuccess, isTrue);
      expect(result.isFailed, isFalse);
      expect(result.duration?.inMinutes, equals(5));
    });

    test('debe detectar fallo', () {
      const config = CIConfig(name: 'Test');
      final result = PipelineResult(
        config: config,
        results: const [
          StageResult(stage: CIStage.format, status: StageStatus.passed),
          StageResult(stage: CIStage.test, status: StageStatus.failed),
        ],
        startTime: DateTime(2024, 1, 1, 10),
      );

      expect(result.isSuccess, isFalse);
      expect(result.isFailed, isTrue);
    });

    test('debe generar resumen legible', () {
      const config = CIConfig(name: 'DFSpec CI');
      final result = PipelineResult(
        config: config,
        results: const [
          StageResult(
            stage: CIStage.format,
            status: StageStatus.passed,
            duration: Duration(seconds: 10),
          ),
          StageResult(
            stage: CIStage.test,
            status: StageStatus.passed,
            duration: Duration(minutes: 2),
          ),
        ],
        startTime: DateTime(2024, 1, 1, 10),
        endTime: DateTime(2024, 1, 1, 10, 3),
        commit: 'abc123def456',
        branch: 'feature/test',
        pullRequest: 42,
      );

      final summary = result.toSummary();

      expect(summary, contains('Pipeline: DFSpec CI'));
      expect(summary, contains('Exitoso'));
      expect(summary, contains('abc123d'));
      expect(summary, contains('feature/test'));
      expect(summary, contains('#42'));
      expect(summary, contains('Formato'));
      expect(summary, contains('Tests'));
    });

    test('debe serializar y deserializar', () {
      const config = CIConfig(name: 'Test');
      final original = PipelineResult(
        config: config,
        results: const [
          StageResult(stage: CIStage.format, status: StageStatus.passed),
        ],
        startTime: DateTime(2024, 1, 1, 10),
        endTime: DateTime(2024, 1, 1, 10, 5),
        commit: 'abc123',
        branch: 'main',
      );

      final json = original.toJson();
      final restored = PipelineResult.fromJson(json);

      expect(restored.config.name, equals('Test'));
      expect(restored.results.length, equals(1));
      expect(restored.commit, equals('abc123'));
      expect(restored.branch, equals('main'));
    });
  });
}
