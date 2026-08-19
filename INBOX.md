# INBOX — Protocolo Maestro de Procesamiento de Proyectos

> **Instrucción para Agentes y ErBolamm Studio**: 
> Este documento define el estándar oficial para analizar, categorizar y publicar proyectos en el **Universo ErBolamm** (`universe.json`).

---

## ⚡ Resumen Ejecutivo del Flujo

```
                       ┌─────────────────────────────────────┐
                       │  Proyecto en INBOX/ o URL de GitHub │
                       └──────────────────┬──────────────────┘
                                          │
                                          ▼
                       ┌─────────────────────────────────────┐
                       │       Paso 1: Análisis Rápido       │
                       │   (README, LICENSE, Promo, Landing) │
                       └──────────────────┬──────────────────┘
                                          │
                    ┌─────────────────────┴─────────────────────┐
                    ▼                                           ▼
       ¿Tiene Landing y está en orden?             ¿Faltan Assets, Promo o Docs?
                    │                                           │
                    ▼                                           ▼
      ┌───────────────────────────┐               ┌───────────────────────────┐
      │  CAMINO A: Inyección Directa│               │   CAMINO B: Orchestrator  │
      │  - Registrar en universe.json│              │  - Clonar a INBOX/$nombre │
      │  - Sin descargas pesadas   │              │  - 7 agentes generan assets│
      └───────────────────────────┘               └───────────────────────────┘
```

---

## 📋 Checklist Oficial de Requisitos

