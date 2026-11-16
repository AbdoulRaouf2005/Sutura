import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/garment_model_repository.dart';
import '../../../core/state/data_controller.dart';
import '../../../core/state/data_events_listener.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/local_image.dart';
import '../models/garment_model.dart';
import 'gallery_preview_screen.dart';

/// Galerie de modèles : grille de photos, recherche par nom, filtre par
/// catégorie (§4.4).
///
/// La grille privilégie les photos pour donner un aperçu rapide de tous les
/// modèles. Un appui ouvre un aperçu plein écran qui permet de faire défiler
/// les modèles sans quitter la galerie.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen>
    with DataEventsListener<GalleryScreen> {
  final GarmentModelRepository _repo = GarmentModelRepository();
  final TextEditingController _search = TextEditingController();

  Future<List<GarmentModel>>? _future;

  /// Catégorie sélectionnée dans le filtre (`null` = toutes).
  String? _category;

  @override
  Set<DataEntity> get dataEntities => const <DataEntity>{DataEntity.models};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Recharge la liste lorsque les données de modèles changent ailleurs.
  @override
  void onDataChanged() => _load();

  /// Relance la requête en appliquant la recherche et le filtre courants.
  void _load() {
    setState(() {
      _future = _repo.list(query: _search.text, category: _category);
    });
  }

  /// Ouvre l'aperçu plein écran puis l'édition si le client le demande.
  ///
  /// [models] est la liste affichée et [index] la position du modèle touché.
  Future<void> _openPreview(List<GarmentModel> models, int index) async {
    final String? editId = await Navigator.of(context).push<String>(
      PageRouteBuilder<String>(
        pageBuilder: (_, _, _) =>
            GalleryPreviewScreen(models: models, initialIndex: index),
        // Fondu léger à l'ouverture de l'aperçu.
        transitionsBuilder: (_, Animation<double> animation, _, Widget child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
    // Ignore le retour si l'écran n'est plus monté ou si aucune édition.
    if (!mounted || editId == null) return;
    await context.push('/galerie/$editId/modifier');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Galerie de modèles')),
      // Bouton d'ajout d'un nouveau modèle.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/galerie/nouveau'),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Ajouter'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: (_) => _load(),
              decoration: const InputDecoration(
                hintText: 'Rechercher un modèle',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          // Filtre horizontal par catégorie.
          _CategoryFilter(
            selected: _category,
            onSelected: (String? category) {
              _category = category;
              _load();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: FutureBuilder<List<GarmentModel>>(
              future: _future,
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<GarmentModel>> snapshot,
                  ) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return ErrorState(
                        message: 'Impossible de charger la galerie.',
                        onRetry: _load,
                      );
                    }
                    final List<GarmentModel> models =
                        snapshot.data ?? <GarmentModel>[];
                    if (models.isEmpty) {
                      // Distingue une galerie vide d'une recherche sans résultat.
                      final bool filtered =
                          _search.text.trim().isNotEmpty || _category != null;
                      return EmptyState(
                        icon: Icons.photo_library_outlined,
                        message: filtered
                            ? 'Aucun modèle ne correspond à votre recherche.'
                            : 'Votre galerie est vide. Ajoutez une photo de modèle '
                                  'pour la retrouver facilement lors d\'une commande.',
                        // Pas de bouton d'ajout lorsque la liste est filtrée.
                        actionLabel: filtered ? null : 'Ajouter un modèle',
                        onAction: filtered
                            ? null
                            : () => context.push('/galerie/nouveau'),
                      );
                    }
                    return _GalleryGrid(
                      models: models,
                      onOpen: (int index) => _openPreview(models, index),
                    );
                  },
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryGrid extends StatelessWidget {
  /// Grille responsive des modèles, agencée en colonnes selon la largeur.
  const _GalleryGrid({required this.models, required this.onOpen});

  /// Modèles à afficher.
  final List<GarmentModel> models;

  /// Callback appelé avec l'index du modèle touché.
  final ValueChanged<int> onOpen;

  /// Nombre de colonnes adapté à la largeur disponible.
  int _columnsFor(double width) {
    if (width >= 1000) return 5;
    if (width >= 760) return 4;
    if (width >= 560) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = _columnsFor(constraints.maxWidth);
        return CustomScrollView(
          slivers: <Widget>[
            // Compteur du nombre de modèles affichés.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  models.length == 1 ? '1 modèle' : '${models.length} modèles',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            // Grille des vignettes, avec marge basse pour le bouton flottant.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xxl * 2,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 3 / 4,
                ),
                delegate: SliverChildBuilderDelegate((
                  BuildContext context,
                  int index,
                ) {
                  return _ModelTile(
                    model: models[index],
                    onTap: () => onOpen(index),
                  );
                }, childCount: models.length),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  /// Rangée de puces pour filtrer la galerie par catégorie.
  const _CategoryFilter({required this.selected, required this.onSelected});

  /// Catégorie active, `null` pour « Toutes ».
  final String? selected;

  /// Callback appelé avec la catégorie choisie (`null` = toutes).
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: <Widget>[
          // Puce « Toutes » pour retirer le filtre de catégorie.
          FilterChip(
            label: const Text('Toutes'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Une puce par catégorie disponible.
          ...kGarmentCategories.map(
            (String category) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(category),
                selected: selected == category,
                onSelected: (_) => onSelected(category),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelTile extends StatelessWidget {
  /// Vignette d'un modèle : photo surmontée de son nom et de sa catégorie.
  const _ModelTile({required this.model, required this.onTap});

  /// Modèle représenté par la vignette.
  final GarmentModel model;

  /// Action déclenchée au toucher de la vignette.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            LocalImage(
              path: model.localImagePath,
              label: model.name,
              // Limite la largeur de décodage pour économiser la mémoire.
              cacheWidth: 700,
            ),
            // Bandeau dégradé avec le nom et la catégorie en bas de la photo.
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Colors.transparent, Colors.black87],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      model.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (model.category != null)
                      Text(
                        model.category!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
