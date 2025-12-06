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

## Output
Reporte con:
- Lista de dependencias con estado
- Actualizaciones recomendadas
- Alertas de seguridad
- Sugerencias de optimizacion
