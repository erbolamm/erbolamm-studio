// ═══════════════════════════════════════════════════════════════
// 🧪 Tests — Agente 7: Migrador (actualizado)
// ═══════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:test/test.dart';
import 'package:erbolamm_studio/features/orchestrator/agents/migrator_agent.dart';
import '../fixtures/project_fixtures.dart';

void main() {
  late Directory tempDir;
  late MigratorAgent agent;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('migrator_test_');
    agent = MigratorAgent();
  });

  tearDown(() {
    cleanTempDir(tempDir);
  });

  group('execute', () {
    test('detects Flutter app type correctly', () async {
      createFlutterProject(tempDir);
      final output = await agent.execute(tempDir.path);
      expect(output.data['type'], equals('flutter-app'));
    });

    test('no web hosting recommended for Flutter app without web', () async {
      createFlutterProject(tempDir);
      final output = await agent.execute(tempDir.path);
      expect(output.data['shouldMigrate'], isFalse);
    });

    test('recommends Marketplace for VS Code extension', () async {
      final json = '''
{
  "name": "test-extension",
  "description": "VS Code extension",
  "publisher": "test",
  "engines": { "vscode": "^1.0.0" }
}
''';
      File('${tempDir.path}/package.json').writeAsStringSync(json);
      final output = await agent.execute(tempDir.path);
      expect(output.data['type'], equals('vscode-extension'));
      expect(output.data['recommended'], equals('vscode-marketplace'));
    });

    test('recommends Firebase for Web project', () async {
      createWebProject(tempDir);
      final output = await agent.execute(tempDir.path);
      expect(output.data['recommended'], equals('firebase'));
    });

    test('includes viable options list', () async {
      createWebProject(tempDir);
      final output = await agent.execute(tempDir.path);
      expect(output.data['viableOptions'], isA<List>());
      expect((output.data['viableOptions'] as List).isNotEmpty, isTrue);
    });

    test('includes migration commands', () async {
      createWebProject(tempDir);
      final output = await agent.execute(tempDir.path);
      expect(output.data['commands'], isA<List>());
    });
  });

  group('agent metadata', () {
    test('has correct agentId', () {
      expect(agent.agentId, equals('migrator'));
    });

    test('has correct inboxStep', () {
      expect(agent.inboxStep, equals('Paso 7'));
    });
  });
}
