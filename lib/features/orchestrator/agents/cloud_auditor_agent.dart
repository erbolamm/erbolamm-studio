// ═══════════════════════════════════════════════════════════════
// ☁️ Agente 6 — Auditor de Nube
// ═══════════════════════════════════════════════════════════════
// Cruza el proyecto con Firebase, GCP y GitHub para detectar
// proyectos huérfanos o mal registrados.
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

import '../domain/agent_interface.dart';

class CloudAuditorAgent implements AgentInterface {
  @override
  String get agentId => 'cloud-auditor';
  @override
  String get agentName => 'Auditor de Nube';
  @override
  String get inboxStep => 'Paso 6';

  @override
  Future<bool> canExecute(String projectPath) async => true;

  @override
  Future<AgentOutput> execute(String projectPath) async {
    final projectName = projectPath.split(Platform.pathSeparator).last;
    final auditResults = <String, dynamic>{};
    final issues = <String>[];
    final foundProjects = <String>{};

    // ── 1. Firebase audit ─────────────────────────────────────
    auditResults['firebase'] = await _auditFirebase(issues, foundProjects);

    // ── 2. GitHub audit ───────────────────────────────────────
    auditResults['github'] = await _auditGitHub(
      projectPath,
      issues,
      foundProjects,
    );

    // ── 3. GCP audit ──────────────────────────────────────────
    auditResults['gcp'] = await _auditGCP(issues, foundProjects);

    // ── 4. Cross-reference with universe.json ─────────────────
    final universeResult = _crossReferenceUniverse(projectPath, foundProjects);
    auditResults['universe'] = universeResult;
    issues.addAll(universeResult['issues'] as List<String>);

    // ── Build summary ─────────────────────────────────────────
    final firebaseOk = auditResults['firebase']?['success'] == true;
    final githubOk = auditResults['github']?['success'] == true;
    final gcpOk = auditResults['gcp']?['success'] == true;

    final summary = StringBuffer();
    summary.writeln(
      '☁️ Auditoría de nube para "$projectName":\n'
      '   • Firebase: ${firebaseOk ? "✅" : "⚠️"} ${auditResults['firebase']?['count'] ?? 0} proyectos\n'
      '   • GitHub: ${githubOk ? "✅" : "⚠️"} ${auditResults['github']?['count'] ?? 0} repos\n'
      '   • GCP: ${gcpOk ? "✅" : "⚠️"} ${auditResults['gcp']?['count'] ?? 0} proyectos\n',
    );

    if (issues.isNotEmpty) {
      summary.writeln('\n⚠️ Incidencias encontradas:');
      for (final issue in issues.take(10)) {
        summary.writeln('   • $issue');
      }
      if (issues.length > 10) {
        summary.writeln('   • ... y ${issues.length - 10} más');
      }
    }

    return AgentOutput(
      agentId: agentId,
      success: true,
      summary: summary.toString().trim(),
      data: auditResults,
    );
  }

  // ─── Firebase audit ────────────────────────────────────────

  Future<Map<String, dynamic>> _auditFirebase(
    List<String> issues,
    Set<String> foundProjects,
  ) async {
    final result = <String, dynamic>{
      'success': false,
      'count': 0,
      'projects': <String>[],
      'error': null,
    };

    try {
      final process = await Process.run('firebase', [
        'projects:list',
        '--json',
      ], runInShell: true).timeout(Duration(seconds: 10));

      if (process.exitCode != 0) {
        result['error'] = _truncateError(process.stderr.toString());
        result['note'] = 'firebase CLI no disponible o no logueado';
        return result;
      }

      final output = process.stdout.toString();
      final json = jsonDecode(output);

      if (json is List) {
        final projects = json
            .whereType<Map<String, dynamic>>()
            .map((p) => p['projectId']?.toString() ?? 'unknown')
            .toList();
        result['success'] = true;
        result['count'] = projects.length;
        result['projects'] = projects;
        foundProjects.addAll(projects);
      }
    } catch (e) {
      result['error'] = 'Firebase: ${e.toString().substring(0, 100)}';
      result['note'] = 'firebase CLI no disponible';
    }

    return result;
  }

  // ─── GitHub audit ──────────────────────────────────────────

