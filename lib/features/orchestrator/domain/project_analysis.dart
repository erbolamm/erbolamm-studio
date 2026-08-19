// ═══════════════════════════════════════════════════════════════
// 📋 ProjectAnalysis — Resultado del Agente 1: Analizador
// ═══════════════════════════════════════════════════════════════
// Modelo de datos con el análisis completo de un proyecto local.
// Sigue el esquema del Paso 1 de INBOX.md.
// ═══════════════════════════════════════════════════════════════

/// Tipo de proyecto detectado
enum ProjectType {
  flutterApp,
  dartPackage,
  vsCodeExtension,
  webHtml,
  nodePackage,
  pythonProject,
  exerciseDart,
  hardware,
  unknown;

  String get label {
    switch (this) {
      case ProjectType.flutterApp: return 'App Flutter';
      case ProjectType.dartPackage: return 'Paquete Dart/Flutter';
      case ProjectType.vsCodeExtension: return 'Extensión VS Code';
      case ProjectType.webHtml: return 'Web HTML/JS';
      case ProjectType.nodePackage: return 'Paquete Node.js';
      case ProjectType.pythonProject: return 'Proyecto Python';
      case ProjectType.exerciseDart: return 'Ejercicio Dart';
      case ProjectType.hardware: return 'Dispositivo / Hardware';
      case ProjectType.unknown: return 'Tipo no identificado';
    }
  }
}

/// Nivel de completitud del proyecto
enum Completeness {
  functional,
  partial,
  skeleton,
  broken;

  String get label {
    switch (this) {
      case Completeness.functional: return '✅ Funcional — compila y funciona';
      case Completeness.partial: return '🟡 A medias — código parcial';
      case Completeness.skeleton: return '⬜ Esqueleto — solo estructura';
      case Completeness.broken: return '❌ Roto — no compila / errores';
    }
  }
}

/// Archivo detectado como relevante
class DetectedFile {
  final String path;
  final String type;
  final int sizeBytes;

  const DetectedFile({
    required this.path,
    required this.type,
    required this.sizeBytes,
  });
}

/// Resultado completo del análisis
class ProjectAnalysis {
  final String projectName;
  final String projectPath;

  // Paso 1.1: ¿Qué es?
  final ProjectType type;
  final String typeDetail;

  // Paso 1.2: Lenguaje/framework
  final String language;
  final String? framework;
  final String? sdkVersion;

  // Paso 1.3: Completitud
  final Completeness completeness;
  final List<String> issues;

  // Paso 1.4: Código aprovechable
  final bool hasValuableCode;
  final List<String> valuableParts;
  final int totalFiles;
  final int totalLines;

  // Paso 1.5: Resumen
  final String summary;

  // Archivos clave
  final List<DetectedFile> keyFiles;

  // Metadatos
  final DateTime analyzedAt;
  final Duration analysisDuration;

  ProjectAnalysis({
    required this.projectName,
    required this.projectPath,
    required this.type,
    required this.typeDetail,
    required this.language,
    this.framework,
    this.sdkVersion,
    required this.completeness,
    this.issues = const [],
    required this.hasValuableCode,
    this.valuableParts = const [],
    required this.totalFiles,
    required this.totalLines,
    required this.summary,
    this.keyFiles = const [],
    DateTime? analyzedAt,
    this.analysisDuration = Duration.zero,
  }) : analyzedAt = analyzedAt ?? DateTime.now();
}
