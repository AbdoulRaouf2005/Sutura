import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/repositories/measurement_repository.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/id_generator.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../models/measurement_set.dart';

/// Représente une ligne de saisie de mesure avec son nom et sa valeur.
class _MeasurementField {
  /// Crée une ligne de mesure pour [name] avec une valeur [initial] optionnelle.
  _MeasurementField({required this.name, String? initial})
    : controller = TextEditingController(text: initial);

  /// Nom de la mesure associée à cette ligne.
  final String name;

  /// Contrôleur du champ de saisie de la valeur.
  final TextEditingController controller;

  /// Libère le contrôleur associé à cette ligne.
  void dispose() => controller.dispose();
}

/// Écran de formulaire pour créer un nouveau jeu de mensurations (§4.3).
///
/// Chaque enregistrement crée un nouveau jeu : l'historique n'est jamais
/// écrasé.
class MeasurementFormScreen extends StatefulWidget {
  /// Crée le formulaire pour le client identifié par [clientId].
  const MeasurementFormScreen({super.key, required this.clientId});

  /// Identifiant du client pour lequel les mesures sont saisies.
  final String clientId;

  /// Crée l'état associé à ce formulaire.
  @override
  State<MeasurementFormScreen> createState() => _MeasurementFormScreenState();
}

/// État de [MeasurementFormScreen] gérant la saisie et l'enregistrement des mesures.
class _MeasurementFormScreenState extends State<MeasurementFormScreen> {
  /// Dépôt pour la persistance des jeux de mensurations.
  final MeasurementRepository _repo = MeasurementRepository();

  /// Clé du formulaire pour déclencher la validation.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Contrôleur du champ type de vêtement ou usage.
  final TextEditingController _garmentType = TextEditingController();

  /// Contrôleur du champ notes.
  final TextEditingController _notes = TextEditingController();

  /// Contrôleur du champ d'ajout d'une mesure personnalisée.
  final TextEditingController _customName = TextEditingController();

  /// Lignes de saisie des mesures affichées dans le formulaire.
  late List<_MeasurementField> _fields;

  /// Date de prise des mesures.
  DateTime _measuredAt = DateTime.now();

  /// Indique si une sauvegarde est en cours.
  bool _saving = false;

  /// Initialise l'état avec les mesures proposées par défaut.
  @override
  void initState() {
    super.initState();
    // Prépare les champs de saisie à partir des noms de mesures par défaut.
    _fields = kDefaultMeasurementNames
        .map((String name) => _MeasurementField(name: name))
        .toList();
  }

  /// Libère les contrôleurs de texte et les champs de mesure.
  @override
  void dispose() {
    _garmentType.dispose();
    _notes.dispose();
    _customName.dispose();
    for (final _MeasurementField field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  /// Ouvre le sélecteur de date pour modifier la date de prise des mesures.
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _measuredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Date de prise des mesures',
    );
    if (picked != null) setState(() => _measuredAt = picked);
  }

  /// Ajoute une mesure personnalisée à la liste des champs.
  void _addCustomMeasure() {
    final String name = _customName.text.trim();
    // Validation du nom de la mesure personnalisée.
    if (name.isEmpty) {
      showAppSnackBar(
        context,
        message: 'Saisissez le nom de la mesure.',
        isError: true,
      );
      return;
    }
    if (_fields.any((f) => f.name.toLowerCase() == name.toLowerCase())) {
      showAppSnackBar(
        context,
        message: 'Cette mesure existe déjà.',
        isError: true,
      );
      return;
    }
    setState(() {
      _fields.add(_MeasurementField(name: name));
      _customName.clear();
    });
  }

  /// Retire une ligne de mesure [field] du formulaire.
  void _removeField(_MeasurementField field) {
    setState(() {
      _fields.remove(field);
      field.dispose();
    });
  }

