import '../../models/project_record.dart' as project_record;
import '../../models/public_project_record.dart';
import '../../models/repo_analysis.dart' as repo_analysis;

project_record.ProjectRecord projectRecordFromAnalysis(
  repo_analysis.RepoAnalysis analysis,
) {
  return project_record.ProjectRecord(
    id: projectRecordIdFromAnalysis(analysis),
    owner: analysis.owner,
    name: analysis.name,
    url: analysis.url,
    type: projectTypeFromAnalysis(analysis.projectType),
    techStack: project_record.TechStack.other,
    language: analysis.language,
    patternCompliant: analysis.missingItems.isEmpty,
    patternViolations: analysis.missingItems,
    lastAnalyzedAt: analysis.analyzedAt,
    hasReadme: analysis.hasReadme,
    hasLicense: analysis.hasLicense,
    hasScreenshots: analysis.hasScreenshots,
    hasVideo: analysis.hasVideo,
    hasLanding: analysis.hasLanding,
    hasBrandSpec: analysis.hasBrandSpec,
    topics: analysis.topics,
    description: analysis.description,
    isOwned: analysis.owner != 'local',
    isPublic: true,
  );
}

String projectRecordIdFromAnalysis(repo_analysis.RepoAnalysis analysis) {
  return '${_slugPart(analysis.owner)}--${_slugPart(analysis.name)}';
}

String _slugPart(String value) {
  final slug = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  return slug.isEmpty ? 'unknown' : slug;
}

project_record.ProjectType projectTypeFromAnalysis(
  repo_analysis.ProjectType source,
) {
  switch (source) {
    case repo_analysis.ProjectType.flutterApp:
    case repo_analysis.ProjectType.flutterPackage:
      return project_record.ProjectType.app;
    case repo_analysis.ProjectType.vscodeExtension:
      return project_record.ProjectType.extension;
    case repo_analysis.ProjectType.react:
    case repo_analysis.ProjectType.node:
      return project_record.ProjectType.website;
    case repo_analysis.ProjectType.python:
      return project_record.ProjectType.other;
    case repo_analysis.ProjectType.n8nWorkflow:
      return project_record.ProjectType.workflow;
    case repo_analysis.ProjectType.blogger:
      return project_record.ProjectType.website;
    case repo_analysis.ProjectType.unknown:
      return project_record.ProjectType.other;
  }
}

/// Convierte un [ProjectRecord] local en un [PublicProjectRecord]
/// con solo los campos allowlisted para publicación en Universo.
///
/// Los valores de pillar, emoji, color se asignan con defaults
/// razonables; el caller puede ajustarlos antes de publicar.
PublicProjectRecord publicRecordFromProjectRecord(
  project_record.ProjectRecord record,
) {
  return PublicProjectRecord(
    id: record.id,
    label: record.name,
    subtitle: record.description ?? '${record.owner}/${record.name}',
    url: record.url,
    type: _publicTypeFromProjectType(record.type),
    status: 'published',
    pillar: _pillarFromProjectType(record.type),
    emoji: _emojiFromProjectType(record.type),
    color: '#7C3AED',
    size: 1,
  );
}

String _publicTypeFromProjectType(project_record.ProjectType type) {
  switch (type) {
    case project_record.ProjectType.app:
      return 'app';
    case project_record.ProjectType.extension:
      return 'extension';
    case project_record.ProjectType.website:
      return 'website';
    case project_record.ProjectType.package:
      return 'package';
    case project_record.ProjectType.workflow:
      return 'workflow';
    case project_record.ProjectType.other:
      return 'other';
  }
}

String _pillarFromProjectType(project_record.ProjectType type) {
  switch (type) {
    case project_record.ProjectType.app:
      return 'apps';
    case project_record.ProjectType.extension:
      return 'tools';
    case project_record.ProjectType.website:
      return 'web';
    case project_record.ProjectType.package:
      return 'tools';
    case project_record.ProjectType.workflow:
      return 'automation';
    case project_record.ProjectType.other:
      return 'tools';
  }
}

String _emojiFromProjectType(project_record.ProjectType type) {
  switch (type) {
    case project_record.ProjectType.app:
      return '📱';
    case project_record.ProjectType.extension:
      return '🧩';
    case project_record.ProjectType.website:
      return '🌐';
    case project_record.ProjectType.package:
      return '📦';
    case project_record.ProjectType.workflow:
      return '⚡';
    case project_record.ProjectType.other:
      return '📦';
  }
}
