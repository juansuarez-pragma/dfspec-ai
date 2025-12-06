import 'package:dfspec/src/models/models.dart';
import 'package:dfspec/src/templates/artifact_templates.dart';
import 'package:dfspec/src/utils/utils.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// Resultado de la generacion de especificacion.
@immutable
class GenerationResult {
  /// Crea un resultado exitoso.
  const GenerationResult.success({
    required this.filePath,
    required this.type,
    this.overwritten = false,
  })  : error = null,
        isSuccess = true;

  /// Crea un resultado con error.
  const GenerationResult.failure({
    required this.error,
    required this.type,
  })  : filePath = null,
        overwritten = false,
        isSuccess = false;

  /// Si la generacion fue exitosa.
  final bool isSuccess;

  /// Ruta del archivo generado.
  final String? filePath;

  /// Tipo de especificacion generada.
  final SpecType type;

  /// Si el archivo fue sobrescrito.
  final bool overwritten;

  /// Mensaje de error si fallo.
  final String? error;
}

/// Generador de especificaciones.
///
/// Crea archivos de especificacion basados en templates.
class SpecGenerator {
  /// Crea un nuevo generador.
  const SpecGenerator({
    this.baseDir = '.',
  });

  /// Directorio base para generar archivos.
  final String baseDir;

  /// Genera una especificacion.
  ///
  /// [type] - Tipo de especificacion a generar.
  /// [name] - Nombre para la especificacion.
  /// [variables] - Variables para reemplazar en el template.
  /// [overwrite] - Si debe sobrescribir archivos existentes.
  /// [customDir] - Directorio personalizado (opcional).
  Future<GenerationResult> generate({
    required SpecType type,
    required String name,
    Map<String, String> variables = const {},
    bool overwrite = false,
    String? customDir,
  }) async {
    try {
      // Obtener template
      final template = ArtifactTemplates.getTemplate(type);

      // Preparar variables: primero defaults, luego valores especificos
      final allVariables = <String, String>{
        ...template.variables,
        'title': name,
        'date': _formatDate(DateTime.now()),
        ...variables,
      };

      // Renderizar contenido
      final content = template.render(allVariables);

      // Determinar ruta del archivo
      final directory = customDir ?? template.suggestedDirectory();
      final filename = template.suggestedFilename(name);
      final filePath = p.join(baseDir, directory, filename);

      // Verificar si existe
      final exists = FileUtils.fileExists(filePath);
      if (exists && !overwrite) {
        return GenerationResult.failure(
          type: type,
          error: 'El archivo ya existe: $filePath. '
              'Usa --force para sobrescribir.',
        );
      }

      // Crear directorio si no existe
      await FileUtils.ensureDirectory(p.dirname(filePath));

      // Escribir archivo
      await FileUtils.writeFile(filePath, content, overwrite: overwrite);

      return GenerationResult.success(
        filePath: filePath,
        type: type,
        overwritten: exists,
      );
    } catch (e) {
      return GenerationResult.failure(
        type: type,
        error: 'Error al generar especificacion: $e',
      );
    }
  }

  /// Genera multiples especificaciones.
  Future<List<GenerationResult>> generateMultiple({
    required List<SpecType> types,
    required String name,
    Map<String, String> variables = const {},
    bool overwrite = false,
  }) async {
    final results = <GenerationResult>[];

    for (final type in types) {
      final result = await generate(
        type: type,
        name: name,
        variables: variables,
        overwrite: overwrite,
      );
      results.add(result);
    }

    return results;
  }

  /// Lista las especificaciones existentes.
  List<String> listExisting(SpecType type) {
    final template = ArtifactTemplates.getTemplate(type);
    final directory = p.join(baseDir, template.suggestedDirectory());

    return FileUtils.listFiles(directory, extension: '.md')
        .map((f) => p.basename(f.path))
        .where((name) => name.endsWith('.${type.value}.md'))
        .toList();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${_pad(date.month)}-${_pad(date.day)}';
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}
