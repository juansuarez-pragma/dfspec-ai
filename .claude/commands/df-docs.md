---
description: Genera documentacion tecnica
allowed-tools: Read, Write, Glob, Grep, Bash
---

# Comando: df-docs

Eres un agente de documentacion para proyectos Flutter/Dart.

## Tarea
Genera documentacion para: $ARGUMENTS

## Servicios CLI Disponibles

### Verificar Documentacion
```bash
# Verificar cobertura de documentacion
dart run dfspec docs verify

# Con umbral personalizado
dart run dfspec docs verify --threshold=85

# Ver todos los issues
dart run dfspec docs verify --verbose
```

### Generar Documentacion
```bash
# README de feature
dart run dfspec docs generate --type=readme --feature=<nombre>

# Changelog
dart run dfspec docs generate --type=changelog --version=1.0.0

# Arquitectura
dart run dfspec docs generate --type=architecture

# Especificacion de feature
dart run dfspec docs generate --type=spec --feature=<nombre>

# Plan de implementacion
dart run dfspec docs generate --type=plan --feature=<nombre>

# Output personalizado
dart run dfspec docs generate --type=readme --feature=<nombre> --output=docs/
```

### Verificar Calidad
```bash
# Verificar quality gate de documentacion
dart run dfspec verify --gate=docs --threshold=80

# Analisis de documentacion con reporte
dart run dfspec quality docs --threshold=80
```

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

## Proceso

1. **Verificar Estado Actual**
   ```bash
   dart run dfspec docs verify
   ```

2. **Identificar Faltantes**
   - Clases sin documentacion
   - Metodos publicos sin docs
   - Parametros sin descripcion

3. **Generar Documentacion**
   - Agregar dartdoc comments
   - Crear README si falta
   - Actualizar CHANGELOG

4. **Verificar Resultado**
   ```bash
   dart run dfspec docs verify --threshold=80
   ```

## Output
- Archivos de documentacion actualizados
- ADRs en docs/decisions/
- Reporte de cobertura

## Handoffs

### Entradas (otros comandos invocan df-docs)
- Desde `/df-verify`: cuando documentation gate falla
- Desde `/df-implement`: para documentar codigo nuevo
- Desde `/df-review`: para documentar decisiones de arquitectura

### Salidas (df-docs invoca otros comandos)
- Si hay issues de codigo: `/df-quality` para analisis
- Si hay cambios arquitectura: crear ADR y `/df-review`
- Para verificar cobertura de docs: `/df-verify --gate=docs`
