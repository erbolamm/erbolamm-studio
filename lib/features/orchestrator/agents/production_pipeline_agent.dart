// ═══════════════════════════════════════════════════════════════
// 🎬 Agente 8 — Production Pipeline (Content Studio)
// ═══════════════════════════════════════════════════════════════
// Integra: Music Studio → Animation Studio → Voice Studio → Publisher
// Se ejecuta después del pipeline de 7 agentes INBOX.
//
// Flujo:
//   1. Analizar proyecto → clasificar tipo
//   2. Generar música (si es proyecto promo)
//   3. Generar animación
//   4. Generar narración de voz
//   5. Exportar a redes
//
// Cada paso puede ejecutarse o saltarse según el tipo de proyecto.
// ═══════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/agent_interface.dart';

// ─── Servicios de los módulos ───
import '../../music/domain/audio_renderer.dart';
import '../../music/domain/strudel_generator.dart';
import '../../animation/domain/video_renderer.dart';
import '../../animation/domain/animation_template.dart';
import '../../voice/domain/voice_service.dart';
import '../../publisher/domain/media_mixer.dart';

/// Resultado de un paso del pipeline de producción
class ProductionStepResult {
  final String stepId;
  final String title;
  final bool success;
  final String? outputPath;
  final int? fileSizeBytes;
  final Duration? duration;
  final String? error;
  final Map<String, dynamic> metadata;

  const ProductionStepResult({
    required this.stepId,
    required this.title,
    required this.success,
    this.outputPath,
    this.fileSizeBytes,
    this.duration,
    this.error,
    this.metadata = const {},
  });

  String get summary {
    if (success) {
      return '✅ $title — ${outputPath ?? "completado"}';
    }
    return '⚠️ $title — ${error ?? "sin output"}';
  }
}

/// Resultado completo del pipeline de producción
class ProductionPipelineResult {
  final String projectPath;
  final String projectName;
  final List<ProductionStepResult> steps;
  final bool allSucceeded;
  final Duration totalDuration;
  final List<String> generatedAssets;
  final List<String> exportedFiles;

  const ProductionPipelineResult({
    required this.projectPath,
    required this.projectName,
    required this.steps,
    required this.allSucceeded,
    required this.totalDuration,
    required this.generatedAssets,
    required this.exportedFiles,
  });

  String get summary {
    final succeeded = steps.where((s) => s.success).length;
    return '🎬 Production Pipeline: $succeeded/${steps.length} pasos completados. '
        '${generatedAssets.length} assets generados, ${exportedFiles.length} archivos exportados.';
  }
}

/// Configuración del pipeline de producción
class ProductionConfig {
  /// Estilo musical (presets: funk80s, electronic, ambient, hiphop, rock)
  final String musicStyle;
  final int musicBpm;
  final int musicDurationSec;

  /// Template de animación (vertical-promo, horizontal-promo, screenshots)
  final String animationTemplate;

  /// Texto de narración para Voice Studio
  final String? narrationText;

  /// Idiomas de narración
  final List<String> narrationLanguages;

  /// Plataformas de exportación (vació = todas)
  final List<String> exportPlatforms;

  /// Volumen de música de fondo (0.0 - 1.0)
  final double musicVolume;

  const ProductionConfig({
    this.musicStyle = 'funk80s',
    this.musicBpm = 120,
    this.musicDurationSec = 30,
    this.animationTemplate = 'vertical-promo',
    this.narrationText,
    this.narrationLanguages = const ['es'],
    this.exportPlatforms = const [],
    this.musicVolume = 0.3,
  });

  static const defaults = ProductionConfig();
}

