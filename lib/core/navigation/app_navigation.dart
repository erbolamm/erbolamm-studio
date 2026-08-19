import 'package:flutter/material.dart';
import '../config/feature_flags.dart';

class NavigationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
}

class AppNavigation {
  static const List<NavigationItem> items = [
    NavigationItem(
      label: 'Analizador',
      icon: Icons.search_outlined,
      selectedIcon: Icons.search,
      route: '/analyzer',
    ),
    NavigationItem(
      label: '🧠 Orchestrator',
      icon: Icons.account_tree_outlined,
      selectedIcon: Icons.account_tree,
      route: '/orchestrator',
    ),
    NavigationItem(
      label: '🗣️ Voice',
      icon: Icons.record_voice_over_outlined,
      selectedIcon: Icons.record_voice_over,
      route: '/voice',
    ),
    NavigationItem(
      label: '📊 Market',
      icon: Icons.trending_up_outlined,
      selectedIcon: Icons.trending_up,
      route: '/market',
    ),
    NavigationItem(
      label: '🎵 Music',
      icon: Icons.music_note_outlined,
      selectedIcon: Icons.music_note,
      route: '/music',
    ),
    NavigationItem(
      label: '🎬 Animación',
      icon: Icons.movie_creation_outlined,
      selectedIcon: Icons.movie_creation,
      route: '/animation',
    ),
    if (FeatureFlags.cloudEnabled)
      NavigationItem(
        label: '📦 Publisher',
        icon: Icons.publish_outlined,
        selectedIcon: Icons.publish,
        route: '/publisher',
      ),
    NavigationItem(
      label: 'Proyectos',
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder,
      route: '/projects',
    ),
    NavigationItem(
      label: 'Terminal',
      icon: Icons.terminal_outlined,
      selectedIcon: Icons.terminal,
      route: '/terminal',
    ),
    NavigationItem(
      label: 'Admin',
      icon: Icons.admin_panel_settings_outlined,
      selectedIcon: Icons.admin_panel_settings,
      route: '/admin',
    ),
    NavigationItem(
      label: 'Ajustes',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      route: '/settings',
    ),
  ];
}
