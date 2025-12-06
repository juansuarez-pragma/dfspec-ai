import 'dart:io';

import 'package:dfspec/dfspec.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('FileUtils', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('dfspec_file_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('ensureDirectory', () {
      test('crea directorio si no existe', () async {
        final path = p.join(tempDir.path, 'nuevo', 'directorio');

        final created = await FileUtils.ensureDirectory(path);

        expect(created, isTrue);
        expect(Directory(path).existsSync(), isTrue);
      });

      test('retorna false si directorio existe', () async {
        final path = p.join(tempDir.path, 'existente');
        await Directory(path).create();

        final created = await FileUtils.ensureDirectory(path);

        expect(created, isFalse);
      });
    });

    group('writeFile', () {
      test('escribe archivo nuevo', () async {
        final path = p.join(tempDir.path, 'nuevo.txt');

        final created = await FileUtils.writeFile(path, 'contenido');

        expect(created, isTrue);
        expect(File(path).readAsStringSync(), equals('contenido'));
      });

      test('no sobrescribe sin overwrite', () async {
        final path = p.join(tempDir.path, 'existente.txt');
        await File(path).writeAsString('original');

        final created = await FileUtils.writeFile(path, 'nuevo');

        expect(created, isFalse);
        expect(File(path).readAsStringSync(), equals('original'));
      });

      test('sobrescribe con overwrite', () async {
        final path = p.join(tempDir.path, 'existente.txt');
        await File(path).writeAsString('original');

        final created = await FileUtils.writeFile(
          path,
          'nuevo',
          overwrite: true,
        );

        expect(created, isFalse);
        expect(File(path).readAsStringSync(), equals('nuevo'));
      });

      test('crea directorios padres', () async {
        final path = p.join(tempDir.path, 'a', 'b', 'c', 'archivo.txt');

        await FileUtils.writeFile(path, 'contenido');

        expect(File(path).existsSync(), isTrue);
      });
    });

    group('readFile', () {
      test('lee archivo existente', () async {
        final path = p.join(tempDir.path, 'leer.txt');
        await File(path).writeAsString('contenido');

        final content = await FileUtils.readFile(path);

        expect(content, equals('contenido'));
      });

      test('retorna null si no existe', () async {
        final path = p.join(tempDir.path, 'noexiste.txt');

        final content = await FileUtils.readFile(path);

        expect(content, isNull);
      });
    });

    group('fileExists', () {
      test('retorna true si existe', () async {
        final path = p.join(tempDir.path, 'existe.txt');
        await File(path).writeAsString('');

        expect(FileUtils.fileExists(path), isTrue);
      });

      test('retorna false si no existe', () {
        final path = p.join(tempDir.path, 'noexiste.txt');

        expect(FileUtils.fileExists(path), isFalse);
      });
    });

    group('directoryExists', () {
      test('retorna true si existe', () async {
        final path = p.join(tempDir.path, 'dir');
        await Directory(path).create();

        expect(FileUtils.directoryExists(path), isTrue);
      });

      test('retorna false si no existe', () {
        final path = p.join(tempDir.path, 'noexiste');

        expect(FileUtils.directoryExists(path), isFalse);
      });
    });

    group('listFiles', () {
      test('lista archivos en directorio', () async {
        await File(p.join(tempDir.path, 'a.txt')).writeAsString('');
        await File(p.join(tempDir.path, 'b.txt')).writeAsString('');

        final files = FileUtils.listFiles(tempDir.path);

        expect(files.length, equals(2));
      });

      test('filtra por extension', () async {
        await File(p.join(tempDir.path, 'a.txt')).writeAsString('');
        await File(p.join(tempDir.path, 'b.md')).writeAsString('');

        final files = FileUtils.listFiles(tempDir.path, extension: '.md');

        expect(files.length, equals(1));
        expect(files.first.path, endsWith('.md'));
      });

      test('retorna lista vacia si directorio no existe', () {
        final files = FileUtils.listFiles('/no/existe');

        expect(files, isEmpty);
      });
    });

    test('getCurrentDirectoryName retorna nombre', () {
      final name = FileUtils.getCurrentDirectoryName();

      expect(name, isNotEmpty);
    });

    test('resolvePath resuelve ruta relativa', () {
      final resolved = FileUtils.resolvePath('subdir/file.txt');

      expect(resolved, contains('subdir'));
      expect(resolved, contains('file.txt'));
    });
  });
}
