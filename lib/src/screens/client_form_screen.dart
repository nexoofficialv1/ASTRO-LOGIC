import 'package:flutter/material.dart';

import '../data/client_store.dart';
import '../localization/app_copy.dart';
import '../models/birth_record.dart';
import '../models/client.dart';

class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({required this.clientStore, super.key});

  final ClientStore clientStore;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _notes = TextEditingController();
  final _birthLabel = TextEditingController();
  final _place = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _sourceNote = TextEditingController();

  ClientGender _gender = ClientGender.male;
  BirthTimeConfidence _confidence = BirthTimeConfidence.recorded;
  DateTime? _birthDate;
  TimeOfDay? _birthTime;
  int _utcOffsetMinutes = 330;
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _mobile,
      _email,
      _notes,
      _birthLabel,
      _place,
      _latitude,
      _longitude,
      _sourceNote,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppCopy.of(context, 'addClient'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            _SectionTitle(AppCopy.of(context, 'clientDetails')),
            _requiredField(_name, 'fullName'),
            const SizedBox(height: 12),
            _textField(_mobile, 'mobile', keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _textField(_email, 'email', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            DropdownButtonFormField<ClientGender>(
              initialValue: _gender,
              decoration: _decoration('gender'),
              items: ClientGender.values
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(AppCopy.of(context, value.name)),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _gender = value!),
            ),
            const SizedBox(height: 12),
            _textField(_notes, 'notes', maxLines: 3),
            const SizedBox(height: 28),
            _SectionTitle(AppCopy.of(context, 'birthDetails')),
            TextFormField(
              controller: _birthLabel,
              decoration: _decoration('birthLabel').copyWith(
                hintText: AppCopy.of(context, 'birthRecord'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PickerField(
                    label: AppCopy.of(context, 'birthDate'),
                    value: _birthDate == null ? null : _formatDate(_birthDate!),
                    onTap: _pickDate,
                    errorText: _birthDate == null && _attempted
                        ? AppCopy.of(context, 'required')
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerField(
                    label: AppCopy.of(context, 'birthTime'),
                    value: _birthTime?.format(context),
                    onTap: _pickTime,
                    errorText: _birthTime == null && _attempted
                        ? AppCopy.of(context, 'required')
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _requiredField(_place, 'birthPlace'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _coordinateField(_latitude, 'latitude', -90, 90)),
                const SizedBox(width: 12),
                Expanded(
                    child: _coordinateField(_longitude, 'longitude', -180, 180)),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _utcOffsetMinutes,
              decoration: _decoration('utcOffset'),
              menuMaxHeight: 360,
              items: [
                for (var minutes = -720; minutes <= 840; minutes += 15)
                  DropdownMenuItem(
                    value: minutes,
                    child: Text(_formatOffset(minutes)),
                  ),
              ],
              onChanged: (value) => setState(() => _utcOffsetMinutes = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BirthTimeConfidence>(
              initialValue: _confidence,
              decoration: _decoration('timeConfidence'),
              items: BirthTimeConfidence.values
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(AppCopy.of(context, value.name)),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _confidence = value!),
            ),
            const SizedBox(height: 12),
            _textField(_sourceNote, 'sourceNote', maxLines: 2),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(AppCopy.of(context, 'save')),
            ),
          ],
        ),
      ),
    );
  }

  bool _attempted = false;

  InputDecoration _decoration(String key) => InputDecoration(
        labelText: AppCopy.of(context, key),
        border: const OutlineInputBorder(),
      );

  Widget _textField(
    TextEditingController controller,
    String key, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: _decoration(key),
      );

  Widget _requiredField(TextEditingController controller, String key) =>
      TextFormField(
        controller: controller,
        decoration: _decoration(key),
        validator: (value) => value == null || value.trim().isEmpty
            ? AppCopy.of(context, 'required')
            : null,
      );

  Widget _coordinateField(
    TextEditingController controller,
    String key,
    double minimum,
    double maximum,
  ) =>
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        decoration: _decoration(key),
        validator: (value) {
          final number = double.tryParse(value?.trim() ?? '');
          if (number == null) return AppCopy.of(context, 'invalidNumber');
          if (number < minimum || number > maximum) {
            return AppCopy.of(
              context,
              key == 'latitude' ? 'invalidLatitude' : 'invalidLongitude',
            );
          }
          return null;
        },
      );

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(1800),
      lastDate: now,
      initialDate: _birthDate ?? DateTime(now.year - 30, now.month, now.day),
    );
    if (selected != null) setState(() => _birthDate = selected);
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _birthTime ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (selected != null) setState(() => _birthTime = selected);
  }

  Future<void> _save() async {
    setState(() => _attempted = true);
    if (!_formKey.currentState!.validate() ||
        _birthDate == null ||
        _birthTime == null) {
      return;
    }

    final localDateTime = DateTime(
      _birthDate!.year,
      _birthDate!.month,
      _birthDate!.day,
      _birthTime!.hour,
      _birthTime!.minute,
    );
    if (localDateTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'futureDate'))),
      );
      return;
    }

    setState(() => _saving = true);
    final client = Client(
      fullName: _name.text.trim(),
      mobile: _mobile.text.trim(),
      email: _email.text.trim(),
      gender: _gender,
      notes: _notes.text.trim(),
      createdAt: DateTime.now(),
      birthRecords: [
        BirthRecord(
          label: _birthLabel.text.trim().isEmpty
              ? AppCopy.of(context, 'birthRecord')
              : _birthLabel.text.trim(),
          localDateTime: localDateTime,
          utcOffsetMinutes: _utcOffsetMinutes,
          placeName: _place.text.trim(),
          latitude: double.parse(_latitude.text.trim()),
          longitude: double.parse(_longitude.text.trim()),
          confidence: _confidence,
          sourceNote: _sourceNote.text.trim(),
        ),
      ],
    );

    try {
      await widget.clientStore.addClient(client);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'saved'))),
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

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatOffset(int minutes) {
    final sign = minutes >= 0 ? '+' : '-';
    final absolute = minutes.abs();
    final hours = (absolute ~/ 60).toString().padLeft(2, '0');
    final mins = (absolute % 60).toString().padLeft(2, '0');
    return 'UTC$sign$hours:$mins';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(text, style: Theme.of(context).textTheme.titleLarge),
      );
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.errorText,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            errorText: errorText,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.event),
          ),
          child: Text(value ?? '—'),
        ),
      );
}
