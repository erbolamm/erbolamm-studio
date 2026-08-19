// ═══════════════════════════════════════════════════════════════
// 🗣️ Mmx Voice Service — TTS con mmx CLI (sin Python)
// ═══════════════════════════════════════════════════════════════
// Backend para Voice Studio usando mmx speech synthesize
// Reemplaza voice_pipeline.py + Python + XTTS
//
// Uso: MmxVoiceService.generateNarration(text, language)
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:io';
import '../../../core/logging/app_logger.dart';

import 'package:path/path.dart' as p;

import 'dart:convert';

/// Idiomas soportados con sus voces mmx
const kMmxLanguages = {
  'es': 'Spanish_Narrator',
  'en': 'English_expressive_narrator',
  'pt': 'Portuguese_Narrator',
  'fr': 'French_Male_Speech_New',
  'de': 'German_FriendlyMan',
  'it': 'Italian_Narrator',
};

/// Narración generado por mmx
class MmxNarrationTrack {
  final String language;
  final String filePath;
  final Duration duration;
  final int fileSize;

  const MmxNarrationTrack({
    required this.language,
    required this.filePath,
    required this.duration,
    required this.fileSize,
  });
}

/// Resultado de verificación del sistema
class MmxSystemCheck {
  final bool mmxAvailable;
  final bool ffmpegAvailable;
  final String mmxVersion;
  final String? error;

  const MmxSystemCheck({
    required this.mmxAvailable,
    required this.ffmpegAvailable,
    required this.mmxVersion,
    this.error,
  });

  bool get allReady => mmxAvailable && ffmpegAvailable;
}

/// Servicio de voz usando mmx CLI
class MmxVoiceService {
  static const _outputDir = '/tmp/erbolamm_mmx_narrations';

  /// Verifica que mmx y ffmpeg estén disponibles
  static Future<MmxSystemCheck> checkAvailability() async {
    bool mmxAvailable = false;
    String mmxVersion = '';
    bool ffmpegAvailable = false;

    // Check mmx
    try {
      final result = await Process.run('mmx', ['--version']);
      if (result.exitCode == 0) {
        mmxAvailable = true;
        final output = (result.stdout as String).trim();
        final match = RegExp(r'(\d+\.\d+\.\d+)').firstMatch(output);
        mmxVersion = match?.group(1) ?? output;
      }
    } catch (_) {}

    // Check ffmpeg
    try {
      final result = await Process.run('ffmpeg', ['-version']);
      ffmpegAvailable = result.exitCode == 0;
    } catch (_) {}

    if (!mmxAvailable) {
      return MmxSystemCheck(
        mmxAvailable: false,
        ffmpegAvailable: ffmpegAvailable,
        mmxVersion: '',
        error: 'mmx no encontrado. Instalar: npm install -g @minimax/mmx-cli',
      );
    }

    return MmxSystemCheck(
      mmxAvailable: mmxAvailable,
      ffmpegAvailable: ffmpegAvailable,
      mmxVersion: mmxVersion,
    );
  }

  /// Lista voces disponibles
  static Future<List<String>> listVoices() async {
    try {
      final result = await Process.run('mmx', ['speech', 'voices']);
      if (result.exitCode == 0) {
        final json = result.stdout as String;
        return _parseVoicesJson(json);
      }
    } catch (_) {}
    return [];
  }

