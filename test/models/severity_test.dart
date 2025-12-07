import 'package:dfspec/src/models/severity.dart';
import 'package:test/test.dart';

void main() {
  group('Severity', () {
    group('valores', () {
      test('tiene los tres niveles esperados', () {
        expect(Severity.values, hasLength(3));
        expect(
          Severity.values,
          containsAll([Severity.critical, Severity.warning, Severity.info]),
        );
      });

      test('critical tiene propiedades correctas', () {
        expect(Severity.critical.label, equals('CRITICAL'));
        expect(Severity.critical.icon, equals('✗'));
        expect(Severity.critical.weight, equals(3));
      });

      test('warning tiene propiedades correctas', () {
        expect(Severity.warning.label, equals('WARNING'));
        expect(Severity.warning.icon, equals('⚠'));
        expect(Severity.warning.weight, equals(2));
      });

      test('info tiene propiedades correctas', () {
        expect(Severity.info.label, equals('INFO'));
        expect(Severity.info.icon, equals('ℹ'));
        expect(Severity.info.weight, equals(1));
      });
    });

    group('fromString', () {
      test('parsea CRITICAL', () {
        expect(Severity.fromString('CRITICAL'), equals(Severity.critical));
        expect(Severity.fromString('critical'), equals(Severity.critical));
        expect(Severity.fromString('ERROR'), equals(Severity.critical));
      });

      test('parsea WARNING', () {
        expect(Severity.fromString('WARNING'), equals(Severity.warning));
        expect(Severity.fromString('warning'), equals(Severity.warning));
        expect(Severity.fromString('WARN'), equals(Severity.warning));
      });

      test('parsea INFO', () {
        expect(Severity.fromString('INFO'), equals(Severity.info));
        expect(Severity.fromString('info'), equals(Severity.info));
        expect(Severity.fromString('INFORMATION'), equals(Severity.info));
      });

      test('retorna info para valores desconocidos', () {
        expect(Severity.fromString('unknown'), equals(Severity.info));
        expect(Severity.fromString(''), equals(Severity.info));
      });
    });

    group('ansiColor', () {
      test('critical es rojo', () {
        expect(Severity.critical.ansiColor, equals('\x1B[31m'));
      });

      test('warning es amarillo', () {
        expect(Severity.warning.ansiColor, equals('\x1B[33m'));
      });

      test('info es azul', () {
        expect(Severity.info.ansiColor, equals('\x1B[34m'));
      });
    });

    group('isBlocking', () {
      test('solo critical es bloqueante', () {
        expect(Severity.critical.isBlocking, isTrue);
        expect(Severity.warning.isBlocking, isFalse);
        expect(Severity.info.isBlocking, isFalse);
      });
    });

    group('comparaciones', () {
      test('isMoreSevereThan funciona correctamente', () {
        expect(Severity.critical.isMoreSevereThan(Severity.warning), isTrue);
        expect(Severity.critical.isMoreSevereThan(Severity.info), isTrue);
        expect(Severity.warning.isMoreSevereThan(Severity.info), isTrue);
        expect(Severity.warning.isMoreSevereThan(Severity.critical), isFalse);
        expect(Severity.info.isMoreSevereThan(Severity.warning), isFalse);
      });

      test('isAtLeast funciona correctamente', () {
        expect(Severity.critical.isAtLeast(Severity.critical), isTrue);
        expect(Severity.critical.isAtLeast(Severity.warning), isTrue);
        expect(Severity.warning.isAtLeast(Severity.warning), isTrue);
        expect(Severity.warning.isAtLeast(Severity.critical), isFalse);
        expect(Severity.info.isAtLeast(Severity.info), isTrue);
      });
    });
  });

  group('MetricLevel', () {
    group('valores', () {
      test('tiene los cuatro niveles esperados', () {
        expect(MetricLevel.values, hasLength(4));
        expect(
          MetricLevel.values,
          containsAll([
            MetricLevel.optimal,
            MetricLevel.acceptable,
            MetricLevel.warning,
            MetricLevel.critical,
          ]),
        );
      });

      test('optimal tiene propiedades correctas', () {
        expect(MetricLevel.optimal.label, equals('Óptimo'));
        expect(MetricLevel.optimal.icon, equals('✓'));
        expect(MetricLevel.optimal.score, equals(4));
      });

      test('acceptable tiene propiedades correctas', () {
        expect(MetricLevel.acceptable.label, equals('Aceptable'));
        expect(MetricLevel.acceptable.icon, equals('○'));
        expect(MetricLevel.acceptable.score, equals(3));
      });

      test('warning tiene propiedades correctas', () {
        expect(MetricLevel.warning.label, equals('Advertencia'));
        expect(MetricLevel.warning.icon, equals('⚠'));
        expect(MetricLevel.warning.score, equals(2));
      });

      test('critical tiene propiedades correctas', () {
        expect(MetricLevel.critical.label, equals('Crítico'));
        expect(MetricLevel.critical.icon, equals('✗'));
        expect(MetricLevel.critical.score, equals(1));
      });
    });

    group('fromString', () {
      test('parsea optimal', () {
        expect(MetricLevel.fromString('optimal'), equals(MetricLevel.optimal));
        expect(
          MetricLevel.fromString('excellent'),
          equals(MetricLevel.optimal),
        );
      });

      test('parsea acceptable', () {
        expect(
          MetricLevel.fromString('acceptable'),
          equals(MetricLevel.acceptable),
        );
        expect(MetricLevel.fromString('good'), equals(MetricLevel.acceptable));
      });

      test('parsea warning', () {
        expect(MetricLevel.fromString('warning'), equals(MetricLevel.warning));
        expect(
          MetricLevel.fromString('needs_improvement'),
          equals(MetricLevel.warning),
        );
      });

      test('parsea critical', () {
        expect(
          MetricLevel.fromString('critical'),
          equals(MetricLevel.critical),
        );
        expect(MetricLevel.fromString('poor'), equals(MetricLevel.critical));
      });

      test('retorna warning para valores desconocidos', () {
        expect(MetricLevel.fromString('unknown'), equals(MetricLevel.warning));
      });
    });

    group('ansiColor', () {
      test('optimal es verde', () {
        expect(MetricLevel.optimal.ansiColor, equals('\x1B[32m'));
      });

      test('acceptable es cyan', () {
        expect(MetricLevel.acceptable.ansiColor, equals('\x1B[36m'));
      });

      test('warning es amarillo', () {
        expect(MetricLevel.warning.ansiColor, equals('\x1B[33m'));
      });

      test('critical es rojo', () {
        expect(MetricLevel.critical.ansiColor, equals('\x1B[31m'));
      });
    });

    group('passes', () {
      test('optimal y acceptable pasan', () {
        expect(MetricLevel.optimal.passes, isTrue);
        expect(MetricLevel.acceptable.passes, isTrue);
      });

      test('warning y critical no pasan', () {
        expect(MetricLevel.warning.passes, isFalse);
        expect(MetricLevel.critical.passes, isFalse);
      });
    });

    group('needsAttention', () {
      test('solo critical necesita atención inmediata', () {
        expect(MetricLevel.critical.needsAttention, isTrue);
        expect(MetricLevel.warning.needsAttention, isFalse);
        expect(MetricLevel.acceptable.needsAttention, isFalse);
        expect(MetricLevel.optimal.needsAttention, isFalse);
      });
    });

    group('toSeverity', () {
      test('convierte correctamente a Severity', () {
        expect(MetricLevel.optimal.toSeverity(), equals(Severity.info));
        expect(MetricLevel.acceptable.toSeverity(), equals(Severity.info));
        expect(MetricLevel.warning.toSeverity(), equals(Severity.warning));
        expect(MetricLevel.critical.toSeverity(), equals(Severity.critical));
      });
    });
  });

  group('SeverityListExtension', () {
    group('highest', () {
      test('retorna la severidad más alta', () {
        expect(
          [Severity.info, Severity.warning, Severity.critical].highest,
          equals(Severity.critical),
        );
        expect(
          [Severity.info, Severity.warning].highest,
          equals(Severity.warning),
        );
        expect(
          [Severity.info, Severity.info].highest,
          equals(Severity.info),
        );
      });

      test('retorna null para lista vacía', () {
        expect(<Severity>[].highest, isNull);
      });
    });

    group('counts', () {
      test('cuenta correctamente cada severidad', () {
        final list = [
          Severity.critical,
          Severity.critical,
          Severity.warning,
          Severity.info,
          Severity.info,
          Severity.info,
        ];

        final counts = list.counts;

        expect(counts[Severity.critical], equals(2));
        expect(counts[Severity.warning], equals(1));
        expect(counts[Severity.info], equals(3));
      });

      test('retorna ceros para lista vacía', () {
        final counts = <Severity>[].counts;

        expect(counts[Severity.critical], equals(0));
        expect(counts[Severity.warning], equals(0));
        expect(counts[Severity.info], equals(0));
      });
    });

    group('hasCritical', () {
      test('retorna true cuando hay crítico', () {
        expect([Severity.info, Severity.critical].hasCritical, isTrue);
      });

      test('retorna false cuando no hay crítico', () {
        expect([Severity.info, Severity.warning].hasCritical, isFalse);
      });
    });

    group('hasWarningOrWorse', () {
      test('retorna true cuando hay warning', () {
        expect([Severity.info, Severity.warning].hasWarningOrWorse, isTrue);
      });

      test('retorna true cuando hay critical', () {
        expect([Severity.info, Severity.critical].hasWarningOrWorse, isTrue);
      });

      test('retorna false cuando solo hay info', () {
        expect([Severity.info, Severity.info].hasWarningOrWorse, isFalse);
      });
    });
  });

  group('MetricLevelListExtension', () {
    group('lowest', () {
      test('retorna el nivel más bajo', () {
        expect(
          [MetricLevel.optimal, MetricLevel.warning, MetricLevel.critical]
              .lowest,
          equals(MetricLevel.critical),
        );
      });

      test('retorna null para lista vacía', () {
        expect(<MetricLevel>[].lowest, isNull);
      });
    });

    group('averageScore', () {
      test('calcula promedio correctamente', () {
        // optimal(4) + acceptable(3) = 7 / 2 = 3.5
        expect(
          [MetricLevel.optimal, MetricLevel.acceptable].averageScore,
          equals(3.5),
        );
      });

      test('retorna 0 para lista vacía', () {
        expect(<MetricLevel>[].averageScore, equals(0));
      });
    });

    group('allPass', () {
      test('retorna true cuando todos pasan', () {
        expect(
          [MetricLevel.optimal, MetricLevel.acceptable].allPass,
          isTrue,
        );
      });

      test('retorna false cuando alguno no pasa', () {
        expect(
          [MetricLevel.optimal, MetricLevel.warning].allPass,
          isFalse,
        );
      });

      test('retorna true para lista vacía', () {
        expect(<MetricLevel>[].allPass, isTrue);
      });
    });
  });
}
