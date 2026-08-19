// ═══════════════════════════════════════════════════════════════
// 🚀 ErBolamm Studio — Entry Point (100% Local & Standalone)
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ErBolammStudioApp(
    startupMessage: 'Modo 100% local. Tus proyectos se gestionan en este dispositivo.',
  ));
}
