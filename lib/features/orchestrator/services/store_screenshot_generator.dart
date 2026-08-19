import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import '../../../core/logging/app_logger.dart';

// ═══════════════════════════════════════════════════════════════
// 📱 StoreScreenshotGenerator — Capturas Profesionales para Tiendas
// ═══════════════════════════════════════════════════════════════
// Genera capturas de marketing para App Store y Google Play
// enmarcadas en mockups de dispositivos con titulares llamativos
// en todos los idiomas seleccionados.
// ═══════════════════════════════════════════════════════════════

/// Especificación de un slide o captura para la tienda.
class StoreSlideSpec {
  final String screenshotPath;
  final Map<String, String> titles; // {'es': '...', 'en': '...'}
  final Map<String, String> subtitles;
  final String badgeText;

  const StoreSlideSpec({
    required this.screenshotPath,
    required this.titles,
    required this.subtitles,
    this.badgeText = 'ERBOLAMM APP',
  });
}

/// Idiomas soportados por defecto.
const kAvailableStoreLanguages = {
  'es': 'Español',
  'en': 'English',
  'pt': 'Português',
  'fr': 'Français',
  'de': 'Deutsch',
  'it': 'Italiano',
  'ja': '日本語',
  'zh': '中文',
};

/// Posibles paths de Chrome en macOS y Linux.
const _chromePaths = [
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/Applications/Chromium.app/Contents/MacOS/Chromium',
  '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium-browser',
  '/usr/bin/chromium',
];

