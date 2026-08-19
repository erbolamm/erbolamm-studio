// ═══════════════════════════════════════════════════════════════
// 🗣️ Voice Service — Backend con mmx CLI (sin Python)
// ═══════════════════════════════════════════════════════════════
// Reemplaza voice_pipeline.py + XTTS v2 por mmx speech synthesize
// Todo en Dart puro + CLI externo mmx
//
// Uso:
//   final check = await VoiceService.checkAvailability();
//   final tracks = await VoiceService.generateAllLanguages(texts: {...});
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/record_service.dart';

/// Narración generada resultante
class NarrationTrack {
  final String language;
  final String filePath;
  final Duration duration;
  final int fileSize;

  const NarrationTrack({
    required this.language,
    required this.filePath,
    required this.duration,
    required this.fileSize,
  });
}

/// Estado del servicio de voz
enum VoiceServiceStatus { unavailable, checking, ready, error }

/// Una frase grabada por el usuario
class VoiceSample {
  final String phrase;
  final String filePath;
  final Duration duration;

  const VoiceSample({
    required this.phrase,
    required this.filePath,
    required this.duration,
  });
}

/// Verificación completa del sistema
class SystemCheckResult {
  final bool ffmpegAvailable;
  final bool mmxAvailable;
  final String mmxVersion;
  final String? error;

  const SystemCheckResult({
    required this.ffmpegAvailable,
    required this.mmxAvailable,
    required this.mmxVersion,
    this.error,
  });

  bool get allReady => mmxAvailable && ffmpegAvailable;
}

/// Servicio de voz — usa mmx CLI para TTS
///
/// Anula el pipeline Python原来的VoiceService para evitar dependencias de Python.
/// La grabación sigue usando RecordService (ffmpeg).
class VoiceService {
  VoiceServiceStatus _status = VoiceServiceStatus.unavailable;
  String? _error;
  final RecordService _recordService = RecordService();
  static const _outputDir = '/tmp/erbolamm_narrations';

  VoiceServiceStatus get status => _status;
  String? get error => _error;
  RecordService get recordService => _recordService;

  /// Verifica que mmx y ffmpeg estén disponibles
  Future<SystemCheckResult> checkAvailability() async {
    _status = VoiceServiceStatus.checking;

    bool mmxAvailable = false;
    String mmxVersion = '';
    bool ffmpegAvailable = false;

    // Check mmx via mmx --version
    try {
      final result = await Process.run('mmx', ['--version']);
      if (result.exitCode == 0) {
        mmxAvailable = true;
        final output = (result.stdout as String).trim();
        final match = RegExp(r'(\d+\.\d+\.\d+)').firstMatch(output);
        mmxVersion = match?.group(1) ?? 'unknown';
      }
    } catch (_) {}

    // Check ffmpeg
    try {
      final result = await Process.run('which', ['ffmpeg']);
      ffmpegAvailable = result.exitCode == 0;
    } catch (_) {}

    if (!mmxAvailable) {
      _status = VoiceServiceStatus.unavailable;
      _error = 'mmx no disponible. Instalar: npm install -g @minimax/mmx-cli';
      return SystemCheckResult(
        ffmpegAvailable: ffmpegAvailable,
        mmxAvailable: false,
        mmxVersion: '',
        error: _error,
      );
    }

    if (!ffmpegAvailable) {
      _status = VoiceServiceStatus.unavailable;
      _error = 'ffmpeg no disponible';
      return SystemCheckResult(
        ffmpegAvailable: false,
        mmxAvailable: true,
        mmxVersion: mmxVersion,
        error: _error,
      );
    }

    _status = VoiceServiceStatus.ready;
    return SystemCheckResult(
      ffmpegAvailable: true,
      mmxAvailable: true,
      mmxVersion: mmxVersion,
    );
  }

