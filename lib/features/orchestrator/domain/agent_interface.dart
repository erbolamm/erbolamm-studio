// ═══════════════════════════════════════════════════════════════
// 🧠 Agent Interface — Contrato base para todos los agentes
// ═══════════════════════════════════════════════════════════════
// Todo agente recibe un proyecto y produce un resultado.
// La ejecución puede ser: local (Dart), subagente (gentle-ai)
// o remota (Paperclip server).
//
// Plan futuro: modos de ejecución, cancelación, timeout.
// ═══════════════════════════════════════════════════════════════

/// Resultado devuelto por un agente después de ejecutarse
class AgentOutput {
  final String agentId;
  final bool success;
  final String summary;
  final List<String> artifacts;
  final String? error;
  final Map<String, dynamic> data;

  AgentOutput({
    required this.agentId,
    required this.success,
    required this.summary,
    this.artifacts = const [],
    this.error,
    this.data = const {},
  });
}

/// Interfaz que debe implementar cada agente
abstract class AgentInterface {
  String get agentId;
  String get agentName;
  String get inboxStep;

  /// Ejecuta el agente para el proyecto en [projectPath]
  Future<AgentOutput> execute(String projectPath);

  /// Verifica si el agente puede ejecutarse (dependencias, estado)
  Future<bool> canExecute(String projectPath);
}