class StoreScreenshotGenerator {
  /// Busca Chrome/Chromium en el sistema.
  static String? _findChrome() {
    for (final path in _chromePaths) {
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  /// Genera las capturas de tienda enmarcadas para los idiomas seleccionados.
  ///
  /// [projectPath] — Directorio raíz del proyecto.
  /// [languages] — Lista de códigos de idioma seleccionados (ej: `['es', 'en', 'pt']`).
  /// [slides] — Lista opcional de especificaciones de slides. Si no se pasa,
  ///            se autodescubren las capturas reales de Flutter en `promo/screenshots/`.
  static Future<Map<String, List<String>>> generateFramedStoreScreenshots({
    required String projectPath,
    List<String> languages = const ['es', 'en', 'pt', 'fr', 'de', 'it'],
    List<StoreSlideSpec>? customSlides,
    String? primaryColor,
    String? accentColor,
  }) async {
    final chrome = _findChrome();
    if (chrome == null) {
      AppLogger.e('[StoreScreenshotGenerator] Chrome no disponible para renderizado.');
      return {};
    }

    final projectName = p.basename(projectPath);
    final rawScreenshots = _discoverRawScreenshots(projectPath);
    if (rawScreenshots.isEmpty && (customSlides == null || customSlides.isEmpty)) {
      AppLogger.i('[StoreScreenshotGenerator] ℹ️ Sin capturas base en erbolamm-studio/screenshots/raw/. Colocá capturas PNG de tu app allí para generar los stores.');
      return {};
    }

    final slides = customSlides ?? _buildDefaultSlideSpecs(rawScreenshots, projectName);
    final results = <String, List<String>>{};

    final htmlTemplateDir = p.join(projectPath, 'erbolamm-studio', 'source', 'store_templates');
    Directory(htmlTemplateDir).createSync(recursive: true);

    for (final lang in languages) {
      results[lang] = [];
      final langStoreDir = p.join(projectPath, 'erbolamm-studio', 'screenshots', 'store', lang);
      final iphone65Dir = p.join(langStoreDir, 'iphone_6_5');
      final iphone67Dir = p.join(langStoreDir, 'iphone_6_7');
      final ipadDir = p.join(langStoreDir, 'ipad_13');
      Directory(iphone65Dir).createSync(recursive: true);
      Directory(iphone67Dir).createSync(recursive: true);
      Directory(ipadDir).createSync(recursive: true);

      for (int i = 0; i < slides.length; i++) {
        final slide = slides[i];
        final title = slide.titles[lang] ?? slide.titles['es'] ?? slide.titles['en'] ?? projectName;
        final subtitle = slide.subtitles[lang] ?? slide.subtitles['es'] ?? slide.subtitles['en'] ?? '';
        final badge = slide.badgeText;

        // Render iPhone 6.5" (1284x2778) — Exacto para App Store Connect 6.5" Display
        final iphone65Html = _buildSlideHtml(
          title: title,
          subtitle: subtitle,
          badge: badge,
          screenshotPath: slide.screenshotPath,
          width: 1284,
          height: 2778,
          isTablet: false,
          primaryColor: primaryColor ?? '#FF5722',
          accentColor: accentColor ?? '#FFB300',
        );

        final iphone65HtmlFile = p.join(htmlTemplateDir, 'slide_65_${lang}_$i.html');
        File(iphone65HtmlFile).writeAsStringSync(iphone65Html);

        final iphone65OutPath = p.join(iphone65Dir, 'screenshot_${i + 1}.png');
        final okIphone65 = await _captureWithChrome(
          chrome: chrome,
          url: 'file://${File(iphone65HtmlFile).absolute.path}',
          outputPath: iphone65OutPath,
          width: 1284,
          height: 2778,
        );

        if (okIphone65) {
          results[lang]!.add(iphone65OutPath);
        }

        // Render iPhone 6.7" (1290x2796)
        final iphoneHtml = _buildSlideHtml(
          title: title,
          subtitle: subtitle,
          badge: badge,
          screenshotPath: slide.screenshotPath,
          width: 1290,
          height: 2796,
          isTablet: false,
          primaryColor: primaryColor ?? '#FF5722',
          accentColor: accentColor ?? '#FFB300',
        );

        final iphoneHtmlFile = p.join(htmlTemplateDir, 'slide_${lang}_$i.html');
        File(iphoneHtmlFile).writeAsStringSync(iphoneHtml);

        final iphoneOutPath = p.join(iphone67Dir, 'screenshot_${i + 1}.png');
        final okIphone = await _captureWithChrome(
          chrome: chrome,
          url: 'file://${File(iphoneHtmlFile).absolute.path}',
          outputPath: iphoneOutPath,
          width: 1290,
          height: 2796,
        );

        if (okIphone) {
          results[lang]!.add(iphoneOutPath);
        }

        // Render iPad 13" (2048x2732)
        final ipadHtml = _buildSlideHtml(
          title: title,
          subtitle: subtitle,
          badge: badge,
          screenshotPath: slide.screenshotPath,
          width: 2048,
          height: 2732,
          isTablet: true,
          primaryColor: primaryColor ?? '#FF5722',
          accentColor: accentColor ?? '#FFB300',
        );

        final ipadHtmlFile = p.join(htmlTemplateDir, 'slide_ipad_${lang}_$i.html');
        File(ipadHtmlFile).writeAsStringSync(ipadHtml);

        final ipadOutPath = p.join(ipadDir, 'screenshot_${i + 1}.png');
        final okIpad = await _captureWithChrome(
          chrome: chrome,
          url: 'file://${File(ipadHtmlFile).absolute.path}',
          outputPath: ipadOutPath,
          width: 2048,
          height: 2732,
        );

        if (okIpad) {
          results[lang]!.add(ipadOutPath);
        }
      }

      AppLogger.i(
        '[StoreScreenshotGenerator] ✅ Idioma "$lang": ${results[lang]!.length} capturas enmarcadas generadas.',
      );
    }

    return results;
  }

  /// Busca capturas base generadas por el motor Flutter o provistas por el usuario.
  static List<String> _discoverRawScreenshots(String projectPath) {
    final searchDirs = [
      p.join(projectPath, 'erbolamm-studio', 'screenshots', 'raw'),
      p.join(projectPath, 'erbolamm-studio', 'screenshots', 'real_flutter', 'iphone_6_7'),
      p.join(projectPath, 'erbolamm-studio', 'screenshots', 'appstore', 'iphone_6_7'),
      p.join(projectPath, 'erbolamm-studio', 'screenshots', 'real_flutter'),
      p.join(projectPath, 'erbolamm-studio', 'screenshots'),
      p.join(projectPath, 'assets', 'screenshots'),
    ];

    final found = <String>[];
    for (final dir in searchDirs) {
      if (Directory(dir).existsSync()) {
        final files = Directory(dir)
            .listSync(recursive: false)
            .whereType<File>()
            .where((f) => f.path.endsWith('.png') || f.path.endsWith('.jpg'))
            .where((f) => !p.basename(f.path).startsWith('.'))
            .toList()
          ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

        // Si contiene 01_, 02_, etc., tomar esos preferentemente
        final numbered = files.where((f) => RegExp(r'^\d\d_').hasMatch(p.basename(f.path))).toList();
        final selected = numbered.isNotEmpty ? numbered : files;

        for (final f in selected) {
          if (!found.contains(f.path)) {
            found.add(f.path);
          }
        }
        if (found.isNotEmpty) break;
      }
    }

    return found;
  }

  /// Construye diccionarios de copies localizados para proyectos de la suite.
  static List<StoreSlideSpec> _buildDefaultSlideSpecs(
    List<String> screenshotPaths,
    String projectName,
  ) {
    if (screenshotPaths.isEmpty) return [];

    final cleanName = projectName.replaceAll('_', ' ').replaceAll('-', ' ').trim().toUpperCase();

    return screenshotPaths.map((path) {
      final idx = screenshotPaths.indexOf(path) + 1;
      return StoreSlideSpec(
        screenshotPath: path,
        badgeText: 'ERBOLAMM SUITE',
        titles: {
          'es': '$cleanName — FUNCIÓN $idx',
          'en': '$cleanName — FEATURE $idx',
          'pt': '$cleanName — RECURSO $idx',
          'fr': '$cleanName — FONCTIONNALITÉ $idx',
          'de': '$cleanName — FUNKTION $idx',
          'it': '$cleanName — FUNZIONE $idx',
        },
        subtitles: {
          'es': 'Experiencia fluida, moderna y optimizada',
          'en': 'Seamless, fast, and modern user experience',
          'pt': 'Experiência fluida, rápida e moderna',
          'fr': 'Une expérience utilisateur rapide et moderne',
          'de': 'Flüssige, moderne und optimierte Benutzererfahrung',
          'it': 'Esperienza fluida, veloce e moderna',
        },
      );
    }).toList();
  }

  /// Construye el template HTML5 para la captura enmarcada.
  static String _buildSlideHtml({
    required String title,
    required String subtitle,
    required String badge,
    required String screenshotPath,
    required int width,
    required int height,
    required bool isTablet,
    required String primaryColor,
    required String accentColor,
  }) {
    // Si la imagen existe, incrustar con data URI para carga instantánea
    String imgDataUrl = '';
    if (File(screenshotPath).existsSync()) {
      final bytes = File(screenshotPath).readAsBytesSync();
      imgDataUrl = 'data:image/png;base64,${base64Encode(bytes)}';
    }

    final deviceWidth = isTablet ? 1400 : 800;
    final deviceHeight = isTablet ? 1800 : 1700;
    final borderRadius = isTablet ? 36 : 60;
    final borderWidth = isTablet ? 14 : 12;

    return '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      width: ${width}px;
      height: ${height}px;
      background: radial-gradient(circle at 50% 25%, #240a0a 0%, #0d0404 55%, #000000 100%);
      color: #ffffff;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Outfit", sans-serif;
      overflow: hidden;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: flex-start;
      padding-top: ${isTablet ? 140 : 180}px;
      position: relative;
    }

    .glow {
      position: absolute;
      top: 25%;
      left: 50%;
      transform: translate(-50%, -50%);
      width: ${isTablet ? 1200 : 900}px;
      height: ${isTablet ? 1200 : 900}px;
      background: radial-gradient(circle, rgba(245, 128, 32, 0.28) 0%, transparent 65%);
      pointer-events: none;
      z-index: 1;
    }

    .header-content {
      z-index: 2;
      text-align: center;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: ${isTablet ? 24 : 28}px;
      margin-bottom: ${isTablet ? 80 : 90}px;
      padding: 0 60px;
    }

    .badge {
      display: inline-flex;
      align-items: center;
      background: rgba(245, 128, 32, 0.15);
      border: 3px solid $accentColor;
      padding: ${isTablet ? '12px 36px' : '14px 40px'};
      border-radius: 40px;
      font-size: ${isTablet ? 32 : 36}px;
      font-weight: 800;
      color: $accentColor;
      letter-spacing: 3px;
      text-transform: uppercase;
    }

    .title {
      font-size: ${isTablet ? 82 : 88}px;
      font-weight: 900;
      line-height: 1.12;
      text-shadow: 0 8px 30px rgba(0,0,0,0.9);
      letter-spacing: -0.5px;
      max-width: ${isTablet ? 1600 : 1100}px;
      background: linear-gradient(135deg, #ffffff 40%, #FFCC80 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }

    .subtitle {
      font-size: ${isTablet ? 38 : 42}px;
      font-weight: 500;
      color: #d1d5db;
      max-width: ${isTablet ? 1400 : 1000}px;
      line-height: 1.35;
      text-shadow: 0 4px 15px rgba(0,0,0,0.8);
    }

    .device-mockup {
      z-index: 2;
      position: relative;
      width: ${deviceWidth}px;
      height: ${deviceHeight}px;
      background: #111111;
      border-radius: ${borderRadius}px;
      border: ${borderWidth}px solid #2d2d2d;
      box-shadow: 0 35px 100px rgba(0,0,0,0.95), 0 0 60px rgba(245, 128, 32, 0.35);
      overflow: hidden;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .device-screen {
      width: 100%;
      height: 100%;
      object-fit: cover;
      display: block;
    }
  </style>
</head>
<body>
  <div class="glow"></div>
  <div class="header-content">
    <div class="badge">$badge</div>
    <h1 class="title">$title</h1>
    <p class="subtitle">$subtitle</p>
  </div>
  <div class="device-mockup">
    ${imgDataUrl.isNotEmpty ? '<img class="device-screen" src="$imgDataUrl" alt="Screenshot">' : '<div style="color:#666; font-size:32px;">Vista previa</div>'}
  </div>
</body>
</html>
''';
  }

  /// Ejecuta Chrome headless para capturar la URL a PNG.
  static Future<bool> _captureWithChrome({
    required String chrome,
    required String url,
    required String outputPath,
    required int width,
    required int height,
  }) async {
    try {
      final result = await Process.run(
        chrome,
        [
          '--headless=new',
          '--disable-gpu',
          '--no-sandbox',
          '--hide-scrollbars',
          '--window-size=$width,$height',
          '--screenshot=$outputPath',
          url,
        ],
      ).timeout(const Duration(seconds: 25));

      return result.exitCode == 0 && File(outputPath).existsSync();
    } catch (e) {
      AppLogger.e('[StoreScreenshotGenerator] Error capturando $outputPath: $e');
      return false;
    }
  }
}
