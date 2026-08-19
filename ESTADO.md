# ESTADO — ErBolamm Studio

> Última actualización: 19 de agosto de 2026

---

## 🎯 Propósito

Suite creativa y software factory autónoma multiplataforma. Permite analizar, auditar, generar assets de marketing (video, audios multilingües, screenshots enmarcados para tiendas, landing) y registrar proyectos en el ecosistema ErBolamm (`universe.json` / `erbolamm-universo`) con cero esfuerzo manual y total aislamiento de artefactos.

---

## ✅ Lo que funciona hoy

| Módulo | Estado | Notas |
|---|:---:|---|
| **Modo Referencia Directa** | ✅ Producción | Opera directamente sobre cualquier ruta local (`~/trabajo/...`) sin clonar ni duplicar proyectos en `INBOX/`. |
| **Carpeta Canónica `erbolamm-studio/`** | ✅ Producción | Todos los assets generados se encapsulan en `<project>/erbolamm-studio/` (brand-spec, screenshots, narration, music, videos, source) limpiando automáticamente carpetas legacy `promo/`. |
| **Capturas Reales y Stores Anti-2.3.3** | ✅ Producción | Generador dinámico de slides por proyecto (iPhone 6.5", 6.7", iPad 13") buscando capturas reales en `erbolamm-studio/screenshots/raw/` o widgets Flutter sin inventar mockups de otras apps. |
| **Analyzer (Remoto y Local)** | ✅ Producción | 1 sola llamada a Git Trees (sin clone) o ruta local directa. Detecta landings públicas en `README.md`. |
| **Orchestrator (7 Agentes)** | ✅ Producción | Pipeline secuencial: Analyzer, Classifier, Auditor, Marketing, CloudAuditor, Migrator y Registrar con selector multi-proyecto reactivo en AppBar. |
| **CLI Runner & Headless (`bin/studio.dart`)** | ✅ Producción | Comandos: `process <path>`, `analyze <url_o_path>`, `pipeline <path>`, `promo <path>`, `list`, `doctor` para operar directamente desde terminal o con agentes IA (`pi`, `opencode`, `grok`, `codex`). |
| **Proveedores IA Dual** | ✅ Producción | Catálogo oficial (DeepSeek, MiniMax, Claude, OpenAI, Gemini, Groq, NVIDIA NIM) con selector al vuelo en AppBar y Modo Auto. |
| **Voice Studio & Narration** | ✅ Producción | MiniMax API / TTS en Dart puro para 6 idiomas (ES, EN, PT, FR, DE, IT) sin dependencias de GPU. |
| **Animation Studio** | ✅ Producción | Playwright + Chromium headless + ffmpeg → MP4 verticales/horizontales con marcos de dispositivos. |
| **Music Studio** | ✅ Producción | Web Audio API / Tone.js / Strudel sintetizado procedural con historial y renderizado a WAV. |
| **Publisher** | ✅ Producción | ffmpeg MediaMixer + exportación a redes + publicación a Firestore. |
| **Auditoría de Metadatos (Anti-2.3.3)** | ✅ Producción | `StoreMetadataAuditorWidget`: Release notes multilingües (1-clic Android/iOS) y validador de capturas legacy. |
| **NavigationRail Badged** | ✅ Producción | Badges de estado dinámicos (verde/amarillo) según progreso real en disco (`PipelineProgress`). |
| **Terminal Contextual & Agentes** | ✅ Producción | Terminal con `cwd` en proyecto activo y detección de `gentle-ai`, `opencode`, `claude`, `codex`, `pi`, `flutter`, `dart`, `gh`. |
| **Sincronización Canónica** | ✅ Producción | `ProjectRegistryService` unifica SQLite y `universe.json` con Sandbox Guard. |
| **Gobernanza de Agentes** | ✅ Producción | `AGENTS.md` canónico establecido, declarando `ESTADO.md` como Fuente Única de Verdad. |

---

## 📁 Estructura Estándar de Artefactos de un Proyecto

```
<projectPath>/
└── erbolamm-studio/
    ├── brand-spec.md                    ← Identidad, colores, tipografía y pilares
    ├── narration.json                   ← Guiones de voz traducidos a 6 idiomas
    ├── landing.html                     ← Landing page autogenerada si no existía
    ├── screenshots/
    │   ├── raw/                         ← Capturas originales del usuario o motor Flutter
    │   └── store/<lang>/                ← Capturas enmarcadas para App Store & Play Store
    │       ├── iphone_6_5/              ← 1284x2778 px
    │       ├── iphone_6_7/              ← 1290x2796 px
    │       └── ipad_13/                 ← 2064x2752 px
    ├── narration/<lang>/                ← Pistas de audio WAV de voz sintetizada / clonada
    ├── music/                           ← Estilos JSON y audio generado (background.wav)
    ├── videos/                          ← MP4 finales renderizados (vertical y horizontal)
    └── source/                          ← Templates HTML5 y scripts de renderizado
```

---

## 📊 Métricas

| Métrica | Valor |
|---------|-------|
| Tests | 120 passing (100%) |
| Módulos | 9 features |
| Agentes pipeline | 7 |
| Análisis estático | 0 issues (`flutter analyze` limpio) |