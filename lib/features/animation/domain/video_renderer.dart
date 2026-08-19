// ═══════════════════════════════════════════════════════════════
// 🎬 Video Renderer — Renderiza HTML a MP4 via Playwright
// ═══════════════════════════════════════════════════════════════
// Usa design-engine/scripts/render-video.cjs para convertir
// animaciones HTML a video MP4 con Playwright + ffmpeg.
//
// Requiere: Node.js, playwright, ffmpeg
// ═══════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:path/path.dart' as p;

import 'animation_template.dart';

class VideoRenderer {
  String? _lastError;
  bool _scriptsFound = false;
  String? _designEnginePath;

  String? get lastError => _lastError;

  /// Busca el design-engine en el proyecto
  Future<bool> findDesignEngine({String? projectBase}) async {
    final base = projectBase ?? Directory.current.path;
    final candidates = [
      p.join(base, 'design-engine'),                        // desde erbolamm-studio/
      p.join(base, '..', 'design-engine'),                   // desde lib/
    ];

    for (final dir in candidates) {
      final renderScript = p.join(dir, 'scripts', 'render-video.cjs');
      if (await File(renderScript).exists()) {
        _designEnginePath = dir;
        _scriptsFound = true;
        return true;
      }
    }
    _lastError = 'design-engine/scripts/render-video.cjs no encontrado';
    return false;
  }

  /// Resuelve NODE_PATH dando prioridad a pnpm, luego npm y variables de entorno
  Future<String?> _resolveNodePath() async {
    try {
      final pnpm = await Process.run('pnpm', ['root', '-g']);
      if (pnpm.exitCode == 0 && (pnpm.stdout as String).trim().isNotEmpty) {
        return (pnpm.stdout as String).trim();
      }
    } catch (_) {}

    try {
      final npm = await Process.run('npm', ['root', '-g']);
      if (npm.exitCode == 0 && (npm.stdout as String).trim().isNotEmpty) {
        return (npm.stdout as String).trim();
      }
    } catch (_) {}

    return Platform.environment['NODE_PATH'];
  }

  /// Verifica que Node.js y playwright estén disponibles
  Future<bool> checkAvailable() async {
    try {
      final node = await Process.run('node', ['--version']);
      if (node.exitCode != 0) {
        _lastError = 'Node.js no encontrado';
        return false;
      }
      final nodePath = await _resolveNodePath();
      final env = nodePath != null ? {'NODE_PATH': nodePath} : null;
      final pw = await Process.run(
        'node',
        ['-e', 'require("playwright");'],
        environment: env,
      );
      if (pw.exitCode != 0) {
        _lastError = 'playwright no disponible (instalá con pnpm add -g playwright o npm install -g playwright)';
        return false;
      }
      final ffmpeg = await Process.run('which', ['ffmpeg']);
      if (ffmpeg.exitCode != 0) {
        _lastError = 'ffmpeg no encontrado';
        return false;
      }
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  /// Renderiza un HTML a video MP4
  Future<VideoRenderResult> render({
    required String htmlPath,
    required AnimationTemplate template,
    required int durationSec,
    required String outputPath,
  }) async {
    if (!_scriptsFound && !await findDesignEngine()) {
      return VideoRenderResult(
        outputPath: outputPath,
        fileSize: 0, duration: Duration.zero, success: false,
        error: _lastError ?? 'design-engine no encontrado',
      );
    }

    await Directory(p.dirname(outputPath)).create(recursive: true);

    final renderScript = p.join(_designEnginePath!, 'scripts', 'render-video.cjs');

    if (!await File(renderScript).exists()) {
      return VideoRenderResult(
        outputPath: outputPath, fileSize: 0, duration: Duration.zero, success: false,
        error: 'render-video.cjs no encontrado en $renderScript',
      );
    }

    try {
      final nodePath = await _resolveNodePath();
      final env = nodePath != null ? {'NODE_PATH': nodePath} : null;
      final result = await Process.run('node', [
        renderScript,
        htmlPath,
        '--duration=$durationSec',
        '--width=${template.width}',
        '--height=${template.height}',
      ], environment: env);

      // El script guarda el MP4 junto al HTML con el mismo nombre base
      final htmlDir = p.dirname(htmlPath);
      final htmlBase = p.basenameWithoutExtension(htmlPath);

      // Buscar el archivo generado
      final candidates = [
        p.join(htmlDir, '$htmlBase.mp4'),
        p.join(htmlDir, 'output.mp4'),
        outputPath,
      ];

      for (final candidate in candidates) {
        final file = File(candidate);
        if (await file.exists()) {
          // Copiar a la ruta de salida deseada si es diferente
          if (candidate != outputPath) {
            await file.copy(outputPath);
          }
          final stat = await file.stat();
          return VideoRenderResult(
            outputPath: outputPath,
            fileSize: stat.size,
            duration: Duration(seconds: durationSec),
            success: true,
          );
        }
      }

      // Si no se encontró, verificar stderr por errores
      if (result.exitCode != 0) {
        return VideoRenderResult(
          outputPath: outputPath, fileSize: 0, duration: Duration.zero, success: false,
          error: result.stderr as String? ?? 'Error en render-video.cjs',
        );
      }

      return VideoRenderResult(
        outputPath: outputPath, fileSize: 0, duration: Duration.zero, success: false,
        error: 'Video generado pero no encontrado en la salida esperada',
      );
    } catch (e) {
      return VideoRenderResult(
        outputPath: outputPath, fileSize: 0, duration: Duration.zero, success: false,
        error: e.toString(),
      );
    }
  }

  /// Renderiza usando ffmpeg como fallback (convierte imágenes a video)
  Future<VideoRenderResult> renderFallback({
    required String outputPath,
    required int durationSec,
    required int width,
    required int height,
  }) async {
    await Directory(p.dirname(outputPath)).create(recursive: true);

    final args = [
      '-f', 'lavfi',
      '-i', 'color=c=0x1a1a2e:s=${width}x$height:d=$durationSec',
      '-c:v', 'libx264',
      '-preset', 'ultrafast',
      '-pix_fmt', 'yuv420p',
      '-y',
      outputPath,
    ];

    try {
      final result = await Process.run('ffmpeg', args);
      if (result.exitCode == 0) {
        final file = File(outputPath);
        final stat = await file.stat();
        return VideoRenderResult(
          outputPath: outputPath,
          fileSize: stat.size,
          duration: Duration(seconds: durationSec),
          success: true,
        );
      }
      return VideoRenderResult(
        outputPath: outputPath, fileSize: 0, duration: Duration.zero, success: false,
        error: result.stderr as String?,
      );
    } catch (e) {
      return VideoRenderResult(
        outputPath: outputPath, fileSize: 0, duration: Duration.zero, success: false,
        error: e.toString(),
      );
    }
  }
}
