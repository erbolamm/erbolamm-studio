// ═══════════════════════════════════════════════════════════════
// 🎵 Music Studio Screen — Generación de música procedural
// ═══════════════════════════════════════════════════════════════
// 1. Describí un estilo → genera código Strudel + audio WAV
// 2. Preview con Tone.js (OfflineAudioContext)
// 3. Guarda en promo/music/ para Publisher
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../../../core/constants/colors.dart';
import '../../../../../core/navigation/adaptive_navigation.dart';
import '../../../../../services/project_monitor.dart';
import '../../domain/audio_renderer.dart';
import '../../domain/music_style.dart';
import '../../domain/strudel_generator.dart';

class MusicStudioScreen extends StatefulWidget {
  final ProjectMonitor monitor;

  const MusicStudioScreen({super.key, required this.monitor});

  @override
  State<MusicStudioScreen> createState() => _MusicStudioScreenState();
}

class _MusicStudioScreenState extends State<MusicStudioScreen> {
  final _styleController = TextEditingController();
  final _bpmController = TextEditingController();
  final _durationController = TextEditingController();
  final _renderer = AudioRenderer();

  MusicStyle? _currentStyle;
  bool _isGenerating = false;
  bool _isRendering = false;
  AudioRenderResult? _lastRender;
  List<MusicStyle> _history = [];
  bool _showHistory = false;
  int _selectedPreset = -1;

  @override
  void initState() {
    super.initState();
    _durationController.text = '30';
    _loadHistory();
  }

