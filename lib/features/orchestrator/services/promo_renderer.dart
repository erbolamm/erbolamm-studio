import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import '../../../core/logging/app_logger.dart';

// ═══════════════════════════════════════════════════════════════
// 🎬 PromoRenderer — Renderiza audio y video final
// ═══════════════════════════════════════════════════════════════
// Convierte las fuentes generadas por MarketingAgent en archivos
// finales: audio WAV desde generate-audio.html (Tone.js) y
// video MP4 desde screenshots + audio (ffmpeg slideshow).
// ═══════════════════════════════════════════════════════════════

/// Posibles paths de Chrome.
const _chromePaths = [
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/Applications/Chromium.app/Contents/MacOS/Chromium',
  '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',
  '/usr/bin/google-chrome',
];

String? _findChrome() {
  for (final path in _chromePaths) {
    if (File(path).existsSync()) return path;
  }
  return null;
}

/// Resultado de renderizado de audio.
class AudioRenderResult {
  final String filePath;
  final int fileSize;
  final int durationSeconds;
  final bool success;
  final String? error;

  const AudioRenderResult({
    required this.filePath,
    required this.fileSize,
    required this.durationSeconds,
    required this.success,
    this.error,
  });
}

/// Resultado de renderizado de video.
class VideoRenderResult {
  final String filePath;
  final int fileSize;
  final int durationSeconds;
  final int width;
  final int height;
  final bool success;
  final String? error;

  const VideoRenderResult({
    required this.filePath,
    required this.fileSize,
    required this.durationSeconds,
    required this.width,
    required this.height,
    required this.success,
    this.error,
  });
}

