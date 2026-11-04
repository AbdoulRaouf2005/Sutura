import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/client_repository.dart';
import '../../../core/state/data_controller.dart';
import '../../../core/state/data_events_listener.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/client.dart';

/// Liste, recherche et accès aux fiches clients (cahier des charges §4.2).
class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen>
    with DataEventsListener<ClientsScreen> {
  final ClientRepository _repo = ClientRepository();
  final TextEditingController _search = TextEditingController();

  Future<List<Client>>? _future;

  @override
  Set<DataEntity> get dataEntities => const <DataEntity>{DataEntity.clients};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void onDataChanged() => _load();

  void _load() {
    setState(() {
      _future = _repo.list(query: _search.text);
    });
  }

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
              builder: (BuildContext context,
                  AsyncSnapshot<List<Client>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
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
                    actionLabel:
                        _search.text.trim().isEmpty ? 'Ajouter un client' : null,
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
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Text(_initials(client.fullName)),
                        ),
                        title: Text(client.fullName),
                        subtitle: client.phone == null
                            ? null
                            : Text(client.phone!),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/clients/${client.id}'),
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

  String _initials(String name) {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
