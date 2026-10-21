import 'package:flutter/material.dart';

/// Palette de couleurs de Sutura — voir guide_conception_sutura.md §1.
///
/// Les cinq couleurs officielles sont [deepGreen], [africanGold],
/// [earthOrange], [cream] et [darkGray]. Les autres constantes sont des
/// couleurs fonctionnelles neutres, pas des couleurs supplémentaires de marque.
abstract final class AppColors {
  // Palette officielle
  static const Color deepGreen = Color(0xFF0F5132);
  static const Color africanGold = Color(0xFFF4B400);
  static const Color earthOrange = Color(0xFFE76F51);
  static const Color cream = Color(0xFFFAF7F0);
  static const Color darkGray = Color(0xFF2E2E2E);

  // Couleurs fonctionnelles dérivées de la palette.
  static const Color white = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E0D7);
  static const Color mutedText = Color(0xFF6B6B6B);

  // Rôles sémantiques utilisés par les écrans.
  static const Color primary = deepGreen;
  static const Color accent = africanGold;
  static const Color background = cream;
  static const Color surface = white;
  static const Color textPrimary = darkGray;
  static const Color textSecondary = mutedText;
  static const Color success = deepGreen;
  static const Color warning = earthOrange;
  static const Color error = earthOrange;

  // Sombre
  static const Color darkBackground = Color(0xFF17141A);
  static const Color darkSurface = Color(0xFF242027);
  static const Color darkTextPrimary = Color(0xFFF7F4F8);
}
