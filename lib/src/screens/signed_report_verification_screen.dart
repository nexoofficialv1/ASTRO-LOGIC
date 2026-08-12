import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/client_store.dart';
import '../localization/app_copy.dart';
import '../models/professional_report_verification.dart';
import '../services/professional_report_verification_service.dart';
import '../widgets/signed_report_qr_view.dart';

class SignedReportVerificationScreen extends StatefulWidget {
  const SignedReportVerificationScreen({
    required this.clientStore,
    this.initialPayload = '',
    super.key,
  });

  final ClientStore clientStore;
  final String initialPayload;

  @override
  State<SignedReportVerificationScreen> createState() =>
      _SignedReportVerificationScreenState();
}

class _SignedReportVerificationScreenState
    extends State<SignedReportVerificationScreen> {
  late final TextEditingController _controller;
  ProfessionalReportVerificationResult? _result;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPayload);
    if (widget.initialPayload.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _verify() {
    final result = const ProfessionalReportVerificationService().verify(
      rawPayload: _controller.text,
      reports: widget.clientStore.professionalReports,
      approvals: widget.clientStore.professionalReportApprovals,
    );
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: Text(AppCopy.of(context, 'signedReportVerifierTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppCopy.of(context, 'signedReportVerifierIntro'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            minLines: 5,
            maxLines: 10,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: AppCopy.of(context, 'verificationPayload'),
              hintText: AppCopy.of(context, 'verificationPayloadHint'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _controller.text.trim().isEmpty ? null : _verify,
                icon: const Icon(Icons.verified_outlined),
                label: Text(AppCopy.of(context, 'verifySignedReport')),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (!mounted || data?.text == null) return;
                  _controller.text = data!.text!;
                  _verify();
                },
                icon: const Icon(Icons.content_paste_outlined),
                label: Text(AppCopy.of(context, 'pasteAndVerify')),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            AppCopy.of(context, 'verificationScopeDisclosure'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (result != null) ...[
            const SizedBox(height: 18),
            _VerificationResultCard(result: result),
          ],
        ],
      ),
    );
  }
}

class _VerificationResultCard extends StatelessWidget {
  const _VerificationResultCard({required this.result});

  final ProfessionalReportVerificationResult result;

  @override
  Widget build(BuildContext context) {
    final payload = result.payload;
    final (icon, color) = switch (result.status) {
      ProfessionalReportVerificationStatus.verifiedAgainstLocalRecord =>
        (Icons.verified_user_outlined, Theme.of(context).colorScheme.primary),
      ProfessionalReportVerificationStatus.validPayloadNoLocalRecord =>
        (Icons.help_outline, Theme.of(context).colorScheme.secondary),
      ProfessionalReportVerificationStatus.mismatchDetected =>
        (Icons.warning_amber_outlined, Theme.of(context).colorScheme.error),
      ProfessionalReportVerificationStatus.invalidPayload =>
        (Icons.error_outline, Theme.of(context).colorScheme.error),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppCopy.of(context, result.summaryCode),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final code in result.evidenceCodes)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${AppCopy.of(context, code)}'),
              ),
            if (payload != null) ...[
              const Divider(height: 24),
              Center(child: SignedReportQrView(payload: payload.encode(), size: 150)),
              const SizedBox(height: 10),
              SelectableText(
                '${AppCopy.of(context, 'signedReportHash')}: ${payload.signedReportHash}\n'
                '${AppCopy.of(context, 'reportHash')}: ${payload.reportHash}\n'
                '${AppCopy.of(context, 'approvalHash')}: ${payload.approvalHash}\n'
                '${AppCopy.of(context, 'verificationContract')}: ${payload.contractVersion}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
