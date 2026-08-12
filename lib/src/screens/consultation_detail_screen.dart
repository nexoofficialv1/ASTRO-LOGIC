import 'package:flutter/material.dart';

import '../data/client_store.dart';
import '../ephemeris/production_vedic_engine.dart';
import '../localization/app_copy.dart';
import '../kp/kp_native_chart_engine.dart';
import '../kp/kp_native_ffi_bridge.dart';
import '../western/western_chart_engine.dart';
import '../western/western_native_ffi_bridge.dart';
import '../models/consultation.dart';
import '../models/client.dart';
import '../models/birth_record.dart';
import '../models/gemstone_remedy.dart';
import '../models/kundli_analysis_snapshot.dart';
import '../models/numerology_snapshot.dart';
import '../models/professional_report_snapshot.dart';
import '../services/calculation_orchestrator.dart';
import '../services/kundli_analysis_orchestrator.dart';
import '../services/kp_native_chart_orchestrator.dart';
import '../services/western_chart_orchestrator.dart';
import '../services/professional_report_engine.dart';
import '../vedic/vedic_lagna_judgment_engine.dart';
import 'consultation_form_screen.dart';
import 'gemstone_remedy_form_screen.dart';
import 'numerology_workspace_screen.dart';
import 'professional_report_preview_screen.dart';
import 'vedic_dasha_timeline_screen.dart';

part 'consultation_detail_analysis_sections.dart';
part 'consultation_detail_analysis_widgets.dart';

class ConsultationDetailScreen extends StatefulWidget {
  const ConsultationDetailScreen({
    required this.clientStore,
    required this.consultationId,
    super.key,
  });

  final ClientStore clientStore;
  final int consultationId;

  @override
  State<ConsultationDetailScreen> createState() =>
      _ConsultationDetailScreenState();
}

class _ConsultationDetailScreenState extends State<ConsultationDetailScreen> {
  bool _isRunningKundli = false;
  bool _isRunningKp = false;
  bool _isRunningWestern = false;
  bool _isGeneratingReport = false;

