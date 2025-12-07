import 'dart:io';

import 'package:dfspec/src/models/traceability.dart';
import 'package:dfspec/src/parsers/user_story_parser.dart';
import 'package:path/path.dart' as p;

/// Analizador de consistencia entre artefactos SDD.
///
/// Construye la matriz de trazabilidad y detecta:
/// - Requisitos sin User Stories
/// - User Stories sin criterios de aceptación
/// - User Stories sin tareas
/// - Tareas sin implementación
/// - Código sin tests
/// - Tests sin código correspondiente
class ConsistencyAnalyzer {
  /// Crea un analizador de consistencia.
  ConsistencyAnalyzer({String? projectRoot})
      : _projectRoot = projectRoot ?? Directory.current.path;

  final String _projectRoot;

  /// Patrones para detectar referencias a IDs.
  static final _usPattern = RegExp(r'US-(\d+)', caseSensitive: false);
  static final _acPattern = RegExp(r'AC-(\d+)', caseSensitive: false);
  static final _taskPattern = RegExp(r'TASK-(\d+)', caseSensitive: false);

  /// Analiza la consistencia de una feature.
  Future<ConsistencyReport> analyze(String featureId) async {
    final matrix = await buildMatrix(featureId);
    final issues = <ConsistencyIssue>[];
    final suggestions = <String>[];

    // Detectar requisitos huérfanos
    for (final req in matrix.requirements) {
      final links = matrix.linksFrom(req);
      if (links.isEmpty) {
        issues.add(
          ConsistencyIssue(
            code: 'ORPHAN_REQ',
            message: 'Requisito ${req.id} no tiene User Stories asociadas',
            severity: IssueSeverity.critical,
            artifact: req,
            suggestion: 'Crear User Story para implementar ${req.id}',
          ),
        );
      }
    }

    // Detectar User Stories sin ACs
    for (final us in matrix.userStories) {
      final hasACs = matrix
          .linksFrom(us)
          .any((l) => l.target.type == ArtifactType.acceptanceCriteria);
      if (!hasACs) {
        issues.add(
          ConsistencyIssue(
            code: 'US_NO_AC',
            message: 'User Story ${us.id} no tiene criterios de aceptación',
            severity: IssueSeverity.critical,
            artifact: us,
            suggestion:
                'Agregar criterios de aceptación con formato Given/When/Then',
          ),
        );
      }
    }

    // Detectar User Stories sin tareas
    for (final us in matrix.userStories) {
      final hasTasks = matrix
          .linksFrom(us)
          .any((l) => l.target.type == ArtifactType.task);
      if (!hasTasks) {
        issues.add(
          ConsistencyIssue(
            code: 'US_NO_TASKS',
            message: 'User Story ${us.id} no tiene tareas definidas',
            severity: IssueSeverity.warning,
            artifact: us,
            suggestion: 'Ejecutar /df-tasks para generar tareas',
          ),
        );
      }
    }

    // Detectar tareas sin implementación
    for (final task in matrix.tasks) {
      final hasCode = matrix
          .linksFrom(task)
          .any((l) => l.target.type == ArtifactType.sourceCode);
      if (!hasCode) {
        issues.add(
          ConsistencyIssue(
            code: 'TASK_NO_CODE',
            message: 'Tarea ${task.id} no tiene código implementado',
            severity: IssueSeverity.warning,
            artifact: task,
            suggestion: 'Implementar ${task.title}',
          ),
        );
      }
    }

    // Detectar código sin tests
    for (final code in matrix.sourceCode) {
      final hasTests = matrix
          .linksTo(code)
          .any((l) => l.source.type == ArtifactType.test);
      if (!hasTests) {
        issues.add(
          ConsistencyIssue(
            code: 'CODE_NO_TEST',
            message: 'Archivo ${code.sourcePath} no tiene tests',
            severity: IssueSeverity.warning,
            artifact: code,
            suggestion: 'Crear test en test/unit/${_testFileName(code)}',
          ),
        );
      }
    }

    // Detectar tests sin código
    for (final test in matrix.tests) {
      final hasCode = matrix
          .linksFrom(test)
          .any((l) => l.target.type == ArtifactType.sourceCode);
      if (!hasCode) {
        issues.add(
          ConsistencyIssue(
            code: 'TEST_NO_CODE',
            message: 'Test ${test.sourcePath} no tiene código correspondiente',
            severity: IssueSeverity.info,
            artifact: test,
            suggestion: 'Verificar que el test prueba código existente',
          ),
        );
      }
    }

    // Generar sugerencias globales
    if (matrix.coveragePercentage < 80) {
      suggestions.add(
        'Cobertura de trazabilidad: ${matrix.coveragePercentage.toStringAsFixed(1)}%. '
        'Objetivo: >80%',
      );
    }

    if (matrix.orphanArtifacts.isNotEmpty) {
      suggestions.add(
        '${matrix.orphanArtifacts.length} artefactos huérfanos detectados. '
        'Revisar matriz de trazabilidad.',
      );
    }

    if (matrix.userStories.isEmpty && matrix.requirements.isNotEmpty) {
      suggestions.add(
        'Hay requisitos pero no User Stories. '
        'Ejecutar /df-spec para crear especificación.',
      );
    }

    return ConsistencyReport(
      matrix: matrix,
      issues: issues,
      suggestions: suggestions,
    );
  }

