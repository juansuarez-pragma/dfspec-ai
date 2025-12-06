import 'package:dfspec/src/models/user_story.dart';
import 'package:dfspec/src/parsers/user_story_parser.dart';
import 'package:test/test.dart';

void main() {
  late UserStoryParser parser;

  setUp(() {
    parser = UserStoryParser();
  });

  group('UserStoryParser', () {
    group('parse', () {
      test('debe parsear documento con multiples User Stories', () {
        const content = '''
## User Stories

### US-001: Login de usuario (Priority: P1 - MVP)

**Como** usuario registrado
**Quiero** iniciar sesion
**Para** acceder a mi cuenta

#### Criterios de Aceptacion
- [ ] AC-001: Given credenciales validas When hace login Then accede al sistema
- [ ] AC-002: Given credenciales invalidas When hace login Then ve error

#### Test Independiente
Si - Puede probarse de forma aislada

### US-002: Perfil de usuario (Priority: P2)

**Como** usuario autenticado
**Quiero** ver mi perfil
**Para** revisar mis datos

#### Criterios de Aceptacion
- [ ] AC-003: Given usuario logueado When accede a perfil Then ve sus datos

#### Test Independiente
Si - Independiente del login

### US-003: Tema oscuro (Priority: P3 - Nice-to-have)

**Como** usuario
**Quiero** cambiar a tema oscuro
**Para** reducir fatiga visual

#### Criterios de Aceptacion
- [ ] AC-004: Given preferencias When activa dark mode Then UI cambia

#### Test Independiente
No - Depende de sistema de temas
''';

        final collection = parser.parse(content);

        expect(collection.stories.length, equals(3));
        expect(collection.mvpStories.length, equals(1));
        expect(collection.p2Stories.length, equals(1));
        expect(collection.p3Stories.length, equals(1));
      });

      test('debe parsear prioridades correctamente', () {
        const content = '''
### US-001: MVP Feature (Priority: P1 - MVP)

**Como** user
**Quiero** feature
**Para** benefit

#### Criterios de Aceptacion
- [ ] AC-001: Given x When y Then z

### US-002: Important (Priority: P2)

**Como** user
**Quiero** feature
**Para** benefit

#### Criterios de Aceptacion
- [ ] AC-002: Given a When b Then c
''';

        final collection = parser.parse(content);

        expect(collection.stories[0].priority, equals(Priority.p1));
        expect(collection.stories[1].priority, equals(Priority.p2));
      });

      test('debe extraer criterios de aceptacion en formato Gherkin', () {
        const content = '''
### US-001: Test (Priority: P1)

**Como** user
**Quiero** test
**Para** verify

#### Criterios de Aceptacion
- [ ] AC-001: Given usuario autenticado When accede al dashboard Then ve sus metricas
- [ ] AC-002: Given error de red When intenta cargar Then ve mensaje de error
''';

        final collection = parser.parse(content);
        final criteria = collection.stories.first.acceptanceCriteria;

        expect(criteria.length, equals(2));
        expect(criteria[0].id, equals('AC-001'));
        expect(criteria[0].given, equals('usuario autenticado'));
        expect(criteria[0].when, equals('accede al dashboard'));
        expect(criteria[0].then, equals('ve sus metricas'));
      });

      test('debe extraer requisitos relacionados FR-XXX', () {
        const content = '''
### US-001: Feature (Priority: P1)

**Como** user
**Quiero** feature
**Para** benefit

Esta US implementa FR-001 y FR-002.

#### Criterios de Aceptacion
- [ ] AC-001: Given x When y Then z

Tambien relacionado con FR-003.
''';

        final collection = parser.parse(content);
        final requirements = collection.stories.first.relatedRequirements;

        expect(requirements, contains('FR-001'));
        expect(requirements, contains('FR-002'));
        expect(requirements, contains('FR-003'));
      });
    });

    group('parseOne', () {
      test('debe parsear una sola User Story', () {
        const content = '''
### US-001: Single Story (Priority: P1 - MVP)

**Como** developer
**Quiero** parsear historias
**Para** automatizar

#### Criterios de Aceptacion
- [ ] AC-001: Given markdown When parse Then objeto

#### Test Independiente
Si - Sin dependencias
''';

        final story = parser.parseOne(content);

        expect(story, isNotNull);
        expect(story!.id, equals('US-001'));
        expect(story.title, equals('Single Story'));
        expect(story.priority, equals(Priority.p1));
        expect(story.asA, equals('developer'));
        expect(story.iWant, equals('parsear historias'));
        expect(story.soThat, equals('automatizar'));
      });

      test('debe retornar null para contenido invalido', () {
        const content = 'Este no es un formato valido de User Story';

        final story = parser.parseOne(content);

        expect(story, isNull);
      });
    });

    group('validate', () {
      test('debe validar User Story completa sin errores', () {
        const story = UserStory(
          id: 'US-001',
          title: 'Complete Story',
          priority: Priority.p1,
          asA: 'user',
          iWant: 'feature',
          soThat: 'benefit',
          acceptanceCriteria: [
            AcceptanceCriteria(
              id: 'AC-001',
              given: 'context',
              when: 'action',
              then: 'result',
            ),
          ],
        );

        final errors = parser.validate(story);

        expect(errors, isEmpty);
      });

      test('debe detectar campos faltantes', () {
        const story = UserStory(
          id: '',
          title: '',
          priority: Priority.p1,
          asA: '',
          iWant: '',
          soThat: '',
        );

        final errors = parser.validate(story);

        expect(errors, contains('ID es requerido'));
        expect(errors, contains('Titulo es requerido'));
        expect(errors, contains('Campo "Como" es requerido'));
        expect(errors, contains('Campo "Quiero" es requerido'));
        expect(errors, contains('Campo "Para" es requerido'));
        expect(
          errors,
          contains('Al menos un criterio de aceptacion es requerido'),
        );
      });

      test('debe validar criterios de aceptacion incompletos', () {
        const story = UserStory(
          id: 'US-001',
          title: 'Test',
          priority: Priority.p1,
          asA: 'user',
          iWant: 'test',
          soThat: 'verify',
          acceptanceCriteria: [
            AcceptanceCriteria(
              id: 'AC-001',
              given: '',
              when: '',
              then: '',
            ),
          ],
        );

        final errors = parser.validate(story);

        expect(errors, contains('Criterio AC-001: Given es requerido'));
        expect(errors, contains('Criterio AC-001: When es requerido'));
        expect(errors, contains('Criterio AC-001: Then es requerido'));
      });
    });

    group('validateCollection', () {
      test('debe validar coleccion sin MVP', () {
        const collection = UserStoryCollection([
          UserStory(
            id: 'US-001',
            title: 'P2 Only',
            priority: Priority.p2,
            asA: 'user',
            iWant: 'feature',
            soThat: 'benefit',
            acceptanceCriteria: [
              AcceptanceCriteria(
                id: 'AC-001',
                given: 'x',
                when: 'y',
                then: 'z',
              ),
            ],
          ),
        ]);

        final errors = parser.validateCollection(collection);

        expect(errors['_collection'], isNotNull);
        expect(
          errors['_collection'],
          contains('Al menos una User Story debe ser P1 (MVP)'),
        );
      });

      test('debe detectar IDs duplicados', () {
        const collection = UserStoryCollection([
          UserStory(
            id: 'US-001',
            title: 'First',
            priority: Priority.p1,
            asA: 'user',
            iWant: 'feature',
            soThat: 'benefit',
            acceptanceCriteria: [
              AcceptanceCriteria(
                id: 'AC-001',
                given: 'x',
                when: 'y',
                then: 'z',
              ),
            ],
          ),
          UserStory(
            id: 'US-001',
            title: 'Duplicate',
            priority: Priority.p2,
            asA: 'user',
            iWant: 'other',
            soThat: 'thing',
            acceptanceCriteria: [
              AcceptanceCriteria(
                id: 'AC-002',
                given: 'a',
                when: 'b',
                then: 'c',
              ),
            ],
          ),
        ]);

        final errors = parser.validateCollection(collection);

        expect(errors['_collection'], isNotNull);
        expect(
          errors['_collection']!.any((e) => e.contains('IDs duplicados')),
          isTrue,
        );
      });
    });

    group('toMarkdown', () {
      test('debe generar markdown agrupado por prioridad', () {
        const collection = UserStoryCollection([
          UserStory(
            id: 'US-001',
            title: 'MVP',
            priority: Priority.p1,
            asA: 'user',
            iWant: 'core',
            soThat: 'value',
            acceptanceCriteria: [
              AcceptanceCriteria(
                id: 'AC-001',
                given: 'x',
                when: 'y',
                then: 'z',
              ),
            ],
          ),
          UserStory(
            id: 'US-002',
            title: 'Nice',
            priority: Priority.p3,
            asA: 'user',
            iWant: 'extra',
            soThat: 'nice',
            acceptanceCriteria: [
              AcceptanceCriteria(
                id: 'AC-002',
                given: 'a',
                when: 'b',
                then: 'c',
              ),
            ],
          ),
        ]);

        final markdown = parser.toMarkdown(collection);

        expect(markdown, contains('## User Stories'));
        expect(markdown, contains('### P1 - MVP'));
        expect(markdown, contains('### P3 - Nice-to-have'));
        expect(markdown, contains('US-001'));
        expect(markdown, contains('US-002'));
      });
    });

    group('generateSummary', () {
      test('debe generar tabla de resumen', () {
        const collection = UserStoryCollection([
          UserStory(
            id: 'US-001',
            title: 'Feature One',
            priority: Priority.p1,
            asA: 'user',
            iWant: 'feature',
            soThat: 'benefit',
            acceptanceCriteria: [
              AcceptanceCriteria(
                id: 'AC-001',
                given: 'x',
                when: 'y',
                then: 'z',
                isCompleted: true,
              ),
              AcceptanceCriteria(
                id: 'AC-002',
                given: 'a',
                when: 'b',
                then: 'c',
              ),
            ],
          ),
        ]);

        final summary = parser.generateSummary(collection);

        expect(summary, contains('## Resumen de User Stories'));
        expect(summary, contains('| ID | Titulo | Prioridad | Criterios |'));
        expect(summary, contains('US-001'));
        expect(summary, contains('Feature One'));
        expect(summary, contains('P1'));
        expect(summary, contains('**MVP Stories**: 1'));
        expect(summary, contains('**Total Criterios**: 2'));
      });
    });
  });
}
