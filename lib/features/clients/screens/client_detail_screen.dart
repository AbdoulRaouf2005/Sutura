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

/// Fiche client : informations, historique des commandes et accès aux
/// mensurations (§4.2).
class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  final String clientId;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen>
    with DataEventsListener<ClientDetailScreen> {
  final ClientRepository _clients = ClientRepository();
  final OrderRepository _orders = OrderRepository();
  final MeasurementRepository _measurements = MeasurementRepository();

  Future<_ClientDetailData>? _future;

  @override
  Set<DataEntity> get dataEntities => const <DataEntity>{
        DataEntity.clients,
        DataEntity.orders,
        DataEntity.measurements,
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void onDataChanged() => _load();

  void _load() {
    setState(() {
      _future = _fetch();
    });
  }

  Future<_ClientDetailData> _fetch() async {
    final Client? client = await _clients.findById(widget.clientId);
    if (client == null) throw StateError('Client introuvable');
    final List<Order> orders = await _orders.list(clientId: widget.clientId);
    final List<MeasurementSet> sets =
        await _measurements.listSetsForClient(widget.clientId);
    return _ClientDetailData(client: client, orders: orders, sets: sets);
  }

  Future<void> _archive(Client client) async {
    final bool confirmed = await confirmAction(
      context,
      title: 'Archiver ce client ?',
      message: 'Il ne sera plus proposé dans les nouvelles sélections, '
          'mais son historique sera conservé.',
      confirmLabel: 'Archiver',
    );
    if (!confirmed) return;
    await _clients.update(
      client.copyWith(isArchived: true, updatedAt: DateTime.now()),
    );
    if (!mounted) return;
    showAppSnackBar(context, message: 'Client archivé.');
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiche client'),
        actions: <Widget>[
          FutureBuilder<_ClientDetailData>(
            future: _future,
            builder: (BuildContext context,
                AsyncSnapshot<_ClientDetailData> snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final Client client = snapshot.data!.client;
              return PopupMenuButton<String>(
                onSelected: (String value) async {
                  switch (value) {
                    case 'edit':
                      await context.push('/clients/${client.id}/modifier');
                    case 'archive':
                      await _archive(client);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
        builder: (BuildContext context,
            AsyncSnapshot<_ClientDetailData> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
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
                    context.push('/clients/${widget.clientId}/mensurations'),
              ),
              const SizedBox(height: AppSpacing.xl),
              _OrdersSection(orders: data.orders),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/commandes/nouvelle?clientId=${widget.clientId}'),
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Nouvelle commande'),
      ),
    );
  }
}

class _ClientDetailData {
  const _ClientDetailData({
    required this.client,
    required this.orders,
    required this.sets,
  });

  final Client client;
  final List<Order> orders;
  final List<MeasurementSet> sets;
}

class _Header extends StatelessWidget {
  const _Header({required this.client});

  final Client client;

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
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasuresSection extends StatelessWidget {
  const _MeasuresSection({required this.sets, required this.onViewAll});

  final List<MeasurementSet> sets;
  final VoidCallback onViewAll;

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

class _OrdersSection extends StatelessWidget {
  const _OrdersSection({required this.orders});

  final List<Order> orders;

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
                  onTap: () => context.push('/commandes/${order.id}'),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
