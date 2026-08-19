import 'dart:io';
import '../../../models/repo_analysis.dart';
import '../../../services/github_api.dart';

enum InputSource { gitHub, local }

class RulesEngine {
  final GitHubApiService _github = GitHubApiService();

  /// Detecta automáticamente si es una URL de GitHub o una ruta local.
  /// Lanza excepción si el input no es válido.
  InputSource detectSource(String input) {
    final trimmed = input.trim();
    // Empieza con / o ~ → ruta local
    if (trimmed.startsWith('/') || trimmed.startsWith('~')) {
      return InputSource.local;
    }
    // Contiene github.com → GitHub URL
    if (trimmed.contains('github.com')) {
      return InputSource.gitHub;
    }
    // Es una ruta relativa que existe
    if (Directory(trimmed).existsSync()) {
      return InputSource.local;
    }
    // Nada de lo anterior → asumimos GitHub por defecto (usuario pegará URL)
    return InputSource.gitHub;
  }

  Future<RepoAnalysis> analyzeRepo(String url) async {
    final source = detectSource(url);

    if (source == InputSource.local) {
      return _analyzeLocal(url.trim());
    } else {
      return _analyzeGitHub(url);
    }
  }

  /// Análisis de repositorio local en el filesystem.
  Future<RepoAnalysis> _analyzeLocal(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      throw Exception('La ruta local no existe: $path');
    }

    final name = dir.path.split(Platform.pathSeparator).last;
    final owner = 'local'; // sin owner en paths locales

    // Detectar tipo de proyecto
    final projectType = _detectProjectType(path);

    final s = Platform.pathSeparator;
    final readmeFile = File('$path${s}README.md');
    final licenseFile = File('$path${s}LICENSE');
    final promoDir = Directory('$path${s}promo');
    final landingFile = File('$path${s}landing.html');
    final indexFile = File('$path${s}index.html');
    final brandSpecFile = File('$path${s}promo${s}brand-spec.md');

    final hasReadme = readmeFile.existsSync();
    final hasLicense = licenseFile.existsSync();
    final hasPromoFolder = promoDir.existsSync();
    final hasBrandSpec = brandSpecFile.existsSync();

    String? landingUrl;
    if (landingFile.existsSync() || indexFile.existsSync()) {
      landingUrl = landingFile.existsSync() ? '$path${s}landing.html' : '$path${s}index.html';
    } else if (hasReadme) {
      try {
        final content = readmeFile.readAsStringSync();
        landingUrl = _findLandingUrlInText(content);
      } catch (_) {}
    }

    final hasLanding = landingUrl != null;

    bool hasScreenshots = false;
    bool hasVideo = false;
    if (hasPromoFolder) {
      final promoContents = promoDir.listSync();
      hasScreenshots = promoContents.any((e) =>
        e.path.contains('screenshot') ||
        e.path.contains('ios') ||
        e.path.contains('android') ||
        (e is File && (e.path.endsWith('.png') || e.path.endsWith('.jpg') || e.path.endsWith('.jpeg')))
      );
      hasVideo = promoContents.any((e) =>
        e.path.endsWith('.mp4') ||
        e.path.endsWith('.mov') ||
        e.path.contains('video')
      );
    }

    // Calcular items faltantes
    final missingItems = <String>[];
    if (!hasReadme) missingItems.add('README.md (obligatorio)');
    if (!hasLicense) missingItems.add('LICENSE (recomendado)');
    if (!hasPromoFolder) {
      missingItems.add('Carpeta promo/ (assets de marketing)');
    } else {
      if (!hasScreenshots) missingItems.add('Screenshots en promo/screenshots/');
      if (!hasVideo) missingItems.add('Video promocional en promo/videos/');
      if (!hasBrandSpec) missingItems.add('promo/brand-spec.md (colores y tipografía)');
    }
    if (!hasLanding) missingItems.add('Landing page (index.html, landing.html o URL pública en README)');

