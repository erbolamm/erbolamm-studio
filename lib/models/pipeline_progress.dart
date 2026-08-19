// ═══════════════════════════════════════════════════════════════
// 📊 Pipeline Progress — Estado del Proyecto Activo
// ═══════════════════════════════════════════════════════════════
// Calcula y expone los indicadores de progreso (verde, amarillo,
// gris) para cada módulo en el NavigationRail según los artefactos
// presentes en el sistema de archivos del proyecto.
// ═══════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:path/path.dart' as p;

enum ModuleStatus {
  completed, // 🟢 Completado con éxito
  warning,   // 🟡 Parcial o requiere atención
  pending,   // ⚪ Pendiente / No iniciado
  disabled,  // 🔘 No aplicable
}

class PipelineProgress {
  final ModuleStatus analyzer;
  final ModuleStatus orchestrator;
  final ModuleStatus voice;
  final ModuleStatus market;
  final ModuleStatus music;
  final ModuleStatus animation;
  final ModuleStatus publisher;
  final ModuleStatus terminal;

  const PipelineProgress({
    this.analyzer = ModuleStatus.pending,
    this.orchestrator = ModuleStatus.pending,
    this.voice = ModuleStatus.pending,
    this.market = ModuleStatus.pending,
    this.music = ModuleStatus.pending,
    this.animation = ModuleStatus.pending,
    this.publisher = ModuleStatus.pending,
    this.terminal = ModuleStatus.pending,
  });

  /// Evalúa en tiempo real los artefactos del proyecto en disco
  static PipelineProgress evaluate(String? projectPath) {
    if (projectPath == null || !Directory(projectPath).existsSync()) {
      return const PipelineProgress();
    }

    final studioPath = Directory(p.join(projectPath, 'erbolamm-studio')).existsSync()
        ? p.join(projectPath, 'erbolamm-studio')
        : p.join(projectPath, 'promo');
    final hasStudio = Directory(studioPath).existsSync();
    final hasReadme = File(p.join(projectPath, 'README.md')).existsSync();
    final hasLicense = File(p.join(projectPath, 'LICENSE')).existsSync();

    // 1. Analyzer: Verde si tiene README y LICENSE, Amarillo si solo README
    final analyzerStatus = (hasReadme && hasLicense)
        ? ModuleStatus.completed
        : (hasReadme ? ModuleStatus.warning : ModuleStatus.pending);

    // 2. Orchestrator: Verde si erbolamm-studio/ contiene brand-spec.md y copy-pack.md
    final hasBrandSpec = File(p.join(studioPath, 'brand-spec.md')).existsSync();
    final hasCopyPack = File(p.join(studioPath, 'copy-pack.md')).existsSync();
    final orchestratorStatus = (hasStudio && hasBrandSpec)
        ? ModuleStatus.completed
        : (hasStudio ? ModuleStatus.warning : ModuleStatus.pending);

    // 3. Voice: Verde si hay audios generados y video, Amarillo si solo hay audios
    final audioDir = Directory(p.join(studioPath, 'audio'));
    final narrationDir = Directory(p.join(studioPath, 'narration'));
    final hasAudios = (audioDir.existsSync() &&
            audioDir.listSync().where((f) => f.path.endsWith('.wav') || f.path.endsWith('.mp3')).isNotEmpty) ||
        (narrationDir.existsSync() &&
            narrationDir.listSync().where((f) => f.path.endsWith('.wav') || f.path.endsWith('.mp3')).isNotEmpty);

    final videosDir = Directory(p.join(studioPath, 'videos'));
    final hasVideos = videosDir.existsSync() &&
        videosDir.listSync().where((f) => f.path.endsWith('.mp4')).isNotEmpty;

    final voiceStatus = (hasAudios && hasVideos)
        ? ModuleStatus.completed
        : (hasAudios ? ModuleStatus.warning : ModuleStatus.pending);

    // 4. Market: Verde si existe análisis de mercado o copy-pack
    final hasMarketNotes = File(p.join(studioPath, 'market-analysis.md')).existsSync() || hasCopyPack;
    final marketStatus = hasMarketNotes ? ModuleStatus.completed : ModuleStatus.pending;

    // 5. Music: Verde si hay audio de música de fondo, Amarillo si hay studio pero sin música
    final hasMusicFile = File(p.join(studioPath, 'audio', 'bg_music.mp3')).existsSync() ||
        File(p.join(studioPath, 'audio', 'music.mp3')).existsSync() ||
        File(p.join(studioPath, 'audio', 'background.wav')).existsSync();
    final musicStatus = hasMusicFile
        ? ModuleStatus.completed
        : (hasStudio ? ModuleStatus.warning : ModuleStatus.pending);

    // 6. Animation: Verde si hay videos renderizados, Amarillo si hay carpeta source/
    final hasAnimationSource = Directory(p.join(studioPath, 'source')).existsSync();
    final animationStatus = hasVideos
        ? ModuleStatus.completed
        : (hasAnimationSource ? ModuleStatus.warning : ModuleStatus.pending);

    // 7. Publisher: Verde si hay landing y capturas generadas
    final hasLanding = File(p.join(studioPath, 'landing.html')).existsSync() ||
        File(p.join(projectPath, 'landing.html')).existsSync() ||
        File(p.join(projectPath, 'web', 'index.html')).existsSync();

    final screenshotsDir = Directory(p.join(studioPath, 'screenshots'));
    final hasScreenshots = screenshotsDir.existsSync() &&
        screenshotsDir.listSync(recursive: true).whereType<File>().isNotEmpty;

    final publisherStatus = (hasLanding && hasScreenshots)
        ? ModuleStatus.completed
        : (hasLanding || hasScreenshots ? ModuleStatus.warning : ModuleStatus.pending);

    // 8. Terminal: Siempre activo y disponible si el proyecto existe
    final terminalStatus = ModuleStatus.completed;

    return PipelineProgress(
      analyzer: analyzerStatus,
      orchestrator: orchestratorStatus,
      voice: voiceStatus,
      market: marketStatus,
      music: musicStatus,
      animation: animationStatus,
      publisher: publisherStatus,
      terminal: terminalStatus,
    );
  }
}
