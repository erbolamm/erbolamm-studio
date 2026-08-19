// ═══════════════════════════════════════════════════════════════
// 📊 Market Research Screen
// ═══════════════════════════════════════════════════════════════
// Analiza el proyecto activo + tendencias del día → genera
// hooks promocionales conectados con la actualidad.
//
// Usa mmx search para tendencias reales y mmx text chat
// para generar hooks con IA. Sin datos mock.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../services/project_monitor.dart';
import '../../../../../core/constants/colors.dart';
import '../../domain/market_research_service.dart';

/// 📊 Market Research — tendencias + hooks promocionales
class MarketResearchScreen extends StatefulWidget {
  final ProjectMonitor monitor;

  const MarketResearchScreen({super.key, required this.monitor});

  @override
  State<MarketResearchScreen> createState() => _MarketResearchScreenState();
}

class _MarketResearchScreenState extends State<MarketResearchScreen> {
  bool _isAnalyzing = false;
  List<Trend> _trends = [];
  List<PromoHook> _hooks = [];
  String? _selectedTrend;

  @override
  Widget build(BuildContext context) {
    final hasProject = widget.monitor.hasProject;
    final projName = widget.monitor.projectName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Market Research'),
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
          const SizedBox(width: 16),
        ],
      ),
      body: hasProject ? _buildResearch() : _buildEmptyState(),
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
              Icons.trending_up,
              size: 40,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Market Research',
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
              'Agregá un proyecto para empezar.\n'
              'Analizamos tendencias y generamos hooks promocionales\n'
              'conectados con la actualidad.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResearch() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Botón de análisis ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _runAnalysis,
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isAnalyzing
                    ? 'Analizando...'
                    : '🔍 Analizar tendencias + generar hooks',
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── Tendencias del día ──
          if (_trends.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tendencias del día',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._trends.map(
              (t) => _TrendCard(
                trend: t,
                isSelected: _selectedTrend == t.title,
                onTap: () => setState(() => _selectedTrend = t.title),
              ),
            ),
          ],

          // ── Hooks promocionales generados ──
          if (_hooks.isNotEmpty) ...[
            const SizedBox(height: 32),
            Row(
              children: [
                const Icon(Icons.lightbulb, color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Hooks promocionales',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Regenerar hooks',
                  onPressed: _runAnalysis,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._hooks.map((h) => _HookCard(hook: h)),
          ],
        ],
      ),
    );
  }

  void _runAnalysis() async {
    setState(() => _isAnalyzing = true);

    try {
      final trends = await MarketResearchService.fetchTrends();
      final projectName = widget.monitor.projectName ?? 'este proyecto';
      final hooks = await MarketResearchService.generateHooks(
        projectName: projectName,
        projectPath: widget.monitor.projectPath ?? '',
        trends: trends,
      );

      if (mounted) {
        setState(() {
          _trends = trends;
          _hooks = hooks;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  // ── Trend card ──
}

class _TrendCard extends StatelessWidget {
  final Trend trend;
  final bool isSelected;
  final VoidCallback onTap;

  const _TrendCard({
    required this.trend,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? AppColors.warning.withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trend.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          trend.source,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.educacion.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            trend.category,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.educacion,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(trend.relevance * 100).toInt()}% match',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text('🎯', style: TextStyle(fontSize: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HookCard extends StatelessWidget {
  final PromoHook hook;

  const _HookCard({required this.hook});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: platform
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Hook para ${hook.platform}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.herramientas.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hook.platform,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.herramientas,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Hook text
            SelectableText(
              hook.hook,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            // Footer: tono + actions
            Row(
              children: [
                Icon(Icons.style, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  hook.tone,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  tooltip: 'Copiar hook',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: hook.hook));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📋 Hook copiado al portapapeles'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 16),
                  tooltip: 'Compartir',
                  onPressed: () {},
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