| Elemento | Estado | Criterio de Aprobación |
| :--- | :---: | :--- |
| **README.md** | **Obligatorio** | Debe incluir descripción, propósito y el **Bloque de Cierre Oficial** (Paso 3.5: Autor, Nota Multilingüe en `<details>`, Apoyo y Licencia). |
| **LICENSE** | **Obligatorio** | Licencia formal del proyecto (MIT por defecto © 2026 ApliArte). |
| **Landing Page** | **Obligatorio** | Cumple si existe `landing.html`/`index.html` **O** si el `README.md` incluye una URL pública activa (`*.web.app`, `*.firebaseapp.com`, `*.vercel.app`, `*.pages.dev`, `*.github.io`). |
| **Carpeta promo/** | *Recomendado* | Requerido para promoción en redes y apps móviles: `promo/screenshots/`, `promo/videos/`, `promo/brand-spec.md`. |

---

## 🧠 Contexto de Javier (ErBolamm / ApliArte)

- **Javier Mateo**: Aprendió a programar desde el 4 de abril de 2023.
- **Formato de comunicación**: Frases directas, listas numeradas, conceptos claros, español.
- **Ecosistema**: Apps multiplataforma (Flutter), webs (Cloudflare + Firebase), extensiones y workflows.
- **Universo de Proyectos**: Centralizado en [universe.json](file:///Users/apliarte/trabajo/erbolamm-studio/universe.json) y visualizado en [erbolamm-hub.web.app](https://erbolamm-hub.web.app).
- **Regla Canónica de Redes Sociales**:
  - Todas las redes son `@erbolamm`: GitHub (`github.com/erbolamm`), X/Twitter (`x.com/erbolamm`), PayPal (`paypal.me/erbolamm`), Ko-fi (`ko-fi.com/C0C11TWR1K`).
  - **⚠️ Única Excepción (Twitch)**: Es `@apliarte` ➔ Canal: `https://www.twitch.tv/apliarte` · Tips: `streamelements.com/apliarte/tip` (NUNCA usar /erbolamm en Twitch).

---

## 📋 Paso 1 — Análisis automático

Nada más leer esto, analiza el proyecto y determina:

1. **Tipo de proyecto**: Flutter App, Paquete Dart, Node/Web, Extensión VS Code, Python, n8n Workflow.
2. **Estado**: Completo, En desarrollo (WIP), Solo esqueleto, Descartable.
3. **Landing / URL Pública**: Si ya tiene web activa (`*.web.app`, `*.github.io`) o si requiere generarla.
4. **Acción sugerida**: Inyectar directo en `universe.json` o enviar al Orchestrator.

---

## 📋 Paso 2 — Preguntar a Javier

1. "¿Qué quieres hacer con este proyecto?"
   - a) **Publicar en Universo** → Registrar directamente con sus URLs actuales.
   - b) **Procesar con Orchestrator** → Generar screenshots, videos, audios TTS y landing.
   - c) **Fusionar / Aprovechar partes** → Integrar en otro proyecto existente.
   - d) **Descartar / Archivar**.

---

## 📋 Paso 3 — Requisitos por tipo de proyecto

### App móvil (Flutter)
| Campo | Obligatorio | Ejemplo |
|---|:---:|---|
| `name` | ✅ | CalcaApp |
| `description` | ✅ | Mesa de luz digital |
| `urls.playstore` | ✅ (Android) | https://play.google.com/store/apps/details?id=... |
| `urls.landing` | ✅ | https://apliarte-link.web.app |
| `key/` (Keystore Android) | ✅ (Android) | `key/` con `.keystore`, `.pem` y `leeme.txt` |

> **Firma Android (OBLIGATORIO si Android):** la app debe tener carpeta `key/` con keystore, `.pem` y `leeme.txt` documentado. Ver **Paso 3.12**.

### Extensión VS Code
| Campo | Obligatorio | Ejemplo |
|-------|-------------|---------|
| `name` | ✅ | Key Master |
| `description` | ✅ | Gestión de claves API |
| `urls.github` | ✅ | https://github.com/erbolamm/... |
| `urls.marketplace` | ⬜ | https://marketplace.visualstudio.com/... |

### Paquete / Librería
| Campo | Obligatorio | Ejemplo |
|-------|-------------|---------|
| `name` | ✅ | apliarte_faq |
| `description` | ✅ | FAQ integrable para apps Flutter |
| `urls.github` | ✅ | https://github.com/erbolamm/... |
| `urls.pub` | ⬜ (si Dart) | https://pub.dev/packages/... |
| `urls.npm` | ⬜ (si JS/TS) | https://npmjs.com/package/... |

### Web / Blog
| Campo | Obligatorio | Ejemplo |
|-------|-------------|---------|
| `name` | ✅ | ApliArte |
| `description` | ✅ | Hub de Aprendizaje de Flutter |
| `urls.web` | ✅ | https://apliarte.com |

### Dispositivo / Hardware
| Campo | Obligatorio | Ejemplo |
|-------|-------------|---------|
| `name` | ✅ | ApliMemo |
| `description` | ✅ | Asistente Cognitivo de Bolsillo |
| `urls.landing` | ⬜ (cuando exista) | https://aplimemo.apliarte.com |

## 📋 Paso 3.5 — Regla obligatoria de README (GitHub o idea nueva)

Si el proyecto está publicado en GitHub **o** es un proyecto nuevo (solo idea inicial), el `README.md` debe quedar visualmente cuidado y **terminar siempre** con este bloque final (sin ninguna sección después):

```md
## Autor
Javier Mateo (ApliArte) — github.com/erbolamm

## 💬 Una nota personal del autor / A personal note from the author
ℹ️ Nota: El texto siguiente es un mensaje personal del autor, escrito en varios idiomas para que pueda leerlo gente de todo el mundo. Esto no implica que el proyecto tenga soporte funcional completo en esos idiomas.

ℹ️ Note: The text below is a personal message from the author, written in several languages so people around the world can read it. This does not imply full multilingual feature support in those languages.

<details>
<summary>🇪🇸 Español</summary>
[Mensaje completo adaptado al proyecto analizado: qué es, para qué sirve y por qué se comparte]
</details>

<details>
<summary>🇬🇧 English</summary>
[Full message adapted to the analyzed project: what it is, what it does, and why it is shared]
</details>

<details>
<summary>🇧🇷 Português</summary>
[Mensagem completa adaptada ao projeto analisado: o que é, para que serve e por que é compartilhado]
</details>

<details>
<summary>🇫🇷 Français</summary>
[Message complet adapté au projet analysé : ce que c'est, à quoi il sert et pourquoi il est partagé]
</details>

<details>
<summary>🇩🇪 Deutsch</summary>
[Vollständige Nachricht zum analysierten Projekt: was es ist, wofür es dient und warum es geteilt wird]
</details>

<details>
<summary>🇮🇹 Italiano</summary>
[Messaggio completo adattato al progetto analizzato: cos'è, a cosa serve e perché viene condiviso]
</details>

## 💖 Apoya el proyecto
Herramienta gratuita y open source. Si te ahorra tiempo, un café ayuda a mantener el desarrollo.

| Plataforma | Enlace |
|-----------|--------|
| PayPal | paypal.me/erbolamm |
| Ko-fi | ko-fi.com/C0C11TWR1K |
| Twitch Tip | streamelements.com/apliarte/tip |

🌐 Sitio Oficial · 📦 GitHub

## Licencia
MIT — © 2026 ApliArte

## About
[Descripción corta real del proyecto actual]
```

Reglas adicionales de esta sección final:
1. Debe ser el cierre real del README (no añadir nada después de `About`).
2. Mantener exactamente el orden de secciones del bloque.
3. Se permite mejorar estilo visual (tablas, enlaces Markdown, detalles plegables), sin romper el contenido mínimo.
4. En `About`, adaptar solo la descripción al proyecto concreto que se está publicando.
5. Los idiomas deben ir en formato desplegable con `<details><summary>...</summary>...</details>` como en `corrector-vscode`.
6. El texto de cada idioma debe hablar del proyecto actual (nombre, utilidad, propósito y estado), no copiar literalmente el mensaje de otro repositorio.
7. Si el proyecto es una **extensión de VS Code** (tipo `.vsix`), debe incluir una sección **"Compatibilidad"** indicando que funciona en todos los editores basados en VS Code: **VS Code, Cursor, Windsurf, Antigravity y VS Codium**. Esto se coloca antes de la sección "Contribuir" o "Autor", según corresponda.

---

## 📋 Paso 3.6 — Verificación obligatoria de privacidad iOS (apps con anuncios)

> **Aplica a:** TODA app Flutter/iOS que muestre anuncios (AdMob, Yandex, o cualquier red).
> **Cuándo ejecutar:** Siempre que analices una app iOS del ecosistema o prepares una actualización.

### SKAdNetworkItems (OBLIGATORIO)

El archivo `ios/Runner/Info.plist` DEBE contener la lista completa de SKAdNetworkIdentifier.
Sin estos IDs, los compradores de anuncios no pueden atribuir instalaciones → **pujan menos → menos revenue**.

**Lista mínima actualizada (abril 2026 — 59 IDs):**

```
cstr6suwn9  4fzdc2evr5  2fnua5tdw4  ydx93a7ass  p78axxw29g
v72qych5uu  ludvb6z3bs  cp8zw746q7  3sh42y64q3  c6k4g5qg8m
s39g8k73mm  wg4vff78zm  3qy4746246  f38h382jlk  hs6bdukanm
mlmmfzh3r3  v4nxqhlyqp  wzmmz9fp6w  su67r6k2v3  yclnxrl5pm
t38b2kh725  7ug5zh24hu  gta9lk7p23  vutu7akeur  y5ghdn5j9k
v9wttpbfk9  n38lu8286q  47vhws6wlr  kbd757ywx3  9t245vhmpl
a2p9lx4jpn  22mmun2rn5  44jx6755aq  k674qkevps  4468km3ulz
2u9pt9hc89  8s468mfl3y  klf5c3l5u5  ppxm28t8ap  kbmxgpxpgc
uw77j35x4d  578prtvx9j  4dzt52r2t5  tl55sbb4fm  c3frkrj4fj
e5fvkxwrpn  8c4e2ghe7u  3rd42ekr43  97r2b46745  3qcr597p9d
4pfyvq9l8r  5a6flpkh64  5l3tpt7t6e  n6fk4nfna4  n9x2a789qt
pwa73g5rt2  r26jy69rpl  ecpz2srf59  eh6m2bh4zr
```

Cada ID va dentro de un `<dict>` con clave `SKAdNetworkIdentifier` y el valor `ID.skadnetwork`.

**Fuente oficial:** [Estrategias de privacidad para iOS — Google AdMob](https://developers.google.com/admob/ios/privacy/strategies)
⚠️ Google actualiza esta lista periódicamente. Antes de aplicar, verificar si hay IDs nuevos en la fuente oficial.

### NSUserTrackingUsageDescription (OBLIGATORIO)

El `Info.plist` DEBE tener esta clave con un texto que explique por qué se pide permiso de tracking.
Sin esto, Apple rechaza la app en revisión.

```xml
<key>NSUserTrackingUsageDescription</key>
<string>Este identificador se usará para mostrarte anuncios personalizados.</string>
```

Idealmente, localizar en los idiomas que soporte la app (crear archivos `InfoPlist.strings` por cada `.lproj`).

### ATT — App Tracking Transparency (OBLIGATORIO en código)

La app DEBE llamar a `requestTrackingAuthorization()` ANTES de cargar anuncios.
Sin esto, el IDFA no está disponible → los anunciantes pujan menos → menos revenue.

En Flutter se usa el paquete `app_tracking_transparency`.

### Checklist rápido para el agente

Al analizar una app iOS con anuncios, verificar:

- [ ] `Info.plist` tiene `SKAdNetworkItems` con los 59+ IDs
- [ ] `Info.plist` tiene `NSUserTrackingUsageDescription`
- [ ] Si la app soporta varios idiomas: existen `InfoPlist.strings` localizados para `NSUserTrackingUsageDescription`
- [ ] El código llama a `requestTrackingAuthorization()` ANTES de cargar ads
- [ ] Si usa UMP/consentimiento: AdMob se inicializa DESPUÉS de resolver UMP y, en iOS, DESPUÉS de ATT
- [ ] `Info.plist` NO tiene `WKAppBoundDomains` (bloquea carga de anuncios)
- [ ] Si implementa anuncios nativos: Android usa `MediaView` registrado en `NativeAdView`
- [ ] Si implementa anuncios nativos: iOS usa `GADMediaView` visible en la jerarquía y registrado en `GADNativeAdView`
- [ ] Si usa anuncios nativos: probar con ad units de test y/o Native Ad Validator antes de publicar
- [ ] Revisar si `Publisher first-party ID` está activo por defecto y decidir explícitamente si mantenerlo o desactivarlo según la postura de privacidad del proyecto
- [ ] Si usa Yandex: los IDs de ad units son los REALES, no los demo (`demo-*-yandex`)

### Reglas prácticas de implementación (privacy + monetización)

1. **No cargar anuncios demasiado pronto.**
   - Error típico: inicializar `MobileAds` en `main.dart` o en el arranque global antes del consentimiento.
   - Regla correcta: primero UMP, luego ATT en iOS, y recién después cargar anuncios.

2. **UMP y ATT NO son lo mismo.**
   - **UMP** cubre consentimiento publicitario / privacidad regulatoria.
   - **ATT** cubre acceso a tracking de Apple (`IDFA`).
   - En iOS con AdMob, si se usan ambos, el orden recomendado es: **UMP → ATT → carga de ads**.

3. **MediaView es obligatoria en native ads con assets de imagen o video.**
   - Si el ad nativo puede traer media, no alcanza con mostrar texto o CTA.
   - Hay que registrar `MediaView` / `GADMediaView` en la implementación nativa.

4. **`WKAppBoundDomains` es una bandera roja.**
   - Si aparece en `Info.plist`, Google Mobile Ads SDK puede dejar de cargar anuncios.
   - El agente debe marcarlo como bloqueo crítico de monetización.

5. **`Publisher first-party ID` debe revisarse de forma consciente.**
   - Google lo deja activo por defecto en SDKs compatibles.
   - No siempre hay que desactivarlo, pero el proyecto debe tomar una decisión explícita: **privacy-first** o **yield-first**.

6. **No asumir cumplimiento por tener solo el `Info.plist`.**
   - Tener `SKAdNetworkItems` y `NSUserTrackingUsageDescription` NO alcanza.
   - También hay que verificar el flujo real de runtime y el orden en que se piden permisos / se inicializan ads.

---

## 📋 Paso 3.7 — Verificación obligatoria de seguridad npm / Node

> **Aplica a:** proyectos con `package.json`, `package-lock.json`, `pnpm-lock.yaml`, `bun.lock*`, `yarn.lock`, scripts Node, Vite, React, Next.js, Astro, herramientas CLI JS/TS o cualquier repo que instale dependencias desde npm.

### Fuente de referencia obligatoria

Al analizar proyectos Node/npm, revisar también esta guía externa y usarla como checklist mental:

- `lirantal/npm-security-best-practices`  
  https://github.com/lirantal/npm-security-best-practices

No hace falta copiar todo el repo al proyecto. Lo importante es que el agente **revise si el proyecto cae en alguno de esos errores clásicos de supply chain**.

### Qué debe revisar el agente

- [ ] Si el proyecto depende de `npm install` normal, evaluar si conviene `npm ci` en CI/CD para instalaciones deterministas
- [ ] Revisar scripts peligrosos en `package.json` (`postinstall`, `preinstall`, `prepare`)
- [ ] Revisar dependencias instaladas desde Git URLs o fuentes no registradas
- [ ] Verificar que no haya secretos en `.env`, `.npmrc`, scripts o README
- [ ] Revisar si el lockfile está presente y se commitea
- [ ] Evitar upgrades ciegos de dependencias sin revisar changelog / advisories
- [ ] Si el proyecto usa `npx`, revisar que no ejecute paquetes arbitrarios sin versión fijada
- [ ] Proponer escaneo de vulnerabilidades y salud del paquete antes de publicar o desplegar
- [ ] Si el repo publica paquetes npm, revisar 2FA, provenance/OIDC y superficie de dependencias

### Regla práctica

Si el proyecto es web/Node y el agente detecta `package.json`, debe incluir en su análisis una mini sección:

**Seguridad npm / supply chain**
1. Riesgos encontrados
2. Riesgos no verificados todavía
3. Qué haría antes de instalar / actualizar / desplegar

### Checklist específico: 3 capas anti-supply-chain (Alam, mayo 2026)

> Aplica a todo proyecto que consuma o publique paquetes npm. Estas 3 capas son **obligatorias** de revisar, no son opcionales.

#### Capa 1 — Scripts de instalación desactivados
- [ ] Si el proyecto usa `npm install` suelto, cambiarlo por `npm install --ignore-scripts`
- [ ] Si el proyecto tiene `postinstall`, `preinstall` o `prepare` scripts, justificarlos o eliminarlos
- [ ] Evaluar si se puede poner `ignore-scripts=true` en un `.npmrc` local del proyecto

#### Capa 2 — PNPM + cooldown
- [ ] Verificar si el proyecto ya usa pnpm. Si no, evaluar migración:
  ```bash
  npm install -g pnpm --ignore-scripts
  cd proyecto
  pnpm import         # convierte package-lock.json a pnpm-lock.yaml
  pnpm install --frozen-lockfile --ignore-scripts
  ```
- [ ] Si se migra a pnpm, configurar en `.npmrc`:
  ```
  minimum-release-age=4320
  ```
  Esto equivale a 3 días de cooldown antes de aceptar una versión recién publicada.
- [ ] Si se queda en npm, configurar en `.npmrc`:
  ```
  package-suppression=warn
  ignore-scripts=true
  ```

#### Capa 3 — Lockfile + publicación segura
- [ ] Verificar que `package-lock.json` o `pnpm-lock.yaml` esté presente y commiteado
- [ ] Si usa npm, ejecutar en CI (no local):
  ```bash
  npx lockfile-lint --path package-lock.json --allowed-hosts npm --validate-https
  ```
  Nota: en pnpm este paso no es necesario (no expone ese vector).
- [ ] Si el repositorio **publica** paquetes npm:
  - [ ] Verificar que tenga 2FA obligatorio en npm
  - [ ] Usar `npm publish --provenance` en CI con OIDC (sin tokens permanentes)
  - [ ] Tener `files` allow list en `package.json` (evitar publicar `.env` o secretos)

#### Acción mínima antes de cada deploy o actualización

El agente debe preguntar (o marcar checklist):
1. ¿Se hizo `pnpm install --frozen-lockfile` (o `npm ci`) en vez de `npm install`?
2. ¿Se revisaron las dependencias nuevas en el diff del lockfile antes de mergear?
3. Si el proyecto publica paquetes, ¿tiene 2FA + provenance activados?

#### Nota sobre proyectos privados / en desarrollo

Si el proyecto **no está publicado** y solo vive en local o en un repo privado:
- Las capas 1 y 2 siguen aplicando (evitan que un `npm install` te infecte la máquina)
- La capa 3 (publicación) no aplica hasta que el proyecto se publique
- Sí conviene tener lockfile commiteado desde el inicio para trazabilidad

### Señales de alerta fuertes

- Scripts de instalación que descargan binarios sin validar
- Dependencias Git sin necesidad clara
- Ausencia de lockfile
- `npx` sin versión fijada
- secretos en `.env.example` o `.npmrc`
- upgrades masivos sin auditoría

---

## 📋 Paso 3.8 — Verificación obligatoria de skills oficiales Dart / Flutter

> **Aplica a:** cualquier proyecto Dart o Flutter del ecosistema.

### Fuentes de referencia obligatorias

Si el proyecto usa Flutter o Dart, el agente debe revisar también estas bibliotecas oficiales de skills:

- `flutter/skills`  
  https://github.com/flutter/skills
- `dart-lang/skills`  
  https://github.com/dart-lang/skills

### Cómo interpretarlas correctamente

No son exactamente lo mismo:

- **`flutter/skills`** → buenas prácticas y workflows para apps Flutter
  - widget tests
  - integration tests
  - responsive layout
  - localization
  - routing
  - arquitectura por capas

- **`dart-lang/skills`** → buenas prácticas y workflows base para Dart
  - unit tests
  - mocks
  - análisis estático
  - resolución de conflictos de paquetes
  - CLI apps
  - pattern matching

### Regla obligatoria para el agente

Si detectas un proyecto Flutter o Dart, NO te limites a mirar el código actual.
También debes contrastar el proyecto con estas skills oficiales para detectar:

- prácticas modernas que faltan
- tests que deberían existir y no existen
- arquitectura desordenada o acoplada
- problemas de layout / localización / routing
- deuda técnica que ya tenga un workflow oficial claro

### Qué debe revisar el agente

- [ ] Si es Flutter: comparar el proyecto con `flutter/skills` para testing, arquitectura, responsive layout, localization y routing
- [ ] Si es Dart puro o mezcla Dart/Flutter: comparar también con `dart-lang/skills`
- [ ] Si el proyecto ya tiene una skill local para el mismo tema, priorizar la skill local del proyecto y usar las oficiales como contraste
- [ ] Si faltan tests, decir explícitamente qué tipo faltan: unit, widget o integration
- [ ] Si falta análisis estático o convenciones modernas, marcarlo como mejora recomendada

### Regla práctica de análisis

Cuando el proyecto sea Flutter/Dart, añadir una mini sección extra en la respuesta:

**Contraste con skills oficiales**
1. Qué ya cumple
2. Qué no cumple todavía
3. Qué skill oficial aplicaría para mejorarlo

### Prioridad correcta

1. **Primero**: reglas internas del proyecto (`AGENTS.md`, `INBOX.md`, docs propias, skills locales)
2. **Después**: `flutter/skills` y `dart-lang/skills` como referencia oficial externa
3. **Nunca** imponer una skill oficial si contradice una convención explícita del proyecto

---

## 📋 Paso 3.13 — Especificación Oficial de Landing Page (Filosofía ApliArte Link)

> **Regla de Oro**: Toda landing page (`landing.html` o `index.html`) del ecosistema ErBolamm debe seguir la **Filosofía ApliArte Link** (inspirada en https://github.com/erbolamm/apliarte-link).
> No se crean webs de marketing genéricas con humo corporativo. Se construyen páginas didácticas, directas, técnicas y humanas estructuradas en **10 bloques obligatorios**:

```
 ┌─────────────────────────────────────────────────────────────┐
 │ 1. Header con Badges de Estado y Plataformas                │
 ├─────────────────────────────────────────────────────────────┤
 │ 2. Hero con One-Liner Value Proposition y Badge de Confianza│
 ├─────────────────────────────────────────────────────────────┤
 │ 3. Grid de 6 Beneficios Técnicos (Specs Reales)             │
 ├─────────────────────────────────────────────────────────────┤
 │ 4. Cómo funciona Paso a Paso (1 al 6) + Mini FAQ            │
 ├─────────────────────────────────────────────────────────────┤
 │ 5. Descargas con Comandos One-Liner (macOS, Windows, Linux) │
 ├─────────────────────────────────────────────────────────────┤
 │ 6. Apoyo Comunitario & Early Adopters (PayPal, Ko-fi)       │
 ├─────────────────────────────────────────────────────────────┤
 │ 7. Roadmap por Fases (Fase 0 a 5: Listo, Siguiente, etc.)   │
 ├─────────────────────────────────────────────────────────────┤
 │ 8. Planes Futuros Transparentes (Con aviso "Sin pagos hoy") │
 ├─────────────────────────────────────────────────────────────┤
 │ 9. Nota Personal del Autor en 6 Idiomas (<details>)         │
 ├─────────────────────────────────────────────────────────────┤
 │ 10. Botones de Compartir en Redes & Footer MIT License      │
 └─────────────────────────────────────────────────────────────┘
```

### Detalle de los 10 Bloques Obligatorios:

1. **Header & Badges de Estado**:
   - Plataformas soportadas (`🍎 macOS`, `🪟 Windows`, `🐧 Linux`, `📱 Mobile`, `🌐 Web`).
   - Badges de confianza: `🆓 Gratis`, `🚫 Sin publicidad`, `🔒 Cifrado / Seguro`.

2. **Hero & One-Liner Directo**:
   - Titular contundente de 1 frase (ej. *"Un teclado. Un ratón. Todos tus ordenadores"* o *"De una idea a un video y proyecto auditado"*).
   - Subtítulo de 2 líneas explicando el beneficio real sin palabrerío.

3. **Grid de 6 Beneficios Técnicos**:
   - Tarjetas explicando la ingeniería real (ej. *TCP+TLS*, *MessagePack 8x más rápido*, *App nativa Flutter*, *Playwright 60fps*, *Privacidad local*).

4. **Cómo Funciona Paso a Paso (Numerado 1 al 6)**:
   - Explicación didáctica y secuencial para personas con TDAH: frases cortas, pasos 1, 2, 3, 4, 5, 6.
   - Mini FAQ de 2 o 3 dudas típicas (*"¿Usa Bluetooth?", "¿Se guardan mis datos?", etc.*).

5. **Descargas con Comandos One-Liner**:
   - Terminal copy-paste directo para que el usuario no tenga que lidiar con instaladores:
     - macOS: `curl -L ... | unzip`
     - Windows: `powershell -Command ...`
     - Linux: `curl -L ... && ./binario`

6. **Filosofía de Apoyo Comunitario & Early Adopter**:
   - Explicación honesta: *"Quien apoya hoy es un early adopter. Tendrá canje y descuentos futuros cuando salgan planes pro. Sin letra pequeña, de buena fe"*.
   - Enlaces a `PayPal` (`paypal.me/erbolamm`), `Ko-fi` (`ko-fi.com/C0C11TWR1K`), `Twitch` (`twitch.tv/apliarte`) y Tips (`streamelements.com/apliarte/tip`).

7. **Roadmap por Fases**:
   - Fases 0, 1, 2, 3, 4, 5 con estados explícitos: `Listo ✅`, `Siguiente 🟡`, `Planificado ⬜`, `Idea 💡`.

8. **Planes Futuros Transparentes**:
   - Mostrar los planes `Start`, `Pro`, `Vitalicio` en modo **`Próximamente / No disponible`**, con la advertencia: *"⚠️ Sin pagos por ahora. Hoy todo es gratis. Los enseñamos por transparencia"*.

9. **Nota Personal del Autor Multilingüe**:
   - Historia auténtica de Javier Mateo (aprendizaje autodidacta desde el 4 de abril de 2023) con acordeones desplegables `<details>` en los 6 idiomas (`ES`, `EN`, `PT`, `FR`, `DE`, `IT`).

10. **Botones de Compartir & Footer**:
    - Botones para compartir en X, LinkedIn, WhatsApp, Telegram, Reddit, Facebook, Email.
    - Footer con `© 2026 ApliArte · MIT License · Hecho con 🧠 desde 2023`.

---

## 📋 Paso 4 — Auditoría de Marketing (ApliArte Design)

> Después de decidir qué hacer con el proyecto, verifica si tiene assets de marketing.

### Principio: la app real es la fuente

Cuando el proyecto es Flutter/Dart con web demo (`example/`), **NO generes HTML mockups**. Usá la app Flutter real como fuente:

1. Si ya existe una web Flutter publicada (GitHub Pages, Firebase Hosting) → usa esa URL
2. Si no está publicada pero existe `example/` → intentá buildearla
3. Solo si no existe web Flutter ni `example/` → ahí sí usa HTML mockups

---

### 4.1 — Detectar web Flutter existente

```bash
# Buscar build web existente
ls {proyecto}/example/build/web/index.html 2>/dev/null && echo "✅ Build web existe"
ls {proyecto}/build/web/index.html 2>/dev/null && echo "✅ Build web en raíz"

# Buscar si se puede construir
ls {proyecto}/example/pubspec.yaml 2>/dev/null && echo "✅ example/ con pubspec"
```

**Si existe build web:**
- Servir localmente: `cd {proyecto}/example/build/web && python3 -m http.server 8080`
- O directamente usar la URL publicada
- Capturar screenshots con Playwright desde la app real

**Si existe `example/` pero no build:**
```bash
cd {proyecto}/example && flutter build web --no-tree-shake-icons
```

**Si no existe nada:**
- Recién ahí generar HTML mockups con `design-engine/`

---

### 4.2 — Screenshots desde la web real con Playwright

> **Requiere:** Playwright instalado globalmente
> ```bash
> npm install -g playwright && npx playwright install chromium
> ```

Flujo recomendado (usar en vez de crear HTML mockups):

1. Servir la web Flutter localmente:
   ```bash
   cd {proyecto}/example/build/web && python3 -m http.server 8080 &
   ```

2. Usar un script Playwright como `promo/source/capture-screenshots.cjs`:
   ```javascript
   const { chromium } = require('playwright');
   const browser = await chromium.launch({ headless: true });
   const page = await browser.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 2 });
   await page.goto('http://localhost:8080', { waitUntil: 'networkidle' });
   await page.screenshot({ path: 'promo/screenshots/browser/full.png', fullPage: true });
   // Capturar componentes individuales
   await browser.close();
   ```

   ```bash
   NODE_PATH=$(npm root -g) node {proyecto}/promo/source/capture-screenshots.cjs
   ```

3. Guardar resultados en `{proyecto}/promo/screenshots/browser/`

**Para apps móviles:** además tomar screenshots con marcos iPhone/Android desde `design-engine/`.

---

### 4.3 — Assets recomendados según tipo de proyecto

| Tipo de proyecto | Screenshots | Video vertical (TikTok) | Video horizontal | Landing | Fuente |
|-----------------|:-----------:|:----------------------:|:----------------:|:-------:|--------|
| App móvil | ✅ iOS + Android | ✅ | ⬜ Opcional | ✅ (ya tiene) | App real |
| Extensión VS Code | ✅ Editor | ✅ | ⬜ Opcional | ⬜ | Editor real |
| Web / Blog | ✅ Browser | ⬜ Opcional | ⬜ Opcional | ❌ Ya es web | La web misma |
| Paquete / Librería | ⬜ Opcional | ⬜ Opcional | ⬜ Opcional | ✅ Web demo | example/ de Flutter |
| Hardware | ✅ Producto | ✅ | ⬜ Opcional | ✅ | Fotos reales |

---

### 4.4 — ¿Existe `promo/` dentro del proyecto?

- ❌ **NO existe** → Crear con esta estructura:
  ```
  promo/
  ├── assets/           ← Logos, iconos originales
  ├── screenshots/      ← Capturas desde la web real
  │   ├── ios/
  │   ├── android/
  │   └── browser/
  ├── videos/           ← MP4 finales
  ├── source/           ← Scripts de captura (Playwright .cjs)
  └── brand-spec.md     ← Colores y tipografía del proyecto
  ```
- ✅ **SÍ existe** → Revisar qué tiene y qué falta (ver tabla arriba)

### 4.5 — Script de captura reutilizable

Crear `promo/source/capture-screenshots.cjs` con este template mínimo:

```javascript
const { chromium } = require('playwright');
const { createServer } = require('http');
const { readFileSync, readdirSync, mkdirSync } = require('fs');
const { join } = require('path');

const PROMO_DIR = join(__dirname, '..');
const SCREENSHOTS_DIR = join(PROMO_DIR, 'screenshots', 'browser');
mkdirSync(SCREENSHOTS_DIR, { recursive: true });

async function main() {
  const browser = await chromium.launch({ headless: true });
  const page = await (await browser.newContext({
    viewport: { width: 1440, height: 900 }, deviceScaleFactor: 2
  })).newPage();

  // Opción A: servidor local
  // await page.goto('http://localhost:8080', { waitUntil: 'networkidle' });
  // Opción B: URL publicada
  await page.goto('https://erbolamm.github.io/mi-proyecto/', { waitUntil: 'networkidle' });

  await page.waitForTimeout(1000); // esperar render
  await page.screenshot({ path: join(SCREENSHOTS_DIR, 'full.png'), fullPage: true });

  // Capturar secciones específicas con page.locator()
  console.log('✅ Screenshots capturadas');
  await browser.close();
}
main().catch(console.error);
```

Ejecutar:
```bash
NODE_PATH=$(npm root -g) node {proyecto}/promo/source/capture-screenshots.cjs
```

### 4.6 — Colores por pilar (para diseño complementario)

Usar el color del pilar al que pertenece el proyecto (ver tabla de Pilares).
Si el proyecto ya tiene colores en `promo/brand-spec.md`, usar esos.
Si la web Flutter ya define su propia paleta, respetar la paleta existente.

---

## 📋 Paso 5 — Registrar en el universo

Si el proyecto cumple los requisitos mínimos, **añádelo a `universe.json`** con esta estructura:

```json
{
  "id": "nombre-en-kebab-case",
  "name": "Nombre Visible",
  "pillar": "creacion|educacion|cultura|herramientas|hardware",
  "type": "app|web|extension|package|device|client",
  "description": "Descripción corta",
  "urls": { ... },
  "status": "published|wip|archived",
  "promo": {
    "video": false,
    "screenshots": false,
    "landing": false
  }
}
```

> **Campo `promo`**: Indica si el proyecto ya tiene assets de marketing generados.
> El agente debe actualizar estos valores a `true` cada vez que genere un asset con `design-engine/`.

### Pilares disponibles:
- `creacion` (rosa #ff4e83) — Apps y productos creativos
- `educacion` (azul #1976D2) — Enseñanza, tutoriales, aprendizaje
- `cultura` (verde #388E3C) — Carnaval, música, identidad cultural
- `herramientas` (naranja #FF8F00) — Extensiones, paquetes, tools de dev
- `hardware` (dorado #FFB300) — Dispositivos físicos, IoT

---

## 📋 Paso 6 — Auditoría de Nube (Proyectos Huérfanos)

> Esta fase es **opcional** pero recomendada cuando Javier quiera limpiar su ecosistema de Firebase / GCP / GitHub.
> El objetivo: cruzar `universe.json` con lo que hay en la nube y detectar **proyectos huérfanos** (proyectos abandonados que ocupan espacio, consumen cuota o "hacen ruido" sin estar registrados).

### ¿Qué es un proyecto huérfano?
Un proyecto que existe en Firebase, GCP o GitHub **pero NO está en `universe.json`** (o está con `status: archived` y sigue activo en la nube).

### ⚠️ Decisión de seguridad FIRME

**El bot NO tiene acceso directo a las cuentas de Javier.**
No se usará Service Account JSON ni GitHub PAT almacenado en el bot.

El modelo correcto es: **el bot actúa como guía**.
El bot lee `universe.json`, genera los comandos exactos y los da a Javier para que él los ejecute localmente en su Mac.

### Cómo funciona el flujo

**1. El bot lee `universe.json`** y genera una lista de todos los proyectos registrados con sus IDs de Firebase, repos de GitHub y dominios.

**2. El bot genera los comandos exactos** para que Javier los ejecute localmente:

```bash
# Listar proyectos Firebase (requiere firebase-tools instalado y sesión activa)
firebase projects:list

# Listar repositorios GitHub (requiere gh CLI instalado y sesión activa)
gh repo list erbolamm --limit 100 --json name,updatedAt,isArchived

# Listar proyectos GCP activos
gcloud projects list --format="table(projectId,name,lifecycleState)"
```

**3. Javier pega el output** de esos comandos en el chat con el bot.

**4. El bot cruza** los resultados con `universe.json` y devuelve:
- ✅ Proyectos en nube que SÍ están en universe.json → OK
- ⚠️ Proyectos en nube que NO están en universe.json → candidatos a revisar
- 🗑️ Proyectos en nube con `status: archived` en universe.json → candidatos a borrar

**5. El bot propone acciones concretas** (nunca las ejecuta solo):
- "Este repo lleva 18 meses sin commits y no está en universe.json. ¿Lo archivamos en GitHub?"
- "Este proyecto de Firebase tiene 0 usuarios activos. ¿Lo borramos?"

### ⚠️ Regla de oro de la auditoría

**NUNCA borrar nada automáticamente.** Cada borrado requiere confirmación explícita de Javier.
El bot solo sugiere. Javier decide y ejecuta.

### Añadir al SOUL.md del bot

Cuando se desarrolle esta funcionalidad, el `SOUL.md` del bot deberá incluir un bloque con:
- La lista de IDs de proyectos Firebase conocidos (del universe.json)
- La lista de repos GitHub conocidos
- El prompt maestro para guiar la auditoría paso a paso sin acceso directo

> Estado: **pendiente** — desarrollar una vez completadas las prioridades de la web (Auth, Admin Panel, Chat IA).

---

## 📋 Paso 3.9 — Si el proyecto es privado / interno / no público

> **Aplica a:** repos privados, prototipos, pruebas, herramientas internas, proyectos incompletos o ideas que todavía NO están listas para publicar.

### Prioridad correcta en proyectos privados

Si el proyecto es privado, el agente debe priorizar esto por encima de marketing o publicación:

1. **Seguridad**
2. **Mantenibilidad**
3. **Recuperabilidad / rescate**
4. **Coste real de continuarlo**
5. **Recién después** pensar en publicación

### Qué debe responder el agente en un proyecto privado

Además del análisis normal, debe responder:

1. **¿Arranca o no arranca?**
2. **¿Compila o está roto?**
3. **¿Qué dependencias o credenciales faltan para ejecutarlo?**
4. **¿Qué partes merecen rescatarse?**
5. **¿Conviene continuarlo, congelarlo, fusionarlo o descartarlo?**

### Checklist obligatorio para proyectos privados

- [ ] Detectar secretos o credenciales sin imprimirlos en el chat
- [ ] Verificar si existe `.env`, `.env.local`, `.npmrc`, service accounts, `google-services.json`, `GoogleService-Info.plist`, claves API o tokens
- [ ] Indicar si el proyecto arranca / compila / testea / analiza
- [ ] Indicar si faltan versiones concretas de entorno (Node, Flutter, Dart, Java, Xcode, etc.)
- [ ] Detectar archivos fósiles, dependencias muertas o scripts rotos
- [ ] Detectar si el proyecto duplica otro ya existente en el universo
- [ ] Evaluar si sale más barato rescatarlo o rehacerlo

### Regla de secretos (OBLIGATORIA)

Si el agente encuentra secretos:

- **SÍ** debe avisar que existen
- **NO** debe pegarlos en el chat
- **NO** debe moverlos ni copiarlos sin permiso
- **SÍ** debe indicar dónde están de forma segura (ej. `archivo X contiene credenciales`)

### Estados recomendados para proyectos privados

Usar uno de estos diagnósticos claros:

- **Continuar** → el proyecto tiene base sana y objetivo claro
- **Congelar** → no está listo, pero merece quedar documentado
- **Fusionar** → tiene piezas útiles para otro proyecto del universo
- **Archivar** → ya no compensa seguir, pero conviene conservarlo
- **Descartar** → no aporta valor técnico ni reutilizable

### Regla práctica de descarte profesional

Un proyecto privado es candidato a **descartar o archivar** si cumple varias de estas señales:

- duplica otro proyecto mejor
- stack muy viejo o roto
- dependencias abandonadas
- sin objetivo claro
- sin assets ni lógica rescatable
- requiere más esfuerzo repararlo que rehacerlo

### Mini sección obligatoria del informe

Si el proyecto es privado, añadir esta sección:

**Diagnóstico de rescate**
1. Qué se puede salvar
2. Qué está roto
3. Qué falta para volverlo usable
4. Si conviene seguir, fusionar, congelar o tirar

### Antes de tocar fuerte un proyecto privado

Si el agente va a hacer cambios grandes, recordar:

- crear branch o snapshot si aplica
- no borrar archivos sin confirmación
- identificar archivos load-bearing / delicados
- documentar primero si el estado es confuso

---

## 📋 Paso 3.9 — Archivo ESTADO.md obligatorio (Hoja de Ruta)

> **Aplica a:** TODO proyecto que entre por INBOX, sin excepción.

### Regla estricta

Cuando un proyecto se procesa a través de INBOX, DEBE generar o actualizar un archivo `ESTADO.md` en la raíz del proyecto. Este archivo es la **hoja de ruta viva** del proyecto.

### Estructura obligatoria de ESTADO.md

```md
# ESTADO — [Nombre del Proyecto]

## 🎯 Propósito
[Qué es, para qué sirve, quién lo usa]

## 📊 Estado actual
- **Completado**: [lista de cosas terminadas]
- **En progreso**: [lista de cosas activas]
- **Pendiente**: [lista de cosas por hacer]

## 🗺️ Hoja de ruta (siguientes pasos)
1. [Paso próximo con descripción]
2. [Paso siguiente]
3. [Paso siguiente]

## ⚠️ Bloqueos / Dependencias
- [Qué bloquea cada cosa pendiente, si hay alguna]

## 📅 Fecha de última actualización
[YYYY-MM-DD]
```

### Cuándo crear / actualizar ESTADO.md

| Situación | Acción |
|-----------|--------|
| Proyecto nuevo en INBOX | Crear `ESTADO.md` con propósito + estado inicial |
| Proyecto publicado | Actualizar estado → marcar como completado lo que aplique |
| Proyecto archivado | Marcar todo como "congelado" o "descartado" |
| Cada sesión que avance el proyecto | Actualizar fecha y progreso |

### Regla de oro

> Si un proyecto no tiene `ESTADO.md`, se considera **proyecto no analizado**. El agente debe crearlo antes de reportar a Javier.

---

## 📋 Paso 3.10 — Archivo BUILD_AND_DEPLOY.md obligatorio

> **Aplica a:** TODO proyecto que se vaya a compilar/desplegar desde ErBolamm Studio.

### Regla estricta

Cuando un proyecto pase por INBOX y tenga intención de publicarse, DEBE crear un archivo `BUILD_AND_DEPLOY.md` en su raíz. Este archivo permite ejecutar build y deploy desde la **terminal integrada de ErBolamm Studio** sin necesidad de abrir otro entorno.

### Estructura obligatoria de BUILD_AND_DEPLOY.md

```md
# 🚀 Guía de Build & Deploy — [Nombre del Proyecto]

**Versión actual**: X.Y.Z
**Última actualización**: YYYY-MM-DD
**Mantenedor**: Francisco Mateo Márquez

---

> ⚙️ **Modo agente**: Esta guía está diseñada para ser ejecutada por un agente de IA
> de principio a fin **sin confirmaciones intermedias**, salvo puntos explicitly marcados.

---

## 1️⃣ Preparación General (Obligatorio)

```bash
# Limpieza y dependencias
flutter clean && flutter pub get

# Generación de código
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n

# Verificación de calidad
flutter analyze
flutter test
```

---

## 2️⃣ Android (Google Play)

```bash
flutter build appbundle --release
```

✅ **Output**: `build/app/outputs/bundle/release/app-release.aab`

---

## 3️⃣ iOS (App Store Connect)

### A. Compilación y Pods

```bash
cd ios && pod install && cd ..
flutter build ios --release
```

### B. Xcode: Archive y dSYMs (⚠️ PUNTO DE PARADA MANUAL)

**El agente se DETIENE aquí y espera instrucciones del usuario.**

1. Abre Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Selecciona como destino **Any iOS Device (arm64)**.
3. Ve a **Product → Archive** y espera a que termine.
4. Sube los dSYMs a Crashlytics:
   ```bash
   make upload-dsyms
   ```
5. En la ventana de *Organizer* de Xcode, haz clic en **Distribute App**.

---

## 📋 Referencia de Versiones

| Archivo | Constante | Valor actual |
|---------|-----------|--------------|
| `pubspec.yaml` | `version` | `X.Y.Z+NNN` |
| `lib/main.dart` | `appVersionXxx` | `'X.Y.Z'` |

> Al subir una nueva versión, actualizar AMBAS constantes y este documento.

---

## ⚠️ Notas Técnicas

- [ ] Anotar particularidades del proyecto (plugins, configuración, errores conocidos)
- [ ] RevenueCat: toda llamada a `Purchases.*` debe llevar guard `_isInitialized`
- [ ] Ads: no cargar hasta tener consentimiento / ATT resueltos
- [ ] SKAdNetworkItems: verificar que los 59+ IDs estén en Info.plist
```

### Cuándo crear / actualizar BUILD_AND_DEPLOY.md

| Situación | Acción |
|-----------|--------|
| Proyecto nuevo que entra por INBOX | Crear `BUILD_AND_DEPLOY.md` con las plataformas que aplique |
| Proyecto existente sin el archivo | Crearlo al procesarlo |
| Nueva versión disponible | Actualizar versión en el archivo + pubspec.yaml + main.dart |

### Punto de parada manual

El archivo puede tener **un único punto de parada manual**: cuando se requiere abrir Xcode para Archive. Esto es intencional porque Xcode requiere interacción del usuario y no se puede automatizar completamente.

### Ejemplos por tipo de proyecto

| Tipo | Plataformas típicas |
|------|---------------------|
| App Flutter móvil | Android (AAB) + iOS (App Store) |
| Paquete Dart | Solo pub.dev (sin build binario) |
| Web Flutter | Firebase Hosting (`firebase deploy`) |
| Extension VS Code | Marketplace + GitHub |

---

## 📋 Paso 3.11 — Patrón de inicialización de Firebase (Flutter/Dart)

> **Aplica a:** TODO proyecto Flutter/Dart que use Firebase (Firestore, Auth, Crashlytics, etc.).
> **Fuente:** Patrón extraído de CalcaApp (`firebase_init_service.dart`) y validado en Me-llaman.

### El error clásico

```dart
// ❌ MAL: Firebase.apps.isEmpty como guard para NO configurar
if (Firebase.apps.isEmpty) {
  await Firebase.initializeApp(...);
  FirebaseFirestore.instance.settings = ...;
  // Crashlytics setup...
}
// En hot restart, Firebase.apps NO está vacío (nativo sigue vivo)
// pero la conexión Dart se rompió. Resultado: [core/no-app] por todos lados.
```

### El patrón correcto (3 reglas)

#### Regla 1 — `Firebase.apps.isNotEmpty` = ÉXITO, no excusa para saltear

Si Firebase ya existe, igual configurá Firestore y Crashlytics. El SDK nativo sigue vivo pero la VM de Dart se reinició en hot restart.

```dart
// ✅ BIEN
if (Firebase.apps.isEmpty) {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).timeout(const Duration(seconds: 5));
} else {
  // Hot restart: reconfigurar igual
}

// Configurar SIEMPRE (con try-catch propio porque puede fallar si ya se aplicó)
try {
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
} catch (_) { /* ya aplicado por otro flujo */ }

