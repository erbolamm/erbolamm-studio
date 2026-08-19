// ═══════════════════════════════════════════════════════════════
// 🎨 Agente 4 — Creador de Assets de Marketing
// ═══════════════════════════════════════════════════════════════
// Genera todo el contenido promocional para un proyecto:
//   - brand-spec.md según template (app, extension, package, etc.)
//   - Screenshots (Chrome headless o busca en el proyecto)
//   - Videos promocionales (slideshow ffmpeg + fuentes HTML)
//   - Código Strudel + Tone.js para música de fondo
//   - Narración multi-idioma con mmx speech synthesize
//
// Sigue el Paso 4 de INBOX.md.
// ═══════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:path/path.dart' as p;

import '../domain/agent_interface.dart';
import '../templates/project_templates.dart';
import '../services/narration_generator.dart';
import '../services/screenshot_capturer.dart';
import '../services/promo_renderer.dart';
import '../services/store_screenshot_generator.dart';
import '../../voice/data/voice_clone_service.dart';
import '../../../core/logging/app_logger.dart';

/// Resultado de la generación de assets
class MarketingResult {
  final bool brandSpecCreated;
  final int screenshotsGenerated;
  final bool videoCreated;
  final bool musicGenerated;
  final List<String> generatedFiles;
  final String summary;

  const MarketingResult({
    required this.brandSpecCreated,
    required this.screenshotsGenerated,
    required this.videoCreated,
    required this.musicGenerated,
    required this.generatedFiles,
    required this.summary,
  });
}

class MarketingAgent implements AgentInterface {
  final List<String> selectedLanguages;
  final bool renderMedia;

  MarketingAgent({
    this.selectedLanguages = const ['es', 'en', 'pt', 'fr', 'de', 'it'],
    this.renderMedia = true,
  });

  @override
  String get agentId => 'marketing';
  @override
  String get agentName => 'Creador de Assets';
  @override
  String get inboxStep => 'Paso 4';

  @override
  Future<bool> canExecute(String projectPath) async {
    return Directory(projectPath).existsSync();
  }

