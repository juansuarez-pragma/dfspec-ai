import 'package:dfspec/src/models/traceability.dart';
import 'package:test/test.dart';

void main() {
  group('ArtifactType', () {
    test('tiene prefijos correctos', () {
      expect(ArtifactType.requirement.prefix, equals('REQ'));
      expect(ArtifactType.userStory.prefix, equals('US'));
      expect(ArtifactType.acceptanceCriteria.prefix, equals('AC'));
      expect(ArtifactType.task.prefix, equals('TASK'));
      expect(ArtifactType.test.prefix, equals('TEST'));
      expect(ArtifactType.sourceCode.prefix, equals('CODE'));
    });
  });

  group('TraceableArtifact', () {
    test('crea artefacto con campos requeridos', () {
      const artifact = TraceableArtifact(
        id: '001',
        type: ArtifactType.requirement,
        title: 'Test Requirement',
        sourcePath: 'specs/test.md',
      );

      expect(artifact.id, equals('001'));
      expect(artifact.type, equals(ArtifactType.requirement));
      expect(artifact.title, equals('Test Requirement'));
      expect(artifact.sourcePath, equals('specs/test.md'));
      expect(artifact.lineNumber, isNull);
      expect(artifact.metadata, isEmpty);
    });

    test('crea artefacto con campos opcionales', () {
      const artifact = TraceableArtifact(
        id: '002',
        type: ArtifactType.userStory,
        title: 'User Story',
        sourcePath: 'specs/feature.md',
        lineNumber: 42,
        metadata: {'priority': 'P1'},
      );

      expect(artifact.lineNumber, equals(42));
      expect(artifact.metadata['priority'], equals('P1'));
    });

    test('location incluye número de línea cuando está presente', () {
      const withLine = TraceableArtifact(
        id: '001',
        type: ArtifactType.requirement,
        title: 'Test',
        sourcePath: 'specs/test.md',
        lineNumber: 10,
      );

      const withoutLine = TraceableArtifact(
        id: '002',
        type: ArtifactType.requirement,
        title: 'Test',
        sourcePath: 'specs/test.md',
      );

      expect(withLine.location, equals('specs/test.md:10'));
      expect(withoutLine.location, equals('specs/test.md'));
    });

    test('igualdad se basa en id y tipo', () {
      const artifact1 = TraceableArtifact(
        id: '001',
        type: ArtifactType.requirement,
        title: 'Title 1',
        sourcePath: 'path1',
      );

      const artifact2 = TraceableArtifact(
        id: '001',
        type: ArtifactType.requirement,
        title: 'Title 2', // Diferente título
        sourcePath: 'path2', // Diferente path
      );

      const artifact3 = TraceableArtifact(
        id: '001',
        type: ArtifactType.userStory, // Diferente tipo
        title: 'Title 1',
        sourcePath: 'path1',
      );

      expect(artifact1, equals(artifact2));
      expect(artifact1, isNot(equals(artifact3)));
    });

    test('toJson serializa correctamente', () {
      const artifact = TraceableArtifact(
        id: '001',
        type: ArtifactType.requirement,
        title: 'Test',
        sourcePath: 'specs/test.md',
        lineNumber: 5,
        metadata: {'key': 'value'},
      );

      final json = artifact.toJson();

      expect(json['id'], equals('001'));
      expect(json['type'], equals('requirement'));
      expect(json['title'], equals('Test'));
      expect(json['source_path'], equals('specs/test.md'));
      expect(json['line_number'], equals(5));
      expect(json['metadata'], equals({'key': 'value'}));
    });

    test('toString muestra formato legible', () {
      const artifact = TraceableArtifact(
        id: '001',
        type: ArtifactType.requirement,
        title: 'My Requirement',
        sourcePath: 'test.md',
      );

      expect(artifact.toString(), equals('REQ-001: My Requirement'));
    });
  });

  group('TraceabilityLink', () {
    late TraceableArtifact source;
    late TraceableArtifact target;

    setUp(() {
      source = const TraceableArtifact(
        id: 'US-001',
        type: ArtifactType.userStory,
        title: 'Source',
        sourcePath: 'source.md',
      );
      target = const TraceableArtifact(
        id: 'AC-001',
        type: ArtifactType.acceptanceCriteria,
        title: 'Target',
        sourcePath: 'target.md',
      );
    });

    test('crea link con valores por defecto', () {
      final link = TraceabilityLink(source: source, target: target);

      expect(link.source, equals(source));
      expect(link.target, equals(target));
      expect(link.linkType, equals(LinkType.implements));
      expect(link.isVerified, isFalse);
      expect(link.notes, isNull);
    });

    test('crea link con valores personalizados', () {
      final link = TraceabilityLink(
        source: source,
        target: target,
        linkType: LinkType.tests,
        isVerified: true,
        notes: 'Verified manually',
      );

      expect(link.linkType, equals(LinkType.tests));
      expect(link.isVerified, isTrue);
      expect(link.notes, equals('Verified manually'));
    });

    test('igualdad se basa en source, target y linkType', () {
      final link1 = TraceabilityLink(
        source: source,
        target: target,
      );

      final link2 = TraceabilityLink(
        source: source,
        target: target,
        isVerified: true, // Diferente isVerified
      );

      final link3 = TraceabilityLink(
        source: source,
        target: target,
        linkType: LinkType.tests, // Diferente linkType
      );

      expect(link1, equals(link2));
      expect(link1, isNot(equals(link3)));
    });

    test('toJson serializa correctamente', () {
      final link = TraceabilityLink(
        source: source,
        target: target,
        linkType: LinkType.tests,
        isVerified: true,
        notes: 'Test note',
      );

      final json = link.toJson();

      expect(json['source'], isA<Map<String, dynamic>>());
      expect(json['target'], isA<Map<String, dynamic>>());
      expect(json['link_type'], equals('tests'));
      expect(json['is_verified'], isTrue);
      expect(json['notes'], equals('Test note'));
    });
  });

  group('TraceabilityMatrix', () {
    late TraceableArtifact req;
    late TraceableArtifact us;
    late TraceableArtifact ac;
    late TraceableArtifact task;
    late TraceableArtifact code;
    late TraceableArtifact testArtifact;

    setUp(() {
      req = const TraceableArtifact(
        id: 'REQ-001',
        type: ArtifactType.requirement,
        title: 'Requirement',
        sourcePath: 'spec.md',
      );
      us = const TraceableArtifact(
        id: 'US-001',
        type: ArtifactType.userStory,
        title: 'User Story',
        sourcePath: 'spec.md',
      );
      ac = const TraceableArtifact(
        id: 'AC-001',
        type: ArtifactType.acceptanceCriteria,
        title: 'AC',
        sourcePath: 'spec.md',
      );
      task = const TraceableArtifact(
        id: 'TASK-001',
        type: ArtifactType.task,
        title: 'Task',
        sourcePath: 'tasks.md',
      );
      code = const TraceableArtifact(
        id: 'CODE-main',
        type: ArtifactType.sourceCode,
        title: 'main',
        sourcePath: 'lib/src/main.dart',
      );
      testArtifact = const TraceableArtifact(
        id: 'TEST-main',
        type: ArtifactType.test,
        title: 'main_test',
        sourcePath: 'test/main_test.dart',
      );
    });

    test('empty crea matriz vacía', () {
      final matrix = TraceabilityMatrix.empty('test-feature');

      expect(matrix.featureId, equals('test-feature'));
      expect(matrix.artifacts, isEmpty);
      expect(matrix.links, isEmpty);
    });

    test('byType retorna artefactos filtrados', () {
      final matrix = TraceabilityMatrix(
        featureId: 'test',
        artifacts: [req, us, ac],
        links: const [],
        generatedAt: DateTime.now(),
      );

      expect(matrix.byType(ArtifactType.requirement), equals([req]));
      expect(matrix.byType(ArtifactType.userStory), equals([us]));
      expect(matrix.byType(ArtifactType.task), isEmpty);
    });

    test('getters por tipo funcionan correctamente', () {
      final matrix = TraceabilityMatrix(
        featureId: 'test',
        artifacts: [req, us, ac, task, code, testArtifact],
        links: const [],
        generatedAt: DateTime.now(),
      );

      expect(matrix.requirements, equals([req]));
      expect(matrix.userStories, equals([us]));
      expect(matrix.acceptanceCriteria, equals([ac]));
      expect(matrix.tasks, equals([task]));
      expect(matrix.sourceCode, equals([code]));
      expect(matrix.tests, equals([testArtifact]));
    });

    test('linksFrom retorna links salientes', () {
      final link1 = TraceabilityLink(source: us, target: ac);
      final link2 = TraceabilityLink(source: us, target: task);
      final link3 = TraceabilityLink(source: req, target: us);

      final matrix = TraceabilityMatrix(
        featureId: 'test',
        artifacts: [req, us, ac, task],
        links: [link1, link2, link3],
        generatedAt: DateTime.now(),
      );

      expect(matrix.linksFrom(us), equals([link1, link2]));
      expect(matrix.linksFrom(req), equals([link3]));
      expect(matrix.linksFrom(ac), isEmpty);
    });

    test('linksTo retorna links entrantes', () {
      final link1 = TraceabilityLink(source: us, target: ac);
      final link2 = TraceabilityLink(source: req, target: us);

      final matrix = TraceabilityMatrix(
        featureId: 'test',
        artifacts: [req, us, ac],
        links: [link1, link2],
        generatedAt: DateTime.now(),
      );

      expect(matrix.linksTo(ac), equals([link1]));
      expect(matrix.linksTo(us), equals([link2]));
      expect(matrix.linksTo(req), isEmpty);
    });

    test('findById encuentra artefacto por ID', () {
      final matrix = TraceabilityMatrix(
        featureId: 'test',
        artifacts: [req, us, ac],
        links: const [],
        generatedAt: DateTime.now(),
      );

      expect(matrix.findById('US-001'), equals(us));
      expect(matrix.findById('INVALID'), isNull);
    });

    test('getCoverageStatus para sourceCode', () {
      final testLink = TraceabilityLink(
        source: testArtifact,
        target: code,
        linkType: LinkType.tests,
      );

      final matrixWithTest = TraceabilityMatrix(
        featureId: 'test',
        artifacts: [code, testArtifact],
        links: [testLink],
        generatedAt: DateTime.now(),
      );

      final matrixWithoutTest = TraceabilityMatrix(
        featureId: 'test',
        artifacts: [code],
        links: const [],
        generatedAt: DateTime.now(),
      );

      expect(
        matrixWithTest.getCoverageStatus(code),
        equals(CoverageStatus.covered),
      );
      expect(
        matrixWithoutTest.getCoverageStatus(code),
        equals(CoverageStatus.orphan),
      );
    });

    test('getCoverageStatus para userStory', () {
      final acLink = TraceabilityLink(source: us, target: ac);
      final taskLink = TraceabilityLink(source: us, target: task);

      // Cobertura completa
      final matrixFull = TraceabilityMatrix(
        featureId: 'test',
        artifacts: [us, ac, task],
        links: [acLink, taskLink],
        generatedAt: DateTime.now(),
      );
      expect(
        matrixFull.getCoverageStatus(us),
        equals(CoverageStatus.covered),
      );

      // Cobertura parcial (solo AC)
      final matrixPartial = TraceabilityMatrix(
        featureId: 'test',
        artifacts: [us, ac],
        links: [acLink],
        generatedAt: DateTime.now(),
      );
      expect(
        matrixPartial.getCoverageStatus(us),
        equals(CoverageStatus.partial),
      );

      // Sin cobertura
      final matrixOrphan = TraceabilityMatrix(
        featureId: 'test',
        artifacts: [us],
        links: const [],
        generatedAt: DateTime.now(),
      );
      expect(
        matrixOrphan.getCoverageStatus(us),
        equals(CoverageStatus.orphan),
      );
    });

    test('orphanArtifacts retorna artefactos huérfanos', () {
      const orphanReq = TraceableArtifact(
        id: 'REQ-002',
        type: ArtifactType.requirement,
        title: 'Orphan',
        sourcePath: 'spec.md',
      );

      final link = TraceabilityLink(source: req, target: us);

      final matrix = TraceabilityMatrix(
        featureId: 'test',
        artifacts: [req, orphanReq, us],
        links: [link],
        generatedAt: DateTime.now(),
      );

      expect(matrix.orphanArtifacts, contains(orphanReq));
    });

    test('coveragePercentage calcula correctamente', () {
      // Matriz vacía = 100%
      final emptyMatrix = TraceabilityMatrix.empty('test');
      expect(emptyMatrix.coveragePercentage, equals(100.0));

      // Todos cubiertos = 100%
      final link = TraceabilityLink(source: req, target: us);
      final fullMatrix = TraceabilityMatrix(
        featureId: 'test',
        artifacts: [req],
        links: [link],
        generatedAt: DateTime.now(),
      );
      expect(fullMatrix.coveragePercentage, equals(100.0));
    });

    test('toJson serializa correctamente', () {
      final link = TraceabilityLink(source: req, target: us);
      final matrix = TraceabilityMatrix(
        featureId: 'test-feature',
        artifacts: [req, us],
        links: [link],
        generatedAt: DateTime.now(),
      );

      final json = matrix.toJson();

      expect(json['feature_id'], equals('test-feature'));
      expect(json['summary'], isA<Map<String, dynamic>>());
      expect((json['artifacts'] as List).length, equals(2));
      expect((json['links'] as List).length, equals(1));
    });
  });

  group('ConsistencyReport', () {
    late TraceabilityMatrix matrix;

    setUp(() {
      matrix = TraceabilityMatrix.empty('test');
    });

    test('passed es true cuando no hay issues críticos', () {
      final reportNoIssues = ConsistencyReport(
        matrix: matrix,
        issues: const [],
        suggestions: const [],
      );
      expect(reportNoIssues.passed, isTrue);

      final reportWithWarning = ConsistencyReport(
        matrix: matrix,
        issues: const [
          ConsistencyIssue(
            code: 'WARNING',
            message: 'Test',
            severity: IssueSeverity.warning,
          ),
        ],
        suggestions: const [],
      );
      expect(reportWithWarning.passed, isTrue);
    });

    test('passed es false cuando hay issues críticos', () {
      final report = ConsistencyReport(
        matrix: matrix,
        issues: const [
          ConsistencyIssue(
            code: 'CRITICAL',
            message: 'Test',
            severity: IssueSeverity.critical,
          ),
        ],
        suggestions: const [],
      );
      expect(report.passed, isFalse);
    });

    test('score se calcula correctamente', () {
      // Sin issues = 100
      final reportNoIssues = ConsistencyReport(
        matrix: matrix,
        issues: const [],
        suggestions: const [],
      );
      expect(reportNoIssues.score, equals(100));

      // Con issues
      final reportWithIssues = ConsistencyReport(
        matrix: matrix,
        issues: const [
          ConsistencyIssue(
            code: 'CRITICAL',
            message: 'Test',
            severity: IssueSeverity.critical,
          ), // -20
          ConsistencyIssue(
            code: 'WARNING',
            message: 'Test',
            severity: IssueSeverity.warning,
          ), // -10
          ConsistencyIssue(
            code: 'INFO',
            message: 'Test',
            severity: IssueSeverity.info,
          ), // -2
        ],
        suggestions: const [],
      );
      expect(reportWithIssues.score, equals(68)); // 100 - 20 - 10 - 2

      // Score mínimo es 0
      final reportManyIssues = ConsistencyReport(
        matrix: matrix,
        issues: List.generate(
          10,
          (_) => const ConsistencyIssue(
            code: 'CRITICAL',
            message: 'Test',
            severity: IssueSeverity.critical,
          ),
        ),
        suggestions: const [],
      );
      expect(reportManyIssues.score, equals(0));
    });

    test('toJson serializa correctamente', () {
      final report = ConsistencyReport(
        matrix: matrix,
        issues: const [
          ConsistencyIssue(
            code: 'TEST',
            message: 'Test issue',
            severity: IssueSeverity.warning,
          ),
        ],
        suggestions: const ['Suggestion 1'],
      );

      final json = report.toJson();

      expect(json['passed'], isTrue);
      expect(json['score'], isA<int>());
      expect(json['issues'], isA<List>());
      expect(json['suggestions'], equals(['Suggestion 1']));
      expect(json['matrix'], isA<Map<String, dynamic>>());
    });
  });

  group('ConsistencyIssue', () {
    test('crea issue con campos requeridos', () {
      const issue = ConsistencyIssue(
        code: 'ORPHAN_REQ',
        message: 'Requisito sin US',
        severity: IssueSeverity.critical,
      );

      expect(issue.code, equals('ORPHAN_REQ'));
      expect(issue.message, equals('Requisito sin US'));
      expect(issue.severity, equals(IssueSeverity.critical));
      expect(issue.artifact, isNull);
      expect(issue.suggestion, isNull);
    });

    test('crea issue con campos opcionales', () {
      const artifact = TraceableArtifact(
        id: 'REQ-001',
        type: ArtifactType.requirement,
        title: 'Test',
        sourcePath: 'test.md',
      );

      const issue = ConsistencyIssue(
        code: 'ORPHAN_REQ',
        message: 'Requisito sin US',
        severity: IssueSeverity.critical,
        artifact: artifact,
        suggestion: 'Crear US para este requisito',
      );

      expect(issue.artifact, equals(artifact));
      expect(issue.suggestion, equals('Crear US para este requisito'));
    });

    test('toJson serializa correctamente', () {
      const artifact = TraceableArtifact(
        id: 'REQ-001',
        type: ArtifactType.requirement,
        title: 'Test',
        sourcePath: 'test.md',
      );

      const issue = ConsistencyIssue(
        code: 'ORPHAN_REQ',
        message: 'Test',
        severity: IssueSeverity.critical,
        artifact: artifact,
        suggestion: 'Fix it',
      );

      final json = issue.toJson();

      expect(json['code'], equals('ORPHAN_REQ'));
      expect(json['message'], equals('Test'));
      expect(json['severity'], equals('critical'));
      expect(json['artifact'], isA<Map<String, dynamic>>());
      expect(json['suggestion'], equals('Fix it'));
    });
  });

  group('LinkType', () {
    test('tiene todos los valores esperados', () {
      expect(LinkType.values, containsAll([
        LinkType.implements,
        LinkType.tests,
        LinkType.derivesFrom,
        LinkType.satisfies,
        LinkType.refines,
      ]));
    });
  });

  group('CoverageStatus', () {
    test('tiene todos los valores esperados', () {
      expect(CoverageStatus.values, containsAll([
        CoverageStatus.covered,
        CoverageStatus.partial,
        CoverageStatus.orphan,
        CoverageStatus.notApplicable,
      ]));
    });
  });

  group('IssueSeverity', () {
    test('tiene todos los valores esperados', () {
      expect(IssueSeverity.values, containsAll([
        IssueSeverity.critical,
        IssueSeverity.warning,
        IssueSeverity.info,
      ]));
    });
  });
}
