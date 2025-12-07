---
description: Analiza seguridad siguiendo OWASP Mobile Top 10
allowed-tools: Read, Glob, Grep, WebSearch, Task
---

# Comando: df-security

Eres un agente de seguridad para aplicaciones Flutter.

## Tarea
Analiza seguridad de: $ARGUMENTS

## OWASP Mobile Top 10

1. **M1: Uso inapropiado de plataforma**
   - Permisos excesivos
   - Uso incorrecto de APIs

2. **M2: Almacenamiento inseguro**
   - Datos sensibles en SharedPreferences
   - Sin encriptacion

3. **M3: Comunicacion insegura**
   - HTTP sin TLS
   - Certificate pinning

4. **M4: Autenticacion insegura**
   - Tokens expuestos
   - Sesiones sin timeout

5. **M5: Criptografia insuficiente**
   - Algoritmos debiles
   - Keys hardcodeadas

## Servicios CLI Disponibles

### Analisis de Calidad
```bash
# Analisis de seguridad integrado
dart run dfspec quality analyze --metrics=security

# Analisis completo
dart run dfspec quality analyze --all
```

### Verificacion
```bash
# Verificar quality gates
dart run dfspec verify --all
```

### Dependencias Seguras
```bash
# Verificar vulnerabilidades en dependencias
dart pub outdated

# Ver arbol de dependencias
dart pub deps
```

### Reportes
```bash
# Generar reporte de seguridad
dart run dfspec report --project --save
```

## Proceso

1. **Ejecutar analisis de calidad**
   ```bash
   dart run dfspec quality analyze --all
   ```

2. **Revisar dependencias**
   ```bash
   dart pub outdated
   ```

3. **Analizar codigo manualmente** usando checklist OWASP

4. **Documentar hallazgos** con severidad

## Output
Reporte de seguridad con:
- Vulnerabilidades por categoria (Alta/Media/Baja)
- Codigo problematico
- Recomendaciones de correccion

## Handoffs

### Entradas (otros comandos invocan df-security)
- Desde `/df-orchestrate`: como parte del pipeline de calidad
- Desde `/df-review`: cuando se detectan patrones inseguros
- Desde `/df-verify`: verificacion pre-release

### Salidas (df-security invoca otros comandos)
- Si hay dependencias vulnerables: `/df-deps` para actualizar
- Si hay problemas de implementacion: `/df-implement` para corregir
- Si falta documentacion de seguridad: `/df-docs`
- Para verificar fixes: `/df-verify` despues de corregir
