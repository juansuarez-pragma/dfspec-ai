import 'package:dfspec/src/models/feature_context.dart';
import 'package:dfspec/src/models/project_context.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectType', () {
    test('tiene todos los tipos de proyecto', () {
      expect(ProjectType.values, containsAll([
        ProjectType.flutterApp,
        ProjectType.dartPackage,
        ProjectType.dartCli,
        ProjectType.flutterPlugin,
        ProjectType.unknown,
      ]));
    });
  });

  group('GitContext', () {
    test('se crea con todos los campos', () {
      const git = GitContext(
        isGitRepo: true,
        currentBranch: 'main',
        gitRoot: '/path/to/repo',
        hasUncommittedChanges: false,
        remoteUrl: 'https://github.com/user/repo.git',
      );

      expect(git.isGitRepo, isTrue);
      expect(git.currentBranch, equals('main'));
      expect(git.gitRoot, equals('/path/to/repo'));
      expect(git.hasUncommittedChanges, isFalse);
    });

    test('empty crea contexto git vacío', () {
      const git = GitContext.empty();

      expect(git.isGitRepo, isFalse);
      expect(git.currentBranch, isEmpty);
      expect(git.gitRoot, isEmpty);
    });

    test('fromJson parsea JSON correctamente', () {
      final json = {
        'is_git_repo': true,
        'current_branch': 'feature-branch',
        'git_root': '/home/user/project',
        'has_uncommitted_changes': true,
        'remote_url': 'git@github.com:user/repo.git',
      };

      final git = GitContext.fromJson(json);

      expect(git.isGitRepo, isTrue);
      expect(git.currentBranch, equals('feature-branch'));
      expect(git.hasUncommittedChanges, isTrue);
    });

    test('toJson serializa correctamente', () {
      const git = GitContext(
        isGitRepo: true,
        currentBranch: 'main',
        gitRoot: '/path',
        hasUncommittedChanges: false,
        remoteUrl: '',
      );

      final json = git.toJson();

      expect(json['is_git_repo'], isTrue);
      expect(json['current_branch'], equals('main'));
    });

    test('soporta igualdad con Equatable', () {
      const git1 = GitContext(
        isGitRepo: true,
        currentBranch: 'main',
        gitRoot: '/path',
        hasUncommittedChanges: false,
        remoteUrl: '',
      );

      const git2 = GitContext(
        isGitRepo: true,
        currentBranch: 'main',
        gitRoot: '/path',
        hasUncommittedChanges: false,
        remoteUrl: '',
      );

      expect(git1, equals(git2));
    });
  });

  group('ProjectInfo', () {
    test('se crea con todos los campos', () {
      const project = ProjectInfo(
        name: 'my_app',
        type: ProjectType.flutterApp,
        stateManagement: 'riverpod',
        hasDfspecConfig: true,
        hasPubspec: true,
        hasConstitution: true,
        platforms: ['android', 'ios', 'web'],
      );

      expect(project.name, equals('my_app'));
      expect(project.type, equals(ProjectType.flutterApp));
      expect(project.stateManagement, equals('riverpod'));
      expect(project.platforms, hasLength(3));
    });

    test('empty crea proyecto vacío', () {
      const project = ProjectInfo.empty();

      expect(project.name, isEmpty);
      expect(project.type, equals(ProjectType.unknown));
      expect(project.hasDfspecConfig, isFalse);
    });

    test('fromJson parsea tipos de proyecto correctamente', () {
      final testCases = {
        'flutter_app': ProjectType.flutterApp,
        'dart_package': ProjectType.dartPackage,
        'dart_cli': ProjectType.dartCli,
        'flutter_plugin': ProjectType.flutterPlugin,
        'unknown_type': ProjectType.unknown,
      };

      for (final entry in testCases.entries) {
        final json = {
          'name': 'test',
          'type': entry.key,
          'has_dfspec_config': true,
          'has_pubspec': true,
          'has_constitution': false,
        };

        final project = ProjectInfo.fromJson(json);
        expect(project.type, equals(entry.value),
            reason: 'Failed for type: ${entry.key}');
      }
    });

    test('isConfigured es true cuando hay dfspec.yaml', () {
      const project = ProjectInfo(
        name: 'my_app',
        type: ProjectType.flutterApp,
        stateManagement: '',
        hasDfspecConfig: true,
        hasPubspec: true,
        hasConstitution: false,
        platforms: [],
      );

      expect(project.isConfigured, isTrue);
    });

    test('isFlutter es true para flutter_app y flutter_plugin', () {
      const flutterApp = ProjectInfo(
        name: 'app',
        type: ProjectType.flutterApp,
        stateManagement: '',
        hasDfspecConfig: false,
        hasPubspec: false,
        hasConstitution: false,
        platforms: [],
      );

      const flutterPlugin = ProjectInfo(
        name: 'plugin',
        type: ProjectType.flutterPlugin,
        stateManagement: '',
        hasDfspecConfig: false,
        hasPubspec: false,
        hasConstitution: false,
        platforms: [],
      );

      const dartPackage = ProjectInfo(
        name: 'package',
        type: ProjectType.dartPackage,
        stateManagement: '',
        hasDfspecConfig: false,
        hasPubspec: false,
        hasConstitution: false,
        platforms: [],
      );

      expect(flutterApp.isFlutter, isTrue);
      expect(flutterPlugin.isFlutter, isTrue);
      expect(dartPackage.isFlutter, isFalse);
    });

    test('isDartOnly es true para dart_package y dart_cli', () {
      const dartPackage = ProjectInfo(
        name: 'package',
        type: ProjectType.dartPackage,
        stateManagement: '',
        hasDfspecConfig: false,
        hasPubspec: false,
        hasConstitution: false,
        platforms: [],
      );

      const dartCli = ProjectInfo(
        name: 'cli',
        type: ProjectType.dartCli,
        stateManagement: '',
        hasDfspecConfig: false,
        hasPubspec: false,
        hasConstitution: false,
        platforms: [],
      );

      const flutterApp = ProjectInfo(
        name: 'app',
        type: ProjectType.flutterApp,
        stateManagement: '',
        hasDfspecConfig: false,
        hasPubspec: false,
        hasConstitution: false,
        platforms: [],
      );

      expect(dartPackage.isDartOnly, isTrue);
      expect(dartCli.isDartOnly, isTrue);
      expect(flutterApp.isDartOnly, isFalse);
    });

    test('toJson serializa correctamente', () {
      const project = ProjectInfo(
        name: 'my_app',
        type: ProjectType.flutterApp,
        stateManagement: 'bloc',
        hasDfspecConfig: true,
        hasPubspec: true,
        hasConstitution: false,
        platforms: ['android', 'ios'],
      );

      final json = project.toJson();

      expect(json['name'], equals('my_app'));
      expect(json['type'], equals('flutterApp'));
      expect(json['state_management'], equals('bloc'));
      expect(json['is_flutter'], isTrue);
      expect(json['is_dart_only'], isFalse);
    });
  });

  group('ProjectQualityMetrics', () {
    test('se crea con todos los campos', () {
      const metrics = ProjectQualityMetrics(
        hasTests: true,
        testFileCount: 50,
        hasLib: true,
        libFileCount: 30,
        hasRecoveryPoints: true,
        recoveryChainCount: 3,
      );

      expect(metrics.hasTests, isTrue);
      expect(metrics.testFileCount, equals(50));
      expect(metrics.libFileCount, equals(30));
    });

    test('empty crea métricas vacías', () {
      const metrics = ProjectQualityMetrics.empty();

      expect(metrics.hasTests, isFalse);
      expect(metrics.testFileCount, equals(0));
    });

    test('testRatio calcula correctamente', () {
      const metrics = ProjectQualityMetrics(
        hasTests: true,
        testFileCount: 50,
        hasLib: true,
        libFileCount: 25,
        hasRecoveryPoints: false,
        recoveryChainCount: 0,
      );

      expect(metrics.testRatio, equals(2.0));
    });

    test('testRatio es 0 cuando no hay archivos lib', () {
      const metrics = ProjectQualityMetrics(
        hasTests: true,
        testFileCount: 50,
        hasLib: false,
        libFileCount: 0,
        hasRecoveryPoints: false,
        recoveryChainCount: 0,
      );

      expect(metrics.testRatio, equals(0.0));
    });

    test('fromJson parsea correctamente', () {
      final json = {
        'has_tests': true,
        'test_file_count': 100,
        'has_lib': true,
        'lib_file_count': 50,
        'has_recovery_points': true,
        'recovery_chain_count': 5,
      };

      final metrics = ProjectQualityMetrics.fromJson(json);

      expect(metrics.hasTests, isTrue);
      expect(metrics.testFileCount, equals(100));
      expect(metrics.testRatio, equals(2.0));
    });

    test('toJson incluye testRatio calculado', () {
      const metrics = ProjectQualityMetrics(
        hasTests: true,
        testFileCount: 30,
        hasLib: true,
        libFileCount: 20,
        hasRecoveryPoints: false,
        recoveryChainCount: 0,
      );

      final json = metrics.toJson();

      expect(json['test_ratio'], equals(1.5));
    });
  });

  group('ProjectContext', () {
    test('se crea con todos los campos', () {
      const context = ProjectContext(
        project: ProjectInfo.empty(),
        git: GitContext.empty(),
        feature: FeatureContext.empty(),
        quality: ProjectQualityMetrics.empty(),
        nextFeatureNumber: '001',
      );

      expect(context.nextFeatureNumber, equals('001'));
    });

    test('empty crea contexto vacío', () {
      const context = ProjectContext.empty();

      expect(context.project.name, isEmpty);
      expect(context.git.isGitRepo, isFalse);
      expect(context.feature.hasFeature, isFalse);
      expect(context.nextFeatureNumber, equals('001'));
    });

    test('fromJson parsea JSON completo correctamente', () {
      final json = {
        'data': {
          'project': {
            'name': 'my_app',
            'type': 'flutter_app',
            'state_management': 'riverpod',
            'has_dfspec_config': true,
            'has_pubspec': true,
            'has_constitution': true,
          },
          'git': {
            'is_git_repo': true,
            'current_branch': '001-auth',
            'git_root': '/path/to/project',
            'has_uncommitted_changes': false,
            'remote_url': '',
          },
          'feature': {
            'id': '001-auth',
            'number': '001',
            'name': 'auth',
            'status': 'specified',
            'next_available_number': '002',
          },
          'documents': {
            'exists': {
              'spec': true,
              'plan': false,
              'tasks': false,
              'research': false,
              'checklist': false,
              'data_model': false,
            },
          },
          'quality': {
            'has_tests': true,
            'test_file_count': 50,
            'has_lib': true,
            'lib_file_count': 30,
            'has_recovery_points': false,
            'recovery_chain_count': 0,
          },
        },
      };

      final context = ProjectContext.fromJson(json);

      expect(context.project.name, equals('my_app'));
      expect(context.project.type, equals(ProjectType.flutterApp));
      expect(context.git.isGitRepo, isTrue);
      expect(context.git.currentBranch, equals('001-auth'));
      expect(context.feature.id, equals('001-auth'));
      expect(context.nextFeatureNumber, equals('002'));
    });

    test('hasProject es true cuando hay pubspec o dfspec', () {
      const contextWithPubspec = ProjectContext(
        project: ProjectInfo(
          name: 'app',
          type: ProjectType.flutterApp,
          stateManagement: '',
          hasDfspecConfig: false,
          hasPubspec: true,
          hasConstitution: false,
          platforms: [],
        ),
        git: GitContext.empty(),
        feature: FeatureContext.empty(),
        quality: ProjectQualityMetrics.empty(),
        nextFeatureNumber: '001',
      );

      const contextWithDfspec = ProjectContext(
        project: ProjectInfo(
          name: 'app',
          type: ProjectType.flutterApp,
          stateManagement: '',
          hasDfspecConfig: true,
          hasPubspec: false,
          hasConstitution: false,
          platforms: [],
        ),
        git: GitContext.empty(),
        feature: FeatureContext.empty(),
        quality: ProjectQualityMetrics.empty(),
        nextFeatureNumber: '001',
      );

      expect(contextWithPubspec.hasProject, isTrue);
      expect(contextWithDfspec.hasProject, isTrue);
    });

    test('needsInit es true cuando no hay dfspec.yaml', () {
      const context = ProjectContext(
        project: ProjectInfo(
          name: 'app',
          type: ProjectType.flutterApp,
          stateManagement: '',
          hasDfspecConfig: false,
          hasPubspec: true,
          hasConstitution: false,
          platforms: [],
        ),
        git: GitContext.empty(),
        feature: FeatureContext.empty(),
        quality: ProjectQualityMetrics.empty(),
        nextFeatureNumber: '001',
      );

      expect(context.needsInit, isTrue);
    });

    test('needsFeature es true cuando no hay feature activa', () {
      const context = ProjectContext(
        project: ProjectInfo.empty(),
        git: GitContext.empty(),
        feature: FeatureContext.empty(),
        quality: ProjectQualityMetrics.empty(),
        nextFeatureNumber: '001',
      );

      expect(context.needsFeature, isTrue);
    });

    test('statusMessage retorna mensaje apropiado', () {
      // Sin proyecto
      const noProject = ProjectContext.empty();
      expect(noProject.statusMessage, contains('dfspec init'));

      // Con proyecto pero sin dfspec
      const needsInit = ProjectContext(
        project: ProjectInfo(
          name: 'app',
          type: ProjectType.flutterApp,
          stateManagement: '',
          hasDfspecConfig: false,
          hasPubspec: true,
          hasConstitution: false,
          platforms: [],
        ),
        git: GitContext.empty(),
        feature: FeatureContext.empty(),
        quality: ProjectQualityMetrics.empty(),
        nextFeatureNumber: '001',
      );
      expect(needsInit.statusMessage, contains('dfspec init'));

      // Con dfspec pero sin feature
      const needsFeature = ProjectContext(
        project: ProjectInfo(
          name: 'app',
          type: ProjectType.flutterApp,
          stateManagement: '',
          hasDfspecConfig: true,
          hasPubspec: true,
          hasConstitution: false,
          platforms: [],
        ),
        git: GitContext.empty(),
        feature: FeatureContext.empty(),
        quality: ProjectQualityMetrics.empty(),
        nextFeatureNumber: '001',
      );
      expect(needsFeature.statusMessage, contains('/df-spec'));

      // Con feature activa
      const hasFeature = ProjectContext(
        project: ProjectInfo(
          name: 'app',
          type: ProjectType.flutterApp,
          stateManagement: '',
          hasDfspecConfig: true,
          hasPubspec: true,
          hasConstitution: false,
          platforms: [],
        ),
        git: GitContext.empty(),
        feature: FeatureContext(
          id: '001-auth',
          number: '001',
          name: 'auth',
          status: SddFeatureStatus.specified,
          branchName: '001-auth',
          paths: FeaturePaths.empty(),
          documents: FeatureDocuments.empty(),
        ),
        quality: ProjectQualityMetrics.empty(),
        nextFeatureNumber: '002',
      );
      expect(hasFeature.statusMessage, contains('001-auth'));
    });

    test('toJson serializa correctamente', () {
      const context = ProjectContext(
        project: ProjectInfo(
          name: 'my_app',
          type: ProjectType.flutterApp,
          stateManagement: 'riverpod',
          hasDfspecConfig: true,
          hasPubspec: true,
          hasConstitution: true,
          platforms: ['android', 'ios'],
        ),
        git: GitContext(
          isGitRepo: true,
          currentBranch: 'main',
          gitRoot: '/path',
          hasUncommittedChanges: false,
          remoteUrl: '',
        ),
        feature: FeatureContext.empty(),
        quality: ProjectQualityMetrics.empty(),
        nextFeatureNumber: '001',
      );

      final json = context.toJson();

      expect(json['project'], isA<Map>());
      expect(json['git'], isA<Map>());
      expect(json['feature'], isA<Map>());
      expect(json['quality'], isA<Map>());
      expect(json['next_feature_number'], equals('001'));
      expect(json['has_project'], isTrue);
      expect(json['needs_init'], isFalse);
      expect(json['needs_feature'], isTrue);
      expect(json['status_message'], isNotEmpty);
    });

    test('soporta igualdad con Equatable', () {
      const context1 = ProjectContext(
        project: ProjectInfo.empty(),
        git: GitContext.empty(),
        feature: FeatureContext.empty(),
        quality: ProjectQualityMetrics.empty(),
        nextFeatureNumber: '001',
      );

      const context2 = ProjectContext(
        project: ProjectInfo.empty(),
        git: GitContext.empty(),
        feature: FeatureContext.empty(),
        quality: ProjectQualityMetrics.empty(),
        nextFeatureNumber: '001',
      );

      expect(context1, equals(context2));
    });
  });
}
