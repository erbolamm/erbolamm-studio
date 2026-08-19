import 'package:flutter_test/flutter_test.dart';
import 'package:erbolamm_studio/features/publisher/domain/publisher_service.dart';

void main() {
  group('PipelineStep', () {
    test('initial status is pending', () {
      final step = PipelineStep(
        id: 'test',
        title: 'Test step',
        subtitle: 'A test',
      );
      expect(step.status, equals(PipelineStepStatus.pending));
      expect(step.duration, isNull);
    });

    test('duration is null before start', () {
      final step = PipelineStep(
        id: 'test',
        title: 'Test',
        subtitle: '',
      );
      expect(step.duration, isNull);
      expect(step.startedAt, isNull);
    });
  });

  group('ExportResult', () {
    test('creates success result', () {
      final result = ExportResult(
        platform: 'tiktok',
        filePath: '/tmp/promo-vertical.mp4',
        success: true,
        fileSize: 2048,
        duration: const Duration(seconds: 22),
      );
      expect(result.success, isTrue);
      expect(result.platform, equals('tiktok'));
      expect(result.duration.inSeconds, equals(22));
    });

    test('creates failure result', () {
      final result = ExportResult(
        platform: 'youtube',
        filePath: '',
        success: false,
        fileSize: 0,
        duration: Duration.zero,
        error: 'Render failed',
      );
      expect(result.success, isFalse);
      expect(result.error, equals('Render failed'));
    });
  });

  group('PublisherService', () {
    test('creates with project path', () {
      final service = PublisherService(projectPath: '/tmp/test-project');
      expect(service.steps.length, equals(5));
      expect(service.steps[0].id, equals('audio'));
      expect(service.steps[4].id, equals('export'));
    });

    test('checkAssets returns map with defaults', () async {
      final service = PublisherService(projectPath: '/tmp/nonexistent-project');
      final assets = await service.checkAssets();
      expect(assets, containsPair('audio', false));
      expect(assets, containsPair('video', false));
      expect(assets, containsPair('narration', false));
      expect(assets, containsPair('videosPromo', false));
    });

    test('findAssetPaths returns nulls for nonexistent project', () async {
      final service = PublisherService(projectPath: '/tmp/nonexistent-project');
      final paths = await service.findAssetPaths();
      expect(paths['video'], isNull);
      expect(paths['audio'], isNull);
      expect(paths['narration'], isNull);
    });

    test('getAvailableLanguages returns empty for no narration', () async {
      final service = PublisherService(projectPath: '/tmp/nonexistent-project');
      final langs = await service.getAvailableLanguages();
      expect(langs, isEmpty);
    });
  });
}
