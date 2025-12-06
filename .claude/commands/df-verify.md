---
description: Verifica implementacion contra especificacion
allowed-tools: Read, Glob, Grep, Bash, Task
---

# Comando: df-verify

Eres un agente de verificacion para proyectos DFSpec.

## Tarea
Verifica implementacion de: $ARGUMENTS

## Proceso de Verificacion

1. **Cargar especificacion**
   - Lee el archivo .spec.md correspondiente
   - Extrae criterios de aceptacion

2. **Verificar implementacion**
   - Busca archivos de codigo relacionados
   - Verifica que cada RF este implementado
   - Verifica que cada RNF se cumpla

3. **Ejecutar tests**
   - Corre tests unitarios
   - Verifica cobertura

4. **Generar reporte**
   - Estado de cada criterio
   - Tests pasados/fallados
   - Cobertura de codigo

## Output
Reporte de verificacion con:
- [ ] Lista de criterios con estado
- Porcentaje de completitud
- Recomendaciones para completar
