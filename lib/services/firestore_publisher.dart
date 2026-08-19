import 'package:flutter/foundation.dart';
import '../models/public_project_record.dart';

// ═══════════════════════════════════════════════════════════════
// 📦 FirestorePublisher (Local & Offline Publisher)
// ═══════════════════════════════════════════════════════════════

class FirestorePublisher {
  void initialize() {
    debugPrint('FirestorePublisher: Modo local activo');
  }

  bool get isReady => true;
  String? get initError => null;

  Future<bool> upsertPublicProject(PublicProjectRecord record) async {
    debugPrint('FirestorePublisher: proyecto ${record.id} guardado localmente');
    return true;
  }

  Future<bool> deletePublicProject(String projectId) async {
    debugPrint('FirestorePublisher: proyecto $projectId eliminado localmente');
    return true;
  }

  Future<PublicProjectRecord?> getPublicProject(String projectId) async {
    return null;
  }

  void dispose() {}
}
