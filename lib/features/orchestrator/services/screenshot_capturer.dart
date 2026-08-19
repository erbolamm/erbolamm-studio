import 'dart:io';

import 'package:path/path.dart' as p;
import '../../../core/logging/app_logger.dart';

// ═══════════════════════════════════════════════════════════════
// 📸 ScreenshotCapturer — Captura screenshots reales
// ═══════════════════════════════════════════════════════════════
// Usa Chrome headless para capturar HTML mockups como PNG reales.
// Si Chrome no está disponible, genera un script Playwright.
// ═══════════════════════════════════════════════════════════════

/// Resultado de una captura.
class ScreenshotCapture {
  final String label;
  final String filePath;
  final int width;
  final int height;
  final bool captured; // true = PNG real, false = script generado
  final String? error;

  const ScreenshotCapture({
    required this.label,
    required this.filePath,
    required this.width,
    required this.height,
    required this.captured,
    this.error,
  });
}

/// Resultado global de la captura.
class ScreenshotCaptureResult {
  final List<ScreenshotCapture> captures;
  final int total;
  final int captured;

  const ScreenshotCaptureResult({
    required this.captures,
    required this.total,
    required this.captured,
  });

  bool get allCaptured => captured == total;
  bool get anyCaptured => captured > 0;
}

/// Posibles paths de Chrome en macOS y Linux.
const _chromePaths = [
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/Applications/Chromium.app/Contents/MacOS/Chromium',
  '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium-browser',
  '/usr/bin/chromium',
];

