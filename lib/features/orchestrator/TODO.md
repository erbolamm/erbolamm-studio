# 🧠 features/orchestrator/ — Pipeline de Agentes (fork Paperclip)

Orquestador que recibe un proyecto en INBOX/ y lo reparte entre 7 agentes
especializados, cada uno correspondiente a un paso de INBOX.md.

## Mapa de agentes

| # | Agente | Paso INBOX.md | Archivo planeado |
|---|--------|--------------|------------------|
| 1 | 🔍 Analizador Inicial | Paso 1 | `agents/analyzer_agent.dart` |
| 2 | 🏷️ Clasificador | Paso 2 | `agents/classifier_agent.dart` |
| 3 | ✅ Auditor de Requisitos | Pasos 3–3.9 | `agents/auditor_agent.dart` |
| 4 | 🎨 Creador de Assets | Paso 4 | `agents/marketing_agent.dart` |
| 5 | 📝 Registrador | Paso 5 | `agents/registrar_agent.dart` |
| 6 | ☁️ Auditor de Nube | Paso 6 | `agents/cloud_auditor_agent.dart` |
| 7 | 🚚 Evaluador de Hosting | Paso 7 | `agents/migrator_agent.dart` |

## Arquitectura

```
orchestrator/
├── domain/
│   ├── pipeline.dart          ← Modelos: Agent, AgentStatus, PipelineResult
│   └── agent_interface.dart   ← Interfaz base para todos los agentes
├── agents/                    ← Implementación de cada agente
│   ├── analyzer_agent.dart
│   ├── classifier_agent.dart
│   ├── auditor_agent.dart
│   ├── marketing_agent.dart
│   ├── registrar_agent.dart
│   ├── cloud_auditor_agent.dart
│   └── migrator_agent.dart
├── orchestration/
│   ├── pipeline_runner.dart   ← Ejecuta los 7 agentes en orden
│   └── result_collector.dart  ← Recolecta outputs de cada agente
└── presentation/
    └── screens/
        ├── orchestrator_screen.dart  ← Panel principal de control
        └── agent_detail_screen.dart  ← Detalle de cada agente
```

## TODO: Fork de Paperclip

Paperclip (65k★, paperclipai/paperclip) es un orquestador de agentes Node.js.
En lugar de integrarlo directamente, se forkeará adaptándolo al ecosistema:

- [ ] Leer arquitectura de Paperclip (Node.js server + React UI)
- [ ] Extraer el core de orquestación (goal → agents → tasks → results)
- [ ] Adaptar a Dart/Flutter para ejecución local
- [ ] Mantener compatibilidad con gentle-ai para lanzar subagentes
- [ ] Los agentes se ejecutan como procesos: `pi-subagents` o `gentle-ai`
- [ ] Cada agente lee/escribe en `INBOX/{proyecto}/openspec/`

## Flujo completo

```
1. Proyecto cae en INBOX/
2. Orchestrator detecta el cambio (vía ProjectMonitor)
3. Lanza Agente 1 (Analizador) → escribe en openspec/explore.md
4. Lanza Agente 2 (Clasificador) → pregunta a Javier
5. Lanza Agente 3 (Auditor) → verifica requisitos
6. Lanza Agente 4 (Marketing) → genera assets en promo/
7. Lanza Agente 5 (Registrador) → actualiza universe.json
8. Lanza Agente 6 (Cloud Auditor) → guía a Javier
9. Lanza Agente 7 (Migrador) → recomienda hosting
10. Pipeline completo → proyecto listo en el ecosistema
```

## Dependencias

- gentle-ai (para ejecutar subagentes)
- Paperclip fork (orquestación base)
- design-engine (assets)
- Firebase CLI (cloud audit)
- gh CLI (GitHub audit)
