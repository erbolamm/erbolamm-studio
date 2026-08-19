// ═══════════════════════════════════════════════════════════════
// 🏗️ Project Templates — "Made in Apliarte/ErBolamm"
// ═══════════════════════════════════════════════════════════════
// Cada tipo de proyecto tiene su propia estructura de promo/,
// requisitos de assets, branding, y checklist de publicación.
// El Orchestrator usa estas plantillas para guiar al MarketingAgent
// y AuditorAgent según el tipo detectado.
// ═══════════════════════════════════════════════════════════════

/// Define la estructura y requisitos para un tipo de proyecto.
class ProjectTemplate {
  final String typeKey; // 'app', 'extension', 'package', 'website', 'workflow'
  final String label;
  final String emoji;
  final String defaultPillar;
  final String defaultColor;

  /// Carpetas que deben existir en promo/
  final List<String> requiredDirs;

  /// Assets requeridos para considerar el proyecto "listo para publicar"
  final List<AssetRequirement> requiredAssets;

  /// Checklist de publicación (se muestra al usuario)
  final List<String> publishChecklist;

  /// Template de brand-spec específico para este tipo
  final String Function(String name, String type) brandSpecBuilder;

  /// Mockup HTML específico para este tipo
  final String Function(String name, String type) mockupBuilder;

  const ProjectTemplate({
    required this.typeKey,
    required this.label,
    required this.emoji,
    required this.defaultPillar,
    required this.defaultColor,
    required this.requiredDirs,
    required this.requiredAssets,
    required this.publishChecklist,
    required this.brandSpecBuilder,
    required this.mockupBuilder,
  });
}

/// Un asset que el proyecto debe tener para publicarse.
class AssetRequirement {
  final String id;
  final String label;
  final String description;
  final bool critical; // ¿Bloquea la publicación si falta?

  const AssetRequirement({
    required this.id,
    required this.label,
    required this.description,
    this.critical = true,
  });
}

// ═══════════════════════════════════════════════════════════════
// 📱 App Template (Flutter app)
// ═══════════════════════════════════════════════════════════════

const appTemplate = ProjectTemplate(
  typeKey: 'app',
  label: 'App',
  emoji: '📱',
  defaultPillar: 'apps',
  defaultColor: '#7C3AED',
  requiredDirs: [
    'screenshots',
    'screenshots/mobile',
    'screenshots/desktop',
    'videos',
    'assets',
  ],
  requiredAssets: [
    AssetRequirement(
      id: 'screenshots_mobile',
      label: 'Screenshots mobile',
      description: '3-5 capturas en dispositivos móviles (iOS + Android)',
      critical: true,
    ),
    AssetRequirement(
      id: 'screenshots_desktop',
      label: 'Screenshots desktop',
      description: '2-3 capturas en macOS/Windows',
    ),
    AssetRequirement(
      id: 'video_vertical',
      label: 'Video vertical',
      description: 'Promo 1080×1920 para TikTok/Reels/Shorts',
      critical: true,
    ),
    AssetRequirement(
      id: 'video_horizontal',
      label: 'Video horizontal',
      description: 'Promo 1920×1080 para YouTube/Web',
    ),
    AssetRequirement(
      id: 'brand_spec',
      label: 'Brand spec',
      description: 'Paleta de colores, tipografía, logo',
      critical: true,
    ),
    AssetRequirement(
      id: 'music',
      label: 'Música de fondo',
      description: 'Track instrumental 22-30s al estilo de la app',
    ),
    AssetRequirement(
      id: 'narration_es',
      label: 'Narración español',
      description: 'Audio con tu voz describiendo la app',
      critical: true,
    ),
    AssetRequirement(
      id: 'narration_en',
      label: 'Narración inglés',
      description: 'Audio con tu voz en inglés',
    ),
    AssetRequirement(
      id: 'landing',
      label: 'Landing page',
      description:
          'Página web de presentación (GitHub Pages, Firebase Hosting)',
      critical: true,
    ),
  ],
  publishChecklist: [
    'README.md completo con badges y descripción',
    'LICENSE (MIT, Apache, etc.)',
    'Screenshots en App Store Connect / Google Play Console',
    'Landing page publicada',
    'Video promo en YouTube',
    'Registrado en universe.json',
  ],
  brandSpecBuilder: _appBrandSpec,
  mockupBuilder: _appMockup,
);