    return RepoAnalysis(
      owner: owner,
      name: name,
      url: path,
      description: null,
      language: null,
      topics: [],
      projectType: projectType,
      hasReadme: hasReadme,
      hasLicense: hasLicense,
      hasPromoFolder: hasPromoFolder,
      hasScreenshots: hasScreenshots,
      hasVideo: hasVideo,
      hasLanding: hasLanding,
      landingUrl: landingUrl,
      hasBrandSpec: hasBrandSpec,
      missingItems: missingItems,
    );
  }

  /// Análisis de repositorio remoto via GitHub API (Git Tree + Repo Info).
  Future<RepoAnalysis> _analyzeGitHub(String url) async {
    final parts = _parseGitHubUrl(url);
    if (parts == null) {
      throw Exception('URL no válida. Usa formato: https://github.com/usuario/repo');
    }

    final owner = parts['owner']!;
    final name = parts['name']!;

    // Obtener info básica del repo y árbol de archivos
    final repoInfo = await _github.fetchRepoInfo(owner, name);
    final tree = await _github.fetchRepoTree(owner, name);
    final readmeContent = await _github.fetchRawReadme(owner, name);

    final bool hasReadme;
    final bool hasLicense;
    final bool hasPromoFolder;
    final bool hasScreenshots;
    final bool hasVideo;
    final bool hasBrandSpec;
    String? landingUrl;
    ProjectType projectType = ProjectType.unknown;

    if (tree != null) {
      final treeLower = tree.map((p) => p.toLowerCase()).toSet();

      hasReadme = tree.any((p) => p.toLowerCase() == 'readme.md');
      hasLicense = tree.any((p) => p.toLowerCase().startsWith('license'));
      hasPromoFolder = tree.any((p) => p.startsWith('promo/'));
      hasScreenshots = tree.any((p) =>
          p.startsWith('promo/screenshots/') ||
          p.contains('screenshot') ||
          p.contains('ios') ||
          p.contains('android') ||
          (p.startsWith('promo/') && (p.endsWith('.png') || p.endsWith('.jpg') || p.endsWith('.jpeg'))));
      hasVideo = tree.any((p) =>
          p.startsWith('promo/videos/') ||
          p.endsWith('.mp4') ||
          p.endsWith('.mov') ||
          (p.startsWith('promo/') && p.contains('video')));
      hasBrandSpec = tree.any((p) => p == 'promo/brand-spec.md');

      // Buscar landing en árbol de archivos
      final hasPhysicalLanding = tree.any((p) =>
          p == 'landing.html' ||
          p == 'index.html' ||
          p == 'web/index.html' ||
          p == 'public/index.html');

      if (hasPhysicalLanding) {
        landingUrl = 'https://$owner.github.io/$name';
      } else if (repoInfo?['has_pages'] == true) {
        landingUrl = 'https://$owner.github.io/$name';
      } else if (repoInfo?['homepage'] != null && (repoInfo!['homepage'] as String).isNotEmpty) {
        landingUrl = repoInfo['homepage'];
      } else if (readmeContent != null) {
        landingUrl = _findLandingUrlInText(readmeContent);
      }

      // Detectar tipo de proyecto desde el árbol
      if (treeLower.contains('pubspec.yaml')) {
        if (treeLower.contains('lib/main.dart')) {
          projectType = ProjectType.flutterApp;
        } else {
          projectType = ProjectType.flutterPackage;
        }
      } else if (treeLower.contains('package.json')) {
        projectType = ProjectType.node;
      } else if (treeLower.contains('setup.py') || treeLower.contains('pyproject.toml') || treeLower.contains('requirements.txt')) {
        projectType = ProjectType.python;
      } else if (treeLower.contains('workflow.json') || tree.any((p) => p.startsWith('n8n/'))) {
        projectType = ProjectType.n8nWorkflow;
      }
    } else {
      // Fallback a endpoints individuales si no se pudo leer el árbol
      hasReadme = await _github.hasFile(owner, name, 'README.md');
      hasLicense = await _github.hasFile(owner, name, 'LICENSE');
      hasPromoFolder = await _github.listContents(owner, name, path: 'promo') != null;
      final promoContents = hasPromoFolder
          ? await _github.listContents(owner, name, path: 'promo')
          : null;
      hasScreenshots = _hasScreenshots(promoContents);
      hasVideo = _hasVideo(promoContents);
      hasBrandSpec = await _github.hasFile(owner, name, 'promo/brand-spec.md');

      if (await _github.hasFile(owner, name, 'landing.html') || await _github.hasFile(owner, name, 'index.html')) {
        landingUrl = 'https://$owner.github.io/$name';
      } else if (repoInfo?['has_pages'] == true) {
        landingUrl = 'https://$owner.github.io/$name';
      } else if (repoInfo?['homepage'] != null && (repoInfo!['homepage'] as String).isNotEmpty) {
        landingUrl = repoInfo['homepage'];
      } else if (readmeContent != null) {
        landingUrl = _findLandingUrlInText(readmeContent);
      }
    }

    final hasLanding = landingUrl != null;

    // Calcular items faltantes
    final missingItems = <String>[];
    if (!hasReadme) missingItems.add('README.md (obligatorio)');
    if (!hasLicense) missingItems.add('LICENSE (recomendado)');
    if (!hasPromoFolder) {
      missingItems.add('Carpeta promo/ (assets de marketing)');
    } else {
      if (!hasScreenshots) missingItems.add('Screenshots en promo/screenshots/');
      if (!hasVideo) missingItems.add('Video promocional en promo/videos/');
      if (!hasBrandSpec) missingItems.add('promo/brand-spec.md (colores y tipografía)');
    }
    if (!hasLanding) missingItems.add('Landing page (index.html, landing.html o URL pública en README)');

    return RepoAnalysis(
      owner: owner,
      name: name,
      url: url,
      description: repoInfo?['description'],
      language: repoInfo?['language'],
      topics: List<String>.from(repoInfo?['topics'] ?? []),
      projectType: projectType,
      hasReadme: hasReadme,
      hasLicense: hasLicense,
      hasPromoFolder: hasPromoFolder,
      hasScreenshots: hasScreenshots,
      hasVideo: hasVideo,
      hasLanding: hasLanding,
      landingUrl: landingUrl,
      hasBrandSpec: hasBrandSpec,
      missingItems: missingItems,
    );
  }

  /// Busca una URL de landing o web app en el texto del README
  String? _findLandingUrlInText(String text) {
    // 1. Dominios comunes de hosting de apps: .web.app, .firebaseapp.com, .vercel.app, .netlify.app, .pages.dev, .github.io
    final domainRegex = RegExp(
      r'(https?://[a-zA-Z0-9\-\._]+\.(?:web\.app|firebaseapp\.com|vercel\.app|netlify\.app|pages\.dev|github\.io)[^\s\)\],]*)',
      caseSensitive: false,
    );
    final domainMatch = domainRegex.firstMatch(text);
    if (domainMatch != null) {
      return domainMatch.group(1);
    }

    // 2. Links en formato markdown: [Demo](https://...) o [Landing](https://...)
    final markdownLinkRegex = RegExp(
      r'\[(?:landing|demo|web|app|live|sitio|ver en vivo)\]\((https?://[^\s\)]+)\)',
      caseSensitive: false,
    );
    final linkMatch = markdownLinkRegex.firstMatch(text);
    if (linkMatch != null) {
      return linkMatch.group(1);
    }

    // 3. Patrón directo de subdominio: ejemplo "apliarte-link.web.app"
    final rawAppDomainRegex = RegExp(
      r'([a-zA-Z0-9\-_]+\.(?:web\.app|firebaseapp\.com|vercel\.app|netlify\.app|pages\.dev|github\.io))',
      caseSensitive: false,
    );
    final rawMatch = rawAppDomainRegex.firstMatch(text);
    if (rawMatch != null) {
      return 'https://${rawMatch.group(1)}';
    }

    return null;
  }

  /// Detecta el tipo de proyecto según archivos de configuración.
  ProjectType _detectProjectType(String path) {
    final s = Platform.pathSeparator;
    if (File('$path${s}pubspec.yaml').existsSync()) {
      // ¿Es un package o una app?
      final content = File('$path${s}pubspec.yaml').readAsStringSync();
      if (content.contains('pluginClass:') ||
          content.contains('publish_to: https://pub.dev') ||
          content.contains('version:')) {
        // Mirar si tiene platform folders → package, si tiene lib/main.dart → app
        if (File('$path${s}lib${s}main.dart').existsSync()) {
          return ProjectType.flutterApp;
        }
        return ProjectType.flutterPackage;
      }
      return ProjectType.flutterApp;
    }
    if (File('$path${s}package.json').existsSync()) {
      final content = File('$path${s}package.json').readAsStringSync();
      if (content.contains('"categories"') || content.contains('vscode')) {
        return ProjectType.vscodeExtension;
      }
      return ProjectType.node;
    }
    if (File('$path${s}setup.py').existsSync() ||
        File('$path${s}pyproject.toml').existsSync() ||
        File('$path${s}requirements.txt').existsSync()) {
      return ProjectType.python;
    }
    if (File('$path${s}workflow.json').existsSync() ||
        Directory('$path${s}n8n').existsSync()) {
      return ProjectType.n8nWorkflow;
    }
    return ProjectType.unknown;
  }

  Map<String, String>? _parseGitHubUrl(String url) {
    final regex = RegExp(r'github\.com/([^/]+)/([^/]+)');
    final match = regex.firstMatch(url);
    if (match != null) {
      return {
        'owner': match.group(1)!,
        'name': match.group(2)!.replaceAll('.git', ''),
      };
    }
    return null;
  }

  bool _hasScreenshots(List<dynamic>? contents) {
    if (contents == null) return false;
    return contents.any((item) => 
      item['name'].toString().contains('screenshot') ||
      item['name'].toString().contains('ios') ||
      item['name'].toString().contains('android')
    );
  }

  bool _hasVideo(List<dynamic>? contents) {
    if (contents == null) return false;
    return contents.any((item) => 
      item['name'].toString().endsWith('.mp4') ||
      item['name'].toString().endsWith('.mov') ||
      item['name'].toString().contains('video')
    );
  }
}
