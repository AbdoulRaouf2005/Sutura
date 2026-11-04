import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/client_repository.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../core/repositories/payment_repository.dart';
import '../../../core/state/data_controller.dart';
import '../../../core/state/data_events_listener.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/formatters/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../orders/models/order.dart';

/// Données synthétiques du tableau de bord (cahier des charges §4.1).
class DashboardData {
  const DashboardData({
    required this.activeOrders,
    required this.lateOrders,
    required this.upcomingOrders,
    required this.totalOutstanding,
    required this.clientCount,
  });

  final int activeOrders;
  final int lateOrders;
  final List<Order> upcomingOrders;
  final int totalOutstanding;
  final int clientCount;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with DataEventsListener<DashboardScreen> {
  final OrderRepository _orders = OrderRepository();
  final PaymentRepository _payments = PaymentRepository();
  final ClientRepository _clients = ClientRepository();

  Future<DashboardData>? _future;

  @override
  Set<DataEntity> get dataEntities => const <DataEntity>{
    DataEntity.orders,
    DataEntity.payments,
    DataEntity.clients,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void onDataChanged() => _load();

  Future<void> _load() async {
    final Future<DashboardData> future = _fetch();
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<DashboardData> _fetch() async {
    final int active = await _orders.countActive();
    final int late = await _orders.countLate();
    final List<Order> upcoming = await _orders.upcomingWithin(7);
    final int outstanding = await _payments.totalOutstanding();
    final int clientCount = await _clients.countActive();
    return DashboardData(
      activeOrders: active,
      lateOrders: late,
      upcomingOrders: upcoming,
      totalOutstanding: outstanding,
      clientCount: clientCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: FutureBuilder<DashboardData>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<DashboardData> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErrorState(
                message: 'Impossible de charger le tableau de bord.',
                onRetry: _load,
              );
            }
            final DashboardData data = snapshot.data!;
            if (data.activeOrders == 0 && data.clientCount == 0) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: <Widget>[
                  const SizedBox(height: AppSpacing.xxl),
                  const EmptyState(
                    icon: Icons.storefront_outlined,
                    message:
                        'Bienvenue dans Sutura.\nAjoutez votre premier client '
                        'pour commencer à organiser votre atelier.',
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: <Widget>[
                _KpiGrid(data: data),
                const SizedBox(height: AppSpacing.xl),
                _SectionTitle(
                  icon: Icons.calendar_month_outlined,
                  label: 'À livrer bientôt',
                  actionLabel: 'Voir tout',
                  onAction: () => context.push('/commandes'),
                ),
                const SizedBox(height: AppSpacing.md),
                _UpcomingList(orders: data.upcomingOrders),
                const SizedBox(height: AppSpacing.xl),
                _SectionTitle(
                  icon: Icons.add_circle_outline,
                  label: 'Actions rapides',
                ),
                const SizedBox(height: AppSpacing.md),
                _QuickActions(
                  onNewClient: () => context.push('/clients/nouveau'),
                  onNewOrder: () => context.push('/commandes/nouvelle'),
                  onGallery: () => context.push('/galerie'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _KpiCard(
                icon: Icons.assignment_outlined,
                label: 'En cours',
                value: '${data.activeOrders}',
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _KpiCard(
                icon: Icons.warning_amber_rounded,
                label: 'En retard',
                value: '${data.lateOrders}',
                color: AppSemanticColors.of(context).error,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _KpiCard(
          icon: Icons.payments_outlined,
          label: 'Restant à encaisser',
          value: Formatters.money(data.totalOutstanding),
          color: AppSemanticColors.of(context).success,
          wide: true,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.wide = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.label,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        if (onAction != null && actionLabel != null) ...<Widget>[
          const Spacer(),
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    );
  }
}

class _UpcomingList extends StatelessWidget {
  const _UpcomingList({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text('Aucune livraison prévue dans les 7 prochains jours.'),
        ),
      );
    }
    return Column(
      children: orders.take(5).map((Order order) {
        final bool late = order.isLate();
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            leading: const Icon(Icons.local_mall_outlined),
            title: Text(order.modelNameSnapshot ?? 'Commande'),
            subtitle: Text('Livraison : ${Formatters.date(order.deliveryAt)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  late ? 'En retard' : order.status.label,
                  style: late
                      ? TextStyle(
                          color: AppSemanticColors.of(context).error,
                          fontWeight: FontWeight.w600,
                        )
                      : null,
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => context.push('/commandes/${order.id}'),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onNewClient,
    required this.onNewOrder,
    required this.onGallery,
  });

  final VoidCallback onNewClient;
  final VoidCallback onNewOrder;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _ActionTile(
            icon: Icons.person_add_alt,
            label: 'Nouveau\nclient',
            onTap: onNewClient,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionTile(
            icon: Icons.note_add_outlined,
            label: 'Nouvelle\ncommande',
            onTap: onNewOrder,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionTile(
            icon: Icons.photo_library_outlined,
            label: 'Galerie',
            onTap: onGallery,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            children: <Widget>[
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 26,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
