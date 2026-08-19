# 📁 lib/ — ErBolamm Studio

Núcleo de la aplicación Flutter multiplataforma.

## 🧱 Capas

| Capa | Carpeta | Propósito |
|------|---------|-----------|
| 🎯 Core | `core/` | Constantes, navegación, tema |
| 🧩 Features | `features/` | Módulos funcionales (cada uno es independiente) |
| 🔌 Services | `services/` | Conexiones externas: Firebase, GitHub, SQLite, sistema de archivos |
| 📦 Models | `models/` | DTOs y objetos de datos compartidos |

## 🗺️ Roadmap de features

### ✅ Implementado
- `analyzer/` — Analizador de proyectos (reglas, checklist, reportes)
- `music/` — Music Studio (Web Audio API procedural + Tone.js + Strudel)
- `animation/` — Animation Studio (HTML → MP4 con Playwright y design-engine)
- `publisher/` — Publisher (MediaMixer con ffmpeg + exportación multiplataforma)
- `voice/` — Voice Studio (Síntesis multi-idioma con MiniMax CLI `mmx`)
- `orchestrator/` — Pipeline de 7 agentes + NarrationGenerator + Registrar
- `projects/` — Gestión de proyectos del ecosistema
- `terminal/` — Terminal integrada
- `admin/` — Panel de administración
- `settings/` — Configuración de la app y proveedores de IA

### ⬜ Pendiente (TODO)
- `market_research/` — Scrapers y microservicio FastAPI para hooks de mercado
- `assets/` — Catálogo unificado de fuentes y recursos gráficos compartidos

## 📐 Principios

- Cada feature es autocontenida: screen + bloc + widgets
- Los servicios son singleton o inyectados
- La navegación es BLoC-based
- TODO: donde algo falta, está marcado con `// TODO:` en el código
