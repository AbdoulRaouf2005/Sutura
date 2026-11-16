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
  /// Crée une instance des données du tableau de bord.
  const DashboardData({
    required this.activeOrders,
    required this.lateOrders,
    required this.upcomingOrders,
    required this.totalOutstanding,
    required this.clientCount,
  });

  /// Nombre de commandes actuellement actives.
  final int activeOrders;

  /// Nombre de commandes en retard.
  final int lateOrders;

  /// Liste des commandes à livrer prochainement.
  final List<Order> upcomingOrders;

  /// Montant total restant à encaisser.
  final int totalOutstanding;

  /// Nombre de clients actifs.
  final int clientCount;
}

/// Écran d'accueil affichant les indicateurs clés et les actions rapides.
class DashboardScreen extends StatefulWidget {
  /// Crée l'écran du tableau de bord.
  const DashboardScreen({super.key});

  /// Crée l'état associé à cet écran.
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

/// État de [DashboardScreen] chargé de récupérer et d'afficher les données.
class _DashboardScreenState extends State<DashboardScreen>
    with DataEventsListener<DashboardScreen> {
  /// Dépôt des commandes.
  final OrderRepository _orders = OrderRepository();

  /// Dépôt des paiements.
  final PaymentRepository _payments = PaymentRepository();

  /// Dépôt des clients.
  final ClientRepository _clients = ClientRepository();

  /// Futur contenant les données du tableau de bord.
  Future<DashboardData>? _future;

  /// Entités dont les changements déclenchent un rechargement.
  @override
  Set<DataEntity> get dataEntities => const <DataEntity>{
    DataEntity.orders,
    DataEntity.payments,
    DataEntity.clients,
  };

  /// Initialise l'état et lance le premier chargement des données.
  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Recharge les données lorsque les entités écoutées sont modifiées.
  @override
  void onDataChanged() => _load();

  /// Lance le chargement des données et met à jour le futur affiché.
  Future<void> _load() async {
    final Future<DashboardData> future = _fetch();
    setState(() {
      _future = future;
    });
    await future;
  }

  /// Récupère les indicateurs et listes nécessaires au tableau de bord.
  ///
  /// Retourne une instance de [DashboardData] agrégée depuis les dépôts.
  Future<DashboardData> _fetch() async {
    // Récupération des indicateurs de commandes, paiements et clients.
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

  /// Construit l'interface du tableau de bord selon l'état du chargement.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: FutureBuilder<DashboardData>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<DashboardData> snapshot) {
            // Affichage d'un indicateur pendant le chargement.
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // Affichage d'un état d'erreur en cas d'échec.
            if (snapshot.hasError) {
              return ErrorState(
                message: 'Impossible de charger le tableau de bord.',
                onRetry: _load,
              );
            }
            final DashboardData data = snapshot.data!;
            // Affichage d'un message d'accueil si aucune donnée n'existe encore.
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
            // Affichage des indicateurs, des livraisons à venir et des actions.
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

/// Grille des indicateurs clés du tableau de bord.
class _KpiGrid extends StatelessWidget {
  /// Crée la grille des indicateurs.
  const _KpiGrid({required this.data});

  /// Données à afficher dans les indicateurs.
  final DashboardData data;

  /// Construit les cartes d'indicateurs.
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

/// Carte affichant un indicateur clé (KPI).
class _KpiCard extends StatelessWidget {
  /// Crée une carte d'indicateur.
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.wide = false,
  });

  /// Icône associée à l'indicateur.
  final IconData icon;

  /// Libellé de l'indicateur.
  final String label;

  /// Valeur affichée de l'indicateur.
  final String value;

  /// Couleur principale de l'indicateur.
  final Color color;

  /// Indique si la carte occupe toute la largeur.
  final bool wide;

  /// Construit la carte d'indicateur.
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

/// Titre de section avec icône et action optionnelle.
class _SectionTitle extends StatelessWidget {
  /// Crée un titre de section.
  const _SectionTitle({
    required this.icon,
    required this.label,
    this.actionLabel,
    this.onAction,
  });

  /// Icône affichée avant le libellé.
  final IconData icon;

  /// Libellé de la section.
  final String label;

  /// Libellé du bouton d'action optionnel.
  final String? actionLabel;

  /// Action déclenchée par le bouton optionnel.
  final VoidCallback? onAction;

  /// Construit le titre de section.
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

/// Liste des prochaines commandes à livrer.
class _UpcomingList extends StatelessWidget {
  /// Crée la liste des livraisons à venir.
  const _UpcomingList({required this.orders});

  /// Commandes à afficher.
  final List<Order> orders;

  /// Construit la liste ou un message si aucune livraison n'est prévue.
  @override
  Widget build(BuildContext context) {
    // Affichage d'un message si aucune livraison n'est prévue.
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
        // Détermination du retard pour adapter le libellé et le style.
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
            // Navigation vers le détail de la commande sélectionnée.
            onTap: () => context.push('/commandes/${order.id}'),
          ),
        );
      }).toList(),
    );
  }
}

/// Section des actions rapides du tableau de bord.
class _QuickActions extends StatelessWidget {
  /// Crée la section des actions rapides.
  const _QuickActions({
    required this.onNewClient,
    required this.onNewOrder,
    required this.onGallery,
  });

  /// Action de création d'un nouveau client.
  final VoidCallback onNewClient;

  /// Action de création d'une nouvelle commande.
  final VoidCallback onNewOrder;

  /// Action d'ouverture de la galerie.
  final VoidCallback onGallery;

  /// Construit les tuiles d'actions rapides.
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

/// Tuile cliquable représentant une action rapide.
class _ActionTile extends StatelessWidget {
  /// Crée une tuile d'action.
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  /// Icône de l'action.
  final IconData icon;

  /// Libellé de l'action.
  final String label;

  /// Action déclenchée lors du clic.
  final VoidCallback onTap;

  /// Construit la tuile d'action.
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