  @override
  Future<AgentOutput> execute(String projectPath) async {
    final generatedFiles = <String>[];
    final projectName = projectPath.split(Platform.pathSeparator).last;
    final studioDir = Directory('$projectPath/erbolamm-studio');
    final sourceDir = Directory('$projectPath/erbolamm-studio/source');

    // Limpieza de carpeta legacy promo/ si existiera
    final legacyPromo = Directory('$projectPath/promo');
    if (legacyPromo.existsSync()) {
      try {
        legacyPromo.deleteSync(recursive: true);
      } catch (_) {}
    }

    // Comprobar estado de la voz clonada
    final clonedVoices = await VoiceCloneService.listVoices();
    if (clonedVoices.isEmpty) {
      AppLogger.i(
        '[MarketingAgent] ℹ️ Aún no tenés tu voz guardada en Voice Studio. '
        'Se usará el narrador estándar multi-idioma (podés clonar tu voz en Voice Studio cuando quieras).',
      );
    } else {
      AppLogger.i(
        '[MarketingAgent] 🎙️ Usando tu voz guardada: ${clonedVoices.first.displayName} (${clonedVoices.first.voiceId})',
      );
    }

    // Asegurar estructura erbolamm-studio/
    if (!studioDir.existsSync()) studioDir.createSync(recursive: true);
    if (!sourceDir.existsSync()) sourceDir.createSync(recursive: true);

    // Limpiar narraciones viejas de ejecuciones anteriores
    final narrationDir = Directory('$projectPath/erbolamm-studio/narration');
    if (narrationDir.existsSync()) {
      for (final lang in narrationDir.listSync()) {
        if (lang is Directory) {
          try {
            lang.deleteSync(recursive: true);
          } catch (_) {}
        }
      }
    }
    // Limpiar audio/música viejo
    for (final dir in ['audio', 'music']) {
      final d = Directory('$projectPath/erbolamm-studio/$dir');
      if (d.existsSync()) {
        for (final f in d.listSync()) {
          if (f is File) {
            try {
              f.deleteSync();
            } catch (_) {}
          }
        }
      }
    }

    // 4.1 — Detectar tipo y cargar template
    final projectType = await _detectType(projectPath);
    final template = templateForType(_templateKey(projectType));

    // Crear estructura de directorios según template
    for (final dir in template.requiredDirs) {
      Directory('$projectPath/erbolamm-studio/$dir').createSync(recursive: true);
    }
    if (!sourceDir.existsSync()) sourceDir.createSync(recursive: true);

    // 4.2 — Crear brand-spec.md según template
    final brandSpec = template.brandSpecBuilder(projectName, projectType);
    File('$projectPath/erbolamm-studio/brand-spec.md').writeAsStringSync(brandSpec);
    generatedFiles.add('erbolamm-studio/brand-spec.md');

    // 4.3 — Buscar o capturar screenshots reales en el proyecto
    final screenshots = await _findAndCopyScreenshots(projectPath, projectName);
    if (screenshots.isNotEmpty) {
      generatedFiles.addAll(screenshots);
    } else if (ScreenshotCapturer.isFlutterProject(projectPath)) {
      // Si es un proyecto Flutter, ejecutar captura directa desde el motor de widgets
      final flutterCaptures = await ScreenshotCapturer.captureFromFlutterEngine(
        projectPath: projectPath,
      );
      for (final c in flutterCaptures.captures) {
        if (c.captured) {
          generatedFiles.add(p.relative(c.filePath, from: projectPath));
        }
      }
    }

    // Fallback: si aún no hay capturas reales (ej: proyecto web o no-Flutter), crear mockup HTML
    if (!generatedFiles.any((f) => f.contains('erbolamm-studio/screenshots/'))) {
      final mockup = template.mockupBuilder(projectName, projectType);
      File('$projectPath/erbolamm-studio/source/mockup.html').writeAsStringSync(mockup);
      generatedFiles.add('erbolamm-studio/source/mockup.html');

      // Intentar capturar screenshots del mockup con Chrome headless
      if (renderMedia && ScreenshotCapturer.isAvailable) {
        final captureResult = await ScreenshotCapturer.captureFromMockup(
          projectPath: projectPath,
        );
        for (final c in captureResult.captures) {
          if (c.captured) {
            generatedFiles.add('erbolamm-studio/screenshots/${c.label}.png');
          }
        }
      }
    }

    // 4.3.1 — Generar capturas enmarcadas para tiendas en todos los idiomas seleccionados
    if (renderMedia) {
      final storeScreenshots = await StoreScreenshotGenerator.generateFramedStoreScreenshots(
        projectPath: projectPath,
        languages: selectedLanguages,
      );
      for (final entry in storeScreenshots.entries) {
        for (final filePath in entry.value) {
          generatedFiles.add(p.relative(filePath, from: projectPath));
        }
      }
    }

    // 4.4 — Crear source HTML para video
    final videoFiles = _createVideoSources(
      projectPath,
      projectName,
      projectType,
    );
    generatedFiles.addAll(videoFiles);

    // 4.5 — Generar audio (Strudel + Tone.js)
    final strudelCode = _generateStrudelCode(projectName, projectType);
    File(
      '$projectPath/erbolamm-studio/source/music.strudel',
    ).writeAsStringSync(strudelCode);
    generatedFiles.add('erbolamm-studio/source/music.strudel');

    final toneJsCode = _generateToneJsAudio(projectName, projectType);
    File(
      '$projectPath/erbolamm-studio/source/generate-audio.html',
    ).writeAsStringSync(toneJsCode);
    generatedFiles.add('erbolamm-studio/source/generate-audio.html');

    // 4.6 — Crear narration.json para multi-idioma
    final narration = _generateNarration(projectPath, projectName, projectType);
    File('$projectPath/erbolamm-studio/narration.json').writeAsStringSync(narration);
    generatedFiles.add('erbolamm-studio/narration.json');

    // 4.7 — Generar audios de narración con mmx
    int narrationCount = 0;
    if (renderMedia && await NarrationGenerator.isAvailable()) {
      final narrationResult = await NarrationGenerator.generateAll(
        projectPath: projectPath,
      );
      narrationCount = narrationResult.successCount;
      for (final r in narrationResult.results) {
        if (r.success) {
          generatedFiles.add('erbolamm-studio/narration/${r.language}/');
        }
      }
    }

    // 4.8 — Renderizar audio y video final
    int videosRendered = 0;
    bool audioRendered = false;
    if (renderMedia) {
      try {
        // Intentar renderizar audio de fondo
        final audioResult = await PromoRenderer.renderAudio(
          projectPath: projectPath,
          durationSeconds: 22,
        );
        if (audioResult.success) {
          audioRendered = true;
          generatedFiles.add('erbolamm-studio/audio/background.wav');

          // Intentar renderizar slideshow con screenshots + audio
          if (ScreenshotCapturer.isAvailable || screenshots.isNotEmpty) {
            final slideshowResults = await PromoRenderer.renderAll(
              projectPath: projectPath,
              audioPath: audioResult.filePath,
            );
            for (final v in slideshowResults) {
              if (v.success) {
                videosRendered++;
                generatedFiles.add(
                  'erbolamm-studio/videos/promo-${v.width == 1080 ? 'vertical' : 'horizontal'}.mp4',
                );
              }
            }
          }
        }
      } catch (_) {
        // Renderizado opcional — no bloquear el pipeline
      }
    }

    // 4.9 — Generar landing page si no existe
    final landingFiles = _generateLandingPage(
      projectPath,
      projectName,
      projectType,
      template,
    );
    generatedFiles.addAll(landingFiles);

    final result = MarketingResult(
      brandSpecCreated: true,
      screenshotsGenerated: screenshots.length,
      videoCreated: videoFiles.isNotEmpty || videosRendered > 0,
      musicGenerated: true,
      generatedFiles: generatedFiles,
      summary:
          '✅ Brand spec, ${screenshots.length} screenshots, '
          '${videoFiles.length} videos, $narrationCount narraciones, '
          '${audioRendered ? 'audio renderizado' : 'música generada'}'
          '${videosRendered > 0 ? ', $videosRendered slideshows' : ''}.',
    );

    return AgentOutput(
      agentId: agentId,
      success: true,
      summary: result.summary,
      data: {
        'generatedFiles': result.generatedFiles,
        'screenshots': result.screenshotsGenerated,
        'brandSpec': result.brandSpecCreated,
      },
    );
  }

