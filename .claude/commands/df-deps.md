---
description: Analiza y gestiona dependencias del proyecto
allowed-tools: Read, Write, Edit, Bash, WebFetch, WebSearch
---

# Comando: df-deps

Eres un agente especializado en gestion de dependencias para Flutter/Dart.

## Tarea
Analiza dependencias de: $ARGUMENTS

## Proceso

1. **Analisis de pubspec.yaml**
   - Lee dependencias actuales
   - Identifica versiones desactualizadas
   - Detecta dependencias no usadas

2. **Verificacion de Seguridad**
   - Busca vulnerabilidades conocidas
   - Verifica licencias compatibles
   - Revisa advisories de seguridad

3. **Optimizacion**
   - Sugiere alternativas mas ligeras
   - Identifica dependencias duplicadas
   - Recomienda tree-shaking

## Comandos Utiles

```bash
dart pub outdated          # Ver desactualizadas
dart pub deps              # Arbol de dependencias
dart pub upgrade           # Actualizar compatibles
dart pub upgrade --major-versions  # Actualizar majors
```

## Verificaciones

- [ ] Todas las dependencias tienen version fija
- [ ] No hay dependencias con vulnerabilidades
- [ ] Licencias son compatibles (MIT, BSD, Apache)
- [ ] No hay dependencias abandonadas (>1 año sin update)

## Servicios CLI Disponibles

### Gestion de Dependencias (MCP)
```bash
# Obtener dependencias
mcp__dart__pub get

# Agregar dependencia
mcp__dart__pub add <paquete>

# Ver desactualizadas
mcp__dart__pub outdated
```

### Busqueda de Paquetes
```bash
# Buscar en pub.dev
mcp__dart__pub_dev_search --query="<termino>"
```

### Reportes
```bash
# Reporte del proyecto
dart run dfspec report --project

# Analisis de calidad
dart run dfspec quality analyze --all
```

### Recovery
```bash
# Checkpoint antes de actualizar
dart run dfspec recovery create --feature=deps --component=dependencies --message="Pre-actualizacion"

# Restaurar si actualización falla
dart run dfspec recovery restore --feature=deps
```

## Proceso

1. **Crear checkpoint**
   ```bash
   dart run dfspec recovery create --feature=deps --component=dependencies --message="Pre-actualizacion"
   ```

2. **Analizar dependencias**
   ```bash
   dart pub outdated
   dart pub deps
   ```

3. **Verificar seguridad** usando WebSearch para advisories

4. **Actualizar** si es seguro
   ```bash
   dart pub upgrade
   ```

5. **Ejecutar tests** para verificar compatibilidad
   ```bash
   dart run dfspec verify --gate=tdd
   ```

## Output
Reporte con:
- Lista de dependencias con estado
- Actualizaciones recomendadas
- Alertas de seguridad
- Sugerencias de optimizacion

## Handoffs

### Entradas (otros comandos invocan df-deps)
- Desde `/df-spec`: al analizar dependencias de nueva feature
- Desde `/df-plan`: antes de implementar
- Desde `/df-security`: cuando se detectan vulnerabilidades

### Salidas (df-deps invoca otros comandos)
- Si tests fallan tras actualizar: `/df-test` para diagnosticar
- Si hay vulnerabilidades: `/df-security` para analisis profundo
- Documentar cambios: `/df-docs` para changelog
- Para verificar compatibilidad: `/df-verify --gate=tdd`
