// ═══════════════════════════════════════════════════════════════
// 📦 Publisher Screen — Pipeline real con ffmpeg
// ═══════════════════════════════════════════════════════════════
// 1. Lee assets del proyecto (video, música, narración)
// 2. Mezcla con ffmpeg
// 3. Exporta a 6 plataformas (TikTok, YouTube, IG, FB, Twitch, X)
// 4. Integra narración desde Voice Studio
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../../../core/constants/colors.dart';
import '../../../../../core/navigation/adaptive_navigation.dart';
import '../../../../../services/project_monitor.dart';
import '../../domain/media_mixer.dart';
import '../../domain/publisher_service.dart';
import '../widgets/store_metadata_auditor_widget.dart';

class PublisherScreen extends StatefulWidget {
  final ProjectMonitor monitor;

  const PublisherScreen({super.key, required this.monitor});

  @override
  State<PublisherScreen> createState() => _PublisherScreenState();
}

class _PublisherScreenState extends State<PublisherScreen> {
  late final PublisherService _service;
  bool _initialized = false;
  bool _ffmpegAvailable = false;
  Map<String, String?> _assetPaths = {};
  bool _isExporting = false;
  bool _pipelineDone = false;
  double _progress = 0;
  String _progressLabel = '';
  List<ExportResult> _exportResults = [];
  bool _showNarration = false;
  List<String> _availableLangs = [];

  @override
  void initState() {
    super.initState();
    _initService();
    widget.monitor.addListener(_onMonitorChanged);
  }

  void _onMonitorChanged() {
    if (mounted) {
      _initService();
    }
  }

  @override
  void dispose() {
    widget.monitor.removeListener(_onMonitorChanged);
    super.dispose();
  }

