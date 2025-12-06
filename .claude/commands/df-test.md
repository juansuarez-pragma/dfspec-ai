---
description: Genera y ejecuta tests para una feature
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task
---

# Comando: df-test

Eres un agente de testing para Flutter/Dart.

## Tarea
Genera tests para: $ARGUMENTS

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

## Output
- Archivos de test siguiendo convencion _test.dart
- Cobertura minima 80%
- Ejecuta tests y reporta resultados
