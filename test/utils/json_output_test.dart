import 'dart:convert';
import 'dart:io';

import 'package:dfspec/src/utils/json_output.dart';
import 'package:test/test.dart';

// Clase de prueba que usa el mixin
class TestJsonOutput with JsonOutputMixin {}

void main() {
  group('JsonOutputMixin', () {
    late TestJsonOutput testClass;

    setUp(() {
      testClass = TestJsonOutput();
    });

    group('formatJson', () {
      test('formatea objeto simple con pretty=true', () {
        final result = testClass.formatJson({'key': 'value'});
        expect(result, contains('\n'));
        expect(result, contains('  '));
        expect(result, contains('"key"'));
        expect(result, contains('"value"'));
      });

      test('formatea objeto simple con pretty=false', () {
        final result = testClass.formatJson({'key': 'value'}, pretty: false);
        expect(result, isNot(contains('\n')));
        expect(result, equals('{"key":"value"}'));
      });

      test('formatea lista', () {
        final result = testClass.formatJson([1, 2, 3]);
        expect(result, contains('1'));
        expect(result, contains('2'));
        expect(result, contains('3'));
      });

      test('formatea null', () {
        final result = testClass.formatJson(null);
        expect(result, equals('null'));
      });

      test('formatea objeto anidado', () {
        final result = testClass.formatJson({
          'level1': {
            'level2': {'key': 'value'},
          },
        });
        expect(result, contains('level1'));
        expect(result, contains('level2'));
        expect(result, contains('key'));
      });
    });

    group('parseJson', () {
      test('parsea JSON válido', () {
        final result = testClass.parseJson('{"key": "value"}');
        expect(result, isNotNull);
        expect(result!['key'], equals('value'));
      });

      test('retorna null para JSON inválido', () {
        final result = testClass.parseJson('not valid json');
        expect(result, isNull);
      });

      test('retorna null para array JSON', () {
        final result = testClass.parseJson('[1, 2, 3]');
        expect(result, isNull);
      });

      test('parsea JSON con caracteres especiales', () {
        final result = testClass.parseJson('{"key": "value with \\"quotes\\""}');
        expect(result, isNotNull);
        expect(result!['key'], contains('quotes'));
      });
    });

    group('isValidJson', () {
      test('retorna true para JSON válido', () {
        expect(testClass.isValidJson('{"key": "value"}'), isTrue);
        expect(testClass.isValidJson('[1, 2, 3]'), isTrue);
        expect(testClass.isValidJson('"string"'), isTrue);
        expect(testClass.isValidJson('123'), isTrue);
        expect(testClass.isValidJson('null'), isTrue);
      });

      test('retorna false para JSON inválido', () {
        expect(testClass.isValidJson('not json'), isFalse);
        expect(testClass.isValidJson('{invalid}'), isFalse);
        expect(testClass.isValidJson('{"key": }'), isFalse);
      });
    });

    group('mergeJson', () {
      test('merge múltiples objetos', () {
        final result = testClass.mergeJson([
          {'a': 1},
          {'b': 2},
          {'c': 3},
        ]);
        expect(result['a'], equals(1));
        expect(result['b'], equals(2));
        expect(result['c'], equals(3));
      });

      test('sobrescribe claves duplicadas', () {
        final result = testClass.mergeJson([
          {'key': 'first'},
          {'key': 'second'},
        ]);
        expect(result['key'], equals('second'));
      });

      test('funciona con lista vacía', () {
        final result = testClass.mergeJson([]);
        expect(result, isEmpty);
      });

      test('funciona con un solo objeto', () {
        final result = testClass.mergeJson([
          {'only': 'one'},
        ]);
        expect(result['only'], equals('one'));
      });
    });

    group('createReport', () {
      test('crea reporte con summary', () {
        final report = testClass.createReport(
          summary: {'total': 10, 'passed': 8},
        );

        expect(report['status'], equals('success'));
        expect(report['report'], isNotNull);
        expect(report['report']['summary']['total'], equals(10));
        expect(report['report']['generated_at'], isNotNull);
      });

      test('crea reporte con details', () {
        final report = testClass.createReport(
          summary: {'count': 5},
          details: {'items': [1, 2, 3]},
        );

        expect(report['report']['details'], isNotNull);
        expect(report['report']['details']['items'], hasLength(3));
      });

      test('usa fecha personalizada', () {
        final customDate = DateTime(2024, 1, 15, 10, 30);
        final report = testClass.createReport(
          summary: {},
          generatedAt: customDate,
        );

        expect(
          report['report']['generated_at'],
          equals('2024-01-15T10:30:00.000'),
        );
      });

      test('no incluye details si es null', () {
        final report = testClass.createReport(
          summary: {'key': 'value'},
        );

        expect(report['report'].containsKey('details'), isFalse);
      });
    });
  });

  group('JsonOutput (static)', () {
    group('format', () {
      test('formatea con pretty=true por defecto', () {
        final result = JsonOutput.format({'key': 'value'});
        expect(result, contains('\n'));
      });

      test('formatea con pretty=false', () {
        final result = JsonOutput.format({'key': 'value'}, pretty: false);
        expect(result, isNot(contains('\n')));
      });
    });

    group('success', () {
      test('crea respuesta de éxito', () {
        final result = JsonOutput.success({'data': 'test'});

        expect(result['status'], equals('success'));
        expect(result['data'], isNotNull);
        expect(result['data']['data'], equals('test'));
      });

      test('acepta cualquier tipo de data', () {
        expect(JsonOutput.success(null)['data'], isNull);
        expect(JsonOutput.success([1, 2, 3])['data'], equals([1, 2, 3]));
        expect(JsonOutput.success('string')['data'], equals('string'));
      });
    });

    group('error', () {
      test('crea respuesta de error', () {
        final result = JsonOutput.error('TEST_CODE', 'Test message');

        expect(result['status'], equals('error'));
        expect(result['error']['code'], equals('TEST_CODE'));
        expect(result['error']['message'], equals('Test message'));
      });
    });

    group('tryParse', () {
      test('parsea Map correctamente', () {
        final result = JsonOutput.tryParse<Map<String, dynamic>>(
          '{"key": "value"}',
        );
        expect(result, isNotNull);
        expect(result!['key'], equals('value'));
      });

      test('parsea List correctamente', () {
        final result = JsonOutput.tryParse<List<dynamic>>('[1, 2, 3]');
        expect(result, isNotNull);
        expect(result, hasLength(3));
      });

      test('retorna null para tipo incorrecto', () {
        final result = JsonOutput.tryParse<Map<String, dynamic>>('[1, 2, 3]');
        expect(result, isNull);
      });

      test('retorna null para JSON inválido', () {
        final result = JsonOutput.tryParse<Map<String, dynamic>>('invalid');
        expect(result, isNull);
      });

      test('parsea string', () {
        final result = JsonOutput.tryParse<String>('"hello"');
        expect(result, equals('hello'));
      });

      test('parsea número', () {
        final result = JsonOutput.tryParse<int>('42');
        expect(result, equals(42));
      });
    });

    group('encoders', () {
      test('prettyEncoder tiene indentación', () {
        final result = JsonOutput.prettyEncoder.convert({'key': 'value'});
        expect(result, contains('\n'));
        expect(result, contains('  '));
      });

      test('compactEncoder no tiene indentación', () {
        final result = JsonOutput.compactEncoder.convert({'key': 'value'});
        expect(result, isNot(contains('\n')));
      });
    });
  });

  group('Integration tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('json_output_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('saveJson escribe archivo correctamente', () async {
      final testClass = TestJsonOutput();
      final filePath = '${tempDir.path}/test.json';

      await testClass.saveJson(filePath, {'saved': true});

      final content = await File(filePath).readAsString();
      final decoded = jsonDecode(content) as Map<String, dynamic>;

      expect(decoded['saved'], isTrue);
    });

    test('saveJson escribe JSON formateado', () async {
      final testClass = TestJsonOutput();
      final filePath = '${tempDir.path}/pretty.json';

      await testClass.saveJson(filePath, {'key': 'value'}, pretty: true);

      final content = await File(filePath).readAsString();
      expect(content, contains('\n'));
      expect(content, contains('  '));
    });

    test('saveJson escribe JSON compacto', () async {
      final testClass = TestJsonOutput();
      final filePath = '${tempDir.path}/compact.json';

      await testClass.saveJson(filePath, {'key': 'value'}, pretty: false);

      final content = await File(filePath).readAsString();
      expect(content, isNot(contains('\n')));
    });
  });
}