  Future<Map<String, dynamic>> _auditGitHub(
    String projectPath,
    List<String> issues,
    Set<String> foundProjects,
  ) async {
    final result = <String, dynamic>{
      'success': false,
      'count': 0,
      'repos': <Map<String, dynamic>>[],
      'error': null,
      'note': null,
    };

    // Try gh CLI
    try {
      final process = await Process.run('gh', [
        'repo',
        'list',
        'erbolamm',
        '--limit',
        '100',
        '--json',
        'name,updatedAt,isArchived,isFork',
      ], runInShell: true).timeout(Duration(seconds: 15));

      if (process.exitCode == 0) {
        final output = process.stdout.toString();
        final json = jsonDecode(output);
        if (json is List) {
          final repos = json.cast<Map<String, dynamic>>();
          result['success'] = true;
          result['count'] = repos.length;
          result['repos'] = repos
              .map(
                (r) => {
                  'name': r['name'],
                  'updatedAt': r['updatedAt'],
                  'archived': r['isArchived'] == true,
                  'fork': r['isFork'] == true,
                },
              )
              .toList();

          for (final repo in repos) {
            foundProjects.add(repo['name']?.toString() ?? '');
          }

          // Detect orphaned repos (no activity >1 year, not archived)
          final oneYearAgo = DateTime.now().subtract(Duration(days: 365));
          final archived = <String>[];
          final stale = <String>[];

          for (final repo in repos) {
            final name = repo['name']?.toString() ?? '';
            if (repo['isArchived'] == true) {
              archived.add(name);
            } else if (repo['updatedAt'] != null) {
              final updated = DateTime.tryParse(repo['updatedAt'].toString());
              if (updated != null && updated.isBefore(oneYearAgo)) {
                stale.add(name);
              }
            }
          }

          if (archived.isNotEmpty) {
            issues.add(
              'Repos archivados en GitHub (${archived.length}): ${archived.take(5).join(", ")}',
            );
          }
          if (stale.isNotEmpty) {
            issues.add(
              'Repos sin actividad >1 año (${stale.length}): ${stale.take(5).join(", ")}',
            );
          }
        }
        return result;
      }
    } catch (_) {}

    // Try reading git remotes from local repos instead
    result['note'] = 'gh CLI no disponible. Verificando remotos locales...';
    try {
      final localRepos = _scanLocalRepos(projectPath);
      result['success'] = true;
      result['count'] = localRepos.length;
      result['repos'] = localRepos;
      result['note'] =
          'Detectados desde remotos locales. gh CLI recomendado para auditoría completa.';
      for (final repo in localRepos) {
        if (repo['name'] != null) foundProjects.add(repo['name'] as String);
      }
    } catch (_) {
      result['error'] = 'No se pudo acceder a gh CLI ni a repos locales';
    }

    return result;
  }

  List<Map<String, dynamic>> _scanLocalRepos(String startPath) {
    final repos = <Map<String, dynamic>>[];
    var dir = Directory(startPath);

    // Walk up to find the trabajo/ directory, then scan sibling dirs
    for (int i = 0; i < 5; i++) {
      if (dir.path.endsWith('trabajo')) break;
      dir = dir.parent;
    }

    if (dir.existsSync()) {
      for (final entry in dir.listSync()) {
        if (entry is Directory) {
          final gitDir = Directory('${entry.path}/.git');
          if (gitDir.existsSync()) {
            repos.add({
              'name': entry.path.split(Platform.pathSeparator).last,
              'path': entry.path,
            });
          }
        }
      }
    }

    return repos;
  }

  // ─── GCP audit ─────────────────────────────────────────────

  Future<Map<String, dynamic>> _auditGCP(
    List<String> issues,
    Set<String> foundProjects,
  ) async {
    final result = <String, dynamic>{
      'success': false,
      'count': 0,
      'projects': <String>[],
      'error': null,
    };

    try {
      final process = await Process.run('gcloud', [
        'projects',
        'list',
        '--format=json',
      ], runInShell: true).timeout(Duration(seconds: 10));

      if (process.exitCode != 0) {
        result['error'] = _truncateError(process.stderr.toString());
        result['note'] = 'gcloud CLI no disponible o no logueado';
        return result;
      }

      final output = process.stdout.toString();
      final json = jsonDecode(output);

      if (json is List) {
        final projects = json
            .whereType<Map<String, dynamic>>()
            .map((p) => p['projectId']?.toString() ?? 'unknown')
            .toList();
        result['success'] = true;
        result['count'] = projects.length;
        result['projects'] = projects;
        foundProjects.addAll(projects);
      }
    } catch (e) {
      result['error'] = 'GCP: ${e.toString().substring(0, 100)}';
      result['note'] = 'gcloud CLI no disponible';
    }

    return result;
  }

  // ─── Universe cross-reference ──────────────────────────────

  Map<String, dynamic> _crossReferenceUniverse(
    String projectPath,
    Set<String> cloudProjects,
  ) {
    final issues = <String>[];
    final universePath = '$projectPath/../../universe.json';
    final file = File(universePath);

    if (!file.existsSync()) {
      issues.add('universe.json no encontrado');
      return {'issues': issues, 'unregistered': [], 'orphaned': []};
    }

    try {
      final content = file.readAsStringSync();
      final universe = jsonDecode(content) as Map<String, dynamic>;
      final projects =
          (universe['projects'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      final universeIds = projects
          .map((p) => p['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      // Projects in cloud but not in universe.json
      final unregistered =
          cloudProjects.where((cp) => !universeIds.contains(cp)).toList()
            ..removeWhere(
              (p) => p == 'erbolamm-hub' || p.startsWith('erbolamm-com'),
            );

      // Projects in universe but not in cloud (potential orphans)
      final cloudIds = cloudProjects.map((id) => id.replaceAll('-', ''));
      final orphaned = universeIds
          .where((id) => !cloudIds.contains(id.replaceAll('-', '')))
          .toList();

      if (unregistered.isNotEmpty) {
        issues.add(
          'Proyectos en Firebase/GCP no registrados en universe.json '
          '(${unregistered.length}): ${unregistered.take(5).join(", ")}',
        );
      }
      if (orphaned.isNotEmpty) {
        issues.add(
          'Proyectos en universe.json sin proyecto cloud '
          '(${orphaned.length}): ${orphaned.take(5).join(", ")}',
        );
      }

      return {
        'issues': issues,
        'unregistered': unregistered,
        'orphaned': orphaned,
        'totalInUniverse': universeIds.length,
      };
    } catch (e) {
      issues.add('Error al leer universe.json: $e');
      return {'issues': issues, 'unregistered': [], 'orphaned': []};
    }
  }

  // ─── Helpers ───────────────────────────────────────────────

  String _truncateError(String err) {
    return err.length > 120 ? '${err.substring(0, 120)}...' : err;
  }
}
