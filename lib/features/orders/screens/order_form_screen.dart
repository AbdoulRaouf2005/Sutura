import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/client_repository.dart';
import '../../../core/repositories/garment_model_repository.dart';
import '../../../core/repositories/measurement_repository.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../core/state/data_controller.dart';
import '../../../core/state/data_events_listener.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/id_generator.dart';
import '../../../shared/formatters/formatters.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/local_image.dart';
import '../../clients/models/client.dart';
import '../../gallery/models/garment_model.dart';
import '../../measurements/models/measurement_set.dart';
import '../models/order.dart';

/// Formulaire de création / modification d'une commande (§4.5).
///
/// Une commande peut référencer un modèle de la galerie et un jeu de
/// mensurations, ou exister sans (modèle personnalisé). Le nom du modèle est
/// copié au moment de la commande (snapshot), pour ne pas changer
/// rétroactivement si le modèle évolue ensuite.
class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key, this.preselectedClientId, this.orderId});

  /// Client pré-sélectionné lorsqu'on crée depuis sa fiche.
  final String? preselectedClientId;

  /// `null` en création, identifiant de la commande en modification.
  final String? orderId;

  bool get isEditing => orderId != null;

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen>
    with DataEventsListener<OrderFormScreen> {
  final ClientRepository _clients = ClientRepository();
  final GarmentModelRepository _models = GarmentModelRepository();
  final MeasurementRepository _measurements = MeasurementRepository();
  final OrderRepository _orders = OrderRepository();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _quantity = TextEditingController(text: '1');
  final TextEditingController _price = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  Future<_OrderFormData>? _future;

  Order? _existing;
  Client? _client;
  GarmentModel? _model;
  MeasurementSet? _measurementSet;
  DateTime _deliveryAt = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  /// Le formulaire n'est pré-rempli qu'une fois : un rafraîchissement des
  /// listes (client ajouté, modèle modifié) ne doit pas écraser la saisie.
  bool _initialized = false;

  @override
  Set<DataEntity> get dataEntities => const <DataEntity>{
        DataEntity.clients,
        DataEntity.models,
      };

  @override
  void initState() {
    super.initState();
    _future = _loadOptions();
  }

  @override
  void onDataChanged() {
    setState(() {
      _future = _loadOptions();
    });
  }

  @override
  void dispose() {
    _description.dispose();
    _quantity.dispose();
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<_OrderFormData> _loadOptions() async {
    final List<Client> clients = await _clients.list();
    final List<GarmentModel> models = await _models.list();

    if (!_initialized) {
      await _fillFromExisting();
      _initialized = true;
    }

    return _OrderFormData(clients: clients, models: models);
  }

  /// Reprend les valeurs de la commande modifiée (ou le client présélectionné)
  /// au premier chargement uniquement.
  Future<void> _fillFromExisting() async {
    if (widget.isEditing) {
      final Order? order = await _orders.findById(widget.orderId!);
      if (order == null) {
        throw StateError('Commande introuvable');
      }
      _existing = order;
      _client = await _clients.findById(order.clientId) ??
          Client(
            id: order.clientId,
            fullName: 'Client inconnu',
            createdAt: order.createdAt,
            updatedAt: order.updatedAt,
            isArchived: true,
          );
      if (order.garmentModelId != null) {
        // Le modèle peut avoir été archivé : on le cherche sans filtre.
        _model = await _models.findById(order.garmentModelId!);
      }
      if (order.measurementSetId != null) {
        _measurementSet =
            await _measurements.findSetById(order.measurementSetId!);
      }
      _description.text = order.description ?? '';
      _quantity.text = '${order.quantity}';
      _price.text = '${order.totalPrice}';
      _notes.text = order.notes ?? '';
      _deliveryAt = order.deliveryAt;
    } else if (widget.preselectedClientId != null) {
      _client = await _clients.findById(widget.preselectedClientId!);
    }
  }

  Future<void> _selectClient() async {
    final _OrderFormData? data = await _future;
    if (!mounted || data == null) return;
    final Client? picked = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => _ClientPicker(clients: data.clients),
    );
    if (picked != null) {
      setState(() {
        _client = picked;
        _measurementSet = null;
      });
    }
  }

  Future<void> _selectModel() async {
    final _OrderFormData? data = await _future;
    if (!mounted || data == null) return;
    final GarmentModel? picked = await showModalBottomSheet<GarmentModel>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => _ModelPicker(models: data.models),
    );
    if (mounted) setState(() => _model = picked);
  }

  Future<void> _selectMeasurementSet() async {
    if (_client == null) return;
    final List<MeasurementSet> sets =
        await _measurements.listSetsForClient(_client!.id);
    if (!mounted) return;
    if (sets.isEmpty) {
      showAppSnackBar(
        context,
        message: 'Aucune mensuration pour ce client.',
        isError: true,
      );
      return;
    }
    final MeasurementSet? picked = await showModalBottomSheet<MeasurementSet>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => _MeasurementSetPicker(sets: sets),
    );
    if (mounted) setState(() => _measurementSet = picked);
  }

  Future<void> _pickDeliveryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deliveryAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      helpText: 'Date de livraison prévue',
    );
    if (picked != null) setState(() => _deliveryAt = picked);
  }

  Future<void> _save() async {
    if (_client == null) {
      showAppSnackBar(
        context,
        message: 'Choisissez un client.',
        isError: true,
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final DateTime now = DateTime.now();
    final int quantity = int.parse(_quantity.text.trim());
    final int totalPrice = int.parse(_price.text.trim());
    final String? description =
        _description.text.trim().isEmpty ? null : _description.text.trim();
    final String? notes =
        _notes.text.trim().isEmpty ? null : _notes.text.trim();

    setState(() => _saving = true);
    try {
      if (_existing == null) {
        final Order order = Order(
          id: newId(),
          clientId: _client!.id,
          garmentModelId: _model?.id,
          modelNameSnapshot: _model?.name,
          modelImageSnapshotPath: _model?.localImagePath,
          measurementSetId: _measurementSet?.id,
          description: description,
          quantity: quantity,
          totalPrice: totalPrice,
          deliveryAt: _deliveryAt,
          status: OrderStatus.toStart,
          notes: notes,
          createdAt: now,
          updatedAt: now,
        );
        await _orders.insert(order);
      } else {
        // Le modèle et les mensurations peuvent être modifiés ; le snapshot
        // suit alors le choix courant. Les paiements et l'identifiant de la
        // commande restent inchangés.
        final bool removeModel =
            _model == null && _existing!.garmentModelId != null;
        await _orders.update(
          _existing!.copyWith(
            garmentModelId: _model?.id,
            modelNameSnapshot: _model?.name,
            modelImageSnapshotPath: _model?.localImagePath,
            clearModel: removeModel,
            measurementSetId: _measurementSet?.id,
            clearMeasurementSet:
                _measurementSet == null && _existing!.measurementSetId != null,
            description: description,
            clearDescription: description == null,
            quantity: quantity,
            totalPrice: totalPrice,
            deliveryAt: _deliveryAt,
            notes: notes,
            clearNotes: notes == null,
            updatedAt: now,
          ),
        );
      }
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: widget.isEditing
            ? 'Commande modifiée.'
            : 'Commande enregistrée.',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Modifier la commande' : 'Nouvelle commande'),
      ),
      body: FutureBuilder<_OrderFormData>(
        future: _future,
        builder: (BuildContext context,
            AsyncSnapshot<_OrderFormData> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Impossible de charger le formulaire.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.data!.clients.isEmpty) {
            return _NeedClient(
              onAdd: () => context.push('/clients/nouveau'),
            );
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: <Widget>[
                _PickerTile(
                  icon: Icons.person_outline,
                  label: 'Client *',
                  value: _client?.fullName,
                  hint: 'Choisir un client',
                  onTap: _selectClient,
                ),
                const SizedBox(height: AppSpacing.md),
                _PickerTile(
                  icon: Icons.checkroom_outlined,
                  label: 'Modèle',
                  value: _model?.name,
                  hint: 'Modèle personnalisé / aucun',
                  leading: _model != null
                      ? LocalImage(path: _model!.localImagePath)
                      : null,
                  onTap: _selectModel,
                ),
                if (_model != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: () => setState(() => _model = null),
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: 'Retirer le modèle',
                          visualDensity: VisualDensity.compact,
                        ),
                        const Text(
                          'Sans modèle de la galerie',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                _PickerTile(
                  icon: Icons.straighten,
                  label: 'Mensurations',
                  value: _measurementSet == null
                      ? null
                      : '${_measurementSet!.garmentType} — '
                          '${Formatters.date(_measurementSet!.measuredAt)}',
                  hint: _client == null
                      ? 'Choisissez d\'abord un client'
                      : 'Associer des mensurations',
                  onTap: _client == null ? null : _selectMeasurementSet,
                ),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _description,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Détail du travail demandé',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _quantity,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Quantité *',
                        ),
                        validator: (String? value) {
                          final int? q = int.tryParse((value ?? '').trim());
                          if (q == null || q < 1) {
                            return 'La quantité doit être au moins égale à 1.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Prix total *',
                          suffixText: 'FCFA',
                        ),
                        validator: (String? value) {
                          final int? price = int.tryParse((value ?? '').trim());
                          if (price == null) {
                            return 'Choisissez un montant.';
                          }
                          if (price < 0) {
                            return 'Montant invalide.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _PickerTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'Date de livraison *',
                  value: Formatters.date(_deliveryAt),
                  hint: 'Choisir une date',
                  onTap: _pickDeliveryDate,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _notes,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notes (facultatives)',
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
                        : 'Enregistrer la commande',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OrderFormData {
  const _OrderFormData({required this.clients, required this.models});

  final List<Client> clients;
  final List<GarmentModel> models;
}

class _NeedClient extends StatelessWidget {
  const _NeedClient({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.people_outline,
              size: 56,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.35),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Ajoutez d\'abord un client pour créer une commande.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: onAdd,
              child: const Text('Ajouter un client'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
    this.value,
    this.leading,
  });

  final IconData icon;
  final String label;
  final String hint;
  final String? value;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              if (leading != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  child: SizedBox(width: 48, height: 48, child: leading),
                )
              else
                Icon(
                  icon,
                  color: onTap == null
                      ? Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.35)
                      : Theme.of(context).colorScheme.primary,
                ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasValue ? value! : hint,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            hasValue ? FontWeight.w600 : FontWeight.normal,
                        color: hasValue
                            ? null
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientPicker extends StatelessWidget {
  const _ClientPicker({required this.clients});

  final List<Client> clients;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (BuildContext context, ScrollController controller) {
        return Column(
          children: <Widget>[
            const _SheetHandle(),
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Choisir un client',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: clients.length,
                itemBuilder: (BuildContext context, int index) {
                  final Client client = clients[index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(client.fullName),
                    subtitle: client.phone == null ? null : Text(client.phone!),
                    onTap: () => Navigator.of(context).pop(client),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ModelPicker extends StatelessWidget {
  const _ModelPicker({required this.models});

  final List<GarmentModel> models;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (BuildContext context, ScrollController controller) {
        return Column(
          children: <Widget>[
            const _SheetHandle(),
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Choisir un modèle',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: models.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          'Votre galerie est vide. Vous pouvez créer la '
                          'commande sans modèle, ou ajouter un modèle depuis '
                          'la galerie.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      itemCount: models.length,
                      itemBuilder: (BuildContext context, int index) {
                        final GarmentModel model = models[index];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: LocalImage(
                                path: model.localImagePath,
                                label: model.name,
                              ),
                            ),
                          ),
                          title: Text(model.name),
                          subtitle: model.category == null
                              ? null
                              : Text(model.category!),
                          onTap: () => Navigator.of(context).pop(model),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _MeasurementSetPicker extends StatelessWidget {
  const _MeasurementSetPicker({required this.sets});

  final List<MeasurementSet> sets;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (BuildContext context, ScrollController controller) {
        return Column(
          children: <Widget>[
            const _SheetHandle(),
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Choisir des mensurations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: sets.length,
                itemBuilder: (BuildContext context, int index) {
                  final MeasurementSet set = sets[index];
                  return ListTile(
                    leading: const Icon(Icons.straighten),
                    title: Text(set.garmentType),
                    subtitle:
                        Text('Prise le ${Formatters.date(set.measuredAt)}'),
                    onTap: () => Navigator.of(context).pop(set),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
