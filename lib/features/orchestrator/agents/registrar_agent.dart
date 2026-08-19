// ═══════════════════════════════════════════════════════════════
// 📝 Agente 5 — Registrador en universe.json
// ═══════════════════════════════════════════════════════════════
// Añade el proyecto procesado a universe.json con todos sus
// campos: id, name, pillar, type, description, urls, status, promo.
// Crea universe.json si no existe, detecta pillar por keywords,
// y evita duplicados.
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/agent_interface.dart';

class RegistrarAgent implements AgentInterface {
  @override
  String get agentId => 'registrar';
  @override
  String get agentName => 'Registrador';
  @override
  String get inboxStep => 'Paso 5';

  @override
  Future<bool> canExecute(String projectPath) async {
    // Necesita acceso al universe.json del proyecto raíz
    return true;
  }

  @override
  Future<AgentOutput> execute(String projectPath) async {
    final projectName = projectPath.split(Platform.pathSeparator).last;

    // Buscar universe.json (subir 2 niveles desde INBOX/{proyecto})
    final universePath = p.normalize(
      p.join(projectPath, '..', '..', 'universe.json'),
    );
    final universeFile = File(universePath);
    final universeExists = universeFile.existsSync();

    // Leer o crear universe.json
    Map<String, dynamic> universe;
    if (universeExists) {
      try {
        final content = universeFile.readAsStringSync();
        universe = jsonDecode(content) as Map<String, dynamic>;
        if (universe['projects'] is! List) {
          universe['projects'] = [];
        }
      } catch (e) {
        return AgentOutput(
          agentId: agentId,
          success: false,
          summary: 'Error al leer universe.json: $e',
          error: e.toString(),
        );
      }
    } else {
      universe = {
        'projects': <dynamic>[],
        'lastUpdated': DateTime.now().toIso8601String().substring(0, 10),
      };
    }

    // Verificar si el proyecto ya existe
    final projects = universe['projects'] as List<dynamic>? ?? [];
    final exists = projects.any((p) => (p is Map && p['id'] == projectName));

    if (exists) {
      return AgentOutput(
        agentId: agentId,
        success: true,
        summary: '⚠️ "$projectName" ya existe en universe.json. No se duplicó.',
        data: {'status': 'already_exists', 'projectId': projectName},
      );
    }

    // Determinar tipo, pillar, descripción y URLs
    final pillar = _detectPillar(projectPath);
    final type = _detectType(projectPath);
    final description = _extractDescription(projectPath);
    final detectedUrls = _detectUrls(projectPath, type);

    final landingRef = detectedUrls['landing'];
    final landingNotice = landingRef != null && landingRef.isNotEmpty
        ? '🌐 Web de referencia detectada: $landingRef'
        : '⚠️ Sin web de referencia asignada actualmente (ninguna).';

    // Crear entrada
    final entry = {
      'id': projectName,
      'name': _formatName(projectName),
      'pillar': pillar,
      'type': type,
      'description': description,
      'urls': detectedUrls,
      'status': 'wip',
      'promo': {
        'video': File(p.join(projectPath, 'promo', 'videos')).existsSync(),
        'screenshots': File(p.join(projectPath, 'promo', 'screenshots')).existsSync(),
        'landing': landingRef != null,
      },
    };

    // Actualizar fecha
    universe['lastUpdated'] = DateTime.now().toIso8601String().substring(0, 10);
    (universe['projects'] as List).add(entry);

    // Escribir en universe.json
    try {
      universeFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(universe),
      );
    } catch (e) {
      return AgentOutput(
        agentId: agentId,
        success: false,
        summary: 'Error al escribir universe.json: $e',
        error: e.toString(),
      );
    }

