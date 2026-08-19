// ═══════════════════════════════════════════════════════════════
// 🍏 Store Metadata & Release Notes Auditor (Anti-Rechazo 2.3.3)
// ═══════════════════════════════════════════════════════════════
// Permite copiar notas de versión multilingües en 1 clic para
// Google Play y App Store Connect, y audita las capturas de
// pantalla para prevenir rechazos por tamaños legacy (Guideline 2.3.3).
// ═══════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../../../../core/constants/colors.dart';
import '../../../../services/project_monitor.dart';

class StoreMetadataAuditorWidget extends StatefulWidget {
  final ProjectMonitor? monitor;

  const StoreMetadataAuditorWidget({super.key, this.monitor});

  @override
  State<StoreMetadataAuditorWidget> createState() =>
      _StoreMetadataAuditorWidgetState();
}

class _StoreMetadataAuditorWidgetState
    extends State<StoreMetadataAuditorWidget> {
  String _selectedLanguage = 'es';
  final Map<String, String> _languages = {
    'es': '🇪🇸 Español',
    'en': '🇬🇧 English',
    'de': '🇩🇪 Deutsch',
    'fr': '🇫🇷 Français',
    'it': '🇮🇹 Italiano',
    'pt': '🇵🇹 Português',
  };

  final Map<String, String> _releaseNotes = {
    'es': '• Mejoras en la interfaz y rendimiento general.\n• Corrección de errores y optimización de audio.',
    'en': '• User interface improvements and performance optimization.\n• Bug fixes and enhanced audio experience.',
    'de': '• Verbesserungen der Benutzeroberfläche und Leistung.\n• Fehlerbehebungen und optimiertes Audio.',
    'fr': '• Améliorations de l\'interface utilisateur et performances.\n• Corrections de bugs et audio optimisé.',
    'it': '• Miglioramenti dell\'interfaccia e prestazioni generali.\n• Risoluzione di bug e audio ottimizzato.',
    'pt': '• Melhorias na interface e desempenho geral.\n• Correção de erros e áudio otimizado.',
  };

  @override
  void initState() {
    super.initState();
    _loadCustomCopyPack();
  }

  void _loadCustomCopyPack() {
    final projPath = widget.monitor?.projectPath;
    if (projPath == null) return;

    final copyPackFile = File(p.join(projPath, 'erbolamm-studio', 'copy-pack.md')).existsSync()
        ? File(p.join(projPath, 'erbolamm-studio', 'copy-pack.md'))
        : File(p.join(projPath, 'promo', 'copy-pack.md'));
    if (copyPackFile.existsSync()) {
      final content = copyPackFile.readAsStringSync();
      // Si el copy-pack contiene notas específicas, las podemos adaptar
      if (content.contains('Novedades') || content.contains('What\'s New')) {
        // Mantiene valores o adapta según el archivo
      }
    }
  }

  List<String> _auditScreenshots() {
    final projPath = widget.monitor?.projectPath;
    if (projPath == null) return [];

    final warnings = <String>[];
    final screenDir = Directory(p.join(projPath, 'erbolamm-studio', 'screenshots')).existsSync()
        ? Directory(p.join(projPath, 'erbolamm-studio', 'screenshots'))
        : Directory(p.join(projPath, 'promo', 'screenshots'));
    if (!screenDir.existsSync()) {
      warnings.add('No existe la carpeta erbolamm-studio/screenshots/');
      return warnings;
    }

    final entities = screenDir.listSync(recursive: true);
    final paths = entities.map((e) => e.path.toLowerCase()).toList();

    // Detección de tamaños legacy peligrosos (Apple Guideline 2.3.3)
    final legacyKeywords = ['5.5', '5_5', '4.7', '4_7', '4-inch', '3.5', '3_5', '9.7', '9_7', 'ipad_pro_2'];
    for (final kw in legacyKeywords) {
      if (paths.any((p) => p.contains(kw))) {
        warnings.add('⚠️ Detectada carpeta/archivo legacy "$kw": Eliminalo del Media Manager para evitar el rechazo 2.3.3 de Apple.');
        break;
      }
    }

    final has67 = paths.any((p) => p.contains('6.7') || p.contains('6_7') || p.contains('iphone_6_7'));
    final hasIpad13 = paths.any((p) => p.contains('13') || p.contains('ipad_13') || p.contains('12.9'));

    if (!has67) {
      warnings.add('ℹ️ Recomendado: Agregar capturas para iPhone 6.7" (App Store las escala automáticamente).');
    }
    if (!hasIpad13) {
      warnings.add('ℹ️ Recomendado: Agregar capturas para iPad 13" si la app soporta iPad.');
    }

    return warnings;
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1000),
        backgroundColor: AppColors.cultura,
      ),
    );
  }

  void _copyBatchAndroid() {
    final buffer = StringBuffer();
    _releaseNotes.forEach((lang, notes) {
      buffer.writeln('<$lang>');
      buffer.writeln(notes);
      buffer.writeln('</$lang>');
      buffer.writeln('');
    });
    _copyToClipboard(
      buffer.toString().trim(),
      'Novedades en todos los idiomas copiadas para Google Play ✅',
    );
  }

  void _copySingleIos() {
    final text = _releaseNotes[_selectedLanguage] ?? '';
    _copyToClipboard(
      text,
      'Novedades en ${_languages[_selectedLanguage]} copiadas para App Store ✅',
    );
  }

  @override
  Widget build(BuildContext context) {
    final warnings = _auditScreenshots();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.verified_outlined, color: AppColors.educacion, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Auditoría de Metadatos & Release Notes (App Store / Play Store)',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Generá y copiá las novedades de versión por idioma y verificá que tus capturas no violen las directrices de tiendas.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),

          // Alertas de screenshots
          if (warnings.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: warnings
                    .map(
                      (w) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          w,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 16),

          // Selector de Idioma & Copia con Wrap responsivo
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    dropdownColor: AppColors.surfaceLight,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _languages.entries.map((e) {
                      return DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedLanguage = val);
                      }
                    },
                  ),
                ),
              ),

              // Botón iOS (1 idioma)
              ElevatedButton.icon(
                onPressed: _copySingleIos,
                icon: const Icon(Icons.apple, size: 18),
                label: const Text('Copiar para iOS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ia,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Botón Android (Todo junto)
              ElevatedButton.icon(
                onPressed: _copyBatchAndroid,
                icon: const Icon(Icons.android, size: 18),
                label: const Text('Copiar Todo (Android)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cultura,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Preview del texto actual
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0e0e16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Text(
              _releaseNotes[_selectedLanguage] ?? '',
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
