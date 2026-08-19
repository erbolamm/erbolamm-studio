# 🧩 features/publisher/ — 📦 Publisher

Pipeline de publicación: mezclar video + música + narración, exportar a redes.

## Estado actual
✅ PublisherScreen — UI con pipeline steps y exportación multiplataforma
⬜ Integración real con ffmpeg
⬜ Mezcla de audio + video
⬜ Exportación a redes (subida automática)
⬜ Soporte multi-idioma (6 idiomas)

## TODO por archivo

### `presentation/screens/publisher_screen.dart`
- ✅ Pipeline visual: audio → video → mezcla → export
- ✅ Cards de plataformas (TikTok, YouTube, IG, FB, Twitch, X)
- TODO: integración real con `render-audio.cjs`
- TODO: progreso de render (barra + porcentaje)
- TODO: selector de calidad (1080p, 720p, etc.)
- TODO: preview del video final antes de exportar

### `domain/` (pendiente)
- TODO: crear `domain/pipeline_step.dart` — modelo de paso
- TODO: crear `domain/media_mixer.dart` — ffmpeg wrapper
- TODO: crear `domain/platform_exporter.dart` — subida a redes
- TODO: crear `domain/multi_lang_renderer.dart` — 6 idiomas

### ⬜ Voice integration (futuro)
- TODO: integrar con `features/voice/` para narración
- TODO: paso "4. Añadir narración" en pipeline
