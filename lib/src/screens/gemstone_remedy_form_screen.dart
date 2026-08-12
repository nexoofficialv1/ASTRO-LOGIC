import 'package:flutter/material.dart';

import '../data/client_store.dart';
import '../localization/app_copy.dart';
import '../models/consultation.dart';
import '../models/gemstone_remedy.dart';

class GemstoneRemedyFormScreen extends StatefulWidget {
  const GemstoneRemedyFormScreen({
    required this.clientStore,
    required this.consultation,
    required this.verifiedOutputExists,
    this.existingRemedy,
    super.key,
  });

  final ClientStore clientStore;
  final Consultation consultation;
  final bool verifiedOutputExists;
  final GemstoneRemedy? existingRemedy;

  @override
  State<GemstoneRemedyFormScreen> createState() =>
      _GemstoneRemedyFormScreenState();
}

class _GemstoneRemedyFormScreenState
    extends State<GemstoneRemedyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _primaryGemstone;
  late final TextEditingController _substituteGemstone;
  late final TextEditingController _weight;
  late final TextEditingController _metal;
  late final TextEditingController _finger;
  late final TextEditingController _wearingDay;
  late final TextEditingController _instructions;
  late final TextEditingController _astrologicalReason;
  late final TextEditingController _evidence;
  late final TextEditingController _cautions;
  late RemedyPlanet _planet;
  late GemstoneWeightUnit _weightUnit;
  late RemedyDecision _decision;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final remedy = widget.existingRemedy;
    _planet = remedy?.planet ?? RemedyPlanet.sun;
    _weightUnit = remedy?.weightUnit ?? GemstoneWeightUnit.ratti;
    _decision = remedy?.decision ?? RemedyDecision.draft;
    _primaryGemstone = TextEditingController(text: remedy?.primaryGemstone);
    _substituteGemstone =
        TextEditingController(text: remedy?.substituteGemstone);
    _weight = TextEditingController(
      text: remedy == null ? '' : remedy.weightValue.toString(),
    );
    _metal = TextEditingController(text: remedy?.metal);
    _finger = TextEditingController(text: remedy?.finger);
    _wearingDay = TextEditingController(text: remedy?.wearingDay);
    _instructions = TextEditingController(text: remedy?.instructions);
    _astrologicalReason =
        TextEditingController(text: remedy?.astrologicalReason);
    _evidence = TextEditingController(
      text: remedy?.evidenceReferences.join('\n'),
    );
    _cautions = TextEditingController(text: remedy?.cautions);
  }

  @override
  void dispose() {
    for (final controller in [
      _primaryGemstone,
      _substituteGemstone,
      _weight,
      _metal,
      _finger,
      _wearingDay,
      _instructions,
      _astrologicalReason,
      _evidence,
      _cautions,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existingRemedy != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppCopy.of(
          context,
          editing ? 'editGemstoneRemedy' : 'addGemstoneRemedy',
        )),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(AppCopy.of(context, 'remedyTraditionalDisclaimer')),
              ),
            ),
            const SizedBox(height: 12),
            _dropdown<RemedyPlanet>(
              'planet',
              RemedyPlanet.values,
              _planet,
              (value) => setState(() => _planet = value),
            ),
            const SizedBox(height: 12),
            _requiredField(_primaryGemstone, 'primaryGemstone'),
            const SizedBox(height: 12),
            _field(_substituteGemstone, 'substituteGemstone'),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weight,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _decoration('gemstoneWeight'),
                    validator: (value) {
                      final number = double.tryParse(value?.trim() ?? '');
                      if (number == null || number <= 0 || number > 100) {
                        return AppCopy.of(context, 'invalidGemstoneWeight');
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dropdown<GemstoneWeightUnit>(
                    'weightUnit',
                    GemstoneWeightUnit.values,
                    _weightUnit,
                    (value) => setState(() => _weightUnit = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field(_metal, 'metal'),
            const SizedBox(height: 12),
            _field(_finger, 'finger'),
            const SizedBox(height: 12),
            _field(_wearingDay, 'wearingDay'),
            const SizedBox(height: 12),
            _field(_instructions, 'wearingInstructions', maxLines: 3),
            const SizedBox(height: 12),
            _requiredField(
              _astrologicalReason,
              'astrologicalReason',
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _evidence,
              minLines: 3,
              maxLines: 5,
              decoration: _decoration('evidenceReferences').copyWith(
                helperText: AppCopy.of(context, 'evidenceHint'),
              ),
              validator: (value) {
                if (_decision == RemedyDecision.approved &&
                    _evidenceValues().isEmpty) {
                  return AppCopy.of(context, 'approvalRequiresEvidence');
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _requiredField(_cautions, 'cautions', maxLines: 3),
            const SizedBox(height: 12),
            _dropdown<RemedyDecision>(
              'remedyDecision',
              RemedyDecision.values,
              _decision,
              (value) => setState(() => _decision = value),
            ),
            if (_decision == RemedyDecision.approved &&
                !widget.verifiedOutputExists) ...[
              const SizedBox(height: 8),
              Text(
                AppCopy.of(context, 'approvalRequiresOutput'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(AppCopy.of(context, 'saveRemedy')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String key, {
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: _decoration(key),
      );

  Widget _requiredField(
    TextEditingController controller,
    String key, {
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: _decoration(key),
        validator: (value) => value == null || value.trim().isEmpty
            ? AppCopy.of(context, 'required')
            : null,
      );

  Widget _dropdown<T extends Enum>(
    String key,
    List<T> values,
    T selected,
    ValueChanged<T> onChanged,
  ) =>
      DropdownButtonFormField<T>(
        initialValue: selected,
        decoration: _decoration(key),
        items: values
            .map((value) => DropdownMenuItem(
                  value: value,
                  child: Text(AppCopy.of(context, value.name)),
                ))
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      );

  InputDecoration _decoration(String key) => InputDecoration(
        labelText: AppCopy.of(context, key),
        border: const OutlineInputBorder(),
      );

  List<String> _evidenceValues() => _evidence.text
      .split(RegExp(r'[,\n]'))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_decision == RemedyDecision.approved &&
        !widget.verifiedOutputExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'approvalRequiresOutput'))),
      );
      return;
    }
    setState(() => _saving = true);
    final existing = widget.existingRemedy;
    final now = DateTime.now();
    final remedy = GemstoneRemedy(
      id: existing?.id,
      consultationId: widget.consultation.id!,
      planet: _planet,
      primaryGemstone: _primaryGemstone.text,
      substituteGemstone: _substituteGemstone.text,
      weightValue: double.parse(_weight.text.trim()),
      weightUnit: _weightUnit,
      metal: _metal.text,
      finger: _finger.text,
      wearingDay: _wearingDay.text,
      instructions: _instructions.text,
      astrologicalReason: _astrologicalReason.text,
      evidenceReferences: _evidenceValues(),
      cautions: _cautions.text,
      decision: _decision,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      if (existing == null) {
        await widget.clientStore.addGemstoneRemedy(remedy);
      } else {
        await widget.clientStore.updateGemstoneRemedy(remedy);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'remedySaved'))),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'databaseError'))),
      );
    }
  }
}
