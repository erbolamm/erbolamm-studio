// ═══════════════════════════════════════════════════════════════
// 📁 Workspace Service — Proyecto activo compartido
// ═══════════════════════════════════════════════════════════════
// Mantiene el path del proyecto activo. Lo lee el Terminal
// y lo escribe el Orchestrator cuando seleccionas un proyecto.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';

class WorkspaceService extends ChangeNotifier {
  static final WorkspaceService instance = WorkspaceService._();

  WorkspaceService._();

  String _activeProjectPath = '';
  String _activeProjectName = '';

  String get activeProjectPath => _activeProjectPath;
  String get activeProjectName => _activeProjectName;
  bool get hasActiveProject => _activeProjectPath.isNotEmpty;

  void setActiveProject(String path, String name) {
    _activeProjectPath = path;
    _activeProjectName = name;
    notifyListeners();
  }

  void clearActiveProject() {
    _activeProjectPath = '';
    _activeProjectName = '';
    notifyListeners();
  }
}