  /// Lista voces disponibles en mmx
  Future<List<String>> listVoices() async {
    try {
      final result = await Process.run('mmx', ['speech', 'voices']);
      if (result.exitCode == 0) {
        final output = (result.stdout as String).trim();
        if (output.startsWith('[')) {
          // Es JSON
          final decoded = jsonDecode(output);
          if (decoded is List) {
            return decoded.cast<String>();
          }
        }
        // Es texto plano, una voz por línea
        return output.split('\n').where((l) => l.trim().isNotEmpty).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Genera narración en un idioma usando mmx
  Future<NarrationTrack?> synthesizeNarration({
    required String text,
    required String language,
    String? customVoice,
    Duration timeout = const Duration(minutes: 2),
  }) async {
    _error = null;

    final voice = customVoice ?? _defaultVoiceForLang(language);
    if (voice == null) {
      _error = 'Idioma $language no soportado';
      return null;
    }

    // Crear directorio de salida
    final outDir = Directory(_outputDir);
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = p.join(_outputDir, 'narration_${language}_$timestamp.wav');

    final result = await Process.run('mmx', [
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
    ]).timeout(timeout);

    if (result.exitCode == 0) {
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return NarrationTrack(
          language: language,
          filePath: filePath,
          duration: Duration(
            milliseconds: stat.size ~/ 88,
          ), // WAV 44.1kHz 16bit ~88KB/s
          fileSize: stat.size,
        );
      }
    }

    _error = 'mmx synthesize falló: ${result.stderr}';
    return null;
  }

  /// Genera narración en todos los idiomas soportados
  Future<List<NarrationTrack>> generateAllLanguages({
    required Map<String, String> texts,
    Duration timeoutPerLang = const Duration(minutes: 2),
  }) async {
    final tracks = <NarrationTrack>[];

    for (final entry in texts.entries) {
      if (!mounted) break;

      final track = await synthesizeNarration(
        text: entry.value,
        language: entry.key,
        timeout: timeoutPerLang,
      );

      if (track != null) {
        tracks.add(track);
      }
    }

    return tracks;
  }

  /// Graba una muestra de voz usando RecordService
  Future<VoiceSample?> recordSample(String phrase, Duration maxDuration) async {
    final recordingsDir = Directory('/tmp/erbolamm_voice_samples');
    await recordingsDir.create(recursive: true);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = p.join(recordingsDir.path, 'sample_$timestamp.wav');

    final started = await _recordService.startRecording(
      outputPath: filePath,
      maxDuration: maxDuration.inSeconds,
    );

    if (!started) return null;

    final result = await _recordService.stopRecording();
    if (result == null) return null;

    return VoiceSample(
      phrase: phrase,
      filePath: filePath,
      duration: result.duration,
    );
  }

  /// Reproduce un archivo de audio
  Future<void> playAudio(String filePath) async {
    await _recordService.playAudio(filePath);
  }

  /// Limpia archivos temporales
  Future<void> cleanup() async {
    _recordService.dispose();

    for (final dir in ['/tmp/erbolamm_voice_samples', _outputDir]) {
      try {
        await Directory(dir).delete(recursive: true);
      } catch (_) {}
    }
  }

  static String? _defaultVoiceForLang(String lang) {
    const voices = {
      'es': 'Spanish_Narrator',
      'en': 'English_expressive_narrator',
      'pt': 'Portuguese_Narrator',
      'fr': 'French_Male_Speech_New',
      'de': 'German_FriendlyMan',
      'it': 'Italian_Narrator',
      'ja': 'Japanese_IntellectualSenior',
      'ko': 'Korean_GentleWoman',
      'zh': 'Chinese (Mandarin)_News_Anchor',
    };
    return voices[lang];
  }

  bool mounted = true;
}

// Alias para la UI existente
class VoiceCloneResult {
  final String modelPath;
  final double quality;
  final int samplesUsed;
  final String testAudioPath;

  const VoiceCloneResult({
    required this.modelPath,
    required this.quality,
    required this.samplesUsed,
    required this.testAudioPath,
  });
}
