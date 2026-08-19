// ═══════════════════════════════════════════════════════════════
// 🧪 Tests — Agente 2: Clasificador
// ═══════════════════════════════════════════════════════════════

import 'package:test/test.dart';
import 'package:erbolamm_studio/features/orchestrator/agents/classifier_agent.dart';

void main() {
  late ClassifierAgent agent;

  setUp(() {
    agent = ClassifierAgent();
  });

  group('canExecute', () {
    test('returns false when no decision set', () async {
      final result = await agent.canExecute('/any/path');
      expect(result, isFalse);
    });

    test('returns true after decision is set', () async {
      agent.setDecision(decision: ProjectDecision.publish);
      final result = await agent.canExecute('/any/path');
      expect(result, isTrue);
    });
  });

  group('execute - decision labels', () {
    test('publish decision has correct label', () {
      const result = ClassificationResult(
        decision: ProjectDecision.publish,
        summary: 'Test',
      );
      expect(result.decisionLabel, equals('📤 Publicar'));
    });

    test('merge decision has correct label', () {
      const result = ClassificationResult(
        decision: ProjectDecision.merge,
        summary: 'Test',
      );
      expect(result.decisionLabel, equals('🔗 Fusionar'));
    });

    test('discard decision has correct label', () {
      const result = ClassificationResult(
        decision: ProjectDecision.discard,
        summary: 'Test',
      );
      expect(result.decisionLabel, equals('🗑️ Descartar'));
    });

    test('continue decision has correct label', () {
      const result = ClassificationResult(
        decision: ProjectDecision.continue_,
        summary: 'Test',
      );
      expect(result.decisionLabel, equals('🔨 Continuar desarrollo'));
    });

    test('salvage decision has correct label', () {
      const result = ClassificationResult(
        decision: ProjectDecision.salvage,
        summary: 'Test',
      );
      expect(result.decisionLabel, equals('🔧 Aprovechar partes'));
    });
  });

  group('execute - with decision', () {
    test('publish returns success with correct data', () async {
      agent.setDecision(decision: ProjectDecision.publish, notes: 'Test notes');
      final output = await agent.execute('/test/path');
      expect(output.success, isTrue);
      expect(output.data['decision'], contains('Publicar'));
    });

    test('merge includes merge target', () async {
      agent.setDecision(decision: ProjectDecision.merge, mergeTarget: 'other-project');
      final output = await agent.execute('/test/path');
      expect(output.data['mergeTarget'], equals('other-project'));
    });

    test('salvage includes salvage target', () async {
      agent.setDecision(decision: ProjectDecision.salvage, salvageTarget: 'target-project');
      final output = await agent.execute('/test/path');
      expect(output.data['salvageTarget'], equals('target-project'));
    });
  });

  group('requiresApproval', () {
    test('merge requires approval', () {
      const result = ClassificationResult(decision: ProjectDecision.merge, summary: '');
      expect(result.requiresApproval, isTrue);
    });

    test('publish does not require approval', () {
      const result = ClassificationResult(decision: ProjectDecision.publish, summary: '');
      expect(result.requiresApproval, isFalse);
    });
  });

  group('agent metadata', () {
    test('has correct agentId', () {
      expect(agent.agentId, equals('classifier'));
    });

    test('has correct inboxStep', () {
      expect(agent.inboxStep, equals('Paso 2'));
    });
  });
}
