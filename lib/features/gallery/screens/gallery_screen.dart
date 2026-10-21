import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/garment_model_repository.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/local_image.dart';
import '../models/garment_model.dart';

/// Galerie de modèles : grille de photos, recherche par nom, filtre par
/// catégorie (§4.4).
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final GarmentModelRepository _repo = GarmentModelRepository();
  final TextEditingController _search = TextEditingController();

  Future<List<GarmentModel>>? _future;
  String? _category;

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

  void _load() {
    setState(() {
      _future = _repo.list(query: _search.text, category: _category);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Galerie de modèles')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final bool? changed = await context.push<bool>('/galerie/nouveau');
          if (changed == true) _load();
        },
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
              builder: (BuildContext context,
                  AsyncSnapshot<List<GarmentModel>> snapshot) {
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
                  final bool filtered =
                      _search.text.trim().isNotEmpty || _category != null;
                  return EmptyState(
                    icon: Icons.photo_library_outlined,
                    message: filtered
                        ? 'Aucun modèle ne correspond à votre recherche.'
                        : 'Votre galerie est vide. Ajoutez une photo de modèle '
                            'pour la retrouver facilement lors d\'une commande.',
                    actionLabel: filtered ? null : 'Ajouter un modèle',
                    onAction: filtered
                        ? null
                        : () async {
                            final bool? changed =
                                await context.push<bool>('/galerie/nouveau');
                            if (changed == true) _load();
                          },
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xxl * 2,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: models.length,
                  itemBuilder: (BuildContext context, int index) {
                    final GarmentModel model = models[index];
                    return _ModelTile(
                      model: model,
                      onTap: () async {
                        final bool? changed = await context
                            .push<bool>('/galerie/${model.id}/modifier');
                        if (changed == true) _load();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: <Widget>[
          FilterChip(
            label: const Text('Toutes'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: AppSpacing.sm),
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
  const _ModelTile({required this.model, required this.onTap});

  final GarmentModel model;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: LocalImage(
                  path: model.localImagePath,
                  label: model.name,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    model.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (model.category != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      model.category!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