// Crashlytics SIEMPRE
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
```

#### Regla 2 — Servicios Firebase con acceso lazy + fallback offline

NUNCA accedas a `FirebaseFirestore.instance` o `FirebaseAuth.instance` en field initializers de clases. Usá lazy access con try-catch:

```dart
// ✅ BIEN: acceso lazy con fallback
FirebaseFirestore? _firestore;
bool _firebaseDisponible = false;

void _tryInitFirebase() {
  if (_firebaseDisponible) return;
  try {
    _firestore = FirebaseFirestore.instance;
    _firebaseDisponible = true;
  } catch (e) {
    _firebaseDisponible = false; // modo offline
  }
}
```

#### Regla 3 — Chequeo de internet ANTES de Firebase

Si no hay red, no intentes `initializeApp`. Vas a esperar 5-10s de timeout al pedo.

```dart
final hasConnection = await checkInternetConnection();
if (!hasConnection) {
  // modo offline, seguir sin Firebase
  return;
}
await Firebase.initializeApp(...);
```

### Checklist rápido para el agente

Al revisar un proyecto Flutter con Firebase, verificar:

- [ ] `Firebase.initializeApp` NO está protegido por `if (Firebase.apps.isEmpty)` sin reconfigurar después
- [ ] `FirebaseFirestore.instance.settings` se aplica SIEMPRE (con try-catch propio)
- [ ] `Crashlytics` se configura SIEMPRE después de Firebase
- [ ] Ningún service accede a `FirebaseFirestore.instance` / `FirebaseAuth.instance` en field initializers
- [ ] Los servicios que dependen de Firebase tienen lazy access + fallback offline con try-catch
- [ ] Si hay `service_locator`, `AuthService` o similares no explotan si Firebase no está disponible
- [ ] En iOS: `GoogleService-Info.plist` existe y está en el target correcto
- [ ] En Android: `google-services.json` existe

### Señales de alerta

- `FirebaseFirestore.instance` en un field initializer (`final _firestore = FirebaseFirestore.instance;`)
- `FirebaseAuth.instance` en constructor de un servicio registrado en GetIt antes de `initializeApp`
- `Firebase.apps.isEmpty` como condición para NO ejecutar código de configuración
- Error `[core/no-app] No Firebase App '[DEFAULT]' has been created` en logs

---

## 📋 Paso 3.12 — Firma Android + carpeta `key/` obligatoria

> **Aplica a:** TODA app Flutter/Android que se vaya a publicar en Google Play.
> **Origen:** Reconstrucción de apps legacy de Mobincube (afinar, sos, lenguaje no verbal, ¿Quiere ser feliz?), julio-agosto 2026.

### Regla estricta

Toda app que se publique DEBE tener en su raíz una carpeta `key/` con la firma documentada. Si no existe, el proyecto se considera **no listo para publicar**.

### Estructura obligatoria de `key/`

```
key/
├── upload-keystore.jks        ← Keystore de subida (firma cada release)
├── upload_certificate.pem     ← Certificado público (para trámites en Play Console)
├── assetlinks.json            ← Digital Asset Links (si usa App Links)
└── leeme.txt                  ← Documentación de todas las claves (OBLIGATORIO)
```

Además:
- `android/key.properties` con `storePassword`, `keyPassword`, `keyAlias`, `storeFile` (apunta a `../../key/upload-keystore.jks`).
- `key/` y `android/key.properties` DEBEN estar en `.gitignore` (contienen contraseñas).

### Formato obligatorio de `key/leeme.txt`

Documentar SIEMPRE (formato validado en `lenguaje_no_verbal`):
1. **Package ID** (applicationId).
2. **Firma de app (Google Play App Signing)**: huellas MD5, SHA-1, SHA-256 que gestiona Google.
3. **Clave de subida (upload key)**: huellas MD5, SHA-1, SHA-256 del keystore local.
4. **Alias y password** del keystore (o dónde están si no van en el leeme).
5. **Estado del trámite** de cambio de clave de subida (si aplica) + fecha de validez.

### Concepto clave (Play App Signing) — NO confundir

- La **clave de subida** (tu keystore) firma el AAB que subís.
- La **clave de firma de app** la gestiona Google en su servidor y re-firma la app.
- Sus huellas SHA-256 **son distintas y eso es correcto**. No cuadrarlas no es un error.

### Si NO tenés el keystore original (app recuperada)

Como Play App Signing está activo, se puede:
1. Reusar un keystore existente (un mismo keystore puede firmar varias apps — afinar y lenguaje comparten uno).
2. Generar el `.pem`: `keytool -export -rfc -alias upload -keystore key/upload-keystore.jks -storepass <pass> -file key/upload_certificate.pem`
3. En Play Console → Firma de aplicaciones → **"Solicitar cambio de la clave de subida"** → subir el `.pem`.
4. Google tarda ~2 días: da una **fecha de validez**. Hasta esa fecha NO se puede subir AAB/APK.

### Checklist de firma para el agente

- [ ] Existe `key/` con keystore, `.pem`, `assetlinks.json` (si aplica) y `leeme.txt`
- [ ] `android/key.properties` existe y apunta al keystore correcto
- [ ] `key/` y `key.properties` están en `.gitignore`
- [ ] `build.gradle.kts` tiene `signingConfigs { create("release") { ... } }` leyendo `key.properties`
- [ ] `buildTypes.release.signingConfig` NO usa `debug` (error típico de plantilla Flutter)
- [ ] La huella SHA-1 del AAB compilado coincide con la registrada en Play:
      `keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab | grep SHA1`

### Fixes de build recurrentes (apps legacy Mobincube)

Estos dos fallos son habituales en estas apps. Aplicarlos sin dudar:

**1. `record` resuelve `record_linux` incompatible**
Síntoma: `RecordLinux.hasPermission has fewer named arguments...`
Fix en `pubspec.yaml` (`record 5.x` usa `record_platform_interface 1.x`):
```yaml
dependency_overrides:
  record_linux: 1.3.1
