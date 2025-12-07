import 'dart:async';
import 'dart:io';

/// Spinner animado para operaciones largas en CLI.
///
/// Muestra una animación mientras se ejecuta una operación asíncrona.
/// Soporta diferentes estilos de animación y mensajes personalizables.
class Spinner {
  /// Crea un spinner con el mensaje dado.
  ///
  /// [message] - Mensaje a mostrar junto al spinner.
  /// [style] - Estilo de animación (default: dots).
  /// [output] - Stream de salida (default: stdout).
  Spinner({
    required this.message,
    this.style = SpinnerStyle.dots,
    IOSink? output,
  }) : _output = output ?? stdout;

  /// Mensaje a mostrar.
  final String message;

  /// Estilo de animación.
  final SpinnerStyle style;

  /// Stream de salida.
  final IOSink _output;

  /// Timer para la animación.
  Timer? _timer;

  /// Índice del frame actual.
  int _frameIndex = 0;

  /// Si el spinner está activo.
  bool _isRunning = false;

  // Códigos ANSI
  static const String _reset = '\x1B[0m';
  static const String _cyan = '\x1B[36m';
  static const String _green = '\x1B[32m';
  static const String _red = '\x1B[31m';
  static const String _yellow = '\x1B[33m';
  static const String _hide = '\x1B[?25l';
  static const String _show = '\x1B[?25h';
  static const String _clearLine = '\x1B[2K\r';

  /// Inicia la animación del spinner.
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _frameIndex = 0;

    // Ocultar cursor
    _output.write(_hide);

    _timer = Timer.periodic(
      Duration(milliseconds: style.interval),
      (_) => _render(),
    );

    // Render inicial
    _render();
  }

  /// Detiene el spinner y muestra éxito.
  void success([String? finalMessage]) {
    _stop();
    final msg = finalMessage ?? message;
    _output.writeln('$_clearLine$_green✓$_reset $msg');
  }

  /// Detiene el spinner y muestra error.
  void fail([String? errorMessage]) {
    _stop();
    final msg = errorMessage ?? message;
    _output.writeln('$_clearLine$_red✗$_reset $msg');
  }

  /// Detiene el spinner y muestra advertencia.
  void warn([String? warnMessage]) {
    _stop();
    final msg = warnMessage ?? message;
    _output.writeln('$_clearLine$_yellow⚠$_reset $msg');
  }

  /// Detiene el spinner y muestra info.
  void info([String? infoMessage]) {
    _stop();
    final msg = infoMessage ?? message;
    _output.writeln('$_clearLine$_cyan ℹ$_reset $msg');
  }

  /// Actualiza el mensaje del spinner.
  void update(String newMessage) {
    // ignore: parameter_assignments
    message == newMessage;
    if (_isRunning) _render();
  }

  /// Detiene el spinner sin mensaje final.
  void stop() {
    _stop();
    _output.write(_clearLine);
  }

  void _stop() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    // Mostrar cursor
    _output.write(_show);
  }

  void _render() {
    final frame = style.frames[_frameIndex % style.frames.length];
    _output.write('$_clearLine$_cyan$frame$_reset $message');
    _frameIndex++;
  }

  /// Ejecuta una función mientras muestra el spinner.
  ///
  /// Retorna el resultado de la función.
  /// Si hay error, muestra el spinner como fallido.
  static Future<T> run<T>({
    required String message,
    required Future<T> Function() task,
    SpinnerStyle style = SpinnerStyle.dots,
    String? successMessage,
    String? failMessage,
  }) async {
    final spinner = Spinner(message: message, style: style);
    spinner.start();

    try {
      final result = await task();
      spinner.success(successMessage);
      return result;
    } catch (e) {
      spinner.fail(failMessage ?? '$message - Error: $e');
      rethrow;
    }
  }
}

/// Estilos de animación para el spinner.
enum SpinnerStyle {
  /// Puntos rotando.
  dots(['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'], 80),

