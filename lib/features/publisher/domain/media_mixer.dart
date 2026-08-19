// ═══════════════════════════════════════════════════════════════
// 📦 Media Mixer — ffmpeg wrapper para mezclar audio + video
// ═══════════════════════════════════════════════════════════════
// Responsabilidades:
// - Mezclar música de fondo + video promocional
// - Superponer narración (multi-idioma) sobre video
// - Generar formatos por plataforma (vertical, horizontal)
// - Aplicar fade in/out, compresión, y normalización
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Formato de video por plataforma
class PlatformFormat {
  final String name;
  final String label;
  final IconType iconType;
  final String suffix; // vertical, horizontal
  final int width;
  final int height;
  final double aspectRatio;

  const PlatformFormat({
    required this.name,
    required this.label,
    required this.iconType,
    required this.suffix,
    required this.width,
    required this.height,
    required this.aspectRatio,
  });

  String get resolution => '${width}x$height';
}

enum IconType { phone, videocam, photo, thumbsUp, live, x }

/// Formatos soportados
const List<PlatformFormat> kPlatformFormats = [
  PlatformFormat(name: 'tiktok', label: 'TikTok / Reels', iconType: IconType.phone, suffix: 'vertical', width: 1080, height: 1920, aspectRatio: 9 / 16),
  PlatformFormat(name: 'youtube', label: 'YouTube', iconType: IconType.videocam, suffix: 'horizontal', width: 1920, height: 1080, aspectRatio: 16 / 9),
  PlatformFormat(name: 'instagram', label: 'Instagram', iconType: IconType.photo, suffix: 'vertical', width: 1080, height: 1920, aspectRatio: 9 / 16),
  PlatformFormat(name: 'facebook', label: 'Facebook', iconType: IconType.thumbsUp, suffix: 'horizontal', width: 1920, height: 1080, aspectRatio: 16 / 9),
  PlatformFormat(name: 'twitch', label: 'Twitch', iconType: IconType.live, suffix: 'horizontal', width: 1920, height: 1080, aspectRatio: 16 / 9),
  PlatformFormat(name: 'x', label: 'X / Twitter', iconType: IconType.x, suffix: 'vertical', width: 1080, height: 1920, aspectRatio: 9 / 16),
];

/// Resultado de una operación de mezcla
class MixResult {
  final String outputPath;
  final int fileSize;
  final Duration duration;
  final bool success;
  final String? error;

  const MixResult({
    required this.outputPath,
    required this.fileSize,
    required this.duration,
    required this.success,
    this.error,
  });
}

