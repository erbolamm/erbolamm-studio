# 🧩 features/animation/ — 🎬 Animation Studio

Generación de animaciones HTML y renderizado a video mediante el design-engine.

## Estado actual
✅ AnimationStudioScreen — UI con selector de templates, preview placeholder, botón de render
✅ 3 templates: Vertical Promo, Horizontal Promo, Screenshots
⬜ Preview real del HTML animado (WebView)
⬜ Renderizado real con design-engine/scripts/render-video.cjs
⬜ Edición de parámetros (duración, colores, texto)
⬜ Vista previa en vivo

## TODO por archivo

### `presentation/screens/animation_studio_screen.dart`
- ✅ Selector de templates con cards
- ✅ Timeline de render
- TODO: WebView con preview del HTML animado
- TODO: control de duración (slider)
- TODO: botón "Abrir en editor" (VS Code / editor HTML)

### `domain/` (pendiente)
- TODO: crear `domain/animation_template.dart` — modelo de template
- TODO: crear `domain/html_renderer.dart` — interfaz para design-engine
- TODO: crear `domain/video_exporter.dart` — exportar a MP4
