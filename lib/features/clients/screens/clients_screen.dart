import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/client_repository.dart';
import '../../../core/state/data_controller.dart';
import '../../../core/state/data_events_listener.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/client.dart';

/// Écran listant les clients avec recherche et accès aux fiches (§4.2).
class ClientsScreen extends StatefulWidget {
  /// Crée l'écran de liste des clients.
  const ClientsScreen({super.key});

  /// Crée l'état associé à cet écran.
  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

/// État de [ClientsScreen] gérant la recherche et l'affichage des clients.
class _ClientsScreenState extends State<ClientsScreen>
    with DataEventsListener<ClientsScreen> {
  /// Dépôt pour accéder aux clients.
  final ClientRepository _repo = ClientRepository();

  /// Contrôleur du champ de recherche.
  final TextEditingController _search = TextEditingController();

  /// Future contenant la liste des clients à afficher.
  Future<List<Client>>? _future;

  /// Entités de données écoutées pour rafraîchir la liste.
  @override
  Set<DataEntity> get dataEntities => const <DataEntity>{DataEntity.clients};

  /// Initialise l'état et charge la liste initiale des clients.
  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Libère le contrôleur de recherche.
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Recharge la liste lorsque les données clients changent.
  @override
  void onDataChanged() => _load();

  /// Lance le chargement des clients en tenant compte du texte recherché.
  void _load() {
    // Met à jour la future pour appliquer la requête de recherche.
    setState(() {
      _future = _repo.list(query: _search.text);
    });
  }

  /// Construit l'interface de la liste des clients.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/clients/nouveau'),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Ajouter'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              onChanged: (_) => _load(),
              decoration: const InputDecoration(
                hintText: 'Rechercher par nom ou téléphone',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Client>>(
              future: _future,
              builder:
                  (BuildContext context, AsyncSnapshot<List<Client>> snapshot) {
                    // Affiche un indicateur pendant le chargement.
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    // Affiche un état d'erreur en cas d'échec du chargement.
                    if (snapshot.hasError) {
                      return ErrorState(
                        message: 'Impossible de charger les clients.',
                        onRetry: _load,
                      );
                    }
                    final List<Client> clients = snapshot.data ?? <Client>[];
                    if (clients.isEmpty) {
                      return EmptyState(
                        icon: Icons.people_outline,
                        message: _search.text.trim().isEmpty
                            ? 'Aucun client pour le moment. Ajoutez votre premier '
                                  'client pour commencer.'
                            : 'Aucun client ne correspond à cette recherche.',
                        actionLabel: _search.text.trim().isEmpty
                            ? 'Ajouter un client'
                            : null,
                        onAction: _search.text.trim().isEmpty
                            ? () => context.push('/clients/nouveau')
                            : null,
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.xxl * 2,
                      ),
                      itemCount: clients.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (BuildContext context, int index) {
                        final Client client = clients[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Text(_initials(client.fullName)),
                            ),
                            title: Text(client.fullName),
                            subtitle: client.phone == null
                                ? null
                                : Text(client.phone!),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () =>
                                // Navigation vers la fiche détaillée du client.
                                context.push('/clients/${client.id}'),
                          ),
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

  /// Calcule les initiales à afficher pour un [name] de client.
  String _initials(String name) {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
