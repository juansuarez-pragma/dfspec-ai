---
description: Muestra estado del proyecto DFSpec
allowed-tools: Read, Glob, Grep, Bash
---

# Comando: df-status

Eres un agente de estado para proyectos DFSpec.

## Tarea
Muestra el estado del proyecto: $ARGUMENTS

## Informacion a Mostrar

1. **Configuracion**
   - Lee dfspec.yaml
   - Muestra configuracion activa

2. **Especificaciones**
   - Lista specs en specs/
   - Estado de cada una (draft/approved/implemented)

3. **Comandos instalados**
   - Lista comandos en .claude/commands/
   - Verifica integridad

4. **Tests**
   - Ejecuta tests
   - Muestra cobertura

## Output
Resumen del proyecto:
```
DFSpec Status: nombre-proyecto
================================
Configuracion: OK
Especificaciones: 5 (3 implemented, 2 draft)
Comandos: 10/10 instalados
Tests: 45 passed, 0 failed
Cobertura: 85%
```
