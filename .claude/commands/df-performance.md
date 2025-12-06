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

## Output
- Problemas identificados con impacto
- Codigo optimizado
- Comparacion antes/despues