  /// Construye la matriz de trazabilidad para una feature.
  Future<TraceabilityMatrix> buildMatrix(String featureId) async {
    final artifacts = <TraceableArtifact>[];
    final links = <TraceabilityLink>[];

    // 1. Parsear spec.md para requisitos y user stories
    await _parseSpec(featureId, artifacts, links);

    // 2. Parsear tasks.md para tareas
    await _parseTasks(featureId, artifacts, links);

    // 3. Escanear lib/ para código fuente
    await _scanSourceCode(featureId, artifacts, links);

    // 4. Escanear test/ para tests
    await _scanTests(featureId, artifacts, links);

    // 5. Inferir links entre artefactos
    _inferLinks(artifacts, links);

    return TraceabilityMatrix(
      featureId: featureId,
      artifacts: artifacts,
      links: links,
      generatedAt: DateTime.now(),
    );
  }

  Future<void> _parseSpec(
    String featureId,
    List<TraceableArtifact> artifacts,
    List<TraceabilityLink> links,
  ) async {
    final specPath = p.join(_projectRoot, 'specs/features/$featureId/spec.md');
    final specFile = File(specPath);

    if (!specFile.existsSync()) return;

    final content = specFile.readAsStringSync();
    final lines = content.split('\n');

    // Extraer requisitos (## Requisitos Funcionales / ## Requisitos No Funcionales)
    var inReqSection = false;
    var reqCounter = 1;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.contains('## Requisitos')) {
        inReqSection = true;
        continue;
      }

      if (line.startsWith('## ') && inReqSection) {
        inReqSection = false;
      }

