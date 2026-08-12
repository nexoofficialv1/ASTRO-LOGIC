import 'package:flutter/material.dart';

import '../data/client_store.dart';
import '../localization/app_copy.dart';
import '../models/birth_record.dart';

class BirthRecordFormScreen extends StatefulWidget {
  const BirthRecordFormScreen({
    required this.clientStore,
    required this.clientId,
    this.existingRecord,
    super.key,
  });

  final ClientStore clientStore;
  final int clientId;
  final BirthRecord? existingRecord;

  @override
  State<BirthRecordFormScreen> createState() => _BirthRecordFormScreenState();
}

class _BirthRecordFormScreenState extends State<BirthRecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _label = TextEditingController();
  final _place = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _source = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  int _offset = 330;
  BirthTimeConfidence _confidence = BirthTimeConfidence.recorded;
  bool _attempted = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingRecord;
    if (existing != null) {
      _label.text = existing.label;
      _place.text = existing.placeName;
      _latitude.text = existing.latitude.toString();
      _longitude.text = existing.longitude.toString();
      _source.text = existing.sourceNote;
      _date = DateTime(
        existing.localDateTime.year,
        existing.localDateTime.month,
        existing.localDateTime.day,
      );
      _time = TimeOfDay.fromDateTime(existing.localDateTime);
      _offset = existing.utcOffsetMinutes;
      _confidence = existing.confidence;
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _place.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppCopy.of(
          context,
          widget.existingRecord == null ? 'addBirthRecord' : 'editBirthRecord',
        )),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_label, 'birthLabel', isRequired: true),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _picker(
                  'birthDate',
                  _date == null ? null : _formatDate(_date!),
                  _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _picker('birthTime', _time?.format(context), _pickTime),
              ),
            ]),
            const SizedBox(height: 12),
            _field(_place, 'birthPlace', isRequired: true),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _coordinate(_latitude, 'latitude', -90, 90)),
              const SizedBox(width: 12),
              Expanded(child: _coordinate(_longitude, 'longitude', -180, 180)),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _offset,
              decoration: _decoration('utcOffset'),
              menuMaxHeight: 360,
              items: [
                for (var value = -720; value <= 840; value += 15)
                  DropdownMenuItem(value: value, child: Text(_formatOffset(value))),
              ],
              onChanged: (value) => setState(() => _offset = value!),
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
            _field(_source, 'sourceNote', maxLines: 2),
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

  Widget _field(
    TextEditingController controller,
    String key, {
    bool isRequired = false,
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: _decoration(key),
        validator: isRequired
            ? (value) => value == null || value.trim().isEmpty
                ? AppCopy.of(context, 'required')
                : null
            : null,
      );

  Widget _coordinate(
    TextEditingController controller,
    String key,
    double min,
    double max,
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
          if (number < min || number > max) {
            return AppCopy.of(
              context,
              key == 'latitude' ? 'invalidLatitude' : 'invalidLongitude',
            );
          }
          return null;
        },
      );

  Widget _picker(String key, String? value, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: _decoration(key).copyWith(
            errorText: _attempted && value == null
                ? AppCopy.of(context, 'required')
                : null,
            suffixIcon: const Icon(Icons.event),
          ),
          child: Text(value ?? '—'),
        ),
      );

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final value = await showDatePicker(
      context: context,
      firstDate: DateTime(1800),
      lastDate: now,
      initialDate: _date ?? DateTime(now.year - 30, now.month, now.day),
    );
    if (value != null) setState(() => _date = value);
  }

  Future<void> _pickTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (value != null) setState(() => _time = value);
  }

  Future<void> _save() async {
    setState(() => _attempted = true);
    if (!_formKey.currentState!.validate() || _date == null || _time == null) {
      return;
    }
    final local = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );
    if (local.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'futureDate'))),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final record = BirthRecord(
          id: widget.existingRecord?.id,
          clientId: widget.existingRecord == null ? null : widget.clientId,
          label: _label.text.trim(),
          localDateTime: local,
          utcOffsetMinutes: _offset,
          placeName: _place.text.trim(),
          latitude: double.parse(_latitude.text.trim()),
          longitude: double.parse(_longitude.text.trim()),
          confidence: _confidence,
          sourceNote: _source.text.trim(),
        );
      if (widget.existingRecord == null) {
        await widget.clientStore.addBirthRecord(widget.clientId, record);
      } else {
        await widget.clientStore.updateBirthRecord(record);
      }
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

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _formatOffset(int minutes) {
    final sign = minutes >= 0 ? '+' : '-';
    final absolute = minutes.abs();
    return 'UTC$sign${(absolute ~/ 60).toString().padLeft(2, '0')}:'
        '${(absolute % 60).toString().padLeft(2, '0')}';
  }
}