// ═══════════════════════════════════════════════════════════════
// 🧩 Extension Template (VSCode)
// ═══════════════════════════════════════════════════════════════

const extensionTemplate = ProjectTemplate(
  typeKey: 'extension',
  label: 'Extensión',
  emoji: '🧩',
  defaultPillar: 'tools',
  defaultColor: '#00BFA5',
  requiredDirs: ['screenshots', 'videos', 'assets'],
  requiredAssets: [
    AssetRequirement(
      id: 'screenshots_marketplace',
      label: 'Screenshots marketplace',
      description: 'Capturas para VS Code / Cursor marketplace',
      critical: true,
    ),
    AssetRequirement(
      id: 'demo_gif',
      label: 'GIF / video demo',
      description: 'Demo animada mostrando la extensión en acción',
      critical: true,
    ),
    AssetRequirement(
      id: 'brand_spec',
      label: 'Brand spec',
      description: 'Paleta de colores, nombre en marketplace, ícono',
      critical: true,
    ),
    AssetRequirement(
      id: 'narration_es',
      label: 'Narración español',
      description: 'Audio describiendo la extensión',
    ),
    AssetRequirement(
      id: 'narration_en',
      label: 'Narración inglés',
      description: 'Audio en inglés',
      critical: true,
    ),
    AssetRequirement(
      id: 'landing',
      label: 'README + marketplace',
      description: 'README.md + página en VS Code marketplace',
      critical: true,
    ),
  ],
  publishChecklist: [
    'README.md con badges, features, y guía de uso',
    'package.json con displayName, description, icon, gallery',
    'Screenshots en marketplace gallery',
    'Publicado en VS Code Marketplace / Open VSX',
    'Video demo subido a YouTube',
    'Registrado en universe.json',
  ],
  brandSpecBuilder: _extensionBrandSpec,
  mockupBuilder: _extensionMockup,
);

// ═══════════════════════════════════════════════════════════════
// 📦 Package Template (Dart/Flutter)
// ═══════════════════════════════════════════════════════════════

const packageTemplate = ProjectTemplate(
  typeKey: 'package',
  label: 'Paquete',
  emoji: '📦',
  defaultPillar: 'tools',
  defaultColor: '#10B981',
  requiredDirs: ['screenshots', 'videos', 'assets'],
  requiredAssets: [
    AssetRequirement(
      id: 'screenshots',
      label: 'Screenshots',
      description: 'Capturas mostrando el paquete en uso',
    ),
    AssetRequirement(
      id: 'demo_video',
      label: 'Video demo',
      description: 'Demo rápida del paquete funcionando',
    ),
    AssetRequirement(
      id: 'brand_spec',
      label: 'Brand spec',
      description: 'Nombre en pub.dev, colores, emoji',
      critical: true,
    ),
    AssetRequirement(
      id: 'readme_badges',
      label: 'README + badges',
      description: 'README con badges de pub.dev, coverage, style',
      critical: true,
    ),
    AssetRequirement(
      id: 'narration_es',
      label: 'Narración español',
      description: 'Audio explicando el paquete',
    ),
    AssetRequirement(
      id: 'narration_en',
      label: 'Narración inglés',
      description: 'Audio en inglés',
      critical: true,
    ),
  ],
  publishChecklist: [
    'pubspec.yaml con description y homepage',
    'README.md con badges, quickstart, API reference',
    'Tests con coverage > 80%',
    'Publicado en pub.dev',
    'Registrado en universe.json',
  ],
  brandSpecBuilder: _packageBrandSpec,
  mockupBuilder: _packageMockup,
);

// ═══════════════════════════════════════════════════════════════
// 🌐 Website Template (React/Node/HTML)
// ═══════════════════════════════════════════════════════════════