  @override
  void dispose() {
    _styleController.dispose();
    _bpmController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final path = widget.monitor.projectPath;
    if (path == null) return;

    final musicDir = Directory(p.join(path, 'erbolamm-studio', 'music', 'styles')).existsSync()
        ? Directory(p.join(path, 'erbolamm-studio', 'music', 'styles'))
        : Directory(p.join(path, 'promo', 'music', 'styles'));
    if (!await musicDir.exists()) return;

    final files = await musicDir.list().toList();
    final styles = <MusicStyle>[];
    for (final entity in files) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final json = entity.readAsStringSync();
          styles.add(MusicStyle.fromJson(jsonDecode(json) as Map<String, dynamic>));
        } catch (_) {}
      }
    }
    styles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (mounted) setState(() => _history = styles);
  }

  @override
  Widget build(BuildContext context) {
    final hasProject = widget.monitor.hasProject;
    final projName = widget.monitor.projectName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎵 Music Studio'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: Icon(
                _showHistory ? Icons.close : Icons.history,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _showHistory = !_showHistory),
              tooltip: 'Historial',
            ),
          if (hasProject)
            Chip(
              avatar: const Icon(Icons.check_circle, size: 16, color: AppColors.success),
              label: Text(projName ?? '', style: const TextStyle(fontSize: 12)),
              backgroundColor: AppColors.success.withValues(alpha: 0.1),
            ),
          const SettingsMenuButton(),
        ],
      ),
      body: !hasProject
          ? _buildEmptyState()
          : _showHistory
              ? _buildHistory()
              : _buildStudio(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.music_note_outlined, size: 40, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          const Text('Music Studio', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Agregá un proyecto en INBOX/ para usar el Music Studio.\n'
              'Acá podrás generar música procedural con Strudel + Tone.js.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudio() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Presets ──
          const Text('Estilos predefinidos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(kStylePresets.length, (i) {
                final selected = _selectedPreset == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(kStylePresets[i].name, style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        _selectedPreset = v ? i : -1;
                        if (v) {
                          _styleController.text = kStylePresets[i].description;
                          _bpmController.text =
                              StrudelGenerator.extractBpm(kStylePresets[i].description).toString();
                        }
                      });
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),

          // ── Input ──
          const Text('Describí el estilo musical',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _styleController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Funk 80s, 120 BPM, bajo slap, pads supersaw...',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bpmController,
                  decoration: const InputDecoration(
                    labelText: 'BPM',
                    hintText: '120',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duración (s)',
                    hintText: '30',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Generate button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateMusic,
              icon: _isGenerating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: Text(_isGenerating ? 'Generando...' : 'Generar música'),
            ),
          ),

          // ── Result ──
          if (_currentStyle != null) ...[
            const SizedBox(height: 32),
            _buildResultCard(),

            // ── Render button ──
            if (_lastRender == null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isRendering ? null : _renderAudio,
                  icon: _isRendering
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.audiotrack),
                  label: Text(_isRendering ? 'Renderizando...' : '🎧 Renderizar audio (Tone.js)'),
                ),
              ),
            ],

            // ── Render result ──
            if (_lastRender != null) _buildRenderResult(),

            // ── Save button ──
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar en proyecto'),
                    onPressed: _lastRender?.success == true ? _saveToProject : null,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copiar código Strudel',
                  onPressed: () => _copyToClipboard(_currentStyle!.strudelCode),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  tooltip: 'Abrir en strudel.cc',
                  onPressed: _openInStrudel,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Text(_currentStyle!.description,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const SizedBox(height: 4),
            Text('${_currentStyle!.bpm} BPM',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: SelectableText(
                _currentStyle!.strudelCode,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textSecondary, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRenderResult() {
    final r = _lastRender!;
    return Card(
      color: r.success ? AppColors.success.withValues(alpha: 0.08) : AppColors.error.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Icon(r.success ? Icons.audiotrack : Icons.error,
              color: r.success ? AppColors.success : AppColors.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.success ? 'Audio generado' : 'Error',
                  style: TextStyle(fontWeight: FontWeight.bold, color: r.success ? AppColors.success : AppColors.error)),
              Text(r.success
                  ? '${_formatSize(r.fileSize)} · ${r.duration.inSeconds}s'
                  : r.error ?? 'Error desconocido',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ]),
          ),
          if (r.success)
            IconButton(
              icon: const Icon(Icons.play_arrow, color: AppColors.success),
              onPressed: () => _playAudio(r.outputPath),
            ),
        ]),
      ),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return const Center(child: Text('No hay estilos guardados',
          style: TextStyle(color: AppColors.textMuted)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, i) {
        final style = _history[i];
        final hasAudio = style.audioPath != null && File(style.audioPath!).existsSync();
        return Card(
          child: ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.educacion.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.music_note, color: AppColors.educacion, size: 20),
            ),
            title: Text(style.description, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${style.bpm} BPM · ${_formatDate(style.createdAt)}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasAudio)
                  IconButton(
                    icon: const Icon(Icons.play_arrow, size: 20),
                    onPressed: () => _playAudio(style.audioPath!),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                  onPressed: () => _deleteStyle(style),
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _currentStyle = style;
                _styleController.text = style.description;
                _bpmController.text = style.bpm.toString();
                _showHistory = false;
              });
            },
          ),
        );
      },
    );
  }

  void _generateMusic() {
    final description = _styleController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describí un estilo musical primero')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    final bpm = int.tryParse(_bpmController.text) ?? StrudelGenerator.extractBpm(description);
    final code = StrudelGenerator.generate(
      description: description,
      projectName: widget.monitor.projectName ?? 'proyecto',
      overrideBpm: bpm,
    );

    setState(() {
      _currentStyle = MusicStyle(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: description,
        bpm: bpm,
        strudelCode: code,
        createdAt: DateTime.now(),
      );
      _lastRender = null;
      _isGenerating = false;
    });
  }

  Future<void> _renderAudio() async {
    if (_currentStyle == null) return;

    setState(() => _isRendering = true);

    final projectPath = widget.monitor.projectPath;
    if (projectPath == null) return;
    final outputPath = p.join(projectPath, 'erbolamm-studio', 'music',
        'generated_${_currentStyle!.id}.wav');

    final result = await _renderer.render(
      strudelCode: _currentStyle!.strudelCode,
      bpm: _currentStyle!.bpm,
      durationSec: int.tryParse(_durationController.text) ?? 30,
      outputPath: outputPath,
    );

    if (!result.success && mounted) {
      // Fallback con ffmpeg
      final fallback = await _renderer.renderFallback(
        bpm: _currentStyle!.bpm,
        durationSec: int.tryParse(_durationController.text) ?? 30,
        outputPath: outputPath,
        style: _currentStyle!.description,
      );
      if (mounted) setState(() => _lastRender = fallback);
    } else if (mounted) {
      setState(() => _lastRender = result);
    }

    if (mounted) {
      setState(() => _isRendering = false);
    }
  }

  Future<void> _saveToProject() async {
    if (_currentStyle == null || _lastRender?.success != true) return;

    final projectPath = widget.monitor.projectPath;
    if (projectPath == null) return;

    final musicDir = Directory(p.join(projectPath, 'erbolamm-studio', 'music'));
    await musicDir.create(recursive: true);

    // Guardar como background.mp3 para Publisher
    final wavPath = p.join(musicDir.path, 'background.wav');
    if (_lastRender!.outputPath != wavPath) {
      await File(_lastRender!.outputPath).copy(wavPath);
    }

    // Guardar estilo en historial
    final updatedStyle = MusicStyle(
      id: _currentStyle!.id,
      description: _currentStyle!.description,
      bpm: _currentStyle!.bpm,
      strudelCode: _currentStyle!.strudelCode,
      createdAt: _currentStyle!.createdAt,
      audioPath: wavPath,
      projectName: widget.monitor.projectName,
      audioDuration: _lastRender!.duration,
    );

    final stylesDir = Directory(p.join(projectPath, 'erbolamm-studio', 'music', 'styles'));
    await stylesDir.create(recursive: true);
    await File(p.join(stylesDir.path, '${updatedStyle.id}.json'))
        .writeAsString(jsonEncode(updatedStyle.toJson()));

    if (mounted) {
      setState(() {
        _currentStyle = updatedStyle;
        _history.insert(0, updatedStyle);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Música guardada en erbolamm-studio/music/')),
      );
    }
  }

  void _copyToClipboard(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📋 Código copiado')),
    );
  }

  void _openInStrudel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🌐 Abriría strudel.cc con el código')),
    );
  }

  void _playAudio(String path) {
    Process.run('ffplay', ['-nodisp', '-autoexit', path]);
  }

  void _deleteStyle(MusicStyle style) {
    setState(() => _history.remove(style));
    final projectPath = widget.monitor.projectPath;
    if (projectPath == null) return;
    final file = File(p.join(projectPath, 'erbolamm-studio', 'music', 'styles', '${style.id}.json')).existsSync()
        ? File(p.join(projectPath, 'erbolamm-studio', 'music', 'styles', '${style.id}.json'))
        : File(p.join(projectPath, 'promo', 'music', 'styles', '${style.id}.json'));
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }
}


