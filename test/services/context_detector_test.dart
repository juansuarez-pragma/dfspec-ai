import 'dart:convert';
import 'dart:io';

import 'package:dfspec/src/models/feature_context.dart';
import 'package:dfspec/src/services/context_detector.dart';
import 'package:test/test.dart';

void main() {
  group('ContextDetector', () {
    late Directory tempDir;
    late String scriptsPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('context_detector_test_');
      scriptsPath = '${tempDir.path}/scripts';
      await Directory(scriptsPath).create();
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    group('constructor', () {
      test('usa path por defecto cuando no se especifica', () {
        final detector = ContextDetector();
        expect(detector, isNotNull);
      });

      test('acepta scriptsPath personalizado', () {
        final detector = ContextDetector(scriptsPath: '/custom/path');
        expect(detector, isNotNull);
      });
    });

    group('_runScript', () {
      test('lanza excepción cuando script no existe', () async {
        final detector = ContextDetector(scriptsPath: scriptsPath);

        expect(
          () => detector.detectFullContext(),
          throwsA(
            isA<ContextDetectionException>()
                .having((e) => e.code, 'code', 'SCRIPT_NOT_FOUND'),
          ),
        );
      });

      test('lanza excepción cuando script falla con exit code no cero',
          () async {
        // Crear script que falla
        final scriptPath = '$scriptsPath/detect-context.sh';
        await File(scriptPath).writeAsString('''
#!/bin/bash
exit 1
''');
        await Process.run('chmod', ['+x', scriptPath]);

        final detector = ContextDetector(scriptsPath: scriptsPath);

        expect(
          () => detector.detectFullContext(),
          throwsA(isA<ContextDetectionException>()),
        );
      });

      test('parsea error JSON cuando script retorna status error', () async {
        final scriptPath = '$scriptsPath/detect-context.sh';
        await File(scriptPath).writeAsString('''
#!/bin/bash
echo '{"status": "error", "error": {"code": "TEST_ERROR", "message": "Test message"}}'
exit 1
''');
        await Process.run('chmod', ['+x', scriptPath]);

        final detector = ContextDetector(scriptsPath: scriptsPath);

        expect(
          () => detector.detectFullContext(),
          throwsA(
            isA<ContextDetectionException>()
                .having((e) => e.code, 'code', 'TEST_ERROR')
                .having((e) => e.message, 'message', 'Test message'),
          ),
        );
      });

      test('lanza excepción cuando output no es JSON válido', () async {
        final scriptPath = '$scriptsPath/detect-context.sh';
        await File(scriptPath).writeAsString('''
#!/bin/bash
echo 'not valid json'
''');
        await Process.run('chmod', ['+x', scriptPath]);

        final detector = ContextDetector(scriptsPath: scriptsPath);

        expect(
          () => detector.detectFullContext(),
          throwsA(
            isA<ContextDetectionException>()
                .having((e) => e.code, 'code', 'JSON_PARSE_ERROR'),
          ),
        );
      });
    });

    group('detectFullContext', () {
      test('retorna ProjectContext desde JSON válido', () async {
        final scriptPath = '$scriptsPath/detect-context.sh';
        final jsonResponse = jsonEncode({
          'status': 'success',
          'data': {
            'project': {
              'name': 'test-project',
              'type': 'dart_package',
              'root': '/path/to/project',
            },
            'git': {
              'is_git_repo': true,
              'current_branch': 'feature/001-test',
              'has_uncommitted_changes': false,
            },
            'feature': {
              'id': '001-test',
              'number': '001',
              'name': 'test',
              'status': 'specified',
              'branch_name': 'feature/001-test',
              'next_available_number': '002',
              'documents': {
                'spec': true,
                'plan': false,
                'tasks': false,
                'research': false,
                'checklist': false,
                'data_model': false,
              },
            },
            'quality': {
              'test_coverage': 85.5,
              'analysis_issues': 0,
            },
          },
        });

        await File(scriptPath).writeAsString('''
#!/bin/bash
echo '$jsonResponse'
''');
        await Process.run('chmod', ['+x', scriptPath]);

        final detector = ContextDetector(scriptsPath: scriptsPath);
        final context = await detector.detectFullContext();

        expect(context.project.name, equals('test-project'));
        expect(context.git.isGitRepo, isTrue);
        expect(context.git.currentBranch, equals('feature/001-test'));
        expect(context.feature.id, equals('001-test'));
        expect(context.nextFeatureNumber, equals('002'));
      });

      test('pasa featureOverride como argumento', () async {
        final scriptPath = '$scriptsPath/detect-context.sh';
        await File(scriptPath).writeAsString('''
#!/bin/bash
echo '{"status": "success", "data": {"project": {"name": "test"}, "git": {"is_git_repo": true, "current_branch": "main"}, "feature": {"next_available_number": "001"}, "quality": {}}}'
''');
        await Process.run('chmod', ['+x', scriptPath]);

        final detector = ContextDetector(scriptsPath: scriptsPath);
        final context =
            await detector.detectFullContext(featureOverride: '002-custom');

        expect(context, isNotNull);
      });
    });

    group('detectCurrentFeature', () {
      test('retorna FeatureContext desde ProjectContext', () async {
        final scriptPath = '$scriptsPath/detect-context.sh';
        final jsonResponse = jsonEncode({
          'status': 'success',
          'data': {
            'project': {'name': 'test'},
            'git': {'is_git_repo': true, 'current_branch': 'main'},
            'feature': {
              'id': '001-auth',
              'number': '001',
              'name': 'auth',
              'status': 'planned',
              'next_available_number': '002',
            },
            'quality': {},
          },
        });

        await File(scriptPath).writeAsString('''
#!/bin/bash
echo '$jsonResponse'
''');
        await Process.run('chmod', ['+x', scriptPath]);

        final detector = ContextDetector(scriptsPath: scriptsPath);
        final feature = await detector.detectCurrentFeature();

        expect(feature.id, equals('001-auth'));
        expect(feature.number, equals('001'));
        expect(feature.name, equals('auth'));
      });
    });

    group('checkPrerequisites', () {
      test('retorna resultado exitoso con paths', () async {
        final scriptPath = '$scriptsPath/check-prerequisites.sh';
        final jsonResponse = jsonEncode({
          'status': 'success',
          'data': {
            'feature_id': '001-test',
            'paths': {
              'feature_dir': 'specs/features/001-test',
              'spec': 'specs/features/001-test/spec.md',
              'plan': 'specs/plans/001-test.plan.md',
              'tasks': 'specs/features/001-test/tasks.md',
              'research': 'specs/features/001-test/research.md',
              'checklist': 'specs/features/001-test/checklist.md',
              'data_model': 'specs/features/001-test/data-model.md',
            },
            'available_docs': ['spec.md', 'plan.md'],
          },
        });

        await File(scriptPath).writeAsString('''
#!/bin/bash
echo '$jsonResponse'
''');
        await Process.run('chmod', ['+x', scriptPath]);

        final detector = ContextDetector(scriptsPath: scriptsPath);
        final result = await detector.checkPrerequisites();

        expect(result.passed, isTrue);
        expect(result.featureId, equals('001-test'));
        expect(result.paths.spec, contains('spec.md'));
        expect(result.availableDocuments, contains('spec.md'));
      });

      test('retorna resultado fallido cuando falta requisito', () async {
        final scriptPath = '$scriptsPath/check-prerequisites.sh';
        final jsonResponse = jsonEncode({
          'status': 'error',
          'error': {
            'code': 'MISSING_SPEC',
            'message': 'spec.md no encontrado',
          },
        });

        await File(scriptPath).writeAsString('''
#!/bin/bash
echo '$jsonResponse'
exit 1
''');
        await Process.run('chmod', ['+x', scriptPath]);

        final detector = ContextDetector(scriptsPath: scriptsPath);
        final result = await detector.checkPrerequisites(requireSpec: true);

        expect(result.passed, isFalse);
        expect(result.errorCode, equals('MISSING_SPEC'));
        expect(result.errorMessage, contains('spec.md'));
      });

      test('pasa flags correctamente', () async {
        final scriptPath = '$scriptsPath/check-prerequisites.sh';
        await File(scriptPath).writeAsString('''
#!/bin/bash
echo '{"status": "success", "data": {"feature_id": "", "paths": {}, "available_docs": []}}'
''');
        await Process.run('chmod', ['+x', scriptPath]);

        final detector = ContextDetector(scriptsPath: scriptsPath);
        final result = await detector.checkPrerequisites(
          requireSpec: true,
          requirePlan: true,
          requireTasks: true,
          featureOverride: '001-test',
        );

        expect(result, isNotNull);
      });
    });

    group('validateSpec', () {
      test('retorna resultado de validación exitoso', () async {
        final scriptPath = '$scriptsPath/validate-spec.sh';
        final jsonResponse = jsonEncode({
          'status': 'success',
          'data': {
            'feature_id': '001-test',
            'spec_path': 'specs/features/001-test/spec.md',
            'validation': {
              'passed': true,
              'score': 95,
              'findings': [
                {
                  'severity': 'INFO',
                  'code': 'SPEC001',
                  'message': 'Consider adding more details',
                  'line': 10,
                },
              ],
            },
          },
        });

        await File(scriptPath).writeAsString('''
#!/bin/bash
echo '$jsonResponse'
''');
        await Process.run('chmod', ['+x', scriptPath]);

        final detector = ContextDetector(scriptsPath: scriptsPath);
        final result = await detector.validateSpec();

        expect(result.passed, isTrue);
        expect(result.score, equals(95));
        expect(result.findings, hasLength(1));
        expect(result.findings.first.severity, equals(FindingSeverity.info));
      });

      test('retorna resultado con múltiples findings', () async {
        final scriptPath = '$scriptsPath/validate-spec.sh';
        final jsonResponse = jsonEncode({
          'status': 'success',
          'data': {
            'feature_id': '001-test',
            'spec_path': 'specs/features/001-test/spec.md',
            'validation': {
              'passed': false,
              'score': 60,
              'findings': [
                {
                  'severity': 'CRITICAL',
                  'code': 'SPEC_EMPTY',
                  'message': 'Spec is empty',
                  'line': 0,
                },
                {
                  'severity': 'WARNING',
                  'code': 'SPEC_TODO',
                  'message': 'Contains TODO',
                  'line': 5,
                },
                {
                  'severity': 'INFO',
                  'code': 'SPEC_STYLE',
                  'message': 'Consider style',
                  'line': 10,
                },
              ],
            },
          },
        });

        await File(scriptPath).writeAsString('''
#!/bin/bash
echo '$jsonResponse'
''');
        await Process.run('chmod', ['+x', scriptPath]);

        final detector = ContextDetector(scriptsPath: scriptsPath);
        final result = await detector.validateSpec();

        expect(result.passed, isFalse);
        expect(result.score, equals(60));
        expect(result.criticalCount, equals(1));
        expect(result.warningCount, equals(1));
        expect(result.infoCount, equals(1));
      });

      test('retorna resultado fallido cuando script falla', () async {
        final scriptPath = '$scriptsPath/validate-spec.sh';
        final jsonResponse = jsonEncode({
          'status': 'error',
          'error': {
            'code': 'SPEC_NOT_FOUND',
            'message': 'Spec file not found',
          },
        });

        await File(scriptPath).writeAsString('''
#!/bin/bash
echo '$jsonResponse'
exit 1
''');
        await Process.run('chmod', ['+x', scriptPath]);

        final detector = ContextDetector(scriptsPath: scriptsPath);
        final result = await detector.validateSpec(featureOverride: '999-none');

        expect(result.passed, isFalse);
        expect(result.score, equals(0));
        expect(result.findings, hasLength(1));
        expect(
          result.findings.first.severity,
          equals(FindingSeverity.critical),
        );
      });

      test('pasa flag strict correctamente', () async {
        final scriptPath = '$scriptsPath/validate-spec.sh';
        await File(scriptPath).writeAsString('''
#!/bin/bash
echo '{"status": "success", "data": {"validation": {"passed": true, "score": 100, "findings": []}}}'
''');
        await Process.run('chmod', ['+x', scriptPath]);

        final detector = ContextDetector(scriptsPath: scriptsPath);
        final result = await detector.validateSpec(strict: true);

        expect(result, isNotNull);
      });
    });

    group('getNextFeatureNumber', () {
      test('retorna siguiente número de feature', () async {
        final scriptPath = '$scriptsPath/detect-context.sh';
        final jsonResponse = jsonEncode({
          'status': 'success',
          'data': {
            'project': {'name': 'test'},
            'git': {'is_git_repo': true, 'current_branch': 'main'},
            'feature': {'next_available_number': '005'},
            'quality': {},
          },
        });

        await File(scriptPath).writeAsString('''
#!/bin/bash
echo '$jsonResponse'
''');
        await Process.run('chmod', ['+x', scriptPath]);

        final detector = ContextDetector(scriptsPath: scriptsPath);
        final nextNumber = await detector.getNextFeatureNumber();

        expect(nextNumber, equals('005'));
      });
    });

    group('isGitRepository', () {
      test('retorna true cuando es repo git', () async {
        final scriptPath = '$scriptsPath/detect-context.sh';
        final jsonResponse = jsonEncode({
          'status': 'success',
          'data': {
            'project': {'name': 'test'},
            'git': {'is_git_repo': true, 'current_branch': 'main'},
            'feature': {'next_available_number': '001'},
            'quality': {},
          },
        });

        await File(scriptPath).writeAsString('''
#!/bin/bash
echo '$jsonResponse'
''');
        await Process.run('chmod', ['+x', scriptPath]);

        final detector = ContextDetector(scriptsPath: scriptsPath);
        final isGit = await detector.isGitRepository();

        expect(isGit, isTrue);
      });

      test('retorna false cuando no es repo git', () async {
        final scriptPath = '$scriptsPath/detect-context.sh';
        final jsonResponse = jsonEncode({
          'status': 'success',
          'data': {
            'project': {'name': 'test'},
            'git': {'is_git_repo': false, 'current_branch': ''},
            'feature': {'next_available_number': '001'},
            'quality': {},
          },
        });

        await File(scriptPath).writeAsString('''
#!/bin/bash
echo '$jsonResponse'
''');
        await Process.run('chmod', ['+x', scriptPath]);

        final detector = ContextDetector(scriptsPath: scriptsPath);
        final isGit = await detector.isGitRepository();

        expect(isGit, isFalse);
      });
    });

    group('getCurrentBranch', () {
      test('retorna nombre del branch actual', () async {
        final scriptPath = '$scriptsPath/detect-context.sh';
        final jsonResponse = jsonEncode({
          'status': 'success',
          'data': {
            'project': {'name': 'test'},
            'git': {
              'is_git_repo': true,
              'current_branch': 'feature/001-auth',
            },
            'feature': {'next_available_number': '002'},
            'quality': {},
          },
        });

        await File(scriptPath).writeAsString('''
#!/bin/bash
echo '$jsonResponse'
''');
        await Process.run('chmod', ['+x', scriptPath]);

        final detector = ContextDetector(scriptsPath: scriptsPath);
        final branch = await detector.getCurrentBranch();

        expect(branch, equals('feature/001-auth'));
      });
    });
  });

  group('PrerequisitesResult', () {
    test('fromJson crea resultado correctamente', () {
      final json = {
        'data': {
          'feature_id': '001-test',
          'paths': {
            'feature_dir': 'specs/features/001-test',
            'spec': 'specs/features/001-test/spec.md',
            'plan': 'specs/plans/001-test.plan.md',
            'tasks': '',
            'research': '',
            'checklist': '',
            'data_model': '',
          },
          'available_docs': ['spec.md'],
        },
      };

      final result = PrerequisitesResult.fromJson(json, passed: true);

      expect(result.passed, isTrue);
      expect(result.featureId, equals('001-test'));
      expect(result.paths.spec, contains('spec.md'));
      expect(result.availableDocuments, equals(['spec.md']));
    });

    test('fromJson maneja JSON sin data wrapper', () {
      final json = <String, dynamic>{
        'feature_id': '001-test',
        'paths': <String, dynamic>{},
        'available_docs': <String>[],
      };

      final result = PrerequisitesResult.fromJson(json, passed: true);

      expect(result.featureId, equals('001-test'));
    });

    test('hasFeature retorna true cuando featureId no está vacío', () {
      const result = PrerequisitesResult(
        passed: true,
        featureId: '001-test',
        paths: FeaturePaths.empty(),
        availableDocuments: [],
      );

      expect(result.hasFeature, isTrue);
    });

    test('hasFeature retorna false cuando featureId está vacío', () {
      const result = PrerequisitesResult(
        passed: true,
        featureId: '',
        paths: FeaturePaths.empty(),
        availableDocuments: [],
      );

      expect(result.hasFeature, isFalse);
    });

    test('toJson serializa correctamente', () {
      const result = PrerequisitesResult(
        passed: false,
        featureId: '001-test',
        paths: FeaturePaths.empty(),
        availableDocuments: ['spec.md'],
        errorMessage: 'Test error',
        errorCode: 'TEST_CODE',
      );

      final json = result.toJson();

      expect(json['passed'], isFalse);
      expect(json['feature_id'], equals('001-test'));
      expect(json['error_message'], equals('Test error'));
      expect(json['error_code'], equals('TEST_CODE'));
    });
  });

  group('FindingSeverity', () {
    test('tiene todos los valores esperados', () {
      expect(FindingSeverity.values, hasLength(3));
      expect(
        FindingSeverity.values,
        containsAll([
          FindingSeverity.critical,
          FindingSeverity.warning,
          FindingSeverity.info,
        ]),
      );
    });
  });

  group('SpecFinding', () {
    test('fromJson parsea severidad CRITICAL', () {
      final json = {
        'severity': 'CRITICAL',
        'code': 'TEST',
        'message': 'Test',
        'line': 5,
      };

      final finding = SpecFinding.fromJson(json);

      expect(finding.severity, equals(FindingSeverity.critical));
    });

    test('fromJson parsea severidad WARNING', () {
      final json = {
        'severity': 'WARNING',
        'code': 'TEST',
        'message': 'Test',
        'line': 5,
      };

      final finding = SpecFinding.fromJson(json);

      expect(finding.severity, equals(FindingSeverity.warning));
    });

    test('fromJson usa INFO como default', () {
      final json = {
        'severity': 'UNKNOWN',
        'code': 'TEST',
        'message': 'Test',
        'line': 5,
      };

      final finding = SpecFinding.fromJson(json);

      expect(finding.severity, equals(FindingSeverity.info));
    });

    test('fromJson maneja valores faltantes', () {
      final json = <String, dynamic>{};

      final finding = SpecFinding.fromJson(json);

      expect(finding.severity, equals(FindingSeverity.info));
      expect(finding.code, isEmpty);
      expect(finding.message, isEmpty);
      expect(finding.line, equals(0));
    });

    test('toJson serializa correctamente', () {
      const finding = SpecFinding(
        severity: FindingSeverity.warning,
        code: 'TEST_CODE',
        message: 'Test message',
        line: 42,
      );

      final json = finding.toJson();

      expect(json['severity'], equals('WARNING'));
      expect(json['code'], equals('TEST_CODE'));
      expect(json['message'], equals('Test message'));
      expect(json['line'], equals(42));
    });
  });

  group('SpecValidationResult', () {
    test('fromJson crea resultado correctamente', () {
      final json = {
        'data': {
          'feature_id': '001-test',
          'spec_path': 'specs/features/001-test/spec.md',
          'validation': {
            'passed': true,
            'score': 90,
            'findings': [
              {
                'severity': 'INFO',
                'code': 'TEST',
                'message': 'Test',
                'line': 1,
              },
            ],
          },
        },
      };

      final result = SpecValidationResult.fromJson(json);

      expect(result.passed, isTrue);
      expect(result.score, equals(90));
      expect(result.featureId, equals('001-test'));
      expect(result.findings, hasLength(1));
    });

    test('fromJson maneja JSON sin data wrapper', () {
      final json = {
        'validation': {
          'passed': false,
          'score': 50,
          'findings': <Map<String, dynamic>>[],
        },
      };

      final result = SpecValidationResult.fromJson(json);

      expect(result.passed, isFalse);
      expect(result.score, equals(50));
    });

    test('criticalCount cuenta findings críticos', () {
      const result = SpecValidationResult(
        passed: false,
        score: 0,
        featureId: 'test',
        specPath: 'test.md',
        findings: [
          SpecFinding(
            severity: FindingSeverity.critical,
            code: 'C1',
            message: '',
            line: 0,
          ),
          SpecFinding(
            severity: FindingSeverity.critical,
            code: 'C2',
            message: '',
            line: 0,
          ),
          SpecFinding(
            severity: FindingSeverity.warning,
            code: 'W1',
            message: '',
            line: 0,
          ),
        ],
      );

      expect(result.criticalCount, equals(2));
      expect(result.warningCount, equals(1));
      expect(result.infoCount, equals(0));
    });

    test('toJson serializa correctamente', () {
      const result = SpecValidationResult(
        passed: true,
        score: 100,
        featureId: '001-test',
        specPath: 'test.md',
        findings: [],
      );

      final json = result.toJson();

      expect(json['passed'], isTrue);
      expect(json['score'], equals(100));
      expect(json['feature_id'], equals('001-test'));
      expect(json['counts']['critical'], equals(0));
    });
  });

  group('ContextDetectionException', () {
    test('crea excepción con message y code', () {
      const exception = ContextDetectionException('Test message', 'TEST_CODE');

      expect(exception.message, equals('Test message'));
      expect(exception.code, equals('TEST_CODE'));
    });

    test('toString incluye code y message', () {
      const exception = ContextDetectionException('Test message', 'TEST_CODE');

      expect(
        exception.toString(),
        equals('ContextDetectionException[TEST_CODE]: Test message'),
      );
    });
  });
}