```
> Ojo: NO fijar `record_linux 2.x` (usa interface 2.x, incompatible con `record 5.x`).

**2. `flutter_local_notifications` requiere core library desugaring**
Síntoma: `Dependency ':flutter_local_notifications' requires core library desugaring`
Fix en `android/app/build.gradle.kts`:
```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        // ...
    }
    defaultConfig {
        multiDexEnabled = true
        // ...
    }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

### Nota sobre archivado en iCloud

Cuando muevas un proyecto a `iCloud/TrabajoCloud/APPS` o hagas `flutter clean`:
- La carpeta `key/` viaja CON el proyecto y lleva contraseñas dentro.
- No es un problema si el proyecto es tuyo y la nube es privada, pero tenerlo presente.
- Buena práctica opcional: una copia del keystore fuera del proyecto por si un `clean` mal hecho se la lleva.

---

## 📋 Paso 3.13 — Patrones compartidos de Build & Deploy

> **Aplica a:** todas las apps del ecosistema que tengan `BUILD_AND_DEPLOY*.md` en su raíz.

Los flujos CLI y de automatización que se replican entre apps NO deben duplicarse en cada guide local. Viven en **`DEPLOY_PATTERNS.md`** (en la raíz de este proyecto) y cada `BUILD_AND_DEPLOY*.md` los referencia.

