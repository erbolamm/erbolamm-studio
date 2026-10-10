#!/usr/bin/env python3
"""
locucion_multidioma.py — Suite de Locución Multi-Idioma Soberana (ErBolamm Studio).
Toma un guion en español, lo traduce automáticamente a los 5 idiomas oficiales
del ecosistema (inglés, francés, alemán, italiano y portugués) y sintetiza las 6 pistas
con la voz clonada de Javier Mateo mediante XTTS v2 en Apple Silicon Metal (MPS).

Uso:
  .venv/bin/python3 locucion_multidioma.py "Texto del guion en español..."
  .venv/bin/python3 locucion_multidioma.py --file guion.txt --slug spot_calca
  .venv/bin/python3 locucion_multidioma.py "Solo inglés y francés" --langs en,fr
"""

import sys
import os
import re
import json
import time
import argparse
from pathlib import Path
import urllib.request
import urllib.parse

# Importar motor base de clonación de erbolamm-studio
SCRIPT_DIR = Path(__file__).parent
sys.path.insert(0, str(SCRIPT_DIR))
import clone_voice

# Idiomas oficiales del ecosistema ErBolamm y CalcaApp (17 idiomas)
IDIOMAS_CANONICOS = {
    # 6 canónicos de tiendas (App Store / Play Store)
    "es": {"nombre": "Español", "flag": "🇪🇸"},
    "en": {"nombre": "English", "flag": "🇬🇧"},
    "fr": {"nombre": "Français", "flag": "🇫🇷"},
    "de": {"nombre": "Deutsch", "flag": "🇩🇪"},
    "it": {"nombre": "Italiano", "flag": "🇮🇹"},
    "pt": {"nombre": "Português", "flag": "🇵🇹"},
    # Idiomas globales adicionales de CalcaApp
    "ar": {"nombre": "العربية", "flag": "🇸🇦"},
    "zh": {"nombre": "中文", "flag": "🇨🇳"},
    "ja": {"nombre": "日本語", "flag": "🇯🇵"},
    "ko": {"nombre": "한국어", "flag": "🇰🇷"},
    "hi": {"nombre": "हिन्दी", "flag": "🇮🇳"},
    "ru": {"nombre": "Русский", "flag": "🇷🇺"},
    "tr": {"nombre": "Türkçe", "flag": "🇹🇷"},
    "pl": {"nombre": "Polski", "flag": "🇵🇱"},
    "id": {"nombre": "Bahasa Indonesia", "flag": "🇮🇩"},
    "vi": {"nombre": "Tiếng Việt", "flag": "🇻🇳"},
    "fa": {"nombre": "فارسی", "flag": "🇮🇷"},
}

CENTRAL_AUDIOS_DIR = Path("/Users/apliarte/trabajo/erbolamm-trabajo/control-erbolamm/difusion/locucion/audios")

def traducir_frase(frase: str, origen: str, destino: str) -> str:
    """Traduce una sola frase con doble proveedor (MyMemory + Google GTX fallback)."""
    frase = frase.strip()
    if not frase or origen == destino:
        return frase

    # Proveedor 1: MyMemory Translated API
    try:
        url_mm = f"https://api.mymemory.translated.net/get?q={urllib.parse.quote(frase)}&langpair={origen}|{destino}"
        req_mm = urllib.request.Request(
            url_mm,
            headers={"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"}
        )
        with urllib.request.urlopen(req_mm, timeout=8) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            trad = data.get("responseData", {}).get("translatedText", "")
            if trad and not trad.startswith("MYMEMORY WARNING"):
                return trad.strip()
    except Exception:
        pass

    # Proveedor 2: Google GTX
    try:
        url_gtx = (
            "https://translate.googleapis.com/translate_a/single?client=gtx"
            f"&sl={origen}&tl={destino}&dt=t&q=" + urllib.parse.quote(frase)
        )
        req_gtx = urllib.request.Request(
            url_gtx,
            headers={"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"}
        )
        with urllib.request.urlopen(req_gtx, timeout=8) as resp:
            res = json.loads(resp.read().decode("utf-8"))
            partes = [s[0] for s in res[0] if s and s[0]]
            if partes:
                return "".join(partes).strip()
    except Exception:
        pass

    return frase

