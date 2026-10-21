import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/client_repository.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/formatters/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/order.dart';

/// Liste des commandes et suivi des échéances (cahier des charges §4.5).
///
/// Les formulaires de création/modification seront ajoutés à l'étape suivante.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderRepository _orders = OrderRepository();
  final ClientRepository _clients = ClientRepository();

  Future<List<Order>>? _future;
  final Map<String, String> _clientNames = <String, String>{};
  OrderStatus? _filter;

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

  Future<List<Order>> _fetch() async {
    final List<Order> orders = await _orders.list(status: _filter);
    for (final Order order in orders) {
      if (!_clientNames.containsKey(order.clientId)) {
        final client = await _clients.findById(order.clientId);
        _clientNames[order.clientId] = client?.fullName ?? 'Client inconnu';
      }
    }
    return orders;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commandes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final bool? changed = await context.push<bool>('/commandes/nouvelle');
          if (changed == true) _load();
        },
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Nouvelle'),
      ),
      body: Column(
        children: <Widget>[
          _FilterBar(
            selected: _filter,
            onSelected: (OrderStatus? status) {
              _filter = status;
              _load();
            },
          ),
          Expanded(
            child: FutureBuilder<List<Order>>(
              future: _future,
              builder: (BuildContext context,
                  AsyncSnapshot<List<Order>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return ErrorState(
                    message: 'Impossible de charger les commandes.',
                    onRetry: _load,
                  );
                }
                final List<Order> orders = snapshot.data ?? <Order>[];
                if (orders.isEmpty) {
                  return EmptyState(
                    icon: Icons.assignment_outlined,
                    message: _filter == null
                        ? 'Aucune commande pour le moment. Créez une commande '
                            'pour commencer le suivi.'
                        : 'Aucune commande avec ce statut.',
                    actionLabel: _filter == null ? 'Nouvelle commande' : null,
                    onAction: _filter == null ? () {} : null,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxl * 2,
                  ),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (BuildContext context, int index) {
                    final Order order = orders[index];
                    return _OrderCard(
                      order: order,
                      clientName:
                          _clientNames[order.clientId] ?? 'Client inconnu',
                      onTap: () async {
                        final bool? changed = await context
                            .push<bool>('/commandes/${order.id}');
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
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
          ...OrderStatus.values.map(
            (OrderStatus status) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(status.label),
                selected: selected == status,
                onSelected: (_) => onSelected(status),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.clientName,
    required this.onTap,
  });

  final Order order;
  final String clientName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      clientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    Formatters.money(order.totalPrice),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                order.modelNameSnapshot ?? 'Modèle personnalisé',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  StatusBadge(status: order.status),
                  if (order.isLate()) ...<Widget>[
                    const SizedBox(width: AppSpacing.sm),
                    const LateBadge(),
                  ],
                  const Spacer(),
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 15,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    Formatters.date(order.deliveryAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