### Patrones disponibles

| # | Patrón | Descripción | Ver `DEPLOY_PATTERNS.md` |
|---|---|---|---|
| 1 | iOS CLI upload (`xcrun altool`) | Subir `.ipa` a TestFlight sin Xcode | [→ DEPLOY_PATTERNS.md#1](./DEPLOY_PATTERNS.md#1--ios-cli-upload-via-xcrun-altool) |

### Cómo agregar un patrón nuevo

1. Agregar el patrón en `DEPLOY_PATTERNS.md` con el formato `#N — <nombre>`
2. Actualizar la tabla de índice arriba
3. Si aplica, replicar la sección en los `BUILD_AND_DEPLOY*.md` de las apps que correspondan

### Cómo replicar un patrón existente en una app nueva

Ver la sección "Cómo replicar este patrón en otra app" dentro del patrón en `DEPLOY_PATTERNS.md`.

---

## ⚠️ Reglas obligatorias

1. **NUNCA borrar nada** sin confirmación de Javier
2. **NUNCA mover archivos fuera** de `INBOX/` sin permiso
3. Si el proyecto tiene secretos o API keys → AVISAR, no imprimir
4. Si dudas del pilar → pregunta
5. Después de analizar, **vaciar `INBOX/`** solo cuando Javier confirme
6. **NUNCA SMS Auth** — Javier perdió 1600€ por esto en CalcaApp
7. Si el proyecto usa Firebase → verificar si ya hay un proyecto Firebase existente en el ecosistema
8. Escribir respuestas en **español**, frases cortas, listas numeradas

---

## 📊 Pilares del ecosistema (referencia rápida)

| Pilar | Color | Emoji | Ejemplos |
|-------|-------|-------|----------|
| `creacion` | Rosa `#ff4e83` | ✏️ | CalcaApp, diseños, vídeos |
| `educacion` | Azul `#1976D2` | 🎓 | ApliArte, TutoGrati, TuAplicacionGratis |
| `cultura` | Verde `#388E3C` | 🎭 | ElBolaDeMarbella, chirigotas, comparsas |
| `herramientas` | Naranja `#FF8F00` | 🔧 | Key Master, Corrector VS Code, apliarte_faq |
| `hardware` | Dorado `#FFB300` | 🤖 | ApliMemo (Asistente Cognitivo de Bolsillo) |
| `ia` | Púrpura `#9c27b0` | 🧠 | BolaBot, IA del universo |

---

## 🏗️ Patrón estándar por tipo de proyecto

### Apps móviles
1. **Landing** (Flutter Web + Firebase Hosting)
2. **Blog** (Blogger, ya existente)
3. **App** (móvil: Flutter/Dart, pub en Play Store / App Store)

### Paquetes y librerías (pub.dev / npm)
1. **Web Demo** (Flutter Web + GitHub Pages — el `example/` compilado a web)
2. **Paquete** (pub.dev o npm)
3. **GitHub** (código fuente + README + issues)

Ejemplo: `apliarte_glass_theme` tiene web demo en `erbolamm.github.io/apliarte-glass-theme/` generada desde `example/`.

### Extensions VS Code
1. **Marketplace** (VS Code Marketplace)
2. **GitHub** (código fuente)

### Webs principales
- **erbolamm-com** (hub): React + Vite + Firebase Hosting (excepción: no es Flutter)
- **Blogs**: Blogger (mantenimiento cero, hosting Google)

### Resumen de presencias web por tipo

| Tipo | Landing/Demo | Hosting recomendado |
|------|-------------|-------------------|
| App móvil | Landing Flutter Web | Firebase Hosting |
| Paquete pub.dev | Web demo desde example/ | GitHub Pages |
| Extensión VS Code | — | Marketplace + GitHub |
| Blog | Blogger | Google (mantenimiento cero) |
| Hub principal | React/Vite | Firebase Hosting |

---

## 📋 Paso 7 — Evaluación de Migración de Hosting

> Añadido el 12 de marzo de 2026 tras inspección directa del VPS Hostinger (`72.60.187.93`).
> Infraestructura VPS: **Docker + Nginx Proxy Manager** — sin nginx nativo.
> Proyectos web de pilares Educación y Cultura: hosting a confirmar (posiblemente Hostinger cPanel o Blogger).

### 🖥️ Mapa de infraestructura actual (VPS)

| Contenedor | Dominio expuesto | Puerto interno | Propósito |
|-----------|-----------------|---------------|-----------|
| `npm` | — | 80/443 | Nginx Proxy Manager (gateway de entrada) |
| `apliarte-bot` | `chatbot.apliarte.com` | 18791 | Bot Telegram (OpenClaw) |
| `apliarte-assistant` | `app.calcaapp.com` (parcial) | 8010 | Chatbot CalcaApp (Python/FastAPI) |
| `calcaapp-landing` | `app.calcaapp.com` | 8085 | Landing CalcaApp (HTML estático) |
| `ai-gateway` | — | 3000 | Gateway LLM (Groq/Gemini/Cerebras) |
| `apliarte-directos` | `directo.apliarte.com` | 7979 | Streaming en directo |
| `info-apliarte` | `info.apliarte.com` | 8082 | Página informacional |
| `n8n` | `n8n.apliarte.com` | 5678 | Automatización n8n |
| `dozzle` | `dozzle.apliarte.com` | 8080 | Monitor de logs Docker |
| `uptime-kuma` | `uptime-kuma.apliarte.com` | 3001 | Monitor de disponibilidad |
| `portainer` | `panel.apliarte.com` | 9000 | Panel Docker visual |
| `postgres` | — | 5432 | Base de datos (n8n + assistant) |
| `redis` | — | 6379 | Caché y memoria de conversación |
| `watchtower` | — | — | Auto-actualización de imágenes Docker |

---

### 📊 Estado de hosting por proyecto del universo

| Proyecto | Estado | Hosting actual | ¿Migrar a Firebase? | Notas |
|---------|--------|---------------|---------------------|-------|
| **erbolamm-com** | 🟢 Producción | ✅ Firebase Hosting | No — ya está | `erbolamm-com.web.app` |
| **erbolamm-hub** | 🟢 Producción | ✅ Firebase Hosting | No — ya está | `erbolamm-hub.web.app` (iframe incrustado) |
| **CalcaApp** (app móvil) | 🟢 Producción | App Store / Play Store | N/A | App nativa, no aplica hosting web |
| **calcaapp-landing** | 🟢 Producción | 🖥️ VPS Hostinger (Docker) | ⚠️ Evaluar | Contenedor `calcaapp-landing` en VPS → `app.calcaapp.com`. Migrar a Firebase Hosting eliminaría carga del VPS |
| **Jurado Popular** | 🟢 Producción | ✅ Firebase Hosting | No — ya está | `jurado-popular.web.app` |
| **ApliArte** | 🟡 Activo | ✅ Blogger (Google) | ❌ No aplica | `apliarte.com` — Mantenimiento cero, hosting rápido de Google |
| **TutoGrati** | 🟡 Activo | ✅ Blogger (Google) | ❌ No aplica | `tutograti.com` — Mantenimiento cero, hosting rápido |
| **TuAplicacionGratis** | 🟡 Activo | ✅ Blogger (Google) | ❌ No aplica | `tuaplicaciongratis.com` — Excelente para este fin |
| **ElBolaDeMarbella** | 🟡 Activo | ✅ Blogger (Google) | ❌ No aplica | `elbolademarbella.com` — Perfecto para el blog de carnaval |
| **LaChirigotaDelBola** | 🟡 Activo | ✅ Blogger (Google) | ❌ No aplica | `lachirigotadelbola.com` — Perfecto para el archivo muscial |
| **LaComparsaDelBola** | 🟡 Activo | ✅ Blogger (Google) | ❌ No aplica | `lacomparsadelbola.com` — Perfecto para el archivo musical |
| **apliarte-assistant** | 🟢 Activo | 🖥️ VPS Hostinger (Docker) | ❌ No aplica | Backend Python/FastAPI — requiere servidor, Firebase Hosting no es oportuno |
| **ai-gateway** | 🟢 Activo | 🖥️ VPS Hostinger (Docker) | ❌ No aplica | Backend Bun/TypeScript — ídem anterior |
| **apliarte-bot** | 🟢 Activo | 🖥️ VPS Hostinger (Docker) | ❌ No aplica | Bot Telegram (OpenClaw) — debe vivir en VPS |
| **ApliMemo** | 🔵 WIP | ❌ Sin hosting (hardware) | ❌ N/A | Dispositivo físico — cuando tenga web/landing, sí evaluar Firebase |
| **apliarte-faq** | 🟢 Publicado | pub.dev + GitHub | ❌ No aplica | Paquete Dart — no tiene hosting, se distribuye por pub.dev |
| **Key Master** | 🟢 Publicado | GitHub + VS Marketplace | ❌ No aplica | Extensión VS Code |
| **Corrector VS Code** | 🟢 Publicado | GitHub + VS Marketplace | ❌ No aplica | Extensión VS Code |
| **Apps iOS** (6 apps legacy) | 🟡 Activo | App Store | ❌ N/A | Apps nativas iOS — sin hosting web propio |

---

### ✅ Ventajas de Firebase Hosting (para los candidatos a migrar)

1. **CDN global nativo** — cero configuración, Cloudflare sería opcional
2. **Integración directa con Firestore / Auth** — si en el futuro los proyectos web tienen backend Firebase
3. **Deploy con un comando** — `firebase deploy` desde CI/CD
4. **HTTPS automático** — sin gestionar certificados Let's Encrypt manualmente
5. **Libera carga del VPS** — la landing de CalcaApp y sitios estáticos no deberían consumir recursos del VPS donde vive el bot

### ⚠️ Cuándo NO migrar a Firebase

- **Backends con servidor** (apliarte-assistant, ai-gateway, apliarte-bot) → necesitan Docker/VPS siempre
- **Blogs en Blogger** → Dejar SIEMPRE en Blogger: es infraestructura de Google de nivel mundial, gratis de por vida y requiere cero mantenimiento del servidor.
- **Lo que ya funciona bien** → no migrar por migrar; solo si hay ganancia real

### 📋 Acción recomendada (por Javier)

| Prioridad | Proyecto | Acción |
|----------|---------|--------|
| 🔴 Alta | `calcaapp-landing` | Migrar a Firebase Hosting → libera VPS |

> **Análisis finalizado**: Se ha verificado la infraestructura general. El único proyecto web susceptible a mejorar su hosting hacia Firebase de manera inmediata es la Landing de CalcaApp (`calcaapp-landing`). El resto de componentes (Pilares Cultura y Educación) están de modo óptimo en *Blogger*.

---

## 🩺 Lecciones de RDD — com_apliarte_sos (agosto 2026)

> **Sesión**: Revisión integral con Gemini 3.6 Flash (High) + Gentle AI RDD
> **Proyecto**: SOS Apliarte (`com_apliarte_sos`)
> **Hallazgos documentados**: Para que futuros agentes no repitan estos errores.

### 🔴 CRÍTICO — Corregido

#### Firestore: Admin escribía en subcolección, app leía de campo en documento
- **Problema**: El admin (`app.js`) escribe en `global/emergencies/items/{id}` (subcolección). La app (`firestore_service.dart`) leía `global/emergencies` → campo `items` (mapa dentro del doc). Los datos NUNCA coincidían. El Seed parecía no funcionar.
- **Fix**: La app ahora lee de la subcolección `global/emergencies/items` igual que escribe el admin. Query con `.where('active', isEqualTo: true)` para filtrar solo activos.

#### `applicationId` en `build.gradle.kts` NO debe tocarse
- **Problema**: Gemini sugirió cambiar `applicationId` de `com.mobincube.android.sc_W4GWE.app_79498` a `com.apliarte.sos`.
- **Realidad**: El `applicationId` ES la identidad en Play Store. Si se cambia, se crea una app nueva. NO SE TOCA.
- **Lo que SÍ puede diferir**: `AndroidManifest.xml` → `package` (namespace de código) puede ser distinto a `applicationId`.
- **IDs reales de tienda**:
  - Google Play: `com.mobincube.android.sc_W4GWE.app_79498`
  - App Store: `com.mobincube.rapido-sos.scW4GWE` (SKU: `RAPIDOERBOLAMM2443`, Apple ID: `1103889159`)

### 🟠 ALTO — Corregido

#### `_listenToProfile()` corría antes de que `authService.userId` existiera
- **Problema**: `SOSApp.initState()` llamaba a `_listenToProfile()` que chequeaba `authService.userId` sincrónicamente. Si Firebase Auth no había terminado de inicializar, `userId` era `null` y el stream de perfil nunca se suscribía. Resultado: usuario atrapado en rol `elderly`.
- **Fix**: `_onAuthChanged()` reactivo usando `authService.addListener()`. Cuando `userId` aparece, se suscribe al perfil. Cuando se va, cancela la subscripción.

#### `main()` metía todas las inicializaciones en un solo `try-catch`
- **Problema**: Si `authService.initialize()` fallaba, `localizationService` nunca cargaba los ARB. La app quedaba sin traducciones.
- **Fix**: Cada inicialización en su propio `try-catch` independiente.

### 🛡️ Admin Panel (Firebase Hosting)

- **URL**: https://rapido-sos.web.app
- **Auth**: SOLO Google login con `erbolamm@gmail.com` (patrón copiado de `eres feliz`)
- **Acceso directo**: Botón fallback sin auth (read-only)
- **Deploy**: `firebase deploy --only hosting` desde la raíz del proyecto
- **Directorio público**: `admin_web/` (cambiado de `pairing_landing/`)

### 🔑 Reglas de oro aprendidas

1. **NUNCA cambiar `applicationId`** de una app publicada en Play Store.
2. **NUNCA asumir que Firebase Auth está listo en `initState`** — usar listeners reactivos.
3. **CADA inicialización en su propio `try-catch`** — un fallo no debe tumbar a los demás.
4. **Firebase Hosting DEBE apuntar al admin panel**, no a una landing de pairing que ya no se usa.
5. **Admin panel = solo Google login** con `login_hint` al email del admin. Sin email/password.
6. **Los ARB tienen prioridad sobre hardcodeos** — `_()` siempre, incluso en diálogos nuevos.

---

## 📚 Archivos clave del proyecto que debes conocer

| Archivo | Qué contiene | Prioridad de lectura |
|---------|-------------|---------------------|
| `ESTADO.md` | Estado completo del proyecto, tareas pendientes, decisiones | 🔴 LEE PRIMERO |
| `universe.json` | Base de datos de todos los proyectos (fuente de verdad) | 🔴 LEE SEGUNDO |
| `INBOX.md` | Este archivo — instrucciones de análisis | 🟡 Ya lo estás leyendo |
| `design-engine/SKILL.md` | Motor de diseño ApliArte Design — instrucciones para agentes | 🟡 Lee si vas a generar promo |
| `design-engine/GUIA.md` | Tutorial para humanos del motor de diseño | 🟢 Referencia |
| `src/App.tsx` | Componente principal (572 líneas) | 🟢 Solo si vas a tocar código |
| `src/App.css` | Estilos completos (2163 líneas) | 🟢 Solo si vas a tocar diseño |
| `index.html` | GA4, OG tags, SEO | 🟢 Solo si vas a tocar SEO |
