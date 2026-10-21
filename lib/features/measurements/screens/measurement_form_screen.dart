import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/repositories/measurement_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/id_generator.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../models/measurement_set.dart';

/// Une ligne de saisie de mesure : nom + valeur, avec possibilité de retirer.
class _MeasurementField {
  _MeasurementField({required this.name, String? initial})
      : controller = TextEditingController(text: initial);

  final String name;
  final TextEditingController controller;

  void dispose() => controller.dispose();
}

/// Formulaire de création d'un jeu de mensurations (§4.3).
///
/// Chaque enregistrement crée un nouveau jeu : l'historique n'est jamais
/// écrasé.
class MeasurementFormScreen extends StatefulWidget {
  const MeasurementFormScreen({super.key, required this.clientId});

  final String clientId;

  @override
  State<MeasurementFormScreen> createState() => _MeasurementFormScreenState();
}

class _MeasurementFormScreenState extends State<MeasurementFormScreen> {
  final MeasurementRepository _repo = MeasurementRepository();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _garmentType = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _customName = TextEditingController();

  late List<_MeasurementField> _fields;
  DateTime _measuredAt = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fields = kDefaultMeasurementNames
        .map((String name) => _MeasurementField(name: name))
        .toList();
  }

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

  void _addCustomMeasure() {
    final String name = _customName.text.trim();
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

  void _removeField(_MeasurementField field) {
    setState(() {
      _fields.remove(field);
      field.dispose();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

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

      await _repo.insertSet(set, linked);
      if (!mounted) return;
      showAppSnackBar(context, message: 'Mensurations enregistrées.');
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
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
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
            _AddMeasureRow(
              controller: _customName,
              onAdd: _addCustomMeasure,
            ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

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

class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({
    super.key,
    required this.field,
    required this.onRemove,
  });

  final _MeasurementField field;
  final VoidCallback onRemove;

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
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}

class _AddMeasureRow extends StatelessWidget {
  const _AddMeasureRow({required this.controller, required this.onAdd});

  final TextEditingController controller;
  final VoidCallback onAdd;

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
