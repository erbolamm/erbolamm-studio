// ═══════════════════════════════════════════════════════════════
// 🏷️ Agente 2 — Clasificador
// ═══════════════════════════════════════════════════════════════
// Pregunta al usuario qué hacer con el proyecto analizado.
// Opciones: publicar, fusionar, aprovechar partes, descartar,
// o continuar desarrollando.
//
// También revisa universe.json para detectar duplicados.
//
// Plan futuro: guardar la decisión para que los siguientes
// agentes del pipeline la consulten automáticamente.
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/agent_interface.dart';

/// Decisión del usuario sobre qué hacer con el proyecto
enum ProjectDecision {
  publish, // Publicar → pasa a agente 3
  merge, // Fusionar con otro proyecto
  salvage, // Aprovechar partes
  discard, // Descartar
  continue_, // Continuar desarrollando
}

/// Resultado del clasificador
class ClassificationResult {
  final ProjectDecision decision;
  final String? mergeTarget;
  final String? salvageTarget;
  final String? notes;
  final List<String> duplicates;
  final String summary;

  const ClassificationResult({
    required this.decision,
    this.mergeTarget,
    this.salvageTarget,
    this.notes,
    this.duplicates = const [],
    required this.summary,
  });

  bool get requiresApproval =>
      decision == ProjectDecision.merge || decision == ProjectDecision.salvage;

  String get decisionLabel {
    switch (decision) {
      case ProjectDecision.publish:
        return '📤 Publicar';
      case ProjectDecision.merge:
        return '🔗 Fusionar';
      case ProjectDecision.salvage:
        return '🔧 Aprovechar partes';
      case ProjectDecision.discard:
        return '🗑️ Descartar';
      case ProjectDecision.continue_:
        return '🔨 Continuar desarrollo';
    }
  }
}

/// Agente 2: Clasifica el proyecto según la decisión del usuario
class ClassifierAgent implements AgentInterface {
  @override
  String get agentId => 'classifier';
  @override
  String get agentName => 'Clasificador';
  @override
  String get inboxStep => 'Paso 2';

  ProjectDecision? _decision;
  String? _mergeTarget;
  String? _salvageTarget;
  String? _notes;

  /// El usuario establece su decisión aquí (desde la UI)
  void setDecision({
    required ProjectDecision decision,
    String? mergeTarget,
    String? salvageTarget,
    String? notes,
  }) {
    _decision = decision;
    _mergeTarget = mergeTarget;
    _salvageTarget = salvageTarget;
    _notes = notes;
  }

  @override
  Future<bool> canExecute(String projectPath) async {
    return _decision != null;
  }

  @override
  Future<AgentOutput> execute(String projectPath) async {
    if (_decision == null) {
      return AgentOutput(
        agentId: agentId,
        success: false,
        summary: 'No se ha tomado una decisión. Usa setDecision() primero.',
        error: 'Decision pending',
      );
    }

    // Buscar duplicados en universe.json (simulado)
    final duplicates = await _checkDuplicates(projectPath);

    final result = ClassificationResult(
      decision: _decision!,
      mergeTarget: _mergeTarget,
      salvageTarget: _salvageTarget,
      notes: _notes,
      duplicates: duplicates,
      summary: _buildSummary(
        _decision!,
        duplicates,
        _mergeTarget,
        _salvageTarget,
      ),
    );

    return AgentOutput(
      agentId: agentId,
      success: true,
      summary: result.summary,
      data: {
        'decision': result.decisionLabel,
        'duplicates': result.duplicates,
        'mergeTarget': result.mergeTarget,
        'salvageTarget': result.salvageTarget,
        'notes': result.notes,
      },
    );
  }

  Future<List<String>> _checkDuplicates(String projectPath) async {
    final projectName = p.basename(projectPath);
    // universe.json está 2 niveles arriba de INBOX/{proyecto}
    final universePath = p.normalize(
      p.join(projectPath, '..', '..', 'universe.json'),
    );
    final universeFile = File(universePath);
    if (!universeFile.existsSync()) return [];
    try {
      final json = jsonDecode(universeFile.readAsStringSync()) as Map;
      final projects = (json['projects'] as List?) ?? [];
      return projects
          .whereType<Map>()
          .where((p) => p['id'] == projectName || p['name'] == projectName)
          .map((p) => (p['id'] ?? p['name'] ?? '').toString())
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _buildSummary(
    ProjectDecision decision,
    List<String> duplicates,
    String? mergeTarget,
    String? salvageTarget,
  ) {
    final parts = <String>['Decisión: ${decision.name}'];

    if (duplicates.isNotEmpty) {
      parts.add('Posibles duplicados: ${duplicates.join(", ")}');
    } else {
      parts.add('Sin duplicados detectados en el universo');
    }

    if (decision == ProjectDecision.merge && mergeTarget != null) {
      parts.add('Fusionar con: $mergeTarget');
    }
    if (decision == ProjectDecision.salvage && salvageTarget != null) {
      parts.add('Partes aprovechables para: $salvageTarget');
    }

    return parts.join('. ');
  }
}
