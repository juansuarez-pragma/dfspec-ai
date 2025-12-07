import 'package:dfspec/src/utils/ansi_colors.dart';
import 'package:test/test.dart';

void main() {
  group('AnsiColors', () {
    group('constantes de color', () {
      test('reset tiene código correcto', () {
        expect(AnsiColors.reset, equals('\x1B[0m'));
      });

      test('bold tiene código correcto', () {
        expect(AnsiColors.bold, equals('\x1B[1m'));
      });

      test('colores básicos tienen códigos correctos', () {
        expect(AnsiColors.red, equals('\x1B[31m'));
        expect(AnsiColors.green, equals('\x1B[32m'));
        expect(AnsiColors.yellow, equals('\x1B[33m'));
        expect(AnsiColors.blue, equals('\x1B[34m'));
        expect(AnsiColors.cyan, equals('\x1B[36m'));
        expect(AnsiColors.gray, equals('\x1B[90m'));
      });

      test('colores brillantes tienen códigos correctos', () {
        expect(AnsiColors.brightRed, equals('\x1B[91m'));
        expect(AnsiColors.brightGreen, equals('\x1B[92m'));
        expect(AnsiColors.brightYellow, equals('\x1B[93m'));
        expect(AnsiColors.brightBlue, equals('\x1B[94m'));
      });

      test('colores de fondo tienen códigos correctos', () {
        expect(AnsiColors.bgRed, equals('\x1B[41m'));
        expect(AnsiColors.bgGreen, equals('\x1B[42m'));
        expect(AnsiColors.bgYellow, equals('\x1B[43m'));
        expect(AnsiColors.bgBlue, equals('\x1B[44m'));
      });
    });

    group('iconos', () {
      test('checkIcon es correcto', () {
        expect(AnsiColors.checkIcon, equals('✓'));
      });

      test('crossIcon es correcto', () {
        expect(AnsiColors.crossIcon, equals('✗'));
      });

      test('warningIcon es correcto', () {
        expect(AnsiColors.warningIcon, equals('⚠'));
      });

      test('infoIcon es correcto', () {
        expect(AnsiColors.infoIcon, equals('ℹ'));
      });
    });

    group('colorize', () {
      test('aplica color y reset', () {
        final result = AnsiColors.colorize('Hello', AnsiColors.green);
        expect(result, equals('\x1B[32mHello\x1B[0m'));
      });

      test('funciona con texto vacío', () {
        final result = AnsiColors.colorize('', AnsiColors.red);
        expect(result, equals('\x1B[31m\x1B[0m'));
      });

      test('funciona con diferentes colores', () {
        expect(
          AnsiColors.colorize('Test', AnsiColors.cyan),
          contains('\x1B[36m'),
        );
        expect(
          AnsiColors.colorize('Test', AnsiColors.yellow),
          contains('\x1B[33m'),
        );
      });
    });

    group('styled', () {
      test('aplica múltiples estilos', () {
        final result = AnsiColors.styled(
          'Hello',
          [AnsiColors.bold, AnsiColors.red],
        );
        expect(result, contains('\x1B[1m'));
        expect(result, contains('\x1B[31m'));
        expect(result, contains('Hello'));
        expect(result, endsWith('\x1B[0m'));
      });

      test('funciona con lista vacía', () {
        final result = AnsiColors.styled('Hello', []);
        expect(result, equals('Hello\x1B[0m'));
      });

      test('funciona con un solo estilo', () {
        final result = AnsiColors.styled('Hello', [AnsiColors.underline]);
        expect(result, contains('\x1B[4m'));
      });
    });

    group('success', () {
      test('incluye check icon verde', () {
        final result = AnsiColors.success('Done');
        expect(result, contains(AnsiColors.checkIcon));
        expect(result, contains(AnsiColors.green));
        expect(result, contains('Done'));
      });
    });

    group('error', () {
      test('incluye cross icon rojo', () {
        final result = AnsiColors.error('Failed');
        expect(result, contains(AnsiColors.crossIcon));
        expect(result, contains(AnsiColors.red));
        expect(result, contains('Failed'));
      });
    });

    group('warning', () {
      test('incluye warning icon amarillo', () {
        final result = AnsiColors.warning('Careful');
        expect(result, contains(AnsiColors.warningIcon));
        expect(result, contains(AnsiColors.yellow));
        expect(result, contains('Careful'));
      });
    });

    group('info', () {
      test('incluye info icon cyan', () {
        final result = AnsiColors.info('Note');
        expect(result, contains(AnsiColors.infoIcon));
        expect(result, contains(AnsiColors.cyan));
        expect(result, contains('Note'));
      });
    });

    group('title', () {
      test('aplica bold', () {
        final result = AnsiColors.title('Header');
        expect(result, contains(AnsiColors.bold));
        expect(result, contains('Header'));
        expect(result, endsWith(AnsiColors.reset));
      });
    });

    group('subtitle', () {
      test('aplica cyan', () {
        final result = AnsiColors.subtitle('Section');
        expect(result, contains(AnsiColors.cyan));
        expect(result, contains('Section'));
      });
    });

    group('code', () {
      test('aplica dim', () {
        final result = AnsiColors.code('path/to/file.dart');
        expect(result, contains(AnsiColors.dim));
        expect(result, contains('path/to/file.dart'));
      });
    });

    group('highlight', () {
      test('aplica bold y color por defecto (yellow)', () {
        final result = AnsiColors.highlight('Important');
        expect(result, contains(AnsiColors.bold));
        expect(result, contains(AnsiColors.yellow));
        expect(result, contains('Important'));
      });

      test('acepta color personalizado', () {
        final result = AnsiColors.highlight('Error', AnsiColors.red);
        expect(result, contains(AnsiColors.red));
        expect(result, contains('Error'));
      });
    });

    group('statusIcon', () {
      test('retorna check verde para true', () {
        final result = AnsiColors.statusIcon(true);
        expect(result, contains(AnsiColors.checkIcon));
        expect(result, contains(AnsiColors.green));
      });

      test('retorna cross rojo para false', () {
        final result = AnsiColors.statusIcon(false);
        expect(result, contains(AnsiColors.crossIcon));
        expect(result, contains(AnsiColors.red));
      });

      test('invierte con invert=true', () {
        final resultTrue = AnsiColors.statusIcon(true, invert: true);
        expect(resultTrue, contains(AnsiColors.crossIcon));

        final resultFalse = AnsiColors.statusIcon(false, invert: true);
        expect(resultFalse, contains(AnsiColors.checkIcon));
      });
    });

    group('severityBadge', () {
      test('formatea CRITICAL correctamente', () {
        final result = AnsiColors.severityBadge('CRITICAL');
        expect(result, contains(AnsiColors.bgRed));
        expect(result, contains('CRITICAL'));
      });

      test('formatea WARNING correctamente', () {
        final result = AnsiColors.severityBadge('WARNING');
        expect(result, contains(AnsiColors.bgYellow));
        expect(result, contains('WARNING'));
      });

      test('formatea INFO correctamente', () {
        final result = AnsiColors.severityBadge('INFO');
        expect(result, contains(AnsiColors.bgBlue));
        expect(result, contains('INFO'));
      });

      test('formatea SUCCESS correctamente', () {
        final result = AnsiColors.severityBadge('SUCCESS');
        expect(result, contains(AnsiColors.bgGreen));
        expect(result, contains('SUCCESS'));
      });

      test('es case insensitive', () {
        expect(AnsiColors.severityBadge('critical'), contains('CRITICAL'));
        expect(AnsiColors.severityBadge('Warning'), contains('WARNING'));
      });

      test('retorna texto original para valores desconocidos', () {
        expect(AnsiColors.severityBadge('UNKNOWN'), equals('UNKNOWN'));
      });
    });

    group('progressBar', () {
      test('genera barra vacía para 0%', () {
        final result = AnsiColors.progressBar(0);
        expect(result, startsWith('['));
        expect(result, endsWith(']'));
        expect(result, contains('░'));
      });

      test('genera barra llena para 100%', () {
        final result = AnsiColors.progressBar(1);
        expect(result, contains('█'));
      });

      test('genera barra parcial para 50%', () {
        final result = AnsiColors.progressBar(0.5, width: 10);
        // Debería tener 5 llenos y 5 vacíos
        final stripped = AnsiColors.stripAnsi(result);
        expect(stripped, contains('█'));
        expect(stripped, contains('░'));
      });

      test('respeta width personalizado', () {
        final result = AnsiColors.progressBar(0, width: 10);
        final stripped = AnsiColors.stripAnsi(result);
        // [░░░░░░░░░░] = 12 caracteres (2 brackets + 10 chars)
        expect(stripped.length, equals(12));
      });

      test('usa caracteres personalizados', () {
        final result = AnsiColors.progressBar(
          0.5,
          width: 4,
          filledChar: '#',
          emptyChar: '-',
        );
        final stripped = AnsiColors.stripAnsi(result);
        expect(stripped, contains('#'));
        expect(stripped, contains('-'));
      });
    });

    group('stripAnsi', () {
      test('elimina códigos ANSI simples', () {
        final colored = '\x1B[32mHello\x1B[0m';
        expect(AnsiColors.stripAnsi(colored), equals('Hello'));
      });

      test('elimina múltiples códigos ANSI', () {
        final styled = '\x1B[1m\x1B[31mBold Red\x1B[0m';
        expect(AnsiColors.stripAnsi(styled), equals('Bold Red'));
      });

      test('preserva texto sin códigos ANSI', () {
        const plain = 'Hello World';
        expect(AnsiColors.stripAnsi(plain), equals(plain));
      });

      test('funciona con texto vacío', () {
        expect(AnsiColors.stripAnsi(''), equals(''));
      });

      test('funciona con solo códigos ANSI', () {
        expect(AnsiColors.stripAnsi('\x1B[0m'), equals(''));
      });
    });

    group('estilos adicionales', () {
      test('dim tiene código correcto', () {
        expect(AnsiColors.dim, equals('\x1B[2m'));
      });

      test('italic tiene código correcto', () {
        expect(AnsiColors.italic, equals('\x1B[3m'));
      });

      test('underline tiene código correcto', () {
        expect(AnsiColors.underline, equals('\x1B[4m'));
      });
    });

    group('colores adicionales', () {
      test('black tiene código correcto', () {
        expect(AnsiColors.black, equals('\x1B[30m'));
      });

      test('magenta tiene código correcto', () {
        expect(AnsiColors.magenta, equals('\x1B[35m'));
      });

      test('white tiene código correcto', () {
        expect(AnsiColors.white, equals('\x1B[37m'));
      });
    });

    group('iconos adicionales', () {
      test('bulletIcon es correcto', () {
        expect(AnsiColors.bulletIcon, equals('•'));
      });

      test('arrowIcon es correcto', () {
        expect(AnsiColors.arrowIcon, equals('→'));
      });
    });
  });
}
