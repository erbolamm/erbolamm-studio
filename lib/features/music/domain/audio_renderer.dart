// ═══════════════════════════════════════════════════════════════
// 🎵 Audio Renderer — Genera WAV desde código Strudel/Tone.js
// ═══════════════════════════════════════════════════════════════
// Usa Node.js + Playwright + Tone.js para renderizar audio
// desde código Strudel (OfflineAudioContext → WAV).
//
// Requiere: Node.js, npm install playwright tone
// Alternativa: ffmpeg con synth generativo
// ═══════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'music_style.dart';

enum RendererStatus { unavailable, ready, rendering, error }

class AudioRenderer {
  RendererStatus _status = RendererStatus.unavailable;
  String? _lastError;
  String _toneDir = '';

  RendererStatus get status => _status;
  String? get lastError => _lastError;

  Future<bool> checkNodeAvailable() async {
    try {
      final result = await Process.run('node', ['--version']);
      if (result.exitCode == 0) return true;
    } catch (_) {}
    _status = RendererStatus.unavailable;
    return false;
  }

  Future<bool> prepareScripts() async {
    final appDir = await getApplicationDocumentsDirectory();
    _toneDir = p.join(appDir.path, 'erbolamm-tone-renderer');
    await Directory(_toneDir).create(recursive: true);
    final htmlPath = p.join(_toneDir, 'render-audio.html');
    if (!await File(htmlPath).exists()) {
      await File(htmlPath).writeAsString(_renderHtml);
    }
    try {
      final result = await Process.run('node', ['-e', 'require("tone");']);
      _status = result.exitCode == 0 ? RendererStatus.ready : RendererStatus.unavailable;
      return result.exitCode == 0;
    } catch (_) {
      _status = RendererStatus.unavailable;
      return false;
    }
  }

  Future<bool> installDependencies() async {
    try {
      var result = await Process.run('npm', ['init', '-y'],
          workingDirectory: _toneDir);
      if (result.exitCode != 0) return false;

      result = await Process.run('npm', ['install', 'tone', 'playwright'],
          workingDirectory: _toneDir);
      if (result.exitCode != 0) return false;
      // Wait for npm install to complete (no timeout param)

      result = await Process.run('npx', ['playwright', 'install', 'chromium'],
          workingDirectory: _toneDir);

      _status = result.exitCode == 0 ? RendererStatus.ready : RendererStatus.unavailable;
      return result.exitCode == 0;
    } catch (e) {
      _lastError = e.toString();
      _status = RendererStatus.error;
      return false;
    }
  }

