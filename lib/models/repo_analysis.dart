enum ProjectType {
  flutterApp,
  flutterPackage,
  react,
  node,
  python,
  vscodeExtension,
  blogger,
  n8nWorkflow,
  unknown,
}

extension ProjectTypeExtension on ProjectType {
  String get label {
    switch (this) {
      case ProjectType.flutterApp:
        return 'Flutter App';
      case ProjectType.flutterPackage:
        return 'Flutter Package';
      case ProjectType.react:
        return 'React';
      case ProjectType.node:
        return 'Node.js';
      case ProjectType.python:
        return 'Python';
      case ProjectType.vscodeExtension:
        return 'VS Code Extension';
      case ProjectType.blogger:
        return 'Blogger';
      case ProjectType.n8nWorkflow:
        return 'n8n Workflow';
      case ProjectType.unknown:
        return 'Desconocido';
    }
  }

  String get icon {
    switch (this) {
      case ProjectType.flutterApp:
      case ProjectType.flutterPackage:
        return '🦋';
      case ProjectType.react:
        return '⚛️';
      case ProjectType.node:
        return '🟢';
      case ProjectType.python:
        return '🐍';
      case ProjectType.vscodeExtension:
        return '📦';
      case ProjectType.blogger:
        return '📝';
      case ProjectType.n8nWorkflow:
        return '🔗';
      case ProjectType.unknown:
        return '❓';
    }
  }
}

class RepoAnalysis {
  final String owner;
  final String name;
  final String url;
  final String? description;
  final String? language;
  final List<String> topics;
  final ProjectType projectType;
  final bool hasReadme;
  final bool hasLicense;
  final bool hasPromoFolder;
  final bool hasScreenshots;
  final bool hasVideo;
  final bool hasLanding;
  final String? landingUrl;
  final bool hasBrandSpec;
  final List<String> missingItems;
  final DateTime analyzedAt;

  RepoAnalysis({
    required this.owner,
    required this.name,
    required this.url,
    this.description,
    this.language,
    this.topics = const [],
    this.projectType = ProjectType.unknown,
    this.hasReadme = false,
    this.hasLicense = false,
    this.hasPromoFolder = false,
    this.hasScreenshots = false,
    this.hasVideo = false,
    this.hasLanding = false,
    this.landingUrl,
    this.hasBrandSpec = false,
    this.missingItems = const [],
    DateTime? analyzedAt,
  }) : analyzedAt = analyzedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'owner': owner,
      'name': name,
      'url': url,
      'description': description,
      'language': language,
      'topics': topics.join(','),
      'projectType': projectType.name,
      'hasReadme': hasReadme ? 1 : 0,
      'hasLicense': hasLicense ? 1 : 0,
      'hasPromoFolder': hasPromoFolder ? 1 : 0,
      'hasScreenshots': hasScreenshots ? 1 : 0,
      'hasVideo': hasVideo ? 1 : 0,
      'hasLanding': hasLanding ? 1 : 0,
      'landingUrl': landingUrl,
      'hasBrandSpec': hasBrandSpec ? 1 : 0,
      'missingItems': missingItems.join('||'),
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  factory RepoAnalysis.fromMap(Map<String, dynamic> map) {
    return RepoAnalysis(
      owner: map['owner'],
      name: map['name'],
      url: map['url'],
      description: map['description'],
      language: map['language'],
      topics: map['topics']?.toString().split(',') ?? [],
      projectType: ProjectType.values.firstWhere(
        (e) => e.name == map['projectType'],
        orElse: () => ProjectType.unknown,
      ),
      hasReadme: map['hasReadme'] == 1,
      hasLicense: map['hasLicense'] == 1,
      hasPromoFolder: map['hasPromoFolder'] == 1,
      hasScreenshots: map['hasScreenshots'] == 1,
      hasVideo: map['hasVideo'] == 1,
      hasLanding: map['hasLanding'] == 1,
      landingUrl: map['landingUrl'],
      hasBrandSpec: map['hasBrandSpec'] == 1,
      missingItems: map['missingItems']?.toString().split('||') ?? [],
      analyzedAt: DateTime.parse(map['analyzedAt']),
    );
  }
}
