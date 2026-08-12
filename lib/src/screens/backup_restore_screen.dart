import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/client_store.dart';
import '../localization/app_copy.dart';
import '../models/encrypted_backup.dart';
import '../services/encrypted_backup_service.dart';
import 'backup_import_ledger_screen.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({required this.clientStore, super.key});

  final ClientStore clientStore;

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _busy = false;
  EncryptedBackupArtifact? _lastBackup;
  EncryptedBackupPreview? _lastPreview;
  EncryptedBackupRestoreResult? _lastRestore;
  EncryptedBackupMergeResult? _lastMerge;
  List<int>? _previewedBackupBytes;
  String? _previewedBackupName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppCopy.of(context, 'backupRestoreTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppCopy.of(context, 'encryptedBackupTitle'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(AppCopy.of(context, 'encryptedBackupIntro')),
                  const SizedBox(height: 12),
                  Text(
                    AppCopy.of(context, 'encryptedBackupCryptoDisclosure'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _busy ? null : _createBackup,
                    icon: const Icon(Icons.lock_outline),
                    label: Text(AppCopy.of(context, 'createEncryptedBackup')),
                  ),
                ],
              ),
            ),
          ),
          if (_lastBackup != null) ...[
            const SizedBox(height: 12),
            _BackupResultCard(artifact: _lastBackup!),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppCopy.of(context, 'restorePreviewTitle'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(AppCopy.of(context, 'restorePreviewIntro')),
                  const SizedBox(height: 8),
                  Text(
                    AppCopy.of(context, 'restoreNoMergeWarning'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _previewBackup,
                    icon: const Icon(Icons.manage_search),
                    label: Text(AppCopy.of(context, 'selectBackupAndPreview')),
                  ),
                ],
              ),
            ),
          ),
          if (_lastPreview != null) ...[
            const SizedBox(height: 12),
            _BackupPreviewCard(
              preview: _lastPreview!,
              fileName: _previewedBackupName ?? '',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: !_busy && _lastPreview!.canRestoreNow
                  ? _restorePreviewedBackup
                  : null,
              icon: const Icon(Icons.settings_backup_restore),
              label: Text(AppCopy.of(context, 'restorePreviewedBackup')),
            ),
            if (_lastPreview!.canMergeNow) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _busy ? null : _mergePreviewedBackup,
                icon: const Icon(Icons.merge_type),
                label: Text(AppCopy.of(context, 'mergePreviewedBackup')),
              ),
            ],
            if (!_lastPreview!.canRestoreNow && !_lastPreview!.canMergeNow) ...[
              const SizedBox(height: 8),
              Text(
                AppCopy.of(context, 'restoreBlockedByPlanner'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
          if (_lastRestore != null) ...[
            const SizedBox(height: 12),
            _RestoreResultCard(result: _lastRestore!),
          ],
          if (_lastMerge != null) ...[
            const SizedBox(height: 12),
            _MergeResultCard(result: _lastMerge!),
          ],
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(AppCopy.of(context, 'importLedgerTitle')),
              subtitle: Text(AppCopy.of(context, 'importLedgerIntro')),
              trailing: const Icon(Icons.chevron_right),
              onTap: _busy
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BackupImportLedgerScreen(
                            clientStore: widget.clientStore,
                          ),
                        ),
                      ),
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 18),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 8),
            Center(child: Text(AppCopy.of(context, 'backupRestoreWorking'))),
          ],
        ],
      ),
    );
  }

  Future<void> _createBackup() async {
    final password = await _askForPassword(confirm: true);
    if (password == null) return;
    setState(() => _busy = true);
    try {
      final artifact = await widget.clientStore.createEncryptedBackup(
        password: password,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _lastBackup = artifact;
      });
      await SharePlus.instance.share(
        ShareParams(
          title: AppCopy.of(context, 'encryptedBackupTitle'),
          text: AppCopy.of(context, 'backupShareNote'),
          files: [
            XFile(
              artifact.filePath,
              mimeType: 'application/vnd.astro-logic.encrypted-backup',
            ),
          ],
        ),
      );
    } on EncryptedBackupException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError(AppCopy.of(context, 'backupCreateFailed'));
    }
  }

  Future<void> _previewBackup() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [EncryptedBackupService.fileExtension],
      allowMultiple: false,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final selected = picked.files.single;
    if (selected.size > EncryptedBackupService.maxEncryptedBackupBytes) {
      _showError(AppCopy.of(context, 'backupFileTooLarge'));
      return;
    }
    List<int>? bytes = selected.bytes;
    if (bytes == null && selected.path != null) {
      bytes = await File(selected.path!).readAsBytes();
    }
    if (bytes == null || bytes.isEmpty) {
      _showError(AppCopy.of(context, 'backupFileReadFailed'));
      return;
    }
    final password = await _askForPassword(confirm: false);
    if (password == null) return;
    final backupBytes = List<int>.from(bytes, growable: false);

    setState(() => _busy = true);
    try {
      final preview = await widget.clientStore.previewEncryptedBackup(
        encryptedBytes: backupBytes,
        password: password,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _lastPreview = preview;
        _previewedBackupBytes = backupBytes;
        _previewedBackupName = selected.name;
        _lastRestore = null;
        _lastMerge = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'restorePreviewCompleted'))),
      );
    } on EncryptedBackupException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError(AppCopy.of(context, 'restorePreviewFailed'));
    }
  }

  Future<void> _restorePreviewedBackup() async {
    final preview = _lastPreview;
    final backupBytes = _previewedBackupBytes;
    if (preview == null || backupBytes == null || !preview.canRestoreNow) {
      _showError(AppCopy.of(context, 'restoreBlockedByPlanner'));
      return;
    }
    final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppCopy.of(context, 'restoreConfirmTitle')),
            content: Text(AppCopy.of(context, 'restoreConfirmMessage')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppCopy.of(context, 'cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppCopy.of(context, 'continueAction')),
              ),
            ],
          ),
        ) ??
        false;
    if (!proceed || !mounted) return;
    final password = await _askForPassword(confirm: false);
    if (password == null) return;

    setState(() => _busy = true);
    try {
      final result = await widget.clientStore.restoreEncryptedBackup(
        encryptedBytes: backupBytes,
        password: password,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _lastRestore = result;
        _lastPreview = null;
        _previewedBackupBytes = null;
        _previewedBackupName = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'restoreCompleted'))),
      );
    } on EncryptedBackupException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError(AppCopy.of(context, 'restoreFailed'));
    }
  }

  Future<void> _mergePreviewedBackup() async {
    final preview = _lastPreview;
    final backupBytes = _previewedBackupBytes;
    if (preview == null || backupBytes == null || !preview.canMergeNow) {
      _showError(AppCopy.of(context, 'restoreBlockedByPlanner'));
      return;
    }
    final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppCopy.of(context, 'mergeConfirmTitle')),
            content: Text(AppCopy.of(context, 'mergeConfirmMessage')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppCopy.of(context, 'cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppCopy.of(context, 'continueAction')),
              ),
            ],
          ),
        ) ??
        false;
    if (!proceed || !mounted) return;
    final password = await _askForPassword(confirm: false);
    if (password == null) return;

    setState(() => _busy = true);
    try {
      final result = await widget.clientStore.mergeEncryptedBackup(
        encryptedBytes: backupBytes,
        password: password,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _lastMerge = result;
        _lastRestore = null;
        _lastPreview = null;
        _previewedBackupBytes = null;
        _previewedBackupName = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'mergeCompleted'))),
      );
    } on EncryptedBackupException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError(AppCopy.of(context, 'mergeFailed'));
    }
  }

  Future<String?> _askForPassword({required bool confirm}) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    String? inlineError;
    final value = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            AppCopy.of(
              context,
              confirm ? 'backupPasswordCreateTitle' : 'backupPasswordEnterTitle',
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppCopy.of(context, 'backupPasswordRule')),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: AppCopy.of(context, 'backupPassword'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (confirm) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: AppCopy.of(context, 'confirmBackupPassword'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
                if (inlineError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    inlineError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  AppCopy.of(context, 'passwordNotStoredWarning'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppCopy.of(context, 'cancel')),
            ),
            FilledButton(
              onPressed: () {
                final password = passwordController.text;
                if (password.length < 12) {
                  setDialogState(
                    () => inlineError =
                        AppCopy.of(context, 'backupPasswordTooShort'),
                  );
                  return;
                }
                if (confirm && password != confirmController.text) {
                  setDialogState(
                    () => inlineError =
                        AppCopy.of(context, 'backupPasswordMismatch'),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(password);
              },
              child: Text(
                AppCopy.of(
                  context,
                  confirm ? 'createEncryptedBackup' : 'continueAction',
                ),
              ),
            ),
          ],
        ),
      ),
    );
    passwordController.dispose();
    confirmController.dispose();
    return value;
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BackupResultCard extends StatelessWidget {
  const _BackupResultCard({required this.artifact});

  final EncryptedBackupArtifact artifact;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppCopy.of(context, 'backupCreated'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SelectableText(artifact.fileName),
              const SizedBox(height: 6),
              Text(
                '${AppCopy.of(context, 'backupManifestHash')}: '
                '${artifact.manifestHash}',
              ),
              const SizedBox(height: 6),
              Text(
                '${AppCopy.of(context, 'backupFileHash')}: ${artifact.sha256}',
              ),
              const SizedBox(height: 6),
              Text(
                '${AppCopy.of(context, 'backupRecordCount')}: '
                '${artifact.tableRowCounts.values.fold<int>(0, (a, b) => a + b)}',
              ),
            ],
          ),
        ),
      );
}