  static List<String> _parseVoicesJson(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        return decoded.cast<String>();
      }
    } catch (_) {}
    // Fallback: split por líneas
    return json.split('\n').where((l) => l.isNotEmpty).toList();
  }

  /// Genera narración en un idioma usando mmx
  static Future<MmxNarrationTrack?> generateNarration({
    required String text,
    required String language,
    String? customVoice,
    String? outputDir,
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final voice = customVoice ?? kMmxLanguages[language] ?? 'Spanish_Narrator';
    final outDir = outputDir ?? _outputDir;

    // Crear directorio de salida
    final outDirObj = Directory(outDir);
    if (!await outDirObj.exists()) {
      await outDirObj.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = p.join(outDir, 'narration_${language}_$timestamp.wav');

    final args = [
      'speech',
      'synthesize',
      '--text',
      text,
      '--voice',
      voice,
      '--out',
      filePath,
      '--format',
      'wav',
      '--sample-rate',
      '44100',
    ];

    try {
      final result = await Process.run('mmx', args).timeout(timeout);

      if (result.exitCode == 0) {
        final file = File(filePath);
        if (await file.exists()) {
          final stat = await file.stat();
          return MmxNarrationTrack(
            language: language,
            filePath: filePath,
            duration: Duration(
              milliseconds: stat.size ~/ (44100 * 2),
            ), // ~44KB/s para WAV 44.1kHz 16bit
            fileSize: stat.size,
          );
        }
      }

      // Log error
      final stderr = result.stderr as String;
      if (stderr.isNotEmpty) {
        AppLogger.i('[MmxVoiceService] mmx notice: $stderr');
      }
    } on TimeoutException {
      AppLogger.i('[MmxVoiceService] Timeout generando narración $language con mmx');
    } catch (e) {
      AppLogger.i('[MmxVoiceService] Excepción mmx: $e');
    }

    // Fallback a motor TTS del sistema (macOS say + ffmpeg)
    AppLogger.i('[MmxVoiceService] 🎙️ Usando fallback local TTS para idioma "$language"...');
    return _fallbackSystemTts(text: text, language: language, outputPath: filePath);
  }

  /// Fallback local con motor TTS del sistema (say + ffmpeg)
  static Future<MmxNarrationTrack?> _fallbackSystemTts({
    required String text,
    required String language,
    required String outputPath,
  }) async {
    if (!Platform.isMacOS) return null;

    final voiceMap = {
      'es': 'Mónica',
      'en': 'Daniel',
      'pt': 'Luciana',
      'fr': 'Amélie',
      'de': 'Anna',
      'it': 'Alice',
      'ja': 'Kyoko',
      'zh': 'Tingting',
    };

    final systemVoice = voiceMap[language] ?? 'Mónica';
    final tempAiff = '${outputPath}_temp.aiff';

    try {
      final sayResult = await Process.run('say', [
        '-v',
        systemVoice,
        '-o',
        tempAiff,
        text,
      ]);

      if (sayResult.exitCode == 0 && File(tempAiff).existsSync()) {
        final ffmpegResult = await Process.run('ffmpeg', [
          '-y',
          '-i',
          tempAiff,
          outputPath,
        ]);

        try {
          File(tempAiff).deleteSync();
        } catch (_) {}

        if (ffmpegResult.exitCode == 0 && File(outputPath).existsSync()) {
          final stat = await File(outputPath).stat();
          AppLogger.i('[MmxVoiceService] ✅ TTS local generado para $language ($systemVoice): ${(stat.size / 1024).toStringAsFixed(0)}KB');
          return MmxNarrationTrack(
            language: language,
            filePath: outputPath,
            duration: Duration(milliseconds: stat.size ~/ (44100 * 2)),
            fileSize: stat.size,
          );
        }
      }
    } catch (e) {
      AppLogger.e('[MmxVoiceService] Error en fallback TTS local: $e');
    }

    return null;
  }

  /// Genera narración en todos los idiomas soportados
  static Future<List<MmxNarrationTrack>> generateAllLanguages({
    required Map<String, String> texts,
    String? customVoice,
    String? outputDir,
    Duration timeoutPerLang = const Duration(minutes: 2),
  }) async {
    final tracks = <MmxNarrationTrack>[];

    for (final entry in texts.entries) {
      final track = await generateNarration(
        text: entry.value,
        language: entry.key,
        customVoice: customVoice ?? kMmxLanguages[entry.key],
        outputDir: outputDir,
        timeout: timeoutPerLang,
      );
      if (track != null) {
        tracks.add(track);
      }
    }

    return tracks;
  }

  /// Limpia archivos temporales
  static Future<void> cleanup() async {
    try {
      await Directory(_outputDir).delete(recursive: true);
    } catch (_) {}
  }
}
