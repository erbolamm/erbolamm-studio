import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:erbolamm_studio/models/pipeline_progress.dart';
import 'package:erbolamm_studio/services/project_monitor.dart';

void main() {
  group('PipelineProgress & ProjectMonitor Tests', () {
    late Directory tempDir;
    late Directory inboxDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('project_monitor_test_');
      inboxDir = Directory(p.join(tempDir.path, 'INBOX'))..createSync();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Empty INBOX returns empty availableProjects and default progress', () {
      final monitor = ProjectMonitor(basePath: tempDir.path);
      expect(monitor.hasProject, isFalse);
      expect(monitor.availableProjects, isEmpty);
      expect(monitor.projectName, isNull);
      expect(monitor.progress.analyzer, ModuleStatus.pending);
    });

    test('Multiple projects in INBOX are detected and selectable', () {
      final proj1 = Directory(p.join(inboxDir.path, 'app_alpha'))..createSync();
      final proj2 = Directory(p.join(inboxDir.path, 'app_beta'))..createSync();

      // Create basic structure for app_alpha
      File(p.join(proj1.path, 'README.md')).writeAsStringSync('# Alpha');
      File(p.join(proj1.path, 'LICENSE')).writeAsStringSync('MIT');

      final monitor = ProjectMonitor(basePath: tempDir.path);
      expect(monitor.hasProject, isTrue);
      expect(monitor.availableProjects, ['app_alpha', 'app_beta']);
      expect(monitor.projectName, 'app_alpha');

      // Check evaluation for app_alpha
      final progressAlpha = monitor.progress;
      expect(progressAlpha.analyzer, ModuleStatus.completed);
      expect(progressAlpha.orchestrator, ModuleStatus.pending);

      // Switch to app_beta
      var notified = false;
      monitor.addListener(() => notified = true);
      monitor.selectProject('app_beta');

      expect(notified, isTrue);
      expect(monitor.projectName, 'app_beta');
      expect(monitor.projectPath, proj2.path);
      expect(monitor.progress.analyzer, ModuleStatus.pending);
    });

    test('PipelineProgress detects completed promo and video assets', () {
      final proj = Directory(p.join(inboxDir.path, 'completed_app'))..createSync();
      File(p.join(proj.path, 'README.md')).writeAsStringSync('# Test');
      File(p.join(proj.path, 'LICENSE')).writeAsStringSync('MIT');

      final promo = Directory(p.join(proj.path, 'promo'))..createSync();
      File(p.join(promo.path, 'brand-spec.md')).writeAsStringSync('# Brand');
      File(p.join(promo.path, 'copy-pack.md')).writeAsStringSync('# Copy');
      File(p.join(promo.path, 'landing.html')).writeAsStringSync('<html></html>');

      final audioDir = Directory(p.join(promo.path, 'audio'))..createSync();
      File(p.join(audioDir.path, 'narration_es.wav')).writeAsStringSync('audio');
      File(p.join(audioDir.path, 'bg_music.mp3')).writeAsStringSync('music');

      final videoDir = Directory(p.join(promo.path, 'videos'))..createSync();
      File(p.join(videoDir.path, 'promo_vertical.mp4')).writeAsStringSync('video');

      final screenDir = Directory(p.join(promo.path, 'screenshots'))..createSync();
      File(p.join(screenDir.path, 'screen1.png')).writeAsStringSync('img');

      final progress = PipelineProgress.evaluate(proj.path);
      expect(progress.analyzer, ModuleStatus.completed);
      expect(progress.orchestrator, ModuleStatus.completed);
      expect(progress.voice, ModuleStatus.completed);
      expect(progress.market, ModuleStatus.completed);
      expect(progress.music, ModuleStatus.completed);
      expect(progress.animation, ModuleStatus.completed);
      expect(progress.publisher, ModuleStatus.completed);
    });

    test('PipelineProgress detects completed erbolamm-studio assets', () {
      final proj = Directory(p.join(inboxDir.path, 'completed_studio_app'))..createSync();
      File(p.join(proj.path, 'README.md')).writeAsStringSync('# Test');
      File(p.join(proj.path, 'LICENSE')).writeAsStringSync('MIT');

      final studio = Directory(p.join(proj.path, 'erbolamm-studio'))..createSync();
      File(p.join(studio.path, 'brand-spec.md')).writeAsStringSync('# Brand');
      File(p.join(studio.path, 'copy-pack.md')).writeAsStringSync('# Copy');
      File(p.join(studio.path, 'landing.html')).writeAsStringSync('<html></html>');

      final audioDir = Directory(p.join(studio.path, 'audio'))..createSync();
      File(p.join(audioDir.path, 'background.wav')).writeAsStringSync('audio');

      final videoDir = Directory(p.join(studio.path, 'videos'))..createSync();
      File(p.join(videoDir.path, 'promo-vertical.mp4')).writeAsStringSync('video');

      final screenDir = Directory(p.join(studio.path, 'screenshots'))..createSync();
      File(p.join(screenDir.path, 'screen1.png')).writeAsStringSync('img');

      final progress = PipelineProgress.evaluate(proj.path);
      expect(progress.analyzer, ModuleStatus.completed);
      expect(progress.orchestrator, ModuleStatus.completed);
      expect(progress.voice, ModuleStatus.completed);
      expect(progress.market, ModuleStatus.completed);
      expect(progress.music, ModuleStatus.completed);
      expect(progress.animation, ModuleStatus.completed);
      expect(progress.publisher, ModuleStatus.completed);
    });

    test('Custom project path outside INBOX is supported and monitored', () {
      final externalProj = Directory(p.join(tempDir.path, 'external_app'))..createSync();
      File(p.join(externalProj.path, 'README.md')).writeAsStringSync('# External');
      File(p.join(externalProj.path, 'LICENSE')).writeAsStringSync('MIT');

      final monitor = ProjectMonitor(basePath: tempDir.path);
      monitor.setCustomProjectPath(externalProj.path);

      expect(monitor.hasProject, isTrue);
      expect(monitor.projectName, 'external_app');
      expect(monitor.projectPath, externalProj.path);
      expect(monitor.availableProjects, contains('external_app'));
      expect(monitor.progress.analyzer, ModuleStatus.completed);
    });
  });
}