const websiteTemplate = ProjectTemplate(
  typeKey: 'website',
  label: 'Web App',
  emoji: '🌐',
  defaultPillar: 'web',
  defaultColor: '#3B82F6',
  requiredDirs: [
    'screenshots',
    'screenshots/mobile',
    'screenshots/desktop',
    'videos',
    'assets',
  ],
  requiredAssets: [
    AssetRequirement(
      id: 'screenshots_responsive',
      label: 'Screenshots responsive',
      description: 'Capturas en mobile, tablet, desktop',
      critical: true,
    ),
    AssetRequirement(
      id: 'video_horizontal',
      label: 'Video horizontal',
      description: 'Demo 1920×1080 mostrando la web',
      critical: true,
    ),
    AssetRequirement(
      id: 'brand_spec',
      label: 'Brand spec',
      description: 'Paleta de colores, tipografía, favicon',
      critical: true,
    ),
    AssetRequirement(
      id: 'seo_meta',
      label: 'SEO metadata',
      description: 'Meta tags, Open Graph, Twitter Cards',
      critical: true,
    ),
    AssetRequirement(
      id: 'narration_es',
      label: 'Narración español',
      description: 'Audio describiendo la web app',
    ),
    AssetRequirement(
      id: 'narration_en',
      label: 'Narración inglés',
      description: 'Audio en inglés',
    ),
    AssetRequirement(
      id: 'landing',
      label: 'Landing page',
      description: 'Página de presentación (Firebase Hosting, Vercel)',
      critical: true,
    ),
  ],
  publishChecklist: [
    'index.html con meta tags completos',
    'Favicon y manifiesto PWA',
    'Sitemap.xml y robots.txt',
    'Firebase Hosting / Vercel / Netlify deploy',
    'Video demo en YouTube',
    'Registrado en universe.json',
  ],
  brandSpecBuilder: _websiteBrandSpec,
  mockupBuilder: _websiteMockup,
);

// ═══════════════════════════════════════════════════════════════
// ⚡ Workflow Template (n8n)
// ═══════════════════════════════════════════════════════════════

const workflowTemplate = ProjectTemplate(
  typeKey: 'workflow',
  label: 'Workflow',
  emoji: '⚡',
  defaultPillar: 'automation',
  defaultColor: '#F59E0B',
  requiredDirs: ['screenshots', 'videos', 'assets'],
  requiredAssets: [
    AssetRequirement(
      id: 'screenshot_flow',
      label: 'Screenshot del flow',
      description: 'Captura del workflow completo en n8n',
      critical: true,
    ),
    AssetRequirement(
      id: 'diagram',
      label: 'Diagrama',
      description: 'Diagrama de flujo (Mermaid, Excalidraw)',
    ),
    AssetRequirement(
      id: 'demo_video',
      label: 'Video demo',
      description: 'Demo del workflow ejecutándose',
      critical: true,
    ),
    AssetRequirement(
      id: 'brand_spec',
      label: 'Brand spec',
      description: 'Nombre, descripción, tags del workflow',
      critical: true,
    ),
    AssetRequirement(
      id: 'narration_es',
      label: 'Narración español',
      description: 'Audio explicando qué hace el workflow',
    ),
    AssetRequirement(
      id: 'narration_en',
      label: 'Narración inglés',
      description: 'Audio en inglés',
    ),
  ],
  publishChecklist: [
    'README.md con descripción y diagrama',
    'Workflow exportado como JSON',
    'Credenciales documentadas',
    'Video demo en YouTube',
    'Registrado en universe.json',
  ],
  brandSpecBuilder: _workflowBrandSpec,
  mockupBuilder: _workflowMockup,
);

// ═══════════════════════════════════════════════════════════════
// 📋 Registry: acceso por tipo
// ═══════════════════════════════════════════════════════════════

const templatesByType = <String, ProjectTemplate>{
  'app': appTemplate,
  'extension': extensionTemplate,
  'package': packageTemplate,
  'website': websiteTemplate,
  'workflow': workflowTemplate,
};

/// Devuelve la plantilla para un tipo de proyecto, o la de app por defecto.
ProjectTemplate templateForType(String type) {
  return templatesByType[type] ?? appTemplate;
}

// ═══════════════════════════════════════════════════════════════
// 🎨 Brand Spec Builders
// ═══════════════════════════════════════════════════════════════

