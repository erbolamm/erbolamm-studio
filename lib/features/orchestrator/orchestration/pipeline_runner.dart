// ═══════════════════════════════════════════════════════════════
// 🧠 PipelineRunner — Ejecuta los 7 agentes en secuencia
// ═══════════════════════════════════════════════════════════════
// Toma un proyecto en INBOX/, ejecuta cada agente que puede
// correr, recolecta los resultados y los devuelve.
//
// Plan futuro: ejecución paralela, timeout por agente,
// estado persistente para reanudar pipelines interrumpidos.
// ═══════════════════════════════════════════════════════════════

import 'dart:io';

import '../../../core/config/feature_flags.dart';
import '../domain/agent_interface.dart';
import '../agents/analyzer_agent.dart';
import '../agents/classifier_agent.dart';
import '../agents/auditor_agent.dart';
import '../agents/marketing_agent.dart';
import '../agents/registrar_agent.dart';
import '../agents/cloud_auditor_agent.dart';
import '../agents/migrator_agent.dart';

/// Resultado completo del pipeline
class PipelineRunResult {
  final String projectPath;
  final String projectName;
  final List<AgentOutput> agentResults;
  final bool allSucceeded;
  final Duration totalDuration;

  PipelineRunResult({
    required this.projectPath,
    required this.projectName,
    required this.agentResults,
    required this.allSucceeded,
    required this.totalDuration,
  });
}

/// Ejecuta el pipeline de agentes para un proyecto
class PipelineRunner {
  final String projectPath;
  final List<AgentInterface> _agents;
  final List<AgentOutput> _results = [];
  bool _running = false;

  /// Callbacks para que la UI pueda seguir el progreso
  void Function(String agentId)? _onAgentStart;
  void Function(String agentId, bool success, String summary, String? error)?
  _onAgentDone;

  void setCallbacks({
    void Function(String agentId)? onStart,
    void Function(String agentId, bool success, String summary, String? error)?
    onDone,
  }) {
    _onAgentStart = onStart;
    _onAgentDone = onDone;
  }

  /// Crea un runner con los agentes por defecto
  PipelineRunner({required this.projectPath}) : _agents = _defaultAgents();

  /// Crea un runner con agentes personalizados (útil para compartir
  /// instancias como ClassifierAgent entre UI y runner)
  PipelineRunner.withAgents({
    required this.projectPath,
    required List<AgentInterface> agents,
  }) : _agents = agents;

  static List<AgentInterface> _defaultAgents() {
    return [
      AnalyzerAgent(),
      ClassifierAgent(),
      AuditorAgent(),
      MarketingAgent(),
      RegistrarAgent(),
      if (FeatureFlags.cloudEnabled) ...[CloudAuditorAgent(), MigratorAgent()],
    ];
  }

  bool get isRunning => _running;

  /// Ejecuta todos los agentes en secuencia
  Future<PipelineRunResult> runAll() async {
    _running = true;
    _results.clear();
    final stopwatch = Stopwatch()..start();
    final projectName = projectPath.split(Platform.pathSeparator).last;

    for (final agent in _agents) {
      if (!_running) break; // Permitir cancelación

      try {
        // Verificar si puede ejecutar
        final canRun = await agent.canExecute(projectPath);
        if (!canRun) {
          _results.add(
            AgentOutput(
              agentId: agent.agentId,
              success: false,
              summary:
                  '${agent.agentName}: no puede ejecutarse (dependencias faltantes)',
            ),
          );
          continue;
        }

        // Ejecutar agente
        // UI callback opcional (el orquestador la usa para actualizar estado)
        _onAgentStart?.call(agent.agentId);
        final output = await agent.execute(projectPath);
        _onAgentDone?.call(
          agent.agentId,
          output.success,
          output.summary,
          output.error,
        );
        _results.add(output);
      } catch (e) {
        _results.add(
          AgentOutput(
            agentId: agent.agentId,
            success: false,
            summary: '${agent.agentName}: error: $e',
            error: e.toString(),
          ),
        );
      }
    }

    stopwatch.stop();
    _running = false;

    return PipelineRunResult(
      projectPath: projectPath,
      projectName: projectName,
      agentResults: List.from(_results),
      allSucceeded: _results.every((r) => r.success),
      totalDuration: stopwatch.elapsed,
    );
  }

  /// Cancela la ejecución
  void cancel() {
    _running = false;
  }
}
