#!/usr/bin/env python3
"""
Voice cloning con XTTS v2 — usa tus audios de mi_voz/wav/ como referencia.
Cualquier texto en cualquier idioma → tu voz.

Uso:
  python3 clone_voice.py "Hola mundo" es
  python3 clone_voice.py "Hello world" en
  python3 clone_voice.py "Bonjour le monde" fr
  python3 clone_voice.py "こんにちは" ja
"""

import sys
import os
import argparse
from pathlib import Path

# Rutas
SCRIPT_DIR = Path(__file__).parent
VOICE_WAV_DIR = SCRIPT_DIR / "mi_voz" / "clean"
OUTPUT_DIR = SCRIPT_DIR / "tts_output"

# Idiomas soportados por XTTS v2
XTTS_LANGS = {
    "es": "es", "en": "en", "fr": "fr", "de": "de",
    "it": "it", "pt": "pt", "pl": "pl", "nl": "nl",
    "ru": "ru", "zh": "zh", "ja": "ja", "ko": "ko",
    "ar": "ar", "hi": "hi", "cs": "cs", "tr": "tr",
    "hu": "hu", "uk": "uk", "el": "el", "th": "th",
}

# Cache del modelo
_tts_instance = None

def get_tts():
    """Inicializa TTS — descarga modelo en primera ejecución."""
    global _tts_instance
    if _tts_instance is None:
        from TTS.api import TTS
        print("[*] Cargando XTTS v2 (primera vez: descarga ~1.5 GB)...")
        _tts_instance = TTS(
            model_name="tts_models/multilingual/multi-dataset/xtts_v2",
            gpu=False
        )
        print("[✓] Modelo listo")
    return _tts_instance

def get_ref_wav(ref_name=None):
    """Selecciona el audio de referencia."""
    wavs = sorted(VOICE_WAV_DIR.glob("*.wav"))
    if not wavs:
        raise FileNotFoundError(f"No hay WAVs en {VOICE_WAV_DIR}")
    if ref_name:
        path = VOICE_WAV_DIR / ref_name
        if not path.exists():
            raise FileNotFoundError(f"No encontrado: {path}")
        return str(path)
    # Default: el más largo (más datos de entrenamiento)
    best = max(wavs, key=lambda f: os.path.getsize(f))
    print(f"[i] Ref: {best.name} ({os.path.getsize(best)//1024} KB)")
    return str(best)

def clone(text, lang_code, ref_wav=None, output_name=None):
    """Genera audio con tu voz."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    lang = XTTS_LANGS.get(lang_code, lang_code)
    print(f"\n[+] '{text[:60]}{'...' if len(text)>60 else ''}'")
    print(f"    Idioma: {lang_code}")

    ref_path = ref_wav or get_ref_wav()
    tts = get_tts()

    print("[*] Sintetizando con tu voz... (1-3 min en CPU)")
    wav = tts.tts(
        text=text,
        language=lang,
        speaker_wav=ref_path,
    )

    if output_name is None:
        sanitized = text[:40].replace(" ", "_").replace("/", "_").replace("'", "")
        output_name = f"clone_{lang_code}_{sanitized}.wav"

    out_path = OUTPUT_DIR / output_name
    import soundfile as sf
    sf.write(str(out_path), wav, 24000)
    size_kb = os.path.getsize(out_path) // 1024
    duration = len(wav) // 24000
    print(f"[✓] {out_path.name} — {size_kb} KB, {duration}s")
    return out_path

def main():
    parser = argparse.ArgumentParser(description="Voice cloning con XTTS v2")
    parser.add_argument("text", help="Texto a sintetizar")
    parser.add_argument("lang", help="Código idioma (es, en, fr, de, ja, zh...)")
    parser.add_argument("--ref", "-r", help="WAV de referencia (default: el más largo)")
    parser.add_argument("--out", "-o", help="Nombre de salida")
    args = parser.parse_args()

    try:
        path = clone(args.text, args.lang, args.ref, args.out)
        print(f"\n→ {path}")
    except FileNotFoundError as e:
        print(f"[✗] {e}")
        sys.exit(1)
    except Exception as e:
        print(f"[✗] Error: {e}")
        import traceback; traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
