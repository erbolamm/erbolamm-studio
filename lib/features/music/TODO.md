# 🧩 features/music/ — 🎵 Music Studio

Generación de música procedural con Strudel + Tone.js.

## Estado actual
✅ MusicStudioScreen — UI completa con input de estilo, generación de código Strudel, preview y guardado
⬜ Integración real con Tone.js (OfflineAudioContext → WAV)
⬜ Preview de audio en vivo desde la app
⬜ Biblioteca de estilos guardados
⬜ Exportar código Strudel a archivo .strudel

## TODO por archivo

### `presentation/screens/music_studio_screen.dart`
- ✅ UI de solicitud de estilo
- ✅ Generación de código Strudel desde descripción
- ✅ Copiar código al portapapeles
- ✅ Abrir strudel.cc para preview
- TODO: reproducción real de audio con Tone.js embebido en WebView
- TODO: guardar en `src/assets/music/codes/`
- TODO: historial de estilos generados

### `domain/` (pendiente)
- TODO: crear `domain/music_style.dart` — modelo de estilo musical
- TODO: crear `domain/strudel_generator.dart` — lógica de generación de código
- TODO: crear `domain/audio_renderer.dart` — interfaz para Tone.js
