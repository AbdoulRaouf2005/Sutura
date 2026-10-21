import 'package:flutter/material.dart';

import '../../../core/repositories/client_repository.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/id_generator.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../models/client.dart';

/// Formulaire de création / modification d'un client (§4.2).
class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key, this.clientId});

  /// `null` en création, identifiant du client en modification.
  final String? clientId;

  bool get isEditing => clientId != null;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final ClientRepository _repo = ClientRepository();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  Client? _existing;
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
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    final Client? client = await _repo.findById(widget.clientId!);
    if (!mounted) return;
    if (client == null) {
      setState(() => _loading = false);
      showAppSnackBar(context, message: 'Client introuvable.', isError: true);
      Navigator.of(context).pop();
      return;
    }
    _existing = client;
    _name.text = client.fullName;
    _phone.text = client.phone ?? '';
    _notes.text = client.notes ?? '';
    setState(() => _loading = false);
  }

  bool get _hasUnsavedInput =>
      _name.text.trim().isNotEmpty ||
      _phone.text.trim().isNotEmpty ||
      _notes.text.trim().isNotEmpty;

  Future<bool> _confirmLeave() async {
    if (_existing != null) return true;
    if (!_hasUnsavedInput) return true;
    return confirmAction(
      context,
      title: 'Abandonner la saisie ?',
      message: 'Les informations non enregistrées seront perdues.',
      confirmLabel: 'Abandonner',
      cancelLabel: 'Continuer',
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final DateTime now = DateTime.now();
    try {
      if (_existing == null) {
        final Client client = Client(
          id: newId(),
          fullName: _name.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          createdAt: now,
          updatedAt: now,
        );
        await _repo.insert(client);
      } else {
        await _repo.update(
          _existing!.copyWith(
            fullName: _name.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            updatedAt: now,
          ),
        );
      }
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: widget.isEditing ? 'Client modifié.' : 'Client enregistré.',
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final NavigatorState navigator = Navigator.of(context);
        if (await _confirmLeave()) {
          if (mounted) navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title:
              Text(widget.isEditing ? 'Modifier le client' : 'Nouveau client'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: <Widget>[
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (String? value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Ce champ est obligatoire.'
                              : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _notes,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Note générale',
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
                            : 'Enregistrer le client',
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