/// Agente 8: Production Pipeline — orquesta Music + Animation + Voice + Publisher
///
/// Se añade al PipelineRunner después de los 7 agentes INBOX.
/// Ejecuta los módulos de contenido en secuencia, generando assets
/// promocionales listos para redes sociales.
///
/// Callbacks para seguir el progreso:
///   void Function(String stepId, String status, double progress)
class ProductionPipelineAgent implements AgentInterface {
  @override
  String get agentId => 'production-pipeline';
  @override
  String get agentName => 'Production Pipeline';
  @override
  String get inboxStep => 'Content Studio';

  /// Configuración del pipeline (settable antes de ejecutar)
  ProductionConfig config;

  /// Callbacks de progreso
  void Function(String stepId, String status, double progress)? onProgress;

  ProductionPipelineAgent({
    this.config = const ProductionConfig(),
    this.onProgress,
  });

  @override
  Future<bool> canExecute(String projectPath) async {
    return Directory(projectPath).existsSync();
  }

  @override
  Future<AgentOutput> execute(String projectPath) async {
    final stopwatch = Stopwatch()..start();
    final projectName = projectPath.split(Platform.pathSeparator).last;
    final promoDir = Directory(p.join(projectPath, 'promo'));
    if (!await promoDir.exists()) {
      await promoDir.create(recursive: true);
    }

    final steps = <ProductionStepResult>[];
    final generatedAssets = <String>[];
    final exportedFiles = <String>[];

    // ── 1. Music Studio ────────────────────────────────────────
    _report('music', 'Generando música...', 0.1);
    final musicResult = await _generateMusic(projectPath, projectName, promoDir);
    steps.add(musicResult);
    if (musicResult.success && musicResult.outputPath != null) {
      generatedAssets.add(musicResult.outputPath!);
    }
    _report('music', musicResult.success ? 'Música lista' : 'Música falló', 0.25);

    // ── 2. Animation Studio ───────────────────────────────────
    _report('animation', 'Generando animación...', 0.35);
    final animResult = await _generateAnimation(projectPath, projectName, promoDir);
    steps.add(animResult);
    if (animResult.success && animResult.outputPath != null) {
      generatedAssets.add(animResult.outputPath!);
    }
    _report('animation', animResult.success ? 'Animación lista' : 'Animación falló', 0.55);

    // ── 3. Voice Studio ───────────────────────────────────────
    _report('voice', 'Generando narración...', 0.6);
    final voiceResult = await _generateNarration(projectPath, projectName, promoDir);
    steps.add(voiceResult);
    if (voiceResult.success && voiceResult.outputPath != null) {
      generatedAssets.add(voiceResult.outputPath!);
    }
    _report('voice', voiceResult.success ? 'Narración lista' : 'Narración falló', 0.75);

    // ── 4. Publisher (mix + export) ───────────────────────────
    _report('mix', 'Mezclando audio + video...', 0.8);
    final mixResult = await _mixContent(
      projectPath, projectName, promoDir,
      musicPath: musicResult.outputPath,
      videoPath: animResult.outputPath,
      narrationPath: voiceResult.outputPath,
    );
    steps.add(mixResult);

    _report('export', 'Exportando a redes...', 0.9);
    final exportResults = await _exportToPlatforms(
      projectPath, projectName, promoDir,
      mixedVideoPath: mixResult.outputPath,
      audioPath: musicResult.outputPath,
      narrationPath: voiceResult.outputPath,
    );
    for (final r in exportResults) {
      steps.add(r);
      if (r.success && r.outputPath != null) {
        exportedFiles.add(r.outputPath!);
      }
    }

    stopwatch.stop();

    final pipelineResult = ProductionPipelineResult(
      projectPath: projectPath,
      projectName: projectName,
      steps: steps,
      allSucceeded: steps.every((s) => s.success),
      totalDuration: stopwatch.elapsed,
      generatedAssets: generatedAssets,
      exportedFiles: exportedFiles,
    );

    return AgentOutput(
      agentId: agentId,
      success: pipelineResult.allSucceeded,
      summary: pipelineResult.summary,
      artifacts: [...generatedAssets, ...exportedFiles],
      data: {
        'projectName': projectName,
        'steps': steps.map((s) => {
          'id': s.stepId,
          'title': s.title,
          'success': s.success,
          'outputPath': s.outputPath,
          'error': s.error,
        }).toList(),
        'generatedAssets': generatedAssets,
        'exportedFiles': exportedFiles,
        'totalDurationSec': stopwatch.elapsed.inSeconds,
      },
    );
  }

