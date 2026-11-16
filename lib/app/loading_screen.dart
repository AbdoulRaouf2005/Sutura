import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Écran de chargement affiché pendant l'initialisation de l'application.
///
/// Il prolonge l'écran de démarrage natif (`flutter_native_splash`) : le même
/// logo de chargement est affiché sur le fond vert de la marque, ce qui évite
/// un écran blanc entre le lancement natif et le premier rendu Flutter.
class LoadingScreen extends StatelessWidget {
  /// Crée l'écran de chargement.
  const LoadingScreen({super.key});

  /// Chemin de l'asset du logo affiché pendant le chargement.
  static const String imageAsset = 'assets/logo/Sutura_Icone_Chargement.png';

  /// Construit l'interface de l'écran de chargement.
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.deepGreen,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 220,
                  maxHeight: 220,
                ),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  semanticLabel: 'Sutura',
                  excludeFromSemantics: false,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.content_cut,
                    color: AppColors.cream,
                    size: 96,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Sutura',
                style: TextStyle(
                  color: AppColors.cream,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Mon atelier, bien géré',
                style: TextStyle(
                  color: AppColors.cream.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.africanGold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
