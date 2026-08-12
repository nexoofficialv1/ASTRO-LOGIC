import 'package:flutter/material.dart';

import '../data/client_store.dart';
import '../localization/app_copy.dart';
import '../models/client.dart';

class ClientEditScreen extends StatefulWidget {
  const ClientEditScreen({
    required this.clientStore,
    required this.client,
    super.key,
  });

  final ClientStore clientStore;
  final Client client;

  @override
  State<ClientEditScreen> createState() => _ClientEditScreenState();
}

class _ClientEditScreenState extends State<ClientEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late final TextEditingController _notes;
  late ClientGender _gender;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.client.fullName);
    _mobile = TextEditingController(text: widget.client.mobile);
    _email = TextEditingController(text: widget.client.email);
    _notes = TextEditingController(text: widget.client.notes);
    _gender = widget.client.gender;
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppCopy.of(context, 'edit'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: _decoration('fullName'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? AppCopy.of(context, 'required')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mobile,
              keyboardType: TextInputType.phone,
              decoration: _decoration('mobile'),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _email, decoration: _decoration('email')),
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
            TextFormField(
              controller: _notes,
              maxLines: 4,
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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.clientStore.updateClient(Client(
        id: widget.client.id,
        fullName: _name.text.trim(),
        mobile: _mobile.text.trim(),
        email: _email.text.trim(),
        gender: _gender,
        notes: _notes.text.trim(),
        createdAt: widget.client.createdAt,
        birthRecords: widget.client.birthRecords,
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'updated'))),
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

