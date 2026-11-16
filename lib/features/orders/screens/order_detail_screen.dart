import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/client_repository.dart';
import '../../../core/repositories/measurement_repository.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../core/repositories/payment_repository.dart';
import '../../../core/state/data_controller.dart';
import '../../../core/state/data_events_listener.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/formatters/formatters.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/local_image.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../clients/models/client.dart';
import '../../measurements/models/measurement_set.dart';
import '../../payments/models/payment.dart';
import '../models/order.dart';

/// Écran de détail d'une commande : informations, modèle, mensurations,
/// statut, solde et accès aux paiements (§4.5 et §4.6).
class OrderDetailScreen extends StatefulWidget {
  /// Crée l'écran de détail pour la commande [orderId].
  const OrderDetailScreen({super.key, required this.orderId});

  /// Identifiant de la commande à afficher.
  final String orderId;

  /// Crée l'état associé à cet écran.
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

/// État de [OrderDetailScreen] gérant le chargement et les actions sur la commande.
class _OrderDetailScreenState extends State<OrderDetailScreen>
    with DataEventsListener<OrderDetailScreen> {
  /// Dépôt des commandes.
  final OrderRepository _orders = OrderRepository();

  /// Dépôt des clients.
  final ClientRepository _clients = ClientRepository();

  /// Dépôt des mensurations.
  final MeasurementRepository _measurements = MeasurementRepository();

  /// Dépôt des paiements.
  final PaymentRepository _payments = PaymentRepository();

  /// Futur contenant les données détaillées de la commande.
  Future<_OrderDetailData>? _future;

  /// Indique si des modifications ont été effectuées depuis l'ouverture.
  bool _changed = false;

  /// Entités dont les changements déclenchent un rechargement.
  @override
  Set<DataEntity> get dataEntities => const <DataEntity>{
    DataEntity.orders,
    DataEntity.clients,
    DataEntity.measurements,
    DataEntity.payments,
  };

  /// Initialise l'état et charge le détail de la commande.
  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Recharge les données lorsque les entités écoutées changent.
  @override
  void onDataChanged() => _load();

  /// Lance le chargement des données de la commande.
  void _load() {
    setState(() {
      _future = _fetch();
    });
  }

  /// Récupère la commande, son client, ses mensurations et son solde.
  ///
  /// Retourne les données agrégées ou lève une erreur si la commande est introuvable.
  Future<_OrderDetailData> _fetch() async {
    final Order? order = await _orders.findById(widget.orderId);
    if (order == null) throw StateError('Commande introuvable');
    final Client? client = await _clients.findById(order.clientId);
    MeasurementSet? set;
    List<Measurement> measurements = <Measurement>[];
    // Chargement des mensurations de référence si la commande en possède.
    if (order.measurementSetId != null) {
      set = await _measurements.findSetById(order.measurementSetId!);
      measurements = await _measurements.listMeasurements(
        order.measurementSetId!,
      );
    }
    // Calcul du total payé pour établir le solde de la commande.
    final int paid = await _payments.totalPaidForOrder(order.id);
    return _OrderDetailData(
      order: order,
      client: client,
      measurementSet: set,
      measurements: measurements,
      balance: OrderBalance(totalPrice: order.totalPrice, totalPaid: paid),
    );
  }

  /// Met à jour le statut de [order] avec [status] après validations éventuelles.
  Future<void> _changeStatus(Order order, OrderStatus status) async {
    if (status == order.status) return;
    // Annulation d'une commande ayant des paiements : confirmation requise.
    if (status == OrderStatus.cancelled) {
      final int paid = await _payments.totalPaidForOrder(order.id);
      if (!mounted) return;
      if (paid > 0) {
        final bool ok = await confirmAction(
          context,
          title: 'Annuler cette commande ?',
          message:
              'Des paiements sont enregistrés. L\'historique financier '
              'sera conservé, mais la commande sera marquée annulée.',
          confirmLabel: 'Annuler la commande',
          destructive: false,
        );
        if (!ok) return;
      }
    }
    await _orders.update(
      order.copyWith(status: status, updatedAt: DateTime.now()),
    );
    if (!mounted) return;
    _changed = true;
    showAppSnackBar(context, message: 'Statut mis à jour.');
    _load();
  }

  /// Construit l'écran de détail de la commande.
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        // Retourne un indicateur de modification à l'écran appelant.
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Commande'),
          actions: <Widget>[
            IconButton(
              onPressed: () async {
                // Navigation vers le formulaire de modification.
                final bool? changed = await context.push<bool>(
                  '/commandes/${widget.orderId}/modifier',
                );
                if (changed == true) _changed = true;
              },
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Modifier',
            ),
          ],
        ),
        body: FutureBuilder<_OrderDetailData>(
          future: _future,
          builder:
              (BuildContext context, AsyncSnapshot<_OrderDetailData> snapshot) {
                // Affichage d'un indicateur pendant le chargement.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Affichage d'un état d'erreur en cas d'échec.
                if (snapshot.hasError || !snapshot.hasData) {
                  return ErrorState(
                    message: 'Impossible de charger la commande.',
                    onRetry: _load,
                  );
                }
                final _OrderDetailData data = snapshot.data!;
                final Order order = data.order;
                // Affichage des informations détaillées de la commande.
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: <Widget>[
                    _StatusHeader(order: order),
                    const SizedBox(height: AppSpacing.lg),
                    _InfoCard(data: data),
                    const SizedBox(height: AppSpacing.lg),
                    _StatusSelector(
                      current: order.status,
                      onSelected: (OrderStatus s) => _changeStatus(order, s),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _BalanceCard(
                      balance: data.balance,
                      // Navigation vers la gestion des paiements.
                      onManagePayments: () =>
                          context.push('/commandes/${order.id}/paiements'),
                    ),
                    if (data.measurements.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.lg),
                      _MeasurementsCard(
                        set: data.measurementSet!,
                        measurements: data.measurements,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                  ],
                );
              },
        ),
      ),
    );
  }
}