class _BackupPreviewCard extends StatelessWidget {
  const _BackupPreviewCard({required this.preview, required this.fileName});

  final EncryptedBackupPreview preview;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    final eligibility = switch (preview.eligibility) {
      BackupRestoreEligibility.eligibleEmptyWorkspace =>
        AppCopy.of(context, 'previewEligible'),
      BackupRestoreEligibility.eligibleGovernedMerge =>
        AppCopy.of(context, 'previewMergeEligible'),
      BackupRestoreEligibility.blockedNonEmptyWorkspace =>
        AppCopy.of(context, 'previewBlockedNonEmpty'),
      BackupRestoreEligibility.requiresSchemaMigration =>
        AppCopy.of(context, 'previewRequiresMigration'),
      BackupRestoreEligibility.unsupportedBackup =>
        AppCopy.of(context, 'previewUnsupported'),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppCopy.of(context, 'restorePreviewVerified'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (fileName.isNotEmpty) ...[
              const SizedBox(height: 6),
              SelectableText(fileName),
            ],
            const SizedBox(height: 10),
            _PreviewLine(
              label: AppCopy.of(context, 'previewSourceApp'),
              value: preview.sourceAppVersion,
            ),
            _PreviewLine(
              label: AppCopy.of(context, 'previewBackupEngine'),
              value: preview.sourceEngineVersion,
            ),
            _PreviewLine(
              label: AppCopy.of(context, 'previewSourceSchema'),
              value: '${preview.sourceDatabaseSchemaVersion}',
            ),
            _PreviewLine(
              label: AppCopy.of(context, 'previewBackupCreated'),
              value: preview.backupCreatedAtUtc.toIso8601String(),
            ),
            _PreviewLine(
              label: AppCopy.of(context, 'backupManifestHash'),
              value: preview.manifestHash,
            ),
            _PreviewLine(
              label: AppCopy.of(context, 'previewManifestIntegrity'),
              value: preview.manifestVerified
                  ? AppCopy.of(context, 'verified')
                  : AppCopy.of(context, 'notVerified'),
            ),
            _PreviewLine(
              label: AppCopy.of(context, 'previewSnapshotIntegrity'),
              value: preview.snapshotIntegrityVerified
                  ? AppCopy.of(context, 'verified')
                  : AppCopy.of(context, 'requiresMigrationReview'),
            ),
            _PreviewLine(
              label: AppCopy.of(context, 'previewIncomingRows'),
              value: '${preview.incomingProtectedRows}',
            ),
            _PreviewLine(
              label: AppCopy.of(context, 'previewLocalSensitiveRows'),
              value: '${preview.localSensitiveRowCount}',
            ),
            _PreviewLine(
              label: AppCopy.of(context, 'previewDatabaseMutation'),
              value: AppCopy.of(context, 'nonePerformed'),
            ),
            _PreviewLine(
              label: AppCopy.of(context, 'previewMergeExecution'),
              value: preview.mergeExecutable
                  ? AppCopy.of(context, 'enabled')
                  : AppCopy.of(context, 'disabled'),
            ),
            const SizedBox(height: 8),
            Text(
              eligibility,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(AppCopy.of(context, 'previewTableCounts')),
              children: [
                for (final entry in preview.tableRowCounts.entries)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.key),
                    trailing: Text('${entry.value}'),
                  ),
              ],
            ),
            if (preview.tablePlans.isNotEmpty) ...[
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(AppCopy.of(context, 'previewConflictPlan')),
                children: [
                  for (final plan in preview.tablePlans)
                    _ConflictPlanTile(plan: plan),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: SelectableText('$label: $value'),
      );
}

class _ConflictPlanTile extends StatelessWidget {
  const _ConflictPlanTile({required this.plan});

