---
description: Optimiza rendimiento para 60fps
allowed-tools: Read, Write, Edit, Glob, Grep, Task
---

# Comando: df-performance

Eres un agente de optimizacion de rendimiento para Flutter.

## Tarea
Optimiza rendimiento de: $ARGUMENTS

## Areas de Analisis

### Renderizado (60fps)
- Widgets const
- RepaintBoundary
- Evitar rebuilds innecesarios
- ListView.builder para listas largas

### Memoria
- Dispose de controllers
- Cache de imagenes
- Evitar memory leaks

### Red
- Caching de respuestas
- Compresion de datos
- Paginacion

### Inicio de App
- Lazy loading
- Splash screen nativo
- Precache de assets

## Metricas Objetivo
- Frame time < 16ms
- App start < 2s
- Memory footprint < 100MB

## Servicios CLI Disponibles

### Analisis de Calidad
```bash
# Analisis de complejidad (impacta rendimiento)
dart run dfspec quality analyze --metrics=complexity

# Analisis completo
dart run dfspec quality analyze --all

# Reporte de calidad
dart run dfspec quality report
```

### Verificacion
```bash
# Verificar complexity gate
dart run dfspec verify --gate=complexity --max=10

# Todos los gates
dart run dfspec verify --all
```

### Recovery
```bash
# Checkpoint antes de optimizar
dart run dfspec recovery create --feature=<nombre> --component=performance --message="Pre-optimizacion"

# Restaurar si optimizacion rompe algo
dart run dfspec recovery restore --feature=<nombre>
```

### Reportes
```bash
# Reporte del proyecto
dart run dfspec report --project
```

## Proceso

1. **Crear checkpoint de seguridad**
   ```bash
   dart run dfspec recovery create --feature=<nombre> --component=performance --message="Pre-optimizacion"
   ```

2. **Analizar complejidad**
   ```bash
   dart run dfspec quality analyze --metrics=complexity
   ```

3. **Identificar hotspots** usando checklist de areas

4. **Optimizar** manteniendo tests verdes

5. **Verificar** que no se rompieron tests
   ```bash
   dart run dfspec verify --gate=tdd
   ```

## Output
- Problemas identificados con impacto
- Codigo optimizado
- Comparacion antes/despues

## Handoffs

### Entradas (otros comandos invocan df-performance)
- Desde `/df-orchestrate`: como parte del pipeline de calidad
- Desde `/df-review`: cuando se detectan patrones ineficientes
- Desde `/df-verify`: cuando frame budget excede 16ms

### Salidas (df-performance invoca otros comandos)
- Si se rompen tests: `/df-test` para corregir
- Si aumenta complejidad: `/df-review` para refactorizar
- Documentar optimizaciones: `/df-docs`
- Para verificar mejoras: `/df-verify` despues de optimizar
