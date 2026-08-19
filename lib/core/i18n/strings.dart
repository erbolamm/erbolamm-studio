// ═══════════════════════════════════════════════════════════════
// 🌐 App Strings — Diccionario clave-valor ES/EN
// ═══════════════════════════════════════════════════════════════
// Cada clave tiene traducción a español e inglés.
// Se usa con `tr(context, Strings.key)`.
// Agregar nuevas claves acá y en ambos idiomas.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'app_lang_notifier.dart';

enum AppLang { es, en }

/// Todas las claves de traducción como constantes.
/// Usar: `Strings.welcome` en vez de strings hardcodeados.
class Strings {
  Strings._();

  // ── General ──
  static const String appTitle = 'app_title';
  static const String appSubtitle = 'app_subtitle';
  static const String loading = 'loading';
  static const String error = 'error';
  static const String success = 'success';
  static const String warning = 'warning';
  static const String cancel = 'cancel';
  static const String confirm = 'confirm';
  static const String save = 'save';
  static const String close = 'close';
  static const String delete = 'delete';
  static const String search = 'search';
  static const String back = 'back';
  static const String next = 'next';
  static const String skip = 'skip';
  static const String finish = 'finish';
  static const String retry = 'retry';
  static const String settings = 'settings';

  // ── Navigation ──
  static const String navAnalyzer = 'nav_analyzer';
  static const String navOrchestrator = 'nav_orchestrator';
  static const String navVoice = 'nav_voice';
  static const String navMarket = 'nav_market';
  static const String navMusic = 'nav_music';
  static const String navAnimation = 'nav_animation';
  static const String navPublisher = 'nav_publisher';
  static const String navProjects = 'nav_projects';
  static const String navTerminal = 'nav_terminal';
  static const String navAdmin = 'nav_admin';
  static const String navSettings = 'nav_settings';

  // ── Settings menu ──
  static const String menuLanguage = 'menu_language';
  static const String menuTheme = 'menu_theme';
  static const String menuDark = 'menu_dark';
  static const String menuLight = 'menu_light';
  static const String menuSpanish = 'menu_spanish';
  static const String menuEnglish = 'menu_english';

  // ── Voice Studio ──
  static const String voiceTitle = 'voice_title';
  static const String voiceIdle = 'voice_idle';
  static const String voiceRecording = 'voice_recording';
  static const String voiceCloning = 'voice_cloning';
  static const String voiceNarrating = 'voice_narrating';
  static const String voiceDone = 'voice_done';
  static const String voiceStart = 'voice_start';
  static const String voiceNoProject = 'voice_no_project';
  static const String voicePhrases = 'voice_phrases';
  static const String voiceRecorded = 'voice_recorded';
  static const String voiceListen = 'voice_listen';
  static const String voiceTapToRecord = 'voice_tap_record';
  static const String voiceRecordingNow = 'voice_recording_now';
  static const String voiceReRecord = 'voice_rerecord';
  static const String voicePrevious = 'voice_previous';
  static const String voiceSkip = 'voice_skip';
  static const String voiceSetup = 'voice_setup';
  static const String voiceSystemReady = 'voice_system_ready';
  static const String voiceMissingDeps = 'voice_missing_deps';
  static const String voiceExportToPublisher = 'voice_export_publisher';

  // ── Orchestrator ──
  static const String orchTitle = 'orch_title';
  static const String orchRun = 'orch_run';
  static const String orchReset = 'orch_reset';
  static const String orchProgress = 'orch_progress';
  static const String orchAgent = 'orch_agent';
  static const String orchCompleted = 'orch_completed';
  static const String orchPending = 'orch_pending';

  // ── Project ──
  static const String projectNoProject = 'project_no_project';
  static const String projectInbox = 'project_inbox';
  static const String projectMonitor = 'project_monitor';
  static const String projectSelect = 'project_select';

  // ── Music Studio ──
  static const String musicTitle = 'music_title';
  static const String musicPlay = 'music_play';
  static const String musicStop = 'music_stop';
  static const String musicGenerate = 'music_generate';

  // ── Market Research ──
  static const String marketTitle = 'market_title';
  static const String marketAnalyze = 'market_analyze';
  static const String marketTrends = 'market_trends';
  static const String marketHooks = 'market_hooks';
}

/// Mapa de traducciones ES/EN por clave
class StringMap {
  StringMap._();

