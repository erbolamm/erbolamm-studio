import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/project_record.dart';
import '../models/repo_analysis.dart' as legacy;

class LocalDatabase {
  static const _databaseVersion = 2;
  static Database? _database;
  static String? _testPath;
  static final LocalDatabase instance = LocalDatabase._init();

  LocalDatabase._init();

  Future<Database> get database async => _database ??= await _initDB();

  static Future<void> useDatabasePathForTesting(String path) async {
    await instance.close();
    _testPath = path;
  }

  static Future<void> resetForTesting() async {
    await instance.close();
    _testPath = null;
  }

  Future<Database> _initDB() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final path =
        _testPath ??
        join(
          (await getApplicationDocumentsDirectory()).path,
          'erbolamm_studio.db',
        );
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await _createProjectsTable(db);
    await _createProjectRecords(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createProjectRecords(db);
  }

  Future<void> _createProjectsTable(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS projects (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      owner TEXT NOT NULL,
      name TEXT NOT NULL,
      url TEXT NOT NULL,
      description TEXT,
      language TEXT,
      topics TEXT,
      hasReadme INTEGER NOT NULL DEFAULT 0,
      hasLicense INTEGER NOT NULL DEFAULT 0,
      hasPromoFolder INTEGER NOT NULL DEFAULT 0,
      hasScreenshots INTEGER NOT NULL DEFAULT 0,
      hasVideo INTEGER NOT NULL DEFAULT 0,
      hasLanding INTEGER NOT NULL DEFAULT 0,
      hasBrandSpec INTEGER NOT NULL DEFAULT 0,
      missingItems TEXT,
      analyzedAt TEXT NOT NULL
    )
  ''');

  Future<void> _createProjectRecords(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS project_records (
        id TEXT PRIMARY KEY,
        owner TEXT NOT NULL,
        name TEXT NOT NULL,
        url TEXT NOT NULL,
        type TEXT NOT NULL,
        techStack TEXT NOT NULL,
        language TEXT,
        patternVersion TEXT,
        patternCompliant INTEGER NOT NULL DEFAULT 0,
        patternViolations TEXT NOT NULL DEFAULT '[]',
        lastCommitAt TEXT,
        lastAnalyzedAt TEXT,
        currentVersions TEXT,
        latestVersions TEXT,
        hasReadme INTEGER NOT NULL DEFAULT 0,
        hasLicense INTEGER NOT NULL DEFAULT 0,
        hasScreenshots INTEGER NOT NULL DEFAULT 0,
        hasVideo INTEGER NOT NULL DEFAULT 0,
        hasLanding INTEGER NOT NULL DEFAULT 0,
        hasBrandSpec INTEGER NOT NULL DEFAULT 0,
        isOwned INTEGER NOT NULL DEFAULT 1,
        isPublic INTEGER NOT NULL DEFAULT 1,
        license TEXT,
        topics TEXT NOT NULL DEFAULT '[]',
        description TEXT,
        addedAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
    for (final statement in const [
      'CREATE INDEX IF NOT EXISTS idx_project_records_updated_at ON project_records(updatedAt)',
      'CREATE INDEX IF NOT EXISTS idx_project_records_last_analyzed_at ON project_records(lastAnalyzedAt)',
      'CREATE INDEX IF NOT EXISTS idx_project_records_type ON project_records(type)',
      'CREATE INDEX IF NOT EXISTS idx_project_records_tech_stack ON project_records(techStack)',
      'CREATE INDEX IF NOT EXISTS idx_project_records_owned ON project_records(isOwned)',
      'CREATE INDEX IF NOT EXISTS idx_project_records_public ON project_records(isPublic)',
    ]) {
      await db.execute(statement);
    }
  }

  Future<int> insertProject(legacy.RepoAnalysis analysis) async =>
      (await database).insert('projects', analysis.toMap());

  Future<List<legacy.RepoAnalysis>> getAllProjects() async =>
      (await (await database).query(
        'projects',
        orderBy: 'analyzedAt DESC',
      )).map(legacy.RepoAnalysis.fromMap).toList();

  Future<int> deleteProject(int id) async =>
      (await database).delete('projects', where: 'id = ?', whereArgs: [id]);

  Future<void> upsertProjectRecord(ProjectRecord project) async {
    await (await database).insert(
      'project_records',
      project.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ProjectRecord?> getProjectRecord(String id) async {
    final rows = await (await database).query(
      'project_records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : ProjectRecord.fromMap(rows.single);
  }

  Future<List<ProjectRecord>> getAllProjectRecords() =>
      _records(orderBy: 'updatedAt DESC');

  Future<void> deleteProjectRecord(String id) async {
    await (await database).delete(
      'project_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ProjectRecord>> getStaleProjectRecords(
    Duration maxAge,
  ) => _records(
    where: 'lastAnalyzedAt IS NULL OR lastAnalyzedAt < ?',
    whereArgs: [DateTime.now().subtract(maxAge).toIso8601String()],
    orderBy:
        'CASE WHEN lastAnalyzedAt IS NULL THEN 0 ELSE 1 END, lastAnalyzedAt ASC',
  );

  Future<List<ProjectRecord>> getProjectRecordsByType(String type) =>
      _records(where: 'type = ?', whereArgs: [type], orderBy: 'updatedAt DESC');

  Future<List<ProjectRecord>> getProjectRecordsByTechStack(String stack) =>
      _records(
        where: 'techStack = ?',
        whereArgs: [stack],
        orderBy: 'updatedAt DESC',
      );

  Future<List<ProjectRecord>> getOwnedProjectRecords() =>
      _records(where: 'isOwned = ?', whereArgs: [1], orderBy: 'updatedAt DESC');

  Future<List<ProjectRecord>> getPublicProjectRecords() => _records(
    where: 'isPublic = ?',
    whereArgs: [1],
    orderBy: 'updatedAt DESC',
  );

  Future<List<ProjectRecord>> _records({
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    final rows = await (await database).query(
      'project_records',
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
    return rows.map(ProjectRecord.fromMap).toList();
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
