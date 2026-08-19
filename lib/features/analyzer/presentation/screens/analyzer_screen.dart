import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import '../../../../core/constants/colors.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/navigation/bloc/navigation_bloc.dart';
import '../../../../core/navigation/bloc/navigation_event.dart';
import '../../../../models/repo_analysis.dart' as ra;
import '../../../../services/project_monitor.dart';
import '../../../../services/project_registry_service.dart';
import '../../../../services/firestore_publisher.dart';
import '../../analyzer_registry_mapper.dart';
import '../widgets/checklist_widget.dart';
import '../bloc/analyzer_bloc.dart';
import '../bloc/analyzer_event.dart';
import '../bloc/analyzer_state.dart';

class AnalyzerScreen extends StatefulWidget {
  final ProjectMonitor? monitor;

  const AnalyzerScreen({super.key, this.monitor});

  @override
  State<AnalyzerScreen> createState() => _AnalyzerScreenState();
}

class _AnalyzerScreenState extends State<AnalyzerScreen> {
  final _urlController = TextEditingController();
  bool _isAnalyzing = false;
  final _publisher = FeatureFlags.cloudEnabled ? FirestorePublisher() : null;

  @override
  void initState() {
    super.initState();
    // Auto-analizar si hay proyecto en INBOX
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.monitor?.hasProject == true) {
        _analyzeInbox();
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _publisher?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: AppColors.ia),
            SizedBox(width: 8),
            Text('ErBolamm Studio'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textSecondary),
            tooltip: 'Ajustes',
            onPressed: () {
              context.read<NavigationBloc>().add(NavigationItemSelected(10));
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, Color(0xFF0f0f1a)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.search,
                          color: AppColors.educacion,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Analizador de Repos',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pega una URL de GitHub o una ruta local para verificar qué falta según INBOX.md',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Selector de Proyectos en INBOX (si existen)
              if (widget.monitor?.hasProject == true) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inbox_rounded, color: AppColors.herramientas, size: 22),
                      const SizedBox(width: 12),
                      const Text(
                        'Proyecto INBOX:',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: widget.monitor?.projectName,
                            dropdownColor: AppColors.surfaceLight,
                            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            items: widget.monitor!.availableProjects.map((proj) {
                              return DropdownMenuItem<String>(
                                value: proj,
                                child: Text(proj),
                              );
                            }).toList(),
                            onChanged: (selected) {
                              if (selected != null) {
                                widget.monitor?.selectProject(selected);
                                _urlController.text = widget.monitor!.projectPath ?? '';
                                setState(() {});
                                _analyze();
                              }
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Analizar proyecto seleccionado',
                        icon: const Icon(Icons.play_circle_fill, color: AppColors.herramientas),
                        onPressed: _analyzeInbox,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Input URL
              TextField(
                controller: _urlController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText:
                      'https://github.com/usuario/repo  o  /ruta/local/proyecto',
                  labelText: 'Repo (GitHub o local)',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(
                    Icons.link,
                    color: AppColors.educacion,
                  ),
                  suffixIcon: _urlController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () {
                            _urlController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.educacion,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.surface.withValues(alpha: 0.5),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _analyze(),
              ),
              const SizedBox(height: 16),

              // Botón Analizar
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.educacion, AppColors.ia],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.educacion.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _urlController.text.isNotEmpty && !_isAnalyzing
                      ? _analyze
                      : null,
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.search),
                  label: Text(
                    _isAnalyzing ? 'Analizando...' : 'Analizar Repo',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Resultados con BLoC
              Expanded(
                child: BlocConsumer<AnalyzerBloc, AnalyzerState>(
                  listener: (context, state) {
                    if (state is AnalyzerError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          duration: const Duration(milliseconds: 1000),
                          backgroundColor: AppColors.creacion,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is AnalyzerInitial) {
                      return _buildEmptyState();
                    }

                    if (state is AnalyzerLoading) {
                      return _buildLoadingState();
                    }

                    if (state is AnalyzerSuccess) {
                      return ChecklistWidget(
                        analysis: state.analysis,
                        onSendToOrchestrator: () =>
                            _sendToOrchestrator(state.analysis),
                        onSaveToRegistry: () => _saveToRegistry(state.analysis),
                        onPublishToUniverse:
                            FeatureFlags.cloudEnabled &&
                                state.analysis.hasLanding &&
                                state.analysis.missingItems.isEmpty
                            ? () => _publishToUniverse(state.analysis)
                            : null,
                        inbxProjectName: widget.monitor?.projectName,
                        onAnalyzeInbox:
                            widget.monitor != null && widget.monitor!.hasProject
                            ? () => _analyzeInbox()
                            : null,
                      );
                    }

                    if (state is AnalyzerError) {
                      return _buildErrorState(state.message);
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasInbox = widget.monitor?.hasProject == true;
    final inboxName = widget.monitor?.projectName;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_outlined,
                size: 80,
                color: AppColors.textMuted.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pega un repo para empezar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analiza cualquier repositorio de GitHub',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted.withValues(alpha: 0.7),
              ),
            ),
            if (hasInbox && inboxName != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.herramientas.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.herramientas.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inbox,
                      color: AppColors.herramientas,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Proyecto en INBOX: $inboxName',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: _analyzeInbox,
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Analizar'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.herramientas,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.educacion.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.educacion),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Analizando repositorio...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.creacion.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.creacion.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.creacion,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.creacion, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _analyze() {
    if (_urlController.text.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
    });

    context.read<AnalyzerBloc>().add(AnalyzeRepoEvent(_urlController.text));

    // Reset después de un breve delay para mostrar el loading
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    });
  }

  Future<void> _sendToOrchestrator(ra.RepoAnalysis analysis) async {
    final project = projectRecordFromAnalysis(analysis);
    await ProjectRegistryService.instance.upsertProject(project);

    if (analysis.owner == 'local') {
      // Modo Referencia Directa: Fijar la ruta directa del proyecto sin copiar
      widget.monitor?.setCustomProjectPath(analysis.url);
    } else {
      // Repositorio remoto: Clonar a INBOX/
      await _copyToInbox(analysis);
      widget.monitor?.selectProject(analysis.name);
    }
    widget.monitor?.refresh();

    if (!mounted) return;

    // Navegar a Orchestrator (índice 1)
    context.read<NavigationBloc>().add(NavigationItemSelected(1));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${analysis.name}" conectado al Orchestrator ✅'),
        duration: const Duration(milliseconds: 1000),
        backgroundColor: AppColors.cultura,
      ),
    );
  }

  Future<void> _copyToInbox(ra.RepoAnalysis analysis) async {
    final basePath = Directory.current.path;
    final inboxPath = '$basePath/INBOX/${analysis.name}';

    try {
      if (analysis.owner == 'local') {
        final sourceDir = Directory(analysis.url);
        if (!sourceDir.existsSync()) return;

        final targetDir = Directory(inboxPath);
        if (!targetDir.existsSync()) {
          targetDir.createSync(recursive: true);
        }

        await _copyDirectory(sourceDir, targetDir);
      } else {
        // Clonar repositorio remoto de GitHub a INBOX/
        final inboxDir = Directory('$basePath/INBOX');
        if (!inboxDir.existsSync()) {
          inboxDir.createSync(recursive: true);
        }
        final targetDir = Directory(inboxPath);
        if (!targetDir.existsSync()) {
          await Process.run('git', ['clone', '--depth', '1', analysis.url, inboxPath]);
        }
      }
    } catch (e) {
      AppLogger.e('Error al copiar a INBOX: $e');
    }
  }

  Future<void> _copyDirectory(Directory source, Directory dest) async {
    dest.createSync(recursive: true);
    for (final entity in source.listSync(followLinks: false)) {
      final name = p.basename(entity.path);
      // Ignorar carpetas temporales/pesadas para una copia rápida y limpia
      if (name == '.dart_tool' ||
          name == 'build' ||
          name == '.git' ||
          name == 'Pods' ||
          name == '.gradle' ||
          name == '.idea' ||
          name == 'node_modules') {
        continue;
      }
      final newPath = p.join(dest.path, name);
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      } else if (entity is File) {
        try {
          await entity.copy(newPath);
        } catch (_) {}
      }
    }
  }

  Future<void> _saveToRegistry(ra.RepoAnalysis analysis) async {
    final project = projectRecordFromAnalysis(analysis);
    await ProjectRegistryService.instance.upsertProject(project);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${analysis.name}" guardado en Registry ✅'),
        duration: const Duration(milliseconds: 1000),
        backgroundColor: AppColors.herramientas,
      ),
    );
  }

  Future<void> _publishToUniverse(ra.RepoAnalysis analysis) async {
    // 1. Guardar localmente en registry
    final project = projectRecordFromAnalysis(analysis);
    await ProjectRegistryService.instance.upsertProject(project);

    // 2. Registrar en universe.json directamente
    await _injectIntoUniverseJson(analysis);

    // 3. Si Cloud está activo, publicar en Firestore
    final publisher = _publisher;
    if (!FeatureFlags.cloudEnabled || publisher == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${analysis.name}" inyectado en universe.json ✅'),
          duration: const Duration(milliseconds: 1000),
          backgroundColor: AppColors.cultura,
        ),
      );
      return;
    }

    publisher.initialize();

    if (!publisher.isReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${analysis.name}" guardado en universe.json ✅ (${publisher.initError ?? "Firestore offline"})',
          ),
          duration: const Duration(milliseconds: 1000),
          backgroundColor: AppColors.cultura,
        ),
      );
      return;
    }

    // Convertir a record público y publicar en Firestore
    final publicRecord = publicRecordFromProjectRecord(project);
    final success = await publisher.upsertPublicProject(publicRecord);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${publicRecord.label}" publicado en Universo 🌐'),
          duration: const Duration(milliseconds: 1000),
          backgroundColor: AppColors.cultura,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${publicRecord.label}" guardado en universe.json ✅'),
          duration: const Duration(milliseconds: 1000),
          backgroundColor: AppColors.cultura,
        ),
      );
    }
  }

  Future<void> _injectIntoUniverseJson(ra.RepoAnalysis analysis) async {
    try {
      final universeFile = File('universe.json');
      Map<String, dynamic> universe;
      if (universeFile.existsSync()) {
        universe = jsonDecode(universeFile.readAsStringSync()) as Map<String, dynamic>;
        if (universe['projects'] is! List) universe['projects'] = [];
      } else {
        universe = {'projects': <dynamic>[], 'lastUpdated': DateTime.now().toIso8601String().substring(0, 10)};
      }

      final projects = universe['projects'] as List<dynamic>;
      final existingIndex = projects.indexWhere((p) => p is Map && p['id'] == analysis.name);

      final entry = {
        'id': analysis.name,
        'name': analysis.name,
        'pillar': 'cultura',
        'type': analysis.projectType.name,
        'description': analysis.description ?? 'Proyecto del ecosistema ErBolamm',
        'urls': {
          'github': analysis.url,
          'landing': analysis.hasLanding ? (analysis.landingUrl ?? (analysis.url.contains('github.com') ? 'https://${analysis.owner}.github.io/${analysis.name}' : null)) : null,
        },
        'status': analysis.missingItems.isEmpty ? 'completed' : 'wip',
        'promo': {'video': analysis.hasVideo, 'screenshots': analysis.hasScreenshots, 'landing': analysis.hasLanding},
      };

      if (existingIndex >= 0) {
        projects[existingIndex] = entry;
      } else {
        projects.add(entry);
      }

      universe['lastUpdated'] = DateTime.now().toIso8601String().substring(0, 10);
      universeFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(universe));
    } catch (_) {}
  }

  void _analyzeInbox() {
    final path = widget.monitor?.projectPath;
    if (path == null) return;

    _urlController.text = path;
    _analyze();
  }
}
