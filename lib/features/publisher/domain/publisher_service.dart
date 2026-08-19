// ═══════════════════════════════════════════════════════════════
// 📦 Publisher Service — Orquesta el pipeline de publicación
// ═══════════════════════════════════════════════════════════════
// Lee assets del proyecto promocional (promo/), mezcla audio+video,
// integra narración desde Voice Studio, y genera formatos por plataforma.
// ═══════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:path/path.dart' as p;

import 'media_mixer.dart';

/// Estado de un paso del pipeline
enum PipelineStepStatus { pending, running, done, failed }

/// Información de un paso
class PipelineStep {
  final String id;
  final String title;
  final String subtitle;
  PipelineStepStatus status;
  String? error;
  DateTime? startedAt;
  DateTime? completedAt;

  PipelineStep({
    required this.id,
    required this.title,
    required this.subtitle,
    this.status = PipelineStepStatus.pending,
    this.error,
  });

  Duration? get duration {
    if (startedAt == null) return null;
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt!);
  }
}

/// Resultado de exportación para una plataforma
class ExportResult {
  final String platform;
  final String filePath;
  final bool success;
  final int fileSize;
  final Duration duration;
  final String? error;

  const ExportResult({
    required this.platform,
    required this.filePath,
    required this.success,
    required this.fileSize,
    required this.duration,
    this.error,
  });
}

/// Servicio principal de publicación
class PublisherService {
  final MediaMixer mixer;
  final String projectPath;
  final String promoPath;

  PublisherService({
    required this.projectPath,
    MediaMixer? mixer,
  }) : mixer = mixer ?? MediaMixer(),
       promoPath = Directory(p.join(projectPath, 'erbolamm-studio')).existsSync()
           ? p.join(projectPath, 'erbolamm-studio')
           : Directory(p.join(projectPath, 'promo')).existsSync()
               ? p.join(projectPath, 'promo')
               : p.join(projectPath, 'erbolamm-studio');

  // Pasos del pipeline
  late final List<PipelineStep> steps = [
    PipelineStep(id: 'audio', title: 'Generar música', subtitle: 'Usar Music Studio para crear el track'),
    PipelineStep(id: 'video', title: 'Renderizar video', subtitle: 'Usar Animation Studio para el video'),
    PipelineStep(id: 'mix', title: 'Mezclar audio + video', subtitle: 'Combinar pistas con ffmpeg'),
    PipelineStep(id: 'narration', title: 'Añadir narración', subtitle: 'Integrar voz desde Voice Studio'),
    PipelineStep(id: 'export', title: 'Exportar a redes', subtitle: 'Generar formatos por plataforma'),
  ];

  void Function(PipelineStep step)? onStepChanged;
  void Function(double progress)? onProgress;
  void Function(ExportResult result)? onExportComplete;

  /// Verificar disponibilidad de ffmpeg
  Future<bool> checkAvailable() => mixer.checkAvailability();

  /// Verificar qué assets existen en el proyecto
  Future<Map<String, bool>> checkAssets() async {
    return {
      'audio': await File(p.join(promoPath, 'music', 'background.mp3')).exists() ||
              await File(p.join(promoPath, 'audio.mp3')).exists(),
      'video': await File(p.join(promoPath, 'video.mp4')).exists() ||
               await File(p.join(promoPath, 'render', 'output.mp4')).exists(),
      'narration': await Directory(p.join(promoPath, 'narration')).exists(),
      'videosPromo': await Directory(p.join(promoPath, 'videos')).exists(),
    };
  }

  /// Encontrar rutas de assets disponibles
  Future<Map<String, String?>> findAssetPaths() async {
    final video = _firstExisting([
      p.join(promoPath, 'render', 'output.mp4'),
      p.join(promoPath, 'video.mp4'),
      p.join(promoPath, 'videos', 'promo-horizontal.mp4'),
      p.join(promoPath, 'videos', 'promo-vertical.mp4'),
    ]);

    final audio = _firstExisting([
      p.join(promoPath, 'music', 'background.mp3'),
      p.join(promoPath, 'audio.mp3'),
      p.join(promoPath, 'music.wav'),
      p.join(promoPath, 'source', 'music.mp3'),
      p.join(promoPath, 'source', 'music.wav'),
    ]);

    // Buscar narraciones (formato: narration/{lang}/narration_{lang}_*.wav)
    final narrationDir = Directory(p.join(promoPath, 'narration'));
    String? narrationEs;
    if (await narrationDir.exists()) {
      final esDir = Directory(p.join(narrationDir.path, 'es'));
      if (await esDir.exists()) {
        final wavFiles = esDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.wav'))
            .toList()
          ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        if (wavFiles.isNotEmpty) {
          narrationEs = wavFiles.first.path;
        }
      }
      if (narrationEs == null) {
        for (final pattern in [
          'narration_es.wav',
          'es/narration.es.wav',
          'es/narration_es.wav',
        ]) {
          final f = File(p.join(narrationDir.path, pattern));
          if (await f.exists()) {
            narrationEs = f.path;
            break;
          }
        }
      }
    }

    return {
      'video': video,
      'audio': audio,
      'narration': narrationEs,
    };
  }