    return AgentOutput(
      agentId: agentId,
      success: true,
      summary:
          '✅ "$projectName" registrado en universe.json como $pillar/$type.\n$landingNotice',
      data: {
        'projectId': projectName,
        'pillar': pillar,
        'type': type,
        'status': 'wip',
        'landing': landingRef,
      },
    );
  }

  // ─── Pillar detection ───────────────────────────────────────
  //
  // Keywords que mapean a cada pillar.
  // Se buscan en: nombre del proyecto, README.md, pubspec description.
  //
  static const _pillarRules = <String, List<String>>{
    'creacion': [
      'calca',
      'arte',
      'art',
      'draw',
      'dibuj',
      'creativ',
      'creación',
      'crear',
      'paint',
      'sketch',
      'design',
      'diseño',
    ],
    'educacion': [
      'aprend',
      'learn',
      'educ',
      'tutorial',
      'curso',
      'course',
      'formación',
      'training',
      'teach',
      'enseñ',
      'gui',
      'guide',
    ],
    'cultura': [
      'carnaval',
      'chirigota',
      'comparsa',
      'música',
      'music',
      'cultura',
      'cultural',
      'fiesta',
      'tradición',
      'coplas',
      'jurado',
      'votación',
      'vot',
      'popular',
    ],
    'herramientas': [
      'tool',
      'herramient',
      'package',
      'paquete',
      'extension',
      'vscode',
      'vs-code',
      'dev',
      'cli',
      'theme',
      'tema',
      'switch',
      'kvm',
      'glass',
      'faq',
      'key',
      'master',
      'studio',
      'orchestrat',
      'pipeline',
      'agent',
      'flutter',
    ],
    'hardware': [
      'hardware',
      'iot',
      'device',
      'dispositivo',
      'robot',
      'legacy',
      'server',
      'servidor',
      'offline',
      'local',
      'cognitivo',
      'asistente',
      'memory',
      'memo',
    ],
  };

  String _detectPillar(String path) {
    final projectName = path.split(Platform.pathSeparator).last.toLowerCase();
    final content = _readProjectContent(path).toLowerCase();

    // Score each pillar
    final scores = <String, int>{};
    for (final entry in _pillarRules.entries) {
      int score = 0;
      for (final keyword in entry.value) {
        if (projectName.contains(keyword)) score += 3;
        if (content.contains(keyword)) score += 1;
      }
      scores[entry.key] = score;
    }

    // Return highest-scoring pillar, default to herramientas
    final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return best.value > 0 ? best.key : _fallbackPillar(path);
  }

  String _fallbackPillar(String path) {
    // Fallback basado en tipo de proyecto
    final type = _detectType(path);
    if (type == 'package' || type == 'extension') return 'herramientas';
    return 'herramientas';
  }

  String _readProjectContent(String path) {
    final buffer = StringBuffer();

    // Leer README
    for (final name in ['README.md', 'readme.md', 'Readme.md']) {
      final file = File('$path/$name');
      if (file.existsSync()) {
        try {
          buffer.writeln(file.readAsStringSync());
        } catch (_) {}
        break;
      }
    }

    // Leer descripción de pubspec.yaml
    final pubspec = File('$path/pubspec.yaml');
    if (pubspec.existsSync()) {
      try {
        final lines = pubspec.readAsLinesSync();
        for (final line in lines) {
          if (line.trimLeft().startsWith('description:')) {
            buffer.writeln(line.replaceAll(RegExp(r'description:\s*'), ''));
          }
        }
      } catch (_) {}
    }

    // Leer descripción de package.json
    final pkgJson = File('$path/package.json');
    if (pkgJson.existsSync()) {
      try {
        final json = jsonDecode(pkgJson.readAsStringSync());
        if (json is Map && json['description'] is String) {
          buffer.writeln(json['description']);
        }
        if (json is Map && json['displayName'] is String) {
          buffer.writeln(json['displayName']);
        }
      } catch (_) {}
    }

    return buffer.toString();
  }

  // ─── Type detection ─────────────────────────────────────────

  String _detectType(String path) {
    final files = Directory(path).listSync();
    final names = files
        .map((f) => f.path.split(Platform.pathSeparator).last)
        .toSet();

    if (names.contains('pubspec.yaml')) {
      // Check if it's a Flutter app or just a package
      try {
        final content = File('$path/pubspec.yaml').readAsStringSync();
        if (content.contains('flutter:') &&
            (content.contains('uses-material-design:') ||
                content.contains('android:') ||
                content.contains('ios:'))) {
          return 'app';
        }
        return 'package';
      } catch (_) {
        return 'package';
      }
    }
    if (names.contains('package.json')) {
      try {
        final content = File('$path/package.json').readAsStringSync();
        final json = jsonDecode(content);
        if (json is Map) {
          final engines = json['engines'];
          final hasVscode =
              json['publisher'] != null ||
              (engines is Map && engines['vscode'] != null);
          if (hasVscode) return 'extension';
        }
        return 'web';
      } catch (_) {
        return 'web';
      }
    }
    if (names.contains('index.html')) return 'web';
    if (names.contains('firebase.json') || names.contains('.firebaserc')) {
      return 'web';
    }

    return 'app';
  }

  String _formatName(String id) {
    return id
        .split('-')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // ─── Description extraction ─────────────────────────────────

  String _extractDescription(String path) {
    // Try pubspec.yaml description
    final pubspec = File('$path/pubspec.yaml');
    if (pubspec.existsSync()) {
      try {
        final lines = pubspec.readAsLinesSync();
        for (final line in lines) {
          if (line.trimLeft().startsWith('description:')) {
            final desc = line.replaceAll(RegExp(r'description:\s*'), '').trim();
            if (desc.isNotEmpty && !desc.startsWith('#')) return desc;
          }
        }
      } catch (_) {}
    }

    // Try package.json description
    final pkgJson = File('$path/package.json');
    if (pkgJson.existsSync()) {
      try {
        final json = jsonDecode(pkgJson.readAsStringSync()) as Map?;
        if (json?['description'] is String) {
          return (json!['description'] as String).trim();
        }
        if (json?['displayName'] is String) {
          return (json!['displayName'] as String).trim();
        }
      } catch (_) {}
    }

    return 'Pendiente de completar';
  }

  // ─── URL detection ──────────────────────────────────────────

  Map<String, String> _detectUrls(String path, String type) {
    final urls = <String, String>{};

    // Check for GitHub remote
    try {
      final gitDir = Directory('$path/.git');
      if (!gitDir.existsSync()) {
        // Try parent directories
        var dir = Directory(path);
        for (int i = 0; i < 3; i++) {
          dir = dir.parent;
          if (Directory('${dir.path}/.git').existsSync()) {
            break;
          }
        }
      }

      // Read git remote URL
      final configFile = File('$path/.git/config');
      if (configFile.existsSync()) {
        final config = configFile.readAsStringSync();
        final match = RegExp(r'url\s*=\s*(.+)\.git').firstMatch(config);
        if (match != null) {
          var url = match.group(1)!;
          // Convert SSH to HTTPS
          url = url.replaceAll('git@github.com:', 'https://github.com/');
          url = url.replaceAll('git://', 'https://');
          urls['github'] = url;
        }
      }
    } catch (_) {}

    // Check for Landing Page
    try {
      final landingFile = File('$path/landing.html');
      final indexFile = File('$path/index.html');
      if (landingFile.existsSync() || indexFile.existsSync()) {
        if (urls['github'] != null) {
          final parts = urls['github']!.replaceAll('https://github.com/', '').split('/');
          if (parts.length >= 2) {
            urls['landing'] = 'https://${parts[0]}.github.io/${parts[1]}';
          }
        }
      }

      // Si aún no hay landing, buscar en README.md
      if (urls['landing'] == null) {
        final readmeFile = File('$path/README.md');
        if (readmeFile.existsSync()) {
          final text = readmeFile.readAsStringSync();
          final domainRegex = RegExp(
            r'(https?://[a-zA-Z0-9\-\._]+\.(?:web\.app|firebaseapp\.com|vercel\.app|netlify\.app|pages\.dev|github\.io)[^\s\)\],]*)',
            caseSensitive: false,
          );
          final match = domainRegex.firstMatch(text);
          if (match != null) {
            urls['landing'] = match.group(1)!;
          }
        }
      }
    } catch (_) {}

    return urls;
  }
}