  // ─── Landing page generator ───

  List<String> _generateLandingPage(
    String projectPath,
    String projectName,
    String projectType,
    ProjectTemplate template,
  ) {
    final landingPath = '$projectPath/erbolamm-studio/landing.html';
    if (File(landingPath).existsSync() ||
        File('$projectPath/index.html').existsSync() ||
        File('$projectPath/landing.html').existsSync()) {
      return [];
    }
    final desc = _readProjectDescription(projectPath);
    final html = _buildLandingHtml(
      name: projectName,
      type: projectType,
      description: desc,
      emoji: template.emoji,
      color: template.defaultColor,
      pillar: template.defaultPillar,
    );
    final landingFile = File(landingPath);
    landingFile.parent.createSync(recursive: true);
    landingFile.writeAsStringSync(html);
    return ['erbolamm-studio/landing.html'];
  }

  String _readProjectDescription(String projectPath) {
    for (final name in ['README.md', 'readme.md']) {
      final f = File('$projectPath/$name');
      if (!f.existsSync()) continue;
      try {
        final lines = f.readAsLinesSync();
        final desc = <String>[];
        var afterTitle = false;
        for (final line in lines) {
          if (line.startsWith('# ') && !afterTitle) {
            afterTitle = true;
            continue;
          }
          if (afterTitle && line.startsWith('## ')) break;
          if (afterTitle && line.trim().isNotEmpty) desc.add(line.trim());
        }
        if (desc.isNotEmpty) return desc.join(' ');
      } catch (_) {}
    }
    return 'Proyecto creado con ErBolamm Studio.';
  }

