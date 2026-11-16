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

/// Écran listant les jeux de mensurations d'un client, du plus récent au plus ancien.
///
/// Une nouvelle prise n'écrase jamais l'historique (§4.3).
class MeasurementsListScreen extends StatefulWidget {
  /// Crée l'écran de liste pour le client identifié par [clientId].
  const MeasurementsListScreen({super.key, required this.clientId});

  /// Identifiant du client dont les mensurations sont affichées.
  final String clientId;

  /// Crée l'état associé à cet écran.
  @override
  State<MeasurementsListScreen> createState() => _MeasurementsListScreenState();
}

/// État de [MeasurementsListScreen] gérant le chargement des mensurations.
class _MeasurementsListScreenState extends State<MeasurementsListScreen>
    with DataEventsListener<MeasurementsListScreen> {
  /// Dépôt pour accéder aux jeux de mensurations.
  final MeasurementRepository _repo = MeasurementRepository();

  /// Dépôt pour accéder aux informations du client.
  final ClientRepository _clients = ClientRepository();

  /// Future contenant les données du client et ses jeux de mensurations.
  Future<_MeasurementsListData>? _future;

  /// Entités de données écoutées pour rafraîchir l'écran.
  @override
  Set<DataEntity> get dataEntities => const <DataEntity>{
    DataEntity.measurements,
    DataEntity.clients,
  };

  /// Initialise l'état et déclenche le chargement initial.
  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Recharge les données lorsque les entités écoutées changent.
  @override
  void onDataChanged() => _load();

  /// Lance le chargement du client et de ses mensurations.
  void _load() {
    // Met à jour la future pour déclencher la reconstruction.
    setState(() {
      _future = _fetch();
    });
  }

  /// Récupère le client et la liste de ses jeux de mensurations.
  ///
  /// Retourne un agrégat [_MeasurementsListData].
  Future<_MeasurementsListData> _fetch() async {
    final Client? client = await _clients.findById(widget.clientId);
    final List<MeasurementSet> sets = await _repo.listSetsForClient(
      widget.clientId,
    );
    return _MeasurementsListData(client: client, sets: sets);
  }

  /// Construit l'interface de la liste des mensurations du client.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mensurations')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            // Navigation vers le formulaire de création d'un nouveau jeu.
            context.push('/clients/${widget.clientId}/mensurations/nouveau'),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: FutureBuilder<_MeasurementsListData>(
        future: _future,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<_MeasurementsListData> snapshot,
            ) {
              // Affiche un indicateur pendant le chargement.
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // Affiche un état d'erreur en cas d'échec du chargement.
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
                  message:
                      'Aucune mensuration pour le moment. '
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
                              color: Theme.of(context).colorScheme.onSurface
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
                          // Le premier élément correspond au jeu le plus récent.
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

/// Agrégat des données nécessaires à l'affichage de la liste des mensurations.
class _MeasurementsListData {
  /// Crée un agrégat contenant le [client] et ses [sets] de mensurations.
  const _MeasurementsListData({required this.client, required this.sets});

  /// Client concerné, s'il est disponible.
  final Client? client;

  /// Jeux de mensurations du client.
  final List<MeasurementSet> sets;
}

/// Carte affichant le résumé d'un jeu de mensurations.
class _MeasurementSetCard extends StatelessWidget {
  /// Crée une carte pour le jeu [set] avec les actions associées.
  ///
  /// [isLatest] indique si le jeu est le plus récent, [onTap] ouvre le détail.
  const _MeasurementSetCard({
    required this.set,
    required this.isLatest,
    required this.onTap,
  });

  /// Jeu de mensurations affiché.
  final MeasurementSet set;

  /// Indique si ce jeu est le plus récent de la liste.
  final bool isLatest;

  /// Action déclenchée lors du tap sur la carte.
  final VoidCallback onTap;

  /// Construit la carte résumé du jeu de mensurations.
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
                  color: Theme.of(context).colorScheme.primary
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
                        color: Theme.of(context).colorScheme.onSurface
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
                          color: Theme.of(context).colorScheme.onSurface
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

/// Badge indiquant que le jeu de mensurations est le plus récent.
class _LatestTag extends StatelessWidget {
  /// Crée le badge « Plus récent ».
  const _LatestTag();

  /// Construit le badge visuel du jeu le plus récent.
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
