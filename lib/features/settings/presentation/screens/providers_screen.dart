import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../services/ai_providers_service.dart';

class ProvidersScreen extends StatefulWidget {
  const ProvidersScreen({super.key});

  @override
  State<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends State<ProvidersScreen> {
  final _service = AIProvidersService.instance;
  Map<String, bool> _status = {};
  String _defaultProvider = 'auto';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final stored = await _service.getAllConnectionStatus();
    final def = await _service.getDefaultProvider();

    // MiniMax.io conectado si mmx CLI funciona
    final mmxWorks = await _checkMmx();

    if (mounted) {
      setState(() {
        _status = stored;
        if (mmxWorks) _status['minimax_io'] = true;
        _defaultProvider = def;
        _loading = false;
      });
    }
  }

  Future<bool> _checkMmx() async {
    try {
      final result = await Process.run('mmx', [
        'quota',
        'show',
      ], runInShell: true).timeout(const Duration(seconds: 5));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> _setDefault(String providerId) async {
    await _service.setDefaultProvider(providerId);
    await _loadStatus();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          providerId == 'auto'
              ? 'Modo Auto activado (Fallback Cascada) 🤖'
              : 'Proveedor predeterminado actualizado ⭐',
        ),
        backgroundColor: AppColors.cultura,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Proveedores IA')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildAutoModeCard(),
                const SizedBox(height: 12),
                ...AIProvidersService.providers.map((provider) {
                  final connected = _status[provider.id] ?? false;
                  final isDefault = _defaultProvider == provider.id;
                  return _buildProviderCard(provider, connected, isDefault);
                }),
              ],
            ),
    );
  }

  Widget _buildAutoModeCard() {
    final isAuto = _defaultProvider == 'auto';
    return Card(
      color: isAuto
          ? AppColors.ia.withValues(alpha: 0.15)
          : AppColors.surfaceLight.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAuto ? AppColors.ia : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('🤖', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Modo Auto (Fallback Inteligente)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Usa DeepSeek ➔ Claude ➔ GPT-4o ➔ Gemini según disponibilidad sin cortes.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: isAuto ? null : () => _setDefault('auto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAuto ? AppColors.cultura : AppColors.surfaceLight,
                foregroundColor: Colors.white,
              ),
              child: Text(isAuto ? 'Activo ⭐' : 'Activar Auto'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(AIProvider provider, bool connected, bool isDefault) {
    final color = Color(provider.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDefault ? color : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(provider.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            provider.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '⭐ Predeterminado',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        provider.description,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: connected
                        ? AppColors.cultura.withValues(alpha: 0.15)
                        : AppColors.textMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: connected
                          ? AppColors.cultura.withValues(alpha: 0.4)
                          : AppColors.textMuted.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        connected ? Icons.check_circle : Icons.circle_outlined,
                        size: 14,
                        color: connected
                            ? AppColors.cultura
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        connected ? 'Conectado' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: connected
                              ? AppColors.cultura
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (connected && !isDefault) ...[
                  TextButton.icon(
                    onPressed: () => _setDefault(provider.id),
                    icon: const Icon(Icons.star_border, size: 18),
                    label: const Text('Fijar como predeterminado'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.ia,
                    ),
                  ),
                ],
                if (connected) ...[
                  TextButton.icon(
                    onPressed: () => _disconnect(provider.id),
                    icon: const Icon(Icons.link_off, size: 18),
                    label: const Text('Desconectar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.creacion,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                if (provider.type == ProviderType.apiKey) ...[
                  ElevatedButton.icon(
                    onPressed: () => _configureApiKey(provider),
                    icon: const Icon(Icons.vpn_key, size: 18),
                    label: Text(connected ? 'Cambiar key' : 'Configurar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: connected ? null : () => _connectOAuth(provider),
                    icon: const Icon(Icons.login, size: 18),
                    label: Text(connected ? 'Conectado' : 'Conectar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: connected ? AppColors.textMuted : color,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _configureApiKey(AIProvider provider) async {
    final existingKey = await _service.getApiKey(provider.id);
    if (!mounted) return;
    final controller = TextEditingController(text: existingKey ?? '');

    final key = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${provider.emoji} ${provider.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.apiKeyEnvVar != null
                  ? 'API Key (var: \${provider.apiKeyEnvVar})'
                  : 'API Key',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            if (provider.portalUrl != null) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => Process.run('open', [provider.portalUrl!]),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.open_in_new, size: 14, color: AppColors.ia),
                    const SizedBox(width: 4),
                    Text(
                      'Obtener key en ${provider.name} ↗',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.ia,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'sk-... o oat-...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppColors.surfaceLight.withValues(alpha: 0.5),
              ),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (key != null && key.isNotEmpty && mounted) {
      await _service.saveApiKey(provider.id, key);
      await _loadStatus();
    }
  }

  Future<void> _connectOAuth(AIProvider provider) async {
    final redirectUri = 'erbolamm-studio://oauth/callback';
    final url = _service.buildOAuthUrl(provider, redirectUri);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${provider.emoji} Conectar ${provider.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OAuth requiere abrir un navegador. Copiá esta URL:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppColors.ia,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Después de autorizar, pegá el código de vuelta aquí.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Código de autorización...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppColors.surfaceLight.withValues(alpha: 0.5),
              ),
              onSubmitted: (code) => Navigator.of(ctx).pop(code),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnect(String providerId) async {
    await _service.disconnect(providerId);
    await _loadStatus();
  }
}