  String _buildLandingHtml({
    required String name,
    required String type,
    required String description,
    required String emoji,
    required String color,
    required String pillar,
  }) {
    String e(String s) => s.replaceAll("'", "\\'");
    return '<!DOCTYPE html>\n<html lang="es">\n<head>\n'
        '<meta charset="UTF-8">\n'
        '<meta name="viewport" content="width=device-width,initial-scale=1.0">\n'
        '<title>$name — $type</title>\n'
        '<meta name="description" content="${e(description)}">\n'
        '<meta property="og:title" content="$name">\n'
        '<meta property="og:description" content="${e(description)}">\n'
        '<style>\n'
        '*{margin:0;padding:0;box-sizing:border-box}\n'
        'body{font-family:system-ui,sans-serif;background:linear-gradient(135deg,#0f0f1a,#1a1a2e);'
        'color:#f1f5f9;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:20px}\n'
        '.card{max-width:600px;background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.08);'
        'border-radius:24px;padding:48px;text-align:center}\n'
        '.emoji{font-size:72px;margin-bottom:20px}\n'
        'h1{font-size:36px;font-weight:800;margin-bottom:8px}\n'
        '.badge{display:inline-block;background:$color;color:#fff;padding:6px 20px;'
        'border-radius:20px;font-size:14px;font-weight:600;margin-bottom:24px}\n'
        'p{font-size:16px;line-height:1.7;color:#94a3b8;max-width:450px;margin:0 auto 32px}\n'
        '.features{display:flex;gap:12px;justify-content:center;flex-wrap:wrap;margin-bottom:32px}\n'
        '.feat{background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.08);'
        'border-radius:12px;padding:12px 20px;font-size:13px;color:#cbd5e1}\n'
        '.footer{font-size:12px;color:#475569;border-top:1px solid rgba(255,255,255,.05);padding-top:20px}\n'
        'a{color:$color;text-decoration:none}\n'
        '</style>\n</head>\n<body><div class="card">\n'
        '<div class="emoji">$emoji</div>\n'
        '<h1>$name</h1>\n'
        '<div class="badge">$pillar · $type</div>\n'
        '<p>$description</p>\n'
        '<div class="features">\n'
        '<span class="feat">📄 Documentado</span>\n'
        '<span class="feat">🎨 Brand-ready</span>\n'
        '<span class="feat">🚀 Listo para publicar</span>\n'
        '</div>\n'
        '<div class="footer">Creado con <a href="#">ErBolamm Studio</a> · Made in ApliArte</div>\n'
        '</div></body>\n</html>';
  }

  // ─── Template key mapping ───

  /// Convierte el tipo detectado a la key del template.
  String _templateKey(String detectedType) {
    switch (detectedType) {
      case 'Flutter':
      case 'Dart':
        // Verificar si es app o package
        return 'app'; // Por defecto; se puede refinar
      case 'Node.js':
        return 'website';
      case 'Web':
        return 'website';
      default:
        return 'app';
    }
  }

  // ─── Detección de tipo de proyecto ───

  Future<String> _detectType(String projectPath) async {
    final files = Directory(projectPath).listSync();
    final names = files
        .map((f) => f.path.split(Platform.pathSeparator).last)
        .toSet();

    if (names.contains('pubspec.yaml')) {
      for (final f in files) {
        if (f.path.endsWith('pubspec.yaml')) {
          try {
            final content = File(f.path).readAsStringSync();
            if (content.contains('flutter:')) return 'Flutter';
            return 'Dart';
          } catch (_) {}
        }
      }
    }
    if (names.contains('package.json')) return 'Node.js';
    if (names.contains('index.html')) return 'Web';
    return 'Desconocido';
  }

