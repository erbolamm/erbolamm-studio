import 'package:flutter_test/flutter_test.dart';
import 'package:erbolamm_studio/features/animation/domain/animation_template.dart';

void main() {
  group('AnimationTemplate', () {
    test('has 3 templates', () {
      expect(kAnimationTemplates.length, equals(3));
    });

    test('vertical template has correct dimensions', () {
      final vertical = kAnimationTemplates[0];
      expect(vertical.id, equals('vertical-promo'));
      expect(vertical.width, equals(1080));
      expect(vertical.height, equals(1920));
      expect(vertical.suffix, equals('vertical'));
    });

    test('horizontal template has correct dimensions', () {
      final horizontal = kAnimationTemplates[1];
      expect(horizontal.id, equals('horizontal-promo'));
      expect(horizontal.width, equals(1920));
      expect(horizontal.height, equals(1080));
      expect(horizontal.suffix, equals('horizontal'));
    });

    test('screenshots template is horizontal', () {
      final screenshots = kAnimationTemplates[2];
      expect(screenshots.id, equals('screenshots'));
      expect(screenshots.width, greaterThan(screenshots.height));
    });

    test('default durations are positive', () {
      for (final template in kAnimationTemplates) {
        expect(template.defaultDurationSec, greaterThan(0));
      }
    });

    test('resolution string', () {
      expect(kAnimationTemplates[0].resolution, equals('1080x1920'));
      expect(kAnimationTemplates[1].resolution, equals('1920x1080'));
    });
  });

  group('VideoRenderResult', () {
    test('creates success result', () {
      final result = VideoRenderResult(
        outputPath: '/tmp/promo.mp4',
        fileSize: 500000,
        duration: const Duration(seconds: 30),
        success: true,
      );
      expect(result.success, isTrue);
      expect(result.fileSize, equals(500000));
    });

    test('creates error result', () {
      final result = VideoRenderResult(
        outputPath: '',
        fileSize: 0,
        duration: Duration.zero,
        success: false,
        error: 'Playwright not found',
      );
      expect(result.success, isFalse);
      expect(result.error, equals('Playwright not found'));
    });
  });

  group('ProjectTemplate', () {
    test('creates with template and status', () {
      final pt = ProjectTemplate(
        template: kAnimationTemplates[0],
        htmlExists: true,
        htmlPath: '/tmp/source/vertical-promo.html',
      );
      expect(pt.htmlExists, isTrue);
      expect(pt.htmlPath, isNotNull);
      expect(pt.videoPath, isNull);
    });
  });
}