      if (inReqSection && line.trim().startsWith('- ')) {
        final reqText = line.trim().substring(2).trim();
        if (reqText.isNotEmpty) {
          final reqId = 'REQ-${reqCounter.toString().padLeft(3, '0')}';
          artifacts.add(
            TraceableArtifact(
              id: reqId,
              type: ArtifactType.requirement,
              title: reqText,
              sourcePath: specPath,
              lineNumber: i + 1,
            ),
          );
          reqCounter++;
        }
      }
    }

    // Extraer User Stories usando el parser existente
    final parser = UserStoryParser();
    final collection = parser.parse(content);
    final stories = collection.stories;

    for (final story in stories) {
      final usArtifact = TraceableArtifact(
        id: story.id,
        type: ArtifactType.userStory,
        title: story.title,
        sourcePath: specPath,
        metadata: {
          'priority': story.priority.code,
          'as_a': story.asA,
          'i_want': story.iWant,
          'so_that': story.soThat,
        },
      );
      artifacts.add(usArtifact);

      // Agregar criterios de aceptación
      for (final ac in story.acceptanceCriteria) {
        final acArtifact = TraceableArtifact(
          id: ac.id,
          type: ArtifactType.acceptanceCriteria,
          title: 'Given ${ac.given} When ${ac.when} Then ${ac.then}',
          sourcePath: specPath,
          metadata: {
            'given': ac.given,
            'when': ac.when,
            'then': ac.then,
            'is_completed': ac.isCompleted,
          },
        );
        artifacts.add(acArtifact);

        // Link US -> AC
        links.add(
          TraceabilityLink(
            source: usArtifact,
            target: acArtifact,
            linkType: LinkType.refines,
          ),
        );
      }
    }

    // Vincular requisitos con User Stories que los mencionan
    for (final req in artifacts.where((a) => a.type == ArtifactType.requirement)) {
      for (final us in artifacts.where((a) => a.type == ArtifactType.userStory)) {
        // Buscar si la US menciona el requisito en su contenido
        final usContent =
            '${us.metadata['as_a']} ${us.metadata['i_want']} ${us.metadata['so_that']}';
        if (_contentRelated(req.title, usContent)) {
          links.add(
            TraceabilityLink(
              source: req,
              target: us,
              linkType: LinkType.derivesFrom,
            ),
          );
        }
      }
    }
  }

  Future<void> _parseTasks(
    String featureId,
    List<TraceableArtifact> artifacts,
    List<TraceabilityLink> links,
  ) async {
    final tasksPath =
        p.join(_projectRoot, 'specs/features/$featureId/tasks.md');
    final tasksFile = File(tasksPath);

    if (!tasksFile.existsSync()) return;

    final content = tasksFile.readAsStringSync();
    final lines = content.split('\n');

    var taskCounter = 1;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Detectar tareas en formato: - [ ] TASK-001: Descripción
      // o - [ ] Descripción (numeración automática)
      if (line.trim().startsWith('- [ ]') || line.trim().startsWith('- [x]')) {
        final taskMatch = _taskPattern.firstMatch(line);
        final taskId = taskMatch != null
            ? 'TASK-${taskMatch.group(1)}'
            : 'TASK-${taskCounter.toString().padLeft(3, '0')}';

        var taskTitle = line.replaceAll(RegExp(r'- \[.\]\s*'), '').trim();
        taskTitle = taskTitle.replaceAll(_taskPattern, '').trim();
        if (taskTitle.startsWith(':')) {
          taskTitle = taskTitle.substring(1).trim();
        }

        if (taskTitle.isNotEmpty) {
          final isCompleted = line.contains('[x]');
          artifacts.add(
            TraceableArtifact(
              id: taskId,
              type: ArtifactType.task,
              title: taskTitle,
              sourcePath: tasksPath,
              lineNumber: i + 1,
              metadata: {'is_completed': isCompleted},
            ),
          );
          taskCounter++;

          // Buscar US relacionada
          final usMatch = _usPattern.firstMatch(line);
          if (usMatch != null) {
            final usId = 'US-${usMatch.group(1)}';
            final usArtifact =
                artifacts.where((a) => a.id == usId).firstOrNull;
            if (usArtifact != null) {
              links.add(
                TraceabilityLink(
                  source: usArtifact,
                  target: artifacts.last,
                  linkType: LinkType.derivesFrom,
                ),
              );
            }
          }
        }
      }
    }
  }

  Future<void> _scanSourceCode(
    String featureId,
    List<TraceableArtifact> artifacts,
    List<TraceabilityLink> links,
  ) async {
    final libDir = Directory(p.join(_projectRoot, 'lib/src'));

    if (!libDir.existsSync()) return;

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final relativePath = p.relative(entity.path, from: _projectRoot);
        final content = entity.readAsStringSync();

        // Extraer nombre del archivo como ID
        final fileName = p.basenameWithoutExtension(entity.path);
        final codeId = 'CODE-$fileName';

        final artifact = TraceableArtifact(
          id: codeId,
          type: ArtifactType.sourceCode,
          title: fileName,
          sourcePath: relativePath,
          metadata: {
            'lines': content.split('\n').length,
          },
        );
        artifacts.add(artifact);

        // Buscar referencias a US, AC, TASK en comentarios
        _extractReferences(content, artifact, artifacts, links);
      }
    }
  }

  Future<void> _scanTests(
    String featureId,
    List<TraceableArtifact> artifacts,
    List<TraceabilityLink> links,
  ) async {
    final testDir = Directory(p.join(_projectRoot, 'test'));

    if (!testDir.existsSync()) return;

    await for (final entity in testDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('_test.dart')) {
        final relativePath = p.relative(entity.path, from: _projectRoot);
        final content = entity.readAsStringSync();

        final fileName = p.basenameWithoutExtension(entity.path);
        final testId = 'TEST-$fileName';

        final artifact = TraceableArtifact(
          id: testId,
          type: ArtifactType.test,
          title: fileName,
          sourcePath: relativePath,
          metadata: {
            'test_count': RegExp(r'test\s*\(').allMatches(content).length,
          },
        );
        artifacts.add(artifact);

        // Inferir código que prueba basado en nombre
        final codeName = fileName.replaceAll('_test', '');
        final codeArtifact = artifacts
            .where(
              (a) =>
                  a.type == ArtifactType.sourceCode && a.title == codeName,
            )
            .firstOrNull;

        if (codeArtifact != null) {
          links.add(
            TraceabilityLink(
              source: artifact,
              target: codeArtifact,
              linkType: LinkType.tests,
            ),
          );
        }

        // Buscar referencias explícitas
        _extractReferences(content, artifact, artifacts, links);
      }
    }
  }

  void _extractReferences(
    String content,
    TraceableArtifact source,
    List<TraceableArtifact> artifacts,
    List<TraceabilityLink> links,
  ) {
    // Buscar referencias a US
    for (final match in _usPattern.allMatches(content)) {
      final usId = 'US-${match.group(1)}';
      final usArtifact = artifacts.where((a) => a.id == usId).firstOrNull;
      if (usArtifact != null) {
        links.add(
          TraceabilityLink(
            source: source,
            target: usArtifact,
          ),
        );
      }
    }

    // Buscar referencias a AC
    for (final match in _acPattern.allMatches(content)) {
      final acId = 'AC-${match.group(1)}';
      final acArtifact = artifacts.where((a) => a.id == acId).firstOrNull;
      if (acArtifact != null) {
        links.add(
          TraceabilityLink(
            source: source,
            target: acArtifact,
            linkType: LinkType.satisfies,
          ),
        );
      }
    }

    // Buscar referencias a TASK
    for (final match in _taskPattern.allMatches(content)) {
      final taskId = 'TASK-${match.group(1)}';
      final taskArtifact = artifacts.where((a) => a.id == taskId).firstOrNull;
      if (taskArtifact != null) {
        links.add(
          TraceabilityLink(
            source: source,
            target: taskArtifact,
          ),
        );
      }
    }
  }

  void _inferLinks(
    List<TraceableArtifact> artifacts,
    List<TraceabilityLink> links,
  ) {
    // Inferir links entre ACs y Tasks basado en contenido similar
    for (final ac in artifacts.where(
      (a) => a.type == ArtifactType.acceptanceCriteria,
    )) {
      for (final task in artifacts.where((a) => a.type == ArtifactType.task)) {
        if (_contentRelated(ac.title, task.title)) {
          // Verificar que no exista ya el link
          final exists = links.any(
            (l) =>
                l.source == ac && l.target == task ||
                l.source == task && l.target == ac,
          );
          if (!exists) {
            links.add(
              TraceabilityLink(
                source: ac,
                target: task,
                linkType: LinkType.derivesFrom,
              ),
            );
          }
        }
      }
    }
  }

  bool _contentRelated(String content1, String content2) {
    final words1 = content1.toLowerCase().split(RegExp(r'\s+'));
    final words2 = content2.toLowerCase().split(RegExp(r'\s+'));

    // Filtrar palabras comunes y cortas
    final stopWords = {
      'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas',
      'de', 'del', 'al', 'en', 'con', 'por', 'para',
      'que', 'y', 'o', 'u', 'e', 'the', 'an', 'and', 'or',
      'to', 'of', 'in', 'for', 'on', 'with', 'as', 'is', 'are',
      'be', 'it', 'this', 'that', 'from', 'by', 'at',
    };

    final significant1 = words1
        .where((w) => w.length > 3 && !stopWords.contains(w))
        .toSet();
    final significant2 = words2
        .where((w) => w.length > 3 && !stopWords.contains(w))
        .toSet();

    if (significant1.isEmpty || significant2.isEmpty) return false;

    final intersection = significant1.intersection(significant2);
    final minSize =
        significant1.length < significant2.length
            ? significant1.length
            : significant2.length;

    // Al menos 30% de coincidencia
    return intersection.length >= (minSize * 0.3).ceil();
  }

  String _testFileName(TraceableArtifact code) {
    return '${code.title}_test.dart';
  }
}
