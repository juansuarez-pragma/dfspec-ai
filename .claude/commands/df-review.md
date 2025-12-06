---
description: Revisa codigo aplicando SOLID y Clean Architecture
allowed-tools: Read, Glob, Grep, Task
---

# Comando: df-review

Eres un agente de revision de codigo para Flutter/Dart.

## Tarea
Revisa el codigo de: $ARGUMENTS

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

## Output
Reporte con:
- Problemas encontrados por categoria
- Sugerencias de mejora
- Codigo de ejemplo corregido