  // ─── Music Studio ────────────────────────────────────────────

  Future<ProductionStepResult> _generateMusic(
    String projectPath,
    String projectName,
    Directory promoDir,
  ) async {
    try {
      final renderer = AudioRenderer();

      // Generar código Strudel desde la descripción del estilo
      final strudelCode = StrudelGenerator.generate(
        description: config.musicStyle,
        projectName: projectName,
        overrideBpm: config.musicBpm,
      );

      final outDir = Directory(p.join(promoDir.path, 'music'));
      await outDir.create(recursive: true);
      final outputPath = p.join(outDir.path, 'background.wav');

      // Intentar render con Tone.js, fallback a ffmpeg
      final result = await renderer.render(
        strudelCode: strudelCode,
        bpm: config.musicBpm,
        durationSec: config.musicDurationSec,
        outputPath: outputPath,
      );

      if (!result.success) {
        // Fallback a ffmpeg (genera un tono simple)
        final fallbackResult = await renderer.renderFallback(
          bpm: config.musicBpm,
          durationSec: config.musicDurationSec,
          outputPath: outputPath,
          style: config.musicStyle,
        );

        return ProductionStepResult(
          stepId: 'music',
          title: '🎵 Music Studio',
          success: fallbackResult.success,
          outputPath: fallbackResult.success ? outputPath : null,
          fileSizeBytes: fallbackResult.fileSize,
          duration: fallbackResult.duration,
          error: fallbackResult.success ? null : fallbackResult.error,
          metadata: {
            'style': config.musicStyle,
            'bpm': config.musicBpm,
            'fallback': true,
          },
        );
      }

      return ProductionStepResult(
        stepId: 'music',
        title: '🎵 Music Studio',
        success: result.success,
        outputPath: result.success ? outputPath : null,
        fileSizeBytes: result.fileSize,
        duration: result.duration,
        error: result.success ? null : result.error,
        metadata: {
          'style': config.musicStyle,
          'bpm': config.musicBpm,
          'renderer': renderer.status.name,
        },
      );
    } catch (e) {
      return ProductionStepResult(
        stepId: 'music',
        title: '🎵 Music Studio',
        success: false,
        error: e.toString(),
        metadata: {'style': config.musicStyle},
      );
    }
  }

  // ─── Animation Studio ────────────────────────────────────────

