import 'dart:io';

import 'package:erbolamm_studio/features/analyzer/analyzer_registry_mapper.dart';
import 'package:erbolamm_studio/models/project_record.dart';
import 'package:erbolamm_studio/models/repo_analysis.dart' as analysis_model;
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
    dir = await Directory.systemTemp.createTemp('analyzer_registry_');
    await LocalDatabase.useDatabasePathForTesting('${dir.path}/registry.db');
  });
  tearDown(() async {
    await LocalDatabase.resetForTesting();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('Analyzer-created ProjectRecord id is stable and Firestore-safe', () {
    final readable = projectRecordFromAnalysis(
      analysis_model.RepoAnalysis(
        owner: 'Erbolamm',
        name: 'Studio Sample',
        url: 'https://github.com/erbolamm/studio-sample',
      ),
    );
    final normalized = projectRecordFromAnalysis(
      analysis_model.RepoAnalysis(
        owner: '  ERBOLAMM  ',
        name: 'Studio/Sample!?',
        url: 'https://github.com/erbolamm/studio-sample',
      ),
    );

    expect(readable.id, 'erbolamm--studio-sample');
    expect(normalized.id, readable.id);
    expect(normalized.id, isNot(matches(RegExp(r'^-?\d+$'))));
    expect(normalized.id, isNot(contains('/')));
    expect(normalized.id, matches(RegExp(r'^[a-z0-9-]+$')));
  });

  test(
    'Analyzer-created ProjectRecord saves locally without RTDB tables',
    () async {
      final analysis = analysis_model.RepoAnalysis(
        owner: 'erbolamm',
        name: 'studio-sample',
        url: 'https://github.com/erbolamm/studio-sample',
        topics: const ['flutter,desktop', 'registry||bridge'],
        projectType: analysis_model.ProjectType.flutterApp,
        hasReadme: true,
        hasLicense: false,
        missingItems: const ['LICENSE, missing', 'brand || spec'],
        analyzedAt: DateTime.utc(2025, 1, 5),
      );
      final project = projectRecordFromAnalysis(analysis);
      await ProjectRegistryService.instance.upsertProject(project);
      await LocalDatabase.instance.close();

      final saved = await ProjectRegistryService.instance.getProject(
        project.id,
      );
      expect(saved?.type, ProjectType.app);
      expect(saved?.patternViolations, ['LICENSE, missing', 'brand || spec']);
      expect(saved?.topics, ['flutter,desktop', 'registry||bridge']);
      expect(saved?.lastAnalyzedAt, DateTime.utc(2025, 1, 5));
      final db = await LocalDatabase.instance.database;
      expect((await db.query('project_records')).map((row) => row['id']), [
        project.id,
      ]);
      expect(
        await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('nodes','edges')",
        ),
        isEmpty,
      );
    },
  );
}
