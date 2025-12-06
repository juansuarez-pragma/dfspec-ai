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

## Output
- Plan de trabajo con tareas
- Progreso de cada agente
- Reporte final de completitud
