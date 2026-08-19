#!/usr/bin/env python3
"""
🗣️ Voice Pipeline — Clonación de voz + TTS multilingüe
=========================================================
Usa Coqui XTTS para clonar voz y generar narración en 6 idiomas.

Subcomandos:
  check       — Verifica disponibilidad de Python y dependencias
  install     — Instala dependencias necesarias
  clone       — Clona voz a partir de archivos WAV
  tts         — Genera TTS con la voz clonada
  preview     — Reproduce un archivo de audio

Requiere: Python 3.10+, torch, TTS
"""

import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


REQUIRED_PACKAGES = ["torch", "TTS"]
LANGUAGES = {
    "es": "Spanish",
    "en": "English",
    "pt": "Portuguese",
    "fr": "French",
    "de": "German",
    "it": "Italian",
}
XTTS_LANG_CODES = {
    "es": "es",
    "en": "en",
    "pt": "pt",
    "fr": "fr-fr",
    "de": "de",
    "it": "it",
}


# ── Helpers ────────────────────────────────────────────────

def log(msg: str):
    print(f"[voice-pipeline] {msg}", flush=True)


def err(msg: str):
    print(f"[voice-pipeline] ERROR: {msg}", file=sys.stderr, flush=True)


def run_cmd(cmd: list, timeout: int = 300) -> tuple[int, str, str]:
    """Run a command and return (exit_code, stdout, stderr)."""
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return -1, "", "Timeout expired"
    except FileNotFoundError:
        return -2, "", f"Command not found: {cmd[0]}"


# ── Commands ───────────────────────────────────────────────

def cmd_check(args):
    """Check system availability."""
    results = {
        "python_version": sys.version,
        "packages": {},
        "ffmpeg": False,
        "mmx_cli": False,
    }

    # Check ffmpeg
    code, _, _ = run_cmd(["which", "ffmpeg"])
    results["ffmpeg"] = code == 0

    # Check mmx CLI
    code, _, _ = run_cmd(["which", "mmx"])
    results["mmx_cli"] = code == 0

    # Check Python packages
    for pkg in REQUIRED_PACKAGES:
        try:
            __import__(pkg.replace("-", "_"))
            results["packages"][pkg] = True
        except ImportError:
            results["packages"][pkg] = False

    # Check if XTTS model is downloaded
    try:
        from TTS.api import TTS
        tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2")
        results["model_downloaded"] = True
        tts = None  # Free memory
    except Exception:
        results["model_downloaded"] = False

    print(json.dumps(results, indent=2))
    return 0 if all(results["packages"].values()) or results["mmx_cli"] else 1


def cmd_install(args):
    """Install Python dependencies."""
    log("Instalando dependencias de voz...")

    packages = REQUIRED_PACKAGES.copy()
    if args.with_gpu:
        packages.append("torch --index-url https://download.pytorch.org/whl/cu118")

    for pkg in packages:
        log(f"Instalando {pkg}...")
        code, out, stderr = run_cmd(
            [sys.executable, "-m", "pip", "install", pkg],
            timeout=600
        )
        if code != 0:
            err(f"Error instalando {pkg}: {stderr}")
            return 1
        log(f"✅ {pkg} instalado")

    log("✅ Dependencias instaladas")
    return 0


