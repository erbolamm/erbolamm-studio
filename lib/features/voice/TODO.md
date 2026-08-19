# 🗣️ Voice Studio — Clonación de voz + Narración multi-idioma

Pipeline de voz integrado en ErBolamm Studio.

## Estado actual
✅ VoiceStudioScreen — UI con pipeline de 4 pasos
✅ RecordingScreen — Grabación de 5 frases con ffmpeg
✅ VoiceService — Backend con mmx CLI (sin Python)
✅ MmxVoiceService — TTS puro con mmx speech synthesize
✅ Grabación real con micrófono (RecordService c/ ffmpeg)
✅ Narración en 6+ idiomas con mmx
✅ Preview de audio en la UI (_playingAudio reservado)
✅ Exportar narración a Publisher (integración con Publisher)
✅ flutter analyze: 0 errores (0 warnings críticos)

## Tecnologías

### mmx CLI (MiniMax)
- Docs: `mmx --help`, `mmx speech --help`
- Cmd: `mmx speech synthesize --text "..." --voice "Spanish_Narrator" --out file.wav`
- Voces: `mmx speech voices` — +270 voces en 15+ idiomas
- Alternativa pura Dart a XTTS v2 + Python

### Voces mmx disponibles
| Idioma | Voz por defecto |
|--------|----------------|
| 🇪🇸 Español | Spanish_Narrator |
| 🇬🇧 English | English_expressive_narrator |
| 🇧🇷 Portugués | Portuguese_Narrator |
| 🇫🇷 Francés | French_Male_Speech_New |
| 🇩🇪 Alemán | German_FriendlyMan |
| 🇮🇹 Italiano | Italian_Narrator |
| 🇯🇵 Japonés | Japanese_IntellectualSenior |
| 🇰🇷 Coreano | Korean_GentleWoman |
| 🇨🇳 Mandarín | Chinese (Mandarin)_News_Anchor |

## Estructura

```
voice/
├── domain/
│   └── voice_service.dart       ← Backend mmx (reemplaza Python)
├── data/
│   ├── record_service.dart       ← Grabación con ffmpeg
│   └── mmx_voice_service.dart   ← Helpers mmx
├── presentation/
│   └── screens/
│       └── voice_studio_screen.dart
└── TODO.md
```

## Pipeline completo (revisado)
```
🎤 Grabar 5 frases → 🔊 mmx TTS synthesize
    → 🌍 Narración 15+ idiomas (sin Python)
    → 📦 Publisher (mezcla con video + música)
```

## Instalación

mmx se instala vía npm:
```bash
npm install -g @minimax/mmx-cli
```

No requiere Python, torch, ni XTTS. Todo vía CLI.

## API mmx Speech

```bash
# Sintetizar voz
mmx speech synthesize --text "Hola mundo" --voice "Spanish_Narrator" --out hola.wav

# Listar voces
mmx speech voices

# Modelos disponibles: speech-2.8-hd (default), 2.6, 02
```
