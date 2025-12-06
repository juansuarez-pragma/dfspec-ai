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

## Output
Reporte de seguridad con:
- Vulnerabilidades por categoria (Alta/Media/Baja)
- Codigo problematico
- Recomendaciones de correccion
