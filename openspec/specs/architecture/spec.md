# ErBolamm Studio — Especificación de Arquitectura

## Visión General

Aplicación Flutter multiplataforma que actúa como suite creativa.
Procesa proyectos alojados en INBOX/ mediante un pipeline de 7 agentes
orquestados, generando contenido promocional listo para redes sociales.

## Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| UI | Flutter 3.32 + Material 3 |
| Estado | BLoC + Equatable |
| Backend | Firebase Auth + Firestore |
| Local | SQLite + SharedPreferences |
| Audio | Strudel + Tone.js (OfflineAudioContext) |
| Video | Playwright + ffmpeg + design-engine |
| Orquestación | Paperclip (fork planeado) |

## Módulos

### Core
- `core/constants/colors.dart` — Paleta del ecosistema (6 pilares)
- `core/navigation/` — Navegación adaptativa (Rail/BottomNav) + BLoC

### Features actuales (9)
1. **analyzer/** — Analizador de proyectos GitHub
2. **market_research/** — Tendencias + hooks promocionales
3. **music/** — Generación de música procedural
4. **animation/** — Animaciones HTML → video
5. **orchestrator/** — Pipeline de 7 agentes
6. **publisher/** — Mezcla + exportación a redes
7. **projects/** — Gestión de proyectos
8. **admin/** — Panel de administración
9. **settings/** — Configuración

### Features futuras
10. **voice/** — Clonación de voz (VibeVoice + VoiceBox)
11. **assets/** — Recursos gráficos

### Servicios
- `project_monitor.dart` — Monitoreo de INBOX/
- `auth_service.dart` — Firebase Auth
- `github_api.dart` — GitHub API
- `local_db.dart` — SQLite local

## Pipeline de Agentes

```
INBOX/ → ① Analizador → ② Clasificador → ③ Auditor → 
         ④ Marketing → ⑤ Registrador → ⑥ Cloud Audit → 
         ⑦ Migrador → Proyecto listo
```

Cada agente implementa `AgentInterface` con `execute()` y `canExecute()`.
El `PipelineRunner` los ejecuta en secuencia.

## Estructura de Archivos

```
desktop/
├── openspec/                    ← SDD artifacts
├── lib/
│   ├── main.dart                ← Entry point
│   ├── app.dart                 ← App root + navegación
│   ├── core/                    ← Constantes, navegación, tema
│   ├── features/                ← 9 módulos funcionales
│   │   └── orchestrator/        ← Pipeline de agentes
│   │       ├── domain/          ← Modelos (Agent, AgentOutput, etc.)
│   │       ├── agents/          ← Implementación de cada agente
│   │       ├── orchestration/   ← PipelineRunner
│   │       └── presentation/    ← UI del orquestador
│   ├── services/                ← Firebase, GitHub, monitor, DB
│   └── models/                  ← DTOs compartidos
├── macos/                       ← macOS platform
├── linux/                       ← Linux platform
├── windows/                     ← Windows platform
└── test/                        ← Tests
```

## Decisiones Técnicas

1. **Path duro vs configurable**: El path a erbolamm-com está hardcodeado para
   macOS. En Windows/Linux usa Directory.current. Futuro: selector de carpeta.

2. **Sandbox desactivado**: Necesario para acceder a INBOX/. En release,
   considerar usar security-scoped bookmarks con selector de carpeta.

3. **Agentes síncronos**: Se ejecutan en secuencia para mantener orden.
   Futuro: paralelizar agentes independientes (ej: 5 y 6).

4. **Inspirado en Paperclip**: El modelo de agentes está tomado de
   paperclipai/paperclip (65k★), adaptado a ejecución local en Dart.
