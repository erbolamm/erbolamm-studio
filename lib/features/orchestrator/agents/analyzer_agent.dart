// ═══════════════════════════════════════════════════════════════
// 🔍 Agente 1 — Analizador Inicial
// ═══════════════════════════════════════════════════════════════
// Escanea un proyecto local y determina:
//   1. Tipo (app, paquete, web, extensión, etc.)
//   2. Lenguaje/framework
//   3. Completitud (funcional, a medias, esqueleto, roto)
//   4. Código aprovechable
//   5. Resumen en 3 líneas
//
// Implementa AgentInterface del orquestador.
// ═══════════════════════════════════════════════════════════════

import 'dart:io';

import '../domain/project_analysis.dart';
import '../domain/agent_interface.dart';

/// Agente 1: Analiza un proyecto local escaneando el sistema de archivos
class AnalyzerAgent implements AgentInterface {
  @override
  String get agentId => 'analyzer';
  @override
  String get agentName => 'Analizador Inicial';
  @override
  String get inboxStep => 'Paso 1';

  @override
  Future<bool> canExecute(String projectPath) async {
    final dir = Directory(projectPath);
    return dir.existsSync();
  }

  @override
  Future<AgentOutput> execute(String projectPath) async {
    final stopwatch = Stopwatch()..start();
    final dir = Directory(projectPath);

    if (!dir.existsSync()) {
      return AgentOutput(
        agentId: agentId,
        success: false,
        summary: 'La ruta del proyecto no existe: $projectPath',
        error: 'Directory not found',
      );
    }

    final projectName = dir.path.split(Platform.pathSeparator).last;
    final allFiles = _walkDirectory(dir);
    final keyFiles = _findKeyFiles(allFiles);
    final totalLines = _countLines(keyFiles);

    // Detectar tipo de proyecto
    final typeResult = _detectType(keyFiles);

    // Detectar lenguaje/framework
    final langResult = _detectLanguage(keyFiles);

    // Evaluar completitud
    final completenessResult = _evaluateCompleteness(keyFiles, allFiles.length, totalLines);

    // Detectar código aprovechable
    final valuableResult = _detectValuableParts(keyFiles, allFiles);

    // Generar resumen
    final summary = _generateSummary(
      projectName,
      typeResult.type,
      langResult.language,
      completenessResult.completeness,
      completenessResult.issues,
    );

    stopwatch.stop();

    final analysis = ProjectAnalysis(
      projectName: projectName,
      projectPath: projectPath,
      type: typeResult.type,
      typeDetail: typeResult.detail,
      language: langResult.language,
      framework: langResult.framework,
      completeness: completenessResult.completeness,
      issues: completenessResult.issues,
      hasValuableCode: valuableResult.hasValue,
      valuableParts: valuableResult.parts,
      totalFiles: allFiles.length,
      totalLines: totalLines,
      summary: summary,
      keyFiles: keyFiles,
      analysisDuration: stopwatch.elapsed,
    );

    return AgentOutput(
      agentId: agentId,
      success: true,
      summary: summary,
      data: {
        'type': analysis.type.label,
        'language': analysis.language,
        'completeness': analysis.completeness.label,
        'totalFiles': analysis.totalFiles,
        'totalLines': analysis.totalLines,
        'issues': analysis.issues,
        'valuableParts': analysis.valuableParts,
      },
    );
  }

  // ─── Escaneo de archivos ───

  List<File> _walkDirectory(Directory dir) {
    final files = <File>[];
    try {
      dir.listSync(recursive: true).forEach((entity) {
        if (entity is File) {
          final path = entity.path;
          // Ignorar carpetas de build, .git, node_modules, .dart_tool
          if (path.contains('/build/') || path.contains('/.git/') ||
              path.contains('/node_modules/') || path.contains('/.dart_tool/') ||
              path.contains('/.idea/') || path.contains('/macos/') ||
              path.contains('/windows/') || path.contains('/linux/') ||
              path.endsWith('.freezed.dart') || path.endsWith('.g.dart') ||
              path.endsWith('.iml') || path.endsWith('.lock')) {
            return;
          }
          files.add(entity);
        }
      });
    } catch (_) {}
    return files;
  }

