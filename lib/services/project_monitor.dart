// ═══════════════════════════════════════════════════════════════
// 📁 Project Monitor
// ═══════════════════════════════════════════════════════════════
// Monitorea la carpeta INBOX/ del proyecto erbolamm-studio.
// Detecta múltiples proyectos, permite seleccionarlos dinámicamente,
// y expone el estado de PipelineProgress para toda la suite.
// ═══════════════════════════════════════════════════════════════

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/pipeline_progress.dart';

/// Monitor reactivo de la carpeta INBOX/
///
/// Detecta si hay proyectos dentro, permite alternar entre ellos
/// y expone el estado de progreso para el NavigationRail y módulos.
class ProjectMonitor extends ChangeNotifier {
  static const String _analizarPath = 'INBOX';

  final String basePath;
  String? _selectedProjectName;

  String? _customProjectPath;

  ProjectMonitor({required this.basePath});

  String get analizarPath => p.join(basePath, _analizarPath);

  /// Permite fijar directamente una ruta de proyecto local externa a INBOX
  void setCustomProjectPath(String path) {
    if (Directory(path).existsSync()) {
      _customProjectPath = path;
      _selectedProjectName = p.basename(path);
      notifyListeners();
    }
  }

  /// Lista de todos los proyectos válidos encontrados en INBOX/ (o el custom activo)
  List<String> get availableProjects {
    final list = <String>[];
    if (_customProjectPath != null && Directory(_customProjectPath!).existsSync()) {
      list.add(p.basename(_customProjectPath!));
    }

    final dir = Directory(analizarPath);
    if (dir.existsSync()) {
      final inboxList = dir
          .listSync()
          .whereType<Directory>()
          .map((d) => p.basename(d.path))
          .where((name) => !name.startsWith('.') && !name.startsWith('_'))
          .toList()
        ..sort();
      for (final item in inboxList) {
        if (!list.contains(item)) list.add(item);
      }
    }

    return list;
  }

  /// Verifica si existe algún proyecto activo (en INBOX o ruta directa)
  bool get hasProject => (_customProjectPath != null && Directory(_customProjectPath!).existsSync()) || availableProjects.isNotEmpty;

  /// Nombre del proyecto actualmente seleccionado
  String? get projectName {
    if (_customProjectPath != null && Directory(_customProjectPath!).existsSync()) {
      return p.basename(_customProjectPath!);
    }
    if (!hasProject) return null;
    final list = availableProjects;
    if (_selectedProjectName != null && list.contains(_selectedProjectName)) {
      return _selectedProjectName;
    }
    if (list.isNotEmpty) {
      _selectedProjectName = list.first;
      return _selectedProjectName;
    }
    return null;
  }

  /// Cambia el proyecto activo
  void selectProject(String name) {
    if (_selectedProjectName != name) {
      _selectedProjectName = name;
      // Si el proyecto está en INBOX, limpiar custom path para que use INBOX
      final inboxDir = Directory(p.join(analizarPath, name));
      if (inboxDir.existsSync()) {
        _customProjectPath = null;
      }
      notifyListeners();
    }
  }

  /// Ruta completa del proyecto activo
  String? get projectPath {
    if (_customProjectPath != null && Directory(_customProjectPath!).existsSync()) {
      return _customProjectPath;
    }
    final name = projectName;
    if (name == null) return null;
    return p.join(analizarPath, name);
  }

  /// Progreso del pipeline para el proyecto activo
  PipelineProgress get progress => PipelineProgress.evaluate(projectPath);

  /// Notifica cambios forzando una re-evaluación del progreso
  void refresh() {
    notifyListeners();
  }

  /// Verifica si existe carpeta erbolamm-studio/ o promo/ dentro del proyecto
  bool get hasPromo {
    final projPath = projectPath;
    if (projPath == null) return false;
    return Directory(p.join(projPath, 'erbolamm-studio')).existsSync() ||
        Directory(p.join(projPath, 'promo')).existsSync();
  }

  /// Verifica si existe carpeta source/ con HTML
  bool get hasSourceAnimations {
    final projPath = projectPath;
    if (projPath == null) return false;
    return Directory(p.join(projPath, 'erbolamm-studio', 'source')).existsSync() ||
        Directory(p.join(projPath, 'promo', 'source')).existsSync();
  }

  /// Verifica si existen códigos Strudel (en erbolamm-com o en el proyecto)
  bool get hasMusicCodes {
    return Directory(
      p.join(basePath, 'src', 'assets', 'music', 'codes'),
    ).existsSync();
  }
}

