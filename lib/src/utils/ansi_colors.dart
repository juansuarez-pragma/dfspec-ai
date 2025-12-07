/// Utilidades para colores ANSI en terminal.
///
/// Proporciona constantes y métodos para formatear texto con colores
/// y estilos en la terminal.
///
/// Ejemplo:
/// ```dart
/// print(AnsiColors.green('Success!'));
/// print(AnsiColors.bold(AnsiColors.red('Error!')));
/// print(AnsiColors.colorize('Warning', AnsiColors.yellow));
/// ```
abstract final class AnsiColors {
  // Reset
  /// Código para resetear todos los estilos.
  static const String reset = '\x1B[0m';

  // Estilos
  /// Código para texto en negrita.
  static const String bold = '\x1B[1m';

  /// Código para texto atenuado.
  static const String dim = '\x1B[2m';

  /// Código para texto en cursiva.
  static const String italic = '\x1B[3m';

  /// Código para texto subrayado.
  static const String underline = '\x1B[4m';

  // Colores de texto
  /// Código para texto negro.
  static const String black = '\x1B[30m';

  /// Código para texto rojo.
  static const String red = '\x1B[31m';

  /// Código para texto verde.
  static const String green = '\x1B[32m';

  /// Código para texto amarillo.
  static const String yellow = '\x1B[33m';

  /// Código para texto azul.
  static const String blue = '\x1B[34m';

  /// Código para texto magenta.
  static const String magenta = '\x1B[35m';

  /// Código para texto cyan.
  static const String cyan = '\x1B[36m';

  /// Código para texto blanco.
  static const String white = '\x1B[37m';

  /// Código para texto gris.
  static const String gray = '\x1B[90m';

  // Colores brillantes
  /// Código para texto rojo brillante.
  static const String brightRed = '\x1B[91m';

  /// Código para texto verde brillante.
  static const String brightGreen = '\x1B[92m';

  /// Código para texto amarillo brillante.
  static const String brightYellow = '\x1B[93m';

  /// Código para texto azul brillante.
  static const String brightBlue = '\x1B[94m';

  /// Código para texto magenta brillante.
  static const String brightMagenta = '\x1B[95m';

  /// Código para texto cyan brillante.
  static const String brightCyan = '\x1B[96m';

  /// Código para texto blanco brillante.
  static const String brightWhite = '\x1B[97m';

  // Colores de fondo
  /// Código para fondo rojo.
  static const String bgRed = '\x1B[41m';

  /// Código para fondo verde.
  static const String bgGreen = '\x1B[42m';

  /// Código para fondo amarillo.
  static const String bgYellow = '\x1B[43m';

  /// Código para fondo azul.
  static const String bgBlue = '\x1B[44m';

  /// Código para fondo magenta.
  static const String bgMagenta = '\x1B[45m';

  /// Código para fondo cyan.
  static const String bgCyan = '\x1B[46m';

  // Iconos comunes
  /// Icono de check.
  static const String checkIcon = '✓';

  /// Icono de cross.
  static const String crossIcon = '✗';

  /// Icono de warning.
  static const String warningIcon = '⚠';

  /// Icono de info.
  static const String infoIcon = 'ℹ';

  /// Icono de bullet.
  static const String bulletIcon = '•';

  /// Icono de flecha derecha.
  static const String arrowIcon = '→';

  // Métodos de utilidad

  /// Aplica un color a un texto.
  ///
  /// ```dart
  /// colorize('Hello', AnsiColors.green) // Verde
  /// ```
  static String colorize(String text, String color) {
    return '$color$text$reset';
  }

  /// Aplica múltiples estilos a un texto.
  ///
  /// ```dart
  /// styled('Hello', [AnsiColors.bold, AnsiColors.red]) // Rojo negrita
  /// ```
  static String styled(String text, List<String> styles) {
    final prefix = styles.join();
    return '$prefix$text$reset';
  }

  /// Formatea texto como éxito (verde con check).
  static String success(String text) {
    return '$green$bold$checkIcon$reset $green$text$reset';
  }

  /// Formatea texto como error (rojo con cross).
  static String error(String text) {
    return '$red$bold$crossIcon$reset $red$text$reset';
  }

  /// Formatea texto como warning (amarillo con warning icon).
  static String warning(String text) {
    return '$yellow$warningIcon$reset $yellow$text$reset';
  }

  /// Formatea texto como info (cyan con info icon).
  static String info(String text) {
    return '$cyan$infoIcon$reset $text';
  }

  /// Formatea texto como título (negrita con subrayado).
  static String title(String text) {
    return '$bold$text$reset';
  }

  /// Formatea texto como subtítulo (cyan).
  static String subtitle(String text) {
    return '$cyan$text$reset';
  }

  /// Formatea texto como código/path (dim).
  static String code(String text) {
    return '$dim$text$reset';
  }

  /// Formatea texto como destacado (bold + color).
  static String highlight(String text, [String color = yellow]) {
    return '$bold$color$text$reset';
  }

  /// Crea un icono de estado basado en booleano.
  static String statusIcon(bool status, {bool invert = false}) {
    final isGood = invert ? !status : status;
    return isGood ? '$green$checkIcon$reset' : '$red$crossIcon$reset';
  }

  /// Crea un badge de severidad.
  static String severityBadge(String severity) {
    return switch (severity.toUpperCase()) {
      'CRITICAL' => '$bgRed$white CRITICAL $reset',
      'WARNING' => '$bgYellow$black WARNING $reset',
      'INFO' => '$bgBlue$white INFO $reset',
      'SUCCESS' => '$bgGreen$white SUCCESS $reset',
      _ => severity,
    };
  }

  /// Crea una barra de progreso visual.
  static String progressBar(
    double percent, {
    int width = 20,
    String filledChar = '█',
    String emptyChar = '░',
  }) {
    final filled = (percent * width).round().clamp(0, width);
    final empty = width - filled;
    final filledPart = '$green${filledChar * filled}$reset';
    final emptyPart = '$gray${emptyChar * empty}$reset';
    return '[$filledPart$emptyPart]';
  }

  /// Elimina todos los códigos ANSI de un texto.
  ///
  /// Útil para calcular longitud real de strings o para logging.
  static String stripAnsi(String text) {
    return text.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
  }

  /// Verifica si la terminal soporta colores.
  ///
  /// Nota: Esta es una verificación básica, no es 100% precisa.
  static bool get supportsColors {
    // En CI usualmente se soporta, pero puede estar deshabilitado
    final term = String.fromEnvironment('TERM', defaultValue: '');
    final colorTerm = String.fromEnvironment('COLORTERM', defaultValue: '');
    final noColor = String.fromEnvironment('NO_COLOR', defaultValue: '');

    if (noColor.isNotEmpty) return false;
    if (colorTerm.isNotEmpty) return true;
    if (term.contains('color') || term.contains('256')) return true;

    return term.isNotEmpty && term != 'dumb';
  }
}
