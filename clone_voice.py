#!/usr/bin/env python3
"""
Voice cloning con XTTS v2 — usa tus audios de mi_voz/clean/ como referencia.
Optimizado para Apple Silicon (Metal/MPS) con chunking inteligente de frases.
Cualquier texto en 17 idiomas → tu voz auténtica.

Uso:
  python3 clone_voice.py "Hola, bienvenidos a ApliArte" es
  python3 clone_voice.py "Welcome to ApliArte" en
"""

import sys
import os
import re
import argparse
from pathlib import Path
import numpy as np
import torch

# Compatibilidad con PyTorch 2.6+: restaurar weights_only=False para checkpoints de Coqui
_orig_torch_load = torch.load
def _compat_torch_load(*args, **kwargs):
    if "weights_only" not in kwargs:
        kwargs["weights_only"] = False
    return _orig_torch_load(*args, **kwargs)
torch.load = _compat_torch_load

# Compatibilidad con torchaudio: backend transparente basado en soundfile
import soundfile as sf
import torchaudio

def _sf_load(audiopath, *args, **kwargs):
    data, sr = sf.read(audiopath)
    t = torch.from_numpy(data).float()
    if t.ndim == 1:
        t = t.unsqueeze(0)
    elif t.ndim == 2:
        t = t.t()
    return t, sr

def _sf_save(uri, src, sample_rate, *args, **kwargs):
    arr = src.detach().cpu().numpy()
    if arr.ndim == 2:
        arr = arr.t()
    sf.write(uri, arr, sample_rate)

torchaudio.load = _sf_load
torchaudio.save = _sf_save

# Aceptación automática no-interactiva de términos de XTTS v2
os.environ["COQUI_TOS_AGREED"] = "1"

# Asegurar directorios de caché locales en disco interno si los volúmenes externos no están montados
local_cache = Path.home() / ".cache" / "huggingface"
local_cache.mkdir(parents=True, exist_ok=True)
if not os.path.exists(os.environ.get("HF_HOME", "")) or "/Volumes/" in os.environ.get("HF_HOME", ""):
    os.environ["HF_HOME"] = str(local_cache)
if not os.path.exists(os.environ.get("TRANSFORMERS_CACHE", "")) or "/Volumes/" in os.environ.get("TRANSFORMERS_CACHE", ""):
    os.environ["TRANSFORMERS_CACHE"] = str(local_cache / "transformers")

# Rutas canónicas
SCRIPT_DIR = Path(__file__).parent
VOICE_WAV_DIR = SCRIPT_DIR / "mi_voz" / "clean"
OUTPUT_DIR = SCRIPT_DIR / "tts_output"
CENTRAL_LOCUCION_DIR = Path("/Users/apliarte/trabajo/erbolamm-trabajo/control-erbolamm/difusion/locucion/audios")

# Idiomas soportados por XTTS v2
XTTS_LANGS = {
    "es": "es", "en": "en", "fr": "fr", "de": "de",
    "it": "it", "pt": "pt", "pl": "pl", "nl": "nl",
    "ru": "ru", "zh": "zh-cn", "zh-cn": "zh-cn", "ja": "ja", "ko": "ko",
    "ar": "ar", "hi": "hi", "cs": "cs", "tr": "tr",
    "hu": "hu",
}

def synthesize_local_fallback(text, lang_code, speed=1.15):
    """Síntesis local de alta fidelidad para idiomas no incluidos en XTTS (ej. id, vi, fa)."""
    import subprocess
    import tempfile
    import soundfile as sf
    voice_map = {"id": "Damayanti", "vi": "Linh"}
    voice = voice_map.get(lang_code)
    aiff_path = Path(tempfile.mktemp(suffix=".aiff"))
    cmd = ["say"]
    if voice:
        cmd += ["-v", voice]
    rate = int(175 * float(speed))
    cmd += ["-r", str(rate), "-o", str(aiff_path), text]
    subprocess.run(cmd, check=True)
    data, sr = sf.read(str(aiff_path))
    if aiff_path.exists():
        aiff_path.unlink()
    return np.array(data, dtype=np.float32), sr

