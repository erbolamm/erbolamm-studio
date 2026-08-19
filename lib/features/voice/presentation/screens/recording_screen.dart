// ═══════════════════════════════════════════════════════════════
// 🎤 Recording Screen — Grabar muestras de voz para clonar
// ═══════════════════════════════════════════════════════════════
// Usa RecordService + ffmpeg para grabación real con micrófono.
// El usuario lee 5 frases. Cada frase se graba en WAV y se
// usa para clonar su voz con VoiceBox/XTTS.
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../../core/constants/colors.dart';
import '../../../../core/navigation/adaptive_navigation.dart';
import '../../data/record_service.dart';

const List<String> kPhrases = [
  'Hola, soy Javier Mateo, creador de ApliArte.',
  'Este proyecto nació para compartir conocimiento.',
  'La tecnología puede ser bella y accesible.',
  'Cada línea de código cuenta una historia.',
  'Gracias por formar parte de este viaje.',
];

class RecordingScreen extends StatefulWidget {
  final void Function(int recorded, List<String> filePaths) onComplete;

  const RecordingScreen({super.key, required this.onComplete});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with SingleTickerProviderStateMixin {
  final _recordService = RecordService();
  int _currentPhrase = 0;
  int _recorded = 0;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _ffmpegAvailable = true;
  String? _error;
  final List<String> _recordedFiles = [];
  Duration _recordingProgress = Duration.zero;
  Timer? _progressTimer;

  late AnimationController _pulseAnim;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _checkFfmpeg();

    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _pulseAnim, curve: Curves.easeInOut));
  }

  Future<void> _checkFfmpeg() async {
    final available = await _recordService.checkAvailability();
    if (mounted) {
      setState(() => _ffmpegAvailable = available);
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _pulseAnim.dispose();
    _recordService.dispose();
    super.dispose();
  }

  String get _phraseLabel {
    if (_isRecording) return 'Grabando... toca para detener';
    if (_recordedFiles.length > _currentPhrase) {
      return '✅ Grabada — toca para re-grabar';
    }
    return 'Toca para grabar esta frase';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎤 Grabar tu voz'),
        actions: const [SettingsMenuButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Lee estas frases en voz alta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '$_recorded de ${kPhrases.length} grabadas',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (!_ffmpegAvailable)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, color: AppColors.error, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'ffmpeg no encontrado. Instalá ffmpeg para grabar.',
                      style: TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),

            const SizedBox(height: 24),

            // Progreso
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(kPhrases.length, (i) {
                final done = i < _recorded;
                final current = i == _currentPhrase;
                return GestureDetector(
                  onTap: done || current
                      ? null
                      : () => setState(() => _currentPhrase = i),
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: done
                          ? AppColors.success
                          : (current
                                ? (_isRecording
                                      ? AppColors.error
                                      : AppColors.educacion)
                                : AppColors.surfaceLight),
                      borderRadius: BorderRadius.circular(8),
                      border: current && !done && !_isRecording
                          ? Border.all(color: AppColors.educacion, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: done
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            )
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: current
                                    ? Colors.white
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // Frase actual
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      listenable: _pulseScale,
                      builder: (ctx, child) => Transform.scale(
                        scale: _isRecording ? _pulseScale.value : 1.0,
                        child: Icon(
                          _isRecording
                              ? Icons.fiber_manual_record
                              : Icons.record_voice_over,
                          size: 48,
                          color: _isRecording
                              ? AppColors.error
                              : AppColors.educacion,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      kPhrases[_currentPhrase],
                      style: const TextStyle(fontSize: 18, height: 1.5),
                      textAlign: TextAlign.center,
                    ),

                    // Timer durante grabación
                    if (_isRecording) ...[
                      const SizedBox(height: 12),
                      Text(
                        _formatDuration(_recordingProgress),
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          color: AppColors.error,
                        ),
                      ),
                    ],

                    // Preview después de grabar
                    if (_recordedFiles.length > _currentPhrase &&
                        !_isRecording) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.stop : Icons.play_arrow,
                              color: AppColors.educacion,
                            ),
                            onPressed: _previewCurrent,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Escuchar',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Botón grabar
            SizedBox(
              width: 80,
              height: 80,
              child: ElevatedButton(
                onPressed: (!_ffmpegAvailable || _isPlaying)
                    ? null
                    : (_isRecording ? _stopRecording : _startRecording),
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: _isRecording
                      ? AppColors.error
                      : AppColors.educacion,
                  disabledBackgroundColor: AppColors.surfaceLight,
                  padding: EdgeInsets.zero,
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  size: 36,
                  color: _isRecording ? Colors.white : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _phraseLabel,
              style: TextStyle(
                color: _isRecording
                    ? AppColors.error
                    : (_recordedFiles.length > _currentPhrase
                          ? AppColors.success
                          : AppColors.textMuted),
                fontSize: 12,
              ),
            ),

            // Barra de progreso de grabación
            if (_isRecording)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: const AlwaysStoppedAnimation(AppColors.error),
                ),
              ),

            const Spacer(),

            // Acciones
            Row(
              children: [
                if (_currentPhrase > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.replay, size: 18),
                      label: const Text('Anterior'),
                      onPressed: () => setState(() => _currentPhrase--),
                    ),
                  ),
                if (_currentPhrase > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: Icon(
                      _recorded >= kPhrases.length
                          ? Icons.check
                          : Icons.skip_next,
                      size: 18,
                    ),
                    label: Text(
                      _recorded >= kPhrases.length ? 'Finalizar' : 'Saltar',
                    ),
                    onPressed: _recorded >= kPhrases.length
                        ? _finish
                        : () => setState(() {
                            _currentPhrase =
                                (_currentPhrase + 1) % kPhrases.length;
                          }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _error = null;
    });
    _pulseAnim.repeat(reverse: true);
    _startProgressTimer();

    // Generar nombre de archivo basado en la frase
    final recordingsDir = Directory('/tmp/erbolamm_voice_samples');
    await recordingsDir.create(recursive: true);
    final filePath = p.join(
      recordingsDir.path,
      'sample_${_currentPhrase + 1}.wav',
    );

    final started = await _recordService.startRecording(
      outputPath: filePath,
      maxDuration: 15,
    );

    if (!started && mounted) {
      setState(() {
        _isRecording = false;
        _error = _recordService.lastError ?? 'Error al iniciar grabación';
      });
      _pulseAnim.stop();
      _pulseAnim.reset();
      _stopProgressTimer();
    }
  }

  Future<void> _stopRecording() async {
    _pulseAnim.stop();
    _pulseAnim.reset();
    _stopProgressTimer();

    final result = await _recordService.stopRecording();

    if (!mounted) return;

    if (result != null) {
      // Validar que el archivo no esté vacío
      final fileSize = result.fileSize;
      if (fileSize < 1000) {
        // Menos de 1KB = grabación fallida
        setState(() {
          _error = 'Grabación muy corta o sin audio. Probá de nuevo.';
          _isRecording = false;
        });
        return;
      }

      setState(() {
        _isRecording = false;
        _recordedFiles.add(result.filePath);
        _recorded = _recordedFiles.length;

        if (_recorded < kPhrases.length) {
          _currentPhrase = (_currentPhrase + 1) % kPhrases.length;
        }
      });
    } else {
      setState(() {
        _isRecording = false;
        _error = 'Error al guardar la grabación';
      });
    }
  }

  Future<void> _previewCurrent() async {
    if (_currentPhrase >= _recordedFiles.length) return;

    setState(() => _isPlaying = true);
    await _recordService.playAudio(_recordedFiles[_currentPhrase]);
    if (mounted) setState(() => _isPlaying = false);
  }

  void _startProgressTimer() {
    _recordingProgress = Duration.zero;
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() {
          _recordingProgress = _recordService.currentDuration;
        });
      }
    });
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  void _finish() {
    widget.onComplete(_recorded, _recordedFiles);
  }

  String _formatDuration(Duration d) {
    final secs = d.inSeconds;
    final ms = d.inMilliseconds % 1000;
    return '${secs.toString().padLeft(2, '0')}.${(ms ~/ 100).toString()}s';
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => builder(context, null);
}
