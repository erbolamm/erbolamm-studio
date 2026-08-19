// ═══════════════════════════════════════════════════════════════
// 🌐 PublicProjectRecord — Contrato público para Universo
// ═══════════════════════════════════════════════════════════════
// Solo los campos allowlisted definidos en el spec
// public-project-registry. Este modelo es la proyección
// pública de un ProjectRecord, no su reemplazo.
// ═══════════════════════════════════════════════════════════════

/// Proyección pública de un proyecto para publicación en Universo.
///
/// Contiene exclusivamente los campos allowlisted. Campos internos
/// de análisis, metadata privada del owner, paths locales y secretos
/// quedan fuera de este modelo.
class PublicProjectRecord {
  final String id;
  final String label;
  final String subtitle;
  final String url;
  final String
  type; // "app", "extension", "website", "package", "workflow", "other"
  final String status; // solo "published" es proyectable
  final String pillar;
  final String emoji;
  final String color;
  final int size;
  final Map<String, dynamic>? stats;

  const PublicProjectRecord({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.url,
    this.type = 'other',
    this.status = 'draft',
    this.pillar = 'tools',
    this.emoji = '📦',
    this.color = '#7C3AED',
    this.size = 1,
    this.stats,
  });

  /// Convierte a Map para escritura en Firestore.
  /// Los campos null se omiten para no ensuciar el documento.
  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{
      'id': id,
      'label': label,
      'subtitle': subtitle,
      'url': url,
      'type': type,
      'status': status,
      'pillar': pillar,
      'emoji': emoji,
      'color': color,
      'size': size,
    };

    if (stats != null && stats!.isNotEmpty) {
      data['stats'] = stats;
    }

    return data;
  }

  factory PublicProjectRecord.fromFirestore(Map<String, dynamic> map) {
    return PublicProjectRecord(
      id: map['id'] as String,
      label: map['label'] as String,
      subtitle: map['subtitle'] as String,
      url: map['url'] as String,
      type: (map['type'] as String?) ?? 'other',
      status: (map['status'] as String?) ?? 'draft',
      pillar: (map['pillar'] as String?) ?? 'tools',
      emoji: (map['emoji'] as String?) ?? '📦',
      color: (map['color'] as String?) ?? '#7C3AED',
      size: (map['size'] as int?) ?? 1,
      stats: map['stats'] as Map<String, dynamic>?,
    );
  }

  /// Devuelve true si el documento está listo para proyección pública.
  bool get isProjectable => status == 'published';

  @override
  String toString() {
    return 'PublicProjectRecord(id: $id, label: $label, status: $status, '
        'type: $type, pillar: $pillar)';
  }
}
