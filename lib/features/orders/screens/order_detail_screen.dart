import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/client_repository.dart';
import '../../../core/repositories/measurement_repository.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../core/repositories/payment_repository.dart';
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

/// Détail d'une commande : informations, modèle et mensurations de référence,
/// statut, solde et accès aux paiements (§4.5 et §4.6).
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderRepository _orders = OrderRepository();
  final ClientRepository _clients = ClientRepository();
  final MeasurementRepository _measurements = MeasurementRepository();
  final PaymentRepository _payments = PaymentRepository();

  Future<_OrderDetailData>? _future;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = _fetch();
    });
  }

  Future<_OrderDetailData> _fetch() async {
    final Order? order = await _orders.findById(widget.orderId);
    if (order == null) throw StateError('Commande introuvable');
    final Client? client = await _clients.findById(order.clientId);
    MeasurementSet? set;
    List<Measurement> measurements = <Measurement>[];
    if (order.measurementSetId != null) {
      set = await _measurements.findSetById(order.measurementSetId!);
      measurements = await _measurements.listMeasurements(order.measurementSetId!);
    }
    final int paid = await _payments.totalPaidForOrder(order.id);
    return _OrderDetailData(
      order: order,
      client: client,
      measurementSet: set,
      measurements: measurements,
      balance: OrderBalance(totalPrice: order.totalPrice, totalPaid: paid),
    );
  }

  Future<void> _changeStatus(Order order, OrderStatus status) async {
    if (status == order.status) return;
    // Annulation d'une commande ayant des paiements : confirmation (§4.5).
    if (status == OrderStatus.cancelled) {
      final int paid = await _payments.totalPaidForOrder(order.id);
      if (!mounted) return;
      if (paid > 0) {
        final bool ok = await confirmAction(
          context,
          title: 'Annuler cette commande ?',
          message: 'Des paiements sont enregistrés. L\'historique financier '
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Commande'),
          actions: <Widget>[
            IconButton(
              onPressed: () async {
                final bool? changed = await context.push<bool>(
                  '/commandes/${widget.orderId}/modifier',
                );
                if (changed == true) {
                  _changed = true;
                  _load();
                }
              },
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Modifier',
            ),
          ],
        ),
        body: FutureBuilder<_OrderDetailData>(
        future: _future,
        builder: (BuildContext context,
            AsyncSnapshot<_OrderDetailData> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorState(
              message: 'Impossible de charger la commande.',
              onRetry: _load,
            );
          }
          final _OrderDetailData data = snapshot.data!;
          final Order order = data.order;
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
                onManagePayments: () async {
                  final bool? changed = await context.push<bool>(
                    '/commandes/${order.id}/paiements',
                  );
                  if (changed == true) _load();
                },
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

class _OrderDetailData {
  const _OrderDetailData({
    required this.order,
    required this.client,
    required this.measurementSet,
    required this.measurements,
    required this.balance,
  });

  final Order order;
  final Client? client;
  final MeasurementSet? measurementSet;
  final List<Measurement> measurements;
  final OrderBalance balance;
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.order});

  final Order order;

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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.data});

  final _OrderDetailData data;

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
                if (order.modelImageSnapshotPath != null)
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSmall),
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
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.06),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSmall),
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
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
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
            if (order.description != null && order.description!.isNotEmpty)
              _InfoRow(
                icon: Icons.notes_outlined,
                label: 'Description',
                value: order.description!,
              ),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

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
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
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

class _StatusSelector extends StatelessWidget {
  const _StatusSelector({required this.current, required this.onSelected});

  final OrderStatus current;
  final ValueChanged<OrderStatus> onSelected;

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

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.onManagePayments,
  });

  final OrderBalance balance;
  final VoidCallback onManagePayments;

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

  Widget _balanceRow(String label, String value,
      {bool highlight = false, Color? color}) {
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

class _MeasurementsCard extends StatelessWidget {
  const _MeasurementsCard({required this.set, required this.measurements});

  final MeasurementSet set;
  final List<Measurement> measurements;

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
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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
