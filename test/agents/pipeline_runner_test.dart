// ═══════════════════════════════════════════════════════════════
// 🧪 Tests — PipelineRunner & Orquestación
// ═══════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:erbolamm_studio/features/orchestrator/domain/agent_interface.dart';
import 'package:erbolamm_studio/features/orchestrator/orchestration/pipeline_runner.dart';
import '../fixtures/project_fixtures.dart';

class _MockSuccessAgent implements AgentInterface {
  @override
  final String agentId;
  @override
  final String agentName;
  @override
  final String inboxStep;

  _MockSuccessAgent(this.agentId, this.agentName, this.inboxStep);

  @override
  Future<bool> canExecute(String projectPath) async => true;

  @override
  Future<AgentOutput> execute(String projectPath) async {
    return AgentOutput(
      agentId: agentId,
      success: true,
      summary: '$agentName completado con éxito',
      data: {'step': inboxStep},
    );
  }
}

class _MockFailingAgent implements AgentInterface {
  @override
  final String agentId = 'failing-agent';
  @override
  final String agentName = 'Agente Fallido';
  @override
  final String inboxStep = 'Paso X';

  @override
  Future<bool> canExecute(String projectPath) async => true;

  @override
  Future<AgentOutput> execute(String projectPath) async {
    return AgentOutput(
      agentId: agentId,
      success: false,
      summary: 'Fallo simulado',
      error: 'Error de prueba',
    );
  }
}

class _MockUnavailableAgent implements AgentInterface {
  @override
  final String agentId = 'unavail-agent';
  @override
  final String agentName = 'Agente No Disponible';
  @override
  final String inboxStep = 'Paso Y';

  @override
  Future<bool> canExecute(String projectPath) async => false;

  @override
  Future<AgentOutput> execute(String projectPath) async {
    throw UnimplementedError();
  }
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pipeline_runner_test_');
    createFlutterProject(tempDir);
  });

  tearDown(() {
    cleanTempDir(tempDir);
  });

  group('PipelineRunner', () {
    test('creates with default agents', () {
      final runner = PipelineRunner(projectPath: tempDir.path);
      expect(runner.isRunning, isFalse);
    });

    test('executes custom sequential agents and reports progress', () async {
      final agent1 = _MockSuccessAgent('agent-1', 'Agente 1', 'Paso 1');
      final agent2 = _MockSuccessAgent('agent-2', 'Agente 2', 'Paso 2');

      final runner = PipelineRunner.withAgents(
        projectPath: tempDir.path,
        agents: [agent1, agent2],
      );

      final started = <String>[];
      final finished = <String>[];

      runner.setCallbacks(
        onStart: (id) => started.add(id),
        onDone: (id, success, summary, error) {
          if (success) finished.add(id);
        },
      );

      final result = await runner.runAll();

      expect(result.allSucceeded, isTrue);
      expect(result.agentResults.length, equals(2));
      expect(started, equals(['agent-1', 'agent-2']));
      expect(finished, equals(['agent-1', 'agent-2']));
      expect(runner.isRunning, isFalse);
    });

    test('handles failing agent gracefully and continues', () async {
      final agent1 = _MockSuccessAgent('agent-1', 'Agente 1', 'Paso 1');
      final failingAgent = _MockFailingAgent();
      final agent2 = _MockSuccessAgent('agent-2', 'Agente 2', 'Paso 2');

      final runner = PipelineRunner.withAgents(
        projectPath: tempDir.path,
        agents: [agent1, failingAgent, agent2],
      );

      final result = await runner.runAll();

      expect(result.allSucceeded, isFalse);
      expect(result.agentResults.length, equals(3));
      expect(result.agentResults[0].success, isTrue);
      expect(result.agentResults[1].success, isFalse);
      expect(result.agentResults[2].success, isTrue);
    });

    test('records skip/failure when canExecute is false', () async {
      final unavail = _MockUnavailableAgent();
      final runner = PipelineRunner.withAgents(
        projectPath: tempDir.path,
        agents: [unavail],
      );

      final result = await runner.runAll();

      expect(result.allSucceeded, isFalse);
      expect(result.agentResults.first.success, isFalse);
      expect(result.agentResults.first.summary, contains('no puede ejecutarse'));
    });
  });
}
