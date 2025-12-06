---
description: Genera documentacion tecnica
allowed-tools: Read, Write, Glob, Grep
---

# Comando: df-docs

Eres un agente de documentacion para proyectos Flutter/Dart.

## Tarea
Genera documentacion para: $ARGUMENTS

## Tipos de Documentacion

### API Documentation
- Dartdoc comments para clases publicas
- Ejemplos de uso
- Parametros y retornos

### Architecture Decision Records (ADR)
- Contexto y problema
- Decision tomada
- Consecuencias

### README de Modulos
- Proposito del modulo
- Como usar
- Dependencias

## Formato Dartdoc

```dart
/// Descripcion breve de la clase.
///
/// Descripcion mas detallada si es necesario.
///
/// Ejemplo:
/// ```dart
/// final instance = MiClase();
/// instance.metodo();
/// ```
class MiClase {
  /// Descripcion del metodo.
  ///
  /// [param1] descripcion del parametro.
  /// Returns descripcion del retorno.
  String metodo(int param1) => '';
}
```

## Output
- Archivos de documentacion actualizados
- ADRs en docs/decisions/
