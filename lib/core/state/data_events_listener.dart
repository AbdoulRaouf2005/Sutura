import 'dart:async';

import 'package:flutter/widgets.dart';

import 'data_controller.dart';

/// Abonne un écran aux modifications des entités qu'il affiche.
///
/// L'écran implémente [dataEntities] (les entités à surveiller) et
/// [onDataChanged] (le rechargement). L'abonnement est actif tant que l'écran
/// est monté, y compris lorsqu'il est masqué (onglets de la coquille).
mixin DataEventsListener<T extends StatefulWidget> on State<T> {
  /// Abonnements actifs aux flux de modification des entités surveillées.
  final List<StreamSubscription<void>> _subscriptions =
      <StreamSubscription<void>>[];

  /// Entités dont la modification déclenche [onDataChanged].
  Set<DataEntity> get dataEntities;

  /// Recharge les données affichées par l'écran.
  void onDataChanged();

  /// Initialise les abonnements aux entités surveillées au montage du widget.
  @override
  void initState() {
    super.initState();
    for (final DataEntity entity in dataEntities) {
      _subscriptions.add(
        DataController.instance.on(entity).listen((_) {
          if (mounted) onDataChanged();
        }),
      );
    }
  }

  /// Annule tous les abonnements lors de la destruction du widget.
  @override
  void dispose() {
    for (final StreamSubscription<void> subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