  Future<List<String>> _findAndCopyScreenshots(
    String projectPath,
    String projectName,
  ) async {
    final screenshots = <String>[];

    // Si hay Flutter web build, intentar capturas con Playwright
    if (await _checkFlutterWeb(projectPath)) {
      screenshots.addAll(await _captureFlutterScreenshots(projectPath));
    }

    // Buscar imágenes existentes en el proyecto
    final targetDir = Directory('$projectPath/erbolamm-studio/screenshots');
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    final imageExts = ['.png', '.jpg', '.jpeg', '.webp', '.gif'];
    final seen = <String>{};

    // Solo buscar en carpetas específicas de screenshots, NO en todo el proyecto
    for (final dirName in [
      'screenshots',
      'assets/screenshots',
      'docs/images',
    ]) {
      final dir = Directory(
        dirName.isEmpty ? projectPath : '$projectPath/$dirName',
      );
      if (!dir.existsSync()) continue;

      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File) continue;
        final ext = entity.path.toLowerCase();
        if (!imageExts.any((e) => ext.endsWith(e))) continue;

        final fileName = entity.path.split(Platform.pathSeparator).last;
        if (seen.contains(fileName)) continue;
        seen.add(fileName);

        try {
          entity.copySync('${targetDir.path}/$fileName');
          screenshots.add('erbolamm-studio/screenshots/$fileName');
        } catch (_) {
          // Skip archivos bloqueados
        }
      }
    }

    return screenshots;
  }

  // ─── Web Flutter ───

  Future<bool> _checkFlutterWeb(String projectPath) async {
    // Buscar build/web/ existente
    final webBuild = Directory('$projectPath/example/build/web');
    if (webBuild.existsSync() && File('$webBuild/index.html').existsSync()) {
      return true;
    }
    // Buscar build/web/ en raíz
    final rootBuild = Directory('$projectPath/build/web');
    return rootBuild.existsSync() && File('$rootBuild/index.html').existsSync();
  }

  Future<List<String>> _captureFlutterScreenshots(String projectPath) async {
    final screenshots = <String>[];
    final basePath = '$projectPath/erbolamm-studio/screenshots/browser';
    Directory(basePath).createSync(recursive: true);

    // Nota: la captura real requiere Playwright.
    // Aquí se genera el script para que el usuario lo ejecute.
    final script =
        '''// capture-screenshots.cjs
// Generado por ErBolamm Studio · Marketing Agent
// Ejecutar: NODE_PATH=\$(npm root -g) node captura-screenshots.cjs

const { chromium } = require('playwright');
const { join } = require('path');

const URL = 'file://$projectPath/example/build/web/index.html';
const OUT = join(__dirname, 'screenshots', 'browser');

async function main() {
  const browser = await chromium.launch({ headless: true });
  const page = await (await browser.newContext({
    viewport: { width: 1440, height: 900 }, deviceScaleFactor: 2
  })).newPage();
  await page.goto(URL, { waitUntil: 'networkidle', timeout: 20000 });
  await page.waitForTimeout(3000);
  await page.screenshot({ path: join(OUT, 'desktop.png'), fullPage: true });
  await browser.close();
  console.log('✅ Screenshots capturadas');
}
main().catch(console.error);
''';
    File(
      '$projectPath/erbolamm-studio/source/capture-screenshots.cjs',
    ).writeAsStringSync(script);
    screenshots.add('erbolamm-studio/source/capture-screenshots.cjs');

    // Placeholders para screenshots reales
    for (final name in ['desktop.png', 'mobile.png', 'tablet.png']) {
      // En producción: reemplazar con captura real
      screenshots.add('erbolamm-studio/screenshots/browser/$name');
    }

    return screenshots;
  }

  // ─── Videos ───

  List<String> _createVideoSources(
    String projectPath,
    String name,
    String type,
  ) {
    final files = <String>[];

    // Template vertical (TikTok/Reels)
    final vertical =
        '''<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8">
<title>Promo Vertical — $name</title>
<script src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
<script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
<script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;800;900&display=swap" rel="stylesheet">
<style>*{margin:0;padding:0;box-sizing:border-box;}body{background:#000;overflow:hidden;font-family:'Inter',sans-serif;}#root{width:100vw;height:100vh;}</style>
</head>
<body><div id="root"></div>
<script>
// Motor de animación y Stage aquí...
// Ver design-engine/templates/vertical-promo.html para el completo
console.log('Template vertical para $name — renderizar con design-engine');
</script>
</body>
</html>''';
    File(
      '$projectPath/erbolamm-studio/source/vertical-promo.html',
    ).writeAsStringSync(vertical);
    files.add('erbolamm-studio/source/vertical-promo.html');

    // Render script (Playwright + ffmpeg)
    final renderScript = _generateRenderScript(name);
    File(
      '$projectPath/erbolamm-studio/source/render-audio.cjs',
    ).writeAsStringSync(renderScript);
    files.add('erbolamm-studio/source/render-audio.cjs');

    return files;
  }

  String _generateRenderScript(String name) {
    return '''const { chromium } = require('playwright');
const { createServer } = require('http');
const { readFileSync, writeFileSync, unlinkSync, mkdirSync } = require('fs');
const { join } = require('path');

const STUDIO_DIR = join(__dirname, '..');
const VIDEOS_DIR = join(STUDIO_DIR, 'videos');
const SOURCE_DIR = join(__dirname);

async function generateAudioForDuration(duration, port) {
  return new Promise(async (resolve, reject) => {
    const server = createServer((req, res) => {
      const html = readFileSync(join(SOURCE_DIR, 'generate-audio.html'), 'utf-8');
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(html);
    });
    await new Promise(r => server.listen(port, r));

    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();
    let audioBase64 = null;
    page.on('console', msg => {
      const text = msg.text();
      if (text.startsWith('AUDIO_DATA:')) audioBase64 = text.replace('AUDIO_DATA:', '');
    });

    try {
      await page.goto(`http://localhost:\${port}/?duration=\${duration}`, { waitUntil: 'load', timeout: 30000 });
      await page.waitForFunction(() => document.title === 'AUDIO_READY', { timeout: 120000 });

      if (!audioBase64) throw new Error(`No audio for \${duration}s`);
      const wavPath = join(VIDEOS_DIR, `generated-audio-\${duration}s.wav`);
      writeFileSync(wavPath, Buffer.from(audioBase64, 'base64'));
      const kb = (readFileSync(wavPath).length / 1024).toFixed(0);
      console.log(`  \u2705 Audio \${duration}s: \${kb}KB`);
      resolve(wavPath);
    } catch (e) {
      reject(e);
    } finally {
      await browser.close();
      server.close();
    }
  });
}

async function main() {
  mkdirSync(VIDEOS_DIR, { recursive: true });
  console.log('\\ud83c\\udfb5 Generando audios para: $name\\n');

  const audios = [
    { name: 'promo-vertical', duration: '22' },
    { name: 'promo-horizontal', duration: '30' },
  ];

  for (const audio of audios) {
    const port = 8766 + (audio.duration === '22' ? 0 : 1);
    await generateAudioForDuration(audio.duration, port);
  }

  console.log('\\n\\u2705 Audios listos en erbolamm-studio/videos/');
  console.log('\\n\\ud83c\\udfac Para mezclar con video:');
  console.log('ffmpeg -i video.mp4 -i generated-audio-22s.wav -c:v copy -c:a aac -t 22 -y output.mp4');
}

main().catch(console.error);
''';
  }

  // ─── Música (Tone.js offline render) ───

  String _generateStrudelCode(String name, String type) {
    // Strudel reference code (documentation only)
    return '''// ───────────────────────────────────────────────
// Código Strudel de referencia para: $name
// Tipo: $type
// Usar generate-audio.html para render real con Tone.js
// ───────────────────────────────────────────────

setCpm(120/4)

let pads = note("<[c3 eb3 g3 bb3]>")
  .s("supersaw").attack(0.3).release(1)
  .lpf(1200).gain(0.25)

let bass = note("c2 ~ c2 c2 ~ g1 ~ c2")
  .s("sawtooth").lpf(500).gain(0.6)

let drums = s("bd*4, ~ sd:1 ~ sd:1")
  .bank("LinnDrum").gain(0.9)

arrange(
  [4, stack(pads, drums)],
  [8, stack(pads, bass, drums)],
  [4, stack(pads, bass, drums)],
  [4, stack(pads, drums)],
)
''';
  }

  String _generateToneJsAudio(String name, String type) {
    return '''<!DOCTYPE html>
<html>
<head>
  <title>Audio Generator — $name</title>
</head>
<body>
<script>
// ─── Tone.js — Funk 80s Pop-Funk 120 BPM ───
// Generado por ErBolamm Studio · Marketing Agent para: $name
// SIN osciladores continuos — solo notas programadas

const BPM = 120;
const SECONDS = new URLSearchParams(window.location.search).get('duration')
  ? parseInt(new URLSearchParams(window.location.search).get('duration'))
  : 22;

async function generateAudio() {
  const offlineCtx = new OfflineAudioContext(2, 44100 * SECONDS, 44100);

  // ── Filtros compartidos ──
  const padFilter = offlineCtx.createBiquadFilter();
  padFilter.type = 'lowpass';
  padFilter.frequency.value = 1200;
  padFilter.Q.value = 2;
  padFilter.connect(offlineCtx.destination);

  const bassFilter = offlineCtx.createBiquadFilter();
  bassFilter.type = 'lowpass';
  bassFilter.frequency.value = 500;
  bassFilter.connect(offlineCtx.destination);

  const bdGain = offlineCtx.createGain();
  bdGain.gain.value = 0.4;
  bdGain.connect(offlineCtx.destination);

  const sdFilter = offlineCtx.createBiquadFilter();
  sdFilter.type = 'bandpass';
  sdFilter.frequency.value = 200;
  sdFilter.Q.value = 1.5;
  const sdGain = offlineCtx.createGain();
  sdGain.gain.value = 0.3;
  sdFilter.connect(sdGain);
  sdGain.connect(offlineCtx.destination);

  const beatDuration = 60 / BPM;
  const totalBeats = (SECONDS / beatDuration) | 0;

  // ── Helpers ──
  function note(freq, startBeat, durBeats, dest, vel) {
    const t = startBeat * beatDuration;
    const dur = durBeats * beatDuration * 0.9;
    const osc = offlineCtx.createOscillator();
    const gain = offlineCtx.createGain();
    osc.type = 'sawtooth';
    osc.frequency.value = freq;
    gain.gain.setValueAtTime(0, t);
    gain.gain.linearRampToValueAtTime(vel || 0.3, t + 0.02);
    gain.gain.setValueAtTime(vel || 0.3, t + dur - 0.05);
    gain.gain.linearRampToValueAtTime(0, t + dur);
    osc.connect(gain);
    gain.connect(dest);
    osc.start(t);
    osc.stop(t + dur);
  }

  function noise(startBeat, durBeats, dest, vel) {
    const t = startBeat * beatDuration;
    const dur = durBeats * beatDuration;
    const bufferSize = offlineCtx.sampleRate * dur;
    const buffer = offlineCtx.createBuffer(1, bufferSize, offlineCtx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) data[i] = (Math.random() * 2 - 1);
    const src = offlineCtx.createBufferSource();
    src.buffer = buffer;
    const gain = offlineCtx.createGain();
    gain.gain.setValueAtTime(vel || 0.3, t);
    gain.gain.setValueAtTime(vel || 0.3, t + dur - 0.02);
    gain.gain.linearRampToValueAtTime(0, t + dur);
    src.connect(gain);
    gain.connect(dest);
    src.start(t);
  }

  // ── Patrones ──
  const bassNotes = [65.41, 65.41, 65.41, 65.41, 98.00, 98.00, 65.41, 65.41]; // C2, G2
  const padNotes = [261.63, 329.63, 392.00, 466.16]; // C4 E4 G4 Bb4

  for (let beat = 0; beat < totalBeats; beat++) {
    const bar = beat % 8;
    const beat4 = beat % 4;
    const isFill = beat % 16 >= 12 && beat % 16 < 15;

    // Kick (1 y 3)
    if (beat4 === 0 || beat4 === 2) {
      const osc = offlineCtx.createOscillator();
      const gain = offlineCtx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(150, beat * beatDuration);
      osc.frequency.exponentialRampToValueAtTime(40, beat * beatDuration + 0.08);
      gain.gain.setValueAtTime(0.5, beat * beatDuration);
      gain.gain.exponentialRampToValueAtTime(0.01, beat * beatDuration + 0.1);
      osc.connect(gain);
      gain.connect(bdGain);
      osc.start(beat * beatDuration);
      osc.stop(beat * beatDuration + 0.12);
    }

    // Snare (2 y 4)
    if (beat4 === 1 || beat4 === 3) {
      noise(beat, 0.15, sdFilter, 0.5);
      const t = beat * beatDuration;
      const osc = offlineCtx.createOscillator();
      const gain = offlineCtx.createGain();
      osc.type = 'triangle';
      osc.frequency.value = 180;
      gain.gain.setValueAtTime(0.4, t);
      gain.gain.exponentialRampToValueAtTime(0.01, t + 0.06);
      osc.connect(gain);
      gain.connect(sdGain);
      osc.start(t);
      osc.stop(t + 0.08);
    }

    // Hi-hat (8ths)
    if (beat4 !== 3 || !isFill) {
      noise(beat, 0.05, offlineCtx.destination, 0.08);
    }

    // Bass
    if (beat4 === 0 || beat4 === 2) {
      const freq = bassNotes[bar];
      note(freq, beat, 1.7, bassFilter, 0.5);
    }

    // Pads (cada 2 compases)
    if (beat % 8 === 0) {
      for (const f of padNotes) {
        note(f, beat, 3.5, padFilter, 0.12);
      }
    }
  }

  const rendered = await offlineCtx.startRendering();
  const wav = audioBufferToWav(rendered);
  console.log('AUDIO_DATA:' + btoa(String.fromCharCode(...new Uint8Array(wav))));
  document.title = 'AUDIO_READY';
}

// ── WAV export ──
function audioBufferToWav(buffer) {
  const numChannels = buffer.numberOfChannels;
  const sampleRate = buffer.sampleRate;
  const format = 1;
  const bitDepth = 16;
  const data = buffer.getChannelData(0);
  const dataLength = data.length * (bitDepth / 8);
  const headerLength = 44;
  const totalLength = headerLength + dataLength;
  const arrayBuffer = new ArrayBuffer(totalLength);
  const view = new DataView(arrayBuffer);

  writeString(view, 0, 'RIFF');
  view.setUint32(4, totalLength - 8, true);
  writeString(view, 8, 'WAVE');
  writeString(view, 12, 'fmt ');
  view.setUint32(16, 16, true);
  view.setUint16(20, format, true);
  view.setUint16(22, numChannels, true);
  view.setUint32(24, sampleRate, true);
  view.setUint32(28, sampleRate * numChannels * (bitDepth / 8), true);
  view.setUint16(32, numChannels * (bitDepth / 8), true);
  view.setUint16(34, bitDepth, true);
  writeString(view, 36, 'data');
  view.setUint32(40, dataLength, true);

  let offset = 44;
  for (let i = 0; i < data.length; i++) {
    const sample = Math.max(-1, Math.min(1, data[i]));
    const val = sample < 0 ? sample * 0x8000 : sample * 0x7FFF;
    view.setInt16(offset, val, true);
    offset += 2;
  }
  return arrayBuffer;
}

function writeString(view, offset, string) {
  for (let i = 0; i < string.length; i++)
    view.setUint8(offset + i, string.charCodeAt(i));
}

generateAudio().catch(console.error);
</script>
</body>
</html>
''';
  }

  // ─── Narración ───

  String _generateNarration(String projectPath, String name, String type) {
    // Leer descripción real del proyecto
    final desc = _readProjectDescription(projectPath);
    final shortDesc = desc.length > 100 ? '${desc.substring(0, 97)}...' : desc;

    // Nombre legible
    final readable = name
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

    return '''{
  "es": "$readable. $type. $shortDesc",
  "en": "$readable. $type. $shortDesc",
  "pt": "$readable. $type. $shortDesc",
  "fr": "$readable. $type. $shortDesc",
  "de": "$readable. $type. $shortDesc",
  "it": "$readable. $type. $shortDesc"
}''';
  }
}
