import 'package:flutter/material.dart';

/// Colores oficiales del ecosistema ErBolamm
/// Fuente: INBOX.md - Pilares del ecosistema
class AppColors {
  // Pilares del ecosistema
  static const Color creacion = Color(0xFFff4e83);      // Rosa
  static const Color educacion = Color(0xFF1976D2);     // Azul
  static const Color cultura = Color(0xFF388E3C);       // Verde
  static const Color herramientas = Color(0xFFFF8F00);  // Naranja
  static const Color hardware = Color(0xFFFFB300);      // Dorado
  static const Color ia = Color(0xFF9c27b0);            // Púrpura

  // Colores de estado
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Fondos (tema oscuro - glassmorphism)
  static const Color background = Color(0xFF0a0a0f);
  static const Color surface = Color(0xFF12121a);
  static const Color surfaceLight = Color(0xFF1a1a25);
  static const Color cardBackground = Color(0xFF151520);
  
  // Texto
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFa0a0b0);
  static const Color textMuted = Color(0xFF6a6a7a);

  // Bordes y divisores
  static const Color border = Color(0xFF2a2a3a);
  static const Color borderLight = Color(0xFF353545);

  // Gradientes para glassmorphism
  static const List<Color> glassGradient = [
    Color(0xFF1a1a2e),
    Color(0xFF16213e),
  ];

  static const List<Color> accentGradient = [
    Color(0xFF4488ff),
    Color(0xFF7c4dff),
  ];

  /// Obtiene el color de un pilar por su ID
  static Color getPillarColor(String pillar) {
    switch (pillar) {
      case 'creacion':
        return creacion;
      case 'educacion':
        return educacion;
      case 'cultura':
        return cultura;
      case 'herramientas':
        return herramientas;
      case 'hardware':
        return hardware;
      case 'ia':
        return ia;
      default:
        return educacion; // Default azul
    }
  }
}