/// Données agrégées nécessaires à l'affichage du détail d'une commande.
class _OrderDetailData {
  /// Crée un conteneur des données détaillées d'une commande.
  const _OrderDetailData({
    required this.order,
    required this.client,
    required this.measurementSet,
    required this.measurements,
    required this.balance,
  });

  /// Commande affichée.
  final Order order;

  /// Client associé à la commande.
  final Client? client;

  /// Jeu de mensurations de référence, le cas échéant.
  final MeasurementSet? measurementSet;

  /// Liste des mensurations associées.
  final List<Measurement> measurements;

  /// Solde financier de la commande.
  final OrderBalance balance;
}

/// En-tête affichant le statut et l'éventuel retard de la commande.
class _StatusHeader extends StatelessWidget {
  /// Crée l'en-tête de statut.
  const _StatusHeader({required this.order});

  /// Commande dont le statut est affiché.
  final Order order;

  /// Construit les badges de statut.
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        StatusBadge(status: order.status),
        if (order.isLate()) ...<Widget>[
          const SizedBox(width: AppSpacing.sm),
          const LateBadge(),
        ],
      ],
    );
  }
}

/// Carte affichant les informations principales de la commande.
class _InfoCard extends StatelessWidget {
  /// Crée la carte d'informations.
  const _InfoCard({required this.data});

  /// Données détaillées de la commande.
  final _OrderDetailData data;

