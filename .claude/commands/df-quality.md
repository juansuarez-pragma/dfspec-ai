---
description: Analiza calidad de codigo con linting estricto
allowed-tools: Read, Edit, Bash, Glob, Grep
---

# Comando: df-quality

Eres un agente de calidad de codigo para Flutter/Dart.

## Tarea
Analiza calidad de: $ARGUMENTS

## Servicios CLI Disponibles

### Analisis de Calidad con DFSpec
Ejecuta el servicio de calidad integrado:
```bash
# Analisis completo
dart run dfspec quality analyze

# Solo complejidad
dart run dfspec quality complexity --max=10

# Solo documentacion
dart run dfspec quality docs --threshold=80

# Con formato JSON
dart run dfspec quality analyze --format=json

# Modo estricto (umbrales de Constitucion)
dart run dfspec quality analyze --strict
```

### Verificacion Constitucional
```bash
# Todos los quality gates
dart run dfspec verify --all

# Gate especifico
dart run dfspec verify --gate=complexity --max=8
dart run dfspec verify --gate=docs --threshold=85
```

## Proceso

1. **Ejecutar Analisis DFSpec**
   ```bash
   dart run dfspec quality analyze --strict
   ```

2. **Ejecutar Analisis Dart**
   ```bash
   dart analyze --fatal-infos
   dart format --set-exit-if-changed .
   ```

3. **Aplicar Correcciones**
   ```bash
   dart fix --apply
   dart format .
   ```

4. **Verificar Quality Gates**
   ```bash
   dart run dfspec verify --all --ci
   ```

## Reglas de Analisis

### Very Good Analysis
- avoid_dynamic_calls
- avoid_print (usar logger)
- public_member_api_docs
- prefer_single_quotes
- lines_longer_than_80_chars

### Metricas Constitucionales
- Complejidad ciclomatica: <10
- Complejidad cognitiva: <8
- LOC por archivo: <400
- Documentacion: >80%

## Output
- Reporte de calidad con score
- Issues criticos identificados
- Correcciones aplicadas
- Estado de quality gates

## Handoffs

### Entradas (otros comandos invocan df-quality)
- Desde `/df-verify`: cuando complexity gate falla
- Desde `/df-review`: para metricas de calidad detalladas
- Desde `/df-status`: como parte del dashboard de proyecto

### Salidas (df-quality invoca otros comandos)
- Si arquitectura comprometida: `/df-review` para analisis SOLID
- Si documentacion falta: `/df-docs` para generar
- Si tests insuficientes: `/df-test` para cobertura
- Si hay vulnerabilidades: `/df-security` para OWASP
