// ═══════════════════════════════════════════════════════════════
// 🧪 Tests — Agente 3: Auditor de Requisitos
// ═══════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:test/test.dart';
import 'package:erbolamm_studio/features/orchestrator/agents/auditor_agent.dart';
import '../fixtures/project_fixtures.dart';

void main() {
  late Directory tempDir;
  late AuditorAgent agent;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('auditor_test_');
    agent = AuditorAgent();
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
      final result = await agent.canExecute('/nonexistent');
      expect(result, isFalse);
    });
  });

  group('execute - Flutter project with full README', () {
    setUp(() {
      createFlutterProject(tempDir);
    });

    test('executes successfully', () async {
      final output = await agent.execute(tempDir.path);
      expect(output.success, isTrue);
    });

    test('has checks array', () async {
      final output = await agent.execute(tempDir.path);
      expect(output.data['checks'], isA<List>());
      expect((output.data['checks'] as List).length, greaterThan(0));
    });

    test('readme check reflects project state', () async {
      final output = await agent.execute(tempDir.path);
      final checks = output.data['checks'] as List;
      final readmeCheck = checks.firstWhere(
        (c) => c['id'] == 'readme-exists',
        orElse: () => {'passed': false},
      );
      expect(readmeCheck['passed'], isTrue);
    });

    test('detects README sections', () async {
      final output = await agent.execute(tempDir.path);
      final checks = output.data['checks'] as List;
      final readmeCheck = checks.firstWhere(
        (c) => c['id'] == 'readme-sections',
      );
      expect(readmeCheck['passed'], isTrue);
    });

    test('detects LICENSE', () async {
      final output = await agent.execute(tempDir.path);
      final checks = output.data['checks'] as List;
      final licenseCheck = checks.firstWhere(
        (c) => c['id'] == 'license-exists',
      );
      expect(licenseCheck['passed'], isTrue);
    });
  });

  group('execute - project with secrets', () {
    setUp(() {
      createProjectWithSecrets(tempDir);
    });

    test('fails security checks', () async {
      final output = await agent.execute(tempDir.path);
      final checks = output.data['checks'] as List;

      final secretsCheck = checks.firstWhere(
        (c) => c['id'] == 'no-secrets-in-repo',
        orElse: () => {'passed': true},
      );
      expect(secretsCheck['passed'], isFalse);
    });
  });

  group('execute - skeleton project', () {
    setUp(() {
      createSkeletonProject(tempDir);
    });

    test('fails basic checks', () async {
      final output = await agent.execute(tempDir.path);
      expect(output.data['canPublish'], isFalse);
    });
  });

  group('AuditCheck model', () {
    test('creates with required fields', () {
      const check = AuditCheck(
        id: 'test',
        label: 'Test check',
        passed: true,
      );
      expect(check.id, equals('test'));
      expect(check.passed, isTrue);
    });

    test('default severity is required', () {
      const check = AuditCheck(id: 'test', label: 'Test', passed: true);
      expect(check.severity, equals('required'));
    });
  });

  group('agent metadata', () {
    test('has correct agentId', () {
      expect(agent.agentId, equals('auditor'));
    });

    test('has correct inboxStep', () {
      expect(agent.inboxStep, equals('Pasos 3–3.9'));
    });
  });
}
