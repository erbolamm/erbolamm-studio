// ═══════════════════════════════════════════════════════════════
// 🧪 Tests — Agente 4: Marketing
// ═══════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:test/test.dart';
import 'package:erbolamm_studio/features/orchestrator/agents/marketing_agent.dart';
import '../fixtures/project_fixtures.dart';

void main() {
  late Directory tempDir;
  late MarketingAgent agent;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('marketing_test_');
    agent = MarketingAgent(selectedLanguages: const ['es'], renderMedia: false);
  });

  tearDown(() {
    cleanTempDir(tempDir);
  });

  group('canExecute', () {
    test('returns true when directory exists', () async {
      expect(await agent.canExecute(tempDir.path), isTrue);
    });
  });

  group('execute - Flutter project', () {
    setUp(() {
      createFlutterProject(tempDir);
    });

    test('generates brand-spec.md', () async {
      final output = await agent.execute(tempDir.path);
      expect(output.success, isTrue);
      expect(output.data['brandSpec'], isTrue);
    });

    test('generates promo files', () async {
      final output = await agent.execute(tempDir.path);
      final files = output.data['generatedFiles'] as List;
      expect(files.any((f) => (f as String).contains('brand-spec.md')), isTrue);
    });

    test('creates studio directories', () async {
      await agent.execute(tempDir.path);
      expect(Directory('${tempDir.path}/erbolamm-studio').existsSync(), isTrue);
      expect(Directory('${tempDir.path}/erbolamm-studio/source').existsSync(), isTrue);
      expect(
        Directory('${tempDir.path}/erbolamm-studio/screenshots').existsSync(),
        isTrue,
      );
    });
  }, timeout: const Timeout(Duration(seconds: 120)));

  group('MarketingResult model', () {
    test('creates with default values', () {
      const result = MarketingResult(
        brandSpecCreated: true,
        screenshotsGenerated: 3,
        videoCreated: false,
        musicGenerated: true,
        generatedFiles: ['brand-spec.md'],
        summary: 'Done',
      );
      expect(result.brandSpecCreated, isTrue);
      expect(result.screenshotsGenerated, equals(3));
      expect(result.generatedFiles.length, equals(1));
    });
  });

  group('agent metadata', () {
    test('has correct agentId', () {
      expect(agent.agentId, equals('marketing'));
    });
  });
}