def traducir(texto: str, origen: str = "es", destino: str = "en") -> str:
    """Traduce texto dividiendo en frases para garantizar máxima precisión y evitar límites de rate."""
    if origen == destino:
        return texto.strip()

    frases = re.split(r'(?<=[.!?])\s+', texto.strip())
    traducidas = [traducir_frase(f, origen, destino) for f in frases if f.strip()]
    return " ".join(traducidas).strip()

def procesar_suite(texto_es: str, idiomas=None, slug=None, ref_wav=None, speed=1.15, temperature=0.75, pause_ms=200):
    """Genera la suite completa de locuciones en los idiomas especificados con control de ritmo."""
    if idiomas is None:
        idiomas = list(IDIOMAS_CANONICOS.keys())

    if slug is None:
        slug = re.sub(r'[^a-zA-Z0-9_-]', '_', texto_es[:24]).strip('_').lower()
        if not slug:
            slug = "spot"

    print("═" * 68)
    print("🎙️ SUITE DE LOCUCIÓN MULTI-IDIOMA CON VOZ SOBERANA DE JAVIER MATEO")
    print(f"Texto original (ES): \"{texto_es[:80]}{'...' if len(texto_es)>80 else ''}\"")
    print(f"Idiomas objetivo: {', '.join([i.upper() for i in idiomas])}")
    print(f"Ajustes: Velocidad: {speed}x · Expresividad: {temperature} · Pausa: {pause_ms}ms")
    print("═" * 68)

    # 1. Traducir el texto a los idiomas solicitados
    traducciones = {}
    print("\n[1/2] Traduciendo guion...")
    for lang in idiomas:
        info = IDIOMAS_CANONICOS.get(lang, {"nombre": lang, "flag": "🌐"})
        if lang == "es":
            traducciones[lang] = texto_es.strip()
            print(f"  {info['flag']} {info['nombre']} (ES): Texto original")
        else:
            try:
                traducido = traducir(texto_es, origen="es", destino=lang)
                traducciones[lang] = traducido
                print(f"  {info['flag']} {info['nombre']} ({lang.upper()}): \"{traducido[:60]}...\"")
            except Exception as e:
                print(f"  [!] Error traduciendo a {lang}: {e}")
                traducciones[lang] = texto_es.strip()

    # 2. Inicializar XTTS v2 una sola vez para toda la tanda
    print("\n[2/2] Sintetizando locuciones neuronales con tu voz (XTTS v2 · Apple Silicon MPS)...")
    t_inicio = time.time()
    
    # Pre-cargar TTS
    tts = clone_voice.get_tts()
    ref_audio = ref_wav or clone_voice.get_ref_wav()
    print(f"[i] Molde vocal maestro: {Path(ref_audio).name}")

    resultados = {}
    for idx, lang in enumerate(idiomas, start=1):
        info = IDIOMAS_CANONICOS.get(lang, {"nombre": lang, "flag": "🌐"})
        txt = traducciones[lang]
        out_name = f"locucion_{slug}_{lang}.wav"

        print(f"\n  [{idx}/{len(idiomas)}] {info['flag']} Sintetizando {info['nombre']} ({lang.upper()})...")
        t_lang_inicio = time.time()

        try:
            # Invocar síntesis directa conservando la sesión del modelo
            out_file = clone_voice.clone(
                text=txt,
                lang_code=lang,
                ref_wav=ref_audio,
                output_name=out_name,
                speed=speed,
                temperature=temperature,
                pause_ms=pause_ms
            )
            t_dur = round(time.time() - t_lang_inicio, 1)

            # Generar también la copia fija con nombre canónico estándar
            standard_name = f"locucion_{lang}.wav"
            if CENTRAL_AUDIOS_DIR.exists():
                import shutil
                shutil.copyfile(out_file, CENTRAL_AUDIOS_DIR / standard_name)

            resultados[lang] = {
                "idioma": lang,
                "nombre": info["nombre"],
                "texto": txt,
                "archivo": out_name,
                "url": f"/difusion/locucion/audios/{standard_name}",
                "tiempo_inferencia": f"{t_dur}s",
                "velocidad": f"{speed}x"
            }
        except Exception as err:
            print(f"  [✗] Error sintetizando {lang}: {err}")

    t_total = round(time.time() - t_inicio, 1)
    print("\n" + "═" * 68)
    print(f"✅ Suite completada en {t_total}s ({len(resultados)}/{len(idiomas)} pistas generadas)")

    # 3. Guardar manifiesto de la suite para la interfaz web (acumulativo)
    if CENTRAL_AUDIOS_DIR.exists():
        manifest_path = CENTRAL_AUDIOS_DIR / "suite_activa.json"
        pistas_acumuladas = {}
        if manifest_path.exists():
            try:
                with open(manifest_path, "r", encoding="utf-8") as f:
                    antiguo = json.load(f)
                    if antiguo.get("texto_original", "").strip() == texto_es.strip() or antiguo.get("slug") == slug:
                        pistas_acumuladas = antiguo.get("pistas", {})
            except Exception:
                pass

        pistas_acumuladas.update(resultados)

        manifest_data = {
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "slug": slug,
            "texto_original": texto_es,
            "total_idiomas": len(pistas_acumuladas),
            "tiempo_total": f"{t_total}s",
            "velocidad": f"{speed}x",
            "expresividad": temperature,
            "pausa_ms": pause_ms,
            "pistas": pistas_acumuladas
        }
        with open(manifest_path, "w", encoding="utf-8") as f:
            json.dump(manifest_data, f, ensure_ascii=False, indent=2)
        print(f"[✓] Manifiesto activo actualizado con {len(pistas_acumuladas)} idiomas en: {manifest_path.name}")

    return resultados

