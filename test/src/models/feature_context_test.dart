import 'package:dfspec/src/models/feature_context.dart';
import 'package:test/test.dart';

void main() {
  group('SddFeatureStatus', () {
    test('tiene todos los estados del flujo SDD', () {
      expect(SddFeatureStatus.values, containsAll([
        SddFeatureStatus.none,
        SddFeatureStatus.specified,
        SddFeatureStatus.planned,
        SddFeatureStatus.readyToImplement,
        SddFeatureStatus.implementing,
        SddFeatureStatus.implemented,
        SddFeatureStatus.verified,
      ]));
    });
  });

  group('FeaturePaths', () {
    test('se crea con todos los campos requeridos', () {
      const paths = FeaturePaths(
        featureDir: 'specs/features/001-auth',
        spec: 'specs/features/001-auth/spec.md',
        plan: 'specs/plans/001-auth.plan.md',
        tasks: 'specs/features/001-auth/tasks.md',
        research: 'specs/features/001-auth/research.md',
        checklist: 'specs/features/001-auth/checklist.md',
        dataModel: 'specs/features/001-auth/data-model.md',
      );

      expect(paths.featureDir, equals('specs/features/001-auth'));
      expect(paths.spec, contains('spec.md'));
      expect(paths.plan, contains('plan.md'));
    });

    test('empty crea paths vacíos', () {
      const paths = FeaturePaths.empty();

      expect(paths.featureDir, isEmpty);
      expect(paths.spec, isEmpty);
      expect(paths.plan, isEmpty);
    });

    test('fromFeatureId genera paths correctos', () {
      final paths = FeaturePaths.fromFeatureId('001-auth');

      expect(paths.featureDir, equals('specs/features/001-auth'));
      expect(paths.spec, equals('specs/features/001-auth/spec.md'));
      expect(paths.plan, equals('specs/plans/001-auth.plan.md'));
      expect(paths.tasks, equals('specs/features/001-auth/tasks.md'));
    });

    test('toJson serializa correctamente', () {
      final paths = FeaturePaths.fromFeatureId('001-auth');
      final json = paths.toJson();

      expect(json['feature_dir'], equals('specs/features/001-auth'));
      expect(json['spec'], equals('specs/features/001-auth/spec.md'));
      expect(json['plan'], equals('specs/plans/001-auth.plan.md'));
    });

    test('soporta igualdad con Equatable', () {
      final paths1 = FeaturePaths.fromFeatureId('001-auth');
      final paths2 = FeaturePaths.fromFeatureId('001-auth');
      final paths3 = FeaturePaths.fromFeatureId('002-other');

      expect(paths1, equals(paths2));
      expect(paths1, isNot(equals(paths3)));
    });
  });

  group('FeatureDocuments', () {
    test('se crea con todos los flags', () {
      const docs = FeatureDocuments(
        specExists: true,
        planExists: true,
        tasksExists: false,
        researchExists: false,
        checklistExists: false,
        dataModelExists: false,
      );

      expect(docs.specExists, isTrue);
      expect(docs.planExists, isTrue);
      expect(docs.tasksExists, isFalse);
    });

    test('empty crea documentos vacíos', () {
      const docs = FeatureDocuments.empty();

      expect(docs.specExists, isFalse);
      expect(docs.planExists, isFalse);
      expect(docs.tasksExists, isFalse);
    });

    test('availableDocuments retorna lista de existentes', () {
      const docs = FeatureDocuments(
        specExists: true,
        planExists: true,
        tasksExists: false,
        researchExists: true,
        checklistExists: false,
        dataModelExists: false,
      );

      final available = docs.availableDocuments;

      expect(available, containsAll(['spec.md', 'plan.md', 'research.md']));
      expect(available, isNot(contains('tasks.md')));
    });

    test('inferredStatus retorna estado correcto', () {
      // Sin spec -> none
      expect(
        const FeatureDocuments.empty().inferredStatus,
        equals(SddFeatureStatus.none),
      );

      // Solo spec -> specified
      expect(
        const FeatureDocuments(
          specExists: true,
          planExists: false,
          tasksExists: false,
          researchExists: false,
          checklistExists: false,
          dataModelExists: false,
        ).inferredStatus,
        equals(SddFeatureStatus.specified),
      );

      // Spec + plan -> planned
      expect(
        const FeatureDocuments(
          specExists: true,
          planExists: true,
          tasksExists: false,
          researchExists: false,
          checklistExists: false,
          dataModelExists: false,
        ).inferredStatus,
        equals(SddFeatureStatus.planned),
      );

      // Spec + plan + tasks -> readyToImplement
      expect(
        const FeatureDocuments(
          specExists: true,
          planExists: true,
          tasksExists: true,
          researchExists: false,
          checklistExists: false,
          dataModelExists: false,
        ).inferredStatus,
        equals(SddFeatureStatus.readyToImplement),
      );
    });
  });

  group('FeatureContext', () {
    test('se crea con todos los campos', () {
      const context = FeatureContext(
        id: '001-auth',
        number: '001',
        name: 'auth',
        status: SddFeatureStatus.specified,
        branchName: '001-auth',
        paths: FeaturePaths.empty(),
        documents: FeatureDocuments.empty(),
      );

      expect(context.id, equals('001-auth'));
      expect(context.number, equals('001'));
      expect(context.status, equals(SddFeatureStatus.specified));
    });

    test('empty crea contexto vacío', () {
      const context = FeatureContext.empty();

      expect(context.id, isEmpty);
      expect(context.hasFeature, isFalse);
    });

    test('fromJson parsea JSON correctamente', () {
      final json = {
        'id': '001-auth',
        'number': '001',
        'name': 'auth',
        'status': 'specified',
        'branch_name': '001-auth',
        'documents': {
          'spec': true,
          'plan': false,
          'tasks': false,
          'research': false,
          'checklist': false,
          'data_model': false,
        },
      };

      final context = FeatureContext.fromJson(json);

      expect(context.id, equals('001-auth'));
      expect(context.number, equals('001'));
      expect(context.status, equals(SddFeatureStatus.specified));
      expect(context.documents.specExists, isTrue);
      expect(context.documents.planExists, isFalse);
    });

    test('hasFeature es true cuando hay ID', () {
      const context = FeatureContext(
        id: '001-auth',
        number: '001',
        name: 'auth',
        status: SddFeatureStatus.specified,
        branchName: '001-auth',
        paths: FeaturePaths.empty(),
        documents: FeatureDocuments.empty(),
      );

      expect(context.hasFeature, isTrue);
    });

    test('canPlan es true cuando hay spec', () {
      const context = FeatureContext(
        id: '001-auth',
        number: '001',
        name: 'auth',
        status: SddFeatureStatus.specified,
        branchName: '001-auth',
        paths: FeaturePaths.empty(),
        documents: FeatureDocuments(
          specExists: true,
          planExists: false,
          tasksExists: false,
          researchExists: false,
          checklistExists: false,
          dataModelExists: false,
        ),
      );

      expect(context.canPlan, isTrue);
      expect(context.canImplement, isFalse);
    });

    test('canImplement es true cuando hay spec y plan', () {
      const context = FeatureContext(
        id: '001-auth',
        number: '001',
        name: 'auth',
        status: SddFeatureStatus.planned,
        branchName: '001-auth',
        paths: FeaturePaths.empty(),
        documents: FeatureDocuments(
          specExists: true,
          planExists: true,
          tasksExists: false,
          researchExists: false,
          checklistExists: false,
          dataModelExists: false,
        ),
      );

      expect(context.canPlan, isTrue);
      expect(context.canImplement, isTrue);
    });

    test('toJson serializa correctamente', () {
      const context = FeatureContext(
        id: '001-auth',
        number: '001',
        name: 'auth',
        status: SddFeatureStatus.specified,
        branchName: '001-auth',
        paths: FeaturePaths.empty(),
        documents: FeatureDocuments.empty(),
      );

      final json = context.toJson();

      expect(json['id'], equals('001-auth'));
      expect(json['number'], equals('001'));
      expect(json['status'], equals('specified'));
      expect(json['has_feature'], isTrue);
      expect(json['can_plan'], isFalse);
    });

    test('soporta igualdad con Equatable', () {
      const context1 = FeatureContext(
        id: '001-auth',
        number: '001',
        name: 'auth',
        status: SddFeatureStatus.specified,
        branchName: '001-auth',
        paths: FeaturePaths.empty(),
        documents: FeatureDocuments.empty(),
      );

      const context2 = FeatureContext(
        id: '001-auth',
        number: '001',
        name: 'auth',
        status: SddFeatureStatus.specified,
        branchName: '001-auth',
        paths: FeaturePaths.empty(),
        documents: FeatureDocuments.empty(),
      );

      const context3 = FeatureContext(
        id: '002-other',
        number: '002',
        name: 'other',
        status: SddFeatureStatus.none,
        branchName: '002-other',
        paths: FeaturePaths.empty(),
        documents: FeatureDocuments.empty(),
      );

      expect(context1, equals(context2));
      expect(context1, isNot(equals(context3)));
    });
  });
}