  Future<ProductionStepResult> _generateAnimation(
    String projectPath,
    String projectName,
    Directory promoDir,
  ) async {
    try {
      final renderer = VideoRenderer();
      final template = _findTemplate(config.animationTemplate);

      // Buscar design-engine para templates HTML
      final designEnginePath = _findDesignEngine(projectPath);
      String? htmlPath;

      if (designEnginePath != null) {
        final templatesDir = Directory(p.join(designEnginePath, 'templates'));
        if (await templatesDir.exists()) {
          // Verificar si existe el template solicitado
          final templateFile = File(p.join(templatesDir.path, template.file));
          if (await templateFile.exists()) {
            htmlPath = templateFile.path;
          }
        }
      }

      final outDir = Directory(p.join(promoDir.path, 'videos'));
      await outDir.create(recursive: true);
      final outputPath = p.join(outDir.path, '${template.suffix}.mp4');

      // Intentar render real
      if (htmlPath != null) {
        final result = await renderer.render(
          htmlPath: htmlPath,
          template: template,
          durationSec: config.musicDurationSec,
          outputPath: outputPath,
        );

        return ProductionStepResult(
          stepId: 'animation',
          title: '🎬 Animation Studio',
          success: result.success,
          outputPath: result.success ? outputPath : null,
          fileSizeBytes: result.fileSize,
          duration: result.duration,
          error: result.success ? null : result.error,
          metadata: {
            'template': template.id,
            'resolution': template.resolution,
          },
        );
      }

      // Fallback: generar video de color sólido con ffmpeg
      final fallbackResult = await renderer.renderFallback(
        outputPath: outputPath,
        durationSec: config.musicDurationSec,
        width: template.width,
        height: template.height,
      );

      return ProductionStepResult(
        stepId: 'animation',
        title: '🎬 Animation Studio',
        success: fallbackResult.success,
        outputPath: fallbackResult.success ? outputPath : null,
        fileSizeBytes: fallbackResult.fileSize,
        duration: fallbackResult.duration,
        error: 'Template no encontrado — fallback a color sólido',
        metadata: {
          'template': template.id,
          'resolution': template.resolution,
          'fallback': true,
        },
      );
    } catch (e) {
      return ProductionStepResult(
        stepId: 'animation',
        title: '🎬 Animation Studio',
        success: false,
        error: e.toString(),
        metadata: {'template': config.animationTemplate},
      );
    }
  }

  AnimationTemplate _findTemplate(String id) {
    for (final t in kAnimationTemplates) {
      if (t.id == id) return t;
    }
    return kAnimationTemplates.first; // default: vertical-promo
  }

  String? _findDesignEngine(String projectPath) {
    // Buscar design-engine relativo al proyecto
    final candidates = [
      p.join(projectPath, 'design-engine'),
      p.join(projectPath, '..', 'design-engine'),
      p.join(Directory.current.path, 'design-engine'),
    ];
    for (final candidate in candidates) {
      if (Directory(candidate).existsSync()) return candidate;
    }
    return null;
  }

  // ─── Voice Studio ───────────────────────────────────────────

  Future<ProductionStepResult> _generateNarration(
    String projectPath,
    String projectName,
    Directory promoDir,
  ) async {
    if (config.narrationText == null || config.narrationText!.isEmpty) {
      return const ProductionStepResult(
        stepId: 'voice',
        title: '🗣️ Voice Studio',
        success: true,
        error: 'Sin texto de narración — saltado',
        metadata: {'skipped': true},
      );
    }

    try {
      final service = VoiceService();
      final check = await service.checkAvailability();

      if (!check.allReady) {
        return ProductionStepResult(
          stepId: 'voice',
          title: '🗣️ Voice Studio',
          success: false,
          error: check.error ?? 'mmx o ffmpeg no disponible',
          metadata: {
            'mmxAvailable': check.mmxAvailable,
            'ffmpegAvailable': check.ffmpegAvailable,
          },
        );
      }

      // Generar narración en el primer idioma
      final lang = config.narrationLanguages.first;
      final narrationDir = Directory(p.join(promoDir.path, 'narration', lang));
      await narrationDir.create(recursive: true);
      final outputPath = p.join(narrationDir.path, 'narration_$lang.wav');

      final track = await service.synthesizeNarration(
        text: config.narrationText!,
        language: lang,
      );

      if (track != null) {
        // Copiar al outputPath deseado
        await File(track.filePath).copy(outputPath);

        return ProductionStepResult(
          stepId: 'voice',
          title: '🗣️ Voice Studio',
          success: true,
          outputPath: outputPath,
          fileSizeBytes: track.fileSize,
          duration: track.duration,
          metadata: {
            'language': lang,
            'textLength': config.narrationText!.length,
          },
        );
      }

      return ProductionStepResult(
        stepId: 'voice',
        title: '🗣️ Voice Studio',
        success: false,
        error: service.error ?? 'Error desconocido',
        metadata: {'language': lang},
      );
    } catch (e) {
      return ProductionStepResult(
        stepId: 'voice',
        title: '🗣️ Voice Studio',
        success: false,
        error: e.toString(),
        metadata: {'language': config.narrationLanguages.first},
      );
    }
  }

