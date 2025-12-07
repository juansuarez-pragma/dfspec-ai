import 'dart:convert';
import 'dart:io';

/// Mixin para facilitar salida JSON en comandos CLI.
///
/// Proporciona métodos estandarizados para:
/// - Formatear JSON con indentación
/// - Escribir a stdout/archivo
/// - Crear respuestas de éxito/error
///
/// Ejemplo:
/// ```dart
/// class MyCommand extends Command<int> with JsonOutputMixin {
///   @override
///   Future<int> run() async {
///     if (useJsonOutput) {
///       writeJsonSuccess({'result': 'done'});
///     }
///     return 0;
///   }
/// }
/// ```
mixin JsonOutputMixin {
  /// Encoder JSON con indentación de 2 espacios.
  static const JsonEncoder _prettyEncoder = JsonEncoder.withIndent('  ');

  /// Encoder JSON compacto.
  static const JsonEncoder _compactEncoder = JsonEncoder();

  /// Formatea un objeto a JSON con indentación.
  String formatJson(Object? data, {bool pretty = true}) {
    final encoder = pretty ? _prettyEncoder : _compactEncoder;
    return encoder.convert(data);
  }

  /// Escribe JSON a stdout con formato.
  void writeJson(Object? data, {bool pretty = true}) {
    stdout.writeln(formatJson(data, pretty: pretty));
  }

  /// Escribe una respuesta de éxito estandarizada.
  ///
  /// Formato:
  /// ```json
  /// {
  ///   "status": "success",
  ///   "data": { ... }
  /// }
  /// ```
  void writeJsonSuccess(Object? data, {bool pretty = true}) {
    writeJson({
      'status': 'success',
      'data': data,
    }, pretty: pretty);
  }

  /// Escribe una respuesta de error estandarizada.
  ///
  /// Formato:
  /// ```json
  /// {
  ///   "status": "error",
  ///   "error": {
  ///     "code": "ERROR_CODE",
  ///     "message": "Error message"
  ///   }
  /// }
  /// ```
  void writeJsonError(
    String code,
    String message, {
    Map<String, dynamic>? details,
    bool pretty = true,
  }) {
    final error = <String, dynamic>{
      'code': code,
      'message': message,
    };
    if (details != null && details.isNotEmpty) {
      error['details'] = details;
    }

    writeJson({
      'status': 'error',
      'error': error,
    }, pretty: pretty);
  }

  /// Escribe una respuesta con lista de items.
  ///
  /// Formato:
  /// ```json
  /// {
  ///   "status": "success",
  ///   "count": 5,
  ///   "items": [ ... ]
  /// }
  /// ```
  void writeJsonList(
    List<dynamic> items, {
    String itemsKey = 'items',
    Map<String, dynamic>? metadata,
    bool pretty = true,
  }) {
    final data = <String, dynamic>{
      'status': 'success',
      'count': items.length,
      itemsKey: items,
    };
    if (metadata != null) {
      data.addAll(metadata);
    }
    writeJson(data, pretty: pretty);
  }

  /// Guarda JSON a un archivo.
  Future<void> saveJson(
    String path,
    Object? data, {
    bool pretty = true,
  }) async {
    final content = formatJson(data, pretty: pretty);
    await File(path).writeAsString(content);
  }

  /// Crea una respuesta de reporte estandarizada.
  ///
  /// Formato:
  /// ```json
  /// {
  ///   "status": "success",
  ///   "report": {
  ///     "generated_at": "2024-...",
  ///     "summary": { ... },
  ///     "details": { ... }
  ///   }
  /// }
  /// ```
  Map<String, dynamic> createReport({
    required Map<String, dynamic> summary,
    Map<String, dynamic>? details,
    DateTime? generatedAt,
  }) {
    return {
      'status': 'success',
      'report': {
        'generated_at': (generatedAt ?? DateTime.now()).toIso8601String(),
        'summary': summary,
        if (details != null) 'details': details,
      },
    };
  }

  /// Valida y parsea JSON desde un string.
  ///
  /// Retorna null si el JSON es inválido.
  Map<String, dynamic>? parseJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } on FormatException {
      return null;
    }
  }

  /// Verifica si un string es JSON válido.
  bool isValidJson(String jsonString) {
    try {
      jsonDecode(jsonString);
      return true;
    } on FormatException {
      return false;
    }
  }

  /// Merge de múltiples objetos JSON.
  Map<String, dynamic> mergeJson(List<Map<String, dynamic>> objects) {
    final result = <String, dynamic>{};
    for (final obj in objects) {
      result.addAll(obj);
    }
    return result;
  }
}

/// Clase utilitaria para operaciones JSON estáticas.
abstract final class JsonOutput {
  /// Encoder JSON con indentación.
  static const JsonEncoder prettyEncoder = JsonEncoder.withIndent('  ');

  /// Encoder JSON compacto.
  static const JsonEncoder compactEncoder = JsonEncoder();

  /// Formatea un objeto a JSON.
  static String format(Object? data, {bool pretty = true}) {
    final encoder = pretty ? prettyEncoder : compactEncoder;
    return encoder.convert(data);
  }

  /// Crea una respuesta de éxito.
  static Map<String, dynamic> success(Object? data) {
    return {
      'status': 'success',
      'data': data,
    };
  }

  /// Crea una respuesta de error.
  static Map<String, dynamic> error(String code, String message) {
    return {
      'status': 'error',
      'error': {
        'code': code,
        'message': message,
      },
    };
  }

  /// Parsea JSON de forma segura.
  static T? tryParse<T>(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is T) {
        return decoded;
      }
      return null;
    } on FormatException {
      return null;
    }
  }
}
