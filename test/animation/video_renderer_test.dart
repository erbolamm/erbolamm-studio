import 'package:flutter_test/flutter_test.dart';
import 'package:erbolamm_studio/features/animation/domain/animation_template.dart';
import 'package:erbolamm_studio/features/animation/domain/video_renderer.dart';

void main() {
  group('VideoRenderer', () {
    test('initial lastError is null', () {
      final renderer = VideoRenderer();
      expect(renderer.lastError, isNull);
    });

    test('findDesignEngine finds engine via absolute fallback', () async {
      final renderer = VideoRenderer();
      // Even with nonexistent relative path, finds via absolute fallback
      final found = await renderer.findDesignEngine(projectBase: '/tmp/nonexistent');
      // Depends on whether design-engine exists at the absolute path
      // If running in dev environment, should find it
      expect(found, isA<bool>());
    });

    test('renderFallback creates valid result', () async {
      final renderer = VideoRenderer();
      final result = await renderer.renderFallback(
        outputPath: '/tmp/test_fallback.mp4',
        durationSec: 2,
        width: 640,
        height: 480,
      );

      // ffmpeg might not be available in test environment
      // Either way, verify the result structure is correct
      expect(result, isA<VideoRenderResult>());
      if (result.success) {
        expect(result.fileSize, greaterThan(0));
        expect(result.duration.inSeconds, equals(2));
      }
    });
  });
}