# Cache del modelo
_tts_instance = None
_device = "cpu"

def get_tts():
    """Inicializa TTS con aceleración Apple Silicon (MPS) o CPU."""
    global _tts_instance, _device
    if _tts_instance is None:
        import torch
        from TTS.api import TTS

        # Detección de aceleración por hardware
        use_gpu = False
        if torch.cuda.is_available():
            _device = "cuda"
            use_gpu = True
        elif torch.backends.mps.is_available():
            _device = "mps"

        print(f"[*] Inicializando XTTS v2 en {_device} (primera vez descarga pesos ~1.8 GB)...")
        try:
            if _device == "mps":
                # XTTS v2 se inicializa y luego se mueve al dispositivo MPS
                _tts_instance = TTS(
                    model_name="tts_models/multilingual/multi-dataset/xtts_v2",
                    gpu=False
                )
                try:
                    _tts_instance.to("mps")
                    print("[✓] Aceleración Apple Silicon Metal (MPS) activa")
                except Exception as mps_err:
                    print(f"[!] MPS no soportado por alguna capa de XTTS ({mps_err}); usando CPU optimizada.")
                    _tts_instance.to("cpu")
                    _device = "cpu"
            else:
                _tts_instance = TTS(
                    model_name="tts_models/multilingual/multi-dataset/xtts_v2",
                    gpu=use_gpu
                )
                print(f"[✓] Modelo listo en {_device}")
        except Exception as e:
            print(f"[!] Reintentando en modo CPU: {e}")
            _tts_instance = TTS(
                model_name="tts_models/multilingual/multi-dataset/xtts_v2",
                gpu=False
            )
            _device = "cpu"
            print("[✓] Modelo listo en CPU")
    return _tts_instance

def get_ref_wav(ref_name=None):
    """Selecciona el audio de referencia de calibración."""
    wavs = sorted(VOICE_WAV_DIR.glob("*.wav"))
    if not wavs:
        # Fallback a la muestra central si existe
        central_ref = Path("/Users/apliarte/trabajo/erbolamm-trabajo/control-erbolamm/difusion/locucion/muestras/javier_mateo_calibracion.wav")
        if central_ref.exists():
            return str(central_ref)
        raise FileNotFoundError(f"No hay archivos WAV en {VOICE_WAV_DIR}")
    if ref_name:
        path = VOICE_WAV_DIR / ref_name
        if not path.exists():
            raise FileNotFoundError(f"No encontrado: {path}")
        return str(path)
    # Por defecto: el archivo javier_mateo_calibracion.wav o el más largo
    for w in wavs:
        if "calibracion" in w.name.lower():
            print(f"[i] Muestra soberana seleccionada: {w.name} ({os.path.getsize(w)//1024} KB)")
            return str(w)
    best = max(wavs, key=lambda f: os.path.getsize(f))
    print(f"[i] Muestra de referencia: {best.name} ({os.path.getsize(best)//1024} KB)")
    return str(best)

def split_into_sentences(text):
    """Divide el texto en frases lógicas para evitar degradación en guiones largos."""
    sentences = re.split(r'(?<=[.!?])\s+', text.strip())
    chunks = []
    current = ""
    for s in sentences:
        s = s.strip()
        if not s:
            continue
        if len(current) + len(s) < 180:
            current = (current + " " + s).strip()
        else:
            if current:
                chunks.append(current)
            current = s
    if current:
        chunks.append(current)
    return chunks if chunks else [text]

def normalize_audio(wav):
    """Normaliza el pico de amplitud para un volumen equilibrado y limpio."""
    arr = np.array(wav, dtype=np.float32)
    max_val = np.max(np.abs(arr))
    if max_val > 0.01:
        # Normalizar a -1.0 dBFS (aprox 0.89)
        arr = (arr / max_val) * 0.89
    return arr