  /// Valide et enregistre un nouveau jeu de mensurations avec ses mesures.
  Future<void> _save() async {
    // Validation des champs du formulaire.
    if (!_formKey.currentState!.validate()) return;

    // Collecte des mesures renseignées avec une valeur valide.
    final List<Measurement> measurements = <Measurement>[];
    for (final _MeasurementField field in _fields) {
      final String raw = field.controller.text.trim().replaceAll(',', '.');
      if (raw.isEmpty) continue;
      final double? value = double.tryParse(raw);
      if (value == null || value <= 0) continue;
      measurements.add(
        Measurement(
          id: newId(),
          measurementSetId: '',
          name: field.name,
          value: value,
        ),
      );
    }

    if (measurements.isEmpty) {
      showAppSnackBar(
        context,
        message: 'Saisissez au moins une mesure.',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // Création du jeu et liaison des mesures à son identifiant.
      final String setId = newId();
      final MeasurementSet set = MeasurementSet(
        id: setId,
        clientId: widget.clientId,
        garmentType: _garmentType.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        measuredAt: _measuredAt,
        createdAt: DateTime.now(),
      );
      final List<Measurement> linked = measurements
          .map(
            (Measurement m) => Measurement(
              id: m.id,
              measurementSetId: setId,
              name: m.name,
              value: m.value,
              unit: m.unit,
            ),
          )
          .toList();

      // Persistance du jeu et de ses mesures.
      await _repo.insertSet(set, linked);
      if (!mounted) return;
      showAppSnackBar(context, message: 'Mensurations enregistrées.');
      Navigator.of(context).pop(true);
    } catch (_) {
      // Gestion des erreurs d'enregistrement.
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(
        context,
        message: 'L\'enregistrement a échoué. Réessayez.',
        isError: true,
      );
    }
  }

  /// Construit l'interface du formulaire de mensurations.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelles mensurations')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            TextFormField(
              controller: _garmentType,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Type de vêtement ou usage *',
                hintText: 'Ex. Boubou, Robe, Pantalon…',
              ),
              validator: (String? value) =>
                  // Validation du type de vêtement obligatoire.
                  (value == null || value.trim().isEmpty)
                  ? 'Ce champ est obligatoire.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            _DateRow(date: _measuredAt, onTap: _pickDate),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle('Mesures (cm)'),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Renseignez uniquement les mesures utiles. '
              'Laissez vide celles qui ne s\'appliquent pas.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ..._fields.map(
              (_MeasurementField field) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _MeasurementRow(
                  key: ObjectKey(field),
                  field: field,
                  onRemove: () => _removeField(field),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _AddMeasureRow(controller: _customName, onAdd: _addCustomMeasure),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (facultative)',
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
              label: const Text('Enregistrer les mensurations'),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// Titre de section utilisé dans le formulaire.
class _SectionTitle extends StatelessWidget {
  /// Crée un titre de section avec le texte [label].
  const _SectionTitle(this.label);

  /// Libellé affiché comme titre de section.
  final String label;

  /// Construit le widget de titre de section.
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }
}

/// Ligne affichant la date de prise des mesures et permettant de la modifier.
class _DateRow extends StatelessWidget {
  /// Crée la ligne de date avec la [date] affichée et l'action [onTap].
  const _DateRow({required this.date, required this.onTap});

  /// Date actuellement sélectionnée.
  final DateTime date;

  /// Action déclenchée lors du tap pour modifier la date.
  final VoidCallback onTap;

  /// Construit la carte de sélection de la date.
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_month_outlined),
        title: const Text('Date de prise des mesures'),
        subtitle: Text(
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/${date.year}',
        ),
        trailing: const Icon(Icons.edit_outlined, size: 18),
        onTap: onTap,
      ),
    );
  }
}

/// Ligne de saisie d'une mesure individuelle avec option de retrait.
class _MeasurementRow extends StatelessWidget {
  /// Crée une ligne pour le champ [field] avec l'action de suppression [onRemove].
  const _MeasurementRow({
    super.key,
    required this.field,
    required this.onRemove,
  });

  /// Champ de mesure associé à cette ligne.
  final _MeasurementField field;

  /// Action déclenchée pour retirer la mesure.
  final VoidCallback onRemove;

  /// Construit la ligne de saisie de la mesure.
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: TextFormField(
            controller: field.controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: field.name,
              suffixText: 'cm',
              isDense: true,
            ),
            validator: (String? value) {
              // Valide la valeur si elle est renseignée.
              final String raw = (value ?? '').trim().replaceAll(',', '.');
              if (raw.isEmpty) return null;
              final double? parsed = double.tryParse(raw);
              if (parsed == null || parsed <= 0) {
                return 'Valeur invalide';
              }
              return null;
            },
          ),
        ),
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.close),
          tooltip: 'Retirer ${field.name}',
          color: AppSemanticColors.of(context).onSurfaceMuted,
        ),
      ],
    );
  }
}

/// Ligne permettant d'ajouter une mesure personnalisée au formulaire.
class _AddMeasureRow extends StatelessWidget {
  /// Crée la ligne d'ajout avec [controller] et l'action [onAdd].
  const _AddMeasureRow({required this.controller, required this.onAdd});

  /// Contrôleur du nom de la nouvelle mesure.
  final TextEditingController controller;

  /// Action déclenchée pour ajouter la mesure.
  final VoidCallback onAdd;

  /// Construit la ligne d'ajout d'une mesure personnalisée.
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => onAdd(),
            decoration: const InputDecoration(
              hintText: 'Ajouter une autre mesure',
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton.filled(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          tooltip: 'Ajouter la mesure',
        ),
      ],
    );
  }
}
