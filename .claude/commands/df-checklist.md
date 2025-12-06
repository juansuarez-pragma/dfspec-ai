---
description: Genera checklist de calidad para verificacion de feature
allowed-tools: Read, Write, Glob
---

# Comando: df-checklist

Eres un agente QA especializado en crear checklists de verificacion.

## Tarea
Genera checklist de calidad para: $ARGUMENTS

## Proceso Obligatorio

### FASE 1: Cargar Contexto

1. **Identificar feature:**
   - Si $ARGUMENTS tiene nombre → usar ese
   - Si vacio → detectar via DFSPEC_FEATURE o branch

2. **Cargar documentos:**
   - Read: specs/[feature]/spec.md
   - Read: specs/[feature]/plan.md
   - Read: specs/[feature]/tasks.md (si existe)

### FASE 2: Extraer Criterios

**De spec.md:**
- Todos los CA-XX (criterios de aceptacion)
- Todos los RNF-XX (requisitos no funcionales)
- Restricciones mencionadas

**De plan.md:**
- Consideraciones tecnicas
- Riesgos identificados

**De tasks.md:**
- Criterios de completitud por tarea
- Archivos a verificar

### FASE 3: Determinar Tipo de Feature

| Tipo | Enfasis |
|------|---------|
| **UI Feature** | Tests de widget, accessibility, responsive |
| **API Feature** | Validacion, error handling, retry logic |
| **Data Feature** | Persistencia, migraciones, cache |
| **Auth Feature** | Seguridad extra, session management |

### FASE 4: Generar Checklist

Crear `specs/[feature]/checklist.md`:

```markdown
# Checklist de Calidad: [Feature Name]

## Metadata
- Feature: [branch]
- Tipo: [UI|API|Data|Auth]
- Generado: [fecha]
- Reviewer: ________________

---

## Estado General

- [ ] **READY FOR REVIEW** (marcar cuando todo este listo)

---

## 1. Criterios de Aceptacion

> Verificar que cada criterio del spec se cumple

### CA-01: [Nombre del criterio]
- [ ] DADO [contexto especifico]
- [ ] CUANDO [accion especifica]
- [ ] ENTONCES [resultado esperado]

### CA-02: [Nombre]
- [ ] DADO [contexto]
- [ ] CUANDO [accion]
- [ ] ENTONCES [resultado]

[... todos los CA del spec ...]

---

## 2. Tests

### Cobertura
- [ ] Cobertura total >= 85%
- [ ] Todas las entidades tienen test
- [ ] Todos los use cases tienen test
- [ ] Todos los repositories tienen test

### Ejecucion
- [ ] `dart test` pasa sin errores
- [ ] No hay tests skipped sin justificacion
- [ ] Tests corren en < 60 segundos

### Tipos de Test
- [ ] Unit tests para domain layer
- [ ] Unit tests para data layer
- [ ] Widget tests para presentation (si UI)
- [ ] Integration tests (si critico)

---

## 3. Calidad de Codigo

### Analisis Estatico
- [ ] `dart analyze` sin errores
- [ ] `dart analyze` sin warnings
- [ ] Sin infos criticos ignorados

### Formato
- [ ] `dart format` aplicado a todos los archivos
- [ ] Estilo consistente con resto del proyecto

### Clean Code
- [ ] No hay codigo comentado
- [ ] No hay `print()` en produccion
- [ ] No hay TODOs sin ticket asociado
- [ ] No hay hardcoded strings (usar constantes)
- [ ] Nombres descriptivos (variables, funciones, clases)

---

## 4. Arquitectura

### Clean Architecture
- [ ] `domain/` no importa `data/` ni `presentation/`
- [ ] `data/` solo importa `domain/`
- [ ] `presentation/` solo importa `domain/`

### Patrones Requeridos
- [ ] Entidades son inmutables (extienden Equatable)
- [ ] Models tienen `fromJson` y `toJson`
- [ ] Repositories implementan interfaces de domain
- [ ] Use cases tienen un solo metodo publico `call()`

### Separacion de Responsabilidades
- [ ] Un archivo = una clase/funcion principal
- [ ] Widgets no tienen logica de negocio
- [ ] DataSources no tienen logica de negocio

---

## 5. Performance

### Rendering (si UI)
- [ ] Frame budget < 16ms (60fps)
- [ ] No jank visible en animaciones
- [ ] No rebuilds innecesarios (usar const, keys)
- [ ] ListView.builder para listas largas

### Recursos
- [ ] Imagenes optimizadas
- [ ] No memory leaks (dispose controllers)
- [ ] Streams cerrados en dispose
- [ ] No llamadas innecesarias a setState

### Red (si API)
- [ ] Timeout configurado
- [ ] Retry logic implementado
- [ ] Cache funcionando (si aplica)

---

## 6. Seguridad

### Datos Sensibles
- [ ] No hay secrets en codigo (API keys, passwords)
- [ ] Datos sensibles en secure storage
- [ ] No logs de datos sensibles

### Input Validation
- [ ] Todos los inputs validados
- [ ] Sanitizacion de datos de usuario
- [ ] Limites de longitud definidos

### Red
- [ ] Solo HTTPS
- [ ] Certificados validados
- [ ] Headers de seguridad correctos

---

## 7. Documentacion

### Codigo
- [ ] Comentarios en APIs publicas
- [ ] Documentacion de parametros complejos
- [ ] No comentarios obvios

### Proyecto
- [ ] README actualizado (si cambios relevantes)
- [ ] CHANGELOG actualizado
- [ ] spec.md actualizado si hubo cambios de requisitos

---

## 8. Pre-Merge

### Git
- [ ] Branch actualizado con main/develop
- [ ] No hay merge conflicts
- [ ] Commits con mensajes claros
- [ ] No hay commits de "fix" consecutivos (squash)

### CI/CD
- [ ] Pipeline verde
- [ ] Todos los checks automaticos pasan

---

## Resumen de Aprobacion

| Categoria | Aprobado | Comentarios |
|-----------|----------|-------------|
| Criterios de Aceptacion | [ ] | |
| Tests | [ ] | |
| Calidad de Codigo | [ ] | |
| Arquitectura | [ ] | |
| Performance | [ ] | |
| Seguridad | [ ] | |
| Documentacion | [ ] | |
| Pre-Merge | [ ] | |

---

## Firma

- **Reviewer:** ________________
- **Fecha:** ________________
- **Decision:** [ ] APPROVED [ ] NEEDS WORK

### Si NEEDS WORK, listar items pendientes:
1.
2.
3.
```

## Personalizacion por Tipo

### Si es UI Feature, agregar:
```markdown
## UI Específico
- [ ] Responsive en mobile (<600px)
- [ ] Responsive en tablet (600-900px)
- [ ] Responsive en desktop (>900px)
- [ ] Dark mode funciona (si aplica)
- [ ] Accessibility labels en elementos interactivos
- [ ] Keyboard navigation funciona
```

### Si es Auth Feature, agregar:
```markdown
## Seguridad Auth
- [ ] Tokens en secure storage
- [ ] Refresh token implementado
- [ ] Logout limpia todos los datos
- [ ] Session timeout manejado
- [ ] Biometrics funciona (si aplica)
```

## Restricciones
- SIEMPRE incluir TODOS los CA del spec
- SIEMPRE verificar Clean Architecture
- SIEMPRE incluir seccion de tests
- NUNCA aprobar sin cobertura >= 85%
- SIEMPRE personalizar segun tipo de feature
