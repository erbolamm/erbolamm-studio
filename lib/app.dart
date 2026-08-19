// ═══════════════════════════════════════════════════════════════
// 🏠 ErBolamm Studio — App Root & MainScreen
// ═══════════════════════════════════════════════════════════════
// Configura tema (claro/oscuro con colores ApliArte),
// i18n (ES/EN vía clave-valor), navegación adaptativa,
// y monitor de proyectos (INBOX/).
// ═══════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/colors.dart';
import 'core/config/feature_flags.dart';
import 'core/i18n/app_lang_notifier.dart';
import 'core/navigation/adaptive_navigation.dart';
import 'core/navigation/bloc/navigation_bloc.dart';
import 'core/navigation/bloc/navigation_event.dart';
import 'core/navigation/bloc/navigation_state.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/presentation/screens/admin_screen.dart';
import 'features/analyzer/presentation/bloc/analyzer_bloc.dart';
import 'features/analyzer/presentation/screens/analyzer_screen.dart';
import 'features/market_research/presentation/screens/market_research_screen.dart';
import 'features/music/presentation/screens/music_studio_screen.dart';
import 'features/animation/presentation/screens/animation_studio_screen.dart';
import 'features/publisher/presentation/screens/publisher_screen.dart';
import 'features/orchestrator/presentation/screens/orchestrator_screen.dart';
import 'features/voice/presentation/screens/voice_studio_screen.dart';
import 'features/projects/presentation/screens/projects_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/terminal/presentation/screens/terminal_screen.dart';
import 'services/project_monitor.dart';

class ErBolammStudioApp extends StatelessWidget {
  const ErBolammStudioApp({super.key, this.startupMessage});

  final String? startupMessage;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => NavigationBloc())],
      child: AppLangProvider(
        child: ThemeModeProvider(
          child: _ThemeAwareApp(startupMessage: startupMessage),
        ),
      ),
    );
  }
}

/// Este widget se rebuild automáticamente cuando cambia el idioma o el tema
/// porque usa `AppLangNotifier.of(context)` y `ThemeModeNotifier.of(context)`
/// en su build, lo que registra dependencias en los InheritedNotifiers.
class _ThemeAwareApp extends StatelessWidget {
  final String? startupMessage;
  const _ThemeAwareApp({this.startupMessage});

  @override
  Widget build(BuildContext context) {
    // Acceder a los notifiers registra dependencia → rebuild automático
    final themeMode = ThemeModeNotifier.of(context)?.mode ?? ThemeMode.dark;
    return MaterialApp(
      title: 'ErBolamm Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: MainScreen(startupMessage: startupMessage),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.startupMessage});

  final String? startupMessage;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final ProjectMonitor _monitor;

  @override
  void initState() {
    super.initState();
    final basePath = Directory.current.path;
    _monitor = ProjectMonitor(basePath: basePath);
    _monitor.addListener(_onMonitorChanged);
  }

  void _onMonitorChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _monitor.removeListener(_onMonitorChanged);
    _monitor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        final screens = [
          BlocProvider(
            create: (_) => AnalyzerBloc(),
            child: AnalyzerScreen(monitor: _monitor),
          ),
          OrchestratorScreen(monitor: _monitor),
          VoiceStudioScreen(monitor: _monitor),
          MarketResearchScreen(monitor: _monitor),
          MusicStudioScreen(monitor: _monitor),
          AnimationStudioScreen(monitor: _monitor),
          if (FeatureFlags.cloudEnabled) PublisherScreen(monitor: _monitor),
          const ProjectsScreen(),
          TerminalScreen(monitor: _monitor),
          const AdminScreen(),
          const SettingsScreen(),
        ];

        return Column(
          children: [
            if (widget.startupMessage != null)
              MaterialBanner(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.surfaceLight
                    : const Color(0xFFF0F0F8),
                content: Text(
                  widget.startupMessage!,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textPrimary
                        : const Color(0xFF1A1A2E),
                  ),
                ),
                actions: const [SizedBox.shrink()],
              ),
            Expanded(
              child: AdaptiveNavigation(
                selectedIndex: state.selectedIndex,
                monitor: _monitor,
                onDestinationSelected: (index) {
                  context.read<NavigationBloc>().add(
                    NavigationItemSelected(index),
                  );
                },
                body: IndexedStack(
                  index: state.selectedIndex,
                  children: screens,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

