import 'package:flutter/material.dart';

import '../../../core/repositories/measurement_repository.dart';
import '../../../core/state/data_controller.dart';
import '../../../core/state/data_events_listener.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/formatters/formatters.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/measurement_set.dart';

/// Écran affichant le détail d'un jeu de mensurations.
///
/// Le jeu est immuable : pour corriger des mesures, on crée un nouveau jeu
/// (§4.3). Ce jeu peut être supprimé s'il n'est référencé par aucune commande.
class MeasurementDetailScreen extends StatefulWidget {
  /// Crée l'écran de détail pour le jeu [setId] du client [clientId].
  const MeasurementDetailScreen({
    super.key,
    required this.clientId,
    required this.setId,
  });

  /// Identifiant du client propriétaire du jeu.
  final String clientId;

  /// Identifiant du jeu de mensurations à afficher.
  final String setId;

  /// Crée l'état associé à cet écran.
  @override
  State<MeasurementDetailScreen> createState() =>
      _MeasurementDetailScreenState();
}

/// État de [MeasurementDetailScreen] gérant le chargement et la suppression.
class _MeasurementDetailScreenState extends State<MeasurementDetailScreen>
    with DataEventsListener<MeasurementDetailScreen> {
  /// Dépôt pour accéder aux jeux de mensurations.
  final MeasurementRepository _repo = MeasurementRepository();

  /// Future contenant les données du jeu et ses mesures.
  Future<_MeasurementDetailData>? _future;

  /// Entités de données écoutées pour rafraîchir l'écran.
  @override
  Set<DataEntity> get dataEntities => const <DataEntity>{
    DataEntity.measurements,
  };

  /// Initialise l'état et déclenche le chargement initial.
  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Recharge les données lorsque les mensurations changent.
  @override
  void onDataChanged() => _load();

  /// Lance le chargement du jeu de mensurations et de ses mesures.
  void _load() {
    // Met à jour la future pour déclencher la reconstruction.
    setState(() {
      _future = _fetch();
    });
  }

  /// Récupère le jeu de mensurations et la liste des mesures associées.
  ///
  /// Retourne un agrégat [_MeasurementDetailData] ou lève une erreur si introuvable.
  Future<_MeasurementDetailData> _fetch() async {
    final MeasurementSet? set = await _repo.findSetById(widget.setId);
    if (set == null) throw StateError('Jeu introuvable');
    final List<Measurement> measurements = await _repo.listMeasurements(
      widget.setId,
    );
    return _MeasurementDetailData(set: set, measurements: measurements);
  }

  /// Supprime le jeu de mensurations après confirmation de l'utilisateur.
  Future<void> _delete() async {
    // Demande de confirmation avant suppression définitive.
    final bool confirmed = await confirmAction(
      context,
      title: 'Supprimer ces mensurations ?',
      message:
          'Ce jeu de mesures sera définitivement supprimé. '
          'Les commandes qui l\'utilisent ne seront pas affectées.',
      confirmLabel: 'Supprimer',
    );
    if (!confirmed) return;
    try {
      // Suppression du jeu via le dépôt.
      await _repo.deleteSet(widget.setId);
      if (!mounted) return;
      showAppSnackBar(context, message: 'Mensurations supprimées.');
      Navigator.of(context).pop(true);
    } catch (_) {
      // Gestion des erreurs de suppression.
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: 'La suppression a échoué. Réessayez.',
        isError: true,
      );
    }
  }

  /// Construit l'interface de détail du jeu de mensurations.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail des mensurations'),
        actions: <Widget>[
          IconButton(
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Supprimer',
          ),
        ],
      ),
      body: FutureBuilder<_MeasurementDetailData>(
        future: _future,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<_MeasurementDetailData> snapshot,
            ) {
              // Affiche un indicateur pendant le chargement.
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // Affiche un état d'erreur en cas d'échec du chargement.
              if (snapshot.hasError || !snapshot.hasData) {
                return ErrorState(
                  message: 'Impossible de charger ces mensurations.',
                  onRetry: _load,
                );
              }
              final _MeasurementDetailData data = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            data.set.garmentType,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.calendar_month_outlined,
                                size: 16,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Prise le ${Formatters.date(data.set.measuredAt)}',
                              ),
                            ],
                          ),
                          if (data.set.notes != null &&
                              data.set.notes!.isNotEmpty) ...<Widget>[
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Icon(Icons.notes_outlined, size: 16),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(child: Text(data.set.notes!)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'Mesures',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (data.measurements.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Text('Aucune mesure enregistrée dans ce jeu.'),
                      ),
                    )
                  else
                    Card(
                      child: Column(
                        children: <Widget>[
                          // Affiche chaque mesure avec un séparateur entre les lignes.
                          for (
                            int i = 0;
                            i < data.measurements.length;
                            i++
                          ) ...<Widget>[
                            if (i > 0) const Divider(height: 1),
                            ListTile(
                              title: Text(data.measurements[i].name),
                              trailing: Text(
                                Formatters.measurement(
                                  data.measurements[i].value,
                                  data.measurements[i].unit,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              );
            },
      ),
    );
  }
}

/// Agrégat des données nécessaires à l'affichage du détail d'un jeu.
class _MeasurementDetailData {
  /// Crée un agrégat contenant le [set] et ses [measurements].
  const _MeasurementDetailData({required this.set, required this.measurements});

  /// Jeu de mensurations affiché.
  final MeasurementSet set;

  /// Mesures individuelles du jeu.
  final List<Measurement> measurements;
}
