# ApliArte Design — Guía de Uso

> Motor de diseño para generar videos, screenshots y presentaciones profesionales de tus proyectos.

---

## ¿Qué es?

ApliArte Design es un motor que convierte HTML en piezas de marketing profesionales:
- **Videos verticales** para TikTok, Reels e Stories
- **Videos horizontales** para YouTube y presentaciones
- **Screenshots con marco** de iPhone, Android, macOS y Chrome
- **Animaciones** con efectos profesionales

No es una app con interfaz — es un conjunto de componentes y scripts que tú (o un agente IA) usa para crear diseños.

---

## ¿Qué necesito?

| Requisito | Cómo instalarlo | ¿Ya lo tengo? |
|-----------|----------------|---------------|
| Node.js | `brew install node` | Probablemente sí |
| ffmpeg | `brew install ffmpeg` | `which ffmpeg` |
| Playwright | `npm install -g playwright && npx playwright install chromium` | `npm list -g playwright` |

---

## ¿Cómo funciona?

```
1. Creas un archivo HTML con tu diseño (o le pides a un agente IA que lo haga)
2. Abres el HTML en Chrome para previsualizar
3. Ejecutas un comando para exportar a MP4
4. Subes el video a TikTok/YouTube/Instagram
```

---

## Forma rápida: Pedir a un agente IA

Abre tu proyecto en VS Code (con Windsurf, Cursor, Codex, o cualquier editor con IA) y escribe:

### Para un video vertical (TikTok):
```
Lee design-engine/SKILL.md y hazme un video vertical de 20 segundos
para promocionar [nombre del proyecto]. Usa capturas reales del proyecto.
Expórtalo a MP4 en promo/videos/vertical.mp4
```

### Para screenshots de App Store:
```
Lee design-engine/SKILL.md y genera screenshots con marco iPhone
del proyecto [nombre]. Usa las capturas de media/screenshots/.
Guárdalas en promo/screenshots/ios/
```

### Para un video "What's New":
```
Lee design-engine/SKILL.md y hazme un video vertical mostrando
las novedades de la versión X.X de [proyecto]. Lee el CHANGELOG.md
para sacar las features. Exporta a MP4.
```

---

## Forma manual: Paso a paso

### 1. Crear el HTML

Usa una plantilla de `design-engine/templates/` como base:

| Plantilla | Para qué | Resolución |
|-----------|----------|-----------|
| `vertical-promo.html` | TikTok/Reels | 1080×1920 |
| `app-showcase.html` | Demo de app | 1920×1080 |
| `screenshot-set.html` | App Store/Play Store | Variable |
| `feature-reel.html` | Novedades de versión | 1080×1920 |

### 2. Previsualizar

Abre el HTML directamente en Chrome:
```bash
open mi-diseño.html
```

### 3. Exportar a video

```bash
# Desde la raíz de erbolamm-com:
NODE_PATH=$(npm root -g) node design-engine/scripts/render-video.cjs \
  ruta/al/archivo.html \
  --duration=22 \
  --width=1080 \
  --height=1920
```

Parámetros:
- `--duration`: Duración en segundos
- `--width` / `--height`: Resolución (1080×1920 vertical, 1920×1080 horizontal)
- `--trim`: Recorte manual del inicio (normalmente automático)

### 4. Añadir música (opcional)

```bash
bash design-engine/scripts/add-music.sh video.mp4 design-engine/sfx/magic/sparkle.mp3
```

### 5. Convertir a 60fps + GIF (opcional)

```bash
bash design-engine/scripts/convert-formats.sh video.mp4
```

---

## Estructura de archivos de promo

Cuando generas assets para un proyecto, se guardan así:

```
tu-proyecto/
└── promo/
    ├── assets/           ← Logos, iconos originales
    ├── screenshots/      ← Con marcos (iPhone, Android...)
    ├── videos/           ← MP4 finales
    ├── source/           ← HTML fuente (para regenerar)
    └── brand-spec.md     ← Colores y tipografía
```

---

## Colores del ecosistema

| Pilar | Color | Para qué proyectos |
|-------|-------|---------------------|
| ✏️ Creación | Rosa `#ff4e83` | CalcaApp, diseños |
| 🎓 Educación | Azul `#1976D2` | ApliArte, TutoGrati |
| 🎭 Cultura | Verde `#388E3C` | ElBolaDeMarbella |
| 🔧 Herramientas | Naranja `#FF8F00` | Key Master, extensiones |
| 🤖 Hardware | Dorado `#FFB300` | ApliMemo |

---

## Efectos de sonido disponibles

En `design-engine/sfx/`:

| Categoría | Archivos | Uso |
|-----------|---------|-----|
| `magic/` | sparkle, ai-process, transform | Apariciones mágicas |
| `transition/` | whoosh, slide-in, dissolve | Cambios de escena |
| `impact/` | logo-reveal, drop-thud | Momento culminante |
| `ui/` | click, hover, focus | Interacciones |
| `feedback/` | success-chime, notification | Confirmaciones |
| `keyboard/` | type, enter | Escritura |

---

## Preguntas frecuentes

**¿Necesito saber programar?**
No. Puedes pedirle a un agente IA que haga todo por ti. Solo necesitas describir lo que quieres.

**¿Se puede editar el diseño después?**
Sí. Los HTML fuente se guardan en `promo/source/`. Ábrelos en Chrome para ver, edita el HTML, y vuelve a exportar.

**¿Funciona offline?**
La previsualización necesita internet (carga React y fuentes desde CDN). La exportación a MP4 funciona offline si ya cargaste el HTML una vez.

**¿Puedo añadir mis propios componentes?**
Sí. Crea un `.jsx` en `design-engine/assets/` siguiendo el patrón de los existentes.

---

## Origen

Basado en [Huashu-Design](https://github.com/alchaincyf/huashu-design). Adaptado al español y al ecosistema ApliArte por Javier Mateo.
