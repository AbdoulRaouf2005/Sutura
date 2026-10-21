import 'package:flutter/material.dart';

import '../../../core/repositories/garment_model_repository.dart';
import '../../../core/storage/local_image_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/id_generator.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/local_image.dart';
import '../models/garment_model.dart';

/// Formulaire de création / modification d'un modèle (§4.4).
///
/// En modification, le modèle déjà utilisé par une commande peut être archivé
/// mais son historique est conservé (l'archivage n'efface rien).
class GarmentModelFormScreen extends StatefulWidget {
  const GarmentModelFormScreen({super.key, this.modelId});

  final String? modelId;

  bool get isEditing => modelId != null;

  @override
  State<GarmentModelFormScreen> createState() => _GarmentModelFormScreenState();
}

class _GarmentModelFormScreenState extends State<GarmentModelFormScreen> {
  final GarmentModelRepository _repo = GarmentModelRepository();
  final LocalImageStorage _images = LocalImageStorage();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();

  GarmentModel? _existing;
  String? _imagePath;
  bool _imageMissing = false;
  String? _category;
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadExisting();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    final GarmentModel? model = await _repo.findById(widget.modelId!);
    if (!mounted) return;
    if (model == null) {
      setState(() => _loading = false);
      showAppSnackBar(context, message: 'Modèle introuvable.', isError: true);
      Navigator.of(context).pop();
      return;
    }
    _existing = model;
    _name.text = model.name;
    _description.text = model.description ?? '';
    _category = model.category;
    _imagePath = model.localImagePath;
    _imageMissing = !await _images.fileExists(model.localImagePath);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _changePhoto() async {
    final String? result = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.of(ctx).pop('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Choisir une photo'),
              onTap: () => Navigator.of(ctx).pop('gallery'),
            ),
            if (_imagePath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Retirer la photo'),
                onTap: () => Navigator.of(ctx).pop('remove'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || result == null) return;

    if (result == 'remove') {
      setState(() {
        _imagePath = null;
        _imageMissing = false;
      });
      return;
    }

    final String? newPath = result == 'camera'
        ? await _images.pickFromCamera()
        : await _images.pickFromGallery();
    if (!mounted || newPath == null) return;
    setState(() {
      _imagePath = newPath;
      _imageMissing = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final DateTime now = DateTime.now();
    try {
      if (_existing == null) {
        final GarmentModel model = GarmentModel(
          id: newId(),
          name: _name.text.trim(),
          category: _category,
          description:
              _description.text.trim().isEmpty ? null : _description.text.trim(),
          localImagePath: _imagePath,
          createdAt: now,
          updatedAt: now,
        );
        await _repo.insert(model);
      } else {
        final String? oldImage = _existing!.localImagePath;
        await _repo.update(
          _existing!.copyWith(
            name: _name.text.trim(),
            category: _category,
            clearCategory: _category == null,
            description:
                _description.text.trim().isEmpty ? null : _description.text.trim(),
            clearDescription: _description.text.trim().isEmpty,
            localImagePath: _imagePath,
            clearImage: _imagePath == null,
            updatedAt: now,
          ),
        );
        // Supprime l'ancienne image si elle a été remplacée.
        if (oldImage != null && oldImage != _imagePath) {
          await _images.deleteFile(oldImage);
        }
      }
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: widget.isEditing ? 'Modèle modifié.' : 'Modèle enregistré.',
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(
        context,
        message: 'L\'enregistrement a échoué. Réessayez.',
        isError: true,
      );
    }
  }

  Future<void> _archive() async {
    final bool confirmed = await confirmAction(
      context,
      title: 'Archiver ce modèle ?',
      message: 'Il ne sera plus proposé dans les nouvelles commandes, '
          'mais son historique sera conservé.',
      confirmLabel: 'Archiver',
    );
    if (!confirmed || _existing == null) return;
    await _repo.update(
      _existing!.copyWith(isArchived: true, updatedAt: DateTime.now()),
    );
    if (!mounted) return;
    showAppSnackBar(context, message: 'Modèle archivé.');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Modifier le modèle' : 'Nouveau modèle'),
        actions: <Widget>[
          if (widget.isEditing && _existing?.isArchived == false)
            IconButton(
              onPressed: _archive,
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'Archiver',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: <Widget>[
                  _PhotoPicker(
                    imagePath: _imagePath,
                    missing: _imageMissing,
                    onTap: _changePhoto,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nom du modèle *',
                    ),
                    validator: (String? value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Ce champ est obligatoire.'
                            : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                    ),
                    items: kGarmentCategories
                        .map(
                          (String category) => DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) =>
                        setState(() => _category = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _description,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Description / notes',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      widget.isEditing
                          ? 'Enregistrer les modifications'
                          : 'Enregistrer le modèle',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.imagePath,
    required this.missing,
    required this.onTap,
  });

  final String? imagePath;
  final bool missing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (missing)
                const _PickPrompt(
                  icon: Icons.broken_image_outlined,
                  label: 'Cette image n\'est plus disponible.\n'
                      'Choisissez une autre photo.',
                )
              else
                LocalImage(path: imagePath),
              if (missing)
                const SizedBox.shrink()
              else if (imagePath == null)
                const _PickPrompt(
                  icon: Icons.add_a_photo_outlined,
                  label: 'Prendre une photo ou choisir une photo',
                )
              else
                Positioned(
                  right: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: onTap,
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      tooltip: 'Remplacer la photo',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickPrompt extends StatelessWidget {
  const _PickPrompt({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            icon,
            size: 40,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
