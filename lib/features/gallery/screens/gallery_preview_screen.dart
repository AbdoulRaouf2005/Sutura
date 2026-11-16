import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/local_image.dart';
import '../models/garment_model.dart';

/// Aperçu plein écran d'un lot de modèles.
///
/// Le client fait défiler les photos horizontalement pour comparer rapidement
/// les modèles. L'écran renvoie l'identifiant du modèle à modifier lorsqu'on
/// appuie sur « Modifier ».
class GalleryPreviewScreen extends StatefulWidget {
  /// Crée l'aperçu d'un lot de modèles.
  ///
  /// [models] est la liste complète affichée et [initialIndex] la position
  /// de départ dans cette liste.
  const GalleryPreviewScreen({
    super.key,
    required this.models,
    required this.initialIndex,
  });

  /// Modèles à parcourir dans l'aperçu.
  final List<GarmentModel> models;

  /// Index du modèle affiché à l'ouverture.
  final int initialIndex;

  @override
  State<GalleryPreviewScreen> createState() => _GalleryPreviewScreenState();
}

class _GalleryPreviewScreenState extends State<GalleryPreviewScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    // Borne l'index de départ pour éviter tout dépassement de la liste.
    _index = widget.initialIndex.clamp(0, widget.models.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Modèle actuellement affiché, mis à jour à chaque changement de page.
  GarmentModel get _current => widget.models[_index];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Défilement horizontal d'un modèle à l'autre.
          PageView.builder(
            controller: _controller,
            itemCount: widget.models.length,
            onPageChanged: (int index) => setState(() => _index = index),
            itemBuilder: (BuildContext context, int index) {
              final GarmentModel model = widget.models[index];
              return SizedBox.expand(
                child: LocalImage(
                  path: model.localImagePath,
                  label: model.name,
                  fit: BoxFit.contain,
                ),
              );
            },
          ),
          // Dégradés haut et bas pour garder les textes lisibles sur la photo.
          const _TopScrim(),
          const _BottomScrim(),
          SafeArea(
            child: Column(
              children: <Widget>[
                _PreviewHeader(
                  position: _index + 1,
                  total: widget.models.length,
                  onClose: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                _PreviewDetails(
                  model: _current,
                  // Renvoie l'identifiant du modèle pour ouvrir l'édition.
                  onEdit: () => Navigator.of(context).pop(_current.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  /// Barre supérieure : bouton de fermeture et compteur de position.
  const _PreviewHeader({
    required this.position,
    required this.total,
    required this.onClose,
  });

  /// Position courante (1-based) dans le lot.
  final int position;

  /// Nombre total de modèles.
  final int total;

  /// Action déclenchée pour fermer l'aperçu.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Fermer',
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            ),
            child: Text(
              '$position / $total',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewDetails extends StatelessWidget {
  /// Bloc d'informations du modèle : nom, catégorie, description et édition.
  const _PreviewDetails({required this.model, required this.onEdit});

  /// Modèle actuellement affiché.
  final GarmentModel model;

  /// Action déclenchée pour demander la modification du modèle.
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    // On ignore une description vide ou composée uniquement d'espaces.
    final String? description = model.description?.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            model.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (model.category != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Text(
                model.category!,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
          if (description != null && description.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Modifier ce modèle'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dégradé sombre en haut de l'écran, derrière l'en-tête.
class _TopScrim extends StatelessWidget {
  const _TopScrim();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: 140,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Colors.black87, Colors.transparent],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dégradé sombre en bas de l'écran, derrière les détails du modèle.
class _BottomScrim extends StatelessWidget {
  const _BottomScrim();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: 280,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: <Color>[Colors.black87, Colors.transparent],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
