import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/i18n/app_lang_notifier.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../models/pipeline_progress.dart';
import '../../services/project_monitor.dart';
import 'app_navigation.dart';

class AdaptiveNavigation extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onDestinationSelected;
  final Widget body;
  final ProjectMonitor? monitor;

  const AdaptiveNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.monitor,
  });

  ModuleStatus? _getStatusForRoute(String route, PipelineProgress progress) {
    switch (route) {
      case '/analyzer':
        return progress.analyzer;
      case '/orchestrator':
        return progress.orchestrator;
      case '/voice':
        return progress.voice;
      case '/market':
        return progress.market;
      case '/music':
        return progress.music;
      case '/animation':
        return progress.animation;
      case '/publisher':
        return progress.publisher;
      case '/terminal':
        return progress.terminal;
      default:
        return null;
    }
  }

  Widget _buildBadgedIcon(IconData icon, String route, BuildContext context) {
    if (monitor == null || !monitor!.hasProject) {
      return Icon(icon);
    }

    final status = _getStatusForRoute(route, monitor!.progress);
    if (status == null || status == ModuleStatus.pending || status == ModuleStatus.disabled) {
      return Icon(icon);
    }

    final Color badgeColor = status == ModuleStatus.completed
        ? AppColors.success
        : AppColors.warning;

    return Badge(
      backgroundColor: badgeColor,
      smallSize: 8,
      child: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return _buildDesktopLayout(context, constraints);
        }
        return _buildMobileLayout(context);
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, BoxConstraints constraints) {
    return Scaffold(
      body: Row(
        children: [
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.surface : const Color(0xFFF0F0F8),
                  selectedIconTheme: const IconThemeData(
                    color: AppColors.educacion, size: 28,
                  ),
                  unselectedIconTheme: IconThemeData(
                    color: AppColors.textMuted.withValues(alpha: 0.7), size: 24,
                  ),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppColors.educacion, fontWeight: FontWeight.bold, fontSize: 12,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12,
                  ),
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.educacion, AppColors.ia],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 8),
                        const Text('Studio',
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  destinations: AppNavigation.items.map((item) {
                    return NavigationRailDestination(
                      icon: _buildBadgedIcon(item.icon, item.route, context),
                      selectedIcon: _buildBadgedIcon(item.selectedIcon, item.route, context),
                      label: Text(item.label),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1, color: AppColors.border),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surface : const Color(0xFFF0F0F8),
        indicatorColor: AppColors.educacion.withValues(alpha: 0.2),
        destinations: AppNavigation.items.map((item) {
          return NavigationDestination(
            icon: _buildBadgedIcon(item.icon, item.route, context),
            selectedIcon: _buildBadgedIcon(item.selectedIcon, item.route, context),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

/// Botón de menú de 3 puntos (⋮) para la AppBar.
/// Contiene: selector de idioma ES/EN y tema claro/oscuro.
class SettingsMenuButton extends StatelessWidget {
  const SettingsMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final langNotifier = AppLangNotifier.of(context);
    final themeNotifier = ThemeModeNotifier.of(context);
    final lang = langNotifier?.currentLang ?? AppLang.es;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'lang':
            await langNotifier?.toggle();
            break;
          case 'theme':
            await themeNotifier?.toggle();
            break;
        }
      },
      itemBuilder: (context) => [
        // ── Idioma ──
        PopupMenuItem(
          enabled: false,
          child: Text(
            tr(context, Strings.menuLanguage),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textMuted : const Color(0xFFa0a0b0),
            ),
          ),
        ),
        PopupMenuItem(
          value: 'lang',
          child: Row(
            children: [
              Text(lang == AppLang.es ? '🇪🇸' : '🇬🇧', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Text(
                lang == AppLang.es
                    ? tr(context, Strings.menuEnglish)
                    : tr(context, Strings.menuSpanish),
              ),
              const Spacer(),
              const Icon(Icons.check, size: 18, color: AppColors.educacion),
            ],
          ),
        ),
        const PopupMenuDivider(),
        // ── Tema ──
        PopupMenuItem(
          enabled: false,
          child: Text(
            tr(context, Strings.menuTheme),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textMuted : const Color(0xFFa0a0b0),
            ),
          ),
        ),
        PopupMenuItem(
          value: 'theme',
          child: Row(
            children: [
              Icon(
                themeNotifier?.isDark == true ? Icons.dark_mode : Icons.light_mode,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                themeNotifier?.isDark == true
                    ? tr(context, Strings.menuLight)
                    : tr(context, Strings.menuDark),
              ),
              const Spacer(),
              const Icon(Icons.check, size: 18, color: AppColors.educacion),
            ],
          ),
        ),
      ],
    );
  }
}
