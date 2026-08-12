import 'package:flutter/material.dart';

import '../data/client_store.dart';
import '../localization/app_copy.dart';
import '../models/consultation.dart';
import '../models/kundli_analysis_snapshot.dart';
import '../numerology/numerology_analysis.dart';
import '../numerology/numerology_analysis_policy.dart';
import '../numerology/numerology_engine.dart';
import '../numerology/numerology_judgment_engine.dart';
import '../services/numerology_snapshot_orchestrator.dart';

class NumerologyWorkspaceScreen extends StatefulWidget {
  const NumerologyWorkspaceScreen({
    this.clientStore,
    this.consultationId,
    this.initialName = '',
    this.initialBirthDate,
    super.key,
  });

  final ClientStore? clientStore;
  final int? consultationId;
  final String initialName;
  final DateTime? initialBirthDate;

  @override
  State<NumerologyWorkspaceScreen> createState() =>
      _NumerologyWorkspaceScreenState();
}

class _NumerologyWorkspaceScreenState
    extends State<NumerologyWorkspaceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _candidateNamesController;
  String? _professionalSelectedName;
  DateTime? _birthDate;
  late int _targetYear;
  NumerologyProfile? _profile;
  NumerologyAnalysis? _analysis;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _candidateNamesController = TextEditingController();
    _birthDate = widget.initialBirthDate;
    _targetYear = DateTime.now().year;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _candidateNamesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = [for (var year = currentYear - 1; year <= currentYear + 9; year += 1) year];
    final profile = _profile;
    final analysis = _analysis;
    return Scaffold(
      appBar: AppBar(title: Text(AppCopy.of(context, 'numerologyWorkspace'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              AppCopy.of(context, 'numerologyIntro'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText:
                              AppCopy.of(context, 'latinNameForCalculation'),
                          helperText: AppCopy.of(context, 'exactSpellingNote'),
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return AppCopy.of(context, 'required');
                          }
                          if (!RegExp(r"^[A-Za-z .'-]+$").hasMatch(text)) {
                            return AppCopy.of(context, 'numerologySpellingInvalid');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _candidateNamesController,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: AppCopy.of(context, 'alternateSpellings'),
                          helperText:
                              AppCopy.of(context, 'alternateSpellingsHint'),
                          alignLabelWithHint: true,
                          prefixIcon: const Icon(Icons.compare_arrows_outlined),
                        ),
                        validator: (value) {
                          final candidates = _candidateNamesFromText(value ?? '');
                          if (candidates.length > NumerologyEngine.maxAlternateNames) {
                            return 'Maximum ${NumerologyEngine.maxAlternateNames}';
                          }
                          for (final candidate in candidates) {
                            if (!RegExp(r"^[A-Za-z .'-]+$").hasMatch(candidate)) {
                              return AppCopy.of(context, 'numerologySpellingInvalid');
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed:
                            widget.consultationId == null ? _pickBirthDate : null,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _birthDate == null
                                ? AppCopy.of(context, 'selectBirthDate')
                                : '${AppCopy.of(context, 'birthDate')}: ${_dateText(_birthDate!)}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int>(
                        value: _targetYear,
                        decoration: InputDecoration(
                          labelText: AppCopy.of(context, 'personalYearTarget'),
                          prefixIcon: const Icon(Icons.event_repeat_outlined),
                        ),
                        items: [
                          for (final year in years)
                            DropdownMenuItem(value: year, child: Text('$year')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _targetYear = value);
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _calculate,
                        icon: const Icon(Icons.calculate_outlined),
                        label:
                            Text(AppCopy.of(context, 'calculateNumerology')),
                      ),
                      if (widget.clientStore != null &&
                          widget.consultationId != null &&
                          profile != null &&
                          analysis != null) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _isSaving ? null : _saveSnapshot,
                          icon: _isSaving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.lock_outline),
                          label: Text(
                            AppCopy.of(
                              context,
                              _isSaving
                                  ? 'numerologySnapshotSaving'
                                  : 'saveNumerologySnapshot',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (profile != null && analysis != null) ...[
              const SizedBox(height: 20),
              _CalculationSummary(profile: profile),
              if (profile.nameCandidateComparisons.isNotEmpty) ...[
                const SizedBox(height: 16),
                _NameCandidateComparisonSection(
                  profile: profile,
                  selectedName: _professionalSelectedName,
                  onSelected: _setProfessionalNameFocus,
                ),
              ],
              const SizedBox(height: 16),
              _InterpretationSection(analysis: analysis),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (selected != null) setState(() => _birthDate = selected);
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      setState(() => _error = AppCopy.of(context, 'selectBirthDate'));
      return;
    }
    try {
      final candidates = _candidateNamesFromText(_candidateNamesController.text);
      final selected = _professionalSelectedName;
      final selectedStillPresent = selected == null || candidates.any(
        (value) => value.trim().toUpperCase() == selected.trim().toUpperCase(),
      );
      if (!selectedStillPresent) _professionalSelectedName = null;
      final profile = const NumerologyEngine().calculate(
        NumerologyInput(
          fullNameLatin: _nameController.text,
          birthDate: _birthDate!,
          personalYear: _targetYear,
          alternateNamesLatin: candidates,
          professionalSelectedNameLatin: _professionalSelectedName,
        ),
      );
      final consultationId = widget.consultationId;
      final store = widget.clientStore;
      final vedicSnapshots = store == null || consultationId == null
          ? const <KundliAnalysisSnapshot>[]
          : store.kundliAnalysesForConsultation(consultationId);
      final analysis = const NumerologyJudgmentEngine().analyze(
        profile,
        vedicSnapshot: vedicSnapshots.isEmpty ? null : vedicSnapshots.first,
      );
      NumerologyAnalysisPolicy.validate(analysis);
      setState(() {
        _profile = profile;
        _analysis = analysis;
        _error = null;
      });
    } on Object {
      setState(() {
        _profile = null;
        _analysis = null;
        _error = AppCopy.of(context, 'numerologyCalculationFailed');
      });
    }
  }

  void _setProfessionalNameFocus(String? normalizedName) {
    setState(() => _professionalSelectedName = normalizedName);
    _calculate();
  }

  static List<String> _candidateNamesFromText(String value) => value
      .split(RegExp(r'[\r\n]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  Future<void> _saveSnapshot() async {
    final store = widget.clientStore;
    final consultationId = widget.consultationId;
    if (store == null || consultationId == null) return;
    final consultation = store.findConsultationById(consultationId);
    if (consultation == null) {
      setState(() => _error = AppCopy.of(context, 'databaseError'));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await NumerologySnapshotOrchestrator(store).run(
        consultation: consultation,
        nameLatin: _nameController.text,
        targetYear: _targetYear,
        alternateNamesLatin: _candidateNamesFromText(
          _candidateNamesController.text,
        ),
        professionalSelectedNameLatin: _professionalSelectedName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppCopy.of(context, 'numerologySnapshotSaved')),
        ),
      );
    } on Object {
      if (!mounted) return;
      setState(() => _error = AppCopy.of(context, 'databaseError'));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  static String _dateText(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.year.toString().padLeft(4, '0')}';
}

class _CalculationSummary extends StatelessWidget {
  const _CalculationSummary({required this.profile});

  final NumerologyProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppCopy.of(context, 'calculationBreakdown'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            SelectableText(profile.normalizedName),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _NumberTile(
                  label: AppCopy.of(context, 'driverNumber'),
                  value: profile.driver,
                ),
                _NumberTile(
                  label: AppCopy.of(context, 'lifePathNumber'),
                  value: profile.lifePath,
                ),
                _NumberTile(
                  label: AppCopy.of(context, 'maturityNumber'),
                  value: profile.maturity,
                ),
                _NumberTile(
                  label: AppCopy.of(context, 'personalYearNumber'),
                  value: profile.personalYear,
                ),
                _NumberTile(
                  label: AppCopy.of(context, 'pythagoreanExpression'),
                  value: profile.pythagorean.expression,
                ),
                _NumberTile(
                  label: AppCopy.of(context, 'soulUrgeNumber'),
                  value: profile.pythagorean.soulUrge!,
                ),
                _NumberTile(
                  label: AppCopy.of(context, 'personalityNumber'),
                  value: profile.pythagorean.personality!,
                ),
                _NumberTile(
                  label: AppCopy.of(context, 'chaldeanNameNumber'),
                  value: profile.chaldean.expression,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(AppCopy.of(context, 'calculationEvidence')),
              children: [
                for (final evidence in profile.evidence)
                  ListTile(
                    dense: true,
                    title: SelectableText(evidence.calculation),
                    subtitle: Text(evidence.ruleId),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({required this.label, required this.value});

  final String label;
  final NumerologyValue value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 145),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 5),
          Text(
            '${value.compound} → ${value.reduced}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

class _NameCandidateComparisonSection extends StatelessWidget {
  const _NameCandidateComparisonSection({
    required this.profile,
    required this.selectedName,
    required this.onSelected,
  });

  final NumerologyProfile profile;
  final String? selectedName;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final bengali = Localizations.localeOf(context).languageCode == 'bn';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppCopy.of(context, 'nameCandidateComparison'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(AppCopy.of(context, 'nameCandidateSafety')),
            const SizedBox(height: 12),
            for (final comparison in profile.nameCandidateComparisons)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              comparison.candidateName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (comparison.selectedForProfessionalReview)
                            const Icon(Icons.how_to_reg_outlined),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${comparison.status.name} · '
                        'P ${comparison.pythagoreanDelta.baselineReduced}→${comparison.pythagoreanDelta.candidateReduced} '
                        '(Δ ${_signed(comparison.pythagoreanDelta.compoundDelta)}) · '
                        'C ${comparison.chaldeanDelta.baselineReduced}→${comparison.chaldeanDelta.candidateReduced} '
                        '(Δ ${_signed(comparison.chaldeanDelta.compoundDelta)})',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bengali
                            ? 'Core-number overlap শুধু arithmetic reference; বেশি overlap মানে বেশি শুভ নয়।'
                            : 'Core-number overlap is an arithmetic reference only; more overlap does not mean more favourable.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (comparison.flags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        SelectableText(comparison.flags.join(' · ')),
                      ],
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: comparison.selectedForProfessionalReview
                            ? OutlinedButton.icon(
                                onPressed: () => onSelected(null),
                                icon: const Icon(Icons.clear),
                                label: Text(
                                  AppCopy.of(
                                    context,
                                    'professionalNameFocusClear',
                                  ),
                                ),
                              )
                            : OutlinedButton.icon(
                                onPressed: () =>
                                    onSelected(comparison.candidateName),
                                icon: const Icon(Icons.how_to_reg_outlined),
                                label: Text(
                                  AppCopy.of(
                                    context,
                                    'professionalNameFocusAction',
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_search_outlined),
              title: Text(AppCopy.of(context, 'professionalNameFocus')),
              subtitle: Text(
                selectedName ??
                    AppCopy.of(context, 'professionalNameFocusNone'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _signed(int value) => value > 0 ? '+$value' : '$value';
}

class _InterpretationSection extends StatelessWidget {
  const _InterpretationSection({required this.analysis});

  final NumerologyAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final bengali = Localizations.localeOf(context).languageCode == 'bn';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppCopy.of(context, 'strengthsChallenges'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        for (final finding in analysis.findings)
          Card(
            child: ExpansionTile(
              title: Text(bengali ? finding.titleBn : finding.titleEn),
              subtitle: Text(
                '${finding.polarity.name} · ${finding.confidence.name}',
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(
                    bengali ? finding.narrativeBn : finding.narrativeEn,
                  ),
                ),
                const SizedBox(height: 8),
                for (final evidence in finding.evidence)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${evidence.ruleId}: ${bengali ? evidence.descriptionBn : evidence.descriptionEn}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        Text(
          AppCopy.of(context, 'numerologyPredictionConfidence'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: Text(
              '${analysis.confidenceSummary.predictionConfidence.name} · deterministic arithmetic',
            ),
            subtitle: Text(
              bengali
                  ? analysis.confidenceSummary.rationaleBn
                  : analysis.confidenceSummary.rationaleEn,
            ),
          ),
        ),
        if (analysis.crossSystemFindings.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            AppCopy.of(context, 'vedicCrossCheck'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final finding in analysis.crossSystemFindings)
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.compare_arrows_outlined),
                title: Text(bengali ? finding.titleBn : finding.titleEn),
                subtitle: Text(finding.confidence.name),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(
                      bengali ? finding.narrativeBn : finding.narrativeEn,
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 14),
        Text(
          AppCopy.of(context, 'personalYearWindow'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final timing in analysis.timingWindows)
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_repeat_outlined),
              title: Text(bengali ? timing.narrativeBn : timing.narrativeEn),
              subtitle: Text(
                '${timing.start.year}–${timing.end.year - 1} · ${timing.confidence.name}',
              ),
            ),
          ),
        const SizedBox(height: 14),
        Text(
          AppCopy.of(context, 'numerologyRemedyReview'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final remedy in analysis.remedyCandidates)
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.task_alt_outlined),
              title: Text(bengali ? remedy.actionBn : remedy.actionEn),
              subtitle:
                  Text(bengali ? remedy.rationaleBn : remedy.rationaleEn),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(bengali ? remedy.cautionBn : remedy.cautionEn),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        ExpansionTile(
          title: Text(AppCopy.of(context, 'numerologyWarnings')),
          children: [
            for (final warning
                in bengali ? analysis.warningsBn : analysis.warningsEn)
              ListTile(
                dense: true,
                leading: const Icon(Icons.info_outline),
                title: Text(warning),
              ),
          ],
        ),
      ],
    );
  }
}
