import 'package:flutter_test/flutter_test.dart';
import 'package:erbolamm_studio/features/publisher/domain/media_mixer.dart';

void main() {
  group('PlatformFormat', () {
    test('all formats have correct aspect ratios', () {
      for (final format in kPlatformFormats) {
        final expectedAspect = format.width / format.height;
        expect(format.aspectRatio, closeTo(expectedAspect, 0.01));
      }
    });

    test('vertical formats are taller than wide', () {
      for (final format in kPlatformFormats) {
        if (format.suffix == 'vertical') {
          expect(format.height, greaterThan(format.width));
        }
      }
    });

    test('horizontal formats are wider than tall', () {
      for (final format in kPlatformFormats) {
        if (format.suffix == 'horizontal') {
          expect(format.width, greaterThan(format.height));
        }
      }
    });

    test('has 6 platform formats', () {
      expect(kPlatformFormats.length, equals(6));
    });

    test('each format has unique name', () {
      final names = kPlatformFormats.map((f) => f.name).toSet();
      expect(names.length, equals(kPlatformFormats.length));
    });
  });

  group('Match Result', () {
    test('creates success result', () {
      final result = MixResult(
        outputPath: '/tmp/test.mp4',
        fileSize: 1024,
        duration: const Duration(seconds: 30),
        success: true,
      );
      expect(result.success, isTrue);
      expect(result.fileSize, equals(1024));
    });

    test('creates error result with message', () {
      final result = MixResult(
        outputPath: '/tmp/test.mp4',
        fileSize: 0,
        duration: Duration.zero,
        success: false,
        error: 'ffmpeg not found',
      );
      expect(result.success, isFalse);
      expect(result.error, equals('ffmpeg not found'));
    });
  });

  group('MediaMixer', () {
    test('checkAvailability returns bool', () async {
      final mixer = MediaMixer();
      final result = await mixer.checkAvailability();
      expect(result, isA<bool>());
    });
  });
}
