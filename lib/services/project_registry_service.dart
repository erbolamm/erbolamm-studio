// ═══════════════════════════════════════════════════════════════
// 🗄️ ProjectRegistryService — CRUD + queries de salud
// ═══════════════════════════════════════════════════════════════
// Punto de acceso único al Project Registry.
// Delega el almacenamiento en LocalDatabase.
//
// Uso:
//
//   final service = ProjectRegistryService.instance;
//   await service.upsertProject(project);
//   final all = await service.getAllProjects();
//   final stale = await service.getStaleProjects(Duration(days: 180));
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

import '../models/project_record.dart';
import 'local_db.dart';

class ProjectRegistryService {
  static final ProjectRegistryService instance =
      ProjectRegistryService._();

  ProjectRegistryService._();

  LocalDatabase get _db => LocalDatabase.instance;

  // ─── CRUD básico + Sincronización Canónica ─────────────────────

  /// Inserta o actualiza un ProjectRecord en LocalDatabase y sincroniza con universe.json.
  Future<void> upsertProject(ProjectRecord project, {bool syncUniverse = true}) async {
    await _db.upsertProjectRecord(project);
    if (syncUniverse) {
      await syncToUniverseJson(project);
    }
  }

  /// Sincroniza un ProjectRecord directamente con el archivo universe.json
  Future<void> syncToUniverseJson(ProjectRecord project) async {
    try {
      final universeFile = File('universe.json');
      Map<String, dynamic> universe;
      if (universeFile.existsSync()) {
        final content = universeFile.readAsStringSync();
        universe = jsonDecode(content) as Map<String, dynamic>;
        if (universe['projects'] is! List) universe['projects'] = [];
      } else {
        universe = {
          'projects': <dynamic>[],
          'lastUpdated': DateTime.now().toIso8601String().substring(0, 10),
        };
      }

      final projects = universe['projects'] as List<dynamic>;
      final existingIndex = projects.indexWhere(
        (p) => p is Map && (p['id'] == project.id || p['id'] == project.name),
      );

      final entry = {
        'id': project.id.isNotEmpty ? project.id : project.name,
        'name': project.name,
        'pillar': 'herramientas',
        'type': project.type.name,
        'description': project.description ?? '',
        'urls': {
          'github': project.url,
          'landing': project.hasLanding ? project.url : null,
          'playstore': null,
          'appstore': null,
        },
        'status': project.patternViolations.isEmpty ? 'completed' : 'wip',
        'promo': {
          'video': project.hasVideo,
          'screenshots': project.hasScreenshots,
          'landing': project.hasLanding,
        },
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

  /// Obtiene un proyecto por su UUID. Devuelve null si no existe.
  Future<ProjectRecord?> getProject(String id) async {
    return await _db.getProjectRecord(id);
  }

  /// Obtiene todos los proyectos ordenados por fecha de actualización.
  Future<List<ProjectRecord>> getAllProjects() async {
    return await _db.getAllProjectRecords();
  }

  /// Elimina un proyecto por UUID y de universe.json si existe.
  Future<void> deleteProject(String id) async {
    await _db.deleteProjectRecord(id);
    try {
      final universeFile = File('universe.json');
      if (universeFile.existsSync()) {
        final universe = jsonDecode(universeFile.readAsStringSync()) as Map<String, dynamic>;
        if (universe['projects'] is List) {
          (universe['projects'] as List).removeWhere((p) => p is Map && p['id'] == id);
          universe['lastUpdated'] = DateTime.now().toIso8601String().substring(0, 10);
          universeFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(universe));
        }
      }
    } catch (_) {}
  }

  // ─── Queries de salud ────────────────────────────────────────

  /// Proyectos que no se han analizado en más de [maxAge].
  /// Útil para encontrar proyectos olvidados.
  Future<List<ProjectRecord>> getStaleProjects(Duration maxAge) async {
    return await _db.getStaleProjectRecords(maxAge);
  }

  /// Proyectos que incumplen el patrón actual.
  /// Se basa en el flag patternCompliant (false = necesita atención).
  Future<List<ProjectRecord>> getProjectsNeedingAttention() async {
    final all = await getAllProjects();
    return all.where((p) =>
        p.patternViolations.isNotEmpty || p.isMissingCriticalFiles).toList();
  }

  /// Proyectos por tipo de proyecto.
  Future<List<ProjectRecord>> getProjectsByType(ProjectType type) async {
    return await _db.getProjectRecordsByType(type.name);
  }

  /// Proyectos por stack tecnológico.
  Future<List<ProjectRecord>> getProjectsByTechStack(TechStack stack) async {
    return await _db.getProjectRecordsByTechStack(stack.name);
  }

  /// Solo proyectos propios (isOwned = true).
  Future<List<ProjectRecord>> getOwnedProjects() async {
    return await _db.getOwnedProjectRecords();
  }

  /// Solo proyectos públicos en GitHub.
  Future<List<ProjectRecord>> getPublicProjects() async {
    return await _db.getPublicProjectRecords();
  }

  // ─── Estadísticas ────────────────────────────────────────────

  /// Resumen rápido del estado del registry.
  Future<RegistryStats> getStats() async {
    final all = await getAllProjects();
    final owned = await getOwnedProjects();
    final stale =
        await getStaleProjects(const Duration(days: 180));

    return RegistryStats(
      total: all.length,
      owned: owned.length,
      stale: stale.length,
      byType: _groupByType(all),
      byTechStack: _groupByTechStack(all),
    );
  }

  Map<ProjectType, int> _groupByType(List<ProjectRecord> projects) {
    final map = <ProjectType, int>{};
    for (final p in projects) {
      map[p.type] = (map[p.type] ?? 0) + 1;
    }
    return map;
  }

  Map<TechStack, int> _groupByTechStack(List<ProjectRecord> projects) {
    final map = <TechStack, int>{};
    for (final p in projects) {
      map[p.techStack] = (map[p.techStack] ?? 0) + 1;
    }
    return map;
  }

  // ─── Migración legacy ───────────────────────────────────────

  /// Migra un registro de la tabla legacy "projects" a "project_records".
  /// Genera un UUID a partir del nombre del proyecto.
  Future<void> migrateLegacyProject(String owner, String name, String url) async {
    // Generar UUID determinista para reproducibilidad
    final uuid = _generateUuid(owner, name);

    // Obtener datos legacy si existen (mediante migrateFromRepoAnalysis
    // desde LocalDatabase, que requiere un RepoAnalysis — aquí usamos un
    // atajo creando el ProjectRecord directamente con los datos disponibles)
    final record = ProjectRecord(
      id: uuid,
      owner: owner,
      name: name,
      url: url,
      isOwned: true,
      isPublic: true,
      addedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await upsertProject(record);
  }

  String _generateUuid(String owner, String name) {
    // UUID simple basado en owner + name — reproducible y corto
    final input = '$owner/$name';
    var hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash) + input.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF;
    }
    // Formato UUID-like: 8-4-4-4-12 hex
    final hex = hash.toRadixString(16).padLeft(8, '0');
    return '${hex.substring(0, 8)}-${hex.substring(0, 4)}-0000-0000-${hex.substring(4, 12).padLeft(12, '0')}';
  }
}

/// Estadísticas agregadas del registry
class RegistryStats {
  final int total;
  final int owned;
  final int stale;
  final Map<ProjectType, int> byType;
  final Map<TechStack, int> byTechStack;

  const RegistryStats({
    required this.total,
    required this.owned,
    required this.stale,
    required this.byType,
    required this.byTechStack,
  });

  @override
  String toString() {
    return 'RegistryStats(total: $total, owned: $owned, stale: $stale)';
  }
}