// ═══════════════════════════════════════════════════════════════
// 📦 Agente 1.5 — Version Checker
// ═══════════════════════════════════════════════════════════════
// Detecta las versiones de las tecnologías usadas en un proyecto
// y las registra en ProjectRegistryService.
//
// Tecnologías detectadas:
//   - Flutter SDK
//   - Dart SDK
//   - Node.js / npm / pnpm / yarn
//   - Python
//   - VS Code (para extensiones)
//
// Uso: Se ejecuta después de AnalyzerAgent.
// ═══════════════════════════════════════════════════════════════

import 'dart:io';

import '../../../services/project_registry_service.dart';
import '../domain/agent_interface.dart';

/// Resultado de detección de versión para una tecnología
class DetectedVersion {
  final String technology;
  final String current;
  final String? latest;
  final bool available;

  const DetectedVersion({
    required this.technology,
    required this.current,
    this.latest,
    this.available = true,
  });

  String get display => '$technology: $current${latest != null ? ' (latest: $latest)' : ''}';
}

/// Agente que detecta y reporta versiones de tecnologías
class VersionCheckerAgent implements AgentInterface {
  @override
  String get agentId => 'version_checker';
  @override
  String get agentName => 'Version Checker';
  @override
  String get inboxStep => 'Paso 1.5';

  @override
  Future<bool> canExecute(String projectPath) async {
    return Directory(projectPath).existsSync();
  }

  @override
  Future<AgentOutput> execute(String projectPath) async {
    final stopwatch = Stopwatch()..start();
    final versions = <DetectedVersion>[];
    final dir = Directory(projectPath);
    final projectName = dir.path.split(Platform.pathSeparator).last;

    // ─── 1. Detectar tecnologías del proyecto ──────────────────
    final techFiles = _detectTechFiles(dir);

    // ─── 2. Detectar versiones según tecnologías presentes ──────
    if (techFiles.containsKey('pubspec.yaml')) {
      versions.addAll(await _detectFlutterVersions(techFiles['pubspec.yaml']!));
    }

    if (techFiles.containsKey('package.json')) {
      versions.addAll(await _detectNodeVersions(techFiles['package.json']!));
    }

    if (techFiles.containsKey('requirements.txt') ||
        techFiles.containsKey('setup.py') ||
        techFiles.containsKey('pyproject.toml')) {
      versions.addAll(await _detectPythonVersions(dir));
    }

    // ─── 3. Detectar versiones globales (si están en PATH) ───────
    versions.addAll(await _detectGlobalVersions());

    // ─── 4. Generar string de versiones ────────────────────────
    final currentVersions = versions
        .map((v) => '${v.technology}:${v.current}')
        .join(', ');

    // ─── 5. Guardar en registry ────────────────────────────────
    final id = _generateRegistryId(projectPath);
    try {
      final existing = await ProjectRegistryService.instance.getProject(id);
      if (existing != null) {
        final updated = existing.copyWith(
          currentVersions: currentVersions.isEmpty ? null : currentVersions,
          updatedAt: DateTime.now(),
        );
        await ProjectRegistryService.instance.upsertProject(updated);
      }
    } catch (e) {
      // No bloqueamos si falla el registry
    }

    stopwatch.stop();

    final summary = versions.isEmpty
        ? 'No se detectaron tecnologías en "$projectName"'
        : 'Detectadas ${versions.length} versiones: ${versions.map((v) => v.display).join(', ')}';

    return AgentOutput(
      agentId: agentId,
      success: true,
      summary: summary,
      data: {
        'versions': versions.map((v) => {
          'technology': v.technology,
          'current': v.current,
          'latest': v.latest,
          'available': v.available,
        }).toList(),
        'projectName': projectName,
        'duration': stopwatch.elapsedMilliseconds,
      },
    );
  }

  // ─── Detectar archivos de tecnología ────────────────────────

