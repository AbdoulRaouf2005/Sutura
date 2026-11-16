import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/client_repository.dart';
import '../../../core/repositories/measurement_repository.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../core/state/data_controller.dart';
import '../../../core/state/data_events_listener.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/formatters/formatters.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../measurements/models/measurement_set.dart';
import '../../orders/models/order.dart';
import '../models/client.dart';

/// Écran affichant la fiche détaillée d'un client.
///
/// Présente les informations du client, ses mensurations récentes
/// et l'historique de ses commandes (§4.2).
class ClientDetailScreen extends StatefulWidget {
  /// Crée l'écran de détail pour le client identifié par [clientId].
  const ClientDetailScreen({super.key, required this.clientId});

  /// Identifiant du client à afficher.
  final String clientId;

  /// Crée l'état associé à cet écran.
  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

/// État de [ClientDetailScreen] gérant le chargement et les actions de la fiche.
class _ClientDetailScreenState extends State<ClientDetailScreen>
    with DataEventsListener<ClientDetailScreen> {
  /// Dépôt pour accéder aux données des clients.
  final ClientRepository _clients = ClientRepository();

  /// Dépôt pour accéder aux commandes du client.
  final OrderRepository _orders = OrderRepository();

  /// Dépôt pour accéder aux mensurations du client.
  final MeasurementRepository _measurements = MeasurementRepository();

  /// Future contenant les données agrégées de la fiche client.
  Future<_ClientDetailData>? _future;

  /// Entités de données écoutées pour rafraîchir l'écran.
  @override
  Set<DataEntity> get dataEntities => const <DataEntity>{
    DataEntity.clients,
    DataEntity.orders,
    DataEntity.measurements,
  };

  /// Initialise l'état et déclenche le chargement initial des données.
  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Recharge les données lorsque les entités écoutées changent.
  @override
  void onDataChanged() => _load();

  /// Lance le chargement des données de la fiche client.
  void _load() {
    // Met à jour la future pour déclencher la reconstruction du FutureBuilder.
    setState(() {
      _future = _fetch();
    });
  }

  /// Récupère le client, ses commandes et ses mensurations.
  ///
  /// Retourne un agrégat [_ClientDetailData] ou lève une erreur si le client est introuvable.
  Future<_ClientDetailData> _fetch() async {
    final Client? client = await _clients.findById(widget.clientId);
    if (client == null) throw StateError('Client introuvable');
    final List<Order> orders = await _orders.list(clientId: widget.clientId);
    final List<MeasurementSet> sets = await _measurements.listSetsForClient(
      widget.clientId,
    );
    return _ClientDetailData(client: client, orders: orders, sets: sets);
  }

  /// Archive le [client] après confirmation de l'utilisateur.
  ///
  /// Met à jour le dépôt puis revient à l'écran précédent si le widget est monté.
  Future<void> _archive(Client client) async {
    // Demande de confirmation avant l'archivage.
    final bool confirmed = await confirmAction(
      context,
      title: 'Archiver ce client ?',
      message:
          'Il ne sera plus proposé dans les nouvelles sélections, '
          'mais son historique sera conservé.',
      confirmLabel: 'Archiver',
    );
    if (!confirmed) return;
    // Mise à jour du client en base avec l'état archivé.
    await _clients.update(
      client.copyWith(isArchived: true, updatedAt: DateTime.now()),
    );
    if (!mounted) return;
    showAppSnackBar(context, message: 'Client archivé.');
    // Retour à l'écran précédent avec un résultat positif.
    context.pop(true);
  }

  /// Construit l'interface de la fiche client.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiche client'),
        actions: <Widget>[
          FutureBuilder<_ClientDetailData>(
            future: _future,
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<_ClientDetailData> snapshot,
                ) {
                  // Masque le menu tant que les données ne sont pas disponibles.
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final Client client = snapshot.data!.client;
                  return PopupMenuButton<String>(
                    onSelected: (String value) async {
                      // Navigation ou action selon l'option sélectionnée.
                      switch (value) {
                        case 'edit':
                          await context.push('/clients/${client.id}/modifier');
                        case 'archive':
                          await _archive(client);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Modifier'),
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'archive',
                            child: ListTile(
                              leading: Icon(Icons.archive_outlined),
                              title: Text('Archiver'),
                            ),
                          ),
                        ],
                  );
                },
          ),
        ],
      ),
      body: FutureBuilder<_ClientDetailData>(
        future: _future,
        builder:
            (BuildContext context, AsyncSnapshot<_ClientDetailData> snapshot) {
              // Affiche un indicateur pendant le chargement.
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // Affiche un état d'erreur en cas d'échec du chargement.
              if (snapshot.hasError || !snapshot.hasData) {
                return ErrorState(
                  message: 'Impossible de charger la fiche client.',
                  onRetry: _load,
                );
              }
              final _ClientDetailData data = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: <Widget>[
                  _Header(client: data.client),
                  const SizedBox(height: AppSpacing.xl),
                  _MeasuresSection(
                    sets: data.sets,
                    onViewAll: () =>
                        // Navigation vers la liste complète des mensurations.
                        context.push(
                          '/clients/${widget.clientId}/mensurations',
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _OrdersSection(orders: data.orders),
                ],
              );
            },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            // Navigation vers la création d'une commande pour ce client.
            context.push('/commandes/nouvelle?clientId=${widget.clientId}'),
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Nouvelle commande'),
      ),
    );
  }
}

