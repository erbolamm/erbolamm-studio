// ═══════════════════════════════════════════════════════════════
// 🎬 Animation Template — Modelos de templates animados
// ═══════════════════════════════════════════════════════════════

/// Un template de animación
class AnimationTemplate {
  final String id;
  final String name;
  final String description;
  final IconType iconType;
  final String file; // nombre del archivo HTML
  final int width;
  final int height;
  final int defaultDurationSec;
  final bool hasNarration;

  const AnimationTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.iconType,
    required this.file,
    required this.width,
    required this.height,
    required this.defaultDurationSec,
    this.hasNarration = false,
  });

  String get resolution => '${width}x$height';
  String get suffix => width > height ? 'horizontal' : 'vertical';
}

enum IconType { phone, desktop, camera }

/// Templates predefinidos
const List<AnimationTemplate> kAnimationTemplates = [
  AnimationTemplate(
    id: 'vertical-promo',
    name: 'Vertical Promo',
    description: '1080×1920 — TikTok, Reels, Shorts',
    iconType: IconType.phone,
    file: 'vertical-promo.html',
    width: 1080,
    height: 1920,
    defaultDurationSec: 22,
  ),
  AnimationTemplate(
    id: 'horizontal-promo',
    name: 'Horizontal Promo',
    description: '1920×1080 — YouTube, Facebook',
    iconType: IconType.desktop,
    file: 'horizontal-promo.html',
    width: 1920,
    height: 1080,
    defaultDurationSec: 30,
  ),
  AnimationTemplate(
    id: 'screenshots',
    name: 'Screenshots',
    description: 'Capturas de componentes',
    iconType: IconType.camera,
    file: 'screenshots.html',
    width: 1920,
    height: 1080,
    defaultDurationSec: 10,
  ),
];

/// Resultado de renderizado de video
class VideoRenderResult {
  final String outputPath;
  final int fileSize;
  final Duration duration;
  final bool success;
  final String? error;

  const VideoRenderResult({
    required this.outputPath,
    required this.fileSize,
    required this.duration,
    required this.success,
    this.error,
  });
}

/// Información de un template en el proyecto
class ProjectTemplate {
  final AnimationTemplate template;
  final bool htmlExists;
  final String? htmlPath;
  final String? videoPath;

  const ProjectTemplate({
    required this.template,
    required this.htmlExists,
    this.htmlPath,
    this.videoPath,
  });
}
