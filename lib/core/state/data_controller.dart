import 'dart:async';

/// Entités de l'application dont l'écriture doit rafraîchir les écrans.
enum DataEntity {
  /// Données relatives aux clients.
  clients,

  /// Données relatives aux commandes.
  orders,

  /// Données relatives aux mensurations.
  measurements,

  /// Données relatives aux paiements.
  payments,

  /// Données relatives aux modèles de vêtements.
  models,
}

/// Signale les modifications de données entre les dépôts et les écrans.
///
/// Les dépôts émettent un signal après chaque écriture ; les écrans
/// s'abonnent aux entités qu'ils affichent et se rechargent automatiquement.
/// Cela évite de dépendre du résultat de `context.push(...)`, qui est ignoré
/// sur plusieurs écrans (et qui laisse les autres onglets avec des données
/// obsolètes).
class DataController {
  /// Constructeur privé pour le singleton.
  DataController._();

  /// Instance unique du contrôleur de données.
  static final DataController instance = DataController._();

  /// Contrôleurs de flux de diffusion par type d'entité.
  final Map<DataEntity, StreamController<void>> _controllers =
      <DataEntity, StreamController<void>>{
        for (final DataEntity entity in DataEntity.values)
          entity: StreamController<void>.broadcast(),
      };

  /// Flux des événements de modification de [entity].
  Stream<void> on(DataEntity entity) => _controllers[entity]!.stream;

  /// Signale une modification de [entity].
  void notify(DataEntity entity) {
    final StreamController<void>? controller = _controllers[entity];
    if (controller == null || controller.isClosed) return;
    controller.add(null);
  }

  /// Signale une modification de toutes les entités (restauration de sauvegarde).
  void notifyAll() {
    for (final DataEntity entity in DataEntity.values) {
      notify(entity);
    }
  }
}
