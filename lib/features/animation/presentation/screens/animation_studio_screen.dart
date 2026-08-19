// ═══════════════════════════════════════════════════════════════
// 🎬 Animation Studio — Generación de animaciones HTML a video
// ═══════════════════════════════════════════════════════════════
// 1. Seleccioná un template (vertical/horizontal/screenshots)
// 2. Renderizá a MP4 con design-engine/render-video.cjs
// 3. El Publisher lo detecta automáticamente
// ═══════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../../../core/constants/colors.dart';
import '../../../../../core/navigation/adaptive_navigation.dart';
import '../../../../../services/project_monitor.dart';
import '../../domain/animation_template.dart';
import '../../domain/video_renderer.dart';

class AnimationStudioScreen extends StatefulWidget {
  final ProjectMonitor monitor;

  const AnimationStudioScreen({super.key, required this.monitor});

  @override
  State<AnimationStudioScreen> createState() => _AnimationStudioScreenState();
}

class _AnimationStudioScreenState extends State<AnimationStudioScreen> {
  int _selectedIndex = 0;
  bool _isRendering = false;
  bool _isChecking = true;
  bool _rendererReady = false;
  bool _hasHtmlSource = false;
  bool _showAdvanced = false;
  final _durationController = TextEditingController(text: '22');
  final _renderer = VideoRenderer();
  VideoRenderResult? _lastRender;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _initRenderer() async {
    final projectPath = widget.monitor.projectPath;
    if (projectPath == null) return;

    final found = await _renderer.findDesignEngine(projectBase: projectPath);
    final available = found ? await _renderer.checkAvailable() : false;
    final hasHtml = await _checkHtmlSource(projectPath);

    if (mounted) {
      setState(() {
        _rendererReady = available;
        _hasHtmlSource = hasHtml;
        _isChecking = false;
        if (_selectedIndex >= 0 && _selectedIndex < kAnimationTemplates.length) {
          _durationController.text =
              kAnimationTemplates[_selectedIndex].defaultDurationSec.toString();
        }
      });
    }
  }

  Future<bool> _checkHtmlSource(String projectPath) async {
    final sourceDir = Directory(p.join(projectPath, 'erbolamm-studio', 'source')).existsSync()
        ? Directory(p.join(projectPath, 'erbolamm-studio', 'source'))
        : Directory(p.join(projectPath, 'promo', 'source'));
    if (!await sourceDir.exists()) return false;
    final files = await sourceDir.list().toList();
    return files.any((f) => f.path.endsWith('.html'));
  }

  AnimationTemplate get _currentTemplate =>
      _selectedIndex >= 0 && _selectedIndex < kAnimationTemplates.length
          ? kAnimationTemplates[_selectedIndex]
          : kAnimationTemplates[0];

