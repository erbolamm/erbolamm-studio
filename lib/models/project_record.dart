import 'dart:convert';

// ═══════════════════════════════════════════════════════════════
// 📋 ProjectRecord — Registro completo de un proyecto
// ═══════════════════════════════════════════════════════════════
// Schema completo para el Project Registry (Fase 1 del PLAN).
// Reemplaza al básico RepoAnalysis y cubre:
//   - Identificación (id, owner, name, url)
//   - Clasificación (type, techStack, language)
//   - Estado de patrón (patternVersion, patternCompliant, violations)
//   - Salud (lastCommit, lastAnalyzed, versions)
//   - Cobertura de contenido (README, LICENSE, screenshots, etc.)
//   - Metadata (isOwned, isPublic, license, topics)
// ═══════════════════════════════════════════════════════════════

/// Tipo de proyecto según su naturaleza
enum ProjectType {
  app,
  extension,
  website,
  package,
  workflow,
  other;

  String get label {
    switch (this) {
      case ProjectType.app:
        return 'App';
      case ProjectType.extension:
        return 'Extensión';
      case ProjectType.website:
        return 'Sitio Web';
      case ProjectType.package:
        return 'Paquete';
      case ProjectType.workflow:
        return 'Workflow';
      case ProjectType.other:
        return 'Otro';
    }
  }

  static ProjectType fromString(String? value) {
    if (value == null) return ProjectType.other;
    return ProjectType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ProjectType.other,
    );
  }
}

/// Stack tecnológico principal
enum TechStack {
  flutter,
  react,
  vue,
  svelte,
  vscode,
  blogger,
  n8n,
  nodejs,
  python,
  dart,
  go,
  rust,
  other;

  String get label {
    switch (this) {
      case TechStack.flutter:
        return 'Flutter';
      case TechStack.react:
        return 'React';
      case TechStack.vue:
        return 'Vue';
      case TechStack.svelte:
        return 'Svelte';
      case TechStack.vscode:
        return 'VS Code Extension';
      case TechStack.blogger:
        return 'Blogger';
      case TechStack.n8n:
        return 'n8n Workflow';
      case TechStack.nodejs:
        return 'Node.js';
      case TechStack.python:
        return 'Python';
      case TechStack.dart:
        return 'Dart';
      case TechStack.go:
        return 'Go';
      case TechStack.rust:
        return 'Rust';
      case TechStack.other:
        return 'Otro';
    }
  }

  static TechStack fromString(String? value) {
    if (value == null) return TechStack.other;
    return TechStack.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => TechStack.other,
    );
  }
}

/// Registro completo de un proyecto en el registry
class ProjectRecord {
  // ─── Identificación ──────────────────────────────────────────
  final String id; // UUID
  final String owner;
  final String name;
  final String url;

  // ─── Clasificación ────────────────────────────────────────────
  final ProjectType type;
  final TechStack techStack;
  final String? language;

  // ─── Estado de patrón ────────────────────────────────────────
  final String? patternVersion;
  final bool patternCompliant;
  final List<String> patternViolations;

  // ─── Salud del proyecto ──────────────────────────────────────
  final DateTime? lastCommitAt;
  final DateTime? lastAnalyzedAt;
  final String? currentVersions; // "Flutter:3.19, pnpm:8.0"
  final String? latestVersions; // versiones disponibles

  // ─── Cobertura de contenido ────────────────────────────────
  final bool hasReadme;
  final bool hasLicense;
  final bool hasScreenshots;
  final bool hasVideo;
  final bool hasLanding;
  final bool hasBrandSpec;

  // ─── Metadata adicional ─────────────────────────────────────
  final bool isOwned; // ¿Es suyo?
  final bool isPublic; // ¿Es público en GitHub?
  final String? license; // MIT, Apache...
  final List<String> topics;
  final String? description;
  final DateTime addedAt;
  final DateTime updatedAt;

  ProjectRecord({
    required this.id,
    required this.owner,
    required this.name,
    required this.url,
    this.type = ProjectType.app,
    this.techStack = TechStack.other,
    this.language,
    this.patternVersion,
    this.patternCompliant = false,
    this.patternViolations = const [],
    this.lastCommitAt,
    this.lastAnalyzedAt,
    this.currentVersions,
    this.latestVersions,
    this.hasReadme = false,
    this.hasLicense = false,
    this.hasScreenshots = false,
    this.hasVideo = false,
    this.hasLanding = false,
    this.hasBrandSpec = false,
    this.isOwned = true,
    this.isPublic = true,
    this.license,
    this.topics = const [],
    this.description,
    DateTime? addedAt,
    DateTime? updatedAt,
  }) : addedAt = addedAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // ─── Health derivada ─────────────────────────────────────────

  bool get needsAttention {
    if (lastAnalyzedAt == null) return true;
    return DateTime.now().difference(lastAnalyzedAt!).inDays > 30;
  }

  bool get isMissingCriticalFiles => !hasReadme || !hasLicense;

  double get coverageScore {
    int total = 0;
    if (hasReadme) total++;
    if (hasLicense) total++;
    if (hasScreenshots) total++;
    if (hasVideo) total++;
    if (hasLanding) total++;
    if (hasBrandSpec) total++;
    return total / 6.0;
  }