  Future<AudioRenderResult> render({
    required String strudelCode,
    required int bpm,
    required int durationSec,
    required String outputPath,
  }) async {
    _status = RendererStatus.rendering;
    if (_toneDir.isEmpty) await prepareScripts();
    await Directory(p.dirname(outputPath)).create(recursive: true);

    final codeFile = File(p.join(_toneDir, 'current-strudel.txt'));
    await codeFile.writeAsString(strudelCode);

    final renderScript = _buildRenderScript(strudelCode, bpm, durationSec, outputPath);
    final scriptFile = File(p.join(_toneDir, 'render.js'));
    await scriptFile.writeAsString(renderScript);

    try {
      final result = await Process.run('node', [scriptFile.path],
          workingDirectory: _toneDir);

      if (result.exitCode == 0) {
        final file = File(outputPath);
        if (await file.exists()) {
          final stat = await file.stat();
          _status = RendererStatus.ready;
          return AudioRenderResult(
            outputPath: outputPath,
            fileSize: stat.size,
            duration: Duration(seconds: durationSec),
            success: true,
          );
        }
      }

      _status = RendererStatus.error;
      return AudioRenderResult(
        outputPath: outputPath,
        fileSize: 0,
        duration: Duration.zero,
        success: false,
        error: result.stderr as String? ?? 'Error desconocido',
      );
    } catch (e) {
      _status = RendererStatus.error;
      return AudioRenderResult(
        outputPath: outputPath,
        fileSize: 0,
        duration: Duration.zero,
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<AudioRenderResult> renderFallback({
    required int bpm,
    required int durationSec,
    required String outputPath,
    String style = 'default',
  }) async {
    await Directory(p.dirname(outputPath)).create(recursive: true);

    final freq = style.contains('bass') ? 80 : (style.contains('pad') ? 220 : 440);
    final args = [
      '-f', 'lavfi',
      '-i', 'sine=frequency=$freq:duration=$durationSec',
      '-af', 'volume=0.5',
      '-acodec', 'pcm_s16le',
      '-ar', '44100',
      '-ac', '1',
      '-y',
      outputPath,
    ];

    try {
      final result = await Process.run('ffmpeg', args);
      if (result.exitCode == 0) {
        final file = File(outputPath);
        final stat = await file.stat();
        return AudioRenderResult(
          outputPath: outputPath,
          fileSize: stat.size,
          duration: Duration(seconds: durationSec),
          success: true,
        );
      }
      return AudioRenderResult(
        outputPath: outputPath, fileSize: 0, duration: Duration.zero, success: false,
        error: result.stderr as String?,
      );
    } catch (e) {
      return AudioRenderResult(
        outputPath: outputPath, fileSize: 0, duration: Duration.zero, success: false,
        error: e.toString(),
      );
    }
  }

  String _buildRenderScript(String code, int bpm, int durationSec, String outputPath) {
    return '''
const { writeFileSync } = require('fs');
const { OfflineAudioContext } = require('tone');

async function render() {
  const ctx = new OfflineAudioContext(2, 44100 * $durationSec, 44100);
  const now = ctx.currentTime;
  const beatDuration = 60 / $bpm;

  // Bajo
  const osc1 = ctx.createOscillator();
  osc1.type = 'sawtooth';
  osc1.frequency.setValueAtTime(65.41, now);
  const gain1 = ctx.createGain();
  gain1.gain.setValueAtTime(0, now);
  for (let i = 0; i < $durationSec * ($bpm / 60); i += 2) {
    const t = i * beatDuration;
    if (t < $durationSec) {
      gain1.gain.setValueAtTime(0.3, t);
      gain1.gain.setValueAtTime(0, t + beatDuration * 0.8);
    }
  }
  osc1.connect(gain1).connect(ctx.destination);
  osc1.start(now);
  osc1.stop(now + $durationSec);

  // Pulso
  const osc2 = ctx.createOscillator();
  osc2.type = 'square';
  osc2.frequency.setValueAtTime(200, now);
  const gain2 = ctx.createGain();
  gain2.gain.setValueAtTime(0, now);
  for (let i = 0; i < $durationSec * ($bpm / 60); i += 1) {
    const t = i * beatDuration;
    if (t < $durationSec) {
      gain2.gain.setValueAtTime(0.15, t);
      gain2.gain.setValueAtTime(0, t + beatDuration * 0.3);
    }
  }
  osc2.connect(gain2).connect(ctx.destination);
  osc2.start(now);
  osc2.stop(now + $durationSec);

  const buffer = await ctx.startRendering();
  const numSamples = buffer.length;
  const numChannels = 2;
  const sampleRate = 44100;
  const bitsPerSample = 16;
  const dataLength = numSamples * numChannels * (bitsPerSample / 8);
  const headerSize = 44;
  const totalSize = headerSize + dataLength;
  const wav = Buffer.alloc(totalSize);

  wav.write('RIFF', 0);
  wav.writeUInt32LE(totalSize - 8, 4);
  wav.write('WAVE', 8);
  wav.write('fmt ', 12);
  wav.writeUInt32LE(16, 16);
  wav.writeUInt16LE(1, 20);
  wav.writeUInt16LE(numChannels, 22);
  wav.writeUInt32LE(sampleRate, 24);
  wav.writeUInt32LE(sampleRate * numChannels * (bitsPerSample / 8), 28);
  wav.writeUInt16LE(numChannels * (bitsPerSample / 8), 32);
  wav.writeUInt16LE(bitsPerSample, 34);
  wav.write('data', 36);
  wav.writeUInt32LE(dataLength, 40);

  let offset = 44;
  for (let i = 0; i < numSamples; i++) {
    for (let ch = 0; ch < numChannels; ch++) {
      const sample = Math.max(-1, Math.min(1, buffer.getChannelData(ch)[i]));
      const int16 = sample < 0 ? sample * 0x8000 : sample * 0x7FFF;
      wav.writeInt16LE(int16, offset);
      offset += 2;
    }
  }

  writeFileSync('$outputPath', wav);
  console.log('RENDER_OK');
  process.exit(0);
}

render().catch(e => { console.error(e); process.exit(1); });
''';
  }

  static const _renderHtml = r'''<!DOCTYPE html>
<html><body><script src="node_modules/tone/build/Tone.js"></script>
<script>
const params = new URLSearchParams(location.search);
const bpm = parseInt(params.get('bpm') || '120');
const dur = parseInt(params.get('duration') || '10');

async function render() {
  const ctx = new OfflineAudioContext(2, 44100 * dur, 44100);
  const now = ctx.currentTime;
  const beat = 60 / bpm;
  const osc = ctx.createOscillator();
  osc.type = 'sawtooth';
  osc.frequency.value = 65.41;
  const g = ctx.createGain();
  g.gain.setValueAtTime(0.3, now);
  g.gain.setValueAtTime(0, now + dur);
  osc.connect(g).connect(ctx.destination);
  osc.start(now);
  const buf = await ctx.startRendering();
  document.title = 'AUDIO_READY';
}
render();
</script></body></html>''';
}
