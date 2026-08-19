// ═══════════════════════════════════════════════════════════════
// 🧪 Tests — Agente 1: Analizador
// ═══════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:test/test.dart';
import 'package:erbolamm_studio/features/orchestrator/agents/analyzer_agent.dart';
import '../fixtures/project_fixtures.dart';

void main() {
  late Directory tempDir;
  late AnalyzerAgent agent;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('analyzer_test_');
    agent = AnalyzerAgent();
  });

  tearDown(() {
    cleanTempDir(tempDir);
  });

  group('canExecute', () {
    test('returns true when directory exists', () async {
      final result = await agent.canExecute(tempDir.path);
      expect(result, isTrue);
    });

    test('returns false when directory does not exist', () async {
      final result = await agent.canExecute('/nonexistent/path');
      expect(result, isFalse);
    });
  });

  group('execute - Flutter project', () {
    setUp(() {
      createFlutterProject(tempDir);
    });

    test('detects Flutter app type', () async {
      final output = await agent.execute(tempDir.path);
      expect(output.success, isTrue);
      expect(output.data['type'], contains('Flutter'));
    });

    test('detects Dart language', () async {
      final output = await agent.execute(tempDir.path);
      expect(output.data['language'], contains('Dart'));
    });

    test('counts files and lines', () async {
      final output = await agent.execute(tempDir.path);
      expect(output.data['totalFiles'] as int, greaterThan(0));
      expect(output.data['totalLines'] as int, greaterThan(0));
    });
  });

  group('execute - Node.js project', () {
    setUp(() {
      createNodeProject(tempDir);
    });

    test('detects Node.js type', () async {
      final output = await agent.execute(tempDir.path);
      expect(output.data['type'], contains('Node'));
    });
  });

  group('execute - Web HTML project', () {
    setUp(() {
      createWebProject(tempDir);
    });

    test('detects Web type', () async {
      final output = await agent.execute(tempDir.path);
      expect(output.data['type'], contains('Web'));
    });
  });

  group('execute - Skeleton project', () {
    setUp(() {
      createSkeletonProject(tempDir);
    });

    test('marked as broken for minimal project', () async {
      createSkeletonProject(tempDir);
      final output = await agent.execute(tempDir.path);
      expect(output.data['completeness'], anyOf(contains('Roto'), contains('Esqueleto')));
    });
  });

  group('execute - agent metadata', () {
    test('has correct agentId', () {
      expect(agent.agentId, equals('analyzer'));
    });

    test('has correct inboxStep', () {
      expect(agent.inboxStep, equals('Paso 1'));
    });
  });
}
