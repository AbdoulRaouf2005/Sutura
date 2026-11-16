import 'package:flutter/material.dart';

/// Palette de couleurs de Sutura — voir guide_conception_sutura.md §1.
///
/// Les cinq couleurs officielles sont [deepGreen], [africanGold],
/// [earthOrange], [cream] et [darkGray]. Les autres constantes sont des
/// couleurs fonctionnelles neutres, pas des couleurs supplémentaires de marque.
abstract final class AppColors {
  // Palette officielle
  /// Vert profond, couleur principale de la marque.
  static const Color deepGreen = Color(0xFF0F5132);

  /// Or africain, couleur d'accent de la marque.
  static const Color africanGold = Color(0xFFF4B400);

  /// Orange terre, couleur d'alerte et d'accent de la marque.
  static const Color earthOrange = Color(0xFFE76F51);

  /// Crème, couleur de fond claire de la marque.
  static const Color cream = Color(0xFFFAF7F0);

  /// Gris foncé, couleur de texte principale de la marque.
  static const Color darkGray = Color(0xFF2E2E2E);

  // Couleurs fonctionnelles dérivées de la palette.
  /// Blanc utilisé pour les surfaces.
  static const Color white = Color(0xFFFFFFFF);

  /// Couleur de bordure neutre.
  static const Color border = Color(0xFFE5E0D7);

  /// Couleur de texte atténué.
  static const Color mutedText = Color(0xFF6B6B6B);

  // Rôles sémantiques utilisés par les écrans.
  /// Couleur principale de l'interface.
  static const Color primary = deepGreen;

  /// Couleur d'accent de l'interface.
  static const Color accent = africanGold;

  /// Couleur de fond principale.
  static const Color background = cream;

  /// Couleur des surfaces (cartes, champs, etc.).
  static const Color surface = white;

  /// Couleur du texte principal.
  static const Color textPrimary = darkGray;

  /// Couleur du texte secondaire.
  static const Color textSecondary = mutedText;

  /// Couleur indiquant un succès.
  static const Color success = deepGreen;

  /// Couleur indiquant un avertissement.
  static const Color warning = earthOrange;

  /// Couleur indiquant une erreur.
  static const Color error = earthOrange;

  // Sombre
  /// Couleur de fond en mode sombre.
  static const Color darkBackground = Color(0xFF17141A);

  /// Couleur de surface en mode sombre.
  static const Color darkSurface = Color(0xFF242027);

  /// Couleur du texte principal en mode sombre.
  static const Color darkTextPrimary = Color(0xFFF7F4F8);
}