String _appBrandSpec(String name, String type) {
  return '''# $name — Brand Spec

> Generado por ErBolamm Studio · App Template

## Identidad

| Campo | Valor |
|-------|-------|
| Nombre | $name |
| Tipo | $type |
| Plataformas | iOS, Android, macOS |
| Licencia | MIT |

## Paleta

| Uso | Color | HEX |
|-----|-------|-----|
| Principal | Púrpura Apliarte | #7C3AED |
| Acento | Verde ErBolamm | #10B981 |
| Fondo claro | White Smoke | #F8F9FC |
| Fondo oscuro | Dark Void | #0F0F1A |
| Texto | Slate | #1E293B |

## Tipografía

| Rol | Fuente |
|-----|--------|
| Títulos | Inter Bold 800 |
| Cuerpo | Inter Regular 400 |
| Código | JetBrains Mono |

## Assets requeridos

| Asset | Formato | Estado |
|-------|---------|--------|
| Logo / Icono | PNG 1024×1024 | ⬜ |
| Screenshots mobile | PNG 1290×2796 | ⬜ |
| Screenshots desktop | PNG 2880×1800 | ⬜ |
| Video vertical | MP4 1080×1920 | ⬜ |
| Video horizontal | MP4 1920×1080 | ⬜ |
| Música fondo | WAV/MP3 22-30s | ⬜ |
| Narración ES | WAV 44.1kHz | ⬜ |
| Narración EN | WAV 44.1kHz | ⬜ |

## Enlaces

- App Store: pendiente
- Google Play: pendiente
- Landing: pendiente
- GitHub: pendiente
''';
}

String _extensionBrandSpec(String name, String type) {
  return '''# $name — Brand Spec

> Generado por ErBolamm Studio · Extension Template

## Identidad

| Campo | Valor |
|-------|-------|
| Nombre | $name |
| Tipo | VS Code / Cursor Extension |
| Marketplace | VS Code Marketplace + Open VSX |
| Licencia | MIT |

## Paleta

| Uso | Color | HEX |
|-----|-------|-----|
| Principal | Teal | #00BFA5 |
| Acento | Púrpura Apliarte | #7C3AED |
| Fondo editor | VS Code Dark | #1E1E1E |
| Texto | Editor Foreground | #D4D4D4 |

## Assets requeridos

| Asset | Formato | Estado |
|-------|---------|--------|
| Icono | PNG 128×128 | ⬜ |
| Screenshots | PNG 1280×800 | ⬜ |
| GIF demo | GIF 800×600 | ⬜ |
| README badges | Markdown | ⬜ |
| Narración EN | WAV 44.1kHz | ⬜ |

## Marketplace

- Publisher: apliarte
- Gallery: 3-5 screenshots
- Tags: pendiente
''';
}

String _packageBrandSpec(String name, String type) {
  return '''# $name — Brand Spec

> Generado por ErBolamm Studio · Package Template

## Identidad

| Campo | Valor |
|-------|-------|
| Nombre | $name |
| Tipo | Dart/Flutter Package |
| Publicación | pub.dev |
| Licencia | MIT |

## Paleta

| Uso | Color | HEX |
|-----|-------|-----|
| Principal | Verde | #10B981 |
| Acento | Púrpura Apliarte | #7C3AED |
| Fondo README | White | #FFFFFF |
| Badge color | Verde | #10B981 |

## Assets requeridos

| Asset | Formato | Estado |
|-------|---------|--------|
| Screenshots | PNG | ⬜ |
| Video demo | MP4 | ⬜ |
| README badges | Markdown | ⬜ |
| Narración EN | WAV 44.1kHz | ⬜ |

## pub.dev

- Publisher: apliarte
- Topics: pendiente
- Coverage: >80%
''';
}

String _websiteBrandSpec(String name, String type) {
  return '''# $name — Brand Spec

> Generado por ErBolamm Studio · Website Template

## Identidad

| Campo | Valor |
|-------|-------|
| Nombre | $name |
| Tipo | Web Application |
| Hosting | Firebase / Vercel |
| Dominio | Pendiente |

## Paleta

| Uso | Color | HEX |
|-----|-------|-----|
| Principal | Azul | #3B82F6 |
| Acento | Púrpura Apliarte | #7C3AED |
| Fondo | Slate Dark | #0F172A |
| Texto | White | #F8FAFC |

## SEO

| Meta | Valor |
|------|-------|
| Title | $name — descripción pendiente |
| Description | Pendiente de completar |
| OG Image | promo/screenshots/og-image.png |
| Favicon | promo/assets/favicon.ico |

## Assets requeridos

| Asset | Formato | Estado |
|-------|---------|--------|
| Screenshots responsive | PNG | ⬜ |
| OG Image | PNG 1200×630 | ⬜ |
| Favicon | ICO 32×32 | ⬜ |
| Video horizontal | MP4 1920×1080 | ⬜ |
| Narración ES | WAV 44.1kHz | ⬜ |
''';
}

