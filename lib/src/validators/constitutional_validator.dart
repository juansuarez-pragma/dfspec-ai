import 'package:dfspec/src/models/constitutional_gate.dart';

/// Validador de gates constitucionales.
///
/// Valida codigo fuente contra las reglas de la constitucion DFSpec.
class ConstitutionalValidator {
  /// Crea una instancia del validador.
  const ConstitutionalValidator();

  /// Valida un archivo contra todos los gates aplicables.
  ///
  /// [content] es el contenido del archivo.
  /// [filePath] es la ruta del archivo para determinar contexto.
  /// [gates] son los gates a evaluar (por defecto todos).
  ConstitutionalReport validate({
    required String content,
    required String filePath,
    List<ConstitutionalGate>? gates,
  }) {
    final gatesToCheck = gates ?? ConstitutionalGates.all;
    final results = <GateResult>[];

    for (final gate in gatesToCheck) {
      final result = _validateGate(gate, content, filePath);
      results.add(result);
    }

    return ConstitutionalReport(
      results: results,
      timestamp: DateTime.now(),
      context: filePath,
    );
  }

  /// Valida solo los gates criticos.
  ConstitutionalReport validateCritical({
    required String content,
    required String filePath,
  }) {
    return validate(
      content: content,
      filePath: filePath,
      gates: ConstitutionalGates.critical,
    );
  }

  /// Valida un gate especifico contra el contenido.
  GateResult _validateGate(
    ConstitutionalGate gate,
    String content,
    String filePath,
  ) {
    // Determinar si el gate aplica a este tipo de archivo
    if (!_gateApplies(gate, filePath)) {
      return GateResult(
        gateId: gate.id,
        status: GateStatus.notApplicable,
        message: 'Gate no aplica a este tipo de archivo',
      );
    }

    final violations = <String>[];
    final details = <String>[];

    // Verificar patrones de violacion
    for (final pattern in gate.violationPatterns) {
      try {
        final regex = RegExp(pattern, multiLine: true);
        final matches = regex.allMatches(content);

        for (final match in matches) {
          final lineNumber = _getLineNumber(content, match.start);
          violations.add('Linea $lineNumber: ${match.group(0)}');
        }
      } catch (_) {
        // Pattern invalido, ignorar
      }
    }

    // Si hay violaciones, el gate falla
    if (violations.isNotEmpty) {
      return GateResult.failed(
        gate.id,
        message: 'Violacion de ${gate.name}',
        details: violations,
        location: filePath,
      );
    }

    // Verificar patrones de conformidad (opcionales)
    if (gate.checkPatterns.isNotEmpty) {
      var hasConformity = false;
      for (final pattern in gate.checkPatterns) {
        try {
          final regex = RegExp(pattern, multiLine: true);
          if (regex.hasMatch(content)) {
            hasConformity = true;
            break;
          }
        } catch (_) {
          // Pattern invalido, ignorar
        }
      }

      if (!hasConformity && _shouldRequireConformity(gate, filePath)) {
        details.add('No se encontraron patrones de conformidad esperados');
        return GateResult.warning(
          gate.id,
          message: 'Posible violacion de ${gate.name}',
          details: details,
        );
      }
    }

    return GateResult.passed(gate.id, message: '${gate.name} OK');
  }

