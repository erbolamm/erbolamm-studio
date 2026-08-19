// ═══════════════════════════════════════════════════════════════
// 🎤 Record Service — Grabación real con micrófono
// ═══════════════════════════════════════════════════════════════
// Usa ffmpeg vía subprocess para capturar audio del micrófono
// en macOS (AVFoundation). En Linux/Mac funciona con ffmpeg.
//
// Requiere: ffmpeg instalado en el sistema
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resultado de una grabación
class RecordResult {
  final String filePath;
  final Duration duration;
  final int sampleRate;
  final int fileSize;

  const RecordResult({
    required this.filePath,
    required this.duration,
    required this.sampleRate,
    required this.fileSize,
  });

  Map<String, dynamic> toJson() => {
    'filePath': filePath,
    'durationMs': duration.inMilliseconds,
    'sampleRate': sampleRate,
    'fileSize': fileSize,
  };
}

/// Estado del servicio de grabación
enum RecordStatus { idle, recording, stopped, error }

/// Servicio de grabación de audio usando ffmpeg
class RecordService {
  RecordStatus _status = RecordStatus.idle;
  Process? _ffmpegProcess;
  String? _currentOutputPath;
  DateTime? _startTime;
  String? _lastError;

  RecordStatus get status => _status;
  String? get lastError => _lastError;
  String? get currentOutputPath => _currentOutputPath;
  Duration get currentDuration => _startTime != null
      ? DateTime.now().difference(_startTime!)
      : Duration.zero;

  /// Verifica que ffmpeg esté disponible
  Future<bool> checkAvailability() async {
    try {
      final result = await Process.run('which', ['ffmpeg']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Lista los dispositivos de audio disponibles en macOS
  Future<List<String>> listAudioDevices() async {
    final devices = <String>[];
    try {
      final result = await Process.run('ffmpeg', [
        '-f',
        'avfoundation',
        '-list_devices',
        'true',
        '-i',
        '',
      ]);
      final stderr = result.stderr as String;
      // Parsear dispositivos de audio del output de ffmpeg
      final lines = stderr.split('\n');
      bool inAudio = false;
      for (final line in lines) {
        if (line.contains('AVFoundation audio devices')) {
          inAudio = true;
          continue;
        }
        if (inAudio) {
          if (line.contains(']') && line.contains('[')) {
            final match = RegExp(r'\[(\d+)\]\s+(.+)').firstMatch(line);
            if (match != null) {
              devices.add('${match.group(1)}: ${match.group(2)}');
            }
          } else if (line.trim().isEmpty || line.contains('video devices')) {
            break;
          }
        }
      }
    } catch (_) {}
    return devices;
  }

  /// Inicia la grabación desde el micrófono por defecto
  ///
  /// [outputPath]: ruta donde guardar el WAV (auto-generada si no se especifica)
  /// [maxDuration]: duración máxima en segundos (por defecto 30s)
  /// [deviceIndex]: índice del dispositivo de audio (0 = default)
  Future<bool> startRecording({
    String? outputPath,
    int maxDuration = 30,
    int deviceIndex = 0,
  }) async {
    if (_status == RecordStatus.recording) {
      await stopRecording();
    }

    // Crear directorio de salida
    final dir = outputPath != null
        ? Directory(p.dirname(outputPath))
        : await _getRecordingsDir();

    if (outputPath == null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      outputPath = p.join(dir.path, 'recording_$timestamp.wav');
    } else {
      await dir.create(recursive: true);
    }

    _currentOutputPath = outputPath;
    _lastError = null;

    try {
      _ffmpegProcess = await Process.start('ffmpeg', [
        '-y', // Sobrescribir
        '-f', 'avfoundation',
        '-i', ':$deviceIndex', // Micrófono por defecto
        '-acodec', 'pcm_s16le', // WAV 16-bit
        '-ar', '44100', // 44.1kHz
        '-ac', '1', // Mono
        '-t', '$maxDuration', // Duración máxima
        outputPath,
      ]);

      _status = RecordStatus.recording;
      _startTime = DateTime.now();

      // Escuchar stderr para detectar errores
      _ffmpegProcess!.stderr.transform(utf8.decoder).listen((data) {
        // ffmpeg logs to stderr, most are informational
        if (data.contains('Error') || data.contains('error')) {
          _lastError = data;
        }
      });

      // Esperar a que termine
      _ffmpegProcess!.exitCode.then((code) {
        if (code != 0 && _status == RecordStatus.recording) {
          _status = RecordStatus.error;
          _lastError = 'ffmpeg exited with code $code';
        }
      });

      return true;
    } catch (e) {
      _status = RecordStatus.error;
      _lastError = e.toString();
      return false;
    }
  }

  /// Detiene la grabación actual
  Future<RecordResult?> stopRecording() async {
    if (_status != RecordStatus.recording || _ffmpegProcess == null) {
      return null;
    }

    // Enviar 'q' para detener ffmpeg gracefulmente
    _ffmpegProcess!.stdin.writeln('q');

    final exitCode = await _ffmpegProcess!.exitCode.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _ffmpegProcess!.kill(ProcessSignal.sigterm);
        return -1;
      },
    );

    _status = exitCode == 0 || exitCode == 255
        ? RecordStatus.stopped
        : RecordStatus.error;

    if (_status == RecordStatus.stopped && _currentOutputPath != null) {
      final file = File(_currentOutputPath!);
      if (await file.exists()) {
        final stat = await file.stat();
        final durationMs = _startTime != null
            ? DateTime.now().difference(_startTime!).inMilliseconds
            : 0;
        return RecordResult(
          filePath: _currentOutputPath!,
          duration: Duration(milliseconds: durationMs),
          sampleRate: 44100,
          fileSize: stat.size,
        );
      }
    }

    return null;
  }

  /// Reproduce un archivo de audio (opcional, para preview)
  Future<void> playAudio(String filePath) async {
    await Process.run('ffplay', ['-nodisp', '-autoexit', filePath]);
  }

  /// Obtiene el directorio de grabaciones
  Future<Directory> _getRecordingsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'voice_recordings'));
    await dir.create(recursive: true);
    return dir;
  }

  /// Limpia recursos
  void dispose() {
    if (_ffmpegProcess != null && _status == RecordStatus.recording) {
      _ffmpegProcess!.kill();
      _ffmpegProcess = null;
    }
    _status = RecordStatus.idle;
  }
}
