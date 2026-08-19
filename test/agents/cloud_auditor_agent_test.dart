// ═══════════════════════════════════════════════════════════════
// 🧪 Tests — Agente 6: Cloud Auditor (actualizado)
// ═══════════════════════════════════════════════════════════════

import 'package:test/test.dart';
import 'package:erbolamm_studio/features/orchestrator/agents/cloud_auditor_agent.dart';

void main() {
  late CloudAuditorAgent agent;

  setUp(() {
    agent = CloudAuditorAgent();
  });

  group('execute', () {
    test('returns output with sections', () async {
      final output = await agent.execute('/test/project');
      expect(output.success, isA<bool>());
      expect(output.data, isA<Map>());
    });

    test('contains firebase section', () async {
      final output = await agent.execute('/test/project');
      expect(output.data.containsKey('firebase'), isTrue);
      expect(output.data['firebase'], isA<Map>());
    });

    test('contains github section', () async {
      final output = await agent.execute('/test/project');
      expect(output.data.containsKey('github'), isTrue);
      expect(output.data['github'], isA<Map>());
    });

    test('contains gcp section', () async {
      final output = await agent.execute('/test/project');
      expect(output.data.containsKey('gcp'), isTrue);
      expect(output.data['gcp'], isA<Map>());
    });

    test('contains universe cross-reference', () async {
      final output = await agent.execute('/test/project');
      expect(output.data.containsKey('universe'), isTrue);
      expect(output.data['universe'], isA<Map>());
    });
  });

  group('agent metadata', () {
    test('has correct agentId', () {
      expect(agent.agentId, equals('cloud-auditor'));
    });

    test('has correct inboxStep', () {
      expect(agent.inboxStep, equals('Paso 6'));
    });
  });
}