  /// Obtener lista de idiomas disponibles en narraciones
  Future<List<String>> getAvailableLanguages() async {
    final narrationDir = Directory(p.join(promoPath, 'narration'));
    if (!await narrationDir.exists()) return [];

    final languages = <String>[];
    final dirs = await narrationDir.list().toList();
    for (final entity in dirs) {
      if (entity is Directory) {
        final langCode = p.basename(entity.path);
        if (langCode.length == 2) {
          languages.add(langCode);
        }
      }
    }
    return languages;
  }

  /// Ejecutar el pipeline completo
  Future<bool> runPipeline({
    required String videoPath,
    required String audioPath,
    String? narrationPath,
  }) async {
    _updateStep('audio', PipelineStepStatus.done);
    _updateStep('video', PipelineStepStatus.done);

    // Paso: mezclar
    _updateStep('mix', PipelineStepStatus.running);
    onProgress?.call(0.3);

    final mixOutput = p.join(promoPath, 'render', 'mixed.mp4');
    final mixResult = await mixer.mixAudioVideo(
      videoPath: videoPath,
      audioPath: audioPath,
      narrationPath: narrationPath,
      outputPath: mixOutput,
    );

    if (!mixResult.success) {
      _updateStep('mix', PipelineStepStatus.failed, error: mixResult.error);
      return false;
    }
    _updateStep('mix', PipelineStepStatus.done);
    onProgress?.call(0.6);

    // Paso: narración
    _updateStep('narration', PipelineStepStatus.done);
    onProgress?.call(0.8);

    return true;
  }

  /// Exportar para una plataforma específica
  Future<ExportResult> exportForPlatform({
    required String mixedVideoPath,
    required String audioPath,
    required PlatformFormat format,
    String? narrationPath,
    String langCode = 'es',
  }) async {
    final outputDir = Directory(p.join(promoPath, 'export'));
    await outputDir.create(recursive: true);

    final suffix = langCode == 'es' ? '' : '_$langCode';
    final outputPath = p.join(outputDir.path, 'promo-${format.suffix}$suffix.mp4');

    final result = await mixer.renderForPlatform(
      videoPath: mixedVideoPath,
      audioPath: audioPath,
      format: format,
      narrationPath: narrationPath,
      outputPath: outputPath,
    );

    final exportResult = ExportResult(
      platform: format.name,
      filePath: result.success ? outputPath : '',
      success: result.success,
      fileSize: result.fileSize,
      duration: result.duration,
      error: result.error,
    );

    onExportComplete?.call(exportResult);
    return exportResult;
  }

  /// Exportar para todas las plataformas
  Future<List<ExportResult>> exportAllPlatforms({
    required String mixedVideoPath,
    required String audioPath,
    String? narrationPath,
  }) async {
    _updateStep('export', PipelineStepStatus.running);
    final results = <ExportResult>[];

    for (var i = 0; i < kPlatformFormats.length; i++) {
      final format = kPlatformFormats[i];
      onProgress?.call(0.8 + (i / kPlatformFormats.length) * 0.2);

      final result = await exportForPlatform(
        mixedVideoPath: mixedVideoPath,
        audioPath: audioPath,
        format: format,
        narrationPath: narrationPath,
      );
      results.add(result);
    }

    final allOk = results.every((r) => r.success);
    _updateStep('export', allOk ? PipelineStepStatus.done : PipelineStepStatus.failed);
    return results;
  }

  // ── Helpers ──

  String? _firstExisting(List<String> paths) {
    for (final path in paths) {
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  void _updateStep(String id, PipelineStepStatus status, {String? error}) {
    for (final step in steps) {
      if (step.id == id) {
        if (status == PipelineStepStatus.running) {
          step.startedAt = DateTime.now();
        } else if (status == PipelineStepStatus.done || status == PipelineStepStatus.failed) {
          step.completedAt = DateTime.now();
        }
        step.status = status;
        step.error = error;
        onStepChanged?.call(step);
        return;
      }
    }
  }
}
