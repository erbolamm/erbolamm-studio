// ═══════════════════════════════════════════════════════════════
// 🎵 Strudel Generator — Genera código Strudel desde descripción
// ═══════════════════════════════════════════════════════════════
// Analiza la descripción del estilo y genera código funcional
// para Tone.js + Strudel (strudel.cc).
// ═══════════════════════════════════════════════════════════════

/// Patrón de estilo pre-definido
class StylePreset {
  final String name;
  final String description;
  final String strudelCode;

  const StylePreset({
    required this.name,
    required this.description,
    required this.strudelCode,
  });
}

/// Códigos Strudel pre-definidos como constantes top-level
const String kStrudelFunk80s = '''
// Pads supersaw
let pads = note("<[c3 eb3 g3 bb3]>")
  .s("supersaw")
  .attack(0.3).release(1)
  .lpf(1200)
  .gain(0.25)

// Bajo slap
let bass = note("c2 ~ c2 c2 ~ g1 ~ c2")
  .s("sawtooth").lpf(500).gain(0.6)

// Batería LinnDrum
let drums = s("bd*4, ~ sd:1 ~ sd:1")
  .bank("LinnDrum").gain(0.9)

// Arreglo
arrange(
  [4, stack(pads, drums)],
  [8, stack(pads, bass, drums)],
  [4, stack(pads, bass, drums)],
  [4, stack(pads, drums)],
)
''';

const String kStrudelElectronic = '''
// Pad principal
let pad = note("<[c4 eb4 g4] [f4 ab4 c5]>")
  .s("sawtooth").attack(0.2).release(0.8)
  .lpf(800).gain(0.3)

// Arpegio
let arp = note("<c4 eb4 g4 bb4>")
  .s("square").attack(0.05).release(0.2)
  .lpf(3000).gain(0.2)
  .slow(2)

// Bajo electrónico
let bass = note("c2 ~ eb2 ~ g2 ~ bb2")
  .s("sawtooth").lpf(400).gain(0.4)

// Batería
let drums = stack(
  s("bd*2").gain(1),
  s("~ sd").gain(0.8),
  s("hh*4").gain(0.3),
)

arrange(
  [4, drums],
  [8, stack(pad, drums)],
  [8, stack(pad, bass, drums, arp)],
  [4, stack(pad, drums)],
)
''';

const String kStrudelAmbient = '''
// Pads texturados
let pad1 = note("<[c3 g3 bb3] [f3 ab3 c4]>")
  .s("sawtooth").attack(2).release(4)
  .lpf(600).gain(0.2)

let pad2 = note("<[eb4 g4 c5] [f4 a4 c5]>")
  .s("sine").attack(3).release(5)
  .gain(0.15)

// Textura
let texture = s("~")
  .add(note("c4").s("sine").attack(1).release(3).gain(0.05))

arrange(
  [4, pad1],
  [8, stack(pad1, pad2)],
  [8, stack(pad1, pad2, texture)],
  [4, texture],
)
''';

const String kStrudelHiphop = '''
// Bombo pesado
let kick = s("bd(3,4,2)").gain(1.2)

// Snare
let snare = s("~ sd(1,2)").gain(0.6)

// Bajo
let bass = note("<c2 ~ eb2 ~>")
  .s("sawtooth").lpf(300).gain(0.3)

// Sample
let sample = s("vinyl").gain(0.15).room(0.3)

arrange(
  [4, stack(kick, snare)],
  [8, stack(kick, snare, sample)],
  [8, stack(kick, snare, bass, sample)],
  [4, stack(kick, snare)],
)
''';

const String kStrudelRock = '''
// Guitarra rítmica
let guitar = note("<[c3 e3 g3] [f3 a3 c4] [g3 b3 d4] [f3 a3 c4]>")
  .s("sawtooth").gain(0.3).lpf(2000)

// Bajo
let bass = note("c2 ~ f2 ~ g2 ~ f2")
  .s("triangle").gain(0.4)

// Batería
let drums = stack(
  s("bd(3,4)").gain(0.9),
  s("~ sd(1,2)").gain(0.6),
  s("hh(7,8)").gain(0.2),
)

arrange(
  [4, drums],
  [8, stack(guitar, drums)],
  [8, stack(guitar, bass, drums)],
  [4, drums],
)
''';

