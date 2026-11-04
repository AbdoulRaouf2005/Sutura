import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Couleurs sémantiques de l'application (succès, avertissement, erreur)
/// adaptées au mode clair ou sombre afin de rester lisibles sur les deux
/// fonds (guide §1 et §2).
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.error,
    required this.onSurfaceMuted,
  });

  /// Vert de confirmation.
  final Color success;

  /// Orange d'attention.
  final Color warning;

  /// Orange d'erreur.
  final Color error;

  /// Texte secondaire, atténué par rapport au texte principal.
  final Color onSurfaceMuted;

  static const AppSemanticColors light = AppSemanticColors(
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    onSurfaceMuted: AppColors.textSecondary,
  );

  static const AppSemanticColors dark = AppSemanticColors(
    success: Color(0xFF7FD1A3),
    warning: Color(0xFFFFB4A2),
    error: Color(0xFFFF8A70),
    onSurfaceMuted: Color(0xFFB0A9B8),
  );

  /// Raccourci de lecture depuis un `BuildContext`.
  static AppSemanticColors of(BuildContext context) {
    return Theme.of(context).extension<AppSemanticColors>() ?? light;
  }

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? error,
    Color? onSurfaceMuted,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
    );
  }

  @override
  AppSemanticColors lerp(covariant AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      onSurfaceMuted: Color.lerp(onSurfaceMuted, other.onSurfaceMuted, t)!,
    );
  }
}
