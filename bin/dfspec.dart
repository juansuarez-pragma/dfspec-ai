import 'dart:io';

import 'package:dfspec/dfspec.dart';

/// Punto de entrada del CLI DFSpec.
Future<void> main(List<String> args) async {
  final exitCode = await DfspecCommandRunner().run(args);
  exit(exitCode);
}