  // ─── Map serialization (SQLite) ─────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner': owner,
      'name': name,
      'url': url,
      'type': type.name,
      'techStack': techStack.name,
      'language': language,
      'patternVersion': patternVersion,
      'patternCompliant': patternCompliant ? 1 : 0,
      'patternViolations': jsonEncode(patternViolations),
      'lastCommitAt': lastCommitAt?.toIso8601String(),
      'lastAnalyzedAt': lastAnalyzedAt?.toIso8601String(),
      'currentVersions': currentVersions,
      'latestVersions': latestVersions,
      'hasReadme': hasReadme ? 1 : 0,
      'hasLicense': hasLicense ? 1 : 0,
      'hasScreenshots': hasScreenshots ? 1 : 0,
      'hasVideo': hasVideo ? 1 : 0,
      'hasLanding': hasLanding ? 1 : 0,
      'hasBrandSpec': hasBrandSpec ? 1 : 0,
      'isOwned': isOwned ? 1 : 0,
      'isPublic': isPublic ? 1 : 0,
      'license': license,
      'topics': jsonEncode(topics),
      'description': description,
      'addedAt': addedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProjectRecord.fromMap(Map<String, dynamic> map) {
    final violations = _parseStringList(map['patternViolations'], '||');
    final topics = _parseStringList(map['topics'], ',');

    return ProjectRecord(
      id: map['id'] as String,
      owner: map['owner'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      type: ProjectType.fromString(map['type'] as String?),
      techStack: TechStack.fromString(map['techStack'] as String?),
      language: map['language'] as String?,
      patternVersion: map['patternVersion'] as String?,
      patternCompliant: map['patternCompliant'] == 1,
      patternViolations: violations,
      lastCommitAt: _parseDate(map['lastCommitAt'] as String?),
      lastAnalyzedAt: _parseDate(map['lastAnalyzedAt'] as String?),
      currentVersions: map['currentVersions'] as String?,
      latestVersions: map['latestVersions'] as String?,
      hasReadme: map['hasReadme'] == 1,
      hasLicense: map['hasLicense'] == 1,
      hasScreenshots: map['hasScreenshots'] == 1,
      hasVideo: map['hasVideo'] == 1,
      hasLanding: map['hasLanding'] == 1,
      hasBrandSpec: map['hasBrandSpec'] == 1,
      isOwned: map['isOwned'] == 1,
      isPublic: map['isPublic'] == 1,
      license: map['license'] as String?,
      topics: topics,
      description: map['description'] as String?,
      addedAt: DateTime.parse(map['addedAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  static List<String> _parseStringList(Object? value, String separator) {
    if (value == null || value.toString().isEmpty) return const [];
    final text = value.toString();
    if (text.trimLeft().startsWith('[')) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is List) {
          return decoded.map((item) => item.toString()).toList();
        }
      } on FormatException {
        // Fall back to legacy delimiter decoding.
      }
    }
    return text.split(separator).where((item) => item.isNotEmpty).toList();
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  // ─── CopyWith ────────────────────────────────────────────────

  ProjectRecord copyWith({
    String? id,
    String? owner,
    String? name,
    String? url,
    ProjectType? type,
    TechStack? techStack,
    String? language,
    String? patternVersion,
    bool? patternCompliant,
    List<String>? patternViolations,
    DateTime? lastCommitAt,
    DateTime? lastAnalyzedAt,
    String? currentVersions,
    String? latestVersions,
    bool? hasReadme,
    bool? hasLicense,
    bool? hasScreenshots,
    bool? hasVideo,
    bool? hasLanding,
    bool? hasBrandSpec,
    bool? isOwned,
    bool? isPublic,
    String? license,
    List<String>? topics,
    String? description,
    DateTime? addedAt,
    DateTime? updatedAt,
  }) {
    return ProjectRecord(
      id: id ?? this.id,
      owner: owner ?? this.owner,
      name: name ?? this.name,
      url: url ?? this.url,
      type: type ?? this.type,
      techStack: techStack ?? this.techStack,
      language: language ?? this.language,
      patternVersion: patternVersion ?? this.patternVersion,
      patternCompliant: patternCompliant ?? this.patternCompliant,
      patternViolations: patternViolations ?? this.patternViolations,
      lastCommitAt: lastCommitAt ?? this.lastCommitAt,
      lastAnalyzedAt: lastAnalyzedAt ?? this.lastAnalyzedAt,
      currentVersions: currentVersions ?? this.currentVersions,
      latestVersions: latestVersions ?? this.latestVersions,
      hasReadme: hasReadme ?? this.hasReadme,
      hasLicense: hasLicense ?? this.hasLicense,
      hasScreenshots: hasScreenshots ?? this.hasScreenshots,
      hasVideo: hasVideo ?? this.hasVideo,
      hasLanding: hasLanding ?? this.hasLanding,
      hasBrandSpec: hasBrandSpec ?? this.hasBrandSpec,
      isOwned: isOwned ?? this.isOwned,
      isPublic: isPublic ?? this.isPublic,
      license: license ?? this.license,
      topics: topics ?? this.topics,
      description: description ?? this.description,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── String representation ───────────────────────────────────

  @override
  String toString() {
    return 'ProjectRecord(id: $id, name: $name, owner: $owner, '
        'type: ${type.label}, techStack: ${techStack.label})';
  }
}
