import 'dart:io';

import 'package:erbolamm_studio/models/project_record.dart';
import 'package:erbolamm_studio/services/local_db.dart';
import 'package:erbolamm_studio/services/project_registry_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dir = await Directory.systemTemp.createTemp('registry_service_');
    await LocalDatabase.useDatabasePathForTesting('${dir.path}/registry.db');
  });
  tearDown(() async {
    await LocalDatabase.resetForTesting();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test(
    'delegates CRUD, filters, attention, and stats to LocalDatabase',
    () async {
      final service = ProjectRegistryService.instance;
      for (final record in [
        _record(
          'flutter',
          type: ProjectType.app,
          stack: TechStack.flutter,
          updated: DateTime.utc(2025, 1, 3),
        ),
        _record(
          'react',
          type: ProjectType.website,
          stack: TechStack.react,
          owned: false,
          updated: DateTime.utc(2025, 1, 2),
        ),
        _record(
          'workflow',
          type: ProjectType.workflow,
          stack: TechStack.n8n,
          public: false,
          hasReadme: false,
          analyzed: DateTime.now().subtract(const Duration(days: 400)),
        ),
      ]) {
        await service.upsertProject(record);
      }

      expect((await service.getProject('flutter'))?.name, 'flutter');
      expect((await service.getAllProjects()).map((r) => r.id), [
        'flutter',
        'react',
        'workflow',
      ]);
      expect(
        (await service.getProjectsByType(ProjectType.website)).single.id,
        'react',
      );
      expect(
        (await service.getProjectsByTechStack(TechStack.n8n)).single.id,
        'workflow',
      );
      expect(
        (await service.getOwnedProjects()).map((r) => r.id),
        containsAll(['flutter', 'workflow']),
      );
      expect(
        (await service.getPublicProjects()).map((r) => r.id),
        containsAll(['flutter', 'react']),
      );
      expect(
        (await service.getProjectsNeedingAttention()).map((r) => r.id),
        contains('workflow'),
      );

      final stats = await service.getStats();
      expect([stats.total, stats.owned, stats.stale], [3, 2, 1]);
      expect(stats.byType[ProjectType.app], 1);
      expect(stats.byTechStack[TechStack.flutter], 1);

      await service.deleteProject('react');
      expect(await service.getProject('react'), isNull);
    },
  );
}

ProjectRecord _record(
  String id, {
  ProjectType type = ProjectType.app,
  TechStack stack = TechStack.flutter,
  bool owned = true,
  bool public = true,
  bool hasReadme = true,
  DateTime? analyzed,
  DateTime? updated,
}) => ProjectRecord(
  id: id,
  owner: 'erbolamm',
  name: id,
  url: 'https://example.test/$id',
  type: type,
  techStack: stack,
  patternCompliant: hasReadme,
  patternViolations: hasReadme ? const [] : const ['missing README'],
  lastAnalyzedAt: analyzed ?? DateTime.now(),
  hasReadme: hasReadme,
  hasLicense: true,
  isOwned: owned,
  isPublic: public,
  addedAt: DateTime.utc(2025, 1, 1),
  updatedAt: updated ?? DateTime.utc(2025, 1, 1),
);
