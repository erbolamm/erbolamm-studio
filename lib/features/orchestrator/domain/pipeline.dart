// ═══════════════════════════════════════════════════════════════
// 🧠 Orchestrator — Mapa de agentes del pipeline INBOX
// ═══════════════════════════════════════════════════════════════
// Orquestador tipo Paperclip: cada paso de INBOX.md tiene un
// agente especializado. El orquestador recibe un proyecto,
// lo reparte entre los agentes, recopila resultados y entrega
// el proyecto procesado con todos sus assets.
//
// Plan futuro: fork de Paperclip, integración con gentle-ai.
// ═══════════════════════════════════════════════════════════════

import '../../../core/config/feature_flags.dart';

// ─── Estados posibles de cada agente ───
enum AgentStatus { pending, running, done, failed, skipped }

// ─── Un agente = un paso de INBOX.md ───
class Agent {
  final String id;
  final String name;
  final String inboxStep;
  final String icon;
  final String description;
  AgentStatus status;

  Agent({
    required this.id,
    required this.name,
    required this.inboxStep,
    required this.icon,
    required this.description,
    this.status = AgentStatus.pending,
  });
}

// ─── Pipeline completo de 7 agentes ───
final List<Agent> inboxPipeline = [
  Agent(
    id: 'analyzer',
    name: 'Analizador Inicial',
    inboxStep: 'Paso 1',
    icon: '🔍',
    description:
        'Analiza el proyecto: qué es, lenguaje, estado, código aprovechable',
  ),
  Agent(
    id: 'classifier',
    name: 'Clasificador',
    inboxStep: 'Paso 2',
    icon: '🏷️',
    description:
        'Pregunta a Javier qué hacer: publicar, fusionar, descartar o continuar',
  ),
  Agent(
    id: 'auditor',
    name: 'Auditor de Requisitos',
    inboxStep: 'Pasos 3–3.9',
    icon: '✅',
    description:
        'Verifica campos obligatorios, README, privacidad iOS, seguridad npm, skills Dart/Flutter',
  ),
  Agent(
    id: 'marketing',
    name: 'Creador de Assets',
    inboxStep: 'Paso 4',
    icon: '🎨',
    description:
        'Genera brand-spec, screenshots (web real o mockups), videos promo, música',
  ),
  Agent(
    id: 'registrar',
    name: 'Registrador',
    inboxStep: 'Paso 5',
    icon: '📝',
    description: 'Añade el proyecto a universe.json con todos sus campos',
  ),
  if (FeatureFlags.cloudEnabled) ...[
    Agent(
      id: 'cloud-auditor',
      name: 'Auditor de Nube',
      inboxStep: 'Paso 6',
      icon: '☁️',
      description:
          'Cruza universe.json con Firebase/GCP/GitHub, detecta proyectos huérfanos',
    ),
    Agent(
      id: 'migrator',
      name: 'Evaluador de Hosting',
      inboxStep: 'Paso 7',
      icon: '🚚',
      description:
          'Analiza si migrar el proyecto a Firebase Hosting, recomienda acciones',
    ),
  ],
];

// ─── Resultado del pipeline ───
class PipelineResult {
  final String projectName;
  final Map<String, AgentStatus> agentResults;
  final List<String> generatedAssets;
  final String? error;

  PipelineResult({
    required this.projectName,
    required this.agentResults,
    this.generatedAssets = const [],
    this.error,
  });
}
