import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/client_store.dart';
import '../localization/app_copy.dart';
import '../models/professional_report_approval.dart';
import '../models/professional_report_export.dart';
import '../models/professional_report_snapshot.dart';
import '../services/professional_report_verification_service.dart';
import '../services/professional_report_export_service.dart';
import '../widgets/signed_report_qr_view.dart';
import 'signed_report_verification_screen.dart';

class ProfessionalReportPreviewScreen extends StatefulWidget {
  const ProfessionalReportPreviewScreen({
    required this.snapshot,
    this.clientStore,
    super.key,
  });

  final ProfessionalReportSnapshot snapshot;
  final ClientStore? clientStore;

  @override
  State<ProfessionalReportPreviewScreen> createState() =>
      _ProfessionalReportPreviewScreenState();
}

class _ProfessionalReportPreviewScreenState
    extends State<ProfessionalReportPreviewScreen> {
  ProfessionalReportExportFormat? _exporting;
  bool _approving = false;

  ProfessionalReportSnapshot get snapshot => widget.snapshot;
  ProfessionalReportApproval? get approval =>
      widget.clientStore?.approvalForReport(snapshot.id);

  @override
  Widget build(BuildContext context) {
    final bengali = Localizations.localeOf(context).languageCode == 'bn';
    final report = snapshot.report;
    final sections = (report['sections'] as List? ?? const [])
        .whereType<Map>()
        .map((value) => Map<String, Object?>.from(value))
        .toList(growable: false);
    final warnings =
        (report[bengali ? 'warningsBn' : 'warningsEn'] as List? ?? const [])
            .whereType<String>()
            .toList(growable: false);
    final signOff = approval;
    final verificationPayload = signOff == null
        ? null
        : const ProfessionalReportVerificationService().payloadFor(
            snapshot: snapshot,
            approval: signOff,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(AppCopy.of(context, 'professionalReportPreview')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            report['clientName']?.toString() ?? '',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(report['consultationSubject']?.toString() ?? ''),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(snapshot.reportSchemaVersion)),
              Chip(
                label: Text(
                  '${AppCopy.of(context, 'reportAsOf')}: '
                  '${report['asOfUtc'] ?? '—'}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            '${AppCopy.of(context, 'reportHash')}: ${snapshot.reportHash}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          _ApprovalCard(
            approval: signOff,
            canApprove: widget.clientStore != null && !_approving,
            onApprove: signOff == null ? _approveReport : null,
          ),
          if (verificationPayload != null) ...[
            const SizedBox(height: 14),
            _VerificationQrCard(
              payload: verificationPayload,
              canVerify: widget.clientStore != null,
              onVerify: widget.clientStore == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SignedReportVerificationScreen(
                            clientStore: widget.clientStore!,
                            initialPayload: verificationPayload,
                          ),
                        ),
                      ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _exporting == null
                    ? () => _exportAndShare(
                          ProfessionalReportExportFormat.pdf,
                          bengali,
                        )
                    : null,
                icon: _exporting == ProfessionalReportExportFormat.pdf
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: Text(AppCopy.of(context, 'exportReportPdf')),
              ),
              OutlinedButton.icon(
                onPressed: _exporting == null
                    ? () => _exportAndShare(
                          ProfessionalReportExportFormat.docx,
                          bengali,
                        )
                    : null,
                icon: _exporting == ProfessionalReportExportFormat.docx
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.description_outlined),
                label: Text(AppCopy.of(context, 'exportReportDocx')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppCopy.of(context, 'reportExportNote'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          for (final section in sections) ...[
            _ReportSectionCard(section: section, bengali: bengali),
            const SizedBox(height: 12),
          ],
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              AppCopy.of(context, 'reportSafetyWarnings'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final warning in warnings)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(warning),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _approveReport() async {
    final store = widget.clientStore;
    if (store == null || approval != null) return;
    final data = await showDialog<_ApprovalFormData>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ProfessionalReportApprovalDialog(),
    );
    if (data == null || !mounted) return;
    setState(() => _approving = true);
    try {
      await store.approveProfessionalReport(
        report: snapshot,
        practitionerName: data.practitionerName,
        practitionerDesignation: data.practitionerDesignation,
        credentialReference: data.credentialReference,
        decision: data.decision,
        approvalNote: data.approvalNote,
      );
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'approvalSaved'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppCopy.of(context, 'approvalFailed')}\n$error'),
        ),
      );
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  Future<void> _exportAndShare(
    ProfessionalReportExportFormat format,
    bool bengali,
  ) async {
    setState(() => _exporting = format);
    try {
      final locale = bengali
          ? ProfessionalReportExportLocale.bengali
          : ProfessionalReportExportLocale.english;
      final service = const ProfessionalReportExportService();
      final signOff = approval;
      final artifact = format == ProfessionalReportExportFormat.pdf
          ? await service.exportPdf(
              snapshot: snapshot,
              locale: locale,
              approval: signOff,
            )
          : await service.exportDocx(
              snapshot: snapshot,
              locale: locale,
              approval: signOff,
            );
      if (!mounted) return;

      final renderBox = context.findRenderObject() as RenderBox?;
      final mimeType = format == ProfessionalReportExportFormat.pdf
          ? 'application/pdf'
          : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      final verificationHash = artifact.signedReportHash ?? artifact.sourceReportHash;
      await SharePlus.instance.share(
        ShareParams(
          title: AppCopy.of(context, 'professionalReportPreview'),
          subject: snapshot.report['consultationSubject']?.toString(),
          text: signOff == null
              ? '${AppCopy.of(context, 'reportHash')}: $verificationHash'
              : '${AppCopy.of(context, 'signedReportHash')}: $verificationHash',
          files: [XFile(artifact.filePath, mimeType: mimeType)],
          sharePositionOrigin: renderBox == null
              ? null
              : renderBox.localToGlobal(Offset.zero) & renderBox.size,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppCopy.of(context, 'reportExportReady')}\n'
            '${artifact.fileName}\n'
            '${AppCopy.of(context, 'reportExportHash')}: ${artifact.sha256}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppCopy.of(context, 'reportExportFailed')}\n$error',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = null);
    }
  }
}


class _VerificationQrCard extends StatelessWidget {
  const _VerificationQrCard({
    required this.payload,
    required this.canVerify,
    required this.onVerify,
  });

  final String payload;
  final bool canVerify;
  final VoidCallback? onVerify;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_2),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppCopy.of(context, 'signedReportVerificationQr'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(child: SignedReportQrView(payload: payload, size: 170)),
            const SizedBox(height: 10),
            Text(
              AppCopy.of(context, 'verificationScopeDisclosure'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: canVerify ? onVerify : null,
                  icon: const Icon(Icons.verified_outlined),
                  label: Text(AppCopy.of(context, 'verifySignedReport')),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: payload));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppCopy.of(context, 'verificationPayloadCopied'))),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: Text(AppCopy.of(context, 'copyVerificationPayload')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.approval,
    required this.canApprove,
    required this.onApprove,
  });

  final ProfessionalReportApproval? approval;
  final bool canApprove;
  final VoidCallback? onApprove;

  @override
  Widget build(BuildContext context) {
    final signOff = approval;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(signOff == null ? Icons.lock_open_outlined : Icons.verified_user_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppCopy.of(context, 'reportApprovalTitle'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (signOff == null) ...[
              Text(AppCopy.of(context, 'reportNotApproved')),
              const SizedBox(height: 8),
              Text(
                AppCopy.of(context, 'approvalElectronicDisclosure'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (onApprove != null) ...[
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: canApprove ? onApprove : null,
                  icon: const Icon(Icons.draw_outlined),
                  label: Text(AppCopy.of(context, 'approveReport')),
                ),
              ],
            ] else ...[
              Text(
                AppCopy.of(context, 'reportApproved'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text('${AppCopy.of(context, 'practitionerName')}: ${signOff.practitionerName}'),
              Text('${AppCopy.of(context, 'practitionerDesignation')}: ${signOff.practitionerDesignation}'),
              if (signOff.credentialReference.isNotEmpty)
                Text('${AppCopy.of(context, 'credentialReference')}: ${signOff.credentialReference}'),
              Text(
                '${AppCopy.of(context, 'approvalDecision')}: '
                '${AppCopy.of(context, signOff.decision == ProfessionalReportApprovalDecision.approvedForClientDelivery ? 'approvedForClientDelivery' : 'approvedWithReservations')}',
              ),
              Text('${AppCopy.of(context, 'approvedAt')}: ${signOff.approvedAt.toUtc().toIso8601String()}'),
              if (signOff.approvalNote.isNotEmpty)
                Text('${AppCopy.of(context, 'approvalNote')}: ${signOff.approvalNote}'),
              const SizedBox(height: 8),
              SelectableText(
                '${AppCopy.of(context, 'approvalHash')}: ${signOff.approvalHash}\n'
                '${AppCopy.of(context, 'signedReportHash')}: ${signOff.signedReportHash}\n'
                '${AppCopy.of(context, 'approvalContract')}: ${signOff.approvalStatementVersion}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Text(
                AppCopy.of(context, 'approvalImmutableNote'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                AppCopy.of(context, 'approvalElectronicDisclosure'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ApprovalFormData {
  const _ApprovalFormData({
    required this.practitionerName,
    required this.practitionerDesignation,
    required this.credentialReference,
    required this.decision,
    required this.approvalNote,
  });

  final String practitionerName;
  final String practitionerDesignation;
  final String credentialReference;
  final ProfessionalReportApprovalDecision decision;
  final String approvalNote;
}

class _ProfessionalReportApprovalDialog extends StatefulWidget {
  const _ProfessionalReportApprovalDialog();

  @override
  State<_ProfessionalReportApprovalDialog> createState() =>
      _ProfessionalReportApprovalDialogState();
}

class _ProfessionalReportApprovalDialogState
    extends State<_ProfessionalReportApprovalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _designationController = TextEditingController();
  final _credentialController = TextEditingController();
  final _noteController = TextEditingController();
  ProfessionalReportApprovalDecision _decision =
      ProfessionalReportApprovalDecision.approvedForClientDelivery;
  bool _attested = false;
  bool _showAttestationError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _designationController.dispose();
    _credentialController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(AppCopy.of(context, 'reportApprovalTitle')),
        content: SizedBox(
          width: 520,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: AppCopy.of(context, 'practitionerName'),
                    ),
                    validator: (value) => (value?.trim().length ?? 0) < 2
                        ? AppCopy.of(context, 'practitionerName')
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _designationController,
                    decoration: InputDecoration(
                      labelText: AppCopy.of(context, 'practitionerDesignation'),
                    ),
                    validator: (value) => (value?.trim().length ?? 0) < 2
                        ? AppCopy.of(context, 'practitionerDesignation')
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _credentialController,
                    decoration: InputDecoration(
                      labelText: AppCopy.of(context, 'credentialReference'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<ProfessionalReportApprovalDecision>(
                    initialValue: _decision,
                    decoration: InputDecoration(
                      labelText: AppCopy.of(context, 'approvalDecision'),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: ProfessionalReportApprovalDecision.approvedForClientDelivery,
                        child: Text(AppCopy.of(context, 'approvedForClientDelivery')),
                      ),
                      DropdownMenuItem(
                        value: ProfessionalReportApprovalDecision.approvedWithReservations,
                        child: Text(AppCopy.of(context, 'approvedWithReservations')),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _decision = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: AppCopy.of(context, 'approvalNote'),
                    ),
                    validator: (value) => _decision ==
                                ProfessionalReportApprovalDecision.approvedWithReservations &&
                            (value?.trim().isEmpty ?? true)
                        ? AppCopy.of(context, 'approvalNoteRequired')
                        : null,
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _attested,
                    onChanged: (value) => setState(() {
                      _attested = value ?? false;
                      _showAttestationError = false;
                    }),
                    title: Text(AppCopy.of(context, 'approvalAttestation')),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (_showAttestationError)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppCopy.of(context, 'approvalAttestationRequired'),
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    AppCopy.of(context, 'approvalElectronicDisclosure'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.lock_outline),
            label: Text(AppCopy.of(context, 'approvalSave')),
          ),
        ],
      );

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!_attested) {
      setState(() => _showAttestationError = true);
    }
    if (!valid || !_attested) return;
    Navigator.of(context).pop(
      _ApprovalFormData(
        practitionerName: _nameController.text.trim(),
        practitionerDesignation: _designationController.text.trim(),
        credentialReference: _credentialController.text.trim(),
        decision: _decision,
        approvalNote: _noteController.text.trim(),
      ),
    );
  }
}

class _ReportSectionCard extends StatelessWidget {
  const _ReportSectionCard({required this.section, required this.bengali});

  final Map<String, Object?> section;
  final bool bengali;

  @override
  Widget build(BuildContext context) {
    final items = (section['items'] as List? ?? const [])
        .whereType<Map>()
        .map((value) => Map<String, Object?>.from(value))
        .toList(growable: false);
    final status = section['status']?.toString() ?? 'unavailable';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    section[bengali ? 'titleBn' : 'titleEn']?.toString() ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(AppCopy.of(context, 'reportStatus_$status')),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              section[bengali ? 'summaryBn' : 'summaryEn']?.toString() ?? '',
            ),
            for (final item in items) ...[
              const Divider(height: 24),
              Text(
                item[bengali ? 'titleBn' : 'titleEn']?.toString() ?? '',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                item[bengali ? 'narrativeBn' : 'narrativeEn']?.toString() ?? '',
              ),
              if (item['confidence'] != null) ...[
                const SizedBox(height: 6),
                Text(
                  '${AppCopy.of(context, 'confidence')}: '
                  '${item['confidence']}',
                ),
              ],
              if ((item['evidencePaths'] as List? ?? const []).isNotEmpty) ...[
                const SizedBox(height: 6),
                SelectableText(
                  '${AppCopy.of(context, 'chartEvidence')}: '
                  '${(item['evidencePaths'] as List).join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
