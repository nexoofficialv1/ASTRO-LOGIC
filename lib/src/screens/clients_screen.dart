import 'package:flutter/material.dart';

import '../data/client_store.dart';
import '../localization/app_copy.dart';
import '../models/client.dart';
import 'client_form_screen.dart';
import 'client_detail_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({required this.clientStore, super.key});

  final ClientStore clientStore;

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppCopy.of(context, 'clients'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addClient,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(AppCopy.of(context, 'addClient')),
      ),
      body: AnimatedBuilder(
        animation: widget.clientStore,
        builder: (context, _) {
          final clients = widget.clientStore.search(_query);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    labelText: AppCopy.of(context, 'searchClients'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: clients.isEmpty
                    ? Center(child: Text(AppCopy.of(context, 'noClients')))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: clients.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) => _ClientTile(
                          client: clients[index],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ClientDetailScreen(
                                clientStore: widget.clientStore,
                                clientId: clients[index].id!,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addClient() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ClientFormScreen(clientStore: widget.clientStore),
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  const _ClientTile({required this.client, required this.onTap});

  final Client client;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final birth =
        client.birthRecords.isEmpty ? null : client.birthRecords.first;
    final subtitleParts = <String>[
      if (client.mobile.isNotEmpty) client.mobile,
      if (birth != null) birth.placeName,
    ];
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(child: Text(client.fullName.characters.first)),
        title: Text(client.fullName),
        subtitle: Text(subtitleParts.join(' • ')),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