def cmd_clone(args):
    """Clone voice from WAV samples.

    Input: directory with sample_*.wav files (5+ samples, 3-10s each)
    Output: directory with cloned voice config for TTS
    """
    samples_dir = Path(args.samples_dir)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    if not samples_dir.exists():
        err(f"No existe el directorio de muestras: {samples_dir}")
        return 1

    wav_files = sorted(samples_dir.glob("sample_*.wav"))
    if len(wav_files) < 3:
        err(f"Se necesitan al menos 3 muestras WAV, encontradas: {len(wav_files)}")
        return 1

    log(f"📂 Encontradas {len(wav_files)} muestras de voz")
    log("🧬 Inicializando XTTS v2 para clonación...")

    try:
        from TTS.api import TTS

        tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2", gpu=args.gpu)

        # XTTS no requiere un paso de "clonación" separado — el speaker embedding
        # se genera durante el TTS. Guardamos las rutas de las muestras para usarlas
        # como referencia de voz.

        # Guardar metadatos de clonación
        clone_info = {
            "model": "xtts_v2",
            "samples_count": len(wav_files),
            "samples": [str(f) for f in wav_files],
            "speaker_wav": str(wav_files[0]),  # Primary reference
            "gpu": args.gpu,
        }

        info_path = output_dir / "clone_info.json"
        with open(info_path, "w") as f:
            json.dump(clone_info, f, indent=2)

        log(f"✅ Voz clonada. Config guardada en: {info_path}")
        log("  Usá el subcomando 'tts' para generar narraciones.")

        # Quick test: generate a short test audio
        if args.test:
            test_output = output_dir / "test_voice.wav"
            log(f"🔊 Generando audio de prueba: {test_output}")
            tts.tts_to_file(
                text="Hola, esta es una prueba de mi voz clonada.",
                speaker_wav=[str(f) for f in wav_files],
                language="es",
                file_path=str(test_output),
            )
            log(f"✅ Prueba generada: {test_output}")

        tts = None  # Free GPU memory
        return 0

    except ImportError as e:
        err(f"Error de importación: {e}")
        err("Ejecutá 'voice_pipeline.py install' primero")
        return 1
    except Exception as e:
        err(f"Error clonando voz: {e}")
        return 1


MINIMAX_VOICES = {
    "es": "Spanish_Narrator",
    "en": "English_expressive_narrator",
    "pt": "Portuguese_Narrator",
    "fr": "French_MaleNarrator",
    "de": "German_FriendlyMan",
    "it": "Italian_Narrator",
}


def cmd_tts(args):
    """Generate TTS narration in multiple languages.

    Input: clone info (from clone command) + texts JSON
    Output: WAV files per language
    """
    clone_dir = Path(args.clone_dir)
    texts_file = Path(args.texts_file)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    provider = getattr(args, "provider", "local")

    # Load clone info
    info_path = clone_dir / "clone_info.json"
    if provider == "local" and not info_path.exists():
        err(f"No se encontró clone_info.json en: {clone_dir}")
        err("Ejecutá el subcomando 'clone' primero")
        return 1

    # Load texts
    if not texts_file.exists():
        err(f"No se encontró el archivo de textos: {texts_file}")
        return 1

    with open(texts_file, encoding="utf-8") as f:
        texts = json.load(f)

    # Validate languages
    available = {k: v for k, v in texts.items() if k in LANGUAGES}
    if not available:
        err("No se encontraron textos para idiomas soportados")
        return 1

    log(f"🔊 Generando narración en {len(available)} idiomas usando proveedor: {provider}...")

    results = {}

    if provider == "minimax":
        # Check if mmx is installed
        code, _, _ = run_cmd(["which", "mmx"])
        if code != 0:
            err("El CLI 'mmx' no está instalado o no se encuentra en el PATH. Instalo o configuralo primero.")
            return 1

        for lang_code, text in available.items():
            voice = MINIMAX_VOICES.get(lang_code, "English_expressive_narrator")
            output_file = output_dir / f"narration_{lang_code}.wav"
            log(f"  🌍 {LANGUAGES.get(lang_code, lang_code)} ({lang_code}) vía MiniMax...")

            cmd = [
                "mmx",
                "speech",
                "synthesize",
                "--text",
                text,
                "--voice",
                voice,
                "--format",
                "wav",
                "--out",
                str(output_file),
            ]

            code, out, stderr = run_cmd(cmd)
            if code == 0:
                file_size = output_file.stat().st_size
                results[lang_code] = {
                    "file": str(output_file),
                    "size": file_size,
                    "status": "ok",
                }
                log(f"    ✅ {output_file.name} ({file_size:,} bytes)")
            else:
                err(f"Error generando {lang_code} con mmx: {stderr or out}")
                results[lang_code] = {"status": "error", "error": stderr or out}

        manifest = {
            "model": "minimax_speech",
            "languages": list(available.keys()),
            "results": results,
        }
        manifest_path = output_dir / "tts_results.json"
        with open(manifest_path, "w") as f:
            json.dump(manifest, f, indent=2)

        log(f"✅ Narraciones generadas en: {output_dir}")
        print(json.dumps(manifest, indent=2))
        return 0

    else:
        # Local XTTS provider
        with open(info_path) as f:
            clone_info = json.load(f)

        speaker_wavs = clone_info.get("samples", [])
        if not speaker_wavs:
            err("No hay muestras de voz en clone_info.json")
            return 1

        try:
            from TTS.api import TTS

            tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2", gpu=args.gpu)

            for lang_code, text in available.items():
                xtts_lang = XTTS_LANG_CODES.get(lang_code, lang_code)
                output_file = output_dir / f"narration_{lang_code}.wav"

                log(f"  🌍 {LANGUAGES.get(lang_code, lang_code)} ({lang_code})...")

                try:
                    tts.tts_to_file(
                        text=text,
                        speaker_wav=speaker_wavs,
                        language=xtts_lang,
                        file_path=str(output_file),
                    )

                    file_size = output_file.stat().st_size
                    results[lang_code] = {
                        "file": str(output_file),
                        "size": file_size,
                        "status": "ok",
                    }
                    log(f"    ✅ {output_file.name} ({file_size:,} bytes)")

                except Exception as e:
                    err(f"Error generando {lang_code}: {e}")
                    results[lang_code] = {"status": "error", "error": str(e)}

            # Save results manifest
            manifest = {
                "model": "xtts_v2",
                "languages": list(available.keys()),
                "results": results,
            }
            manifest_path = output_dir / "tts_results.json"
            with open(manifest_path, "w") as f:
                json.dump(manifest, f, indent=2)

            log(f"✅ Narraciones generadas en: {output_dir}")
            print(json.dumps(manifest, indent=2))
            tts = None
            return 0

        except ImportError as e:
            err(f"Error de importación: {e}")
            return 1
        except Exception as e:
            err(f"Error en TTS: {e}")
            return 1


