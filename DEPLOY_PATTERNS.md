# 🚀 Patrones de Build & Deploy — Compartidos entre apps

> **Propósito**: Documentar los patrones CLI y de automatización que se replican en los `BUILD_AND_DEPLOY*.md` de cada app del ecosistema. Este archivo es la **fuente única de verdad** para los flujos compartidos; cada proyecto lo referencia desde su guide local.

---

## 📦 Índice de patrones

| # | Patrón | Aplicación | Apps que lo usan |
|---|---|---|---|
| 1 | iOS CLI upload (sin Xcode) | Subir `.ipa` a TestFlight desde terminal | `com_apliarte_sos`, `calca_app`, `lenguaje_no_verbal` |

> Nuevos patrones se agregan abajo como `#2`, `#3`, etc. Mantener formato consistente.

---

## #1 — iOS CLI upload via `xcrun altool`

**Aplicación**: Subir un `.ipa` a TestFlight sin abrir Xcode, usando la App Store Connect API key.

**Cuándo usar**:
- Misma máquina, mismas credenciales, pero sin la UI de Xcode
- Builds scripts / CI
- Subida one-off sin abrir el IDE completo

**Cuándo NO usar** (volver a Xcode):
- Primer setup (no hay API key generada todavía)
- Si `altool` falla con auth errors y ya verificaste la key
- Si necesitás adjuntar un dSYM de debug manualmente
- Si el build falla code signing (Xcode da mejores mensajes de error)

### Prerequisitos (one-time)

1. Ir a **appstoreconnect.apple.com** → **Users and Access** → **Integraciones** → **App Store Connect API**
2. Elegir una key existente (ej. "Fastlane") o **Generate API Key** con acceso **Admin** o **App Manager**
3. Descargar el `.p8` (solo se descarga una vez — guardalo bien)
4. Anotar el **Key ID** (10 chars) y el **Issuer ID** (UUID, arriba a la derecha de la página Keys)

### Setup único en la Mac

El archivo `.p8` tiene que estar en `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8`:

```bash
mkdir -p ~/.appstoreconnect/private_keys
cp /path/to/AuthKey_<KEY_ID>.p8 ~/.appstoreconnect/private_keys/
```

### Build del IPA

```bash
flutter build ipa --export-method app-store
```

Output: `build/ios/ipa/<bundle>.ipa`

### Upload a TestFlight

```bash
xcrun altool --upload-app --type ios \
  -f build/ios/ipa/<bundle>.ipa \
  --apiKey <KEY_ID> \
  --apiIssuer <ISSUER_ID>
```

Output esperado en éxito:

```
==========================================
UPLOAD SUCCEEDED with no errors
Delivery UUID: <uuid>
Transferred <bytes> in <seconds>s
==========================================
No errors uploading archive at 'build/ios/ipa/<bundle>.ipa'.
```

### Después del upload

1. App Store Connect → My Apps → <tu app> → TestFlight
2. El build aparece como "Processing" por ~5-10 min
3. Completar **Export Compliance** (pregunta sobre encryption)
4. Distribuir a testers internos o externos

### Troubleshooting

| Error | Causa | Fix |
|---|---|---|
| `Failed to load AuthKey file. (-43)` | `.p8` no está donde se espera | Verificar `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8` con el nombre exacto |
| `Authentication failed` | KEY_ID o ISSUER_ID mal, o `.p8` es de otro team | Verificar ambos en App Store Connect → Keys |
| `Bundle identifier mismatch` | El bundle ID del IPA no coincide con la app registrada | Verificar `ios/Runner.xcodeproj/project.pbxproj` → `PRODUCT_BUNDLE_IDENTIFIER` |
| `Build number already used` | versionCode en pubspec ya fue usado | Bumpear `+N` en pubspec.yaml y rebuildear |
| `ITMS-90068` warning | `MinimumOSVersion` muy bajo | No bloquea, pero planear bumpear a iOS 15+ antes de Spring 2027 |

### Verificado en producción

| Fecha | App | KEY_ID | Resultado |
|---|---|---|---|
| 2026-08-06 | S.O.S ApliArte | `CGASGDR3H3` | ✅ UPLOAD SUCCEEDED, 45.9 MB, Delivery UUID `19acd952-dad5-4b86-bdfa-d1aa7505381b` |

### Cómo replicar este patrón en otra app

1. Editar `BUILD_AND_DEPLOY*.md` del proyecto
2. Agregar una sección `## 🍎 iOS — Alternative: CLI upload via \`xcrun altool\``
3. Copiar el contenido del patrón de arriba
4. Reemplazar `<KEY_ID>`, `<ISSUER_ID>`, `<bundle>` y nombres específicos
5. Commitear con mensaje `docs(ios): add CLI upload guide via xcrun altool`
