// ═══════════════════════════════════════════════════════════════
// 🚚 Agente 7 — Evaluador de Hosting
// ═══════════════════════════════════════════════════════════════
// Analiza el hosting actual del proyecto, detecta alternativas
// viables y recomienda migración si aplica.
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

import '../domain/agent_interface.dart';

/// Opciones de hosting conocidas con sus características.
class _HostingOption {
  final String id;
  final String name;
  final int priority; // lower = preferred
  final String cost;
  final bool supportsStatic;
  final bool supportsDynamic;
  final bool supportsVideos;
  final bool hasCDN;
  final bool hasSSL;
  final bool oneClickDeploy;
  final String setupTime;

  const _HostingOption({
    required this.id,
    required this.name,
    required this.priority,
    required this.cost,
    required this.supportsStatic,
    required this.supportsDynamic,
    required this.supportsVideos,
    required this.hasCDN,
    required this.hasSSL,
    required this.oneClickDeploy,
    required this.setupTime,
  });

  static const options = [
    _HostingOption(
      id: 'firebase',
      name: 'Firebase Hosting',
      priority: 1,
      cost: 'Gratis (free tier)',
      supportsStatic: true,
      supportsDynamic: true,
      supportsVideos: true,
      hasCDN: true,
      hasSSL: true,
      oneClickDeploy: true,
      setupTime: '1 min',
    ),
    _HostingOption(
      id: 'github-pages',
      name: 'GitHub Pages',
      priority: 2,
      cost: 'Gratis',
      supportsStatic: true,
      supportsDynamic: false,
      supportsVideos: false,
      hasCDN: true,
      hasSSL: true,
      oneClickDeploy: true,
      setupTime: '2 min',
    ),
    _HostingOption(
      id: 'netlify',
      name: 'Netlify',
      priority: 3,
      cost: 'Gratis (free tier)',
      supportsStatic: true,
      supportsDynamic: true,
      supportsVideos: false,
      hasCDN: true,
      hasSSL: true,
      oneClickDeploy: true,
      setupTime: '2 min',
    ),
    _HostingOption(
      id: 'vercel',
      name: 'Vercel',
      priority: 4,
      cost: 'Gratis (free tier)',
      supportsStatic: true,
      supportsDynamic: true,
      supportsVideos: false,
      hasCDN: true,
      hasSSL: true,
      oneClickDeploy: true,
      setupTime: '2 min',
    ),
    _HostingOption(
      id: 'cloudflare',
      name: 'Cloudflare Pages',
      priority: 5,
      cost: 'Gratis (free tier)',
      supportsStatic: true,
      supportsDynamic: true,
      supportsVideos: false,
      hasCDN: true,
      hasSSL: true,
      oneClickDeploy: true,
      setupTime: '3 min',
    ),
    _HostingOption(
      id: 'docker-vps',
      name: 'VPS / Docker',
      priority: 6,
      cost: '€4-10/mes',
      supportsStatic: true,
      supportsDynamic: true,
      supportsVideos: true,
      hasCDN: false,
      hasSSL: false,
      oneClickDeploy: false,
      setupTime: '30 min',
    ),
    _HostingOption(
      id: 'pub-dev',
      name: 'pub.dev (Flutter package)',
      priority: 0,
      cost: 'Gratis',
      supportsStatic: false,
      supportsDynamic: false,
      supportsVideos: false,
      hasCDN: true,
      hasSSL: true,
      oneClickDeploy: true,
      setupTime: '1 min',
    ),
    _HostingOption(
      id: 'vscode-marketplace',
      name: 'VS Code Marketplace',
      priority: -1,
      cost: 'Gratis',
      supportsStatic: false,
      supportsDynamic: false,
      supportsVideos: false,
      hasCDN: true,
      hasSSL: true,
      oneClickDeploy: true,
      setupTime: '5 min',
    ),
  ];
}

