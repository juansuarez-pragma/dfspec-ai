/// Excepciones personalizadas para DFSpec.
///
/// Define una jerarquia de excepciones para manejo de errores
/// mas especifico y descriptivo.
library;

/// Excepcion base para todos los errores de DFSpec.
class DfspecException implements Exception {
  /// Crea una excepcion DFSpec con mensaje.
  const DfspecException(this.message);

  /// Mensaje descriptivo del error.
  final String message;

  @override
  String toString() => 'DfspecException: $message';
}

/// Error cuando no se encuentra el archivo de configuracion.
class ConfigNotFoundException extends DfspecException {
  /// Crea excepcion de configuracion no encontrada.
  const ConfigNotFoundException([String? path])
    : super(
        path != null
            ? 'dfspec.yaml no encontrado en: $path'
            : 'dfspec.yaml no encontrado',
      );
}

/// Error cuando la configuracion es invalida.
class InvalidConfigException extends DfspecException {
  /// Crea excepcion de configuracion invalida.
  const InvalidConfigException(super.message);

  /// Error de campo requerido faltante.
  factory InvalidConfigException.missingField(String field) =>
      InvalidConfigException('Campo requerido faltante: $field');

  /// Error de tipo incorrecto.
  factory InvalidConfigException.invalidType(String field, String expected) =>
      InvalidConfigException('$field debe ser de tipo $expected');
}

/// Error cuando un template no existe.
class TemplateNotFoundException extends DfspecException {
  /// Crea excepcion de template no encontrado.
  const TemplateNotFoundException(String templateName)
    : super('Template no encontrado: $templateName');
}

/// Error de operacion de archivo.
class FileOperationException extends DfspecException {
  /// Crea excepcion de operacion de archivo.
  const FileOperationException(super.message);

  /// Error al leer archivo.
  factory FileOperationException.read(String path, [String? detail]) =>
      FileOperationException(
        'Error al leer archivo: $path${detail != null ? ' - $detail' : ''}',
      );

  /// Error al escribir archivo.
  factory FileOperationException.write(String path, [String? detail]) =>
      FileOperationException(
        'Error al escribir archivo: $path${detail != null ? ' - $detail' : ''}',
      );

  /// Error al crear directorio.
  factory FileOperationException.createDir(String path, [String? detail]) =>
      FileOperationException(
        'Error al crear directorio: $path${detail != null ? ' - $detail' : ''}',
      );
}

/// Error cuando un tipo de especificacion no es valido.
class InvalidSpecTypeException extends DfspecException {
  /// Crea excepcion de tipo de spec invalido.
  const InvalidSpecTypeException(String type)
    : super('Tipo de especificacion invalido: $type');
}

/// Error cuando un agente no existe.
class AgentNotFoundException extends DfspecException {
  /// Crea excepcion de agente no encontrado.
  const AgentNotFoundException(String agentId)
    : super('Agente no encontrado: $agentId');
}

/// Error cuando un comando slash no existe.
class CommandNotFoundException extends DfspecException {
  /// Crea excepcion de comando no encontrado.
  const CommandNotFoundException(String command)
    : super('Comando slash no encontrado: $command');
}