def main():
    parser = argparse.ArgumentParser(description="Suite de Locución Multi-Idioma Soberana (XTTS v2)")
    parser.add_argument("text", nargs="?", help="Texto en español a traducir y locutar")
    parser.add_argument("--file", "-f", help="Ruta a un archivo de texto con el guion en español")
    parser.add_argument("--langs", "-l", help="Idiomas separados por coma (default: es,en,pt,fr,de,it)")
    parser.add_argument("--slug", "-s", help="Identificador de la campaña o archivo (default: derivado del texto)")
    parser.add_argument("--ref", "-r", help="WAV de referencia alternativo")
    parser.add_argument("--speed", "-v", type=float, default=1.15, help="Velocidad/ritmo de locución (default: 1.15)")
    parser.add_argument("--temperature", "-t", type=float, default=0.75, help="Temperatura/expresividad (default: 0.75)")
    parser.add_argument("--pause-ms", "-p", type=int, default=200, help="Pausa entre frases en ms (default: 200)")

    args = parser.parse_args()

    texto = None
    if args.file:
        p = Path(args.file)
        if not p.exists():
            print(f"❌ Archivo no encontrado: {args.file}")
            sys.exit(1)
        texto = p.read_text(encoding="utf-8").strip()
    elif args.text:
        texto = args.text.strip()
    else:
        parser.print_help()
        sys.exit(1)

    idiomas = None
    if args.langs:
        idiomas = [x.strip().lower() for x in args.langs.split(",") if x.strip()]

    procesar_suite(
        texto_es=texto,
        idiomas=idiomas,
        slug=args.slug,
        ref_wav=args.ref,
        speed=args.speed,
        temperature=args.temperature,
        pause_ms=args.pause_ms
    )

if __name__ == "__main__":
    main()
