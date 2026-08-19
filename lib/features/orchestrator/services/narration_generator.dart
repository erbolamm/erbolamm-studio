import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import '../../../core/logging/app_logger.dart';

import '../../voice/data/mmx_voice_service.dart';
import '../../voice/data/voice_clone_service.dart';

// ═══════════════════════════════════════════════════════════════
// 🎙️ NarrationGenerator — Voz multi-idioma con mmx
// ═══════════════════════════════════════════════════════════════
// Lee narration.json y genera archivos WAV reales usando
// mmx speech synthesize con voces predefinidas por idioma.
// ═══════════════════════════════════════════════════════════════

/// Voces por idioma (se pueden personalizar)
const kDefaultVoices = <String, String>{
  'es': 'Spanish_Narrator',
  'en': 'English_expressive_narrator',
  'pt': 'Portuguese_Narrator',
  'fr': 'French_Male_Speech_New',
  'de': 'German_FriendlyMan',
  'it': 'Italian_Narrator',
};

/// Resultado de generación de narración para un idioma.
class NarrationResult {
  final String language;
  final String filePath;
  final bool success;
  final String? error;

  const NarrationResult({
    required this.language,
    required this.filePath,
    required this.success,
    this.error,
  });
}

/// Resultado global de la generación de narraciones.
class NarrationGenerationResult {
  final List<NarrationResult> results;
  final int totalLanguages;
  final int successCount;

  const NarrationGenerationResult({
    required this.results,
    required this.totalLanguages,
    required this.successCount,
  });

  bool get allSucceeded => successCount == totalLanguages;
}

/// Genera archivos de audio WAV a partir de narration.json usando mmx.
class NarrationGenerator {
  /// Verifica que mmx esté disponible.
  static Future<bool> isAvailable() async {
    final check = await MmxVoiceService.checkAvailability();
    return check.mmxAvailable;
  }

  /// Genera narraciones para todos los idiomas en narration.json.
  ///
  /// [projectPath] — raíz del proyecto (contiene promo/narration.json).
  /// [customVoices] — mapa opcional de idioma → nombre de voz mmx.
  /// Si no se provee, usa [kDefaultVoices].
  static Future<NarrationGenerationResult> generateAll({
    required String projectPath,
    Map<String, String>? customVoices,
  }) async {
    final voices = customVoices ?? kDefaultVoices;

    // Si hay una voz clonada del usuario, usarla para todos los idiomas
    String? clonedVoiceId;
    try {
      final clonedVoices = await VoiceCloneService.listVoices();
      if (clonedVoices.isNotEmpty) {
        clonedVoiceId = clonedVoices.first.voiceId;
        AppLogger.i(
          '[NarrationGenerator] 🎙️ Usando voz clonada: $clonedVoiceId',
        );
      }
    } catch (_) {}
    final narrationPath = p.join(projectPath, 'erbolamm-studio', 'narration.json');
    final narrationFile = File(narrationPath);

    if (!narrationFile.existsSync()) {
      return NarrationGenerationResult(
        results: [],
        totalLanguages: 0,
        successCount: 0,
      );
    }

    // Leer textos por idioma
    Map<String, String> texts;
    try {
      texts = Map<String, String>.from(
        jsonDecode(narrationFile.readAsStringSync()) as Map,
      );
    } catch (e) {
      AppLogger.i('[NarrationGenerator] Error leyendo narration.json: $e');
      return NarrationGenerationResult(
        results: [],
        totalLanguages: 0,
        successCount: 0,
      );
    }

    final outDir = p.join(projectPath, 'erbolamm-studio', 'narration');
    Directory(outDir).createSync(recursive: true);

    final results = <NarrationResult>[];
    int successCount = 0;

    for (final entry in texts.entries) {
      final lang = entry.key;
      final text = entry.value;
      final voice = voices[lang];

      if (voice == null) {
        AppLogger.i('[NarrationGenerator] Sin voz para $lang, saltando');
        continue;
      }

      AppLogger.i('[NarrationGenerator] Generando narración $lang...');

      final langDir = p.join(outDir, lang);
      Directory(langDir).createSync(recursive: true);

      try {
        final track = await MmxVoiceService.generateNarration(
          text: text,
          language: lang,
          customVoice: clonedVoiceId ?? voice,
          outputDir: langDir,
        );

        if (track != null) {
          results.add(
            NarrationResult(
              language: lang,
              filePath: track.filePath,
              success: true,
            ),
          );
          successCount++;
          AppLogger.i(
            '[NarrationGenerator] ✅ $lang: ${track.filePath} '
            '(${(track.fileSize / 1024).toStringAsFixed(0)}KB)',
          );
        } else {
          results.add(
            NarrationResult(
              language: lang,
              filePath: '',
              success: false,
              error: 'mmx speech synthesize falló',
            ),
          );
          AppLogger.i('[NarrationGenerator] ❌ $lang: falló');
        }
      } catch (e) {
        results.add(
          NarrationResult(
            language: lang,
            filePath: '',
            success: false,
            error: e.toString(),
          ),
        );
        AppLogger.i('[NarrationGenerator] ❌ $lang: $e');
      }
    }

    return NarrationGenerationResult(
      results: results,
      totalLanguages: texts.length,
      successCount: successCount,
    );
  }

  /// Genera narración para un solo idioma.
  static Future<NarrationResult?> generateOne({
    required String projectPath,
    required String language,
    required String text,
    String? customVoice,
  }) async {
    final voice = customVoice ?? kDefaultVoices[language];
    if (voice == null) return null;

    final outDir = p.join(projectPath, 'erbolamm-studio', 'narration', language);
    Directory(outDir).createSync(recursive: true);

    try {
      final track = await MmxVoiceService.generateNarration(
        text: text,
        language: language,
        customVoice: voice,
        outputDir: outDir,
      );

      if (track != null) {
        return NarrationResult(
          language: language,
          filePath: track.filePath,
          success: true,
        );
      }
    } catch (e) {
      AppLogger.i('[NarrationGenerator] Error $language: $e');
    }

    return NarrationResult(
      language: language,
      filePath: '',
      success: false,
      error: 'Falló la generación',
    );
  }
}