  Map<String, String> _detectTechFiles(Directory dir) {
    final files = <String, String>{};

    try {
      dir.listSync(recursive: false).forEach((entity) {
        if (entity is File) {
          final name = entity.path.split(Platform.pathSeparator).last;
          if (name == 'pubspec.yaml' ||
              name == 'package.json' ||
              name == 'requirements.txt' ||
              name == 'setup.py' ||
              name == 'pyproject.toml') {
            files[name] = entity.path;
          }
        }
      });
    } catch (_) {}

    return files;
  }

  // ─── Flutter / Dart ─────────────────────────────────────────

  Future<List<DetectedVersion>> _detectFlutterVersions(String pubspecPath) async {
    final versions = <DetectedVersion>[];

    try {
      final content = File(pubspecPath).readAsStringSync();

      // Detectar Flutter SDK version del pubspec
      final sdkMatch = RegExp(r'sdk:\s*["\x27]?>=\s*([\d.]+)').firstMatch(content);
      if (sdkMatch != null) {
        versions.add(DetectedVersion(
          technology: 'Flutter SDK',
          current: sdkMatch.group(1)!,
          available: true,
        ));
      }

      // Detectar Dart SDK
      if (sdkMatch != null) {
        versions.add(DetectedVersion(
          technology: 'Dart',
          current: sdkMatch.group(1)!,
          available: true,
        ));
      }

      // Detectar versión de Flutter instalada
      final flutterVersion = await _runCommand('flutter', ['--version']);
      if (flutterVersion != null) {
        final versionMatch = RegExp(r'Flutter ([\d.]+)').firstMatch(flutterVersion);
        if (versionMatch != null && versions.isNotEmpty) {
          // Actualizar Flutter SDK con la versión instalada
          versions[0] = DetectedVersion(
            technology: 'Flutter SDK',
            current: versionMatch.group(1)!,
            available: true,
          );
        }
      }

      // Detectar Dart global
      final dartVersion = await _runCommand('dart', ['--version']);
      if (dartVersion != null) {
        final versionMatch = RegExp(r'Dart SDK version:\s*([\d.]+)').firstMatch(dartVersion);
        if (versionMatch != null) {
          versions.add(DetectedVersion(
            technology: 'Dart',
            current: versionMatch.group(1)!,
            available: true,
          ));
        }
      }
    } catch (_) {}

    return versions;
  }

  // ─── Node.js / npm / pnpm ───────────────────────────────────

  Future<List<DetectedVersion>> _detectNodeVersions(String packageJsonPath) async {
    final versions = <DetectedVersion>[];

    try {
      final content = File(packageJsonPath).readAsStringSync();

      // Detectar Node.js engine
      final nodeMatch = RegExp(r'"node"\s*:\s*["\x27]?>=\s*([\d.]+)').firstMatch(content);
      if (nodeMatch != null) {
        versions.add(DetectedVersion(
          technology: 'Node.js',
          current: '>=${nodeMatch.group(1)}',
          available: true,
        ));
      }

      // Detectar versión global de Node
      final nodeVersion = await _runCommand('node', ['--version']);
      if (nodeVersion != null) {
        final cleanVersion = nodeVersion.trim().replaceFirst('v', '');
        versions.add(DetectedVersion(
          technology: 'Node.js',
          current: cleanVersion,
          available: true,
        ));
      }

      // Detectar npm
      final npmVersion = await _runCommand('npm', ['--version']);
      if (npmVersion != null) {
        versions.add(DetectedVersion(
          technology: 'npm',
          current: npmVersion.trim(),
          available: true,
        ));
      }

      // Detectar pnpm
      final pnpmVersion = await _runCommand('pnpm', ['--version']);
      if (pnpmVersion != null) {
        versions.add(DetectedVersion(
          technology: 'pnpm',
          current: pnpmVersion.trim(),
          available: true,
        ));
      }

      // Detectar yarn
      final yarnVersion = await _runCommand('yarn', ['--version']);
      if (yarnVersion != null) {
        versions.add(DetectedVersion(
          technology: 'Yarn',
          current: yarnVersion.trim(),
          available: true,
        ));
      }
    } catch (_) {}

    return versions;
  }