  final BackupTableConflictPlan plan;

  @override
  Widget build(BuildContext context) {
    final icon = switch (plan.severity) {
      BackupConflictSeverity.none => Icons.check_circle_outline,
      BackupConflictSeverity.equivalent => Icons.content_copy_outlined,
      BackupConflictSeverity.warning => Icons.warning_amber_outlined,
      BackupConflictSeverity.blocking => Icons.block_outlined,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(plan.tableName),
      subtitle: Text(
        '${AppCopy.of(context, 'previewIncoming')}: ${plan.incomingRows} · '
        '${AppCopy.of(context, 'previewLocal')}: ${plan.localRows} · '
        '${AppCopy.of(context, 'previewNewIds')}: ${plan.newIds} · '
        '${AppCopy.of(context, 'previewEquivalentIds')}: ${plan.equivalentIds} · '
        '${AppCopy.of(context, 'previewConflictingIds')}: ${plan.conflictingIds} · '
        '${AppCopy.of(context, 'previewRemappedIds')}: ${plan.remappedIds}',
      ),
    );
  }
}

class _MergeResultCard extends StatelessWidget {
  const _MergeResultCard({required this.result});

  final EncryptedBackupMergeResult result;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppCopy.of(context, 'mergeVerified'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('${AppCopy.of(context, 'importBatch')}: #${result.batchId}'),
              Text('${AppCopy.of(context, 'backupManifestHash')}: ${result.manifestHash}'),
              const SizedBox(height: 6),
              Text('${AppCopy.of(context, 'mergeInsertedRows')}: ${result.insertedRows}'),
              Text('${AppCopy.of(context, 'mergeEquivalentSkipped')}: ${result.equivalentRowsSkipped}'),
              Text('${AppCopy.of(context, 'mergeRemappedRows')}: ${result.remappedRows}'),
              Text('${AppCopy.of(context, 'importBatchMappings')}: ${result.mappingRows}'),
              Text('${AppCopy.of(context, 'importedAuditEvents')}: ${result.importedAuditEvents}'),
              SelectableText('${AppCopy.of(context, 'importBatchReceiptHash')}: ${result.receiptHash}'),
              Text('${AppCopy.of(context, 'mergeRollbackPolicy')}: ${result.transactionalRollbackPolicy}'),
            ],
          ),
        ),
      );
}

class _RestoreResultCard extends StatelessWidget {
  const _RestoreResultCard({required this.result});

  final EncryptedBackupRestoreResult result;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppCopy.of(context, 'restoreVerified'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${AppCopy.of(context, 'backupManifestHash')}: '
                '${result.manifestHash}',
              ),
              const SizedBox(height: 6),
              Text(
                '${AppCopy.of(context, 'backupRecordCount')}: '
                '${result.tableRowCounts.values.fold<int>(0, (a, b) => a + b)}',
              ),
              const SizedBox(height: 6),
              Text(
                '${AppCopy.of(context, 'importedAuditEvents')}: '
                '${result.importedAuditEvents}',
              ),
            ],
          ),
        ),
      );
}