class MigratorAgent implements AgentInterface {
  @override
  String get agentId => 'migrator';
  @override
  String get agentName => 'Evaluador de Hosting';
  @override
  String get inboxStep => 'Paso 7';

  @override
  Future<bool> canExecute(String projectPath) async => true;

  @override
  Future<AgentOutput> execute(String projectPath) async {
    final projectName = projectPath.split(Platform.pathSeparator).last;

    // 1. Detectar configuración actual del proyecto
    final config = await _analyzeProject(projectPath);

    // 2. Detectar hosting actual
    final currentHosting = _detectCurrentHosting(projectPath, config);

    // 3. Determinar opciones viables
    final options = _findViableOptions(config);

    // 4. Generar recomendación
    final recommendation = _generateRecommendation(
      projectName, config, currentHosting, options,
    );

    // 5. Generar comandos si aplica migración
    final commands = _generateCommands(
      config, recommendation['target'] as String,
    );

    return AgentOutput(
      agentId: agentId,
      success: true,
      summary: recommendation['summary'] as String,
      data: {
        'projectName': projectName,
        'type': config['type'],
        'currentHosting': currentHosting,
        'recommended': recommendation['target'],
        'shouldMigrate': recommendation['shouldMigrate'],
        'reason': recommendation['reason'],
        'viableOptions': options,
        'commands': commands,
      },
    );
  }

  // ─── Project analysis ──────────────────────────────────────

  Future<Map<String, dynamic>> _analyzeProject(String path) async {
    final config = <String, dynamic>{
      'type': 'unknown',
      'hasBuildStep': false,
      'buildOutput': null,
      'needsBackend': false,
      'needsDatabase': false,
      'hasVideo': false,
      'hasStaticFiles': false,
      'dartType': null,
    };

    final files = Directory(path).listSync();
    final names = files.map((f) => f.path.split(Platform.pathSeparator).last).toSet();
    final allFiles = _listFilesRecursive(path);

    if (names.contains('pubspec.yaml')) {
      try {
        final content = File('$path/pubspec.yaml').readAsStringSync();
        config['dartType'] = content.contains('flutter:') ? 'flutter' : 'dart';
        config['hasBuildStep'] = true;

        if (content.contains('flutter:')) {
          // Check for web
          if (content.contains('web:') ||
              Directory('$path/web').existsSync()) {
            config['buildOutput'] = 'build/web';
            config['type'] = 'flutter-web';
          } else {
            config['type'] = 'flutter-app';
          }
          // Check for assets
          if (content.contains('assets:')) {
            config['hasVideo'] = allFiles.any((f) =>
                f.endsWith('.mp4') || f.endsWith('.mov'));
          }
        } else {
          config['type'] = 'dart-package';
          config['buildOutput'] = null;
        }
      } catch (_) {}
    } else if (names.contains('package.json')) {
      try {
        final content = File('$path/package.json').readAsStringSync();
        final json = jsonDecode(content);
        if (json is Map) {
          final scripts = json['scripts'] as Map? ?? {};
          config['hasBuildStep'] =
              scripts.containsKey('build') || scripts.containsKey('deploy');
          config['buildOutput'] = _detectBuildOutput(path);

          if (json['publisher'] != null ||
              (json['engines'] is Map &&
                  (json['engines'] as Map)['vscode'] != null)) {
            config['type'] = 'vscode-extension';
          } else {
            config['type'] = 'node-web';
          }
        }
      } catch (_) {}
    } else if (names.contains('index.html')) {
      config['type'] = 'static-web';
      config['hasStaticFiles'] = true;
    }

    // Detect backend needs
    config['needsBackend'] = names.contains('functions') ||
        names.contains('server') ||
        names.contains('api') ||
        allFiles.any((f) =>
            f.contains('firebase-functions') || f.contains('express'));

    return config;
  }

  String? _detectBuildOutput(String path) {
    for (final dir in ['dist', 'build', 'out', '_site', 'public']) {
      if (Directory('$path/$dir').existsSync()) return dir;
    }
    return null;
  }

