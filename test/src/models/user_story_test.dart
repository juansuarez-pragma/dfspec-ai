import 'package:dfspec/src/models/user_story.dart';
import 'package:test/test.dart';

void main() {
  group('Priority', () {
    test('debe tener codigo y label correctos', () {
      expect(Priority.p1.code, equals('P1'));
      expect(Priority.p1.label, equals('MVP'));
      expect(Priority.p2.code, equals('P2'));
      expect(Priority.p2.label, equals('Important'));
      expect(Priority.p3.code, equals('P3'));
      expect(Priority.p3.label, equals('Nice-to-have'));
    });

    group('tryParse', () {
      test('debe parsear P1 en diferentes formatos', () {
        expect(Priority.tryParse('P1'), equals(Priority.p1));
        expect(Priority.tryParse('p1'), equals(Priority.p1));
        expect(Priority.tryParse('P1 - MVP'), equals(Priority.p1));
        expect(Priority.tryParse('MVP'), equals(Priority.p1));
      });

      test('debe parsear P2 en diferentes formatos', () {
        expect(Priority.tryParse('P2'), equals(Priority.p2));
        expect(Priority.tryParse('p2'), equals(Priority.p2));
        expect(Priority.tryParse('Important'), equals(Priority.p2));
      });

      test('debe parsear P3 en diferentes formatos', () {
        expect(Priority.tryParse('P3'), equals(Priority.p3));
        expect(Priority.tryParse('p3'), equals(Priority.p3));
        expect(Priority.tryParse('Nice-to-have'), equals(Priority.p3));
      });

      test('debe retornar null para formato invalido', () {
        expect(Priority.tryParse('invalid'), isNull);
        expect(Priority.tryParse('P4'), isNull);
        expect(Priority.tryParse(''), isNull);
      });
    });

    test('toString debe incluir codigo y label', () {
      expect(Priority.p1.toString(), equals('P1 - MVP'));
    });
  });

  group('AcceptanceCriteria', () {
    test('debe crear instancia correctamente', () {
      const criteria = AcceptanceCriteria(
        id: 'AC-001',
        given: 'usuario autenticado',
        when: 'accede al dashboard',
        then: 've sus datos',
      );

      expect(criteria.id, equals('AC-001'));
      expect(criteria.given, equals('usuario autenticado'));
      expect(criteria.when, equals('accede al dashboard'));
      expect(criteria.then, equals('ve sus datos'));
      expect(criteria.isCompleted, isFalse);
    });

    test('debe crear desde mapa', () {
      final criteria = AcceptanceCriteria.fromMap(const {
        'id': 'AC-002',
        'given': 'contexto',
        'when': 'accion',
        'then': 'resultado',
        'is_completed': true,
      });

      expect(criteria.id, equals('AC-002'));
      expect(criteria.isCompleted, isTrue);
    });

    test('debe convertir a mapa', () {
      const criteria = AcceptanceCriteria(
        id: 'AC-001',
        given: 'contexto',
        when: 'accion',
        then: 'resultado',
      );

      final map = criteria.toMap();

      expect(map['id'], equals('AC-001'));
      expect(map['given'], equals('contexto'));
      expect(map['when'], equals('accion'));
      expect(map['then'], equals('resultado'));
      expect(map['is_completed'], isFalse);
    });

    test('toGherkin debe generar formato correcto', () {
      const criteria = AcceptanceCriteria(
        id: 'AC-001',
        given: 'usuario logueado',
        when: 'hace click en logout',
        then: 'cierra sesion',
      );

      final gherkin = criteria.toGherkin();

      expect(gherkin, contains('Given usuario logueado'));
      expect(gherkin, contains('When hace click en logout'));
      expect(gherkin, contains('Then cierra sesion'));
    });

    test('copyWith debe crear copia con modificaciones', () {
      const original = AcceptanceCriteria(
        id: 'AC-001',
        given: 'contexto',
        when: 'accion',
        then: 'resultado',
      );

      final modified = original.copyWith(isCompleted: true);

      expect(modified.id, equals('AC-001'));
      expect(modified.isCompleted, isTrue);
      expect(original.isCompleted, isFalse);
    });

    test('debe tener igualdad por valor', () {
      const criteria1 = AcceptanceCriteria(
        id: 'AC-001',
        given: 'contexto',
        when: 'accion',
        then: 'resultado',
      );

      const criteria2 = AcceptanceCriteria(
        id: 'AC-001',
        given: 'contexto',
        when: 'accion',
        then: 'resultado',
      );

      expect(criteria1, equals(criteria2));
      expect(criteria1.hashCode, equals(criteria2.hashCode));
    });
  });

  group('UserStory', () {
    late UserStory story;

    setUp(() {
      story = const UserStory(
        id: 'US-001',
        title: 'Login de usuario',
        priority: Priority.p1,
        asA: 'usuario registrado',
        iWant: 'iniciar sesion',
        soThat: 'acceder a mi cuenta',
        acceptanceCriteria: [
          AcceptanceCriteria(
            id: 'AC-001',
            given: 'credenciales validas',
            when: 'hace login',
            then: 'accede al sistema',
          ),
          AcceptanceCriteria(
            id: 'AC-002',
            given: 'credenciales invalidas',
            when: 'hace login',
            then: 've error',
            isCompleted: true,
          ),
        ],
        relatedRequirements: ['FR-001', 'FR-002'],
      );
    });

    test('debe crear instancia correctamente', () {
      expect(story.id, equals('US-001'));
      expect(story.title, equals('Login de usuario'));
      expect(story.priority, equals(Priority.p1));
      expect(story.asA, equals('usuario registrado'));
      expect(story.iWant, equals('iniciar sesion'));
      expect(story.soThat, equals('acceder a mi cuenta'));
      expect(story.acceptanceCriteria.length, equals(2));
      expect(story.relatedRequirements, contains('FR-001'));
    });

    test('isMvp debe retornar true para P1', () {
      expect(story.isMvp, isTrue);

      const p2Story = UserStory(
        id: 'US-002',
        title: 'Feature P2',
        priority: Priority.p2,
        asA: 'usuario',
        iWant: 'algo',
        soThat: 'beneficio',
      );

      expect(p2Story.isMvp, isFalse);
    });

    test('completedCriteriaCount debe contar correctamente', () {
      expect(story.completedCriteriaCount, equals(1));
    });

    test('completionPercentage debe calcular correctamente', () {
      expect(story.completionPercentage, equals(0.5));
    });

    test('completionPercentage debe ser 0 si no hay criterios', () {
      const emptyStory = UserStory(
        id: 'US-003',
        title: 'Sin criterios',
        priority: Priority.p1,
        asA: 'usuario',
        iWant: 'algo',
        soThat: 'beneficio',
      );

      expect(emptyStory.completionPercentage, equals(0.0));
    });

    test('isFullyAccepted debe verificar completitud', () {
      expect(story.isFullyAccepted, isFalse);

      const fullyAccepted = UserStory(
        id: 'US-004',
        title: 'Completa',
        priority: Priority.p1,
        asA: 'usuario',
        iWant: 'algo',
        soThat: 'beneficio',
        acceptanceCriteria: [
          AcceptanceCriteria(
            id: 'AC-001',
            given: 'x',
            when: 'y',
            then: 'z',
            isCompleted: true,
          ),
        ],
      );

      expect(fullyAccepted.isFullyAccepted, isTrue);
    });

    test('debe crear desde mapa', () {
      final map = {
        'id': 'US-005',
        'title': 'Test Story',
        'priority': 'P2',
        'as_a': 'developer',
        'i_want': 'test',
        'so_that': 'quality',
        'acceptance_criteria': [
          {
            'id': 'AC-001',
            'given': 'setup',
            'when': 'run',
            'then': 'pass',
          },
        ],
        'related_requirements': ['FR-001'],
      };

      final parsed = UserStory.fromMap(map);

      expect(parsed.id, equals('US-005'));
      expect(parsed.priority, equals(Priority.p2));
      expect(parsed.acceptanceCriteria.length, equals(1));
    });

    test('debe convertir a mapa', () {
      final map = story.toMap();

      expect(map['id'], equals('US-001'));
      expect(map['priority'], equals('P1'));
      expect(map['as_a'], equals('usuario registrado'));
      expect(map['acceptance_criteria'], isA<List<Map<String, dynamic>>>());
    });

    test('toStoryFormat debe generar markdown correcto', () {
      final markdown = story.toStoryFormat();

      expect(markdown, contains('### US-001: Login de usuario'));
      expect(markdown, contains('Priority: P1'));
      expect(markdown, contains('**Como** usuario registrado'));
      expect(markdown, contains('**Quiero** iniciar sesion'));
      expect(markdown, contains('**Para** acceder a mi cuenta'));
      expect(markdown, contains('AC-001'));
    });

    test('copyWith debe crear copia con modificaciones', () {
      final modified = story.copyWith(priority: Priority.p3);

      expect(modified.id, equals('US-001'));
      expect(modified.priority, equals(Priority.p3));
      expect(story.priority, equals(Priority.p1));
    });

    test('debe tener igualdad por id, title y priority', () {
      const story1 = UserStory(
        id: 'US-001',
        title: 'Test',
        priority: Priority.p1,
        asA: 'a',
        iWant: 'b',
        soThat: 'c',
      );

      const story2 = UserStory(
        id: 'US-001',
        title: 'Test',
        priority: Priority.p1,
        asA: 'different',
        iWant: 'different',
        soThat: 'different',
      );

      expect(story1, equals(story2));
    });
  });

  group('UserStoryCollection', () {
    late UserStoryCollection collection;

    setUp(() {
      collection = const UserStoryCollection([
        UserStory(
          id: 'US-001',
          title: 'MVP Feature',
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
          ],
          relatedRequirements: ['FR-001'],
        ),
        UserStory(
          id: 'US-002',
          title: 'P2 Feature',
          priority: Priority.p2,
          asA: 'user',
          iWant: 'another',
          soThat: 'more',
          acceptanceCriteria: [
            AcceptanceCriteria(
              id: 'AC-002',
              given: 'a',
              when: 'b',
              then: 'c',
            ),
          ],
        ),
        UserStory(
          id: 'US-003',
          title: 'Nice to have',
          priority: Priority.p3,
          asA: 'user',
          iWant: 'extra',
          soThat: 'nice',
        ),
      ]);
    });

    test('mvpStories debe filtrar solo P1', () {
      final mvp = collection.mvpStories;

      expect(mvp.length, equals(1));
      expect(mvp.first.id, equals('US-001'));
    });

    test('p2Stories debe filtrar solo P2', () {
      final p2 = collection.p2Stories;

      expect(p2.length, equals(1));
      expect(p2.first.id, equals('US-002'));
    });

    test('p3Stories debe filtrar solo P3', () {
      final p3 = collection.p3Stories;

      expect(p3.length, equals(1));
      expect(p3.first.id, equals('US-003'));
    });

    test('byPriority debe agrupar correctamente', () {
      final grouped = collection.byPriority;

      expect(grouped[Priority.p1]?.length, equals(1));
      expect(grouped[Priority.p2]?.length, equals(1));
      expect(grouped[Priority.p3]?.length, equals(1));
    });

    test('totalCriteria debe contar todos los criterios', () {
      expect(collection.totalCriteria, equals(2));
    });

    test('completedCriteria debe contar criterios completados', () {
      expect(collection.completedCriteria, equals(1));
    });

    test('overallCompletion debe calcular porcentaje global', () {
      expect(collection.overallCompletion, equals(0.5));
    });

    test('findById debe encontrar story por ID', () {
      final found = collection.findById('US-002');

      expect(found, isNotNull);
      expect(found!.title, equals('P2 Feature'));
    });

    test('findById debe retornar null si no existe', () {
      final notFound = collection.findById('US-999');

      expect(notFound, isNull);
    });

    test('findByRequirement debe encontrar stories relacionadas', () {
      final related = collection.findByRequirement('FR-001');

      expect(related.length, equals(1));
      expect(related.first.id, equals('US-001'));
    });

    test('isMvpComplete debe verificar completitud de MVP', () {
      expect(collection.isMvpComplete, isTrue);
    });

    test('debe crear desde lista de mapas', () {
      final fromList = UserStoryCollection.fromList(const [
        {
          'id': 'US-001',
          'title': 'Test',
          'priority': 'P1',
          'as_a': 'user',
          'i_want': 'test',
          'so_that': 'verify',
        },
      ]);

      expect(fromList.stories.length, equals(1));
    });

    test('toList debe convertir a lista de mapas', () {
      final list = collection.toList();

      expect(list.length, equals(3));
      expect(list.first['id'], equals('US-001'));
    });
  });
}