def clone(text, lang_code, ref_wav=None, output_name=None, speed=1.15, temperature=0.75, pause_ms=200):
    """Genera audio con tu voz clonada mediante XTTS v2, con control de ritmo, expresividad y pausas."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    if CENTRAL_LOCUCION_DIR.exists():
        CENTRAL_LOCUCION_DIR.mkdir(parents=True, exist_ok=True)

    lang = XTTS_LANGS.get(lang_code, lang_code)
    print(f"\n[+] Texto: '{text[:80]}{'...' if len(text)>80 else ''}'")
    print(f"    Idioma objetivo: {lang_code.upper()} · Velocidad: {speed}x · Expresividad: {temperature} · Pausa: {pause_ms}ms")

    ref_path = ref_wav or get_ref_wav()
    tts = get_tts()

    if lang not in tts.languages:
        print(f"[i] Idioma '{lang_code}' no está en el catálogo acústico de XTTS v2. Sintetizando con motor local...")
        raw_audio, sample_rate = synthesize_local_fallback(text, lang_code, speed=speed)
        full_wav = normalize_audio(raw_audio)
    else:
        chunks = split_into_sentences(text)
        audio_segments = []
        sample_rate = 24000
        pause_silence = np.zeros(int(sample_rate * (max(50, pause_ms) / 1000.0)), dtype=np.float32)

        print(f"[*] Sintetizando en {len(chunks)} frase(s) con tu timbre de voz (speed={speed}, temp={temperature})...")
        for idx, chunk in enumerate(chunks, start=1):
            print(f"    [{idx}/{len(chunks)}] '{chunk[:50]}...'")
            seg_wav = tts.tts(
                text=chunk,
                language=lang,
                speaker_wav=ref_path,
                speed=float(speed),
                temperature=float(temperature),
            )
            norm_seg = normalize_audio(seg_wav)
            audio_segments.append(norm_seg)
            if idx < len(chunks):
                audio_segments.append(pause_silence)

        full_wav = np.concatenate(audio_segments)

    if output_name is None:
        sanitized = re.sub(r'[^a-zA-Z0-9_-]', '_', text[:30]).strip('_')
        output_name = f"clon_{lang_code}_{sanitized}.wav"
    elif not output_name.endswith(".wav"):
        output_name += ".wav"

    out_path = OUTPUT_DIR / output_name
    import soundfile as sf
    sf.write(str(out_path), full_wav, sample_rate)

    # Copia a la central si está disponible
    if CENTRAL_LOCUCION_DIR.exists():
        central_out = CENTRAL_LOCUCION_DIR / output_name
        sf.write(str(central_out), full_wav, sample_rate)
        print(f"[✓] Copiado a la Oficina central: {central_out.name}")

    size_kb = os.path.getsize(out_path) // 1024
    duration = round(len(full_wav) / sample_rate, 1)
    print(f"[✓] Generado con éxito: {out_path.name} ({size_kb} KB, {duration}s)")
    return out_path

def main():
    parser = argparse.ArgumentParser(description="Voice cloning con XTTS v2 optimizado para Apple Silicon")
    parser.add_argument("text", help="Texto a sintetizar")
    parser.add_argument("lang", nargs="?", default="es", help="Código de idioma (es, en, pt, fr, de, it...) [default: es]")
    parser.add_argument("--ref", "-r", help="WAV de referencia (default: javier_mateo_calibracion.wav)")
    parser.add_argument("--out", "-o", help="Nombre de archivo de salida")
    parser.add_argument("--speed", "-s", type=float, default=1.15, help="Velocidad/ritmo de locución (default: 1.15)")
    parser.add_argument("--temperature", "-t", type=float, default=0.75, help="Temperatura/expresividad (default: 0.75)")
    parser.add_argument("--pause-ms", "-p", type=int, default=200, help="Pausa entre frases en ms (default: 200)")
    args = parser.parse_args()

    try:
        path = clone(
            text=args.text,
            lang_code=args.lang,
            ref_wav=args.ref,
            output_name=args.out,
            speed=args.speed,
            temperature=args.temperature,
            pause_ms=args.pause_ms
        )
        print(f"\n→ Ruta final: {path}")
    except FileNotFoundError as e:
        print(f"[✗] {e}")
        sys.exit(1)
    except Exception as e:
        print(f"[✗] Error: {e}")
        import traceback; traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
