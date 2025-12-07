---
description: Muestra estado del proyecto DFSpec
allowed-tools: Read, Glob, Grep, Bash
---

# Comando: df-status

Eres un agente de estado para proyectos DFSpec.

## Tarea
Muestra el estado del proyecto: $ARGUMENTS

## Servicios CLI Disponibles

### Reportes
```bash
# Reporte completo del proyecto
dart run dfspec report --project

# Reporte de feature especifica
dart run dfspec report --feature=<nombre>

# Guardar reporte
dart run dfspec report --project --save
```

### Verificacion
```bash
# Estado de quality gates
dart run dfspec verify --all

# Solo verificar sin fallar
dart run dfspec verify --all
```

### Cache
```bash
# Estadisticas del cache
dart run dfspec cache stats
```

### Recovery
```bash
# Reporte de recovery points
dart run dfspec recovery report

# Listar por feature
dart run dfspec recovery list --feature=<nombre>
```

## Informacion a Mostrar

1. **Configuracion**
   - Lee dfspec.yaml
   - Muestra configuracion activa

2. **Especificaciones**
   - Lista specs en docs/specs/features/
   - Estado de cada una (planned/implemented/verified)

3. **Quality Gates**
   ```bash
   dart run dfspec verify --all
   ```

4. **Reportes**
   ```bash
   dart run dfspec report --project
   ```

5. **Tests**
   - Ejecutar tests
   - Mostrar cobertura

6. **Recovery Points**
   ```bash
   dart run dfspec recovery report
   ```

## Output
Resumen del proyecto:
```
DFSpec Status: nombre-proyecto
================================
Configuracion: OK
Especificaciones: 5 (3 implemented, 2 planned)
Quality Gates: 4/5 pasando
Tests: 45 passed, 0 failed
Cobertura: 85%
Recovery Points: 12 estables
```

## Handoffs

### Entradas (otros comandos invocan df-status)
- Usuario: para ver dashboard general
- Desde `/df-orchestrate`: para evaluar siguiente paso

### Salidas (df-status sugiere comandos)
- Si quality gates fallan: `/df-verify` para detalles
- Si cobertura baja: `/df-test` para agregar tests
- Si falta documentacion: `/df-docs` para generar
- Si hay features pendientes: `/df-implement` para continuar
- Si hay muchas tareas: `/df-orchestrate` para automatizar
