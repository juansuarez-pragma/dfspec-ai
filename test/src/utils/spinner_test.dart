import 'dart:convert';
import 'dart:io';
import 'package:dfspec/src/utils/spinner.dart';
import 'package:test/test.dart';

void main() {
  group('Spinner', () {
    late _MockIOSink mockOutput;

    setUp(() {
      mockOutput = _MockIOSink();
    });

    test('se crea con mensaje y estilo por defecto', () {
      final spinner = Spinner(
        message: 'Loading...',
        output: mockOutput,
      );

      expect(spinner.message, equals('Loading...'));
      expect(spinner.style, equals(SpinnerStyle.dots));
    });

    test('se puede crear con estilo personalizado', () {
      final spinner = Spinner(
        message: 'Working',
        style: SpinnerStyle.line,
        output: mockOutput,
      );

      expect(spinner.style, equals(SpinnerStyle.line));
    });

    test('success escribe mensaje con checkmark', () {
      final spinner = Spinner(
        message: 'Loading',
        output: mockOutput,
      );

      spinner.success('Done!');

      final output = mockOutput.written.join();
      expect(output, contains('✓'));
      expect(output, contains('Done!'));
    });

    test('fail escribe mensaje con X', () {
      final spinner = Spinner(
        message: 'Loading',
        output: mockOutput,
      );

      spinner.fail('Error occurred');

      final output = mockOutput.written.join();
      expect(output, contains('✗'));
      expect(output, contains('Error occurred'));
    });

    test('warn escribe mensaje con warning', () {
      final spinner = Spinner(
        message: 'Loading',
        output: mockOutput,
      );

      spinner.warn('Warning message');

      final output = mockOutput.written.join();
      expect(output, contains('⚠'));
      expect(output, contains('Warning message'));
    });

    test('info escribe mensaje con info icon', () {
      final spinner = Spinner(
        message: 'Loading',
        output: mockOutput,
      );

      spinner.info('Info message');

      final output = mockOutput.written.join();
      expect(output, contains('ℹ'));
      expect(output, contains('Info message'));
    });
  });

  group('SpinnerStyle', () {
    test('dots tiene frames correctos', () {
      expect(SpinnerStyle.dots.frames, isNotEmpty);
      expect(SpinnerStyle.dots.interval, equals(80));
    });

    test('line tiene 4 frames', () {
      expect(SpinnerStyle.line.frames.length, equals(4));
      expect(SpinnerStyle.line.frames, contains('|'));
      expect(SpinnerStyle.line.frames, contains('/'));
    });

    test('todos los estilos tienen frames', () {
      for (final style in SpinnerStyle.values) {
        expect(style.frames, isNotEmpty);
        expect(style.interval, greaterThan(0));
      }
    });
  });

  group('ProgressBar', () {
    late _MockIOSink mockOutput;

    setUp(() {
      mockOutput = _MockIOSink();
    });

    test('se crea con total y width', () {
      final bar = ProgressBar(
        total: 100,
        width: 20,
        output: mockOutput,
      );

      expect(bar.total, equals(100));
      expect(bar.width, equals(20));
    });

    test('se puede crear con label', () {
      final bar = ProgressBar(
        total: 50,
        label: 'Downloading',
        output: mockOutput,
      );

      expect(bar.label, equals('Downloading'));
    });

    test('update cambia el progreso', () {
      final bar = ProgressBar(
        total: 100,
        output: mockOutput,
      );

      bar.start();
      bar.update(50);

      final output = mockOutput.written.join();
      expect(output, contains('50%'));
    });

    test('increment aumenta en 1 por defecto', () {
      final bar = ProgressBar(
        total: 10,
        output: mockOutput,
      );

      bar.start();
      bar.increment();
      bar.increment();

      final output = mockOutput.written.join();
      expect(output, contains('(2/10)'));
    });

    test('complete muestra 100%', () {
      final bar = ProgressBar(
        total: 100,
        output: mockOutput,
      );

      bar.start();
      bar.complete('Finished');

      final output = mockOutput.written.join();
      expect(output, contains('100%'));
      expect(output, contains('✓'));
      expect(output, contains('Finished'));
    });
  });

  group('TaskRunner', () {
    late _MockIOSink mockOutput;

    setUp(() {
      mockOutput = _MockIOSink();
    });

    test('ejecuta tareas en secuencia', () async {
      final runner = TaskRunner(output: mockOutput);
      final order = <int>[];

      runner.add('Task 1', () async {
        order.add(1);
      });
      runner.add('Task 2', () async {
        order.add(2);
      });

      await runner.run();

      expect(order, equals([1, 2]));
    });

    test('retorna resultado con conteo', () async {
      final runner = TaskRunner(output: mockOutput);

      runner.add('Success', () async {});
      runner.add('Another success', () async {});

      final result = await runner.run();

      expect(result.total, equals(2));
      expect(result.passed, equals(2));
      expect(result.failed, equals(0));
      expect(result.allPassed, isTrue);
    });

    test('maneja errores en tareas', () async {
      final runner = TaskRunner(output: mockOutput);

      runner.add('Success', () async {});
      runner.add('Fail', () async {
        throw Exception('Test error');
      });
      runner.add('Success 2', () async {});

      final result = await runner.run();

      expect(result.passed, equals(2));
      expect(result.failed, equals(1));
      expect(result.allPassed, isFalse);
    });

    test('muestra titulo si se proporciona', () async {
      final runner = TaskRunner(output: mockOutput);

      runner.add('Task', () async {});

      await runner.run(title: 'Running Tests');

      final output = mockOutput.written.join();
      expect(output, contains('Running Tests'));
    });
  });

  group('TaskRunnerResult', () {
    test('allPassed es true cuando failed es 0', () {
      const result = TaskRunnerResult(
        total: 5,
        passed: 5,
        failed: 0,
        results: {'Task 1': true, 'Task 2': true},
      );

      expect(result.allPassed, isTrue);
    });

    test('allPassed es false cuando hay fallos', () {
      const result = TaskRunnerResult(
        total: 5,
        passed: 3,
        failed: 2,
        results: {'Task 1': true, 'Task 2': false},
      );

      expect(result.allPassed, isFalse);
    });
  });
}

/// Mock de IOSink para testing.
class _MockIOSink implements IOSink {
  final List<String> written = [];

  @override
  void write(Object? object) {
    written.add(object.toString());
  }

  @override
  void writeln([Object? object = '']) {
    written.add('${object ?? ''}\n');
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) {
    written.add(objects.join(separator));
  }

  @override
  void writeCharCode(int charCode) {
    written.add(String.fromCharCode(charCode));
  }

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<dynamic> addStream(Stream<List<int>> stream) => Future.value();

  @override
  Future<dynamic> close() => Future.value();

  @override
  Future<dynamic> get done => Future.value();

  @override
  Encoding get encoding => utf8;

  @override
  set encoding(Encoding value) {}

  @override
  Future<dynamic> flush() => Future.value();
}
