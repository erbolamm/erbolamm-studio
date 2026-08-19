import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/logging/app_logger.dart';

enum ProviderType {
  apiKey,     // Requiere API key / Token
  oauth,      // OAuth
}

class AIProvider {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int color;
  final String authUrl;
  final String tokenUrl;
  final String clientId;
  final String scope;
  final ProviderType type;
  final String? apiKeyEnvVar; // Variable de entorno para API key (ej: MINIMAX_API_KEY)
  final String? portalUrl;    // URL para obtener la API key en el dashboard

  const AIProvider({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.color,
    this.authUrl = '',
    this.tokenUrl = '',
    this.clientId = '',
    this.scope = '',
    this.type = ProviderType.apiKey,
    this.apiKeyEnvVar,
    this.portalUrl,
  });
}

class AIProvidersService {
  static final AIProvidersService instance = AIProvidersService._();

  AIProvidersService._();

  final _secure = const FlutterSecureStorage(
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // ─── Catálogo de proveedores oficiales ────────────────────────

  static const List<AIProvider> providers = [
    AIProvider(
      id: 'deepseek',
      name: 'DeepSeek',
      description: 'API Oficial — DeepSeek-V3 & DeepSeek-R1 (Reasoning)',
      emoji: '🐋',
      color: 0xFF0D6EFD,
      apiKeyEnvVar: 'DEEPSEEK_API_KEY',
      portalUrl: 'https://platform.deepseek.com/api_keys',
      type: ProviderType.apiKey,
    ),
    AIProvider(
      id: 'minimax_io',
      name: 'MiniMax.io',
      description: 'API Global Oficial — M2.7, TTS, Voice Clone, Música',
      emoji: '🌐',
      color: 0xFF6366F1,
      apiKeyEnvVar: 'MINIMAX_API_KEY',
      portalUrl: 'https://intl.minimaxi.com/user-center/basic-information/interface-key',
      type: ProviderType.apiKey,
    ),
    AIProvider(
      id: 'anthropic',
      name: 'Anthropic',
      description: 'API Oficial — Claude 3.5 Sonnet & Claude 3.7',
      emoji: '🤖',
      color: 0xFF7C3AED,
      apiKeyEnvVar: 'ANTHROPIC_API_KEY',
      portalUrl: 'https://console.anthropic.com/settings/keys',
      type: ProviderType.apiKey,
    ),
    AIProvider(
      id: 'openai',
      name: 'OpenAI',
      description: 'API Oficial — GPT-4o, o3-mini, Embeddings',
      emoji: '🧠',
      color: 0xFF10B981,
      apiKeyEnvVar: 'OPENAI_API_KEY',
      portalUrl: 'https://platform.openai.com/api-keys',
      type: ProviderType.apiKey,
    ),
    AIProvider(
      id: 'gemini',
      name: 'Google Gemini',
      description: 'API Oficial — Gemini 2.0 Flash / Pro & Multimodal',
      emoji: '✨',
      color: 0xFF4285F4,
      apiKeyEnvVar: 'GEMINI_API_KEY',
      portalUrl: 'https://aistudio.google.com/app/apikey',
      type: ProviderType.apiKey,
    ),
    AIProvider(
      id: 'groq',
      name: 'Groq',
      description: 'Inferencia ultra rápida — DeepSeek-R1 & Llama 3.3',
      emoji: '⚡',
      color: 0xFFFF5722,
      apiKeyEnvVar: 'GROQ_API_KEY',
      portalUrl: 'https://console.groq.com/keys',
      type: ProviderType.apiKey,
    ),
    AIProvider(
      id: 'nvidia_nim',
      name: 'NVIDIA NIM (Build)',
      description: 'NVIDIA Inferencia Oficial — DeepSeek-R1 & Nemotron',
      emoji: '🟢',
      color: 0xFF76B900,
      apiKeyEnvVar: 'NVIDIA_API_KEY',
      portalUrl: 'https://build.nvidia.com',
      type: ProviderType.apiKey,
    ),
    AIProvider(
      id: 'minimax_cn',
      name: 'MiniMax.com',
      description: 'API China Oficial — Mainland access',
      emoji: '🇨🇳',
      color: 0xFFE53935,
      apiKeyEnvVar: 'MINIMAX_CN_API_KEY',
      portalUrl: 'https://platform.minimaxi.com/user-center/basic-information/interface-key',
      type: ProviderType.apiKey,
    ),
    AIProvider(
      id: 'github_api',
      name: 'GitHub API',
      description: 'Personal Access Token — Repos, Git Trees & Universo',
      emoji: '💻',
      color: 0xFF6E40C9,
      apiKeyEnvVar: 'GITHUB_TOKEN',
      portalUrl: 'https://github.com/settings/tokens',
      type: ProviderType.apiKey,
    ),
  ];

  // ─── Keys de almacenamiento ─────────────────────────────────

  String _key(String providerId, String field) =>
      'provider_${providerId}_$field';

  Future<void> _writeStorage(String key, String value) async {
    try {
      await _secure.write(key: key, value: value);
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sec_$key', value);
      } catch (e, st) {
        AppLogger.e('Error writing storage for key $key', e, st, 'AIProvidersService');
      }
    }
  }

