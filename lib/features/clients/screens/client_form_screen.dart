import 'package:flutter/material.dart';

import '../../../core/repositories/client_repository.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/id_generator.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../models/client.dart';

/// Écran de formulaire pour créer ou modifier un client (§4.2).
class ClientFormScreen extends StatefulWidget {
  /// Crée le formulaire. [clientId] vaut `null` en création.
  const ClientFormScreen({super.key, this.clientId});

  /// Identifiant du client en modification, ou `null` en création.
  final String? clientId;

  /// Indique si le formulaire est en mode modification.
  bool get isEditing => clientId != null;

  /// Crée l'état associé à ce formulaire.
  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

/// État de [ClientFormScreen] gérant la saisie, la validation et l'enregistrement.
class _ClientFormScreenState extends State<ClientFormScreen> {
  /// Dépôt pour les opérations de persistance des clients.
  final ClientRepository _repo = ClientRepository();

  /// Clé du formulaire pour déclencher la validation.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Contrôleur du champ nom complet.
  final TextEditingController _name = TextEditingController();

  /// Contrôleur du champ téléphone.
  final TextEditingController _phone = TextEditingController();

  /// Contrôleur du champ notes.
  final TextEditingController _notes = TextEditingController();

  /// Client existant en mode modification, sinon `null`.
  Client? _existing;

  /// Indique si les données initiales sont en cours de chargement.
  bool _loading = false;

  /// Indique si une sauvegarde est en cours.
  bool _saving = false;

  /// Initialise l'état et charge le client existant si nécessaire.
  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadExisting();
  }

  /// Libère les contrôleurs de texte.
  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// Charge les données du client à modifier depuis le dépôt.
  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    final Client? client = await _repo.findById(widget.clientId!);
    if (!mounted) return;
    // Gestion du cas où le client n'existe plus.
    if (client == null) {
      setState(() => _loading = false);
      showAppSnackBar(context, message: 'Client introuvable.', isError: true);
      Navigator.of(context).pop();
      return;
    }
    // Pré-remplit le formulaire avec les données existantes.
    _existing = client;
    _name.text = client.fullName;
    _phone.text = client.phone ?? '';
    _notes.text = client.notes ?? '';
    setState(() => _loading = false);
  }

  /// Indique si une saisie non enregistrée est présente en création.
  bool get _hasUnsavedInput =>
      _name.text.trim().isNotEmpty ||
      _phone.text.trim().isNotEmpty ||
      _notes.text.trim().isNotEmpty;

  /// Demande confirmation avant de quitter si des données risquent d'être perdues.
  ///
  /// Retourne `true` si la navigation peut continuer.
  Future<bool> _confirmLeave() async {
    // Pas de confirmation en édition ou si aucun champ n'est renseigné.
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

  /// Valide le formulaire puis crée ou met à jour le client.
  Future<void> _save() async {
    // Validation des champs avant toute persistance.
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final DateTime now = DateTime.now();
    try {
      if (_existing == null) {
        // Création d'un nouveau client avec les valeurs saisies.
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
        // Mise à jour du client existant.
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
      // Retour à l'écran précédent avec un résultat positif.
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

  /// Construit l'interface du formulaire client.
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        // Intercepte le retour pour confirmer l'abandon si nécessaire.
        if (didPop) return;
        final NavigatorState navigator = Navigator.of(context);
        if (await _confirmLeave()) {
          if (mounted) navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEditing ? 'Modifier le client' : 'Nouveau client',
          ),
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
                          // Validation du champ obligatoire.
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