String _workflowBrandSpec(String name, String type) {
  return '''# $name — Brand Spec

> Generado por ErBolamm Studio · Workflow Template

## Identidad

| Campo | Valor |
|-------|-------|
| Nombre | $name |
| Tipo | n8n Workflow |
| Plataforma | n8n self-hosted / cloud |

## Paleta

| Uso | Color | HEX |
|-----|-------|-----|
| Principal | Ámbar | #F59E0B |
| Acento | Púrpura Apliarte | #7C3AED |
| Fondo | Warm Gray | #1C1917 |

## Assets requeridos

| Asset | Formato | Estado |
|-------|---------|--------|
| Screenshot del flow | PNG | ⬜ |
| Diagrama | Mermaid/PNG | ⬜ |
| Video demo | MP4 1920×1080 | ⬜ |
| Narración ES | WAV 44.1kHz | ⬜ |

## Workflow

- Nodos: pendiente
- Triggers: pendiente
- Credenciales: documentadas en README
''';
}

// ═══════════════════════════════════════════════════════════════
// 📄 Mockup Builders (HTML placeholders específicos por tipo)
// ═══════════════════════════════════════════════════════════════

String _appMockup(String name, String type) {
  return '''<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>$name — App Preview</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:Inter,sans-serif;background:linear-gradient(135deg,#0f0f1a,#1a1a2e);color:#fff;display:flex;align-items:center;justify-content:center;min-height:100vh;padding:20px}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:24px;max-width:1000px}
.card{background:rgba(124,58,237,0.1);border:1px solid rgba(124,58,237,0.3);border-radius:20px;padding:32px;text-align:center}
.card h2{font-size:24px;font-weight:800;margin-bottom:8px}
.card .emoji{font-size:48px;margin-bottom:16px}
.card p{color:#94a3b8;font-size:14px;line-height:1.6}
.tag{display:inline-block;background:rgba(124,58,237,0.2);color:#a78bfa;padding:4px 12px;border-radius:20px;font-size:12px;margin-top:12px}
.footer{margin-top:32px;color:#475569;font-size:11px}
</style></head>
<body>
<div style="text-align:center">
  <div class="grid">
    <div class="card"><div class="emoji">📱</div><h2>$name</h2><p>$type · App Preview</p><span class="tag">iOS + Android</span></div>
    <div class="card"><div class="emoji">🎨</div><h2>Diseño</h2><p>Interfaz moderna con Material Design 3</p><span class="tag">Flutter</span></div>
    <div class="card"><div class="emoji">🚀</div><h2>Performance</h2><p>Compilado nativo, 60fps fluidos</p><span class="tag">ARM64</span></div>
  </div>
  <p class="footer">Mockup generado por ErBolamm Studio · Reemplazar con capturas reales</p>
</div>
</body></html>''';
}

String _extensionMockup(String name, String type) {
  return '''<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>$name — Extension Preview</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:Inter,sans-serif;background:#1e1e1e;color:#d4d4d4;display:flex;align-items:center;justify-content:center;min-height:100vh}
.card{background:#252526;border:1px solid #3e3e42;border-radius:12px;padding:40px;max-width:500px;text-align:center}
.card .emoji{font-size:64px;margin-bottom:16px}
.card h1{font-size:28px;color:#00bfa5;margin-bottom:8px}
.card p{color:#808080;font-size:14px}
.badge{display:inline-block;background:rgba(0,191,165,0.15);color:#00bfa5;padding:6px 16px;border-radius:6px;font-size:13px;margin-top:16px}
</style></head>
<body>
<div class="card">
  <div class="emoji">🧩</div>
  <h1>$name</h1>
  <p>$type · VS Code / Cursor Extension</p>
  <span class="badge">Marketplace</span>
  <p style="margin-top:24px;font-size:11px;color:#555">Mockup · Reemplazar con capturas reales</p>
</div>
</body></html>''';
}