/// Wrapper para operaciones de ffmpeg
class MediaMixer {
  /// Verifica que ffmpeg esté disponible
  Future<bool> checkAvailability() async {
    try {
      final result = await Process.run('which', ['ffmpeg']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Mezcla video + música de fondo
  ///
  /// [videoPath]: archivo de video promocional
  /// [audioPath]: archivo de música de fondo
  /// [outputPath]: archivo de salida
  /// [narrationPath]: opcional, pista de narración
  /// [volumeMusic]: volumen de la música (0.0 - 1.0, default 0.3)
  /// [volumeNarration]: volumen de la narración (0.0 - 1.0, default 1.0)
  Future<MixResult> mixAudioVideo({
    required String videoPath,
    required String audioPath,
    required String outputPath,
    String? narrationPath,
    double volumeMusic = 0.3,
    double volumeNarration = 1.0,
  }) async {
    await Directory(p.dirname(outputPath)).create(recursive: true);

    final hasNarration = narrationPath != null && await File(narrationPath).exists();

    // Construir filtro de audio
    // 1. Música de fondo con volumen reducido
    // 2. Narración con volumen normal (si existe)
    // 3. Mezclar ambas pistas
    String filterComplex;
    List<String> inputFiles;

    if (hasNarration) {
      inputFiles = [
        '-i', videoPath,
        '-i', audioPath,
        '-i', narrationPath,
      ];
      filterComplex =
          '[1:a]volume=$volumeMusic[music];'
          '[2:a]volume=$volumeNarration[narration];'
          '[music][narration]amix=inputs=2:duration=longest[aout]';
    } else {
      inputFiles = [
        '-i', videoPath,
        '-i', audioPath,
      ];
      filterComplex = '[1:a]volume=$volumeMusic[aout]';
    }

    final args = [
      ...inputFiles,
      '-filter_complex', filterComplex,
      '-map', '0:v',        // Video del primer input
      '-map', '[aout]',     // Audio mezclado
      '-c:v', 'libx264',    // Codec video
      '-preset', 'medium',
      '-crf', '23',
      '-c:a', 'aac',        // Codec audio
      '-b:a', '192k',
      '-shortest',          // Cortar al más corto
      '-y',                 // Sobrescribir
      outputPath,
    ];

    try {
      final result = await Process.run('ffmpeg', args)
          .timeout(const Duration(seconds: 300));

      if (result.exitCode == 0) {
        final file = File(outputPath);
        if (await file.exists()) {
          final stat = await file.stat();
          final duration = await _getVideoDuration(outputPath);
          return MixResult(
            outputPath: outputPath,
            fileSize: stat.size,
            duration: duration,
            success: true,
          );
        }
      }

      return MixResult(
        outputPath: outputPath,
        fileSize: 0,
        duration: Duration.zero,
        success: false,
        error: result.stderr as String?,
      );
    } catch (e) {
      return MixResult(
        outputPath: outputPath,
        fileSize: 0,
        duration: Duration.zero,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Genera video para una plataforma específica (redimensiona + mezcla)
  Future<MixResult> renderForPlatform({
    required String videoPath,
    required String audioPath,
    required PlatformFormat format,
    required String outputPath,
    String? narrationPath,
  }) async {
    await Directory(p.dirname(outputPath)).create(recursive: true);

    final hasNarration = narrationPath != null && await File(narrationPath).exists();

    String filterComplex;
    List<String> inputFiles;

    if (hasNarration) {
      inputFiles = [
        '-i', videoPath,
        '-i', audioPath,
        '-i', narrationPath,
      ];
      filterComplex =
          '[0:v]scale=${format.width}:${format.height}:force_original_aspect_ratio=decrease,pad=${format.width}:${format.height}:(ow-iw)/2:(oh-ih)/2[vid];'
          '[1:a]volume=0.3[music];'
          '[2:a]volume=1.0[narration];'
          '[music][narration]amix=inputs=2:duration=longest[aout]';
    } else {
      inputFiles = [
        '-i', videoPath,
        '-i', audioPath,
      ];
      filterComplex =
          '[0:v]scale=${format.width}:${format.height}:force_original_aspect_ratio=decrease,pad=${format.width}:${format.height}:(ow-iw)/2:(oh-ih)/2[vid];'
          '[1:a]volume=0.3[aout]';
    }

    final args = [
      ...inputFiles,
      '-filter_complex', filterComplex,
      '-map', '[vid]',
      '-map', '[aout]',
      '-c:v', 'libx264',
      '-preset', 'medium',
      '-crf', '23',
      '-c:a', 'aac',
      '-b:a', '192k',
      '-movflags', '+faststart',
      '-shortest',
      '-y',
      outputPath,
    ];

    try {
      final result = await Process.run('ffmpeg', args)
          .timeout(const Duration(seconds: 300));

      if (result.exitCode == 0) {
        final file = File(outputPath);
        if (await file.exists()) {
          final stat = await file.stat();
          final duration = await _getVideoDuration(outputPath);
          return MixResult(
            outputPath: outputPath,
            fileSize: stat.size,
            duration: duration,
            success: true,
          );
        }
      }

      return MixResult(
        outputPath: outputPath,
        fileSize: 0,
        duration: Duration.zero,
        success: false,
        error: result.stderr as String?,
      );
    } catch (e) {
      return MixResult(
        outputPath: outputPath,
        fileSize: 0,
        duration: Duration.zero,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Obtiene duración de un video usando ffprobe
  Future<Duration> _getVideoDuration(String videoPath) async {
    try {
      final result = await Process.run('ffprobe', [
        '-v', 'quiet',
        '-print_format', 'json',
        '-show_format',
        videoPath,
      ]);
      if (result.exitCode == 0) {
        final json = jsonDecode(result.stdout as String) as Map<String, dynamic>;
        final format = json['format'] as Map<String, dynamic>?;
        if (format != null && format['duration'] is String) {
          final seconds = double.tryParse(format['duration'] as String) ?? 0;
          return Duration(milliseconds: (seconds * 1000).round());
        }
      }
    } catch (_) {}
    return Duration.zero;
  }
}
