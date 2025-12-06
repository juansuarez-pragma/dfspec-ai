import 'dart:io';

import 'package:path/path.dart' as p;

/// Utilidades para manejo de archivos y directorios.
class FileUtils {
  const FileUtils._();

  /// Crea un directorio si no existe.
  ///
  /// Retorna true si el directorio fue creado, false si ya existia.
  static Future<bool> ensureDirectory(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
      return true;
    }
    return false;
  }

  /// Escribe contenido a un archivo.
  ///
  /// Crea los directorios padres si no existen.
  /// Retorna true si el archivo fue creado, false si fue sobrescrito.
  static Future<bool> writeFile(
    String path,
    String content, {
    bool overwrite = false,
  }) async {
    final file = File(path);
    final exists = file.existsSync();

    if (exists && !overwrite) {
      return false;
    }

    await ensureDirectory(p.dirname(path));
    await file.writeAsString(content);
    return !exists;
  }

  /// Lee el contenido de un archivo.
  ///
  /// Retorna null si el archivo no existe.
  static Future<String?> readFile(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      return null;
    }
    return file.readAsString();
  }

  /// Verifica si un archivo existe.
  static bool fileExists(String path) {
    return File(path).existsSync();
  }

  /// Verifica si un directorio existe.
  static bool directoryExists(String path) {
    return Directory(path).existsSync();
  }

  /// Copia un archivo de origen a destino.
  ///
  /// Crea los directorios padres si no existen.
  static Future<void> copyFile(String source, String destination) async {
    await ensureDirectory(p.dirname(destination));
    await File(source).copy(destination);
  }

  /// Lista archivos en un directorio con un patron opcional.
  static List<File> listFiles(
    String directory, {
    String? extension,
    bool recursive = false,
  }) {
    final dir = Directory(directory);
    if (!dir.existsSync()) {
      return [];
    }

    return dir.listSync(recursive: recursive).whereType<File>().where((file) {
      if (extension == null) return true;
      return p.extension(file.path) == extension;
    }).toList();
  }

  /// Obtiene el nombre del directorio actual como nombre de proyecto.
  static String getCurrentDirectoryName() {
    return p.basename(Directory.current.path);
  }

  /// Resuelve una ruta relativa desde el directorio actual.
  static String resolvePath(String relativePath) {
    return p.normalize(p.join(Directory.current.path, relativePath));
  }
}
