---
description: Genera y ejecuta tests para una feature
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task
---

# Comando: df-test

Eres un agente de testing para Flutter/Dart.

## Tarea
Genera tests para: $ARGUMENTS

## Servicios CLI Disponibles

### Verificacion de Cobertura
```bash
# Verificar quality gate de cobertura
dart run dfspec verify --gate=coverage --threshold=85

# Verificar TDD gate
dart run dfspec verify --gate=tdd
```

### Recovery Points
```bash
# Crear checkpoint despues de tests verdes
dart run dfspec recovery create --feature=<nombre> --component=tests --message="Tests pasando"

# Restaurar si tests fallan
dart run dfspec recovery restore --feature=<nombre>

# Ver historial de checkpoints
dart run dfspec recovery list --feature=<nombre>
```

### Reportes
```bash
# Generar reporte de feature
dart run dfspec report --feature=<nombre>
```

## Tipos de Tests

1. **Unit Tests**
   - Cubren logica de negocio
   - Usan mocks para dependencias
   - Rapidos y aislados

2. **Widget Tests**
   - Verifican UI components
   - Usan WidgetTester
   - Prueban interacciones

3. **Integration Tests**
   - Flujos completos
   - Multiples componentes
   - Escenarios de usuario

## Estructura

```dart
void main() {
  group('NombreClase', () {
    late ClaseBajoTest sut; // System Under Test

    setUp(() {
      // Configuracion
    });

    test('deberia hacer X cuando Y', () {
      // Arrange
      // Act
      // Assert
    });
  });
}
```

## Proceso TDD

### 1. RED - Test que falla
```dart
test('deberia retornar X cuando Y', () {
  // Arrange
  final sut = MiClase();

  // Act
  final result = sut.metodo();

  // Assert
  expect(result, equals(expected));
});
```

### 2. GREEN - Implementar minimo
Crear implementacion minima para pasar el test.

### 3. REFACTOR - Mejorar
Refactorizar manteniendo tests verdes.

### 4. Checkpoint
```bash
# Crear recovery point despues de tests verdes
dart run dfspec recovery create --feature=<nombre> --component=<capa> --message="Tests verdes"
```

## Umbrales de Cobertura (Constitucion)

| Capa | Objetivo |
|------|----------|
| Domain | >= 95% |
| Data | >= 90% |
| Presentation | >= 80% |
| **Total** | **>= 85%** |

## Output
- Archivos de test siguiendo convencion _test.dart
- Cobertura minima 85%
- Recovery checkpoint si tests pasan
- Ejecuta tests y reporta resultados

## Handoffs

### Entradas (otros comandos invocan df-test)
- Desde `/df-implement`: ciclo TDD (RED → GREEN → REFACTOR)
- Desde `/df-verify`: cuando TDD o coverage gate falla
- Desde `/df-review`: para verificar que cambios no rompan tests

### Salidas (df-test invoca otros comandos)
- Si cobertura insuficiente: continuar agregando tests
- Si implementacion falta: `/df-implement` para completar
- Si quality gates fallan: `/df-verify` para detalles
- Si tests revelan bugs de arquitectura: `/df-review` para refactorizar
