# DFReport - Agente de Reportes de Features

Agente especializado en la generación de reportes de estado y progreso
de features siguiendo los estándares DFSpec.

## Principios

### Reportes Objetivos

Los reportes deben ser:
- **Precisos**: Basados en métricas reales del código
- **Accionables**: Con recomendaciones claras
- **Comparables**: Formato consistente entre features

### Métricas Clave

| Métrica | Umbral Óptimo | Fuente |
|---------|---------------|--------|
| Cobertura | >= 85% | Constitución Art. 7 |
| Complejidad | < 10 | Constitución Art. 8 |
| Documentación | >= 80% | Constitución Art. 9 |
| TDD Correspondencia | 100% | Constitución Art. 1-3 |

## Uso

### Generar Reporte de Feature

```dart
import 'package:dfspec/src/services/report_generator.dart';

final generator = ReportGenerator(projectRoot: '.');

// Generar reporte
final report = await generator.generateFeatureReport('city-search');

// Ver resumen
print(report.toMarkdown());

// Guardar como archivo
await generator.saveFeatureReport(report);
```

### Generar Reporte de Proyecto

```dart
final projectReport = await generator.generateProjectReport();

// Ver estado general
print('Progreso: ${(projectReport.overallProgress * 100).toStringAsFixed(1)}%');
print('Cobertura: ${(projectReport.averageCoverage * 100).toStringAsFixed(1)}%');

// Guardar
await generator.saveProjectReport(projectReport);
```

## Estructura del Reporte

### Feature Report

```markdown
# Feature Report: city-search

**Estado:** ✅ Implementada
**Generado:** 2024-06-15

> Búsqueda de ciudades por nombre

## Métricas

| Métrica | Valor | Estado |
|---------|-------|--------|
| Progreso | 100% | ✅ |
| Cobertura | 92% | ✅ |
| Complejidad | 5.2 | ✅ |
| Documentación | 85% | ✅ |

## Componentes

### Domain
| Componente | Tipo | Estado | Cobertura |
|------------|------|--------|-----------|
| CityEntity | Entity | ✅ | 95% |
| SearchCities | Use Case | ✅ | 90% |

### Data
...

## Issues
- 🔵 **Info**: Considerar agregar más tests de edge cases

## Recomendaciones
- La feature cumple con todos los estándares de calidad
```

### Project Report

```markdown
# Project Report: MyApp

**Versión:** 1.0.0
**Generado:** 2024-06-15

## Resumen

| Métrica | Valor |
|---------|-------|
| Total Features | 5 |
| Completadas | 3 |
| Progreso | 60% |
| Cobertura Promedio | 87% |

## Features

| Feature | Estado | Progreso | Cobertura |
|---------|--------|----------|-----------|
| city-search | 🎯 | 100% | 92% |
| user-auth | 🔨 | 75% | 85% |
| settings | 📋 | 0% | - |
```

## Estados de Feature

| Estado | Icono | Descripción |
|--------|-------|-------------|
| Planned | 📋 | Especificación creada, no iniciada |
| In Progress | 🔨 | En desarrollo activo |
| Implemented | ✅ | Código completo, pendiente verificación |
| Verified | 🎯 | Pasa todos los quality gates |
| Blocked | 🚫 | Bloqueada por issues |
| Deprecated | ⚠️ | Cancelada o deprecada |

## Estados de Componente

| Estado | Icono | Condición |
|--------|-------|-----------|
| Pending | ⏳ | Sin archivo de test |
| In Progress | 🔄 | Tiene test, cobertura < 80% |
| Complete | ✅ | Cobertura >= 80% |
| Failed | ❌ | Tests fallando |

## Detección de Issues

El sistema detecta automáticamente:

### Críticos (🔴)
- Componentes sin tests correspondientes
- Cobertura < 50%
- Complejidad > 15

### Warnings (🟠)
- Cobertura < 85%
- Complejidad > 10
- Documentación < 80%

### Info (🔵)
- Sugerencias de mejora
- Optimizaciones opcionales

## Capas de Arquitectura

El reporte agrupa componentes por capa de Clean Architecture:

```
┌─────────────────┐
│   Presentation  │  Pages, Widgets, Providers
├─────────────────┤
│      Data       │  Models, DataSources, Repos Impl
├─────────────────┤
│     Domain      │  Entities, Use Cases, Repos
└─────────────────┘
```

## Tipos de Componente

### Domain
- **Entity**: Entidades de negocio
- **UseCase**: Casos de uso
- **Repository**: Interfaces de repositorio

### Data
- **Model**: Modelos de datos (JSON)
- **DataSource**: Fuentes de datos (API, DB)
- **RepositoryImpl**: Implementaciones de repositorio

### Presentation
- **Widget**: Componentes de UI
- **StateManager**: Providers, BLoCs, Controllers

## Integración con CI/CD

Los reportes pueden integrarse en el pipeline:

```yaml
- name: Generate Feature Reports
  run: |
    dart run bin/dfspec.dart report --feature=city-search
    dart run bin/dfspec.dart report --project

- name: Upload Reports
  uses: actions/upload-artifact@v4
  with:
    name: feature-reports
    path: docs/reports/
```

## Comando CLI

```bash
# Reporte de feature específica
dfspec report --feature city-search

# Reporte de proyecto completo
dfspec report --project

# Guardar en ubicación específica
dfspec report --feature city-search --output reports/

# Formato JSON
dfspec report --feature city-search --format json
```

## Recomendaciones Automáticas

El sistema genera recomendaciones basadas en:

1. **Cobertura baja**: Sugerir agregar más tests
2. **Alta complejidad**: Sugerir refactorización
3. **Sin documentación**: Sugerir agregar DartDoc
4. **Componentes pendientes**: Listar lo que falta implementar

## Ejemplo de Uso en Flujo SDD

```
1. /df-spec city-search       # Crear especificación
2. /df-plan city-search       # Generar plan
3. /df-implement city-search  # Implementar con TDD

4. dfspec report --feature city-search  # Ver progreso
   → Progreso: 60%
   → Issues: 2 componentes pendientes

5. Continuar implementación...

6. dfspec report --feature city-search  # Verificar
   → Progreso: 100%
   → Estado: Verified ✅

7. /df-verify city-search     # Verificación final
```

## API Programática

### FeatureReport

```dart
// Acceder a métricas
print(report.metrics.progress);        // 0.0 - 1.0
print(report.metrics.coverage);        // 0.0 - 1.0
print(report.metrics.averageComplexity);

// Componentes por capa
final domainComponents = report.componentsByLayer[ArchitectureLayer.domain];

// Issues críticos
if (report.hasCriticalIssues) {
  for (final issue in report.issues) {
    print('${issue.severity.icon} ${issue.title}');
  }
}

// Serialización
final json = report.toJson();
final restored = FeatureReport.fromJson(json);
```

### ProjectReport

```dart
// Métricas globales
print(projectReport.totalFeatures);
print(projectReport.completedFeatures);
print(projectReport.overallProgress);

// Features por estado
final verified = projectReport.featuresByStatus[FeatureStatus.verified];
final inProgress = projectReport.featuresByStatus[FeatureStatus.inProgress];
```

## Referencias

- [Feature Report Model](../lib/src/models/feature_report.dart)
- [Report Generator Service](../lib/src/services/report_generator.dart)
- [Constitución DFSpec](../memory/constitution.md)
- [Quality Analyzer](../lib/src/services/quality_analyzer.dart)
