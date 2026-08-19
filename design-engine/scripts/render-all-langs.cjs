#!/usr/bin/env node
/**
 * render-all-langs.cjs — Genera videos en los 6 idiomas del ecosistema.
 *
 * Estrategia: reemplaza el bloque CONFIG completo en el HTML fuente
 * con la versión traducida. Funciona con cualquier template que use CONFIG.
 *
 * Uso:
 *   NODE_PATH=$(npm root -g) node render-all-langs.cjs \
 *     --template=source/vertical.html \
 *     --translations=translations.json \
 *     --outdir=videos/ \
 *     --duration=22 --width=1080 --height=1920
 *
 * translations.json:
 * {
 *   "es": { "nombre": "...", "descripcion": "...", "features": [...], "badges": [...] },
 *   "en": { ... }, "pt": { ... }, "fr": { ... }, "de": { ... }, "it": { ... }
 * }
 *
 * Cada idioma REEMPLAZA los campos correspondientes del objeto CONFIG
 * directamente en el código fuente HTML (string replacement, no runtime).
 */

const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const { spawnSync } = require('child_process');

function arg(name, def) {
  const p = process.argv.find(function(a) { return a.startsWith('--' + name + '='); });
  return p ? p.slice(name.length + 3) : def;
}

const TEMPLATE_FILE = arg('template', null);
const TRANSLATIONS_FILE = arg('translations', null);
const OUT_DIR = arg('outdir', 'videos');
const DURATION = parseFloat(arg('duration', '22'));
const WIDTH = parseInt(arg('width', '1080'));
const HEIGHT = parseInt(arg('height', '1920'));

if (!TEMPLATE_FILE || !TRANSLATIONS_FILE) {
  console.error('Usage: node render-all-langs.cjs --template=<html> --translations=<json> [--outdir=videos/] [--duration=22] [--width=1080] [--height=1920]');
  process.exit(1);
}

var templateHtml = fs.readFileSync(path.resolve(TEMPLATE_FILE), 'utf-8');
var translations = JSON.parse(fs.readFileSync(path.resolve(TRANSLATIONS_FILE), 'utf-8'));
var languages = Object.keys(translations);

fs.mkdirSync(path.resolve(OUT_DIR), { recursive: true });

console.log('▸ Template: ' + TEMPLATE_FILE);
console.log('▸ Languages: ' + languages.join(', '));
console.log('▸ Output: ' + OUT_DIR + '/');
console.log('▸ Size: ' + WIDTH + 'x' + HEIGHT + ' · Duration: ' + DURATION + 's');
console.log('');

// ── Extract base CONFIG from template ────────────────────────────────────
// Find the CONFIG block: everything between "const CONFIG = {" and the closing "};"
var configMatch = templateHtml.match(/const\s+CONFIG\s*=\s*(\{[\s\S]*?\n\};)/);
if (!configMatch) {
  console.error('✗ No CONFIG object found in template. Make sure the template uses:');
  console.error('  const CONFIG = { ... };');
  console.error('');
  console.error('Templates that use CONFIG: vertical-promo.html, app-showcase.html,');
  console.error('screenshot-set.html, feature-reel.html');
  process.exit(1);
}

var originalConfigBlock = configMatch[0];

// ── Generate localized HTMLs ────────────────────────────────────────────
var htmlFiles = {};

