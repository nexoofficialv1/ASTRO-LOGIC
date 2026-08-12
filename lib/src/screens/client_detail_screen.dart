import 'package:flutter/material.dart';

import '../data/client_store.dart';
import '../localization/app_copy.dart';
import '../models/birth_record.dart';
import 'birth_record_form_screen.dart';
import 'client_edit_screen.dart';
import 'audit_history_screen.dart';
import 'consultation_form_screen.dart';
import 'consultation_detail_screen.dart';

class ClientDetailScreen extends StatelessWidget {
  const ClientDetailScreen({
    required this.clientStore,
    required this.clientId,
    super.key,
  });

  final ClientStore clientStore;
  final int clientId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: clientStore,
      builder: (context, _) {
        final client = clientStore.findById(clientId);
        if (client == null) {
          return const Scaffold(body: Center(child: Text('Client not found')));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(client.fullName),
            actions: [
              IconButton(
                tooltip: AppCopy.of(context, 'history'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AuditHistoryScreen(
                      clientStore: clientStore,
                      clientId: clientId,
                    ),
                  ),
                ),
                icon: const Icon(Icons.history),
              ),
              IconButton(
                tooltip: AppCopy.of(context, 'edit'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ClientEditScreen(
                      clientStore: clientStore,
                      client: client,
                    ),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BirthRecordFormScreen(
                  clientStore: clientStore,
                  clientId: clientId,
                ),
              ),
            ),
            icon: const Icon(Icons.add),
            label: Text(AppCopy.of(context, 'addBirthRecord')),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Text(AppCopy.of(context, 'clientProfile'),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(client.fullName,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (client.mobile.isNotEmpty) Text(client.mobile),
                      if (client.email.isNotEmpty) Text(client.email),
                      if (client.notes.isNotEmpty) ...[
                        const Divider(),
                        Text(client.notes),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppCopy.of(context, 'consultations'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: client.birthRecords.isEmpty
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ConsultationFormScreen(
                                  clientStore: clientStore,
                                  client: client,
                                ),
                              ),
                            ),
                    icon: const Icon(Icons.add_comment_outlined),
                    label: Text(AppCopy.of(context, 'newConsultation')),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (clientStore.consultationsForClient(clientId).isEmpty)
                Text(AppCopy.of(context, 'noConsultations')),
              for (final consultation
                  in clientStore.consultationsForClient(clientId))
                Card(
                  child: ListTile(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ConsultationDetailScreen(
                          clientStore: clientStore,
                          consultationId: consultation.id!,
                        ),
                      ),
                    ),
                    leading: const Icon(Icons.forum_outlined),
                    title: Text(consultation.subject),
                    subtitle: Text(
                      '${AppCopy.of(context, consultation.category.name)} • '
                      '${AppCopy.of(context, consultation.status.name)}\n'
                      '${clientStore.outputsForConsultation(consultation.id!).isEmpty && clientStore.numerologySnapshotsForConsultation(consultation.id!).isEmpty ? AppCopy.of(context, 'enginePending') : AppCopy.of(context, 'outputAvailable')}',
                    ),
                    isThreeLine: true,
                  ),
                ),
              const SizedBox(height: 22),
              Text(AppCopy.of(context, 'birthRecords'),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              for (final record in client.birthRecords)
                _BirthRecordCard(
                  record: record,
                  onSnapshot: () async {
                    try {
                      await clientStore.createInputSnapshot(
                        client: client,
                        birthRecord: record,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppCopy.of(context, 'snapshotCreated')),
                        ),
                      );
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppCopy.of(context, 'databaseError')),
                        ),
                      );
                    }
                  },
                  onEdit: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BirthRecordFormScreen(
                        clientStore: clientStore,
                        clientId: clientId,
                        existingRecord: record,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              Text(AppCopy.of(context, 'snapshots'),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(AppCopy.of(context, 'immutableNote')),
              const SizedBox(height: 10),
              if (clientStore.snapshotsForClient(clientId).isEmpty)
                Text(AppCopy.of(context, 'noSnapshots')),
              for (final snapshot in clientStore.snapshotsForClient(clientId))
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: Text(snapshot.label),
                    subtitle: Text(
                      '${AppCopy.of(context, 'schemaVersion')}: '
                      '${snapshot.schemaVersion}\n'
                      '${AppCopy.of(context, 'inputHash')}: '
                      '${snapshot.inputHash.substring(0, 16)}…',
                    ),
                    isThreeLine: true,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BirthRecordCard extends StatelessWidget {
  const _BirthRecordCard({
    required this.record,
    required this.onEdit,
    required this.onSnapshot,
  });

  final BirthRecord record;
  final VoidCallback onEdit;
  final VoidCallback onSnapshot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: AppCopy.of(context, 'editBirthRecord'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_calendar_outlined),
                ),
                IconButton(
                  tooltip: AppCopy.of(context, 'createSnapshot'),
                  onPressed: onSnapshot,
                  icon: const Icon(Icons.lock_clock_outlined),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _row(context, 'localTime', _dateTime(record.localDateTime)),
            _row(context, 'utcTime', '${_dateTime(record.utcDateTime)} UTC'),
            _row(context, 'birthPlace', record.placeName),
            _row(
              context,
              'coordinates',
              '${record.latitude.toStringAsFixed(5)}, ${record.longitude.toStringAsFixed(5)}',
            ),
            _row(context, 'timeConfidence', AppCopy.of(context, record.confidence.name)),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String key, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text('${AppCopy.of(context, key)}: $value'),
      );

  String _dateTime(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