class PromoRenderer {
  /// Renderiza audio WAV desde generate-audio.html usando Chrome headless.
  ///
  /// El HTML contiene código Tone.js que genera audio proceduralmente.
  /// Chrome lo ejecuta y devuelve el WAV como base64 por consola.
  static Future<AudioRenderResult> renderAudio({
    required String projectPath,
    int durationSeconds = 22,
  }) async {
    final chrome = _findChrome();
    if (chrome == null) {
      return AudioRenderResult(
        filePath: '',
        fileSize: 0,
        durationSeconds: 0,
        success: false,
        error: 'Chrome no encontrado para renderizar audio Tone.js',
      );
    }

    final htmlPath = p.join(
      projectPath,
      'erbolamm-studio',
      'source',
      'generate-audio.html',
    );
    if (!File(htmlPath).existsSync()) {
      return AudioRenderResult(
        filePath: '',
        fileSize: 0,
        durationSeconds: 0,
        success: false,
        error: 'generate-audio.html no encontrado',
      );
    }

    final outDir = p.join(projectPath, 'erbolamm-studio', 'audio');
    Directory(outDir).createSync(recursive: true);
    final outPath = p.join(outDir, 'background.wav');

    try {
      // Usar Chrome para ejecutar el JS de Tone.js y capturar la salida
      final jsExtractor = p.join(outDir, '_extract_audio.js');
      File(jsExtractor).writeAsStringSync('''
const page = require('playwright').chromium;
// Intenta con Playwright si está instalado
(async () => {
  const browser = await page.launch({ headless: true });
  const ctx = await browser.newPage();
  let audioData = null;
  ctx.on('console', msg => {
    const text = msg.text();
    if (text.startsWith('AUDIO_DATA:')) {
      audioData = text.replace('AUDIO_DATA:', '');
    }
  });
  await ctx.goto('file://$htmlPath?duration=$durationSeconds', { waitUntil: 'load', timeout: 30000 });
  await ctx.waitForFunction(() => document.title === 'AUDIO_READY', { timeout: 120000 });
  if (audioData) {
    require('fs').writeFileSync('$outPath', Buffer.from(audioData, 'base64'));
    console.log('AUDIO_OK:' + require('fs').statSync('$outPath').size);
  }
  await browser.close();
})().catch(e => { console.error('AUDIO_ERR:' + e.message); process.exit(1); });
''');

      // Intentar con Playwright
      final prResult = await Process.run('node', [
        jsExtractor,
      ], runInShell: true).timeout(const Duration(minutes: 2));

      if (prResult.exitCode == 0 && File(outPath).existsSync()) {
        final size = File(outPath).lengthSync();
        AppLogger.i(
          '[PromoRenderer] ✅ Audio WAV renderizado: ${(size / 1024).toStringAsFixed(0)}KB',
        );
        return AudioRenderResult(
          filePath: outPath,
          fileSize: size,
          durationSeconds: durationSeconds,
          success: true,
        );
      }

      // Fallback: intentar con Chrome headless directamente
      // (menos fiable, solo funciona si el JS escribe a un archivo)
      File(jsExtractor).deleteSync();
      final result = await Process.run(chrome, [
        '--headless',
        '--disable-gpu',
        '--no-sandbox',
        '--virtual-time-budget=30000',
        '--dump-dom',
        'file://$htmlPath?duration=$durationSeconds',
      ], runInShell: true).timeout(const Duration(minutes: 2));

      // Buscar AUDIO_DATA en la salida del DOM
      final output = result.stdout as String;
      final match = RegExp(r'AUDIO_DATA:([A-Za-z0-9+/=]+)').firstMatch(output);
      if (match != null) {
        final bytes = base64Decode(match.group(1)!);
        File(outPath).writeAsBytesSync(bytes);
        final size = bytes.length;
        AppLogger.i(
          '[PromoRenderer] ✅ Audio WAV via Chrome: ${(size / 1024).toStringAsFixed(0)}KB',
        );
        return AudioRenderResult(
          filePath: outPath,
          fileSize: size,
          durationSeconds: durationSeconds,
          success: true,
        );
      }

      return AudioRenderResult(
        filePath: '',
        fileSize: 0,
        durationSeconds: 0,
        success: false,
        error: 'No se pudo extraer AUDIO_DATA de generate-audio.html',
      );
    } catch (e) {
      return AudioRenderResult(
        filePath: '',
        fileSize: 0,
        durationSeconds: 0,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Genera un video slideshow a partir de screenshots + audio.
  ///
  /// Usa ffmpeg para crear un video con las imágenes como secuencia
  /// y el audio de fondo. Ideal cuando no hay video real pero sí
  /// screenshots capturadas.
  static Future<VideoRenderResult> renderSlideshow({
    required String projectPath,
    String? audioPath,
    int durationSeconds = 22,
    int width = 1920,
    int height = 1080,
  }) async {
    // Verificar ffmpeg
    final ffmpegCheck = await Process.run('which', ['ffmpeg']);
    if (ffmpegCheck.exitCode != 0) {
      return VideoRenderResult(
        filePath: '',
        fileSize: 0,
        durationSeconds: 0,
        width: width,
        height: height,
        success: false,
        error: 'ffmpeg no encontrado',
      );
    }

    // Buscar screenshots
    final screenshotsDir = p.join(projectPath, 'erbolamm-studio', 'screenshots');
    final screenshots = <File>[];
    if (Directory(screenshotsDir).existsSync()) {
      for (final entity in Directory(screenshotsDir).listSync(recursive: true)) {
        if (entity is File &&
            (entity.path.endsWith('.png') || entity.path.endsWith('.jpg'))) {
          screenshots.add(entity);
        }
      }
    }

    if (screenshots.isEmpty) {
      return VideoRenderResult(
        filePath: '',
        fileSize: 0,
        durationSeconds: 0,
        width: width,
        height: height,
        success: false,
        error: 'Sin screenshots para generar slideshow',
      );
    }

    // Buscar audio
    String? audio;
    if (audioPath != null && File(audioPath).existsSync()) {
      audio = audioPath;
    } else {
      final audioDir = p.join(projectPath, 'erbolamm-studio', 'audio');
      final bgPath = p.join(audioDir, 'background.wav');
      if (File(bgPath).existsSync()) audio = bgPath;
    }

    final outDir = p.join(projectPath, 'erbolamm-studio', 'videos');
    Directory(outDir).createSync(recursive: true);
    final outPath = p.join(outDir, 'promo-horizontal.mp4');

    // Crear archivo de lista para ffmpeg concat
    final listPath = p.join(outDir, '_slideshow_list.txt');
    // Calcular duración por imagen
    final perImage = screenshots.isNotEmpty
        ? durationSeconds / screenshots.length
        : 3.0;

    final listLines = screenshots
        .map((f) => "file '${f.absolute.path}'\nduration $perImage")
        .join('\n');
    File(
      listPath,
    ).writeAsStringSync('$listLines\nfile \'${screenshots.last.absolute.path}\'');

    try {
      final args = [
        '-f',
        'concat',
        '-safe',
        '0',
        '-i',
        listPath,
        '-vf',
        'scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2,fps=30',
        '-c:v',
        'libx264',
        '-preset',
        'fast',
        '-pix_fmt',
        'yuv420p',
      ];

      if (audio != null) {
        args.addAll(['-i', audio, '-c:a', 'aac', '-shortest']);
      }

      args.addAll(['-y', outPath]);

      final result = await Process.run(
        'ffmpeg',
        args,
        runInShell: true,
      ).timeout(const Duration(minutes: 3));

      // Limpiar
      File(listPath).deleteSync();

      if (result.exitCode == 0 && File(outPath).existsSync()) {
        final size = File(outPath).lengthSync();
        AppLogger.i(
          '[PromoRenderer] ✅ Video slideshow: '
          '${(size / 1024 / 1024).toStringAsFixed(1)}MB',
        );
        return VideoRenderResult(
          filePath: outPath,
          fileSize: size,
          durationSeconds: durationSeconds,
          width: width,
          height: height,
          success: true,
        );
      }

      AppLogger.e('[PromoRenderer] ❌ ffmpeg falló (exit=${result.exitCode}): ${result.stderr}');
      return VideoRenderResult(
        filePath: '',
        fileSize: 0,
        durationSeconds: 0,
        width: width,
        height: height,
        success: false,
        error: 'ffmpeg falló con exit=${result.exitCode}: ${result.stderr}',
      );
    } catch (e) {
      return VideoRenderResult(
        filePath: '',
        fileSize: 0,
        durationSeconds: 0,
        width: width,
        height: height,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Renderiza video vertical y horizontal.
  static Future<List<VideoRenderResult>> renderAll({
    required String projectPath,
    String? audioPath,
  }) async {
    final results = <VideoRenderResult>[];

    // Vertical (TikTok/Reels)
    results.add(
      await renderSlideshow(
        projectPath: projectPath,
        audioPath: audioPath,
        width: 1080,
        height: 1920,
        durationSeconds: 22,
      ),
    );

    // Horizontal (YouTube)
    results.add(
      await renderSlideshow(
        projectPath: projectPath,
        audioPath: audioPath,
        width: 1920,
        height: 1080,
        durationSeconds: 30,
      ),
    );

    return results;
  }
}
