import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../services/project_registry_service.dart';
import '../../../../models/project_record.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<ProjectRecord> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await ProjectRegistryService.instance.getAllProjects();
      if (mounted) {
        setState(() {
          _projects = projects;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Proyectos')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
          ? _buildEmptyState()
          : _buildProjectsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay proyectos',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Analizá un repo en el Analizador',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final p = _projects[index];
        final coveragePct = (p.coverageScore * 100).toInt();
        final coverageColor = coveragePct >= 80
            ? AppColors.cultura
            : coveragePct >= 50
            ? AppColors.herramientas
            : AppColors.creacion;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showDetail(p),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.educacion.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.folder,
                          color: AppColors.educacion,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${p.owner}/${p.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p.type.label,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: coverageColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$coveragePct%',
                          style: TextStyle(
                            color: coverageColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (p.description != null && p.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      p.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildMiniBadge(
                        p.hasReadme ? '📄 README' : null,
                        p.hasReadme,
                      ),
                      const SizedBox(width: 6),
                      _buildMiniBadge(
                        p.hasLicense ? '📜 LICENSE' : null,
                        p.hasLicense,
                      ),
                      const SizedBox(width: 6),
                      _buildMiniBadge(
                        p.hasLanding ? '🌐 Landing' : null,
                        p.hasLanding,
                      ),
                      const Spacer(),
                      if (p.lastAnalyzedAt != null)
                        Text(
                          _formatDate(p.lastAnalyzedAt!),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniBadge(String? label, bool active) {
    if (label == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? AppColors.cultura.withValues(alpha: 0.1)
            : AppColors.textMuted.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: active ? AppColors.cultura : AppColors.textMuted,
        ),
      ),
    );
  }

  void _showDetail(ProjectRecord p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          p.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('ID', p.id),
              _detailRow('Owner', p.owner),
              _detailRow('URL', p.url),
              _detailRow('Tipo', p.type.label),
              _detailRow('Stack', p.techStack.label),
              if (p.language != null) _detailRow('Lenguaje', p.language!),
              const Divider(),
              _detailRow('README', p.hasReadme ? '✅' : '❌'),
              _detailRow('LICENSE', p.hasLicense ? '✅' : '❌'),
              _detailRow('Landing', p.hasLanding ? '✅' : '❌'),
              _detailRow('Screenshots', p.hasScreenshots ? '✅' : '❌'),
              _detailRow('Video', p.hasVideo ? '✅' : '❌'),
              _detailRow('Brand Spec', p.hasBrandSpec ? '✅' : '❌'),
              const Divider(),
              _detailRow('Cobertura', '${(p.coverageScore * 100).toInt()}%'),
              if (p.lastAnalyzedAt != null)
                _detailRow('Analizado', _formatDate(p.lastAnalyzedAt!)),
              if (p.lastCommitAt != null)
                _detailRow('Último commit', _formatDate(p.lastCommitAt!)),
              if (p.topics.isNotEmpty)
                _detailRow('Topics', p.topics.join(', ')),
            ],
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
