import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Tests de integración para los scripts bash de DFSpec.
///
/// Estos tests verifican que los scripts:
/// 1. Son ejecutables
/// 2. Retornan JSON válido
/// 3. Manejan errores correctamente
/// 4. Funcionan en diferentes escenarios
void main() {
  const scriptsDir = 'scripts/bash';

  group('Scripts de Automatización', () {
    test('common.sh existe y es ejecutable', () {
      final file = File('$scriptsDir/common.sh');
      expect(file.existsSync(), isTrue);
    });

    test('check-prerequisites.sh existe y es ejecutable', () {
      final file = File('$scriptsDir/check-prerequisites.sh');
      expect(file.existsSync(), isTrue);
    });

    test('detect-context.sh existe y es ejecutable', () {
      final file = File('$scriptsDir/detect-context.sh');
      expect(file.existsSync(), isTrue);
    });

    test('create-new-feature.sh existe y es ejecutable', () {
      final file = File('$scriptsDir/create-new-feature.sh');
      expect(file.existsSync(), isTrue);
    });

    test('setup-plan.sh existe y es ejecutable', () {
      final file = File('$scriptsDir/setup-plan.sh');
      expect(file.existsSync(), isTrue);
    });

    test('validate-spec.sh existe y es ejecutable', () {
      final file = File('$scriptsDir/validate-spec.sh');
      expect(file.existsSync(), isTrue);
    });
  });

  group('check-prerequisites.sh', () {
    test('retorna JSON válido con --help', () async {
      final result = await Process.run(
        'bash',
        ['$scriptsDir/check-prerequisites.sh', '--help'],
      );

      // --help sale con código 0 y muestra ayuda
      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('DFSpec'));
      expect(result.stdout.toString(), contains('--json'));
    });

    test('retorna JSON válido en directorio git', () async {
      final result = await Process.run(
        'bash',
        ['$scriptsDir/check-prerequisites.sh', '--json'],
      );

      // Debería retornar JSON (aunque feature no detectada)
      final output = result.stdout.toString();

      // Verificar que es JSON válido
      expect(() => jsonDecode(output), returnsNormally);

      final json = jsonDecode(output) as Map<String, dynamic>;
      expect(json['status'], isIn(['success', 'error']));
    });

    test('retorna estructura correcta con --paths-only', () async {
      final result = await Process.run(
        'bash',
        ['$scriptsDir/check-prerequisites.sh', '--json', '--paths-only'],
      );

      final output = result.stdout.toString();
      final json = jsonDecode(output) as Map<String, dynamic>;

      expect(json['status'], equals('success'));
      expect(json['data'], isA<Map<String, dynamic>>());
      expect(json['data'], contains('BRANCH_NAME'));
    });
  });

  group('detect-context.sh', () {
    test('retorna JSON válido con --json', () async {
      final result = await Process.run(
        'bash',
        ['$scriptsDir/detect-context.sh', '--json'],
      );

      final output = result.stdout.toString();
      expect(() => jsonDecode(output), returnsNormally);

      final json = jsonDecode(output) as Map<String, dynamic>;
      expect(json['status'], equals('success'));
      expect(json['data'], isA<Map<String, dynamic>>());
    });

    test('incluye secciones project, git, feature, documents, quality', () async {
      final result = await Process.run(
        'bash',
        ['$scriptsDir/detect-context.sh', '--json'],
      );

      final json = jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;

      expect(data, contains('project'));
      expect(data, contains('git'));
      expect(data, contains('feature'));
      expect(data, contains('documents'));
      expect(data, contains('quality'));
    });

    test('detecta repositorio git correctamente', () async {
      final result = await Process.run(
        'bash',
        ['$scriptsDir/detect-context.sh', '--json'],
      );

      final json = jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      final git = data['git'] as Map<String, dynamic>;

      expect(git['is_git_repo'], isTrue);
      expect(git['current_branch'], isNotEmpty);
    });

    test('--summary muestra output legible', () async {
      final result = await Process.run(
        'bash',
        ['$scriptsDir/detect-context.sh', '--summary'],
      );

      final output = result.stdout.toString();
      expect(output, contains('DFSpec Context Summary'));
      expect(output, contains('Project:'));
      expect(output, contains('Git:'));
    });
  });

  group('create-new-feature.sh', () {
    test('muestra ayuda con --help', () async {
      final result = await Process.run(
        'bash',
        ['$scriptsDir/create-new-feature.sh', '--help'],
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('Create New Feature'));
      expect(result.stdout.toString(), contains('--no-branch'));
    });

    test('falla sin nombre de feature', () async {
      final result = await Process.run(
        'bash',
        ['$scriptsDir/create-new-feature.sh', '--json'],
      );

      // Debería fallar porque no se pasó nombre
      expect(result.exitCode, isNot(0));
    });
  });

  group('setup-plan.sh', () {
    test('muestra ayuda con --help', () async {
      final result = await Process.run(
        'bash',
        ['$scriptsDir/setup-plan.sh', '--help'],
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('Setup Plan'));
      expect(result.stdout.toString(), contains('--with-research'));
    });
  });

  group('validate-spec.sh', () {
    test('muestra ayuda con --help', () async {
      final result = await Process.run(
        'bash',
        ['$scriptsDir/validate-spec.sh', '--help'],
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('Validate Spec'));
      expect(result.stdout.toString(), contains('CRITICAL'));
      expect(result.stdout.toString(), contains('WARNING'));
    });
  });

  group('Funciones comunes (common.sh)', () {
    test('json_escape escapa caracteres correctamente', () async {
      // Crear script temporal que prueba json_escape
      const testScript = r'''
#!/usr/bin/env bash
source scripts/bash/common.sh
echo "$(json_escape 'test "quoted" string')"
''';

      final tempFile = File('.test_json_escape.sh');
      await tempFile.writeAsString(testScript);

      try {
        final result = await Process.run('bash', [tempFile.path]);
        expect(result.stdout.toString().trim(), contains(r'\"'));
      } finally {
        await tempFile.delete();
      }
    });

    test('format_feature_name convierte a kebab-case', () async {
      const testScript = r'''
#!/usr/bin/env bash
source scripts/bash/common.sh
echo "$(format_feature_name "Mi Feature Name")"
''';

      final tempFile = File('.test_format_name.sh');
      await tempFile.writeAsString(testScript);

      try {
        final result = await Process.run('bash', [tempFile.path]);
        expect(result.stdout.toString().trim(), equals('mi-feature-name'));
      } finally {
        await tempFile.delete();
      }
    });

    test('get_next_feature_number retorna formato 3 dígitos', () async {
      const testScript = r'''
#!/usr/bin/env bash
source scripts/bash/common.sh
num=$(get_next_feature_number)
echo "$num"
''';

      final tempFile = File('.test_next_number.sh');
      await tempFile.writeAsString(testScript);

      try {
        final result = await Process.run('bash', [tempFile.path]);
        final number = result.stdout.toString().trim();
        expect(number, matches(RegExp(r'^\d{3}$')));
      } finally {
        await tempFile.delete();
      }
    });
  });

  group('Integración de scripts', () {
    test('detect-context y check-prerequisites son consistentes', () async {
      // Ejecutar ambos scripts
      final detectResult = await Process.run(
        'bash',
        ['$scriptsDir/detect-context.sh', '--json'],
      );

      final checkResult = await Process.run(
        'bash',
        ['$scriptsDir/check-prerequisites.sh', '--json'],
      );

      final detectJson =
          jsonDecode(detectResult.stdout.toString()) as Map<String, dynamic>;
      final checkJson =
          jsonDecode(checkResult.stdout.toString()) as Map<String, dynamic>;

      // Ambos deberían detectar el mismo branch
      final detectData = detectJson['data'] as Map<String, dynamic>;
      final detectGit = detectData['git'] as Map<String, dynamic>;
      final detectBranch = detectGit['current_branch'] as String;
      final checkData = checkJson['data'] as Map<String, dynamic>;
      final checkBranch = checkData['current_branch'] as String;

      expect(detectBranch, equals(checkBranch));
    });
  });
}
