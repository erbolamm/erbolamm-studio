import 'package:flutter_test/flutter_test.dart';
import 'package:erbolamm_studio/features/music/domain/strudel_generator.dart';

void main() {
  group('StrudelGenerator', () {
    test('extractBpm returns 120 for empty description', () {
      expect(StrudelGenerator.extractBpm(''), equals(120));
    });

    test('extractBpm parses explicit BPM', () {
      expect(StrudelGenerator.extractBpm('Funk 80s, 128 BPM'), equals(128));
      expect(StrudelGenerator.extractBpm('120bpm'), equals(120));
      expect(StrudelGenerator.extractBpm('slow 90 BPM'), equals(90));
    });

    test('extractBpm returns 120 when no BPM found', () {
      expect(StrudelGenerator.extractBpm('Ambient piano'), equals(120));
    });

    test('findPreset matches by name', () {
      final preset = StrudelGenerator.findPreset('Funk 80s');
      expect(preset, isNotNull);
      expect(preset!.name, equals('Funk 80s'));
    });

    test('findPreset matches by description keyword', () {
      final preset = StrudelGenerator.findPreset('Electronic beat');
      expect(preset, isNotNull);
      expect(preset!.name, equals('Electronic'));
    });

    test('findPreset returns null for unknown styles', () {
      expect(StrudelGenerator.findPreset('Reggae dub'), isNull);
    });

    test('generate returns valid code for known preset', () {
      final code = StrudelGenerator.generate(
        description: 'Funk 80s',
        projectName: 'test-project',
      );
      expect(code, contains('setCpm'));
      expect(code, contains('Funk 80s'));
      expect(code, contains('test-project'));
      expect(code, contains('supersaw'));
    });

    test('generate returns valid code for unknown style', () {
      final code = StrudelGenerator.generate(
        description: 'Jazz fusion 140 BPM',
        projectName: 'jazz-project',
      );
      expect(code, contains('setCpm(140/4)'));
      expect(code, contains('jazz-project'));
      expect(code, contains('arrange'));
    });

    test('generate with override BPM ignores description BPM', () {
      final code = StrudelGenerator.generate(
        description: 'Slow 80 BPM',
        projectName: 'test',
        overrideBpm: 200,
      );
      expect(code, contains('setCpm(200/4)'));
    });

    test('generate detects fast BPM for electronic patterns', () {
      final code = StrudelGenerator.generate(
        description: 'Hardcore 160 BPM',
        projectName: 'fast',
      );
      expect(code, contains('setCpm(160/4)'));
      // Fast BPM should use electronic preset patterns
      expect(code, anyOf(contains('sawtooth'), contains('square')));
    });
  });

  group('kStylePresets', () {
    test('has 5 presets', () {
      expect(kStylePresets.length, equals(5));
    });

    test('all presets have valid code', () {
      for (final preset in kStylePresets) {
        expect(preset.strudelCode, isNotEmpty);
        expect(preset.strudelCode, contains('arrange'));
      }
    });

    test('all presets have unique names', () {
      final names = kStylePresets.map((p) => p.name).toSet();
      expect(names.length, equals(kStylePresets.length));
    });
  });
}
