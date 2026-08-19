// ═══════════════════════════════════════════════════════════════
// 🎨 App Theme — Tema claro/oscuro con colores ApliArte
// ═══════════════════════════════════════════════════════════════
// Ambos temas respetan los colores del ecosistema:
//   - ApliArte: glassmorphism oscuro + tonos vibrantes
//   - ErBolamm: colores de pilares (creacion, educacion, cultura...)
//
// El tema claro invierte fondos pero mantiene los acentos.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';

class AppTheme {
  AppTheme._();

  /// Tema oscuro (default ApliArte) — glassmorphism
  static ThemeData dark() => _baseDark(ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.educacion,
      secondary: AppColors.ia,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Color(0xCC12121a),
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      iconTheme: IconThemeData(color: AppColors.textSecondary),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border, width: 1)),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: Color(0x331976D2),
      labelType: NavigationRailLabelType.all,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
    ),
  ));

  /// Tema claro — mantiene acentos ApliArte pero fondos claros
  static ThemeData light() => _baseDark(ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5FA),
    colorScheme: const ColorScheme.light(
      primary: AppColors.educacion,
      secondary: AppColors.ia,
      surface: Color(0xFFFFFFFF),
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF1A1A2E),
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Color(0xCCF0F0F8),
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
      iconTheme: IconThemeData(color: Color(0xFF6a6a7a)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE0E0E8), width: 1)),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Color(0xFFF0F0F8),
      indicatorColor: Color(0x1A1976D2),
      labelType: NavigationRailLabelType.all,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE0E0E8))),
    ),
  ));

  /// Base compartida entre temas (input, botones, texto, chips, divisores, list tiles)
  static ThemeData _baseDark(ThemeData t) {
    return t.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.brightness == Brightness.dark ? AppColors.surfaceLight : const Color(0xFFF0F0F8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.brightness == Brightness.dark ? AppColors.border : const Color(0xFFE0E0E8))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.brightness == Brightness.dark ? AppColors.border : const Color(0xFFE0E0E8))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.educacion, width: 2)),
        labelStyle: TextStyle(color: t.brightness == Brightness.dark ? AppColors.textSecondary : const Color(0xFF6a6a7a)),
        hintStyle: TextStyle(color: t.brightness == Brightness.dark ? AppColors.textMuted : const Color(0xFFa0a0b0)),
        prefixIconColor: t.brightness == Brightness.dark ? AppColors.textSecondary : const Color(0xFF6a6a7a),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.educacion,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: t.brightness == Brightness.dark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: t.brightness == Brightness.dark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.brightness == Brightness.dark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.brightness == Brightness.dark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
        bodyLarge: TextStyle(fontSize: 16, color: t.brightness == Brightness.dark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
        bodyMedium: TextStyle(fontSize: 14, color: t.brightness == Brightness.dark ? AppColors.textSecondary : const Color(0xFF6a6a7a)),
        bodySmall: TextStyle(fontSize: 12, color: t.brightness == Brightness.dark ? AppColors.textMuted : const Color(0xFFa0a0b0)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.brightness == Brightness.dark ? AppColors.surfaceLight : const Color(0xFFF0F0F8),
        selectedColor: AppColors.educacion.withValues(alpha: t.brightness == Brightness.dark ? 0.2 : 0.15),
        labelStyle: TextStyle(color: t.brightness == Brightness.dark ? AppColors.textSecondary : const Color(0xFF6a6a7a)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: t.brightness == Brightness.dark ? AppColors.border : const Color(0xFFE0E0E8))),
      ),
      dividerTheme: DividerThemeData(color: t.brightness == Brightness.dark ? AppColors.border : const Color(0xFFE0E0E8), thickness: 1),
      listTileTheme: ListTileThemeData(
        iconColor: t.brightness == Brightness.dark ? AppColors.textSecondary : const Color(0xFF6a6a7a),
        textColor: t.brightness == Brightness.dark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
      ),
    );
  }
}

/// Notificador de cambios de tema. Se pasa por el árbol como InheritedNotifier.
class ThemeModeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('app_theme');
      if (saved == 'light') {
        _mode = ThemeMode.light;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_theme', mode == ThemeMode.light ? 'light' : 'dark');
    } catch (_) {}
  }

  Future<void> toggle() async {
    await setMode(_mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  static ThemeModeNotifier? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ThemeInherited>()?.notifier;
  }
}

class _ThemeInherited extends InheritedNotifier<ThemeModeNotifier> {
  const _ThemeInherited({required super.notifier, required super.child});
}

class ThemeModeProvider extends StatefulWidget {
  final Widget child;
  const ThemeModeProvider({super.key, required this.child});

  @override
  State<ThemeModeProvider> createState() => _ThemeModeProviderState();
}

class _ThemeModeProviderState extends State<ThemeModeProvider> {
  final _notifier = ThemeModeNotifier();

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
    return _ThemeInherited(notifier: _notifier, child: widget.child);
  }
}