  Future<String?> _readStorage(String key) async {
    try {
      final val = await _secure.read(key: key);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('sec_$key');
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteStorage(String key) async {
    try {
      await _secure.delete(key: key);
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sec_$key');
    } catch (_) {}
  }

  // ─── Guardar API Key ────────────────────────────────────────

  Future<void> saveApiKey(String providerId, String apiKey) async {
    await _writeStorage(_key(providerId, 'api_key'), apiKey);
    await _writeStorage(
      _key(providerId, 'connected'),
      DateTime.now().toIso8601String(),
    );
  }

  Future<String?> getApiKey(String providerId) async {
    final stored = await _readStorage(_key(providerId, 'api_key'));
    if (stored != null && stored.isNotEmpty) return stored;

    // Buscar en variables de entorno correspondientes
    final provider = providers.firstWhere(
      (p) => p.id == providerId,
      orElse: () => providers.first,
    );

    if (provider.apiKeyEnvVar != null) {
      final envVal = Platform.environment[provider.apiKeyEnvVar!];
      if (envVal != null && envVal.isNotEmpty) return envVal;
    }

    if (providerId == 'github_copilot') {
      final ghEnv = Platform.environment['GH_TOKEN'];
      if (ghEnv != null && ghEnv.isNotEmpty) return ghEnv;
    }

    return null;
  }

  // ─── Guardar OAuth token ────────────────────────────────────

  Future<void> saveOAuthToken(
    String providerId,
    String accessToken,
    String? refreshToken,
    DateTime expiresAt,
  ) async {
    await _writeStorage(_key(providerId, 'access_token'), accessToken);
    if (refreshToken != null) {
      await _writeStorage(
        _key(providerId, 'refresh_token'),
        refreshToken,
      );
    }
    await _writeStorage(
      _key(providerId, 'expires_at'),
      expiresAt.toIso8601String(),
    );
    await _writeStorage(
      _key(providerId, 'connected'),
      DateTime.now().toIso8601String(),
    );
  }

  Future<String?> getAccessToken(String providerId) async {
    final expiresAtStr = await _readStorage(_key(providerId, 'expires_at'));
    if (expiresAtStr != null) {
      final expiresAt = DateTime.parse(expiresAtStr);
      if (expiresAt.isBefore(DateTime.now())) {
        // Token expirado
        await disconnect(providerId);
        return null;
      }
    }
    return await _readStorage(_key(providerId, 'access_token'));
  }

  // ─── Estado de conexión ─────────────────────────────────────

  Future<bool> isConnected(String providerId) async {
    final key = await getApiKey(providerId);
    if (key != null && key.isNotEmpty) return true;

    final token = await getAccessToken(providerId);
    if (token != null && token.isNotEmpty) return true;

    final val = await _readStorage(_key(providerId, 'connected'));
    return val != null;
  }

  Future<Map<String, bool>> getAllConnectionStatus() async {
    final status = <String, bool>{};
    for (final p in providers) {
      status[p.id] = await isConnected(p.id);
    }
    return status;
  }

  // ─── Proveedor Predeterminado & Resolución Inteligente ──────

  Future<void> setDefaultProvider(String providerId) async {
    await _writeStorage('global_default_provider', providerId);
  }

  Future<String> getDefaultProvider() async {
    final def = await _readStorage('global_default_provider');
    return def ?? 'auto';
  }

  /// Resuelve el proveedor activo y su API Key.
  /// Si se pasa [requestedProviderId], intenta usar ese.
  /// Si es 'auto' o nulo, busca el predeterminado guardado o recorre la cascada de proveedores conectados.
  Future<({AIProvider provider, String apiKey})?> resolveActiveProvider({
    String? requestedProviderId,
  }) async {
    final targetId = requestedProviderId ?? await getDefaultProvider();

    // 1. Si se pidió un proveedor específico
    if (targetId != 'auto') {
      final provider = providers.firstWhere(
        (p) => p.id == targetId,
        orElse: () => providers.first,
      );
      final key = await getApiKey(provider.id);
      if (key != null && key.isNotEmpty) {
        return (provider: provider, apiKey: key);
      }
    }

    // 2. Modo Auto / Fallback Cascada en orden de prioridad:
    // DeepSeek -> Anthropic -> OpenAI -> Gemini -> Groq -> NVIDIA -> MiniMax
    const priorityOrder = [
      'deepseek',
      'anthropic',
      'openai',
      'gemini',
      'groq',
      'nvidia_nim',
      'minimax_io',
    ];

    for (final id in priorityOrder) {
      final p = providers.firstWhere((item) => item.id == id, orElse: () => providers.first);
      final key = await getApiKey(p.id);
      if (key != null && key.isNotEmpty) {
        return (provider: p, apiKey: key);
      }
    }

    return null;
  }

  // ─── Desconectar ───────────────────────────────────────────

  Future<void> disconnect(String providerId) async {
    await _deleteStorage(_key(providerId, 'api_key'));
    await _deleteStorage(_key(providerId, 'access_token'));
    await _deleteStorage(_key(providerId, 'refresh_token'));
    await _deleteStorage(_key(providerId, 'expires_at'));
    await _deleteStorage(_key(providerId, 'connected'));
  }

  // ─── Construir URL de OAuth ────────────────────────────────

  String buildOAuthUrl(AIProvider provider, String redirectUri) {
    final params = {
      'client_id': provider.clientId,
      'redirect_uri': redirectUri,
      'scope': provider.scope,
      'response_type': 'code',
    };
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '${provider.authUrl}?$query';
  }
}
