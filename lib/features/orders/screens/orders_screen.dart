import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/order_repository.dart';
import '../../../core/state/data_controller.dart';
import '../../../core/state/data_events_listener.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/formatters/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/order.dart';

/// Écran listant les commandes et permettant le suivi des échéances.
class OrdersScreen extends StatefulWidget {
  /// Crée l'écran des commandes.
  const OrdersScreen({super.key});

  /// Crée l'état associé à cet écran.
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

/// État de [OrdersScreen] gérant le chargement, le filtre et l'affichage.
class _OrdersScreenState extends State<OrdersScreen>
    with DataEventsListener<OrdersScreen> {
  /// Dépôt des commandes.
  final OrderRepository _orders = OrderRepository();

  /// Futur contenant la liste des commandes à afficher.
  Future<List<OrderWithClient>>? _future;

  /// Filtre de statut actuellement appliqué.
  OrderStatus? _filter;

  /// Entités dont les changements déclenchent un rechargement.
  @override
  Set<DataEntity> get dataEntities => const <DataEntity>{
    DataEntity.orders,
    DataEntity.clients,
  };

  /// Initialise l'état et charge les commandes.
  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Recharge la liste lorsque les données écoutées changent.
  @override
  void onDataChanged() => _load();

  /// Lance le chargement de la liste des commandes.
  void _load() {
    setState(() {
      _future = _fetch();
    });
  }

  /// Récupère les commandes avec le nom du client selon le filtre courant.
  Future<List<OrderWithClient>> _fetch() async {
    return _orders.listWithClientNames(status: _filter);
  }

  /// Construit l'interface de la liste des commandes.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commandes')),
      floatingActionButton: FloatingActionButton.extended(
        // Navigation vers le formulaire de création d'une commande.
        onPressed: () => context.push('/commandes/nouvelle'),
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Nouvelle'),
      ),
      body: Column(
        children: <Widget>[
          _FilterBar(
            selected: _filter,
            onSelected: (OrderStatus? status) {
              // Mise à jour du filtre puis rechargement de la liste.
              _filter = status;
              _load();
            },
          ),
          Expanded(
            child: FutureBuilder<List<OrderWithClient>>(
              future: _future,
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<OrderWithClient>> snapshot,
                  ) {
                    // Affichage d'un indicateur pendant le chargement.
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    // Affichage d'un état d'erreur en cas d'échec.
                    if (snapshot.hasError) {
                      return ErrorState(
                        message: 'Impossible de charger les commandes.',
                        onRetry: _load,
                      );
                    }
                    final List<OrderWithClient> orders =
                        snapshot.data ?? <OrderWithClient>[];
                    // Affichage d'un état vide si aucune commande ne correspond.
                    if (orders.isEmpty) {
                      return EmptyState(
                        icon: Icons.assignment_outlined,
                        message: _filter == null
                            ? 'Aucune commande pour le moment. Créez une commande '
                                  'pour commencer le suivi.'
                            : 'Aucune commande avec ce statut.',
                        actionLabel: _filter == null
                            ? 'Nouvelle commande'
                            : null,
                        onAction: _filter == null ? () {} : null,
                      );
                    }
                    // Affichage de la liste des commandes.
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
                        final OrderWithClient entry = orders[index];
                        final Order order = entry.order;
                        return _OrderCard(
                          order: order,
                          clientName: entry.clientName,
                          onTap: () => context.push('/commandes/${order.id}'),
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

/// Barre de filtres permettant de sélectionner un statut de commande.
class _FilterBar extends StatelessWidget {
  /// Crée la barre de filtres.
  const _FilterBar({required this.selected, required this.onSelected});

  /// Statut actuellement sélectionné, ou `null` pour toutes les commandes.
  final OrderStatus? selected;

  /// Rappel déclenché lors du changement de filtre.
  final ValueChanged<OrderStatus?> onSelected;

  /// Construit la barre de filtres horizontale.
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

/// Carte résumant une commande dans la liste.
class _OrderCard extends StatelessWidget {
  /// Crée une carte de commande.
  const _OrderCard({
    required this.order,
    required this.clientName,
    required this.onTap,
  });

  /// Commande à afficher.
  final Order order;

  /// Nom du client associé.
  final String clientName;

  /// Action déclenchée lors du clic sur la carte.
  final VoidCallback onTap;

  /// Construit la carte de commande.
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
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  StatusBadge(status: order.status),
                  // Affichage du badge de retard si nécessaire.
                  if (order.isLate()) ...<Widget>[
                    const SizedBox(width: AppSpacing.sm),
                    const LateBadge(),
                  ],
                  const Spacer(),
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 15,
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    Formatters.date(order.deliveryAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface
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
