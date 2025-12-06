import 'dart:io';

/// Logger para salida de consola con colores y formatos.
///
/// Soporta inyeccion de dependencias para testabilidad.
class Logger {
  /// Crea un logger con la configuracion dada.
  ///
  /// [verbose] - Si es true, muestra mensajes de debug.
  /// [output] - Stream de salida para mensajes normales (default: stdout).
  /// [errorOutput] - Stream de salida para errores (default: stderr).
  const Logger({
    this.verbose = false,
    IOSink? output,
    IOSink? errorOutput,
  })  : _output = output,
        _errorOutput = errorOutput;

  /// Si es true, muestra mensajes de debug.
  final bool verbose;

  /// Stream de salida personalizado.
  final IOSink? _output;

  /// Stream de errores personalizado.
  final IOSink? _errorOutput;

  /// Obtiene el stream de salida.
  IOSink get _out => _output ?? stdout;

  /// Obtiene el stream de errores.
  IOSink get _err => _errorOutput ?? stderr;

  // Codigos ANSI para colores
  static const String _reset = '\x1B[0m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';
  static const String _cyan = '\x1B[36m';
  static const String _gray = '\x1B[90m';
  static const String _bold = '\x1B[1m';

  /// Muestra un mensaje de exito.
  void success(String message) {
    _out.writeln('$_green$_bold\u2713$_reset $_green$message$_reset');
  }

  /// Muestra un mensaje de informacion.
  void info(String message) {
    _out.writeln('$_cyan\u2139$_reset $message');
  }

  /// Muestra un mensaje de advertencia.
  void warning(String message) {
    _out.writeln('$_yellow\u26A0$_reset $_yellow$message$_reset');
  }

  /// Muestra un mensaje de error.
  void error(String message) {
    _err.writeln('$_red\u2717$_reset $_red$message$_reset');
  }

  /// Muestra un mensaje de debug (solo si verbose es true).
  void debug(String message) {
    if (verbose) {
      _out.writeln('$_gray[debug] $message$_reset');
    }
  }

  /// Muestra un mensaje sin formato.
  void write(String message) {
    _out.writeln(message);
  }

  /// Muestra un titulo.
  void title(String message) {
    _out
      ..writeln()
      ..writeln('$_bold$message$_reset')
      ..writeln('$_gray${'=' * message.length}$_reset');
  }

  /// Muestra un item de lista.
  void item(String message, {String prefix = '  \u2022'}) {
    _out.writeln('$prefix $message');
  }

  /// Muestra una linea en blanco.
  void blank() {
    _out.writeln();
  }

  /// Muestra el progreso de una operacion.
  void progress(String operation, String status) {
    _out.writeln('$_gray[$status]$_reset $operation');
  }
}