  Future<void> _initService() async {
    final path = widget.monitor.projectPath;
    if (path == null) return;

    _service = PublisherService(projectPath: path);
    _service.onStepChanged = (step) {
      if (mounted) setState(() {});
    };
    _service.onProgress = (p) {
      if (mounted) setState(() => _progress = p);
    };
    _service.onExportComplete = (result) {
      if (mounted) {
        setState(() => _exportResults.add(result));
      }
    };

    final ffmpegOk = await _service.checkAvailable();
    await _service.checkAssets();
    final paths = await _service.findAssetPaths();
    final langs = await _service.getAvailableLanguages();

    if (mounted) {
      setState(() {
        _ffmpegAvailable = ffmpegOk;
        _assetPaths = paths;
        _availableLangs = langs;
        _showNarration = _assetPaths['narration'] != null;
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasProject = widget.monitor.hasProject;
    final projName = widget.monitor.projectName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📦 Publisher'),
        actions: [
          if (hasProject)
            Chip(
              avatar: const Icon(
                Icons.check_circle,
                size: 16,
                color: AppColors.success,
              ),
              label: Text(projName ?? '', style: const TextStyle(fontSize: 12)),
              backgroundColor: AppColors.success.withValues(alpha: 0.1),
            ),
          const SettingsMenuButton(),
        ],
      ),
      body: !hasProject
          ? _buildEmptyState()
          : !_initialized
          ? const Center(child: CircularProgressIndicator())
          : _buildPublisher(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.publish_outlined,
              size: 40,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Publisher',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Agregá un proyecto en INBOX/ para usar el Publisher.\n'
              'Acá podrás mezclar video + música + narración y exportar para redes sociales.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublisher() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Assets status ──
          _buildAssetsBanner(),
          const SizedBox(height: 16),

          // ── Store Metadata & Release Notes Auditor ──
          StoreMetadataAuditorWidget(monitor: widget.monitor),
          const SizedBox(height: 20),

          // ── Pipeline steps ──
          const Text(
            'Pipeline de publicación',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          ..._service.steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildStepCard(step),
            ),
          ),

          const SizedBox(height: 16),

          // ── Progress bar ──
          if (_isExporting || _pipelineDone) ...[
            LinearProgressIndicator(value: _pipelineDone ? 1 : _progress),
            const SizedBox(height: 8),
            Text(
              _progressLabel,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
          ],

          // ── Narration toggle ──
          if (_showNarration) ...[
            Card(
              child: SwitchListTile(
                title: const Text(
                  'Incluir narración',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${_availableLangs.length} idiomas disponibles',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                value: _showNarration,
                onChanged: (v) => setState(() => _showNarration = v),
                secondary: const Icon(Icons.record_voice_over),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Export button ──
          if (_assetPaths['video'] != null && _assetPaths['audio'] != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _runPipeline,
                icon: _isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_pipelineDone ? Icons.refresh : Icons.play_arrow),
                label: Text(
                  _isExporting
                      ? 'Procesando...'
                      : _pipelineDone
                      ? 'Re-generar'
                      : '▶ Ejecutar pipeline',
                ),
              ),
            ),

          // ── Platform exports ──
          if (_pipelineDone && _exportResults.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Exportaciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...kPlatformFormats.map((fmt) => _buildExportCard(fmt)),
          ],
        ],
      ),
    );
  }

  Widget _buildAssetsBanner() {
    final missing = <String>[];
    if (_assetPaths['video'] == null) missing.add('video');
    if (_assetPaths['audio'] == null) missing.add('música');
    if (!_ffmpegAvailable) missing.add('ffmpeg');

    if (missing.isEmpty) {
      return Card(
        color: AppColors.success.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Assets listos — ${_showNarration ? "con narración" : "solo música"}',
                style: const TextStyle(fontSize: 12, color: AppColors.success),
              ),
              const Spacer(),
              Text(
                '${_availableLangs.length} idiomas',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: AppColors.warning.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.warning, color: AppColors.warning, size: 18),
            const SizedBox(width: 8),
            Text(
              'Falta: ${missing.join(", ")}',
              style: const TextStyle(fontSize: 12, color: AppColors.warning),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(PipelineStep step) {
    final isActive = step.status == PipelineStepStatus.running;
    final isDone = step.status == PipelineStepStatus.done;
    final isFailed = step.status == PipelineStepStatus.failed;

    IconData icon;
    Color color;
    if (isDone) {
      icon = Icons.check_circle;
      color = AppColors.success;
    } else if (isFailed) {
      icon = Icons.error;
      color = AppColors.error;
    } else if (isActive) {
      icon = Icons.hourglass_top;
      color = AppColors.educacion;
    } else {
      icon = Icons.circle_outlined;
      color = AppColors.textMuted;
    }

    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDone
                ? AppColors.success.withValues(alpha: 0.15)
                : isActive
                ? AppColors.educacion.withValues(alpha: 0.15)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: isActive
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, color: color, size: 20),
        ),
        title: Text(
          step.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDone ? AppColors.success : null,
          ),
        ),
        subtitle: Text(
          step.error ?? step.subtitle,
          style: TextStyle(
            color: isFailed ? AppColors.error : AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        trailing: step.duration != null
            ? Text(
                '${step.duration!.inSeconds}s',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildExportCard(PlatformFormat format) {
    final result = _exportResults
        .where((r) => r.platform == format.name)
        .firstOrNull;
    final icon = _platformIcon(format.iconType);

    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
        title: Text(
          format.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          result != null
              ? (result.success
                    ? '✅ ${_formatSize(result.fileSize)}'
                    : '❌ Error')
              : '${format.resolution} — pendiente',
          style: TextStyle(
            color: result?.success == true
                ? AppColors.success
                : AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        trailing: result?.success == true
            ? IconButton(
                icon: const Icon(Icons.folder_open, size: 20),
                onPressed: () => _openFile(result!.filePath),
              )
            : null,
      ),
    );
  }

  IconData _platformIcon(IconType type) {
    switch (type) {
      case IconType.phone:
        return Icons.smartphone;
      case IconType.videocam:
        return Icons.videocam;
      case IconType.photo:
        return Icons.camera_alt;
      case IconType.thumbsUp:
        return Icons.thumb_up_alt_outlined;
      case IconType.live:
        return Icons.live_tv;
      case IconType.x:
        return Icons.alternate_email;
    }
  }

  Future<void> _runPipeline() async {
    setState(() {
      _isExporting = true;
      _pipelineDone = false;
      _progress = 0;
      _exportResults = [];
      _progressLabel = 'Iniciando...';
    });

    final video = _assetPaths['video'];
    final audio = _assetPaths['audio'];
    final narration = _showNarration ? _assetPaths['narration'] : null;

    if (video == null || audio == null) {
      setState(() {
        _isExporting = false;
        _progressLabel = 'Faltan assets de video o audio';
      });
      return;
    }

    // Pipeline
    _progressLabel = 'Mezclando audio + video...';
    final pipelineOk = await _service.runPipeline(
      videoPath: video,
      audioPath: audio,
      narrationPath: narration,
    );

    if (!pipelineOk || !mounted) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _progressLabel = 'Error en la mezcla';
        });
      }
      return;
    }

    // Exportar
    _progressLabel = 'Exportando a plataformas...';
    await _service.exportAllPlatforms(
      mixedVideoPath: p.join(
        widget.monitor.projectPath!,
        'promo',
        'render',
        'mixed.mp4',
      ),
      audioPath: audio,
      narrationPath: narration,
    );

    if (mounted) {
      setState(() {
        _isExporting = false;
        _pipelineDone = true;
        _progress = 1;
        _progressLabel = '✅ Pipeline completado';
      });
    }
  }

  void _openFile(String path) {
    Process.run('open', [p.dirname(path)]);
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
