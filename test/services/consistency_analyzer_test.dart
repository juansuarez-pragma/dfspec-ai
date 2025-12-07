import 'dart:io';

import 'package:dfspec/src/models/traceability.dart';
import 'package:dfspec/src/services/consistency_analyzer.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('ConsistencyAnalyzer', () {
    late Directory tempDir;
    late String projectRoot;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('consistency_test_');
      projectRoot = tempDir.path;

      // Crear estructura de directorios
      await Directory(p.join(projectRoot, 'specs/features/001-test'))
          .create(recursive: true);
      await Directory(p.join(projectRoot, 'lib/src')).create(recursive: true);
      await Directory(p.join(projectRoot, 'test')).create(recursive: true);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    group('constructor', () {
      test('usa directorio actual cuando no se especifica projectRoot', () {
        final analyzer = ConsistencyAnalyzer();
        expect(analyzer, isNotNull);
      });

      test('acepta projectRoot personalizado', () {
        final analyzer = ConsistencyAnalyzer(projectRoot: '/custom/path');
        expect(analyzer, isNotNull);
      });
    });

    group('buildMatrix', () {
      test('retorna matriz vacía cuando no hay archivos', () async {
        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        expect(matrix.featureId, equals('001-test'));
        expect(matrix.artifacts, isEmpty);
        expect(matrix.links, isEmpty);
      });

      test('parsea requisitos de spec.md', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('''
# Feature 001-test

## Requisitos Funcionales

- El usuario debe poder iniciar sesión
- El sistema debe validar credenciales
- El usuario debe poder cerrar sesión

## Descripción

Esto es una descripción.
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        expect(matrix.requirements.length, equals(3));
        expect(matrix.requirements[0].id, equals('REQ-001'));
        expect(matrix.requirements[0].title,
            equals('El usuario debe poder iniciar sesión'));
        expect(matrix.requirements[1].id, equals('REQ-002'));
        expect(matrix.requirements[2].id, equals('REQ-003'));
      });

      test('parsea User Stories con formato estándar', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('''
# Feature 001-test

## User Stories

### US-001: Login de usuario (Priority: P1)

**Como** usuario
**Quiero** iniciar sesión
**Para** acceder a mi cuenta

#### Criterios de Aceptación

- [ ] AC-001: Given credenciales válidas When inicio sesión Then accedo al dashboard
- [ ] AC-002: Given credenciales inválidas When inicio sesión Then veo mensaje de error
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        expect(matrix.userStories.length, equals(1));
        expect(matrix.userStories[0].id, equals('US-001'));
        expect(matrix.acceptanceCriteria.length, equals(2));
      });

      test('parsea tareas de tasks.md', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/tasks.md'))
            .writeAsString('''
# Tareas Feature 001-test

- [ ] TASK-001: Crear modelo de usuario
- [ ] TASK-002: Implementar repositorio de autenticación
- [x] TASK-003: Configurar endpoint de login
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        expect(matrix.tasks.length, equals(3));
        expect(matrix.tasks[0].id, equals('TASK-001'));
        expect(matrix.tasks[0].title, equals('Crear modelo de usuario'));
        expect(matrix.tasks[2].metadata['is_completed'], isTrue);
      });

      test('escanea archivos de código fuente en lib/src', () async {
        await File(p.join(projectRoot, 'lib/src/auth_service.dart'))
            .writeAsString('''
/// Servicio de autenticación
class AuthService {
  Future<void> login() async {}
}
''');
        await File(p.join(projectRoot, 'lib/src/user_model.dart'))
            .writeAsString('''
class UserModel {}
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        expect(matrix.sourceCode.length, equals(2));
        final codeIds = matrix.sourceCode.map((c) => c.id).toSet();
        expect(codeIds, contains('CODE-auth_service'));
        expect(codeIds, contains('CODE-user_model'));
      });

      test('escanea archivos de test en test/', () async {
        await File(p.join(projectRoot, 'test/auth_service_test.dart'))
            .writeAsString('''
import 'package:test/test.dart';

void main() {
  test('test 1', () {});
  test('test 2', () {});
}
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        expect(matrix.tests.length, equals(1));
        expect(matrix.tests[0].id, equals('TEST-auth_service_test'));
        expect(matrix.tests[0].metadata['test_count'], equals(2));
      });

      test('crea links entre tests y código por convención de nombres',
          () async {
        await File(p.join(projectRoot, 'lib/src/auth_service.dart'))
            .writeAsString('class AuthService {}');
        await File(p.join(projectRoot, 'test/auth_service_test.dart'))
            .writeAsString('void main() {}');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        final testLinks = matrix.linksFrom(matrix.tests[0]);
        expect(testLinks.length, equals(1));
        expect(testLinks[0].target.id, equals('CODE-auth_service'));
        expect(testLinks[0].linkType, equals(LinkType.tests));
      });

      test('extrae referencias US en comentarios de código', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('''
### US-001: Login (Priority: P1)

**Como** usuario
**Quiero** login
**Para** acceso
''');
        await File(p.join(projectRoot, 'lib/src/auth_service.dart'))
            .writeAsString('''
/// Implementa US-001
class AuthService {}
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        final codeArtifact = matrix.sourceCode
            .firstWhere((c) => c.id == 'CODE-auth_service');
        final links = matrix.linksFrom(codeArtifact);

        expect(links.any((l) => l.target.id == 'US-001'), isTrue);
      });

      test('extrae referencias TASK en código', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/tasks.md'))
            .writeAsString('- [ ] TASK-001: Crear servicio');
        await File(p.join(projectRoot, 'lib/src/auth_service.dart'))
            .writeAsString('''
// TASK-001: Implementación del servicio
class AuthService {}
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        final codeArtifact = matrix.sourceCode
            .firstWhere((c) => c.id == 'CODE-auth_service');
        final links = matrix.linksFrom(codeArtifact);

        expect(links.any((l) => l.target.id == 'TASK-001'), isTrue);
      });
    });

    group('analyze', () {
      test('detecta requisitos huérfanos sin User Stories', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('''
## Requisitos Funcionales

- Requisito sin User Story asociada
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final report = await analyzer.analyze('001-test');

        expect(report.issues.any((i) => i.code == 'ORPHAN_REQ'), isTrue);
        final issue = report.issues.firstWhere((i) => i.code == 'ORPHAN_REQ');
        expect(issue.severity, equals(IssueSeverity.critical));
      });

      test('detecta User Stories sin criterios de aceptación', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('''
### US-001: User Story sin ACs (Priority: P1)

**Como** usuario
**Quiero** algo
**Para** nada
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final report = await analyzer.analyze('001-test');

        expect(report.issues.any((i) => i.code == 'US_NO_AC'), isTrue);
        final issue = report.issues.firstWhere((i) => i.code == 'US_NO_AC');
        expect(issue.severity, equals(IssueSeverity.critical));
      });

      test('detecta User Stories sin tareas', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('''
### US-001: User Story (Priority: P1)

**Como** usuario
**Quiero** algo
**Para** nada

#### Criterios de Aceptación

- [ ] AC-001: Given algo When algo Then algo
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final report = await analyzer.analyze('001-test');

        expect(report.issues.any((i) => i.code == 'US_NO_TASKS'), isTrue);
        final issue = report.issues.firstWhere((i) => i.code == 'US_NO_TASKS');
        expect(issue.severity, equals(IssueSeverity.warning));
      });

      test('detecta tareas sin código implementado', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/tasks.md'))
            .writeAsString('- [ ] TASK-001: Tarea sin implementar');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final report = await analyzer.analyze('001-test');

        expect(report.issues.any((i) => i.code == 'TASK_NO_CODE'), isTrue);
        final issue = report.issues.firstWhere((i) => i.code == 'TASK_NO_CODE');
        expect(issue.severity, equals(IssueSeverity.warning));
      });

      test('detecta código sin tests', () async {
        await File(p.join(projectRoot, 'lib/src/untested_service.dart'))
            .writeAsString('class UntestedService {}');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final report = await analyzer.analyze('001-test');

        expect(report.issues.any((i) => i.code == 'CODE_NO_TEST'), isTrue);
        final issue = report.issues.firstWhere((i) => i.code == 'CODE_NO_TEST');
        expect(issue.severity, equals(IssueSeverity.warning));
        expect(issue.suggestion, contains('untested_service_test.dart'));
      });

      test('detecta tests sin código correspondiente', () async {
        await File(p.join(projectRoot, 'test/orphan_test.dart'))
            .writeAsString('void main() {}');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final report = await analyzer.analyze('001-test');

        expect(report.issues.any((i) => i.code == 'TEST_NO_CODE'), isTrue);
        final issue = report.issues.firstWhere((i) => i.code == 'TEST_NO_CODE');
        expect(issue.severity, equals(IssueSeverity.info));
      });

      test('no detecta issue CODE_NO_TEST cuando test existe', () async {
        await File(p.join(projectRoot, 'lib/src/tested_service.dart'))
            .writeAsString('class TestedService {}');
        await File(p.join(projectRoot, 'test/tested_service_test.dart'))
            .writeAsString('void main() {}');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final report = await analyzer.analyze('001-test');

        final codeNoTestIssues = report.issues.where((i) =>
            i.code == 'CODE_NO_TEST' &&
            i.artifact?.title == 'tested_service');
        expect(codeNoTestIssues, isEmpty);
      });

      test('genera sugerencia cuando cobertura es baja', () async {
        // Crear varios artefactos huérfanos para bajar la cobertura
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('''
## Requisitos Funcionales

- Req 1
- Req 2
- Req 3
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final report = await analyzer.analyze('001-test');

        expect(
          report.suggestions.any((s) => s.contains('Cobertura de trazabilidad')),
          isTrue,
        );
      });

      test('genera sugerencia cuando hay artefactos huérfanos', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('''
## Requisitos Funcionales

- Requisito huérfano
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final report = await analyzer.analyze('001-test');

        expect(
          report.suggestions.any((s) => s.contains('huérfanos')),
          isTrue,
        );
      });

      test('genera sugerencia cuando hay requisitos sin User Stories', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('''
## Requisitos Funcionales

- Requisito sin User Story
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final report = await analyzer.analyze('001-test');

        expect(
          report.suggestions.any((s) => s.contains('/df-spec')),
          isTrue,
        );
      });

      test('passed es true cuando no hay issues críticos', () async {
        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final report = await analyzer.analyze('001-test');

        expect(report.passed, isTrue);
      });

      test('passed es false cuando hay issues críticos', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('''
## Requisitos Funcionales

- Requisito huérfano crítico
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final report = await analyzer.analyze('001-test');

        expect(report.passed, isFalse);
      });

      test('score refleja penalización por issues', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('''
## Requisitos Funcionales

- Req 1
- Req 2
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final report = await analyzer.analyze('001-test');

        // 2 issues críticos = -40 puntos
        expect(report.score, lessThan(100));
      });
    });

    group('_parseSpec', () {
      test('maneja secciones de requisitos correctamente', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('''
## Requisitos Funcionales

- Requisito funcional 1
- Requisito funcional 2

## Requisitos No Funcionales

- Requisito no funcional 1

## Otra sección

- Esto no es requisito
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        // Solo los requisitos de las secciones correctas
        expect(matrix.requirements.length, equals(3));
      });

      test('ignora líneas vacías en requisitos', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('''
## Requisitos Funcionales

- Requisito 1

- Requisito 2
-
- Requisito 3
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        expect(matrix.requirements.length, equals(3));
      });

      test('vincula requisitos con User Stories relacionadas', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('''
## Requisitos Funcionales

- El usuario debe autenticarse con email

### US-001: Autenticación (Priority: P1)

**Como** usuario
**Quiero** autenticarme con mi email
**Para** acceder al sistema
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        final req = matrix.requirements.first;
        final reqLinks = matrix.linksFrom(req);

        expect(reqLinks.isNotEmpty, isTrue);
        expect(reqLinks.first.target.type, equals(ArtifactType.userStory));
      });
    });

    group('_parseTasks', () {
      test('numera tareas automáticamente cuando no tienen ID', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/tasks.md'))
            .writeAsString('''
- [ ] Primera tarea
- [ ] Segunda tarea
- [ ] Tercera tarea
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        expect(matrix.tasks[0].id, equals('TASK-001'));
        expect(matrix.tasks[1].id, equals('TASK-002'));
        expect(matrix.tasks[2].id, equals('TASK-003'));
      });

      test('usa ID explícito cuando está presente', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/tasks.md'))
            .writeAsString('''
- [ ] TASK-005: Tarea con ID explícito
- [ ] Tarea sin ID
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        // La primera tarea tiene TASK-005 explícito
        expect(matrix.tasks[0].id, equals('TASK-005'));
        // La segunda tarea recibe numeración automática
        expect(matrix.tasks[1].id, equals('TASK-002'));
      });

      test('detecta tareas completadas', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/tasks.md'))
            .writeAsString('''
- [ ] Tarea pendiente
- [x] Tarea completada
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        expect(matrix.tasks[0].metadata['is_completed'], isFalse);
        expect(matrix.tasks[1].metadata['is_completed'], isTrue);
      });

      test('limpia título de tarea correctamente', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/tasks.md'))
            .writeAsString('''
- [ ] TASK-001: Crear modelo de usuario
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        expect(matrix.tasks[0].title, equals('Crear modelo de usuario'));
      });

      test('vincula tareas con User Stories referenciadas', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('''
### US-001: Login (Priority: P1)

**Como** usuario
**Quiero** login
**Para** acceso
''');
        await File(p.join(projectRoot, 'specs/features/001-test/tasks.md'))
            .writeAsString('''
- [ ] Implementar login (US-001)
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        // Verificar que la US existe
        expect(matrix.userStories.isNotEmpty, isTrue);
        final us = matrix.userStories.first;
        final usLinks = matrix.linksFrom(us);

        expect(usLinks.any((l) => l.target.type == ArtifactType.task), isTrue);
      });
    });

    group('_scanSourceCode', () {
      test('ignora directorios sin lib/src', () async {
        // No crear lib/src
        await tempDir.delete(recursive: true);
        tempDir = await Directory.systemTemp.createTemp('consistency_test_');
        projectRoot = tempDir.path;
        await Directory(p.join(projectRoot, 'specs/features/001-test'))
            .create(recursive: true);

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        expect(matrix.sourceCode, isEmpty);
      });

      test('escanea subdirectorios recursivamente', () async {
        await Directory(p.join(projectRoot, 'lib/src/domain/entities'))
            .create(recursive: true);
        await File(p.join(projectRoot, 'lib/src/domain/entities/user.dart'))
            .writeAsString('class User {}');
        await File(p.join(projectRoot, 'lib/src/auth.dart'))
            .writeAsString('class Auth {}');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        expect(matrix.sourceCode.length, equals(2));
      });

      test('extrae líneas de código como metadata', () async {
        await File(p.join(projectRoot, 'lib/src/service.dart'))
            .writeAsString('''
class Service {
  void method1() {}
  void method2() {}
  void method3() {}
}
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        final code = matrix.sourceCode.first;
        expect(code.metadata['lines'], equals(6));
      });
    });

    group('_scanTests', () {
      test('ignora directorios sin test/', () async {
        await tempDir.delete(recursive: true);
        tempDir = await Directory.systemTemp.createTemp('consistency_test_');
        projectRoot = tempDir.path;
        await Directory(p.join(projectRoot, 'specs/features/001-test'))
            .create(recursive: true);
        await Directory(p.join(projectRoot, 'lib/src')).create(recursive: true);

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        expect(matrix.tests, isEmpty);
      });

      test('solo incluye archivos *_test.dart', () async {
        await File(p.join(projectRoot, 'test/service_test.dart'))
            .writeAsString('void main() {}');
        await File(p.join(projectRoot, 'test/helper.dart'))
            .writeAsString('class Helper {}');
        await File(p.join(projectRoot, 'test/mock_data.dart'))
            .writeAsString('var data = {};');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        expect(matrix.tests.length, equals(1));
        expect(matrix.tests[0].id, equals('TEST-service_test'));
      });

      test('cuenta tests correctamente', () async {
        await File(p.join(projectRoot, 'test/service_test.dart'))
            .writeAsString('''
void main() {
  test('test 1', () {});
  test('test 2', () {});
  test('test 3', () {});
  group('group', () {
    test('test 4', () {});
  });
}
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        expect(matrix.tests[0].metadata['test_count'], equals(4));
      });
    });

    group('_extractReferences', () {
      test('extrae múltiples referencias US', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('''
### US-001: Primera (Priority: P1)

**Como** usuario
**Quiero** algo
**Para** beneficio

### US-002: Segunda (Priority: P2)

**Como** usuario
**Quiero** otra cosa
**Para** otro beneficio
''');
        await File(p.join(projectRoot, 'lib/src/service.dart'))
            .writeAsString('''
// Implementa US-001 y US-002
class Service {}
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        final code = matrix.sourceCode.first;
        final links = matrix.linksFrom(code);

        expect(links.where((l) => l.target.id == 'US-001'), isNotEmpty);
        expect(links.where((l) => l.target.id == 'US-002'), isNotEmpty);
      });

      test('extrae referencias AC', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('''
### US-001: Test (Priority: P1)

**Como** usuario
**Quiero** algo
**Para** beneficio

#### Criterios de Aceptación

- [ ] AC-001: Given x When y Then z
''');
        await File(p.join(projectRoot, 'test/service_test.dart'))
            .writeAsString('''
// Satisface AC-001
void main() {}
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        final test = matrix.tests.first;
        final links = matrix.linksFrom(test);

        expect(links.any((l) => l.target.id == 'AC-001'), isTrue);
        expect(
          links.firstWhere((l) => l.target.id == 'AC-001').linkType,
          equals(LinkType.satisfies),
        );
      });
    });

    group('_inferLinks', () {
      test('infiere links entre ACs y Tasks con contenido similar', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('''
### US-001: Login (Priority: P1)

**Como** usuario
**Quiero** autenticarme
**Para** acceder

#### Criterios de Aceptación

- [ ] AC-001: Given credenciales válidas When autenticación Then acceso permitido
''');
        await File(p.join(projectRoot, 'specs/features/001-test/tasks.md'))
            .writeAsString('''
- [ ] Implementar autenticación con credenciales válidas
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        // Verificar que hay ACs y Tasks
        expect(matrix.acceptanceCriteria.isNotEmpty, isTrue);
        expect(matrix.tasks.isNotEmpty, isTrue);

        final ac = matrix.acceptanceCriteria.first;
        final task = matrix.tasks.first;

        final acLinks = matrix.linksFrom(ac);
        final hasLinkToTask = acLinks.any((l) => l.target.id == task.id);

        // El link debería existir por contenido similar
        expect(hasLinkToTask, isTrue);
      });
    });

    group('_contentRelated', () {
      test('detecta contenido relacionado con palabras clave comunes', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('''
## Requisitos Funcionales

- Implementar autenticación segura con tokens JWT

### US-001: Autenticación JWT (Priority: P1)

**Como** usuario
**Quiero** autenticación con tokens JWT
**Para** seguridad
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        final req = matrix.requirements.first;
        final reqLinks = matrix.linksFrom(req);

        // Deberían estar relacionados por "autenticación", "tokens", "JWT"
        expect(reqLinks.isNotEmpty, isTrue);
      });
    });

    group('edge cases', () {
      test('maneja archivo spec.md inexistente', () async {
        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('nonexistent-feature');

        expect(matrix.artifacts, isEmpty);
      });

      test('maneja archivo tasks.md inexistente', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('# Spec');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        expect(matrix.tasks, isEmpty);
      });

      test('maneja spec.md vacío', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        expect(matrix.requirements, isEmpty);
        expect(matrix.userStories, isEmpty);
      });

      test('maneja caracteres especiales en requisitos', () async {
        await File(p.join(projectRoot, 'specs/features/001-test/spec.md'))
            .writeAsString('''
## Requisitos Funcionales

- El usuario debe poder usar "comillas" y 'apóstrofes'
- Soporte para acentos: áéíóú ñ
''');

        final analyzer = ConsistencyAnalyzer(projectRoot: projectRoot);
        final matrix = await analyzer.buildMatrix('001-test');

        expect(matrix.requirements.length, equals(2));
      });
    });
  });
}
