// ═══════════════════════════════════════════════════════════════
// 🧪 Tests — Agente 5: Registrador
// ═══════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:test/test.dart';
import 'package:erbolamm_studio/features/orchestrator/agents/registrar_agent.dart';
import '../fixtures/project_fixtures.dart';

void main() {
  late Directory rootDir;
  late Directory projectDir;
  late RegistrarAgent agent;

  setUp(() {
    rootDir = Directory.systemTemp.createTempSync('registrar_test_');
    // Simular estructura INBOX/proyecto/
    projectDir = Directory('${rootDir.path}/inbox/test-project');
    projectDir.createSync(recursive: true);
    agent = RegistrarAgent();
  });

  tearDown(() {
    cleanTempDir(rootDir);
  });

  group('execute', () {
    test('creates universe.json when it does not exist', () async {
      createFlutterProject(projectDir);
      final output = await agent.execute(projectDir.path);
      expect(output.success, isTrue);
      expect(output.summary, contains('registrado'));
      // Verify universe.json was created
      final universeFile = File('${rootDir.path}/universe.json');
      expect(universeFile.existsSync(), isTrue);
    });

    test('registers project in universe.json', () async {
      createFlutterProject(projectDir);
      createWithUniverse(rootDir); // universe.json en la raíz (../../)
      final output = await agent.execute(projectDir.path);
      expect(output.success, isTrue);
      expect(output.summary, contains('registrado'));
    });

    test('does not duplicate existing projects', () async {
      createFlutterProject(projectDir);
      createWithUniverse(rootDir);

      await agent.execute(projectDir.path);
      final output = await agent.execute(projectDir.path);
      expect(output.success, isTrue);
      expect(output.data['status'], equals('already_exists'));
    });
  });

  group('agent metadata', () {
    test('has correct agentId', () {
      expect(agent.agentId, equals('registrar'));
    });

    test('has correct inboxStep', () {
      expect(agent.inboxStep, equals('Paso 5'));
    });
  });
}
