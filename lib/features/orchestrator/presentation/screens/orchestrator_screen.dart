// ═══════════════════════════════════════════════════════════════
// 🧠 Orchestrator Screen — Pipeline real con PipelineRunner
// ═══════════════════════════════════════════════════════════════
// UI mejorada: cards expandibles, progreso, tiempos, timeline
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../core/navigation/adaptive_navigation.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../services/project_monitor.dart';
import '../../../../services/ai_providers_service.dart';
import '../../../../core/constants/colors.dart';
import '../../domain/pipeline.dart';
import '../../orchestration/pipeline_runner.dart';
import '../../agents/analyzer_agent.dart';
import '../../agents/classifier_agent.dart';
import '../../agents/auditor_agent.dart';
import '../../agents/marketing_agent.dart';
import '../../agents/registrar_agent.dart';
import '../../agents/cloud_auditor_agent.dart';
import '../../agents/migrator_agent.dart';

class _AgentState {
  final Agent agent;
  bool running = false;
  bool done = false;
  bool failed = false;
  String? result;
  String? error;
  String? duration;
  bool expanded = false;

  _AgentState({required this.agent});
}

class OrchestratorScreen extends StatefulWidget {
  final ProjectMonitor monitor;
  const OrchestratorScreen({super.key, required this.monitor});

  @override
  State<OrchestratorScreen> createState() => _OrchestratorScreenState();
}

class _OrchestratorScreenState extends State<OrchestratorScreen> {
  late List<_AgentState> _agents;
  PipelineRunner? _runner;
  final _classifierAgent = ClassifierAgent();
  double _progress = 0;
  String _statusText = '';
  String _selectedProvider = 'auto';

  @override
  void initState() {
    super.initState();
    _agents = inboxPipeline.map((a) => _AgentState(agent: a)).toList();
    _loadDefaultProvider();
    widget.monitor.addListener(_onMonitorChanged);
  }