  IconData _iconFor(IconType type) {
    switch (type) {
      case IconType.phone: return Icons.phone_android;
      case IconType.desktop: return Icons.desktop_windows;
      case IconType.camera: return Icons.camera_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasProject = widget.monitor.hasProject;
    final projName = widget.monitor.projectName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎬 Animation Studio'),
        actions: [
          if (_hasHtmlSource)
            IconButton(
              icon: const Icon(Icons.folder_open, size: 20),
              tooltip: 'Source HTML encontrado',
              onPressed: () {},
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
          : _isChecking
              ? const Center(child: CircularProgressIndicator())
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
            decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.movie_creation_outlined, size: 40, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          const Text('Animation Studio', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text('Agregá un proyecto en INBOX/ para usar el Animation Studio.\n'
                'Acá podrás generar animaciones HTML y renderizarlas a video.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildStudio() {
    final template = _currentTemplate;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── System check ──
          if (!_rendererReady)
            Card(
              color: AppColors.warning.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  const Icon(Icons.warning, color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Text(_renderer.lastError ?? 'Node.js + playwright + ffmpeg requeridos',
                      style: const TextStyle(fontSize: 12, color: AppColors.warning)),
                ]),
              ),
            ),
          if (_rendererReady)
            Card(
              color: AppColors.success.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  const Text('Sistema listo — Node.js + Playwright + ffmpeg',
                      style: TextStyle(fontSize: 12, color: AppColors.success)),
                  const Spacer(),
                  if (!_hasHtmlSource)
                    const Text('Sin HTML source',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ]),
              ),
            ),
          const SizedBox(height: 16),

          // ── Templates ──
          const Text('Seleccioná un template', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...kAnimationTemplates.map((t) => _TemplateCard(
                template: t,
                isSelected: kAnimationTemplates.indexOf(t) == _selectedIndex,
                icon: _iconFor(t.iconType),
                onTap: () {
                  setState(() {
                    _selectedIndex = kAnimationTemplates.indexOf(t);
                    _durationController.text = t.defaultDurationSec.toString();
                    _lastRender = null;
                  });
                },
              )),

          const SizedBox(height: 24),

          // ── Avanzado ──
          InkWell(
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
            child: Row(children: [
              Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textMuted, size: 20),
              const SizedBox(width: 4),
              Text('Avanzado', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ]),
          ),
          if (_showAdvanced) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _durationController,
                  decoration: const InputDecoration(labelText: 'Duración (s)', hintText: '22'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('${template.width}×${template.height}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),
            ]),
          ],

          const SizedBox(height: 24),

          // ── Progress ──
          if (_isRendering) ...[
            LinearProgressIndicator(value: _progress > 0 ? _progress : null),
            const SizedBox(height: 8),
            Text(_progressLabel, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
          ],

          // ── Result ──
          if (_lastRender != null) _buildResultCard(),

          // ── Actions ──
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (_isRendering || !_rendererReady) ? null : _renderVideo,
                icon: _isRendering
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.videocam),
                label: Text(_isRendering ? 'Renderizando...' : '🎬 Renderizar'),
              ),
            ),
            if (_lastRender?.success == true) ...[
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.play_arrow, color: AppColors.success),
                tooltip: 'Reproducir',
                onPressed: () => _playVideo(_lastRender!.outputPath),
              ),
              IconButton(
                icon: const Icon(Icons.folder_open),
                tooltip: 'Abrir carpeta',
                onPressed: () => _openFolder(_lastRender!.outputPath),
              ),
            ],
          ]),
        ],
      ),
    );
  }

  String get _progressLabel {
    if (_progress < 0.3) return 'Iniciando render...';
    if (_progress < 0.6) return 'Renderizando video...';
    if (_progress < 1) return 'Procesando con ffmpeg...';
    return '✅ Video listo';
  }

  Widget _buildResultCard() {
    final r = _lastRender!;
    return Card(
      color: r.success ? AppColors.success.withValues(alpha: 0.08) : AppColors.error.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Icon(r.success ? Icons.check_circle : Icons.error,
              color: r.success ? AppColors.success : AppColors.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.success ? 'Video renderizado' : 'Error',
                  style: TextStyle(fontWeight: FontWeight.bold, color: r.success ? AppColors.success : AppColors.error)),
              Text(r.success
                  ? '${_formatSize(r.fileSize)} · ${r.duration.inSeconds}s'
                  : r.error ?? 'Error desconocido',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _renderVideo() async {
    final projectPath = widget.monitor.projectPath;
    if (projectPath == null) return;

    final template = _currentTemplate;
    final duration = int.tryParse(_durationController.text) ?? template.defaultDurationSec;
    final sourceDir = Directory(p.join(projectPath, 'erbolamm-studio', 'source')).existsSync()
        ? p.join(projectPath, 'erbolamm-studio', 'source')
        : p.join(projectPath, 'promo', 'source');
    final htmlPath = p.join(sourceDir, template.file);

    if (!await File(htmlPath).exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ No se encontró ${template.file} en erbolamm-studio/source/')),
      );
      return;
    }

    setState(() {
      _isRendering = true;
      _progress = 0.1;
      _lastRender = null;
    });

    final outputDir = Directory(p.join(projectPath, 'erbolamm-studio', 'videos'));
    await outputDir.create(recursive: true);
    final outputPath = p.join(outputDir.path, '${template.suffix}.mp4');

    setState(() => _progress = 0.3);

    VideoRenderResult result;
    if (_rendererReady) {
      result = await _renderer.render(
        htmlPath: htmlPath,
        template: template,
        durationSec: duration,
        outputPath: outputPath,
      );
    } else {
      result = await _renderer.renderFallback(
        outputPath: outputPath,
        durationSec: duration,
        width: template.width,
        height: template.height,
      );
    }

    setState(() {
      _lastRender = result;
      _isRendering = false;
      _progress = result.success ? 1.0 : 0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success
              ? '✅ Video guardado en erbolamm-studio/videos/'
              : '❌ Error: ${result.error ?? "desconocido"}'),
          backgroundColor: result.success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _playVideo(String path) {
    Process.run('ffplay', ['-nodisp', '-autoexit', path]);
  }

  void _openFolder(String path) {
    Process.run('open', [p.dirname(path)]);
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

class _TemplateCard extends StatelessWidget {
  final AnimationTemplate template;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? AppColors.educacion.withValues(alpha: 0.15) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.educacion.withValues(alpha: 0.2) : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? AppColors.educacion : AppColors.textSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(template.name, style: TextStyle(fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.educacion : AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('${template.description} · ${template.defaultDurationSec}s',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ]),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.educacion, size: 20),
          ]),
        ),
      ),
    );
  }
}
