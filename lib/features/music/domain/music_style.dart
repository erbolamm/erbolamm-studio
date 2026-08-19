// ═══════════════════════════════════════════════════════════════
// 🎵 Music Style — Modelos de estilos musicales
// ═══════════════════════════════════════════════════════════════

/// Un estilo musical generado
class MusicStyle {
  final String id;
  final String description;
  final int bpm;
  final String strudelCode;
  final DateTime createdAt;
  final String? audioPath;
  final String? projectName;
  final Duration? audioDuration;

  const MusicStyle({
    required this.id,
    required this.description,
    required this.bpm,
    required this.strudelCode,
    required this.createdAt,
    this.audioPath,
    this.projectName,
    this.audioDuration,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'bpm': bpm,
    'strudelCode': strudelCode,
    'createdAt': createdAt.toIso8601String(),
    'audioPath': audioPath,
    'projectName': projectName,
    'audioDurationMs': audioDuration?.inMilliseconds,
  };

  factory MusicStyle.fromJson(Map<String, dynamic> json) => MusicStyle(
    id: json['id'] as String,
    description: json['description'] as String? ?? '',
    bpm: json['bpm'] as int? ?? 120,
    strudelCode: json['strudelCode'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    audioPath: json['audioPath'] as String?,
    projectName: json['projectName'] as String?,
    audioDuration: json['audioDurationMs'] != null
        ? Duration(milliseconds: json['audioDurationMs'] as int)
        : null,
  );
}

/// Parámetros de generación de audio
class AudioRenderParams {
  final String strudelCode;
  final int bpm;
  final int durationSec;
  final String outputPath;

  const AudioRenderParams({
    required this.strudelCode,
    required this.bpm,
    required this.durationSec,
    required this.outputPath,
  });
}

/// Resultado de renderizado de audio
class AudioRenderResult {
  final String outputPath;
  final int fileSize;
  final Duration duration;
  final bool success;
  final String? error;

  const AudioRenderResult({
    required this.outputPath,
    required this.fileSize,
    required this.duration,
    required this.success,
    this.error,
  });
}