  List<DetectedFile> _findKeyFiles(List<File> files) {
    final keyNames = [
      'pubspec.yaml', 'package.json', 'README.md', 'CHANGELOG.md',
      'LICENSE', 'analysis_options.yaml', '.gitignore',
      'main.dart', 'index.html', 'manifest.json', 'icon.png',
      'landing.html', 'landing.css',
    ];

    return files.where((f) {
      final name = f.path.split(Platform.pathSeparator).last;
      return keyNames.contains(name);
    }).map((f) => DetectedFile(
      path: f.path,
      type: f.path.split('.').last,
      sizeBytes: f.lengthSync(),
    )).toList();
  }

  int _countLines(List<DetectedFile> files) {
    int total = 0;
    for (final f in files) {
      try {
        final content = File(f.path).readAsLinesSync();
        total += content.length;
      } catch (_) {}
    }
    return total;
  }

  // ─── Detección de tipo ───

  _TypeResult _detectType(List<DetectedFile> files) {
    final names = files.map((f) => f.path.split(Platform.pathSeparator).last).toSet();

    if (names.contains('pubspec.yaml')) {
      // Es Dart/Flutter
      for (final f in files) {
        if (f.path.endsWith('pubspec.yaml')) {
          try {
            final content = File(f.path).readAsStringSync();
            if (content.contains('flutter:')) {
              // Verificar si tiene ios/ o android/ o web/
              final hasPlatformDirs = names.any((n) =>
                  n == 'ios' || n == 'android' || n == 'web' || n == 'macos' || n == 'windows' || n == 'linux');
              if (hasPlatformDirs) {
                // Verificar si es package o app
                if (content.contains('publish_to:') && !content.contains("publish_to: 'none'")) {
                  return _TypeResult(ProjectType.dartPackage, 'Paquete Flutter publicado en pub.dev');
                }
                return _TypeResult(ProjectType.flutterApp, 'App Flutter multiplataforma');
              }
              return _TypeResult(ProjectType.dartPackage, 'Paquete Flutter');
            }
            return _TypeResult(ProjectType.dartPackage, 'Paquete Dart');
          } catch (_) {}
        }
      }
    }

    if (names.contains('package.json')) {
      for (final f in files) {
        if (f.path.endsWith('package.json')) {
          try {
            final content = File(f.path).readAsStringSync();
            if (content.contains('"vscode"') || content.contains('vscode')) {
              return _TypeResult(ProjectType.vsCodeExtension, 'Extensión VS Code');
            }
            return _TypeResult(ProjectType.nodePackage, 'Paquete Node.js / npm');
          } catch (_) {}
        }
      }
    }

    if (names.contains('index.html') || names.contains('landing.html')) {
      return _TypeResult(ProjectType.webHtml, 'Web HTML/CSS/JS');
    }

    if (names.contains('requirements.txt') || names.contains('setup.py') || names.contains('pyproject.toml')) {
      return _TypeResult(ProjectType.pythonProject, 'Proyecto Python');
    }

    if (files.any((f) => f.path.endsWith('.dart'))) {
      return _TypeResult(ProjectType.exerciseDart, 'Ejercicio o script Dart');
    }

    return _TypeResult(ProjectType.unknown, 'No se pudo determinar el tipo de proyecto');
  }

  // ─── Detección de lenguaje ───

  _LangResult _detectLanguage(List<DetectedFile> files) {
    final names = files.map((f) => f.path.split(Platform.pathSeparator).last).toSet();

    // Contar extensión dominante en key files
    if (names.contains('pubspec.yaml')) {
      String? sdkVersion;
      for (final f in files) {
        if (f.path.endsWith('pubspec.yaml')) {
          try {
            final content = File(f.path).readAsStringSync();
            final sdkMatch = RegExp(r'sdk:\s*"?(>=?\s*[\d.]+)').firstMatch(content);
            if (sdkMatch != null) sdkVersion = sdkMatch.group(1);
          } catch (_) {}
        }
      }
      if (names.any((n) => n == 'flutter' || n == 'flutter:')) {
        return _LangResult('Dart/Flutter', 'Flutter', sdkVersion: sdkVersion);
      }
      return _LangResult('Dart', null, sdkVersion: sdkVersion);
    }

    if (names.contains('package.json')) {
      return _LangResult('JavaScript/TypeScript', 'Node.js');
    }

    if (names.contains('index.html')) {
      return _LangResult('HTML/CSS/JavaScript', null);
    }

    if (names.contains('requirements.txt') || names.contains('setup.py')) {
      return _LangResult('Python', null);
    }

    if (files.any((f) => f.path.endsWith('.dart'))) {
      return _LangResult('Dart', null);
    }

    if (files.any((f) => f.path.endsWith('.py'))) {
      return _LangResult('Python', null);
    }

    if (files.any((f) => f.path.endsWith('.js') || f.path.endsWith('.ts'))) {
      return _LangResult('JavaScript/TypeScript', null);
    }

    return _LangResult('Desconocido', null);
  }