String _packageMockup(String name, String type) {
  return '''<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>$name — Package Preview</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:Inter,sans-serif;background:#0f172a;color:#e2e8f0;display:flex;align-items:center;justify-content:center;min-height:100vh}
.card{background:rgba(16,185,129,0.08);border:1px solid rgba(16,185,129,0.2);border-radius:16px;padding:40px;max-width:450px;text-align:center}
.card .emoji{font-size:56px;margin-bottom:12px}
.card h1{font-size:26px;color:#10b981;margin-bottom:8px}
.card code{display:block;background:rgba(0,0,0,0.3);padding:12px 20px;border-radius:8px;font-family:"JetBrains Mono",monospace;font-size:13px;color:#34d399;margin:16px 0}
.card p{color:#64748b;font-size:13px}
</style></head>
<body>
<div class="card">
  <div class="emoji">📦</div>
  <h1>$name</h1>
  <p>$type · pub.dev</p>
  <code>flutter pub add $name</code>
  <p style="margin-top:16px;font-size:11px;color:#475569">Mockup · Reemplazar con capturas reales</p>
</div>
</body></html>''';
}

String _websiteMockup(String name, String type) {
  return '''<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>$name — Website Preview</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:Inter,sans-serif;background:linear-gradient(135deg,#0f172a,#1e293b);color:#f8fafc;display:flex;align-items:center;justify-content:center;min-height:100vh}
.card{background:rgba(59,130,246,0.1);border:1px solid rgba(59,130,246,0.3);border-radius:20px;padding:48px;max-width:500px;text-align:center}
.card .emoji{font-size:56px;margin-bottom:16px}
.card h1{font-size:30px;color:#60a5fa;margin-bottom:8px}
.card .url{color:#94a3b8;font-size:14px;margin-bottom:24px}
.devices{display:flex;gap:16px;justify-content:center;margin-top:24px}
.device{background:rgba(0,0,0,0.2);border-radius:10px;padding:12px 16px;font-size:12px;color:#64748b}
</style></head>
<body>
<div class="card">
  <div class="emoji">🌐</div>
  <h1>$name</h1>
  <p class="url">$type · Firebase / Vercel</p>
  <div class="devices">
    <span class="device">📱 Mobile</span>
    <span class="device">💻 Desktop</span>
    <span class="device">📟 Tablet</span>
  </div>
  <p style="margin-top:24px;font-size:11px;color:#475569">Mockup · Reemplazar con capturas reales</p>
</div>
</body></html>''';
}

String _workflowMockup(String name, String type) {
  return '''<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>$name — Workflow Preview</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:Inter,sans-serif;background:#1c1917;color:#fafaf9;display:flex;align-items:center;justify-content:center;min-height:100vh}
.card{background:rgba(245,158,11,0.08);border:1px solid rgba(245,158,11,0.2);border-radius:16px;padding:40px;max-width:450px;text-align:center}
.card .emoji{font-size:56px;margin-bottom:12px}
.card h1{font-size:26px;color:#f59e0b;margin-bottom:8px}
.flow{display:flex;align-items:center;justify-content:center;gap:8px;margin:20px 0}
.node{background:rgba(245,158,11,0.15);border:1px solid rgba(245,158,11,0.4);border-radius:8px;padding:8px 14px;font-size:12px;color:#fbbf24}
.arrow{color:#78716c;font-size:16px}
.card p.sub{color:#78716c;font-size:13px;margin-top:16px}
</style></head>
<body>
<div class="card">
  <div class="emoji">⚡</div>
  <h1>$name</h1>
  <p class="sub">$type · n8n Automation</p>
  <div class="flow">
    <span class="node">📥 Trigger</span>
    <span class="arrow">→</span>
    <span class="node">⚙️ Process</span>
    <span class="arrow">→</span>
    <span class="node">📤 Output</span>
  </div>
  <p style="margin-top:20px;font-size:11px;color:#57534e">Mockup · Reemplazar con captura real del workflow</p>
</div>
</body></html>''';
}
