import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/client_store.dart';
import '../localization/app_copy.dart';
import '../models/encrypted_backup.dart';
import '../services/encrypted_backup_service.dart';

class BackupImportLedgerScreen extends StatefulWidget {
  const BackupImportLedgerScreen({required this.clientStore, super.key});

  final ClientStore clientStore;

  @override
  State<BackupImportLedgerScreen> createState() =>
      _BackupImportLedgerScreenState();
}

class _BackupImportLedgerScreenState extends State<BackupImportLedgerScreen> {
  late Future<List<BackupImportBatchRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.clientStore.listBackupImportBatches();
  }

  void _reload() {
    setState(() {
      _future = widget.clientStore.listBackupImportBatches();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(AppCopy.of(context, 'importLedgerTitle')),
          actions: [
            IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              tooltip: AppCopy.of(context, 'refresh'),
            ),
          ],
        ),
        body: FutureBuilder<List<BackupImportBatchRecord>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(AppCopy.of(context, 'databaseError')));
            }
            final batches = snapshot.data ?? const <BackupImportBatchRecord>[];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(AppCopy.of(context, 'importLedgerIntro')),
                  ),
                ),
                const SizedBox(height: 12),
                if (batches.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(AppCopy.of(context, 'importLedgerEmpty')),
                    ),
                  )
                else
                  for (final batch in batches) ...[
                    _BatchCard(
                      batch: batch,
                      onViewMappings: () => _openBatch(batch),
                      onExportReceipt:
                          batch.status == BackupImportBatchStatus.committed
                              ? () => _exportReceipt(batch)
                              : null,
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            );
          },
        ),
      );

  Future<void> _openBatch(BackupImportBatchRecord batch) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _BackupImportBatchDetailScreen(
          clientStore: widget.clientStore,
          batch: batch,
        ),
      ),
    );
  }

  Future<void> _exportReceipt(BackupImportBatchRecord batch) async {
    try {
      final artifact =
          await widget.clientStore.exportBackupMergeReceipt(batch.id);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          title: AppCopy.of(context, 'exportMergeReceipt'),
          text: '${AppCopy.of(context, 'importBatchReceiptHash')}: '
              '${artifact.receiptHash}',
          files: [
            XFile(
              artifact.filePath,
              mimeType: 'application/json',
            ),
          ],
        ),
      );
    } on EncryptedBackupException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'mergeReceiptFailed'))),
      );
    }
  }
}

class _BatchCard extends StatelessWidget {
  const _BatchCard({
    required this.batch,
    required this.onViewMappings,
    required this.onExportReceipt,
  });

  final BackupImportBatchRecord batch;
  final VoidCallback onViewMappings;
  final VoidCallback? onExportReceipt;

  @override
  Widget build(BuildContext context) {
    final statusText = switch (batch.status) {
      BackupImportBatchStatus.started =>
        AppCopy.of(context, 'importBatchStartedStatus'),
      BackupImportBatchStatus.committed =>
        AppCopy.of(context, 'importBatchCommitted'),
      BackupImportBatchStatus.failed =>
        AppCopy.of(context, 'importBatchFailed'),
    };
    final icon = switch (batch.status) {
      BackupImportBatchStatus.started => Icons.pending_outlined,
      BackupImportBatchStatus.committed => Icons.verified_outlined,
      BackupImportBatchStatus.failed => Icons.error_outline,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${AppCopy.of(context, 'importBatch')} #${batch.id}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(statusText),
              ],
            ),
            const SizedBox(height: 10),
            SelectableText(
              '${AppCopy.of(context, 'backupManifestHash')}: '
              '${batch.manifestHash}',
            ),
            const SizedBox(height: 5),
            Text(
              '${AppCopy.of(context, 'importBatchSource')}: '
              '${batch.sourceAppVersion} · ${batch.sourceEngineVersion}',
            ),
            Text(
              '${AppCopy.of(context, 'importBatchSchema')}: '
              '${batch.sourceDatabaseSchemaVersion}',
            ),
            Text(
              '${AppCopy.of(context, 'importBatchMappings')}: '
              '${batch.mappingRows}',
            ),
            Text(
              '${AppCopy.of(context, 'mergeInsertedRows')}: '
              '${batch.insertedRows} · '
              '${AppCopy.of(context, 'mergeEquivalentSkipped')}: '
              '${batch.equivalentRows} · '
              '${AppCopy.of(context, 'mergeRemappedRows')}: '
              '${batch.remappedRows}',
            ),
            if (batch.receiptHash != null) ...[
              const SizedBox(height: 5),
              SelectableText(
                '${AppCopy.of(context, 'importBatchReceiptHash')}: '
                '${batch.receiptHash}',
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onViewMappings,
                  icon: const Icon(Icons.account_tree_outlined),
                  label: Text(AppCopy.of(context, 'viewMappings')),
                ),
                if (onExportReceipt != null)
                  FilledButton.icon(
                    onPressed: onExportReceipt,
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: Text(AppCopy.of(context, 'exportMergeReceipt')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupImportBatchDetailScreen extends StatelessWidget {
  const _BackupImportBatchDetailScreen({
    required this.clientStore,
    required this.batch,
  });

  final ClientStore clientStore;
  final BackupImportBatchRecord batch;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('${AppCopy.of(context, 'importBatch')} #${batch.id}'),
        ),
        body: FutureBuilder<List<BackupImportMappingRecord>>(
          future: clientStore.listBackupImportMappings(batch.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final mappings = snapshot.data ?? const <BackupImportMappingRecord>[];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          '${AppCopy.of(context, 'backupManifestHash')}: '
                          '${batch.manifestHash}',
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${AppCopy.of(context, 'importBatchStarted')}: '
                          '${batch.startedAtUtc.toIso8601String()}',
                        ),
                        if (batch.completedAtUtc != null)
                          Text(
                            '${AppCopy.of(context, 'importBatchCompleted')}: '
                            '${batch.completedAtUtc!.toIso8601String()}',
                          ),
                        const SizedBox(height: 6),
                        Text(
                          '${AppCopy.of(context, 'importBatchDiagnostics')}: '
                          '${batch.diagnosticsJson}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppCopy.of(context, 'importBatchMappings'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (mappings.isEmpty)
                  Text(AppCopy.of(context, 'noImportMappings'))
                else
                  for (final mapping in mappings)
                    Card(
                      child: ListTile(
                        title: Text(mapping.tableName),
                        subtitle: SelectableText(
                          '${AppCopy.of(context, 'mappingSourceId')}: '
                          '${mapping.sourceId}  →  '
                          '${AppCopy.of(context, 'mappingLocalId')}: '
                          '${mapping.localId}\n'
                          '${AppCopy.of(context, 'mappingResolution')}: '
                          '${AppCopy.of(context, 'mapping_${mapping.resolution.name}')}\n'
                          '${AppCopy.of(context, 'mappingSourceHash')}: '
                          '${mapping.sourceRowSha256}\n'
                          '${AppCopy.of(context, 'mappingLocalHash')}: '
                          '${mapping.localRowSha256}',
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      );
}
