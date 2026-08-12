import 'package:flutter/material.dart';

import '../data/client_store.dart';
import '../localization/app_copy.dart';
import '../models/client.dart';
import '../models/consultation.dart';

class ConsultationFormScreen extends StatefulWidget {
  const ConsultationFormScreen({
    required this.clientStore,
    required this.client,
    this.existingConsultation,
    super.key,
  });

  final ClientStore clientStore;
  final Client client;
  final Consultation? existingConsultation;

  @override
  State<ConsultationFormScreen> createState() => _ConsultationFormScreenState();
}

class _ConsultationFormScreenState extends State<ConsultationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _notes = TextEditingController();
  late int _birthRecordId;
  ConsultationCategory _category = ConsultationCategory.general;
  final Set<AstrologySystem> _systems = {AstrologySystem.vedic};
  bool _attempted = false;
  bool _saving = false;

  bool get _calculationLocked {
    final id = widget.existingConsultation?.id;
    return id != null && widget.clientStore.outputsForConsultation(id).isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existingConsultation;
    _birthRecordId =
        existing?.birthRecordId ?? widget.client.birthRecords.first.id!;
    if (existing != null) {
      _subject.text = existing.subject;
      _notes.text = existing.notes;
      _category = existing.category;
      _systems
        ..clear()
        ..addAll(existing.systems);
    }
  }

  @override
  void dispose() {
    _subject.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppCopy.of(
          context,
          widget.existingConsultation == null
              ? 'newConsultation'
              : 'editConsultation',
        )),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _subject,
              maxLines: 2,
              decoration: _decoration('consultationSubject'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? AppCopy.of(context, 'required')
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _birthRecordId,
              decoration: _decoration('selectBirthRecord'),
              items: widget.client.birthRecords
                  .map((record) => DropdownMenuItem(
                        value: record.id!,
                        child: Text('${record.label} — ${record.placeName}'),
                      ))
                  .toList(),
              onChanged: _calculationLocked
                  ? null
                  : (value) => setState(() => _birthRecordId = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ConsultationCategory>(
              initialValue: _category,
              decoration: _decoration('consultationCategory'),
              items: ConsultationCategory.values
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(AppCopy.of(context, value.name)),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 22),
            Text(
              AppCopy.of(context, 'selectSystems'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_calculationLocked) ...[
              Text(AppCopy.of(context, 'calculatedFieldsLocked')),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AstrologySystem.values
                  .map((system) => FilterChip(
                        label: Text(AppCopy.of(context, system.name)),
                        selected: _systems.contains(system),
                        onSelected: _calculationLocked
                            ? null
                            : (selected) => setState(() {
                                  if (selected) {
                                    _systems.add(system);
                                  } else {
                                    _systems.remove(system);
                                  }
                                }),
                      ))
                  .toList(),
            ),
            if (_attempted && _systems.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                AppCopy.of(context, 'selectAtLeastOne'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 22),
            TextFormField(
              controller: _notes,
              maxLines: 5,
              decoration: _decoration('notes'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(AppCopy.of(context, 'save')),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String key) => InputDecoration(
        labelText: AppCopy.of(context, key),
        border: const OutlineInputBorder(),
      );

  Future<void> _save() async {
    setState(() => _attempted = true);
    if (!_formKey.currentState!.validate() || _systems.isEmpty) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    try {
      final existing = widget.existingConsultation;
      final consultation = Consultation(
        id: existing?.id,
        clientId: widget.client.id!,
        birthRecordId: _birthRecordId,
        subject: _subject.text.trim(),
        category: _category,
        systems: _systems.toList(growable: false),
        status: existing?.status ?? ConsultationStatus.draft,
        notes: _notes.text.trim(),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      if (existing == null) {
        await widget.clientStore.addConsultation(consultation);
      } else {
        await widget.clientStore.updateConsultation(consultation);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppCopy.of(
            context,
            existing == null ? 'consultationCreated' : 'consultationUpdated',
          )),
        ),
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
