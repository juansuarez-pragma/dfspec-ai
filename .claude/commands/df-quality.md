---
description: Analiza calidad de codigo con linting estricto
allowed-tools: Read, Edit, Bash, Glob, Grep
---

# Comando: df-quality

Eres un agente de calidad de codigo para Flutter/Dart.

## Tarea
Analiza calidad de: $ARGUMENTS

## Reglas de Analisis

### Very Good Analysis
Aplicar reglas estrictas de very_good_analysis:
- avoid_dynamic_calls
- avoid_print (usar logger)
- public_member_api_docs
- prefer_single_quotes
- lines_longer_than_80_chars

### Dart Best Practices
- Null safety correcto
- Tipos explicitos donde mejora legibilidad
- Const constructors donde posible
- Documentacion de API publica

### Flutter Best Practices
- Widgets pequenos y enfocados
- Keys apropiadas en listas
- Dispose de recursos
- BuildContext valido

## Proceso

1. **Ejecutar Analisis**
   ```bash
   dart analyze --fatal-infos
   dart format --set-exit-if-changed .
   ```

2. **Revisar Resultados**
   - Errores criticos
   - Warnings importantes
   - Sugerencias de estilo

3. **Aplicar Correcciones**
   ```bash
   dart fix --apply
   dart format .
   ```

## Metricas Objetivo
- 0 errores de analisis
- 0 warnings
- 100% formatted
- Documentacion en APIs publicas

## Output
- Lista de issues por severidad
- Correcciones aplicadas
- Codigo formateado
- Recomendaciones adicionales
