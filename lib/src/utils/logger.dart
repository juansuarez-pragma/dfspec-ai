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
  const Logger({this.verbose = false, IOSink? output, IOSink? errorOutput})
    : _output = output,
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

  /// Muestra un panel con borde.
  void panel(String title, String content, {int width = 60}) {
    final border = '═' * (width - 2);
    final titlePadded = ' $title '.padRight(width - 4).padLeft(width - 2);

    _out
      ..writeln('$_cyan╔$border╗$_reset')
      ..writeln('$_cyan║$_reset$_bold$titlePadded$_reset$_cyan║$_reset')
      ..writeln('$_cyan╠$border╣$_reset');

    for (final line in content.split('\n')) {
      final paddedLine = ' $line'.padRight(width - 2);
      final truncated = paddedLine.length > width - 2
          ? '${paddedLine.substring(0, width - 5)}...'
          : paddedLine;
      _out.writeln('$_cyan║$_reset$truncated$_cyan║$_reset');
    }

    _out.writeln('$_cyan╚$border╝$_reset');
  }

  /// Muestra una tabla con headers y filas.
  void table(List<String> headers, List<List<String>> rows) {
    if (headers.isEmpty) return;

    // Calcular ancho de columnas
    final widths = List<int>.filled(headers.length, 0);
    for (var i = 0; i < headers.length; i++) {
      widths[i] = headers[i].length;
    }
    for (final row in rows) {
      for (var i = 0; i < row.length && i < headers.length; i++) {
        if (row[i].length > widths[i]) {
          widths[i] = row[i].length;
        }
      }
    }

    // Header
    final headerLine = StringBuffer();
    final separatorLine = StringBuffer();
    for (var i = 0; i < headers.length; i++) {
      headerLine.write(' ${headers[i].padRight(widths[i])} │');
      separatorLine.write('${'─' * (widths[i] + 2)}┼');
    }

    _out
      ..writeln(
        '$_bold│${headerLine.toString().substring(0, headerLine.length - 1)}$_reset',
      )
      ..writeln(
        '├${separatorLine.toString().substring(0, separatorLine.length - 1)}',
      );

    // Rows
    for (final row in rows) {
      final rowLine = StringBuffer();
      for (var i = 0; i < headers.length; i++) {
        final cell = i < row.length ? row[i] : '';
        rowLine.write(' ${cell.padRight(widths[i])} │');
      }
      _out.writeln('│${rowLine.toString().substring(0, rowLine.length - 1)}');
    }
  }

  /// Muestra una barra de progreso.
  void progressBar(String label, double percent, {int width = 20}) {
    final filled = (percent * width).round().clamp(0, width);
    final empty = width - filled;
    final bar = '$_green${'█' * filled}$_reset$_gray${'░' * empty}$_reset';
    final pct = (percent * 100).toStringAsFixed(0);
    _out.writeln('$label [$bar] $pct%');
  }

  /// Muestra un resumen con estado.
  void summary(String title, Map<String, bool> checks) {
    _out
      ..writeln()
      ..writeln('$_bold$title$_reset')
      ..writeln('$_gray${'─' * title.length}$_reset');

    for (final entry in checks.entries) {
      final icon = entry.value ? '$_green✓$_reset' : '$_red✗$_reset';
      final color = entry.value ? '' : _yellow;
      _out.writeln('  $icon $color${entry.key}$_reset');
    }
  }

  /// Muestra un separador.
  void separator({int width = 60}) {
    _out.writeln('$_gray${'─' * width}$_reset');
  }

  /// Muestra un encabezado de seccion.
  void section(String title) {
    _out
      ..writeln()
      ..writeln('$_cyan━━━$_reset $_bold$title$_reset')
      ..writeln();
  }

  /// Muestra un paso numerado.
  void step(int number, int total, String description) {
    _out.writeln('$_cyan[$number/$total]$_reset $description');
  }
}
