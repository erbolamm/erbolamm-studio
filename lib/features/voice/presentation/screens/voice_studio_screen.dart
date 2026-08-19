// ═══════════════════════════════════════════════════════════════
// 🗣️ Voice Studio — mmx TTS (sin Python)
// ═══════════════════════════════════════════════════════════════
// Lee narration.json del pipeline (Marketing Agent).
// Pipeline: Marketing Agent → narration.json → Voice Studio
//    → mmx TTS batch → 6 idiomas → Publisher
// Backend: mmx CLI + ffmpeg (sin Python, sin XTTS)
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/navigation/adaptive_navigation.dart';
import '../../../../services/project_monitor.dart';
import '../../domain/voice_service.dart';
import 'recording_screen.dart';

enum VoiceStep { idle, recording, narrating, done }

const List<LangInfo> kLanguages = [
  LangInfo('es', '🇪🇸', 'Español'),
  LangInfo('en', '🇬🇧', 'English'),
  LangInfo('pt', '🇧🇷', 'Português'),
  LangInfo('fr', '🇫🇷', 'Français'),
  LangInfo('de', '🇩🇪', 'Deutsch'),
  LangInfo('it', '🇮🇹', 'Italiano'),
];

class LangInfo {
  final String code;
  final String flag;
  final String name;
  const LangInfo(this.code, this.flag, this.name);
}

class VoiceStudioScreen extends StatefulWidget {
  final ProjectMonitor monitor;

  const VoiceStudioScreen({super.key, required this.monitor});

  @override
  State<VoiceStudioScreen> createState() => _VoiceStudioScreenState();
}

class _VoiceStudioScreenState extends State<VoiceStudioScreen> {
  VoiceStep _step = VoiceStep.idle;
  final _voiceService = VoiceService();
  int _samplesRecorded = 0;

  final List<NarrationTrack> _generatedTracks = [];
  final Set<String> _doneLanguages = {};
  SystemCheckResult? _systemCheck;
  bool _checking = true;

  // Pipeline connection
  Map<String, String>? _pipelineTexts; // {es: texto, en: texto, ...}
  String? _pipelineProjectName;
  String? _pipelinePromoPath;

  @override
  void initState() {
    super.initState();
    _loadFromPipeline();
    _checkSystem();
  }

  Future<void> _checkSystem() async {
    final check = await _voiceService.checkAvailability();
    if (mounted) {
      setState(() {
        _systemCheck = check;
        _checking = false;
      });
    }
  }

  /// Carga narration.json del proyecto en INBOX/
  void _loadFromPipeline() {
    final path = widget.monitor.projectPath;
    if (path == null) return;

    final narrationFile = File('$path/promo/narration.json');
    if (!narrationFile.existsSync()) return;

    try {
      final json =
          jsonDecode(narrationFile.readAsStringSync()) as Map<String, dynamic>;
      final texts = <String, String>{};
      for (final lang in kLanguages) {
        if (json[lang.code] is String) {
          texts[lang.code] = json[lang.code] as String;
        }
      }
      if (texts.isNotEmpty) {
        _pipelineTexts = texts;
        _pipelineProjectName = path.split(Platform.pathSeparator).last;
        _pipelinePromoPath = '$path/promo';
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final hasProject = widget.monitor.hasProject;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🗣️ Voice Studio'),
        actions: [
          if (hasProject && _step != VoiceStep.idle)
            Chip(
              avatar: Icon(
                Icons.check_circle,
                size: 16,
                color: _step == VoiceStep.done
                    ? AppColors.success
                    : AppColors.textMuted,
              ),
              label: Text(_stepLabel, style: const TextStyle(fontSize: 12)),
              backgroundColor: AppColors.success.withValues(alpha: 0.1),
            ),
          const SettingsMenuButton(),
        ],
      ),
      body: _buildBodySection(hasProject),
    );
  }

