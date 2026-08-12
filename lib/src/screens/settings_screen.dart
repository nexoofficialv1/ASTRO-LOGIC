import 'package:flutter/material.dart';

import '../data/client_store.dart';
import '../localization/app_copy.dart';
import '../models/astrology_settings.dart';
import '../ephemeris/ephemeris_engine_policy.dart';
import 'backup_restore_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.clientStore, super.key});

  final ClientStore clientStore;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Ayanamsha _ayanamsha;
  late VedicChartStyle _chartStyle;
  late WesternHouseSystem _houseSystem;
  late LunarNodeMode _nodeMode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = widget.clientStore.settings;
    _ayanamsha = settings.ayanamsha;
    _chartStyle = settings.vedicChartStyle;
    _houseSystem = settings.westernHouseSystem;
    _nodeMode = settings.lunarNodeMode;
  }

  @override
  Widget build(BuildContext context) {
    final ephemerisPolicy = EphemerisEnginePolicy.configuredBuild();
    return Scaffold(
      appBar: AppBar(title: Text(AppCopy.of(context, 'settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(AppCopy.of(context, 'settingsNote')),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                ephemerisPolicy.isRuntimeConfigured
                    ? Icons.verified_outlined
                    : Icons.warning_amber_outlined,
              ),
              title: Text(AppCopy.of(context, 'ephemerisStatus')),
              subtitle: Text(AppCopy.of(
                context,
                switch (ephemerisPolicy.backend) {
                  OfflineEphemerisBackend.astronomyEngine =>
                    'ephemerisOpenEngine',
                  OfflineEphemerisBackend.unconfigured =>
                    'ephemerisNotConfigured',
                },
              )),
            ),
          ),
          const SizedBox(height: 16),
          _dropdown<Ayanamsha>('ayanamsha', Ayanamsha.values, _ayanamsha,
              (value) => setState(() => _ayanamsha = value)),
          const SizedBox(height: 12),
          _dropdown<VedicChartStyle>(
              'vedicChartStyle',
              VedicChartStyle.values,
              _chartStyle,
              (value) => setState(() => _chartStyle = value)),
          const SizedBox(height: 12),
          _dropdown<WesternHouseSystem>(
              'westernHouseSystem',
              WesternHouseSystem.values,
              _houseSystem,
              (value) => setState(() => _houseSystem = value)),
          const SizedBox(height: 12),
          _dropdown<LunarNodeMode>('lunarNodeMode', LunarNodeMode.values,
              _nodeMode, (value) => setState(() => _nodeMode = value)),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const Icon(Icons.enhanced_encryption_outlined),
              title: Text(AppCopy.of(context, 'backupRestore')),
              subtitle: Text(AppCopy.of(context, 'restoreEmptyWorkspaceOnly')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BackupRestoreScreen(
                    clientStore: widget.clientStore,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(AppCopy.of(context, 'saveSettings')),
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T extends Enum>(
    String labelKey,
    List<T> values,
    T selected,
    ValueChanged<T> onChanged,
  ) =>
      DropdownButtonFormField<T>(
        initialValue: selected,
        decoration: InputDecoration(
          labelText: AppCopy.of(context, labelKey),
          border: const OutlineInputBorder(),
        ),
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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.clientStore.updateSettings(AstrologySettings(
        ayanamsha: _ayanamsha,
        vedicChartStyle: _chartStyle,
        westernHouseSystem: _houseSystem,
        lunarNodeMode: _nodeMode,
      ));
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'updated'))),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'databaseError'))),
      );
    }
  }
}
