import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/client_repository.dart';
import '../../../core/repositories/measurement_repository.dart';
import '../../../core/state/data_controller.dart';
import '../../../core/state/data_events_listener.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/formatters/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../clients/models/client.dart';
import '../models/measurement_set.dart';

/// Liste des jeux de mensurations d'un client, du plus récent au plus ancien.
/// Une nouvelle prise n'écrase jamais l'historique (§4.3).
class MeasurementsListScreen extends StatefulWidget {
  const MeasurementsListScreen({super.key, required this.clientId});

  final String clientId;

  @override
  State<MeasurementsListScreen> createState() => _MeasurementsListScreenState();
}

class _MeasurementsListScreenState extends State<MeasurementsListScreen>
    with DataEventsListener<MeasurementsListScreen> {
  final MeasurementRepository _repo = MeasurementRepository();
  final ClientRepository _clients = ClientRepository();

  Future<_MeasurementsListData>? _future;

  @override
  Set<DataEntity> get dataEntities => const <DataEntity>{
        DataEntity.measurements,
        DataEntity.clients,
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

  Future<_MeasurementsListData> _fetch() async {
    final Client? client = await _clients.findById(widget.clientId);
    final List<MeasurementSet> sets =
        await _repo.listSetsForClient(widget.clientId);
    return _MeasurementsListData(client: client, sets: sets);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mensurations')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/clients/${widget.clientId}/mensurations/nouveau'),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: FutureBuilder<_MeasurementsListData>(
        future: _future,
        builder: (BuildContext context,
            AsyncSnapshot<_MeasurementsListData> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorState(
              message: 'Impossible de charger les mensurations.',
              onRetry: _load,
            );
          }
          final _MeasurementsListData data = snapshot.data!;
          if (data.sets.isEmpty) {
            return EmptyState(
              icon: Icons.straighten,
              message: 'Aucune mensuration pour le moment. '
                  'Ajoutez un premier jeu de mesures.',
                    actionLabel: 'Ajouter des mensurations',
                    onAction: () => context.push(
                      '/clients/${widget.clientId}/mensurations/nouveau',
                    ),
                  );
          }
          return Column(
            children: <Widget>[
              if (data.client != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.person_outline, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          data.client!.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${data.sets.length} '
                        '${data.sets.length > 1 ? 'jeux' : 'jeu'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxl * 2,
                  ),
                  itemCount: data.sets.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (BuildContext context, int index) {
                    final MeasurementSet set = data.sets[index];
                    return _MeasurementSetCard(
                      set: set,
                      isLatest: index == 0,
                      onTap: () => context.push(
                        '/clients/${widget.clientId}/mensurations/${set.id}',
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MeasurementsListData {
  const _MeasurementsListData({required this.client, required this.sets});

  final Client? client;
  final List<MeasurementSet> sets;
}

class _MeasurementSetCard extends StatelessWidget {
  const _MeasurementSetCard({
    required this.set,
    required this.isLatest,
    required this.onTap,
  });

  final MeasurementSet set;
  final bool isLatest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Icon(
                  Icons.straighten,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            set.garmentType,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isLatest) ...<Widget>[
                          const SizedBox(width: AppSpacing.sm),
                          const _LatestTag(),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Prise le ${Formatters.date(set.measuredAt)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ),
                    if (set.notes != null && set.notes!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        set.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _LatestTag extends StatelessWidget {
  const _LatestTag();

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Plus récent',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