  // ─── Evaluación de completitud ───

  _CompletenessResult _evaluateCompleteness(List<DetectedFile> keyFiles, int totalFiles, int totalLines) {
    final issues = <String>[];
    final names = keyFiles.map((f) => f.path.split(Platform.pathSeparator).last).toSet();

    // Heurísticas de completitud
    final hasReadme = names.contains('README.md');
    final hasLicense = names.contains('LICENSE');
    final hasChangelog = names.contains('CHANGELOG.md');
    final hasPubspec = names.contains('pubspec.yaml');
    final hasMainDart = names.contains('main.dart');

    if (!hasReadme) issues.add('Falta README.md');
    if (!hasLicense) issues.add('Falta LICENSE');
    if (!hasChangelog) issues.add('Falta CHANGELOG.md');
    if (hasPubspec && !hasMainDart) issues.add('pubspec.yaml sin main.dart');
    if (totalFiles <= 3) issues.add('Muy pocos archivos ($totalFiles)');

    if (totalFiles > 20 && totalLines > 500 && hasReadme && (hasLicense || hasChangelog)) {
      return _CompletenessResult(Completeness.functional, issues);
    }

    if (totalFiles > 8 && totalLines > 100 && hasReadme) {
      return _CompletenessResult(Completeness.partial, issues);
    }

    if (totalFiles > 3) {
      return _CompletenessResult(Completeness.skeleton, issues);
    }

    return _CompletenessResult(Completeness.broken, issues);
  }

  // ─── Detección de código aprovechable ───

  _ValuableResult _detectValuableParts(List<DetectedFile> keyFiles, List<File> allFiles) {
    final parts = <String>[];
    final names = keyFiles.map((f) => f.path.split(Platform.pathSeparator).last).toSet();

    if (names.contains('README.md')) parts.add('README.md con documentación');
    if (names.contains('CHANGELOG.md')) parts.add('CHANGELOG.md con historial de versiones');
    if (names.contains('LICENSE')) parts.add('LICENSE (código listo para publicar)');
    if (names.contains('main.dart')) parts.add('main.dart con lógica de entrada');
    if (names.contains('analysis_options.yaml')) parts.add('Configuración de linting');
    if (keyFiles.any((f) => f.path.endsWith('pubspec.yaml'))) parts.add('pubspec.yaml con dependencias definidas');

    // Detectar si tiene assets rescatables
    final hasAssets = allFiles.any((f) =>
        f.path.contains('/assets/') || f.path.contains('/lib/'));
    if (hasAssets) parts.add('Assets y código fuente en lib/');

    // Detectar si tiene promo
    final hasPromo = allFiles.any((f) => f.path.contains('/promo/'));
    if (hasPromo) parts.add('Carpeta promo/ con assets de marketing');

    return _ValuableResult(parts.isNotEmpty, parts);
  }

  // ─── Generación de resumen ───

  String _generateSummary(
    String name,
    ProjectType type,
    String language,
    Completeness completeness,
    List<String> issues,
  ) {
    final typeLabel = type.label;
    final langLabel = language;
    final stateLabel = completeness.label;

    final issueText = issues.isEmpty
        ? 'Sin problemas detectados.'
        : 'Problemas: ${issues.length} (${issues.first}${issues.length > 1 ? ', ...' : ''})';

    return 'Proyecto "$name" — $typeLabel ($langLabel). $stateLabel. $issueText';
  }
}

// ─── Tipos internos ───

class _TypeResult {
  final ProjectType type;
  final String detail;
  _TypeResult(this.type, this.detail);
}

class _LangResult {
  final String language;
  final String? framework;
  final String? sdkVersion;
  _LangResult(this.language, this.framework, {this.sdkVersion});
}

class _CompletenessResult {
  final Completeness completeness;
  final List<String> issues;
  _CompletenessResult(this.completeness, this.issues);
}

class _ValuableResult {
  final bool hasValue;
  final List<String> parts;
  _ValuableResult(this.hasValue, this.parts);
}
