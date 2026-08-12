import 'package:flutter/material.dart';

import '../data/client_store.dart';
import '../localization/app_copy.dart';
import '../models/audit_event.dart';

class AuditHistoryScreen extends StatelessWidget {
  const AuditHistoryScreen({
    required this.clientStore,
    required this.clientId,
    super.key,
  });

  final ClientStore clientStore;
  final int clientId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppCopy.of(context, 'history'))),
      body: FutureBuilder<List<AuditEvent>>(
        future: clientStore.auditEventsForClient(clientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data ?? const [];
          if (events.isEmpty) {
            return Center(child: Text(AppCopy.of(context, 'noHistory')));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text(AppCopy.of(context, event.action)),
                  subtitle: Text(_format(event.createdAt.toLocal())),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _format(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