  void _onMonitorChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.monitor.removeListener(_onMonitorChanged);
    super.dispose();
  }

  Future<void> _loadDefaultProvider() async {
    final def = await AIProvidersService.instance.getDefaultProvider();
    if (mounted) {
      setState(() {
        _selectedProvider = def;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasProject = widget.monitor.hasProject;
    final projName = widget.monitor.projectName;
    final isRunning = _runner?.isRunning ?? false;
    final isDone = _agents.every((a) => a.done || a.failed);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Orquestador'),
        actions: [
          _buildAISelector(),
          const SizedBox(width: 8),
          if (hasProject) ...[
            if (widget.monitor.availableProjects.length > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _statusColor().withValues(alpha: 0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: widget.monitor.projectName,
                    dropdownColor: AppColors.surfaceLight,
                    style: TextStyle(
                      fontSize: 12,
                      color: _statusColor(),
                      fontWeight: FontWeight.bold,
                    ),
                    icon: Icon(Icons.arrow_drop_down, color: _statusColor(), size: 18),
                    items: widget.monitor.availableProjects.map((p) {
                      return DropdownMenuItem<String>(
                        value: p,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder, size: 14, color: _statusColor()),
                            const SizedBox(width: 6),
                            Text(p),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: isRunning
                        ? null
                        : (val) {
                            if (val != null) {
                              widget.monitor.selectProject(val);
                              setState(() {});
                            }
                          },
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ] else ...[
              Chip(
                avatar: Icon(Icons.folder, size: 16, color: _statusColor()),
                label: Text(projName ?? '', style: const TextStyle(fontSize: 12)),
                backgroundColor: _statusColor().withValues(alpha: 0.1),
              ),
              const SizedBox(width: 8),
            ],
          ],
          const SettingsMenuButton(),
        ],
      ),
      body: hasProject ? _buildBody(isRunning, isDone) : _buildEmptyState(),
    );
  }

  Widget _buildAISelector() {
    final label = _selectedProvider == 'auto'
        ? '🤖 Auto'
        : _selectedProvider == 'deepseek'
        ? '🐋 DeepSeek'
        : _selectedProvider == 'anthropic'
        ? '🤖 Claude'
        : _selectedProvider == 'openai'
        ? '🧠 GPT-4o'
        : _selectedProvider == 'gemini'
        ? '✨ Gemini'
        : _selectedProvider == 'groq'
        ? '⚡ Groq'
        : _selectedProvider == 'nvidia_nim'
        ? '🟢 NVIDIA'
        : '🌐 ${_selectedProvider.toUpperCase()}';

    return PopupMenuButton<String>(
      tooltip: 'Seleccionar motor de IA para la ejecución',
      initialValue: _selectedProvider,
      onSelected: (val) {
        setState(() {
          _selectedProvider = val;
        });
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'auto',
          child: Row(
            children: [
              Text('🤖', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text('Auto (Fallback Cascada)'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        ...AIProvidersService.providers.map(
          (p) => PopupMenuItem(
            value: p.id,
            child: Row(
              children: [
                Text(p.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(p.name),
              ],
            ),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.ia.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.ia.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.ia,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.ia),
          ],
        ),
      ),
    );
  }

  Color _statusColor() {
    if (_agents.any((a) => a.failed)) return AppColors.error;
    if (_agents.any((a) => a.running)) return AppColors.info;
    if (_agents.every((a) => a.done)) return AppColors.success;
    return AppColors.textMuted;
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
              Icons.account_tree_outlined,
              size: 40,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Orquestador',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Agrega un proyecto en INBOX/ para usar el orquestador.\n'
              'Los ${inboxPipeline.length} agentes activos analizarán, '
              'clasificarán y procesarán el proyecto.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isRunning, bool isDone) {
    final doneCount = _agents.where((a) => a.done || a.failed).length;
    _progress = _agents.isEmpty ? 0 : doneCount / _agents.length;

    return Column(
      children: [
        // ── Progress header ──
        if (isRunning || _progress > 0)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            color: AppColors.surface,
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      _statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(doneCount)}/${_agents.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 4,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(
                      _agents.any((a) => a.failed)
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

        // ── Agent cards ──
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            itemCount: _agents.length,
            itemBuilder: (_, i) => _buildAgentCard(i),
          ),
        ),

        // ── Bottom bar ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                if (isDone && !isRunning) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showResults,
                      icon: const Icon(Icons.folder_open, size: 18),
                      label: const Text('📂 Resultados'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cultura,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetPipeline,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reiniciar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: isDone ? 2 : 1,
                  child: ElevatedButton.icon(
                    onPressed: isRunning ? _cancel : _startPipeline,
                    icon: Icon(
                      isRunning ? Icons.stop : Icons.play_arrow,
                      size: 18,
                    ),
                    label: Text(
                      isRunning
                          ? 'Detener'
                          : isDone
                          ? '▶ Ejecutar de nuevo'
                          : '▶ Ejecutar Pipeline',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRunning ? AppColors.error : null,
                      foregroundColor: isRunning ? Colors.white : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgentCard(int index) {
    final state = _agents[index];
    final agent = state.agent;
    final isLast = index == _agents.length - 1;

    Color statusColor;
    IconData statusIcon;
    if (state.running) {
      statusColor = AppColors.info;
      statusIcon = Icons.hourglass_top;
    } else if (state.done) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle;
    } else if (state.failed) {
      statusColor = AppColors.error;
      statusIcon = Icons.error;
    } else {
      statusColor = AppColors.textMuted;
      statusIcon = Icons.circle_outlined;
    }

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 2),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => state.expanded = !state.expanded),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  // ── Main row ──
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      state.expanded ? 8 : 14,
                    ),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              agent.icon,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${index + 1}. ${agent.name}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.textMuted.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      agent.inboxStep,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                  if (state.duration != null) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      state.duration!,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                agent.description,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Status + expand arrow
                        Column(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 22),
                            if (state.result != null) ...[
                              const SizedBox(height: 2),
                              Icon(
                                state.expanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Expanded detail ──
                  if (state.expanded &&
                      (state.result != null || state.error != null))
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (state.result != null) ...[
                            const Text(
                              'Resultado:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                state.result!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: state.failed
                                      ? AppColors.error
                                      : AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                          if (state.error != null) ...[
                            if (state.result != null) const SizedBox(height: 8),
                            const Text(
                              'Error:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                state.error!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.error,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // ── Connector line between cards ──
        if (!isLast)
          SizedBox(
            width: 24,
            height: 20,
            child: CustomPaint(
              painter: _ConnectorPainter(
                color: state.done ? AppColors.success : AppColors.border,
              ),
            ),
          ),
      ],
    );
  }

  // ─── Results display ──────────────────────────────────────

  void _showResults() {
    final projectPath = widget.monitor.projectPath;
    if (projectPath == null) return;

    final promoDir = Directory('$projectPath/promo');
    final files = <String>[];
    if (promoDir.existsSync()) {
      for (final e in promoDir.listSync(recursive: true)) {
        if (e is File) {
          files.add(e.path.replaceFirst('$projectPath/', ''));
        }
      }
    }

    final hasLanding = File('$projectPath/landing.html').existsSync();
    final narraciones = files
        .where((f) => f.contains('narration/') && f.endsWith('.wav'))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📂 Resultados del pipeline'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasLanding)
                  ListTile(
                    leading: const Icon(
                      Icons.language,
                      color: AppColors.cultura,
                    ),
                    title: const Text('🌐 Abrir landing'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Process.run('open', ['$projectPath/landing.html']);
                    },
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.folder,
                    color: AppColors.herramientas,
                  ),
                  title: const Text('📂 Abrir carpeta promo'),
                  subtitle: Text('${files.length} archivos generados'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Process.run('open', ['$projectPath/promo']);
                  },
                ),
                if (narraciones.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.play_circle, color: AppColors.ia),
                    title: Text(
                      '🎤 Narración ES (${narraciones.length} idiomas)',
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      final es = narraciones.firstWhere(
                        (f) => f.contains('/es/'),
                        orElse: () => narraciones.first,
                      );
                      Process.run('ffplay', [
                        '-nodisp',
                        '-autoexit',
                        '$projectPath/$es',
                      ]);
                    },
                  ),
                const Divider(),
                ...files
                    .take(15)
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          f,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                if (files.length > 15)
                  Text(
                    '... y ${files.length - 15} archivos más',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // ─── Pipeline execution ────────────────────────────────────

  void _startPipeline() async {
    final projectPath = widget.monitor.projectPath;
    if (projectPath == null) return;

    setState(() {
      for (final a in _agents) {
        a.running = false;
        a.done = false;
        a.failed = false;
        a.result = null;
        a.error = null;
        a.duration = null;
        a.expanded = false;
      }
      _statusText = 'Iniciando pipeline...';
    });

    final decided = await _showClassifierDialog();
    if (!decided || !mounted) return;

    setState(() => _statusText = 'Ejecutando agentes...');

    _runner = PipelineRunner.withAgents(
      projectPath: projectPath,
      agents: [
        AnalyzerAgent(),
        _classifierAgent,
        AuditorAgent(),
        MarketingAgent(),
        RegistrarAgent(),
        if (FeatureFlags.cloudEnabled) ...[
          CloudAuditorAgent(),
          MigratorAgent(),
        ],
      ],
    );

    final timers = <String, Stopwatch>{};

    _runner!.setCallbacks(
      onStart: (id) {
        if (!mounted) return;
        timers[id] = Stopwatch()..start();
        setState(() {
          final idx = _agents.indexWhere((a) => a.agent.id == id);
          if (idx >= 0) _agents[idx].running = true;
          _statusText = '▶ ${_agents[idx].agent.name}...';
        });
      },
      onDone: (id, success, summary, error) {
        if (!mounted) return;
        final elapsed = timers[id]?.elapsed;
        timers.remove(id);
        setState(() {
          final idx = _agents.indexWhere((a) => a.agent.id == id);
          if (idx >= 0) {
            _agents[idx].running = false;
            _agents[idx].done = success;
            _agents[idx].failed = !success;
            _agents[idx].result = summary;
            _agents[idx].error = error;
            _agents[idx].duration = elapsed != null
                ? '${elapsed.inSeconds}s'
                : null;
          }
        });
      },
    );

    final result = await _runner!.runAll();
    if (!mounted) return;

    setState(() {
      _statusText = result.allSucceeded
          ? '✅ Completo en ${result.totalDuration.inSeconds}s'
          : '⚠️ Completado con errores';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              result.allSucceeded ? Icons.check_circle : Icons.warning,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              result.allSucceeded
                  ? 'Pipeline completado en ${result.totalDuration.inSeconds}s'
                  : 'Pipeline con errores — revisá cada agente',
            ),
          ],
        ),
        backgroundColor: result.allSucceeded
            ? AppColors.success
            : AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _cancel() {
    _runner?.cancel();
    setState(() {
      for (final a in _agents) {
        if (a.running) {
          a.running = false;
          a.failed = true;
          a.error = 'Cancelado';
        }
      }
      _statusText = '⛔ Cancelado';
    });
  }

  void _resetPipeline() {
    setState(() {
      for (final a in _agents) {
        a.running = false;
        a.done = false;
        a.failed = false;
        a.result = null;
        a.error = null;
        a.duration = null;
        a.expanded = false;
      }
      _progress = 0;
      _statusText = '';
    });
  }

  Future<bool> _showClassifierDialog() async {
    final completer = Completer<bool>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ClassifierDialog(
        onDecision: (decision, mergeTarget, salvageTarget, notes) {
          _classifierAgent.setDecision(
            decision: decision,
            mergeTarget: mergeTarget,
            salvageTarget: salvageTarget,
            notes: notes,
          );
          setState(() {
            final idx = _agents.indexWhere((a) => a.agent.id == 'classifier');
            if (idx >= 0) {
              _agents[idx].done = true;
              _agents[idx].result = 'Decisión: ${decision.name}';
            }
          });
          Navigator.pop(ctx);
          completer.complete(true);
        },
      ),
    );
    return completer.future;
  }
}

// ─── Connector line painter ──────────────────────────────────

class _ConnectorPainter extends CustomPainter {
  final Color color;
  _ConnectorPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width / 2, size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) => old.color != color;
}

// ─── Classifier Dialog ──────────────────────────────────────

class _ClassifierDialog extends StatefulWidget {
  final void Function(ProjectDecision, String?, String?, String?) onDecision;
  const _ClassifierDialog({required this.onDecision});

  @override
  State<_ClassifierDialog> createState() => _ClassifierDialogState();
}

class _ClassifierDialogState extends State<_ClassifierDialog> {
  ProjectDecision? _selected;
  final _mergeCtl = TextEditingController();
  final _salvageCtl = TextEditingController();
  final _notesCtl = TextEditingController();

  @override
  void dispose() {
    _mergeCtl.dispose();
    _salvageCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Text('🏷️ ', style: TextStyle(fontSize: 28)),
          SizedBox(width: 8),
          Text('¿Qué hacemos con este proyecto?'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paso 2 de INBOX.md — Elegí una opción:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ..._opt(
              '📤 Publicar',
              ProjectDecision.publish,
              'Generar assets y registrar en el ecosistema',
            ),
            ..._opt(
              '🔗 Fusionar',
              ProjectDecision.merge,
              'Fusionar con otro proyecto existente',
            ),
            ..._opt(
              '🔧 Aprovechar partes',
              ProjectDecision.salvage,
              'Extraer código útil para otro proyecto',
            ),
            ..._opt(
              '🗑️ Descartar',
              ProjectDecision.discard,
              'Confirmar que no sigue y archivar',
            ),
            ..._opt(
              '🔨 Continuar desarrollo',
              ProjectDecision.continue_,
              'Seguir trabajando, ayudar a terminarlo',
            ),
            if (_selected == ProjectDecision.merge) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _mergeCtl,
                decoration: const InputDecoration(
                  labelText: '¿Con qué proyecto fusionar?',
                ),
              ),
            ],
            if (_selected == ProjectDecision.salvage) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _salvageCtl,
                decoration: const InputDecoration(
                  labelText: '¿Para qué proyecto?',
                ),
              ),
            ],
            if (_selected != null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _selected == null
              ? null
              : () => widget.onDecision(
                  _selected!,
                  _selected == ProjectDecision.merge ? _mergeCtl.text : null,
                  _selected == ProjectDecision.salvage
                      ? _salvageCtl.text
                      : null,
                  _notesCtl.text.isNotEmpty ? _notesCtl.text : null,
                ),
          child: const Text('Confirmar decisión'),
        ),
      ],
    );
  }

  List<Widget> _opt(String label, ProjectDecision value, String desc) => [
    InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _selected = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _selected == value
              ? AppColors.educacion.withValues(alpha: 0.15)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              _selected == value
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 20,
              color: _selected == value
                  ? AppColors.educacion
                  : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 4),
  ];
}