  /// Construit la carte d'informations.
  @override
  Widget build(BuildContext context) {
    final Order order = data.order;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                // Affichage de l'image du modèle ou d'une icône par défaut.
                if (order.modelImageSnapshotPath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: LocalImage(
                        path: order.modelImageSnapshotPath,
                        label: order.modelNameSnapshot,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSmall,
                      ),
                    ),
                    child: const Icon(Icons.checkroom_outlined),
                  ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        order.modelNameSnapshot ?? 'Modèle personnalisé',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (data.client != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          data.client!.fullName,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xl),
            _InfoRow(
              icon: Icons.numbers,
              label: 'Quantité',
              value: '${order.quantity}',
            ),
            _InfoRow(
              icon: Icons.payments_outlined,
              label: 'Prix total',
              value: Formatters.money(order.totalPrice),
            ),
            _InfoRow(
              icon: Icons.calendar_month_outlined,
              label: 'Livraison prévue',
              value: Formatters.date(order.deliveryAt),
            ),
            // Affichage conditionnel de la description.
            if (order.description != null && order.description!.isNotEmpty)
              _InfoRow(
                icon: Icons.notes_outlined,
                label: 'Description',
                value: order.description!,
              ),
            // Affichage conditionnel des notes.
            if (order.notes != null && order.notes!.isNotEmpty)
              _InfoRow(
                icon: Icons.sticky_note_2_outlined,
                label: 'Notes',
                value: order.notes!,
              ),
          ],
        ),
      ),
    );
  }
}

/// Ligne d'information composée d'une icône, d'un libellé et d'une valeur.
class _InfoRow extends StatelessWidget {
  /// Crée une ligne d'information.
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  /// Icône associée à l'information.
  final IconData icon;

  /// Libellé de l'information.
  final String label;

  /// Valeur à afficher.
  final String value;

  /// Construit la ligne d'information.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sélecteur permettant de modifier le statut de la commande.
class _StatusSelector extends StatelessWidget {
  /// Crée le sélecteur de statut.
  const _StatusSelector({required this.current, required this.onSelected});

  /// Statut actuellement sélectionné.
  final OrderStatus current;

  /// Rappel déclenché lors de la sélection d'un statut.
  final ValueChanged<OrderStatus> onSelected;

  /// Construit la liste des statuts sélectionnables.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Statut',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: OrderStatus.values.map((OrderStatus status) {
            return ChoiceChip(
              label: Text(status.label),
              selected: current == status,
              onSelected: (_) => onSelected(status),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Carte présentant le solde financier de la commande.
class _BalanceCard extends StatelessWidget {
  /// Crée la carte de solde.
  const _BalanceCard({required this.balance, required this.onManagePayments});

  /// Solde financier de la commande.
  final OrderBalance balance;

  /// Action de navigation vers la gestion des paiements.
  final VoidCallback onManagePayments;

  /// Construit la carte de solde et le bouton de gestion.
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Paiements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.md),
            _balanceRow('Total payé', Formatters.money(balance.totalPaid)),
            _balanceRow(
              balance.isOverpaid ? 'Trop-perçu' : 'Reste à payer',
              Formatters.money(
                // Affiche le montant trop-perçu ou le reste à payer selon le solde.
                balance.isOverpaid ? balance.overpaidAmount : balance.remaining,
              ),
              highlight: !balance.isSettled,
              color: balance.isOverpaid
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onManagePayments,
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Gérer les paiements'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit une ligne de résumé du solde.
  ///
  /// [label] est le libellé affiché et [value] le montant correspondant.
  Widget _balanceRow(
    String label,
    String value, {
    bool highlight = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte affichant les mensurations de référence de la commande.
class _MeasurementsCard extends StatelessWidget {
  /// Crée la carte des mensurations.
  const _MeasurementsCard({required this.set, required this.measurements});

  /// Jeu de mensurations associé.
  final MeasurementSet set;

  /// Liste des mesures à afficher.
  final List<Measurement> measurements;

  /// Construit la carte des mensurations.
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.straighten, size: 18),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Mensurations de référence',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${set.garmentType} — prise le ${Formatters.date(set.measuredAt)}',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Affichage de chaque mesure du jeu sélectionné.
            for (final Measurement m in measurements)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text(m.name)),
                    Text(
                      Formatters.measurement(m.value, m.unit),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