/// Biblioteca de estilos predefinidos
const List<StylePreset> kStylePresets = [
  StylePreset(
    name: 'Funk 80s',
    description:
        'Funk 80s, 120 BPM, bajo slap, pads supersaw, batería LinnDrum',
    strudelCode: kStrudelFunk80s,
  ),
  StylePreset(
    name: 'Electronic',
    description: 'Electronic, 128 BPM, sintetizadores, beats electrónicos',
    strudelCode: kStrudelElectronic,
  ),
  StylePreset(
    name: 'Ambient',
    description: 'Ambient, 80 BPM, pads, texturas, lento',
    strudelCode: kStrudelAmbient,
  ),
  StylePreset(
    name: 'Hip Hop',
    description: 'Hip Hop, 90 BPM, bombo pesado, sampleo, vinilo',
    strudelCode: kStrudelHiphop,
  ),
  StylePreset(
    name: 'Rock',
    description: 'Rock, 140 BPM, guitarras, batería en vivo',
    strudelCode: kStrudelRock,
  ),
];

class StrudelGenerator {
  /// Extrae BPM de una descripción
  static int extractBpm(String description) {
    final match = RegExp(
      r'(\d+)\s*BPM',
      caseSensitive: false,
    ).firstMatch(description);
    if (match != null) return int.tryParse(match.group(1) ?? '120') ?? 120;
    return 120;
  }

  /// Auto-selecciona el estilo musical según el tipo de proyecto.
  static StylePreset presetForProjectType(String? projectType) {
    switch (projectType?.toLowerCase()) {
      case 'app':
      case 'flutter':
        return kStylePresets[0]; // Funk 80s
      case 'extension':
        return kStylePresets[1]; // Electronic
      case 'website':
      case 'web':
        return kStylePresets[2]; // Ambient
      case 'package':
        return kStylePresets[3]; // Hip Hop
      case 'workflow':
        return kStylePresets[4]; // Rock
      default:
        return kStylePresets[0]; // Funk 80s default
    }
  }

  /// Encuentra un preset por nombre o descripción.
  static StylePreset? findPreset(String description) {
    final lower = description.toLowerCase();
    for (final preset in kStylePresets) {
      if (lower.contains(preset.name.toLowerCase()) ||
          lower.contains(
            preset.description.toLowerCase().split(',').first.trim(),
          )) {
        return preset;
      }
    }
    return null;
  }

  /// Genera código Strudel a partir de una descripción
  static String generate({
    required String description,
    required String projectName,
    int? overrideBpm,
  }) {
    final bpm = overrideBpm ?? extractBpm(description);
    final preset = findPreset(description);

    if (preset != null) {
      return _wrapCode(preset.strudelCode, description, bpm, projectName);
    }

    // Generación dinámica básica
    final isFast = bpm >= 130;
    final isSlow = bpm <= 90;
    final hasBass =
        description.toLowerCase().contains('bajo') ||
        description.toLowerCase().contains('bass');
    final hasDrums =
        description.toLowerCase().contains('bater') ||
        description.toLowerCase().contains('drums') ||
        description.toLowerCase().contains('beat');

    String pattern;
    if (isSlow) {
      pattern = kStrudelAmbient;
    } else if (isFast) {
      pattern = kStrudelElectronic;
    } else {
      pattern = hasBass
          ? kStrudelFunk80s
          : (hasDrums ? kStrudelHiphop : kStrudelRock);
    }

    return _wrapCode(pattern, description, bpm, projectName);
  }

  static String _wrapCode(
    String code,
    String description,
    int bpm,
    String projectName,
  ) {
    return '''// ─────────────────────────────────────────────────────────────
// Estilo: $description — $bpm BPM
// Generado para: $projectName
// Motor: Strudel (strudel.cc)
// ─────────────────────────────────────────────────────────────

setCpm($bpm/4)

$code''';
  }
}