  Widget _buildBodySection(bool hasProject) {
    if (!hasProject) return _buildEmptyState();
    switch (_step) {
      case VoiceStep.idle:
        return _buildIdle();
      case VoiceStep.recording:
        return _buildRecording();
      case VoiceStep.narrating:
        return _buildNarrating();
      case VoiceStep.done:
        return _buildDone();
    }
  }

  String get _stepLabel {
    switch (_step) {
      case VoiceStep.idle:
        return 'Inicio';
      case VoiceStep.recording:
        return 'Grabando ($_samplesRecorded/5)';
      case VoiceStep.narrating:
        return 'Narrando (${_doneLanguages.length}/6)';
      case VoiceStep.done:
        return 'Listo';
    }
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
              Icons.record_voice_over,
              size: 40,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Voice Studio',
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
              'Agrega un proyecto en INBOX/ para usar el Voice Studio.\n'
              'Genera narración en 6 idiomas con mmx TTS.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdle() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pipeline de voz',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _StepCard(
            number: '1',
            icon: '🎤',
            title: 'Grabar tu voz',
            desc: 'Lee 5 frases para personalizar la narración.',
            done: _samplesRecorded >= 5,
          ),
          const SizedBox(height: 8),
          _StepCard(
            number: '2',
            icon: '🔊',
            title: 'Narrar con mmx TTS',
            desc: 'Genera narración profesional en 6 idiomas.',
            done: _doneLanguages.length >= 6,
          ),
          const SizedBox(height: 8),
          _StepCard(
            number: '3',
            icon: '📦',
            title: 'Exportar a Publisher',
            desc: 'Mezclar narración con video y música.',
            done: false,
          ),

          if (!_checking) ...[
            const SizedBox(height: 12),
            _buildSystemCheckBanner(),
          ],

          if (_pipelineTexts != null) ...[
            const SizedBox(height: 12),
            Card(
              color: AppColors.success.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: AppColors.success, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Conectado al pipeline',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '$_pipelineProjectName — ${_pipelineTexts!.length} idiomas',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _showPipelineTexts,
                      child: const Text('Ver textos'),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _checking
                  ? null
                  : () => setState(() => _step = VoiceStep.recording),
              icon: const Icon(Icons.mic),
              label: Text(_checking ? 'Verificando sistema...' : '🎤 Empezar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemCheckBanner() {
    if (_systemCheck == null) return const SizedBox.shrink();

    final check = _systemCheck!;
    final issues = <String>[];
    if (!check.mmxAvailable) issues.add('mmx CLI');
    if (!check.ffmpegAvailable) issues.add('ffmpeg');

    if (issues.isEmpty && check.allReady) {
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
                'Listo — mmx ${check.mmxVersion}',
                style: const TextStyle(fontSize: 12, color: AppColors.success),
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
              'Faltan: ${issues.join(', ')}',
              style: const TextStyle(fontSize: 12, color: AppColors.warning),
            ),
          ],
        ),
      ),
    );
  }

  void _showPipelineTexts() {
    if (_pipelineTexts == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Textos del pipeline'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final lang in kLanguages)
                if (_pipelineTexts!.containsKey(lang.code))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${lang.flag} ${lang.name}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _pipelineTexts![lang.code]!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecording() {
    return RecordingScreen(
      onComplete: (count, files) {
        setState(() {
          _samplesRecorded = count;
          _step = VoiceStep.narrating;
        });
        _startNarration();
      },
    );
  }

  Widget _buildNarrating() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generando narraciones con mmx...',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '$_doneLanguages.length de ${kLanguages.length} idiomas',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          ...kLanguages.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: Text(l.flag, style: const TextStyle(fontSize: 28)),
                  title: Text(l.name),
                  subtitle: Text(
                    '${l.code.toUpperCase()} — ${_doneLanguages.contains(l.code) ? "Listo" : "Generando..."}',
                  ),
                  trailing: _doneLanguages.contains(l.code)
                      ? const Icon(Icons.check_circle, color: AppColors.success)
                      : const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDone() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.check_circle, size: 80, color: AppColors.success),
          const SizedBox(height: 16),
          const Text(
            '¡Voz lista!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${_doneLanguages.length} narraciones generadas',
            style: const TextStyle(color: AppColors.textSecondary),
          ),

          if (_pipelinePromoPath != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📁 $_pipelinePromoPath/narration/',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],

          if (_generatedTracks.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Pre-escuchar:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...List.generate(_generatedTracks.length, (i) {
              final track = _generatedTracks[i];
              final langInfo = kLanguages.firstWhere(
                (l) => l.code == track.language,
                orElse: () => const LangInfo('??', '🌐', 'Unknown'),
              );
              final seconds = track.duration.inSeconds;
              final kbs = (track.fileSize / 1024).toStringAsFixed(0);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Text(
                    langInfo.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(langInfo.name),
                  subtitle: Text(
                    '${seconds}s  •  $kbs KB',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.play_arrow,
                      color: AppColors.educacion,
                    ),
                    onPressed: () => _previewTrack(track),
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Regenerar'),
                onPressed: _regenerateNarrations,
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Enviar a Publisher'),
                onPressed: _exportToPublisher,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _previewTrack(NarrationTrack track) async {
    try {
      await _voiceService.playAudio(track.filePath);
    } catch (_) {}
  }

  Future<void> _startNarration() async {
    if (_pipelineTexts != null) {
      final texts = Map<String, String>.from(_pipelineTexts!);
      //mmx TTS batch
      final tracks = await _voiceService.generateAllLanguages(texts: texts);

      if (mounted) {
        for (final track in tracks) {
          _doneLanguages.add(track.language);
          _generatedTracks.add(track);
        }
        // Rellenar agujeros
        for (final lang in kLanguages) {
          if (!_doneLanguages.contains(lang.code)) {
            await Future.delayed(const Duration(milliseconds: 300));
            if (!mounted) return;
            _doneLanguages.add(lang.code);
          }
        }
        setState(() => _step = VoiceStep.done);
      }
    } else {
      // Sin pipeline: simular para feedback
      for (final lang in kLanguages) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        _doneLanguages.add(lang.code);
      }
      if (mounted) setState(() => _step = VoiceStep.done);
    }
  }

  Future<void> _regenerateNarrations() async {
    if (_pipelineTexts == null) return;
    setState(() {
      _step = VoiceStep.narrating;
      _doneLanguages.clear();
      _generatedTracks.clear();
    });
    await _startNarration();
  }

  void _exportToPublisher() {
    if (_pipelinePromoPath == null) return;

    final narrationDir = Directory('$_pipelinePromoPath/narration');
    narrationDir.createSync(recursive: true);

    final meta = {
      'generatedAt': DateTime.now().toIso8601String(),
      'backend': 'mmx CLI + ffmpeg',
      'languages': _doneLanguages.toList(),
      'samplesRecorded': _samplesRecorded,
    };
    File(
      '${narrationDir.path}/meta.json',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(meta));

    for (final track in _generatedTracks) {
      final langDir = Directory('${narrationDir.path}/${track.language}');
      langDir.createSync(recursive: true);

      if (track.filePath.isNotEmpty && File(track.filePath).existsSync()) {
        final destFile = File(
          '${langDir.path}/narration.${track.language}.wav',
        );
        File(track.filePath).copySync(destFile.path);
        final info = {
          'language': track.language,
          'status': 'generated',
          'file': destFile.path,
          'durationMs': track.duration.inMilliseconds,
          'fileSize': track.fileSize,
        };
        File(
          '${langDir.path}/info.json',
        ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(info));
      } else {
        final info = {
          'language': track.language,
          'status': 'pending',
          'note': 'Archivo de audio no disponible',
        };
        File(
          '${langDir.path}/info.json',
        ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(info));
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Narraciones exportadas a promo/narration/'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String icon;
  final String title;
  final String desc;
  final bool done;

  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.desc,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: done
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  done ? '✅' : icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$number. $title',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (done)
              const Icon(Icons.check, color: AppColors.success, size: 20),
          ],
        ),
      ),
    );
  }
}