  List<String> _listFilesRecursive(String path) {
    final files = <String>[];
    try {
      final dir = Directory(path);
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        files.add(entity.path);
      }
    } catch (_) {}
    return files;
  }

  // ─── Current hosting detection ─────────────────────────────

  String _detectCurrentHosting(String path, Map<String, dynamic> config) {
    final files = Directory(path).listSync();
    final names = files.map((f) => f.path.split(Platform.pathSeparator).last).toSet();

    if (names.contains('firebase.json') && names.contains('.firebaserc')) {
      return 'firebase';
    }
    if (names.contains('netlify.toml')) return 'netlify';
    if (names.contains('vercel.json')) return 'vercel';
    if (names.contains('Dockerfile')) return 'docker-vps';
    if (names.contains('CNAME') || names.contains('_redirects')) {
      return 'github-pages';
    }
    if (names.contains('_config.yml') &&
        config['type'] == 'static-web') {
      return 'github-pages';
    }

    // Check firebase.json in parent
    var dir = Directory(path);
    for (int i = 0; i < 3; i++) {
      dir = dir.parent;
      final parentFiles = dir.listSync().map((f) => f.path.split('/').last).toSet();
      if (parentFiles.contains('firebase.json')) {
        return 'firebase';
      }
    }

    return 'none';
  }

  // ─── Viable hosting options ────────────────────────────────

  List<Map<String, dynamic>> _findViableOptions(Map<String, dynamic> config) {
    final viable = <Map<String, dynamic>>[];

    for (final option in _HostingOption.options) {
      bool fits = true;

      switch (config['type'] as String) {
        case 'flutter-web':
          fits = option.supportsStatic;
          break;
        case 'flutter-app':
          fits = false; // mobile/desktop apps don't need web hosting
          break;
        case 'dart-package':
        case 'vscode-extension':
          fits = option.id == 'pub-dev' || option.id == 'vscode-marketplace';
          break;
        case 'node-web':
          fits = option.supportsDynamic;
          break;
        case 'static-web':
          fits = option.supportsStatic;
          break;
        default:
          fits = option.supportsStatic;
      }

      if (fits && config['hasVideo'] == true && !option.supportsVideos) {
        // Video hosting requires CDN with video support or VPS
        if (option.id != 'firebase' && option.id != 'docker-vps') {
          fits = false;
        }
      }

      if (fits) {
        viable.add({
          'id': option.id,
          'name': option.name,
          'cost': option.cost,
          'cd': option.oneClickDeploy,
          'priority': option.priority,
        });
      }
    }

    viable.sort((a, b) => (a['priority'] as int).compareTo(b['priority'] as int));
    return viable;
  }

  // ─── Recommendation engine ─────────────────────────────────

  Map<String, dynamic> _generateRecommendation(
    String projectName,
    Map<String, dynamic> config,
    String current,
    List<Map<String, dynamic>> options,
  ) {
    final sb = StringBuffer();
    final type = config['type'] as String;
    final target = options.isNotEmpty ? options.first['id'] as String : 'none';

    sb.writeln('🚚 Evaluación de hosting para "$projectName":\n');
    sb.writeln('   • Tipo: ${_typeLabel(type)}');
    sb.writeln('   • Hosting actual: ${_hostingLabel(current)}');
    sb.writeln('');

    // Determine if migration is needed
    bool shouldMigrate = false;
    String reason = '';

    if (options.isEmpty) {
      shouldMigrate = false;
      reason = 'El proyecto no requiere hosting web';
    } else if (current == 'none') {
      shouldMigrate = true;
      reason = 'El proyecto no tiene hosting configurado';
    } else if (current == 'docker-vps' && type == 'static-web') {
      shouldMigrate = true;
      reason = 'Estás usando un VPS para un sitio estático. '
          'Firebase Hosting es gratis, más rápido y con CDN.';
    } else if (current == 'github-pages' && (type == 'node-web')) {
      shouldMigrate = true;
      reason = 'GitHub Pages no soporta backend dinámico. '
          'Usá Firebase Hosting + Cloud Functions.';
    } else if (current != target && target != 'none') {
      shouldMigrate = true;
      reason = 'Hay una opción mejor priorizada disponible';
    }

    if (shouldMigrate) {
      sb.writeln('⚠️ $reason.');
      sb.writeln('   ✅ Recomendado: ${_hostingLabel(target)}');
      sb.writeln('');

      if (options.length > 1) {
        sb.writeln('📋 Alternativas viables:');
        for (final opt in options.skip(1).take(3)) {
          sb.writeln('   • ${opt['name']} (${opt['cost']})');
        }
      }
    } else {
      sb.writeln('✅ El hosting actual es adecuado para este tipo de proyecto.');
    }

    return {
      'summary': sb.toString().trim(),
      'target': target,
      'shouldMigrate': shouldMigrate,
      'reason': reason,
    };
  }

  // ─── Migration commands ────────────────────────────────────

  List<Map<String, String>> _generateCommands(
    Map<String, dynamic> config, String target,
  ) {
    if (target == 'none') return [];

    switch (target) {
      case 'firebase':
        final buildDir = config['buildOutput'] ?? 'build/web';
        return [
          {'step': '1. Instalar CLI', 'cmd': 'npm install -g firebase-tools'},
          {'step': '2. Iniciar Firebase', 'cmd': 'firebase init hosting'},
          {
            'step': '3. Configurar build',
            'cmd': 'En firebase.json, poner "public": "$buildDir"',
          },
          {'step': '4. Build', 'cmd': _buildCommand(config['type'] as String)},
          {'step': '5. Deploy', 'cmd': 'firebase deploy --only hosting'},
        ];
      case 'github-pages':
        return [
          {
            'step': '1. Configurar GitHub Pages',
            'cmd': 'Settings → Pages → Source: GitHub Actions',
          },
          {'step': '2. Build', 'cmd': _buildCommand(config['type'] as String)},
        ];
      case 'pub-dev':
        return [
          {'step': '1. Verificar análisis', 'cmd': 'dart analyze'},
          {'step': '2. Publicar', 'cmd': 'dart pub publish'},
        ];
      case 'vscode-marketplace':
        return [
          {'step': '1. Empaquetar', 'cmd': 'vsce package'},
          {'step': '2. Publicar', 'cmd': 'vsce publish'},
        ];
      default:
        return [];
    }
  }

  String _buildCommand(String type) {
    switch (type) {
      case 'flutter-web':
        return 'flutter build web';
      case 'node-web':
        return 'npm run build';
      default:
        return 'Ejecutar build del proyecto';
    }
  }

  // ─── Helpers ───────────────────────────────────────────────

  String _typeLabel(String type) {
    switch (type) {
      case 'flutter-web': return 'Flutter Web';
      case 'flutter-app': return 'Flutter App (móvil/desktop)';
      case 'dart-package': return 'Paquete Dart';
      case 'vscode-extension': return 'Extensión VS Code';
      case 'node-web': return 'Web (Node.js)';
      case 'static-web': return 'Web estática';
      default: return type;
    }
  }

  String _hostingLabel(String hosting) {
    switch (hosting) {
      case 'firebase': return '🔥 Firebase Hosting';
      case 'github-pages': return '📦 GitHub Pages';
      case 'netlify': return '🌐 Netlify';
      case 'vercel': return '▲ Vercel';
      case 'cloudflare': return '☁️ Cloudflare Pages';
      case 'docker-vps': return '🐳 VPS / Docker';
      case 'pub-dev': return '📦 pub.dev';
      case 'vscode-marketplace': return '🧩 VS Code Marketplace';
      case 'none': return '❌ Sin hosting';
      default: return hosting;
    }
  }
}