  /// Determina si un gate aplica a un archivo especifico.
  bool _gateApplies(ConstitutionalGate gate, String filePath) {
    final normalizedPath = filePath.replaceAll(r'\', '/');

    switch (gate.id) {
      case 'clean-architecture':
        // Aplica a archivos en domain/
        return normalizedPath.contains('/domain/');

      case 'tdd':
        // Aplica a archivos de produccion (lib/)
        return (normalizedPath.contains('/lib/') ||
                normalizedPath.startsWith('lib/')) &&
            !normalizedPath.contains('_test.dart');

      case 'immutable-entities':
        // Aplica a entidades de dominio
        return normalizedPath.contains('/domain/entities/') ||
            normalizedPath.contains('/domain/entity/');

      case 'model-entity-separation':
        // Aplica a modelos y entidades
        return normalizedPath.contains('/data/models/') ||
            normalizedPath.contains('/domain/entities/');

      case 'domain-interfaces':
        // Aplica a repositorios
        return normalizedPath.contains('/repositories/');

      case 'atomic-usecases':
        // Aplica a usecases
        return normalizedPath.contains('/usecases/') ||
            normalizedPath.contains('/usecase/');

      case 'state-management':
        // Aplica a providers/blocs
        return normalizedPath.contains('/providers/') ||
            normalizedPath.contains('/bloc/') ||
            normalizedPath.contains('/notifiers/');

      case 'error-handling':
        // Aplica a datasources y repositorios
        return normalizedPath.contains('/datasources/') ||
            normalizedPath.contains('/repositories/');

      case 'flutter-performance':
        // Aplica a widgets y pages
        return normalizedPath.contains('/widgets/') ||
            normalizedPath.contains('/pages/') ||
            normalizedPath.contains('/screens/');

      case 'minimum-docs':
        // Aplica a archivos publicos (no privados)
        return normalizedPath.contains('/lib/') &&
            !normalizedPath.split('/').last.startsWith('_');

      case 'minimum-coverage':
        // Este gate se evalua a nivel de proyecto, no de archivo
        return false;

      default:
        return true;
    }
  }

  /// Determina si se debe requerir conformidad para el gate.
  bool _shouldRequireConformity(ConstitutionalGate gate, String filePath) {
    switch (gate.id) {
      case 'immutable-entities':
        return filePath.contains('/entities/');

      case 'domain-interfaces':
        return filePath.contains('/domain/repositories/');

      case 'atomic-usecases':
        return filePath.contains('/usecases/');

      default:
        return false;
    }
  }

  /// Obtiene el numero de linea para una posicion en el contenido.
  int _getLineNumber(String content, int position) {
    return content.substring(0, position).split('\n').length;
  }

  /// Valida imports de Clean Architecture en un archivo de domain.
  GateResult validateCleanArchitectureImports(String content, String filePath) {
    if (!filePath.contains('/domain/')) {
      return const GateResult(
        gateId: 'clean-architecture',
        status: GateStatus.notApplicable,
      );
    }

    final violations = <String>[];

    // Buscar imports de data/
    final dataImportPattern = RegExp(r"import\s+'package:[^']+/data/[^']*';");
    for (final match in dataImportPattern.allMatches(content)) {
      final lineNumber = _getLineNumber(content, match.start);
      violations.add('Linea $lineNumber: Import de capa data en domain');
    }

    // Buscar imports de presentation/
    final presentationImportPattern =
        RegExp(r"import\s+'package:[^']+/presentation/[^']*';");
    for (final match in presentationImportPattern.allMatches(content)) {
      final lineNumber = _getLineNumber(content, match.start);
      violations.add(
        'Linea $lineNumber: Import de capa presentation en domain',
      );
    }

    if (violations.isNotEmpty) {
      return GateResult.failed(
        'clean-architecture',
        message: 'Violacion de Clean Architecture: domain importa capas externas',
        details: violations,
        location: filePath,
      );
    }

    return GateResult.passed(
      'clean-architecture',
      message: 'Clean Architecture OK',
    );
  }

  /// Valida que una entidad sea inmutable.
  GateResult validateImmutableEntity(String content, String filePath) {
    if (!filePath.contains('/entities/')) {
      return const GateResult(
        gateId: 'immutable-entities',
        status: GateStatus.notApplicable,
      );
    }

    final violations = <String>[];

    // Buscar setters
    final setterPattern = RegExp(r'set\s+\w+\s*\(');
    for (final match in setterPattern.allMatches(content)) {
      final lineNumber = _getLineNumber(content, match.start);
      violations.add('Linea $lineNumber: Setter detectado en entidad');
    }

    // Buscar campos no-final (simplificado)
    final nonFinalPattern = RegExp(r'^\s+(?!final\s+)(\w+)\s+\w+\s*;', multiLine: true);
    for (final match in nonFinalPattern.allMatches(content)) {
      // Excluir lineas que son comentarios o constantes
      final line = match.group(0) ?? '';
      if (!line.trimLeft().startsWith('//') &&
          !line.contains('const') &&
          !line.contains('static')) {
        final lineNumber = _getLineNumber(content, match.start);
        violations.add('Linea $lineNumber: Campo no-final en entidad');
      }
    }

    // Verificar que extiende Equatable
    final extendsEquatable = RegExp(r'extends\s+Equatable').hasMatch(content);
    if (!extendsEquatable && content.contains('class ')) {
      violations.add('La entidad no extiende Equatable');
    }

    if (violations.isNotEmpty) {
      return GateResult.failed(
        'immutable-entities',
        message: 'Entidad no es inmutable',
        details: violations,
        location: filePath,
      );
    }

    return GateResult.passed(
      'immutable-entities',
      message: 'Entidad inmutable OK',
    );
  }

  /// Valida correspondencia test-produccion.
  GateResult validateTestCorrespondence(
    String productionPath,
    bool testExists,
  ) {
    final normalizedPath = productionPath.replaceAll(r'\', '/');
    if (!normalizedPath.contains('/lib/') &&
        !normalizedPath.startsWith('lib/')) {
      return const GateResult(
        gateId: 'tdd',
        status: GateStatus.notApplicable,
      );
    }

    if (!testExists) {
      return GateResult.failed(
        'tdd',
        message: 'Archivo de test no encontrado',
        details: [
          'Todo archivo en lib/ debe tener test correspondiente',
          'Archivo: $productionPath',
        ],
        location: productionPath,
      );
    }

    return GateResult.passed('tdd', message: 'Test correspondiente existe');
  }
}