  // ─── Python ────────────────────────────────────────────────

  Future<List<DetectedVersion>> _detectPythonVersions(Directory dir) async {
    final versions = <DetectedVersion>[];

    try {
      // Detectar Python global
      final pythonVersion = await _runCommand('python3', ['--version']);
      if (pythonVersion != null) {
        final versionMatch = RegExp(r'Python ([\d.]+)').firstMatch(pythonVersion);
        if (versionMatch != null) {
          versions.add(DetectedVersion(
            technology: 'Python',
            current: versionMatch.group(1)!,
            available: true,
          ));
        }
      }

      // Detectar pip
      final pipVersion = await _runCommand('pip3', ['--version']);
      if (pipVersion != null) {
        final versionMatch = RegExp(r'pip ([\d.]+)').firstMatch(pipVersion);
        if (versionMatch != null) {
          versions.add(DetectedVersion(
            technology: 'pip',
            current: versionMatch.group(1)!,
            available: true,
          ));
        }
      }

      // Detectar poetry si existe pyproject.toml
      final hasPoetry = File('${dir.path}/pyproject.toml').existsSync();
      if (hasPoetry) {
        final poetryVersion = await _runCommand('poetry', ['--version']);
        if (poetryVersion != null) {
          final versionMatch = RegExp(r'Poetry \(version ([\d.]+)').firstMatch(poetryVersion);
          if (versionMatch != null) {
            versions.add(DetectedVersion(
              technology: 'Poetry',
              current: versionMatch.group(1)!,
              available: true,
            ));
          }
        }
      }
    } catch (_) {}

    return versions;
  }

  // ─── Versiones globales (Flutter, Dart, Node) ───────────────

  Future<List<DetectedVersion>> _detectGlobalVersions() async {
    final versions = <DetectedVersion>[];

    // Flutter
    try {
      final result = await Process.run('flutter', ['--version']).timeout(Duration(seconds: 10));
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final flutterMatch = RegExp(r'Flutter ([\d.]+)').firstMatch(output);
        final dartMatch = RegExp(r'Dart ([\d.]+)').firstMatch(output);

        if (flutterMatch != null) {
          versions.add(DetectedVersion(
            technology: 'Flutter',
            current: flutterMatch.group(1)!,
            available: true,
          ));
        }
        if (dartMatch != null) {
          versions.add(DetectedVersion(
            technology: 'Dart',
            current: dartMatch.group(1)!,
            available: true,
          ));
        }
      }
    } catch (_) {}

    // Node (si no se detectó en proyecto)
    if (!versions.any((v) => v.technology == 'Node.js')) {
      try {
        final result = await Process.run('node', ['--version']).timeout(Duration(seconds: 5));
        if (result.exitCode == 0) {
          final version = result.stdout.toString().trim().replaceFirst('v', '');
          versions.add(DetectedVersion(
            technology: 'Node.js',
            current: version,
            available: true,
          ));
        }
      } catch (_) {}
    }

    return versions;
  }

  // ─── Helpers ───────────────────────────────────────────────

  Future<String?> _runCommand(String cmd, List<String> args) async {
    try {
      final result = await Process.run(cmd, args).timeout(Duration(seconds: 10));
      if (result.exitCode == 0 && result.stdout.toString().isNotEmpty) {
        return result.stdout.toString();
      }
    } catch (_) {}
    return null;
  }

  /// Genera el mismo ID que AnalyzerAgent para encontrar el registro
  String _generateRegistryId(String projectPath) {
    final input = projectPath;
    var hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash) + input.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF;
    }
    final hex = hash.toRadixString(16).padLeft(8, '0');
    return '${hex.substring(0, 8)}-${hex.substring(0, 4)}-0000-0000-${hex.substring(4, 12).padLeft(12, '0')}';
  }
}