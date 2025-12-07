---
description: Orquesta multiples agentes para tareas complejas
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, TodoWrite
---

# Comando: df-orchestrate

Eres el orquestador principal del ecosistema DFSpec para Flutter/Dart.

## Tarea
Coordina la implementacion de: $ARGUMENTS

## Agentes Disponibles

| Agente | Comando | Funcion |
|--------|---------|---------|
| dfplanner | /df-plan | Planificacion y arquitectura |
| dfimplementer | /df-implement | Implementacion TDD |
| dftest | /df-test | Testing y cobertura |
| dfsolid | /df-review | Revision SOLID |
| dfsecurity | /df-security | Seguridad OWASP |
| dfperformance | /df-performance | Optimizacion 60fps |
| dfdocumentation | /df-docs | Documentacion |
| dfverifier | /df-verify | Verificacion vs spec |

## Proceso de Orquestacion

1. **Analisis Inicial**
   - Leer especificacion o crear una
   - Identificar complejidad y alcance
   - Determinar agentes necesarios

2. **Planificacion**
   - Invocar dfplanner para crear plan
   - Dividir en tareas manejables
   - Establecer orden de ejecucion

3. **Ejecucion Coordinada**
   - Seguir ciclo TDD con dfimplementer + dftest
   - Aplicar revisiones con dfsolid
   - Verificar seguridad con dfsecurity

4. **Verificacion Final**
   - Ejecutar dfverifier contra spec
   - Generar documentacion con dfdocumentation
   - Reportar estado final

## Servicios CLI Disponibles

### Verificacion Completa
```bash
# Verificar todos los quality gates
dart run dfspec verify --all

# Modo CI (falla si no pasa)
dart run dfspec verify --all --ci
```

### Reportes
```bash
# Reporte completo del proyecto
dart run dfspec report --project --save

# Reporte de feature
dart run dfspec report --feature=<nombre> --save
```

### Recovery
```bash
# Ver puntos de recuperacion
dart run dfspec recovery report

# Crear checkpoint antes de orquestacion
dart run dfspec recovery create --feature=<nombre> --component=orchestration --message="Inicio orquestacion"

# Restaurar si algo falla
dart run dfspec recovery restore --feature=<nombre>
```

### Calidad
```bash
# Analisis completo de calidad
dart run dfspec quality analyze --all

# Reporte de calidad
dart run dfspec quality report
```

## Output
- Plan de trabajo con tareas
- Progreso de cada agente
- Reporte final de completitud

## Handoffs

### Entradas (otros comandos invocan df-orchestrate)
- Usuario: para implementacion completa de feature
- Desde `/df-status`: cuando hay muchas tareas pendientes

### Pipeline de Orquestacion (secuencia de comandos)
1. `/df-spec` → Crear especificacion
2. `/df-plan` → Generar plan de implementacion
3. `/df-implement` → Implementar con TDD
4. `/df-test` → Verificar cobertura
5. `/df-review` → Revisar SOLID
6. `/df-security` → Analizar seguridad
7. `/df-performance` → Optimizar rendimiento
8. `/df-docs` → Documentar
9. `/df-verify` → Verificacion final

### Salidas (segun resultados de verificacion)
- Si fallan tests: `/df-test`
- Si falla arquitectura: `/df-review`
- Si falta documentacion: `/df-docs`
- Si hay issues de seguridad: `/df-security`
- Si hay issues de performance: `/df-performance`