for (var i = 0; i < languages.length; i++) {
  var lang = languages[i];
  var t = translations[lang];
  var localizedHtml = templateHtml;

  // Replace specific CONFIG fields using regex on the source
  if (t.nombre) {
    localizedHtml = localizedHtml.replace(
      /(nombre:\s*')([^']*?)(')/,
      '$1' + t.nombre.replace(/'/g, "\\'") + '$3'
    );
  }
  if (t.version) {
    localizedHtml = localizedHtml.replace(
      /(version:\s*')([^']*?)(')/,
      '$1' + t.version.replace(/'/g, "\\'") + '$3'
    );
  }
  if (t.descripcion) {
    localizedHtml = localizedHtml.replace(
      /(descripcion:\s*')([^']*?)(')/,
      '$1' + t.descripcion.replace(/'/g, "\\'") + '$3'
    );
  }
  if (t.url) {
    localizedHtml = localizedHtml.replace(
      /(url:\s*')([^']*?)(')/,
      '$1' + t.url.replace(/'/g, "\\'") + '$3'
    );
  }
  if (t.badges) {
    // Replace the entire badges array
    var badgesStr = JSON.stringify(t.badges);
    localizedHtml = localizedHtml.replace(
      /badges:\s*\[.*?\]/s,
      'badges: ' + badgesStr
    );
  }
  if (t.features) {
    // Replace the entire features array
    var featuresLines = t.features.map(function(f) {
      return "        { icon: '" + f.icon + "', titulo: '" + 
        f.titulo.replace(/'/g, "\\'") + "', desc: '" + 
        f.desc.replace(/'/g, "\\'") + "'" +
        (f.tag ? ", tag: '" + f.tag + "'" : "") + " }";
    }).join(',\n');
    localizedHtml = localizedHtml.replace(
      /features:\s*\[[\s\S]*?\]/,
      'features: [\n' + featuresLines + '\n    ]'
    );
  }

  // Update html lang attribute
  localizedHtml = localizedHtml.replace(/lang="[a-z]{2}"/, 'lang="' + lang + '"');

  var htmlPath = path.resolve(OUT_DIR, 'promo-' + lang + '.html');
  fs.writeFileSync(htmlPath, localizedHtml);
  htmlFiles[lang] = htmlPath;
  console.log('  ✓ Generated: promo-' + lang + '.html');
}

console.log('');

// ── Render each to MP4 ─────────────────────────────────────────────────
(async function() {
  var browser = await chromium.launch();

  for (var i = 0; i < languages.length; i++) {
    var lang = languages[i];
    var htmlPath = htmlFiles[lang];
    var mp4Path = path.resolve(OUT_DIR, 'promo-' + lang + '.mp4');
    var url = 'file://' + htmlPath;
    var tmpDir = path.resolve(OUT_DIR, '.tmp-' + lang + '-' + Date.now());
    fs.mkdirSync(tmpDir, { recursive: true });

    console.log('▸ [' + lang + '] Rendering...');

    // Warmup
    var warmupCtx = await browser.newContext({ viewport: { width: WIDTH, height: HEIGHT } });
    var warmupPage = await warmupCtx.newPage();
    await warmupPage.goto(url, { waitUntil: 'load', timeout: 60000 });
    await warmupPage.waitForTimeout(1500);
    await warmupCtx.close();

    // Record
    var recordCtx = await browser.newContext({
      viewport: { width: WIDTH, height: HEIGHT },
      deviceScaleFactor: 1,
      recordVideo: { dir: tmpDir, size: { width: WIDTH, height: HEIGHT } },
    });
    await recordCtx.addInitScript(function() { window.__recording = true; });

    var T0 = Date.now();
    var page = await recordCtx.newPage();
    await page.goto(url, { waitUntil: 'load', timeout: 60000 });

    var hasReady = await page.waitForFunction(
      function() { return window.__ready === true; },
      { timeout: 8000 }
    ).then(function() { return true; }).catch(function() { return false; });

    var trimSec;
    if (hasReady) {
      trimSec = (Date.now() - T0) / 1000 + 0.05;
      console.log('  [' + lang + '] Ready at ' + trimSec.toFixed(2) + 's');
    } else {
      trimSec = 2;
      console.log('  [' + lang + '] Warning: no __ready, trim=' + trimSec + 's');
    }

    await page.waitForTimeout(DURATION * 1000 + 300);
    await page.close();
    await recordCtx.close();

    // Encode
    var webmFiles = fs.readdirSync(tmpDir).filter(function(f) { return f.endsWith('.webm'); });
    if (webmFiles.length === 0) {
      console.error('  [' + lang + '] ✗ No webm produced');
      continue;
    }
    var webmPath = path.join(tmpDir, webmFiles[0]);

    var ffmpeg = spawnSync('ffmpeg', [
      '-y', '-ss', String(trimSec), '-i', webmPath,
      '-t', String(DURATION),
      '-c:v', 'libx264', '-pix_fmt', 'yuv420p',
      '-crf', '18', '-preset', 'medium', '-movflags', '+faststart',
      mp4Path,
    ], { stdio: ['ignore', 'ignore', 'pipe'] });

    if (ffmpeg.status !== 0) {
      console.error('  [' + lang + '] ✗ ffmpeg failed');
      continue;
    }

    fs.rmSync(tmpDir, { recursive: true, force: true });
    var sizeMB = (fs.statSync(mp4Path).size / 1024 / 1024).toFixed(1);
    console.log('  [' + lang + '] ✓ ' + path.basename(mp4Path) + ' (' + sizeMB + ' MB)');
  }

  await browser.close();
  console.log('\n✓ All languages rendered.');
})();