def cmd_preview(args):
    """Preview an audio file using afplay (macOS) or ffplay."""
    audio_file = Path(args.file)
    if not audio_file.exists():
        err(f"Archivo no encontrado: {audio_file}")
        return 1

    log(f"▶️ Reproduciendo: {audio_file}")

    if sys.platform == "darwin":
        code, _, _ = run_cmd(["afplay", str(audio_file)])
    else:
        code, _, _ = run_cmd(["ffplay", "-nodisp", "-autoexit", str(audio_file)])

    return code


# ── Main ───────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Voice Pipeline — Clonación de voz + TTS multilingüe"
    )
    parser.add_argument("--gpu", action="store_true", help="Usar GPU para inferencia")

    subparsers = parser.add_subparsers(dest="command", required=True)

    # check
    subparsers.add_parser("check", help="Verificar disponibilidad del sistema")

    # install
    install_parser = subparsers.add_parser("install", help="Instalar dependencias")
    install_parser.add_argument("--with-gpu", action="store_true", help="Instalar torch con CUDA")

    # clone
    clone_parser = subparsers.add_parser("clone", help="Clonar voz desde muestras WAV")
    clone_parser.add_argument("samples_dir", help="Directorio con archivos sample_*.wav")
    clone_parser.add_argument("--output-dir", "-o", default="voice_clone", help="Directorio de salida")
    clone_parser.add_argument("--test", action="store_true", help="Generar audio de prueba")

    # tts
    tts_parser = subparsers.add_parser("tts", help="Generar narración TTS")
    tts_parser.add_argument("clone_dir", help="Directorio con clone_info.json")
    tts_parser.add_argument("texts_file", help="Archivo JSON con textos por idioma")
    tts_parser.add_argument("--output-dir", "-o", default="tts_output", help="Directorio de salida")
    tts_parser.add_argument("--provider", default="local", choices=["local", "minimax"], help="Proveedor de audio (local o minimax)")

    # preview
    preview_parser = subparsers.add_parser("preview", help="Reproducir archivo de audio")
    preview_parser.add_argument("file", help="Archivo WAV a reproducir")

    args = parser.parse_args()

    # Global GPU flag
    if hasattr(args, "gpu"):
        os.environ["TTS_USE_GPU"] = "1" if args.gpu else "0"

    commands = {
        "check": cmd_check,
        "install": cmd_install,
        "clone": cmd_clone,
        "tts": cmd_tts,
        "preview": cmd_preview,
    }

    sys.exit(commands[args.command](args))


if __name__ == "__main__":
    main()
