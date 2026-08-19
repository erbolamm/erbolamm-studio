import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../../../core/logging/app_logger.dart';

// ═══════════════════════════════════════════════════════════════
// 🎙️ VoiceCloneService — Clona tu voz con Minimax API
// ═══════════════════════════════════════════════════════════════
// Flujo: grabar muestras → subir a Minimax → obtener voice_id
// → usar voice_id en mmx speech synthesize para narraciones.
// ═══════════════════════════════════════════════════════════════

const _apiBase = 'https://api.minimax.io/v1';

/// Voz clonada registrada en Minimax.
class ClonedVoice {
  final String voiceId;
  final String displayName;
  final DateTime createdAt;

  const ClonedVoice({
    required this.voiceId,
    required this.displayName,
    required this.createdAt,
  });

  factory ClonedVoice.fromJson(Map<String, dynamic> json) {
    return ClonedVoice(
      voiceId: json['voice_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Mi voz',
      createdAt:
          DateTime.tryParse(json['create_time']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class VoiceCloneService {
  /// Lee el token OAuth de la config de mmx.
  static Future<String?> _getAccessToken() async {
    try {
      final configFile = File(
        '${Platform.environment['HOME']}/.mmx/config.json',
      );
      if (!configFile.existsSync()) return null;
      final json = jsonDecode(configFile.readAsStringSync()) as Map;
      return json['oauth']?['access_token']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Sube un archivo de audio a Minimax y devuelve el file_id.
  static Future<String?> _uploadAudio(String filePath) async {
    final token = await _getAccessToken();
    if (token == null) return null;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiBase/files/upload'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['purpose'] = 'voice_clone';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body) as Map;

      if (response.statusCode == 200) {
        return json['file']?['file_id']?.toString();
      }
      AppLogger.i('[VoiceClone] Upload failed: $body');
    } catch (e) {
      AppLogger.i('[VoiceClone] Upload error: $e');
    }
    return null;
  }

  /// Clona una voz a partir de un archivo de audio.
  ///
  /// [audioPath] — ruta al archivo WAV/MP3 con la muestra de voz.
  /// [voiceName] — nombre para la voz clonada.
  /// Retorna el [ClonedVoice] con el voice_id.
  static Future<ClonedVoice?> cloneVoice({
    required String audioPath,
    String voiceName = 'Mi Voz',
  }) async {
    final token = await _getAccessToken();
    if (token == null) return null;

    // Paso 1: subir audio
    final fileId = await _uploadAudio(audioPath);
    if (fileId == null) return null;

    // Paso 2: clonar voz
    try {
      final response = await http
          .post(
            Uri.parse('$_apiBase/voice-clone/clone'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'file_id': fileId,
              'voice_id': 'erbolamm_${DateTime.now().millisecondsSinceEpoch}',
              'display_name': voiceName,
              'language_boost': 'Spanish',
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map;
        final voiceId = json['voice_id']?.toString();
        if (voiceId != null) {
          AppLogger.i('[VoiceClone] ✅ Voz clonada: $voiceId');
          return ClonedVoice(
            voiceId: voiceId,
            displayName: voiceName,
            createdAt: DateTime.now(),
          );
        }
      }
      AppLogger.i('[VoiceClone] Clone failed: ${response.body}');
    } catch (e) {
      AppLogger.i('[VoiceClone] Clone error: $e');
    }
    return null;
  }

  /// Lista las voces clonadas del usuario.
  static Future<List<ClonedVoice>> listVoices() async {
    final token = await _getAccessToken();
    if (token == null) return [];

    try {
      final response = await http
          .get(
            Uri.parse('$_apiBase/voice-clone/list'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map;
        final voices = (json['voices'] as List?) ?? [];
        return voices
            .whereType<Map>()
            .map((v) => ClonedVoice.fromJson(v as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      AppLogger.i('[VoiceClone] List error: $e');
    }
    return [];
  }

  /// Verifica si el servicio está disponible (mmx auth config existe).
  static Future<bool> isAvailable() async {
    return await _getAccessToken() != null;
  }
}
