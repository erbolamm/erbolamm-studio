import 'dart:io';

import 'package:erbolamm_studio/models/project_record.dart';
import 'package:erbolamm_studio/services/local_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dir = await Directory.systemTemp.createTemp('project_records_');
    await LocalDatabase.useDatabasePathForTesting('${dir.path}/registry.db');
  });
  tearDown(() async {
    await LocalDatabase.resetForTesting();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('creates schema and persists JSON-list records across reopen', () async {
    final record = _record(
      'complete',
      updated: DateTime.utc(2025, 1, 2),
      violations: ['README, docs', 'legacy || separator'],
      topics: ['flutter,desktop', 'studio||registry'],
    );
    final db = await LocalDatabase.instance.database;
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('projects','project_records')",
    );
    final indexes = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='project_records'",
    );
    expect(
      tables.map((row) => row['name']),
      containsAll(['projects', 'project_records']),
    );
    expect(
      indexes.map((row) => row['name']),
      containsAll([
        'idx_project_records_updated_at',
        'idx_project_records_last_analyzed_at',
        'idx_project_records_type',
        'idx_project_records_tech_stack',
        'idx_project_records_owned',
        'idx_project_records_public',
      ]),
    );

    await LocalDatabase.instance.upsertProjectRecord(record);
    final raw = (await db.query(
      'project_records',
      where: 'id=?',
      whereArgs: [record.id],
    )).single;
    expect(raw['patternViolations'], startsWith('['));
    expect(raw['topics'], startsWith('['));
    await LocalDatabase.instance.close();

    final reopened = await LocalDatabase.instance.getProjectRecord(record.id);
    expect(reopened?.patternViolations, record.patternViolations);
    expect(reopened?.topics, record.topics);
    expect(reopened?.lastAnalyzedAt, record.lastAnalyzedAt);
  });

  test('replaces, deletes, lists, filters, and finds stale records', () async {
    final fresh = _record(
      'fresh',
      type: ProjectType.app,
      stack: TechStack.flutter,
      analyzed: DateTime.now(),
      updated: DateTime.utc(2025, 1, 3),
    );
    final stale = _record(
      'stale',
      type: ProjectType.website,
      stack: TechStack.react,
      owned: false,
      analyzed: DateTime.now().subtract(const Duration(days: 400)),
      updated: DateTime.utc(2025, 1, 1),
    );
    final never = _record(
      'never',
      type: ProjectType.website,
      stack: TechStack.react,
      public: false,
      analyzed: null,
      updated: DateTime.utc(2025, 1, 2),
    );
    for (final record in [
      fresh,
      stale,
      never,
      fresh.copyWith(
        description: 'updated',
        updatedAt: DateTime.utc(2025, 1, 4),
      ),
    ]) {
      await LocalDatabase.instance.upsertProjectRecord(record);
    }

    expect(
      (await LocalDatabase.instance.getAllProjectRecords()).map((r) => r.id),
      ['fresh', 'never', 'stale'],
    );
    expect(
      (await LocalDatabase.instance.getProjectRecordsByType(
        ProjectType.website.name,
      )).map((r) => r.id),
      containsAll(['stale', 'never']),
    );
    expect(
      (await LocalDatabase.instance.getProjectRecordsByTechStack(
        TechStack.react.name,
      )).map((r) => r.id),
      containsAll(['stale', 'never']),
    );
    expect(
      (await LocalDatabase.instance.getOwnedProjectRecords()).map((r) => r.id),
      containsAll(['fresh', 'never']),
    );
    expect(
      (await LocalDatabase.instance.getPublicProjectRecords()).map((r) => r.id),
      containsAll(['fresh', 'stale']),
    );
    expect(
      (await LocalDatabase.instance.getStaleProjectRecords(
        const Duration(days: 180),
      )).map((r) => r.id),
      ['never', 'stale'],
    );

    await LocalDatabase.instance.deleteProjectRecord('stale');
    expect(await LocalDatabase.instance.getProjectRecord('stale'), isNull);
  });
}

ProjectRecord _record(
  String id, {
  ProjectType type = ProjectType.app,
  TechStack stack = TechStack.flutter,
  bool owned = true,
  bool public = true,
  List<String> violations = const [],
  List<String> topics = const [],
  DateTime? analyzed,
  DateTime? updated,
}) => ProjectRecord(
  id: id,
  owner: 'erbolamm',
  name: id,
  url: 'https://example.test/$id',
  type: type,
  techStack: stack,
  patternCompliant: violations.isEmpty,
  patternViolations: violations,
  lastAnalyzedAt: analyzed ?? DateTime.utc(2025, 1, 1),
  hasReadme: true,
  hasLicense: true,
  isOwned: owned,
  isPublic: public,
  topics: topics,
  description: 'registry record',
  addedAt: DateTime.utc(2025, 1, 1),
  updatedAt: updated ?? DateTime.utc(2025, 1, 1),
);
