---
description: Verifica implementacion contra especificacion
allowed-tools: Read, Glob, Grep, Bash, Task
---

# Comando: df-verify

Eres un agente de verificacion para proyectos DFSpec.

## Tarea
Verifica implementacion de: $ARGUMENTS

## Servicios CLI Disponibles

### Verificacion Constitucional
```bash
# Verificar todos los quality gates
dart run dfspec verify --all

# Verificar gate especifico
dart run dfspec verify --gate=tdd
dart run dfspec verify --gate=architecture
dart run dfspec verify --gate=coverage --threshold=85
dart run dfspec verify --gate=complexity --max=10
dart run dfspec verify --gate=docs --threshold=80

# Modo CI (falla si no pasa)
dart run dfspec verify --all --ci

# Modo estricto
dart run dfspec verify --all --strict
```

### Reportes de Feature
```bash
# Generar reporte de feature
dart run dfspec report --feature=<nombre>

# Reporte en JSON
dart run dfspec report --feature=<nombre> --format=json

# Guardar reporte
dart run dfspec report --feature=<nombre> --save
```

### Verificacion de Documentacion
```bash
dart run dfspec docs verify --threshold=80
```

## Proceso de Verificacion

1. **Cargar Especificacion**
   - Leer `docs/specs/features/<feature>.spec.md`
   - Extraer criterios de aceptacion (CA)

2. **Verificar Quality Gates**
   ```bash
   dart run dfspec verify --all
   ```

3. **Ejecutar Tests**
   ```bash
   flutter test --coverage
   ```

4. **Generar Reporte**
   ```bash
   dart run dfspec report --feature=<nombre> --save
   ```

## Criterios de Verificacion

### TDD Gate
- Tests existen para cada componente
- Cobertura >= 85%
- Tests pasan

### Architecture Gate
- Estructura Clean Architecture
- Domain no importa Data/Presentation
- Dependencias correctas

### Coverage Gate
- Cobertura total >= 85%
- Domain >= 95%
- Data >= 90%

### Complexity Gate
- Complejidad ciclomatica < 10
- Complejidad cognitiva < 8

### Documentation Gate
- API publica documentada >= 80%

## Output
- Estado de cada quality gate
- Lista de criterios con estado
- Porcentaje de completitud
- Recomendaciones para completar

## Handoffs

### Entradas (otros comandos invocan df-verify)
- Desde `/df-implement`: verificacion final post-implementacion
- Desde `/df-orchestrate`: como parte del pipeline de verificacion
- Desde `/df-status`: para mostrar estado de quality gates

### Salidas (df-verify invoca otros comandos)
- Si fallan tests (TDD gate): `/df-test` para corregir
- Si falla arquitectura: `/df-review` para analisis SOLID
- Si falla complexity: `/df-quality` para analisis detallado
- Si falta documentacion: `/df-docs` para generar
- Si falla cobertura: `/df-test` para agregar tests
