import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// État vide réutilisable : icône, message explicatif et action facultative
/// (cahier des charges §4.1 et guide §9).
class EmptyState extends StatelessWidget {
  /// Crée un état vide.
  ///
  /// [icon] et [message] sont obligatoires ; [actionLabel] et [onAction]
  /// affichent un bouton d'action uniquement s'ils sont tous les deux fournis.
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  /// Icône illustrant l'état vide.
  final IconData icon;

  /// Message explicatif affiché sous l'icône.
  final String message;

  /// Libellé du bouton d'action, `null` pour ne pas en afficher.
  final String? actionLabel;

  /// Action déclenchée par le bouton, requise pour l'afficher.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 56,
              color: scheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            // Bouton facultatif : affiché seulement si libellé et action existent.
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xl),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Vue d'erreur réutilisable avec bouton « Réessayer ».
class ErrorState extends StatelessWidget {
  /// Crée une vue d'erreur.
  ///
  /// [onRetry] est facultatif ; s'il est fourni, un bouton « Réessayer »
  /// est ajouté.
  const ErrorState({super.key, required this.message, this.onRetry});

  /// Message d'erreur à afficher.
  final String message;

  /// Action de nouvelle tentative, `null` pour masquer le bouton.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.warning_amber_rounded,
      message: message,
      actionLabel: onRetry == null ? null : 'Réessayer',
      onAction: onRetry,
    );
  }
}