  /// Línea rotando.
  line(['|', '/', '-', r'\'], 100),

  /// Arco iris de puntos.
  dots2(['⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷'], 80),

  /// Círculos.
  circle(['◐', '◓', '◑', '◒'], 100),

  /// Flechas.
  arrows(['←', '↖', '↑', '↗', '→', '↘', '↓', '↙'], 100),

  /// Reloj.
  clock([
    '🕐',
    '🕑',
    '🕒',
    '🕓',
    '🕔',
    '🕕',
    '🕖',
    '🕗',
    '🕘',
    '🕙',
    '🕚',
    '🕛',
  ], 100),

  /// Barra de progreso corta.
  bar(['▏', '▎', '▍', '▌', '▋', '▊', '▉', '█', '▉', '▊', '▋', '▌', '▍', '▎'], 80),

  /// Bounce.
  bounce(['⠁', '⠂', '⠄', '⠂'], 120),

  /// Simple.
  simple(['.  ', '.. ', '...', '   '], 300);

  const SpinnerStyle(this.frames, this.interval);

  /// Frames de la animación.
  final List<String> frames;

  /// Intervalo entre frames en milisegundos.
  final int interval;
}

/// Barra de progreso animada.
class ProgressBar {
  /// Crea una barra de progreso.
  ///
  /// [total] - Valor total (100%).
  /// [width] - Ancho de la barra en caracteres.
  /// [label] - Etiqueta opcional.
  ProgressBar({
    required this.total,
    this.width = 30,
    this.label,
    IOSink? output,
  }) : _output = output ?? stdout;

  /// Valor total.
  final int total;

  /// Ancho de la barra.
  final int width;

  /// Etiqueta opcional.
  final String? label;

  /// Stream de salida.
  final IOSink _output;

  /// Valor actual.
  int _current = 0;

  // Códigos ANSI
  static const String _reset = '\x1B[0m';
  static const String _green = '\x1B[32m';
  static const String _gray = '\x1B[90m';
  static const String _cyan = '\x1B[36m';
  static const String _hide = '\x1B[?25l';
  static const String _show = '\x1B[?25h';
  static const String _clearLine = '\x1B[2K\r';

  /// Inicia la barra de progreso.
  void start() {
    _output.write(_hide);
    _render();
  }

  /// Actualiza el progreso.
  void update(int current) {
    _current = current.clamp(0, total);
    _render();
  }

  /// Incrementa el progreso en 1.
  void increment([int amount = 1]) {
    update(_current + amount);
  }

  /// Completa la barra de progreso.
  void complete([String? message]) {
    _current = total;
    _render();
    _output
      ..write(_show)
      ..writeln();
    if (message != null) {
      _output.writeln('$_green✓$_reset $message');
    }
  }

  /// Marca error y detiene.
  void fail([String? message]) {
    _output
      ..write(_show)
      ..writeln();
    if (message != null) {
      _output.writeln('\x1B[31m✗$_reset $message');
    }
  }

  void _render() {
    final percent = total > 0 ? _current / total : 0.0;
    final filled = (percent * width).round().clamp(0, width);
    final empty = width - filled;

    final bar = '$_green${'█' * filled}$_reset$_gray${'░' * empty}$_reset';
    final pct = (percent * 100).toStringAsFixed(0).padLeft(3);
    final labelText = label != null ? '$label ' : '';

    _output.write('$_clearLine$labelText[$bar] $_cyan$pct%$_reset ($_current/$total)');
  }
}

/// Grupo de tareas con progreso.
class TaskRunner {
  /// Crea un runner de tareas.
  TaskRunner({IOSink? output}) : _output = output ?? stdout;

  final IOSink _output;
  final List<_Task> _tasks = [];

  // Códigos ANSI
  static const String _reset = '\x1B[0m';
  static const String _green = '\x1B[32m';
  static const String _red = '\x1B[31m';
  static const String _yellow = '\x1B[33m';
  static const String _cyan = '\x1B[36m';
  static const String _gray = '\x1B[90m';
  static const String _bold = '\x1B[1m';

  /// Agrega una tarea.
  void add(String name, Future<void> Function() task) {
    _tasks.add(_Task(name: name, task: task));
  }

  /// Ejecuta todas las tareas en secuencia.
  Future<TaskRunnerResult> run({String? title}) async {
    if (title != null) {
      _output
        ..writeln()
        ..writeln('$_bold$title$_reset')
        ..writeln('$_gray${'─' * title.length}$_reset');
    }

    final results = <String, bool>{};
    var passed = 0;
    var failed = 0;

    for (var i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      final prefix = '$_cyan[${i + 1}/${_tasks.length}]$_reset';

      _output.write('$prefix ${task.name}...');

      try {
        await task.task();
        results[task.name] = true;
        passed++;
        _output.writeln('\r$prefix $_green✓$_reset ${task.name}');
      } catch (e) {
        results[task.name] = false;
        failed++;
        _output.writeln('\r$prefix $_red✗$_reset ${task.name}');
        _output.writeln('  $_red└ $e$_reset');
      }
    }

    // Resumen
    _output.writeln();
    if (failed == 0) {
      _output.writeln('$_green✓ Todas las tareas completadas ($passed/$_tasks.length)$_reset');
    } else {
      _output.writeln('$_yellow⚠ Completado con errores: $passed exitosas, $failed fallidas$_reset');
    }

    return TaskRunnerResult(
      total: _tasks.length,
      passed: passed,
      failed: failed,
      results: results,
    );
  }
}

class _Task {
  const _Task({required this.name, required this.task});
  final String name;
  final Future<void> Function() task;
}

/// Resultado de ejecutar múltiples tareas.
class TaskRunnerResult {
  const TaskRunnerResult({
    required this.total,
    required this.passed,
    required this.failed,
    required this.results,
  });

  /// Total de tareas.
  final int total;

  /// Tareas exitosas.
  final int passed;

  /// Tareas fallidas.
  final int failed;

  /// Resultados por tarea.
  final Map<String, bool> results;

  /// Si todas las tareas pasaron.
  bool get allPassed => failed == 0;
}
