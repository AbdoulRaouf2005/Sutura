import 'dart:io';

import 'package:flutter/material.dart';

/// Affiche une photo locale avec une gestion propre des cas d'erreur :
/// fichier manquant, invalide, ou vide (§11).
class LocalImage extends StatelessWidget {
  const LocalImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.label,
    this.cacheWidth,
  });

  final String? path;
  final BoxFit fit;

  /// Texte alternatif/accessible pour l'image (guide §11).
  final String? label;

  /// Largeur de décodage en pixels. Réduit la mémoire utilisée pour les
  /// vignettes d'une grille tout en gardant l'image nette.
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return const _Placeholder(icon: Icons.image_outlined);
    }
    return Image.file(
      File(path!),
      fit: fit,
      semanticLabel: label,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      errorBuilder: (_, _, _) =>
          const _Placeholder(icon: Icons.broken_image_outlined),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
      child: Center(
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface
              .withValues(alpha: 0.35),
          size: 32,
        ),
      ),
    );
  }
}