class ScreenshotCapturer {
  /// Busca Chrome/Chromium en el sistema.
  static String? _findChrome() {
    for (final path in _chromePaths) {
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  /// Verifica si el proyecto es una app de Flutter (contiene pubspec.yaml).
  static bool isFlutterProject(String projectPath) {
    return File(p.join(projectPath, 'pubspec.yaml')).existsSync();
  }

  /// Ejecuta la captura de pantallas reales desde el motor de Flutter (WidgetTester).
  static Future<ScreenshotCaptureResult> captureFromFlutterEngine({
    required String projectPath,
  }) async {
    final testFile = p.join(projectPath, 'test', 'screenshot_real_generator_test.dart');
    final altTestFile = p.join(projectPath, 'test', 'promo_screenshots_test.dart');

    final activeTestPath = File(testFile).existsSync()
        ? testFile
        : File(altTestFile).existsSync()
            ? altTestFile
            : null;

    if (activeTestPath == null) {
      AppLogger.i('[ScreenshotCapturer] No se encontró test de captura Flutter en $projectPath/test/');
      return const ScreenshotCaptureResult(captures: [], total: 0, captured: 0);
    }

    try {
      final relativeTest = p.relative(activeTestPath, from: projectPath);
      await Process.run(
        'flutter',
        ['test', relativeTest],
        workingDirectory: projectPath,
        runInShell: true,
      );

      final realScreensDir = p.join(projectPath, 'erbolamm-studio', 'screenshots', 'real_flutter');
      final appstoreDir = p.join(projectPath, 'erbolamm-studio', 'screenshots', 'appstore');
      final captures = <ScreenshotCapture>[];

      if (Directory(realScreensDir).existsSync()) {
        final files = Directory(realScreensDir).listSync(recursive: true).whereType<File>();
        for (final f in files) {
          if (f.path.endsWith('.png')) {
            captures.add(
              ScreenshotCapture(
                label: p.basenameWithoutExtension(f.path),
                filePath: f.path,
                width: 0,
                height: 0,
                captured: true,
              ),
            );
          }
        }
      }

      if (Directory(appstoreDir).existsSync()) {
        final appstoreFiles = Directory(appstoreDir).listSync(recursive: true).whereType<File>();
        for (final f in appstoreFiles) {
          if (f.path.endsWith('.png') && !captures.any((c) => c.filePath == f.path)) {
            captures.add(
              ScreenshotCapture(
                label: 'appstore_${p.basenameWithoutExtension(f.path)}',
                filePath: f.path,
                width: 0,
                height: 0,
                captured: true,
              ),
            );
          }
        }
      }

      AppLogger.i('[ScreenshotCapturer] ✅ Capturas Flutter generadas: ${captures.length}');
      return ScreenshotCaptureResult(
        captures: captures,
        total: captures.length,
        captured: captures.length,
      );
    } catch (e) {
      AppLogger.i('[ScreenshotCapturer] ❌ Error ejecutando captura Flutter: $e');
      return const ScreenshotCaptureResult(captures: [], total: 0, captured: 0);
    }
  }

  /// Verifica si hay un navegador headless disponible.
  static bool get isAvailable => _findChrome() != null;

  /// Captura screenshots del mockup HTML generado por MarketingAgent.
  static Future<ScreenshotCaptureResult> captureFromMockup({
    required String projectPath,
    String? mockupPath,
  }) async {
    final chrome = _findChrome();
    final htmlPath =
        mockupPath ?? p.join(projectPath, 'erbolamm-studio', 'source', 'mockup.html');

    if (!File(htmlPath).existsSync()) {
      return const ScreenshotCaptureResult(captures: [], total: 0, captured: 0);
    }

    final outDir = p.join(projectPath, 'erbolamm-studio', 'screenshots');
    Directory(outDir).createSync(recursive: true);

    final captures = <ScreenshotCapture>[];

    // Definir tamaños a capturar
    final sizes = [
      ('desktop', 1440, 900),
      ('tablet', 768, 1024),
      ('mobile', 390, 844),
    ];

    for (final (label, w, h) in sizes) {
      final outPath = p.join(outDir, '$label.png');

      if (chrome != null) {
        final success = await _captureWithChrome(
          chrome: chrome,
          url: 'file://$htmlPath',
          outputPath: outPath,
          width: w,
          height: h,
        );

        captures.add(
          ScreenshotCapture(
            label: label,
            filePath: outPath,
            width: w,
            height: h,
            captured: success,
            error: success ? null : 'Chrome capture failed',
          ),
        );
      } else {
        // Sin Chrome: marcar como pendiente
        captures.add(
          ScreenshotCapture(
            label: label,
            filePath: outPath,
            width: w,
            height: h,
            captured: false,
            error:
                'Chrome no encontrado. Instalá Chrome o ejecutá el script Playwright generado.',
          ),
        );
      }
    }

    // Si Chrome no está disponible, generar script Playwright
    if (chrome == null) {
      _generatePlaywrightScript(projectPath, htmlPath, sizes);
    }

    final captured = captures.where((c) => c.captured).length;
    return ScreenshotCaptureResult(
      captures: captures,
      total: captures.length,
      captured: captured,
    );
  }

  /// Captura una URL o archivo HTML con Chrome headless.
  static Future<bool> _captureWithChrome({
    required String chrome,
    required String url,
    required String outputPath,
    required int width,
    required int height,
  }) async {
    try {
      final result = await Process.run(chrome, [
        '--headless',
        '--disable-gpu',
        '--no-sandbox',
        '--disable-dev-shm-usage',
        '--screenshot=$outputPath',
        '--window-size=$width,$height',
        '--hide-scrollbars',
        '--virtual-time-budget=5000',
        url,
      ], runInShell: true);

      if (result.exitCode == 0 && File(outputPath).existsSync()) {
        final size = File(outputPath).lengthSync();
        AppLogger.i(
          '[ScreenshotCapturer] ✅ ${p.basename(outputPath)} '
          '($width×$height, ${(size / 1024).toStringAsFixed(0)}KB)',
        );
        return true;
      }

      AppLogger.i(
        '[ScreenshotCapturer] ❌ Chrome exit=${result.exitCode} '
        'stderr=${result.stderr}',
      );
      return false;
    } catch (e) {
      AppLogger.i('[ScreenshotCapturer] Error: $e');
      return false;
    }
  }

  /// Genera un script Playwright como fallback.
  static void _generatePlaywrightScript(
    String projectPath,
    String htmlPath,
    List<(String, int, int)> sizes,
  ) {
    final scriptPath = p.join(
      projectPath,
      'erbolamm-studio',
      'source',
      'capture-screenshots.cjs',
    );

    final sizeConfigs = sizes
        .map((s) => "  { label: '${s.$1}', width: ${s.$2}, height: ${s.$3} }")
        .join(',\n');

    final script =
        '''// capture-screenshots.cjs
// Generado por ErBolamm Studio · ScreenshotCapturer
// Ejecutar: node capture-screenshots.cjs
// Requiere: npm install playwright

const { chromium } = require('playwright');
const { join } = require('path');

const URL = 'file://$htmlPath';
const OUT = join(__dirname, '..', 'screenshots');
const SIZES = [
$sizeConfigs
];

async function main() {
  const browser = await chromium.launch({ headless: true });

  for (const size of SIZES) {
    const page = await (await browser.newContext({
      viewport: { width: size.width, height: size.height },
      deviceScaleFactor: 2,
    })).newPage();

    await page.goto(URL, { waitUntil: 'networkidle', timeout: 20000 });
    await page.waitForTimeout(2000);
    await page.screenshot({
      path: join(OUT, `\${size.label}.png`),
      fullPage: false,
    });
    console.log(`  ✅ \${size.label} (\${size.width}×\${size.height})`);
  }

  await browser.close();
  console.log('\\n✅ Todas las capturas generadas en erbolamm-studio/screenshots/');
}

main().catch(console.error);
''';

    File(scriptPath).writeAsStringSync(script);
    AppLogger.i('[ScreenshotCapturer] Script Playwright generado: $scriptPath');
  }
}
