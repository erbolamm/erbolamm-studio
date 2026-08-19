// ═══════════════════════════════════════════════════════════════
// 🌐 App Language Notifier — Estado global del idioma
// ═══════════════════════════════════════════════════════════════
// Notifica a los widgets cuando cambia el idioma.
// Se usa con ListenableBuilder o AnimatedBuilder en el árbol.
//
// Usar: final lang = AppLangNotifier.of(context)?.currentLang;
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'strings.dart';

const _kPrefLang = 'app_language';

/// Notificador de cambios de idioma. Se pasa por el árbol de widgets
/// como un Listenable (via ListenableBuilder) o InheritedNotifier.
class AppLangNotifier extends ChangeNotifier {
  AppLang _currentLang = AppLang.es;

  AppLang get currentLang => _currentLang;

  /// Cargar idioma guardado
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kPrefLang);
      if (saved == 'en') {
        _currentLang = AppLang.en;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Cambiar idioma y persistir
  Future<void> setLang(AppLang lang) async {
    if (lang == _currentLang) return;
    _currentLang = lang;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefLang, lang == AppLang.en ? 'en' : 'es');
    } catch (_) {}
  }

  /// Alternar entre ES/EN
  Future<void> toggle() async {
    await setLang(
      _currentLang == AppLang.es ? AppLang.en : AppLang.es,
    );
  }

  /// Obtener el notificador desde el contexto (usa InheritedNotifier)
  static AppLangNotifier? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AppLangInherited>()?.notifier;
  }
}

/// InheritedWidget para propagar AppLangNotifier por el árbol
class _AppLangInherited extends InheritedNotifier<AppLangNotifier> {
  const _AppLangInherited({
    required super.notifier,
    required super.child,
  });
}

/// Widget que inyecta AppLangNotifier en el árbol
class AppLangProvider extends StatefulWidget {
  final Widget child;

  const AppLangProvider({super.key, required this.child});

  @override
  State<AppLangProvider> createState() => _AppLangProviderState();
}

class _AppLangProviderState extends State<AppLangProvider> {
  final _notifier = AppLangNotifier();

  @override
  void initState() {
    super.initState();
    _notifier.load();
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AppLangInherited(
      notifier: _notifier,
      child: widget.child,
    );
  }
}
