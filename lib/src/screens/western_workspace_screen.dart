import 'package:flutter/material.dart';

import '../data/client_store.dart';
import '../localization/app_copy.dart';
import '../models/astrology_settings.dart';
import '../western/western_chart_engine.dart';
import '../western/western_governance.dart';
import '../western/western_native_ffi_bridge.dart';

class WesternWorkspaceScreen extends StatefulWidget {
  const WesternWorkspaceScreen({required this.clientStore, super.key});

  final ClientStore clientStore;

  @override
  State<WesternWorkspaceScreen> createState() => _WesternWorkspaceScreenState();
}

class _WesternWorkspaceScreenState extends State<WesternWorkspaceScreen> {
  late final TextEditingController _utcController;
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  late WesternHouseSystem _houseSystem;
  late LunarNodeMode _nodeMode;
  WesternRulershipProfile _rulershipProfile = WesternRulershipProfile.traditional;
  WesternAspectProfile _aspectProfile = WesternAspectProfile.majorOnly;
  WesternNatalChart? _chart;
  bool _running = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _utcController = TextEditingController(
      text: DateTime.now().toUtc().toIso8601String(),
    );
    _houseSystem = widget.clientStore.settings.westernHouseSystem;
    _nodeMode = widget.clientStore.settings.lunarNodeMode;
  }

  @override
  void dispose() {
    _utcController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = (String key) => AppCopy.of(context, key);
    final bengali = Localizations.localeOf(context).languageCode == 'bn';
    return Scaffold(
      appBar: AppBar(title: Text(copy('westernWorkspace'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy('westernFoundationTitle'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bengali
                        ? WesternGovernance.bengaliDisclosure
                        : WesternGovernance.englishDisclosure,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${WesternChartEngine.engineVersion} • '
                    '${WesternGovernance.profileVersion}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _utcController,
            decoration: InputDecoration(
              labelText: copy('westernUtcDateTime'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: copy('westernLatitude'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _longitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: copy('westernLongitude'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<WesternHouseSystem>(
            initialValue: _houseSystem,
            decoration: InputDecoration(
              labelText: copy('westernHouseSystemLabel'),
              border: const OutlineInputBorder(),
            ),
            items: WesternHouseSystem.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(copy(value.name)),
                  ),
                )
                .toList(growable: false),
            onChanged: _running
                ? null
                : (value) => setState(() {
                      _houseSystem = value ?? _houseSystem;
                      _chart = null;
                    }),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<LunarNodeMode>(
            initialValue: _nodeMode,
            decoration: InputDecoration(
              labelText: copy('westernNodeModeLabel'),
              border: const OutlineInputBorder(),
            ),
            items: LunarNodeMode.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(copy(value.name)),
                  ),
                )
                .toList(growable: false),
            onChanged: _running
                ? null
                : (value) => setState(() {
                      _nodeMode = value ?? _nodeMode;
                      _chart = null;
                    }),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<WesternRulershipProfile>(
            initialValue: _rulershipProfile,
            decoration: InputDecoration(
              labelText: copy('westernRulershipProfileLabel'),
              border: const OutlineInputBorder(),
            ),
            items: WesternRulershipProfile.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(copy('westernRulership_${value.name}')),
                  ),
                )
                .toList(growable: false),
            onChanged: _running
                ? null
                : (value) => setState(() {
                      _rulershipProfile = value ?? _rulershipProfile;
                      _chart = null;
                    }),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<WesternAspectProfile>(
            initialValue: _aspectProfile,
            decoration: InputDecoration(
              labelText: copy('westernAspectProfileLabel'),
              border: const OutlineInputBorder(),
            ),
            items: WesternAspectProfile.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(copy('westernAspectProfile_${value.name}')),
                  ),
                )
                .toList(growable: false),
            onChanged: _running
                ? null
                : (value) => setState(() {
                      _aspectProfile = value ?? _aspectProfile;
                      _chart = null;
                    }),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _running ? null : _cast,
            icon: _running
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.public_outlined),
            label: Text(
              copy(_running ? 'westernChartRunning' : 'westernCastChart'),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (_chart != null) ...[
            const SizedBox(height: 16),
            _chartCard(context, _chart!),
          ],
        ],
      ),
    );
  }

  Widget _chartCard(BuildContext context, WesternNatalChart chart) {
    final copy = (String key) => AppCopy.of(context, key);
    final modernPoints = chart.points
        .where((point) => WesternChartEngine.modernBodies.contains(point.body))
        .toList(growable: false);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy('westernAscMc'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'ASC ${chart.ascendantLongitude.toStringAsFixed(6)}° • '
              'MC ${chart.mcLongitude.toStringAsFixed(6)}° • '
              '${copy(chart.input.houseSystem.name)}',
            ),
            const SizedBox(height: 4),
            Text(
              '${copy('westernRulershipProfileLabel')}: '
              '${copy('westernRulership_${chart.input.rulershipProfile.name}')} • '
              '${copy('westernAspectProfileLabel')}: '
              '${copy('westernAspectProfile_${chart.input.aspectProfile.name}')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 24),
            Text(
              copy('westernPlanetsHouses'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            ...chart.points.map(
              (point) => Text(
                '${copy(point.body.name)}: '
                '${point.longitude.toStringAsFixed(6)}° • '
                '${point.signName} • H${point.house}',
              ),
            ),
            const Divider(height: 24),
            Text(
              copy('westernModernPlanets'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            if (modernPoints.isEmpty) Text(copy('westernModernPlanetsDisabled')),
            if (modernPoints.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(copy('westernPlanetColumn'))),
                    DataColumn(label: Text(copy('westernLongitudeColumn'))),
                    DataColumn(label: Text(copy('westernLatitudeColumn'))),
                    DataColumn(label: Text(copy('westernHouseColumn'))),
                  ],
                  rows: modernPoints
                      .map(
                        (point) => DataRow(
                          cells: [
                            DataCell(Text(copy(point.body.name))),
                            DataCell(Text('${point.longitude.toStringAsFixed(6)}°')),
                            DataCell(
                              Text('${point.eclipticLatitude.toStringAsFixed(6)}°'),
                            ),
                            DataCell(Text('H${point.house}')),
                          ],
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            const Divider(height: 24),
            Text(
              copy('westernAspects'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            if (chart.aspects.isEmpty) Text(copy('westernNoAspects')),
            if (chart.aspects.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(copy('westernAspectPairColumn'))),
                    DataColumn(label: Text(copy('westernAspectColumn'))),
                    DataColumn(label: Text(copy('westernOrbColumn'))),
                    DataColumn(label: Text(copy('westernMotionColumn'))),
                  ],
                  rows: chart.aspects
                      .map(
                        (aspect) => DataRow(
                          cells: [
                            DataCell(
                              Text(
                                '${copy(aspect.first.name)} – '
                                '${copy(aspect.second.name)}',
                              ),
                            ),
                            DataCell(Text(copy(aspect.aspect.name))),
                            DataCell(
                              Text(
                                '${aspect.orb.toStringAsFixed(3)}° / '
                                '${aspect.orbLimit.toStringAsFixed(1)}°',
                              ),
                            ),
                            DataCell(Text(copy(aspect.motion.name))),
                          ],
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            const SizedBox(height: 8),
            Text(copy('westernAspectOrbNote')),
            const Divider(height: 24),
            Text(
              copy('westernAspectPatterns'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            if (chart.patterns.isEmpty) Text(copy('westernNoAspectPatterns')),
            ...chart.patterns.map(
              (pattern) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${copy(pattern.type.name)}: '
                  '${pattern.planets.map((body) => copy(body.name)).join(', ')}\n'
                  '${pattern.componentAspects.map((aspect) => '${copy(aspect.aspect.name)} ${aspect.orb.toStringAsFixed(3)}°').join(' • ')}',
                ),
              ),
            ),
            Text(copy('westernPatternEvidenceNote')),
            const Divider(height: 24),
            Text(
              copy('westernRulerships'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            ...chart.rulerships.map(
              (rulership) => Text(
                '${rulership.signName}: ${copy(rulership.ruler)}',
              ),
            ),
            const Divider(height: 24),
            Text(
              copy('westernDignities'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            ...chart.dignities.map(
              (dignity) => Text(
                '${copy(dignity.body.name)} • ${dignity.signName}: '
                '${dignity.conditions.isEmpty ? copy('westernNoDignity') : dignity.conditions.map((condition) => copy(condition.name)).join(', ')}',
              ),
            ),
            const SizedBox(height: 8),
            Text(copy('westernDignitySeparationNote')),
            const Divider(height: 24),
            Text(copy('westernScopeNote')),
            const SizedBox(height: 6),
            Text(copy('westernPlacidusNoFallback')),
          ],
        ),
      ),
    );
  }

  Future<void> _cast() async {
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      final utc = DateTime.parse(_utcController.text.trim()).toUtc();
      final latitude = double.parse(_latitudeController.text.trim());
      final longitude = double.parse(_longitudeController.text.trim());
      final chart = await WesternChartEngine(WesternNativeFfiBridge.open()).cast(
        WesternChartInput(
          utc: utc,
          latitude: latitude,
          longitude: longitude,
          houseSystem: _houseSystem,
          nodeMode: _nodeMode,
          rulershipProfile: _rulershipProfile,
          aspectProfile: _aspectProfile,
          includeModernPlanets: true,
        ),
      );
      if (!mounted) return;
      setState(() => _chart = chart);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = '${AppCopy.of(context, 'westernChartFailed')}\n$error',
      );
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }
}