/// Agrégat des données nécessaires à l'affichage de la fiche client.
class _ClientDetailData {
  /// Crée un agrégat contenant le [client], ses [orders] et ses [sets].
  const _ClientDetailData({
    required this.client,
    required this.orders,
    required this.sets,
  });

  /// Client affiché.
  final Client client;

  /// Commandes associées au client.
  final List<Order> orders;

  /// Jeux de mensurations associés au client.
  final List<MeasurementSet> sets;
}

/// En-tête affichant les informations principales du client.
class _Header extends StatelessWidget {
  /// Crée l'en-tête pour le [client] donné.
  const _Header({required this.client});

  /// Client dont les informations sont affichées.
  final Client client;

  /// Construit la carte d'en-tête du client.
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
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        client.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (client.isArchived) ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'Archivé',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (client.phone != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  const Icon(Icons.phone_outlined, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text(client.phone!),
                ],
              ),
            ],
            if (client.notes != null && client.notes!.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.notes_outlined, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(client.notes!)),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Client depuis le ${Formatters.date(client.createdAt)}',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section présentant un aperçu des jeux de mensurations du client.
class _MeasuresSection extends StatelessWidget {
  /// Crée la section des mensurations avec [sets] et l'action [onViewAll].
  const _MeasuresSection({required this.sets, required this.onViewAll});

  /// Jeux de mensurations à présenter.
  final List<MeasurementSet> sets;

  /// Action déclenchée pour consulter ou ajouter des mensurations.
  final VoidCallback onViewAll;

  /// Construit l'aperçu des mensurations du client.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.straighten, size: 18),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'Mensurations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton(
              onPressed: onViewAll,
              child: Text(sets.isEmpty ? 'Ajouter' : 'Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (sets.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text('Aucune mensuration enregistrée.'),
            ),
          )
        else
          Card(
            child: Column(
              // Affiche au maximum deux jeux récents en aperçu.
              children: sets.take(2).map((MeasurementSet set) {
                return ListTile(
                  leading: const Icon(Icons.straighten),
                  title: Text(set.garmentType),
                  subtitle: Text('Prise le ${Formatters.date(set.measuredAt)}'),
                  onTap: onViewAll,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

/// Section affichant la liste des commandes du client.
class _OrdersSection extends StatelessWidget {
  /// Crée la section des commandes à partir de [orders].
  const _OrdersSection({required this.orders});

  /// Commandes associées au client.
  final List<Order> orders;

  /// Construit la liste des commandes du client.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: const <Widget>[
            Icon(Icons.assignment_outlined, size: 18),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Commandes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (orders.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text('Aucune commande pour ce client.'),
            ),
          )
        else
          Column(
            children: orders.map((Order order) {
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  title: Text(order.modelNameSnapshot ?? 'Commande'),
                  subtitle: Text(
                    'Livraison : ${Formatters.date(order.deliveryAt)} • '
                    '${Formatters.money(order.totalPrice)}',
                  ),
                  trailing: order.isLate()
                      ? const LateBadge()
                      : StatusBadge(status: order.status),
                  onTap: () =>
                      // Navigation vers le détail de la commande.
                      context.push('/commandes/${order.id}'),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