  ClientStore get clientStore => widget.clientStore;
  int get consultationId => widget.consultationId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: clientStore,
      builder: (context, _) {
        final consultation = clientStore.findConsultationById(consultationId);
        if (consultation == null) {
          return const Scaffold(
            body: Center(child: Text('Consultation not found')),
          );
        }
        final client = clientStore.findById(consultation.clientId)!;
        final records = client.birthRecords.where(
          (record) => record.id == consultation.birthRecordId,
        );
        final birthRecord = records.isEmpty ? null : records.first;
        final outputs = clientStore.outputsForConsultation(consultationId);
        final gemstoneRemedies =
            clientStore.gemstoneRemediesForConsultation(consultationId);
        final kundliAnalyses =
            clientStore.kundliAnalysesForConsultation(consultationId);
        final dashaOutputs = outputs.where((output) {
          final raw = output.output['vimshottari'];
          return raw is Map &&
              raw['ruleVersion'] == 'vimshottari-calendar-v2';
        }).toList(growable: false);
        final dashaOutput =
            dashaOutputs.isEmpty ? null : dashaOutputs.first;
        final vimshottari = dashaOutput == null
            ? null
            : Map<String, Object?>.from(
                dashaOutput.output['vimshottari']! as Map,
              );
        final matchingDashaAnalyses = dashaOutput == null
            ? const <KundliAnalysisSnapshot>[]
            : kundliAnalyses
                .where(
                  (analysis) =>
                      analysis.calculationOutputId == dashaOutput.id,
                )
                .toList(growable: false);
        final latestTimingWindows = matchingDashaAnalyses.isEmpty
            ? const <Map<String, Object?>>[]
            : (matchingDashaAnalyses.first.analysis['timingWindows'] as List? ??
                    const [])
                .whereType<Map>()
                .map((value) => Map<String, Object?>.from(value))
                .toList(growable: false);
        final latestDashaProfiles = matchingDashaAnalyses.isEmpty
            ? const <Map<String, Object?>>[]
            : (matchingDashaAnalyses.first
                        .analysis['dashaActivationProfiles'] as List? ??
                    const [])
                .whereType<Map>()
                .map((value) => Map<String, Object?>.from(value))
                .toList(growable: false);
        final latestPratyantardashaInterpretations =
            matchingDashaAnalyses.isEmpty
                ? const <Map<String, Object?>>[]
                : (matchingDashaAnalyses.first
                            .analysis['pratyantardashaInterpretations'] as List? ??
                        const [])
                    .whereType<Map>()
                    .map((value) => Map<String, Object?>.from(value))
                    .toList(growable: false);
        final numerologySnapshots =
            clientStore.numerologySnapshotsForConsultation(consultationId);
        final professionalReports =
            clientStore.professionalReportsForConsultation(consultationId);
        final canGenerateReport = consultation.status !=
                ConsultationStatus.finalized &&
            birthRecord != null &&
            (kundliAnalyses.isNotEmpty || numerologySnapshots.isNotEmpty);
        final canRunVedic = consultation.status !=
                ConsultationStatus.finalized &&
            consultation.systems.contains(AstrologySystem.vedic);
        final canRunNumerology = consultation.status !=
                ConsultationStatus.finalized &&
            consultation.systems.contains(AstrologySystem.numerology) &&
            birthRecord != null;
        final canRunKp = consultation.status !=
                ConsultationStatus.finalized &&
            consultation.systems.contains(AstrologySystem.kp) &&
            birthRecord != null;
        final canRunWestern = consultation.status !=
                ConsultationStatus.finalized &&
            consultation.systems.contains(AstrologySystem.western) &&
            birthRecord != null;

        return Scaffold(
          appBar: AppBar(
            title: Text(AppCopy.of(context, 'consultationDetails')),
            actions: [
              IconButton(
                tooltip: AppCopy.of(context, 'editConsultation'),
                onPressed: consultation.status == ConsultationStatus.finalized
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ConsultationFormScreen(
                              clientStore: clientStore,
                              client: client,
                              existingConsultation: consultation,
                            ),
                          ),
                        ),
                icon: const Icon(Icons.edit_note_outlined),
              ),
            ],
          ),
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
                        consultation.subject,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${AppCopy.of(context, consultation.category.name)} • '
                        '${AppCopy.of(context, consultation.status.name)}',
                      ),
                      if (birthRecord != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${AppCopy.of(context, 'selectBirthRecord')}: '
                          '${birthRecord.label} — ${birthRecord.placeName}',
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: consultation.systems
                            .map((system) => Chip(
                                  label: Text(
                                    AppCopy.of(context, system.name),
                                  ),
                                ))
                            .toList(),
                      ),
                      if (consultation.notes.isNotEmpty) ...[
                        const Divider(height: 28),
                        Text(consultation.notes),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: consultation.status == ConsultationStatus.finalized
                    ? null
                    : () => _prepareInput(context, consultation),
                icon: const Icon(Icons.lock_clock_outlined),
                label: Text(AppCopy.of(context, 'prepareInput')),
              ),
              const SizedBox(height: 8),
              Text(AppCopy.of(context, 'idempotentInputNote')),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: canRunVedic && !_isRunningKundli
                    ? () => _runKundliAnalysis(context, consultation)
                    : null,
                icon: _isRunningKundli
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_outlined),
                label: Text(
                  AppCopy.of(
                    context,
                    _isRunningKundli
                        ? 'kundliAnalysisRunning'
                        : 'runKundliAnalysis',
                  ),
                ),
              ),
              if (!consultation.systems.contains(AstrologySystem.vedic)) ...[
                const SizedBox(height: 8),
                Text(AppCopy.of(context, 'vedicSystemRequired')),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: canRunKp && !_isRunningKp
                    ? () => _runKpChart(context, consultation)
                    : null,
                icon: _isRunningKp
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.hub_outlined),
                label: Text(
                  AppCopy.of(
                    context,
                    _isRunningKp ? 'kpNativeRunning' : 'runKpNativeChart',
                  ),
                ),
              ),
              if (!consultation.systems.contains(AstrologySystem.kp)) ...[
                const SizedBox(height: 8),
                Text(AppCopy.of(context, 'kpSystemRequired')),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: canRunWestern && !_isRunningWestern
                    ? () => _runWesternChart(context, consultation)
                    : null,
                icon: _isRunningWestern
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.public_outlined),
                label: Text(
                  AppCopy.of(
                    context,
                    _isRunningWestern ? 'westernChartRunning' : 'westernCastChart',
                  ),
                ),
              ),
              if (!consultation.systems.contains(AstrologySystem.western)) ...[
                const SizedBox(height: 8),
                Text(AppCopy.of(context, 'westernSystemRequired')),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: canRunNumerology
                    ? () => _openNumerologyWorkspace(
                          context,
                          consultation,
                          client.fullName,
                          birthRecord!.localDateTime,
                        )
                    : null,
                icon: const Icon(Icons.calculate_outlined),
                label: Text(AppCopy.of(context, 'runNumerologyAnalysis')),
              ),
              if (!consultation.systems
                  .contains(AstrologySystem.numerology)) ...[
                const SizedBox(height: 8),
                Text(AppCopy.of(context, 'numerologySystemRequired')),
              ],
              const SizedBox(height: 24),
              Text(
                AppCopy.of(context, 'calculationOutputs'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (outputs.isEmpty) ...[
                Text(AppCopy.of(context, 'enginePending')),
                const SizedBox(height: 8),
                Text(AppCopy.of(context, 'reviewRequiresOutput')),
              ],
              for (final output in outputs)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.verified_outlined),
                    title: Text(output.engineId),
                    subtitle: Text(
                      '${AppCopy.of(context, 'engineVersion')}: '
                      '${output.engineVersion}\n'
                      '${AppCopy.of(context, 'outputHash')}: '
                      '${output.outputHash.substring(0, 16)}…',
                    ),
                    isThreeLine: true,
                  ),
                ),
              if (vimshottari != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.timeline_outlined),
                    title: Text(AppCopy.of(context, 'dashaTimeline')),
                    subtitle: Text(
                      AppCopy.of(context, 'dashaTimelineSummary'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => VedicDashaTimelineScreen(
                          vimshottari: vimshottari,
                          timingWindows: latestTimingWindows,
                          dashaActivationProfiles: latestDashaProfiles,
                          pratyantardashaInterpretations:
                              latestPratyantardashaInterpretations,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              _KundliAnalysisSection(analyses: kundliAnalyses),
              const SizedBox(height: 24),
              _NumerologySnapshotSection(snapshots: numerologySnapshots),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppCopy.of(context, 'professionalReports'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: canGenerateReport && !_isGeneratingReport
                        ? () => _generateProfessionalReport(
                              context,
                              consultation,
                              client,
                              birthRecord!,
                              kundliAnalyses,
                              numerologySnapshots,
                              gemstoneRemedies,
                            )
                        : null,
                    icon: _isGeneratingReport
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.description_outlined),
                    label: Text(AppCopy.of(context, 'generateProfessionalReport')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (professionalReports.isEmpty)
                Text(AppCopy.of(context, 'noProfessionalReports')),
              for (final report in professionalReports)
                Card(
                  child: ListTile(
                    leading: Icon(
                      clientStore.approvalForReport(report.id) == null
                          ? Icons.article_outlined
                          : Icons.verified_user_outlined,
                    ),
                    title: Text(report.reportSchemaVersion),
                    subtitle: Text(
                      '${report.createdAt.toLocal()}\n'
                      '${AppCopy.of(context, 'reportHash')}: '
                      '${report.reportHash.substring(0, 16)}…\n'
                      '${clientStore.approvalForReport(report.id) == null ? AppCopy.of(context, 'reportNotApproved') : AppCopy.of(context, 'reportApproved')}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProfessionalReportPreviewScreen(
                          snapshot: report,
                          clientStore: clientStore,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppCopy.of(context, 'gemstoneRemedies'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: AppCopy.of(context, 'addGemstoneRemedy'),
                    onPressed:
                        consultation.status == ConsultationStatus.finalized
                            ? null
                            : () => _openGemstoneRemedyForm(
                                  context,
                                  consultation,
                                  outputs.isNotEmpty,
                                ),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (gemstoneRemedies.isEmpty)
                Text(AppCopy.of(context, 'noGemstoneRemedies')),
              for (final remedy in gemstoneRemedies)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.diamond_outlined),
                    title: Text(remedy.primaryGemstone),
                    subtitle: Text(
                      '${AppCopy.of(context, remedy.planet.name)} • '
                      '${remedy.weightValue} '
                      '${AppCopy.of(context, remedy.weightUnit.name)} • '
                      '${AppCopy.of(context, remedy.decision.name)}',
                    ),
                    trailing: consultation.status ==
                            ConsultationStatus.finalized
                        ? const Icon(Icons.lock_outline)
                        : const Icon(Icons.edit_outlined),
                    onTap: consultation.status == ConsultationStatus.finalized
                        ? null
                        : () => _openGemstoneRemedyForm(
                              context,
                              consultation,
                              outputs.isNotEmpty,
                              existingRemedy: remedy,
                            ),
                  ),
                ),
              const SizedBox(height: 24),
              _StatusActions(
                consultation: consultation,
                outputsExist:
                    outputs.isNotEmpty || numerologySnapshots.isNotEmpty,
                onTransition: (target) =>
                    _transition(context, consultation, target),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _runKpChart(
    BuildContext context,
    Consultation consultation,
  ) async {
    setState(() => _isRunningKp = true);
    try {
      await KpNativeChartOrchestrator(clientStore).run(
        consultation: consultation,
        engine: KpNativeChartEngine(KpNativeFfiBridge.open()),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'kpNativeReady'))),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppCopy.of(context, 'kpNativeFailed')}\n$error'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isRunningKp = false);
    }
  }

  Future<void> _runWesternChart(
    BuildContext context,
    Consultation consultation,
  ) async {
    setState(() => _isRunningWestern = true);
    try {
      await WesternChartOrchestrator(clientStore).run(
        consultation: consultation,
        engine: WesternChartEngine(WesternNativeFfiBridge.open()),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'westernChartReady'))),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppCopy.of(context, 'westernChartFailed')}\n$error'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isRunningWestern = false);
    }
  }

  Future<void> _runKundliAnalysis(
    BuildContext context,
    Consultation consultation,
  ) async {
    setState(() => _isRunningKundli = true);
    try {
      final calculationOutput = await CalculationOrchestrator(clientStore).run(
        consultation: consultation,
        engine: createProductionVedicEngine(),
      );
      await KundliAnalysisOrchestrator(clientStore).run(
        consultation: consultation,
        calculationOutput: calculationOutput,
        engine: const VedicLagnaJudgmentEngine(),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'kundliAnalysisReady'))),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppCopy.of(context, 'kundliAnalysisFailed')}\n$error',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isRunningKundli = false);
    }
  }

  Future<void> _generateProfessionalReport(
    BuildContext context,
    Consultation consultation,
    Client client,
    BirthRecord birthRecord,
    List<KundliAnalysisSnapshot> kundliAnalyses,
    List<NumerologySnapshot> numerologySnapshots,
    List<GemstoneRemedy> gemstoneRemedies,
  ) async {
    setState(() => _isGeneratingReport = true);
    try {
      final report = const ProfessionalReportEngine().build(
        consultation: consultation,
        client: client,
        birthRecord: birthRecord,
        asOfUtc: DateTime.now().toUtc(),
        kundli: kundliAnalyses.isEmpty ? null : kundliAnalyses.first,
        numerology: numerologySnapshots.isEmpty ? null : numerologySnapshots.first,
        gemstoneRemedies: gemstoneRemedies,
      );
      final id = await clientStore.createProfessionalReportSnapshot(
        consultation: consultation,
        report: report,
        engineId: ProfessionalReportEngine.engineId,
        engineVersion: ProfessionalReportEngine.engineVersion,
        reportSchemaVersion: ProfessionalReportEngine.reportSchemaVersion,
      );
      final snapshots = clientStore.professionalReportsForConsultation(consultation.id!);
      final snapshot = snapshots.firstWhere((value) => value.id == id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'professionalReportReady'))),
      );
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProfessionalReportPreviewScreen(
            snapshot: snapshot,
            clientStore: clientStore,
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppCopy.of(context, 'professionalReportFailed')}\n$error'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingReport = false);
    }
  }

  Future<void> _openNumerologyWorkspace(
    BuildContext context,
    Consultation consultation,
    String clientName,
    DateTime birthDate,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NumerologyWorkspaceScreen(
          clientStore: clientStore,
          consultationId: consultation.id,
          initialName: clientName,
          initialBirthDate: birthDate,
        ),
      ),
    );
  }

  void _openGemstoneRemedyForm(
    BuildContext context,
    Consultation consultation,
    bool verifiedOutputExists, {
    GemstoneRemedy? existingRemedy,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GemstoneRemedyFormScreen(
          clientStore: clientStore,
          consultation: consultation,
          verifiedOutputExists: verifiedOutputExists,
          existingRemedy: existingRemedy,
        ),
      ),
    );
  }

  Future<void> _prepareInput(
    BuildContext context,
    Consultation consultation,
  ) async {
    try {
      await CalculationOrchestrator(clientStore).prepareInput(consultation);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'inputReady'))),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'databaseError'))),
      );
    }
  }

  Future<void> _transition(
    BuildContext context,
    Consultation consultation,
    ConsultationStatus target,
  ) async {
    try {
      await clientStore.updateConsultation(Consultation(
        id: consultation.id,
        clientId: consultation.clientId,
        birthRecordId: consultation.birthRecordId,
        subject: consultation.subject,
        category: consultation.category,
        systems: consultation.systems,
        status: target,
        notes: consultation.notes,
        createdAt: consultation.createdAt,
        updatedAt: DateTime.now(),
      ));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'statusUpdated'))),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'invalidTransition'))),
      );
    }
  }
}
