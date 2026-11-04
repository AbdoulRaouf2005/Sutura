import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/orders/models/order.dart';

/// Pastille de statut : toujours une icône + un libellé, jamais la couleur
/// seule (guide §2 et §11).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final OrderStatus status;

  ({Color color, IconData icon}) _style(BuildContext context) {
    final AppSemanticColors semantic = AppSemanticColors.of(context);
    return switch (status) {
      OrderStatus.toStart => (
            color: semantic.onSurfaceMuted,
            icon: Icons.schedule_outlined,
          ),
      OrderStatus.inProgress => (
            color: AppColors.accent,
            icon: Icons.construction_outlined,
          ),
      OrderStatus.ready => (
            color: semantic.success,
            icon: Icons.check_circle_outline,
          ),
      OrderStatus.delivered => (
            color: semantic.success,
            icon: Icons.local_shipping_outlined,
          ),
      OrderStatus.cancelled => (
            color: semantic.error,
            icon: Icons.cancel_outlined,
          ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ({Color color, IconData icon}) style = _style(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(style.icon, size: 14, color: style.color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: style.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastille d'alerte « En retard », état calculé (pas un statut enregistré).
class LateBadge extends StatelessWidget {
  const LateBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final Color color = AppSemanticColors.of(context).error;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.warning_amber_rounded, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'En retard',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