  static const Map<String, Map<AppLang, String>> _map = {
    // ── General ──
    Strings.appTitle: {
      AppLang.es: 'ErBolamm Studio',
      AppLang.en: 'ErBolamm Studio',
    },
    Strings.appSubtitle: {
      AppLang.es: 'Suite creativa multiplataforma',
      AppLang.en: 'Cross-platform creative suite',
    },
    Strings.loading: {
      AppLang.es: 'Cargando...',
      AppLang.en: 'Loading...',
    },
    Strings.error: {
      AppLang.es: 'Error',
      AppLang.en: 'Error',
    },
    Strings.success: {
      AppLang.es: 'Éxito',
      AppLang.en: 'Success',
    },
    Strings.warning: {
      AppLang.es: 'Advertencia',
      AppLang.en: 'Warning',
    },
    Strings.cancel: {
      AppLang.es: 'Cancelar',
      AppLang.en: 'Cancel',
    },
    Strings.confirm: {
      AppLang.es: 'Confirmar',
      AppLang.en: 'Confirm',
    },
    Strings.save: {
      AppLang.es: 'Guardar',
      AppLang.en: 'Save',
    },
    Strings.close: {
      AppLang.es: 'Cerrar',
      AppLang.en: 'Close',
    },
    Strings.delete: {
      AppLang.es: 'Eliminar',
      AppLang.en: 'Delete',
    },
    Strings.search: {
      AppLang.es: 'Buscar',
      AppLang.en: 'Search',
    },
    Strings.back: {
      AppLang.es: 'Volver',
      AppLang.en: 'Back',
    },
    Strings.next: {
      AppLang.es: 'Siguiente',
      AppLang.en: 'Next',
    },
    Strings.skip: {
      AppLang.es: 'Saltar',
      AppLang.en: 'Skip',
    },
    Strings.finish: {
      AppLang.es: 'Finalizar',
      AppLang.en: 'Finish',
    },
    Strings.retry: {
      AppLang.es: 'Reintentar',
      AppLang.en: 'Retry',
    },
    Strings.settings: {
      AppLang.es: 'Ajustes',
      AppLang.en: 'Settings',
    },

    // ── Navigation ──
    Strings.navAnalyzer: {
      AppLang.es: 'Analizador',
      AppLang.en: 'Analyzer',
    },
    Strings.navOrchestrator: {
      AppLang.es: 'Orquestador',
      AppLang.en: 'Orchestrator',
    },
    Strings.navVoice: {
      AppLang.es: 'Voz',
      AppLang.en: 'Voice',
    },
    Strings.navMarket: {
      AppLang.es: 'Mercado',
      AppLang.en: 'Market',
    },
    Strings.navMusic: {
      AppLang.es: 'Música',
      AppLang.en: 'Music',
    },
    Strings.navAnimation: {
      AppLang.es: 'Animación',
      AppLang.en: 'Animation',
    },
    Strings.navPublisher: {
      AppLang.es: 'Publicador',
      AppLang.en: 'Publisher',
    },
    Strings.navProjects: {
      AppLang.es: 'Proyectos',
      AppLang.en: 'Projects',
    },
    Strings.navTerminal: {
      AppLang.es: 'Terminal',
      AppLang.en: 'Terminal',
    },
    Strings.navAdmin: {
      AppLang.es: 'Admin',
      AppLang.en: 'Admin',
    },
    Strings.navSettings: {
      AppLang.es: 'Ajustes',
      AppLang.en: 'Settings',
    },

    // ── Settings menu ──
    Strings.menuLanguage: {
      AppLang.es: 'Idioma',
      AppLang.en: 'Language',
    },
    Strings.menuTheme: {
      AppLang.es: 'Tema',
      AppLang.en: 'Theme',
    },
    Strings.menuDark: {
      AppLang.es: 'Oscuro',
      AppLang.en: 'Dark',
    },
    Strings.menuLight: {
      AppLang.es: 'Claro',
      AppLang.en: 'Light',
    },
    Strings.menuSpanish: {
      AppLang.es: 'Español',
      AppLang.en: 'Spanish',
    },
    Strings.menuEnglish: {
      AppLang.es: 'Inglés',
      AppLang.en: 'English',
    },

    // ── Voice Studio ──
    Strings.voiceTitle: {
      AppLang.es: 'Estudio de Voz',
      AppLang.en: 'Voice Studio',
    },
    Strings.voiceIdle: {
      AppLang.es: 'Inicio',
      AppLang.en: 'Start',
    },
    Strings.voiceRecording: {
      AppLang.es: 'Grabando',
      AppLang.en: 'Recording',
    },
    Strings.voiceCloning: {
      AppLang.es: 'Clonando voz...',
      AppLang.en: 'Cloning voice...',
    },
    Strings.voiceNarrating: {
      AppLang.es: 'Generando narraciones...',
      AppLang.en: 'Generating narrations...',
    },
    Strings.voiceDone: {
      AppLang.es: '¡Voz lista!',
      AppLang.en: 'Voice ready!',
    },
    Strings.voiceStart: {
      AppLang.es: 'Empezar grabación',
      AppLang.en: 'Start recording',
    },
    Strings.voiceNoProject: {
      AppLang.es: 'Agrega un proyecto en INBOX/ para usar el Voice Studio.',
      AppLang.en: 'Add a project to INBOX/ to use Voice Studio.',
    },
    Strings.voicePhrases: {
      AppLang.es: 'Lee estas frases en voz alta',
      AppLang.en: 'Read these phrases aloud',
    },
    Strings.voiceRecorded: {
      AppLang.es: 'grabadas',
      AppLang.en: 'recorded',
    },
    Strings.voiceListen: {
      AppLang.es: 'Escuchar',
      AppLang.en: 'Listen',
    },
    Strings.voiceTapToRecord: {
      AppLang.es: 'Toca para grabar',
      AppLang.en: 'Tap to record',
    },
    Strings.voiceRecordingNow: {
      AppLang.es: 'Grabando... toca para detener',
      AppLang.en: 'Recording... tap to stop',
    },
    Strings.voiceReRecord: {
      AppLang.es: 'Grabada — toca para re-grabar',
      AppLang.en: 'Recorded — tap to re-record',
    },
    Strings.voicePrevious: {
      AppLang.es: 'Anterior',
      AppLang.en: 'Previous',
    },
    Strings.voiceSkip: {
      AppLang.es: 'Saltar',
      AppLang.en: 'Skip',
    },
    Strings.voiceSetup: {
      AppLang.es: 'Configurar Voice Pipeline',
      AppLang.en: 'Setup Voice Pipeline',
    },
    Strings.voiceSystemReady: {
      AppLang.es: 'Sistema listo',
      AppLang.en: 'System ready',
    },
    Strings.voiceMissingDeps: {
      AppLang.es: 'Faltan dependencias',
      AppLang.en: 'Missing dependencies',
    },
    Strings.voiceExportToPublisher: {
      AppLang.es: 'Enviar a Publisher',
      AppLang.en: 'Send to Publisher',
    },

    // ── Orchestrator ──
    Strings.orchTitle: {
      AppLang.es: 'Orquestador',
      AppLang.en: 'Orchestrator',
    },
    Strings.orchRun: {
      AppLang.es: 'Ejecutar pipeline',
      AppLang.en: 'Run pipeline',
    },
    Strings.orchReset: {
      AppLang.es: 'Reiniciar',
      AppLang.en: 'Reset',
    },
    Strings.orchProgress: {
      AppLang.es: 'Progreso',
      AppLang.en: 'Progress',
    },
    Strings.orchAgent: {
      AppLang.es: 'Agente',
      AppLang.en: 'Agent',
    },
    Strings.orchCompleted: {
      AppLang.es: 'Completado',
      AppLang.en: 'Completed',
    },
    Strings.orchPending: {
      AppLang.es: 'Pendiente',
      AppLang.en: 'Pending',
    },

    // ── Project ──
    Strings.projectNoProject: {
      AppLang.es: 'No hay proyecto activo',
      AppLang.en: 'No active project',
    },
    Strings.projectInbox: {
      AppLang.es: 'Bandeja de entrada',
      AppLang.en: 'Inbox',
    },
    Strings.projectMonitor: {
      AppLang.es: 'Monitor de proyectos',
      AppLang.en: 'Project Monitor',
    },
    Strings.projectSelect: {
      AppLang.es: 'Seleccionar proyecto',
      AppLang.en: 'Select project',
    },

    // ── Music Studio ──
    Strings.musicTitle: {
      AppLang.es: 'Estudio de Música',
      AppLang.en: 'Music Studio',
    },
    Strings.musicPlay: {
      AppLang.es: 'Reproducir',
      AppLang.en: 'Play',
    },
    Strings.musicStop: {
      AppLang.es: 'Detener',
      AppLang.en: 'Stop',
    },
    Strings.musicGenerate: {
      AppLang.es: 'Generar música',
      AppLang.en: 'Generate music',
    },

    // ── Market Research ──
    Strings.marketTitle: {
      AppLang.es: 'Análisis de Mercado',
      AppLang.en: 'Market Research',
    },
    Strings.marketAnalyze: {
      AppLang.es: 'Analizar',
      AppLang.en: 'Analyze',
    },
    Strings.marketTrends: {
      AppLang.es: 'Tendencias',
      AppLang.en: 'Trends',
    },
    Strings.marketHooks: {
      AppLang.es: 'Hooks de marketing',
      AppLang.en: 'Marketing hooks',
    },
  };

  /// Obtiene la traducción para una clave en el idioma dado
  static String tr(String key, AppLang lang) {
    return _map[key]?[lang] ?? '[$key]';
  }
}

/// Atajo para usar desde widgets: `tr(context, Strings.voiceTitle)`
String tr(BuildContext context, String key) {
  final lang = AppLangNotifier.of(context)?.currentLang ?? AppLang.es;
  return StringMap.tr(key, lang);
}

/// Atajo para usar desde widgets con idioma explícito
String trLang(AppLang lang, String key) {
  return StringMap.tr(key, lang);
}
