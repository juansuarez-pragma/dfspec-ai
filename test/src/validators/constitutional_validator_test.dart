import 'package:dfspec/src/models/constitutional_gate.dart';
import 'package:dfspec/src/validators/constitutional_validator.dart';
import 'package:test/test.dart';

void main() {
  late ConstitutionalValidator validator;

  setUp(() {
    validator = const ConstitutionalValidator();
  });

  group('ConstitutionalValidator', () {
    group('validateCleanArchitectureImports', () {
      test('debe pasar cuando domain no importa data ni presentation', () {
        const content = '''
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

class City extends Equatable {
  const City({required this.id, required this.name});
  final int id;
  final String name;
  @override
  List<Object?> get props => [id, name];
}
''';

        final result = validator.validateCleanArchitectureImports(
          content,
          'lib/src/domain/entities/city.dart',
        );

        expect(result.isPassed, isTrue);
        expect(result.gateId, equals('clean-architecture'));
      });

      test('debe fallar cuando domain importa data', () {
        const content = '''
import 'package:myapp/src/data/models/city_model.dart';

class CityRepository {}
''';

        final result = validator.validateCleanArchitectureImports(
          content,
          'lib/src/domain/repositories/city_repository.dart',
        );

        expect(result.isFailed, isTrue);
        expect(result.message, contains('Clean Architecture'));
        expect(result.details, isNotEmpty);
      });

      test('debe fallar cuando domain importa presentation', () {
        const content = '''
import 'package:myapp/src/presentation/widgets/city_widget.dart';

class CityUseCase {}
''';

        final result = validator.validateCleanArchitectureImports(
          content,
          'lib/src/domain/usecases/city_usecase.dart',
        );

        expect(result.isFailed, isTrue);
        expect(result.details.any((d) => d.contains('presentation')), isTrue);
      });

      test('debe ser notApplicable fuera de domain', () {
        const content = '''
import 'package:myapp/src/domain/entities/city.dart';
''';

        final result = validator.validateCleanArchitectureImports(
          content,
          'lib/src/data/models/city_model.dart',
        );

        expect(result.status, equals(GateStatus.notApplicable));
      });
    });

    group('validateImmutableEntity', () {
      test('debe pasar para entidad inmutable con Equatable', () {
        const content = '''
import 'package:equatable/equatable.dart';

class City extends Equatable {
  const City({required this.id, required this.name});

  final int id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
''';

        final result = validator.validateImmutableEntity(
          content,
          'lib/src/domain/entities/city.dart',
        );

        expect(result.isPassed, isTrue);
      });

      test('debe fallar si tiene setter', () {
        const content = '''
import 'package:equatable/equatable.dart';

class City extends Equatable {
  City({required this.id, required this.name});

  final int id;
  String name;

  set name(String value) {
    name = value;
  }

  @override
  List<Object?> get props => [id, name];
}
''';

        final result = validator.validateImmutableEntity(
          content,
          'lib/src/domain/entities/city.dart',
        );

        expect(result.isFailed, isTrue);
        expect(result.details.any((d) => d.contains('Setter')), isTrue);
      });

      test('debe fallar si no extiende Equatable', () {
        const content = '''
class City {
  const City({required this.id, required this.name});

  final int id;
  final String name;
}
''';

        final result = validator.validateImmutableEntity(
          content,
          'lib/src/domain/entities/city.dart',
        );

        expect(result.isFailed, isTrue);
        expect(
          result.details.any((d) => d.contains('Equatable')),
          isTrue,
        );
      });

      test('debe ser notApplicable fuera de entities', () {
        const content = '''
class CityModel {}
''';

        final result = validator.validateImmutableEntity(
          content,
          'lib/src/data/models/city_model.dart',
        );

        expect(result.status, equals(GateStatus.notApplicable));
      });
    });

    group('validateTestCorrespondence', () {
      test('debe pasar si test existe', () {
        final result = validator.validateTestCorrespondence(
          'lib/src/domain/entities/city.dart',
          true,
        );

        expect(result.status, equals(GateStatus.passed));
        expect(result.gateId, equals('tdd'));
      });

      test('debe fallar si test no existe', () {
        final result = validator.validateTestCorrespondence(
          'lib/src/domain/entities/city.dart',
          false,
        );

        expect(result.status, equals(GateStatus.failed));
        expect(result.message, contains('test no encontrado'));
      });

      test('debe ser notApplicable fuera de lib/', () {
        final result = validator.validateTestCorrespondence(
          'test/src/domain/city_test.dart',
          false,
        );

        expect(result.status, equals(GateStatus.notApplicable));
      });
    });

    group('validate', () {
      test('debe ejecutar todos los gates por defecto', () {
        const content = '''
class SomeClass {}
''';

        final report = validator.validate(
          content: content,
          filePath: 'lib/src/utils/helper.dart',
        );

        expect(report.results, isNotEmpty);
        expect(report.context, equals('lib/src/utils/helper.dart'));
      });

      test('debe ejecutar solo gates especificados', () {
        const content = '''
class SomeClass {}
''';

        final report = validator.validate(
          content: content,
          filePath: 'lib/src/domain/entities/city.dart',
          gates: [ConstitutionalGates.cleanArchitecture],
        );

        expect(report.results.length, equals(1));
        expect(report.results.first.gateId, equals('clean-architecture'));
      });
    });

    group('validateCritical', () {
      test('debe ejecutar solo gates criticos', () {
        const content = '''
class SomeClass {}
''';

        final report = validator.validateCritical(
          content: content,
          filePath: 'lib/src/domain/entities/city.dart',
        );

        // Los criticos son 6
        expect(report.results.length, equals(6));
        expect(
          report.results.every(
            (r) =>
                ConstitutionalGates.critical
                    .any((g) => g.id == r.gateId) ||
                r.status == GateStatus.notApplicable,
          ),
          isTrue,
        );
      });
    });

    group('_gateApplies', () {
      test('clean-architecture aplica solo a domain/', () {
        final reportDomain = validator.validate(
          content: 'class Test {}',
          filePath: 'lib/src/domain/entities/test.dart',
          gates: [ConstitutionalGates.cleanArchitecture],
        );

        final reportData = validator.validate(
          content: 'class Test {}',
          filePath: 'lib/src/data/models/test.dart',
          gates: [ConstitutionalGates.cleanArchitecture],
        );

        // En domain, se aplica
        expect(
          reportDomain.results.first.status,
          isNot(equals(GateStatus.notApplicable)),
        );

        // Fuera de domain, no aplica
        expect(
          reportData.results.first.status,
          equals(GateStatus.notApplicable),
        );
      });

      test('tdd aplica solo a archivos de produccion', () {
        final reportLib = validator.validate(
          content: 'class Test {}',
          filePath: 'lib/src/utils/helper.dart',
          gates: [ConstitutionalGates.tdd],
        );

        final reportTest = validator.validate(
          content: 'class Test {}',
          filePath: 'test/unit/helper_test.dart',
          gates: [ConstitutionalGates.tdd],
        );

        expect(
          reportLib.results.first.status,
          isNot(equals(GateStatus.notApplicable)),
        );

        expect(
          reportTest.results.first.status,
          equals(GateStatus.notApplicable),
        );
      });

      test('immutable-entities aplica solo a domain/entities/', () {
        final reportEntities = validator.validate(
          content: 'class Test {}',
          filePath: 'lib/src/domain/entities/city.dart',
          gates: [ConstitutionalGates.immutableEntities],
        );

        final reportModels = validator.validate(
          content: 'class Test {}',
          filePath: 'lib/src/data/models/city_model.dart',
          gates: [ConstitutionalGates.immutableEntities],
        );

        expect(
          reportEntities.results.first.status,
          isNot(equals(GateStatus.notApplicable)),
        );

        expect(
          reportModels.results.first.status,
          equals(GateStatus.notApplicable),
        );
      });
    });
  });
}
