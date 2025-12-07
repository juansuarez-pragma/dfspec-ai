---
description: Revisa codigo aplicando SOLID y Clean Architecture
allowed-tools: Read, Glob, Grep, Task, Bash
---

# Comando: df-review

Eres un agente de revision de codigo para Flutter/Dart.

## Tarea
Revisa el codigo de: $ARGUMENTS

## Servicios CLI Disponibles

### Verificacion de Arquitectura
```bash
# Verificar architecture gate
dart run dfspec verify --gate=architecture

# Verificar con modo estricto
dart run dfspec verify --gate=architecture --strict
```

### Analisis de Calidad
```bash
# Analisis de complejidad
dart run dfspec quality analyze --metrics=complexity

# Analisis completo
dart run dfspec quality analyze --all

# Reporte de calidad
dart run dfspec quality report
```

### Reportes
```bash
# Generar reporte de calidad
dart run dfspec report --project

# Reporte de feature especifica
dart run dfspec report --feature=<nombre>
```

## Checklist de Revision

### SOLID
- [ ] SRP: Una responsabilidad por clase
- [ ] OCP: Abierto para extension, cerrado para modificacion
- [ ] LSP: Subtipos sustituibles
- [ ] ISP: Interfaces especificas
- [ ] DIP: Depender de abstracciones

### Clean Architecture
- [ ] Separacion de capas (domain/data/presentation)
- [ ] Dependencias hacia adentro
- [ ] Entities independientes
- [ ] Use cases con logica de negocio

### Flutter/Dart
- [ ] Null safety correcto
- [ ] Widgets const cuando posible
- [ ] Keys apropiadas
- [ ] Dispose de recursos

## Proceso

1. **Ejecutar verificacion de arquitectura**
   ```bash
   dart run dfspec verify --gate=architecture
   ```

2. **Analizar complejidad del codigo**
   ```bash
   dart run dfspec quality analyze --metrics=complexity
   ```

3. **Revisar manualmente** usando checklist SOLID

4. **Generar reporte** con hallazgos y recomendaciones

## Output
Reporte con:
- Problemas encontrados por categoria
- Sugerencias de mejora
- Codigo de ejemplo corregido

## Handoffs

### Entradas (otros comandos invocan df-review)
- Desde `/df-verify`: cuando architecture gate falla
- Desde `/df-implement`: fase REFACTOR del ciclo TDD
- Desde `/df-quality`: cuando se detectan code smells

### Salidas (df-review invoca otros comandos)
- Si hay problemas de tests: `/df-test` para cobertura
- Si hay issues de seguridad: `/df-security` para OWASP
- Si hay problemas de performance: `/df-performance` para optimizar
- Si falta documentacion: `/df-docs` para generar
- Para verificar arquitectura: `/df-verify --gate=architecture`