  // ─── Publisher (mix) ──────────────────────────────────────────

  Future<ProductionStepResult> _mixContent(
    String projectPath,
    String projectName,
    Directory promoDir, {
    String? musicPath,
    String? videoPath,
    String? narrationPath,
  }) async {
    if (videoPath == null || musicPath == null) {
      return const ProductionStepResult(
        stepId: 'mix',
        title: '📦 Media Mixer',
        success: false,
        error: 'Faltan assets para mezclar',
        metadata: {'skipped': true},
      );
    }

    try {
      final mixer = MediaMixer();
      final renderDir = Directory(p.join(promoDir.path, 'render'));
      await renderDir.create(recursive: true);
      final outputPath = p.join(renderDir.path, 'mixed.mp4');

      final result = await mixer.mixAudioVideo(
        videoPath: videoPath,
        audioPath: musicPath,
        narrationPath: narrationPath,
        outputPath: outputPath,
        volumeMusic: config.musicVolume,
      );

      return ProductionStepResult(
        stepId: 'mix',
        title: '📦 Media Mixer',
        success: result.success,
        outputPath: result.success ? outputPath : null,
        fileSizeBytes: result.fileSize,
        duration: result.duration,
        error: result.success ? null : result.error,
        metadata: {'volumeMusic': config.musicVolume},
      );
    } catch (e) {
      return ProductionStepResult(
        stepId: 'mix',
        title: '📦 Media Mixer',
        success: false,
        error: e.toString(),
      );
    }
  }

  // ─── Publisher (export) ──────────────────────────────────────

  Future<List<ProductionStepResult>> _exportToPlatforms(
    String projectPath,
    String projectName,
    Directory promoDir, {
    String? mixedVideoPath,
    String? audioPath,
    String? narrationPath,
  }) async {
    if (mixedVideoPath == null || audioPath == null) {
      return [
        const ProductionStepResult(
          stepId: 'export',
          title: '📤 Export to Networks',
          success: false,
          error: 'Faltan assets mezclados para exportar',
          metadata: {'skipped': true},
        ),
      ];
    }

    final results = <ProductionStepResult>[];
    final platforms = config.exportPlatforms.isEmpty
        ? ['tiktok', 'youtube', 'instagram', 'facebook', 'twitch', 'x']
        : config.exportPlatforms;

    final mixer = MediaMixer();

    for (final platform in platforms) {
      final format = _findPlatformFormat(platform);
      if (format == null) continue;

      final exportDir = Directory(p.join(promoDir.path, 'export'));
      await exportDir.create(recursive: true);
      final outputPath = p.join(exportDir.path, 'promo-${format.suffix}.mp4');

      final result = await mixer.renderForPlatform(
        videoPath: mixedVideoPath,
        audioPath: audioPath,
        format: format,
        narrationPath: narrationPath,
        outputPath: outputPath,
      );

      results.add(ProductionStepResult(
        stepId: 'export-$platform',
        title: '📤 Export $platform',
        success: result.success,
        outputPath: result.success ? outputPath : null,
        fileSizeBytes: result.fileSize,
        duration: result.duration,
        error: result.success ? null : result.error,
        metadata: {
          'platform': platform,
          'resolution': format.resolution,
        },
      ));
    }

    return results;
  }

  PlatformFormat? _findPlatformFormat(String name) {
    for (final f in kPlatformFormats) {
      if (f.name == name) return f;
    }
    return null;
  }

  // ─── Helpers ─────────────────────────────────────────────────

  void _report(String stepId, String status, double progress) {
    onProgress?.call(stepId, status, progress);
  }
}

// Alias para compatibilidad con código existente
typedef ProductionAgent = ProductionPipelineAgent;