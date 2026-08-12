import 'package:flutter/material.dart';

import '../kp/kp_foundation_engine.dart';
import '../kp/kp_horary_engine.dart';
import '../kp/kp_dasha_timing_engine.dart';
import '../kp/kp_governance.dart';
import '../kp/kp_event_judgment_engine.dart';
import '../kp/kp_native_chart_engine.dart';
import '../kp/kp_native_ffi_bridge.dart';
import '../kp/kp_timing_confirmation_engine.dart';
import '../models/astrology_settings.dart';
import '../data/client_store.dart';
import '../localization/app_copy.dart';

class KpWorkspaceScreen extends StatefulWidget {
  const KpWorkspaceScreen({required this.clientStore, super.key});

  final ClientStore clientStore;

  @override
  State<KpWorkspaceScreen> createState() => _KpWorkspaceScreenState();
}

class _KpWorkspaceScreenState extends State<KpWorkspaceScreen> {
  final _pointController = TextEditingController();
  final _moonController = TextEditingController();
  final _ascController = TextEditingController();
  final _cuspsController = TextEditingController();
  final _utcController = TextEditingController(
    text: DateTime.now().toUtc().toIso8601String(),
  );
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _horaryNumberController = TextEditingController();
  final _horaryQuestionController = TextEditingController();
  int _weekday = DateTime.monday;
  KpPointClassification? _point;
  KpRulingPlanetPanel? _rulingPlanets;
  List<KpCuspClassification>? _cusps;
  KpNativeChart? _nativeChart;
  KpEventTopic _eventTopic = KpEventTopic.marriage;
  KpEventJudgment? _eventJudgment;
  KpDashaTimingSynthesis? _timingSynthesis;
  KpTimingConfirmationSynthesis? _timingConfirmation;
  KpHoraryChart? _horaryChart;
  int? _horarySnapshotId;
  int _horaryTopicIndex = 0;
  bool _horaryRunning = false;
  bool _nativeRunning = false;
  String? _error;

  @override
  void dispose() {
    _pointController.dispose();
    _moonController.dispose();
    _ascController.dispose();
    _cuspsController.dispose();
    _utcController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _horaryNumberController.dispose();
    _horaryQuestionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = (String key) => AppCopy.of(context, key);
    final bengali = Localizations.localeOf(context).languageCode == 'bn';
    return Scaffold(
      appBar: AppBar(title: Text(copy('kpWorkspace'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(copy('kpFoundationTitle'),
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(bengali
                      ? KpGovernance.bengaliDisclosure
                      : KpGovernance.englishDisclosure),
                  const SizedBox(height: 10),
                  Text(
                    '${KpFoundationEngine.ruleVersion} • ${KpFoundationEngine.engineVersion}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(copy('kpNativeCasting'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _utcController,
            decoration: InputDecoration(
              labelText: copy('kpUtcDateTime'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latitudeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: InputDecoration(
                    labelText: copy('kpLatitude'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _longitudeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: InputDecoration(
                    labelText: copy('kpLongitude'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _nativeRunning ? null : _castNativeChart,
            icon: _nativeRunning
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.hub_outlined),
            label: Text(copy('kpCastNativeChart')),
          ),
          if (_nativeChart != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${copy('kpAyanamsha')}: '
                      '${_nativeChart!.krishnamurtiAyanamsha.toStringAsFixed(8)}°',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ASC ${_nativeChart!.ascendant.siderealLongitude.toStringAsFixed(6)}° '
                      '• MC ${_nativeChart!.mc.siderealLongitude.toStringAsFixed(6)}°',
                    ),
                    const Divider(height: 20),
                    ..._nativeChart!.planets.map(
                      (planet) {
                        final house = _nativeChart!.houseEvidence
                            .planet(planet.name)
                            .occupiedHouse;
                        return Text(
                          '${planet.name.toUpperCase()}: '
                          '${planet.siderealLongitude.toStringAsFixed(6)}° • '
                          'H$house • ${planet.classification.nakshatra} • '
                          'Sub ${planet.classification.subLord.toUpperCase()}',
                        );
                      },
                    ),
                    const Divider(height: 20),
                    Text(copy('kpAdvancedSignificators'),
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    ..._nativeChart!.houseEvidence.planets.values.map(
                      (evidence) => Text(
                        '${evidence.planet.toUpperCase()}: '
                        '${evidence.significator.combinedHouses.join('/')}',
                      ),
                    ),
                    const Divider(height: 20),
                    DropdownButtonFormField<KpEventTopic>(
                      value: _eventTopic,
                      decoration: InputDecoration(
                        labelText: copy('kpEventReviewTopic'),
                        border: const OutlineInputBorder(),
                      ),
                      items: KpEventTopic.values
                          .map((topic) => DropdownMenuItem<KpEventTopic>(
                                value: topic,
                                child: Text(copy(
                                  topic == KpEventTopic.marriage
                                      ? 'kpEventMarriage'
                                      : 'kpEventChildren',
                                )),
                              ))
                          .toList(growable: false),
                      onChanged: (value) => setState(() {
                        _eventTopic = value ?? KpEventTopic.marriage;
                        _eventJudgment = null;
                        _timingSynthesis = null;
                        _timingConfirmation = null;
                      }),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _nativeRunning ? null : () => _reviewNativeEvent(),
                      icon: const Icon(Icons.fact_check_outlined),
                      label: Text(copy('kpReviewEventEvidence')),
                    ),
                    if (_eventJudgment != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${copy('kpEventState')}: ${_eventJudgment!.state.name}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        bengali
                            ? _eventJudgment!.narrativeBn
                            : _eventJudgment!.narrativeEn,
                      ),
                    ],
                    if (_timingSynthesis != null) ...[
                      const Divider(height: 20),
                      Text(
                        copy('kpDashaTiming'),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${copy('kpTimingGate')}: '
                        '${_timingSynthesis!.gateState.name}',
                      ),
                      Text(
                        bengali
                            ? _timingSynthesis!.narrativeBn
                            : _timingSynthesis!.narrativeEn,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${copy('kpSupportiveWindows')}: '
                        '${_timingSynthesis!.supportiveWindowCount} • '
                        '${copy('kpConflictingWindows')}: '
                        '${_timingSynthesis!.conflictingWindowCount}',
                      ),
                      if (_timingSynthesis!.activeWindow != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${copy('kpCurrentDba')}: '
                          '${_timingSynthesis!.activeWindow!.dashaLord.toUpperCase()} / '
                          '${_timingSynthesis!.activeWindow!.bhuktiLord.toUpperCase()} / '
                          '${_timingSynthesis!.activeWindow!.antaraLord.toUpperCase()} '
                          '(${_timingSynthesis!.activeWindow!.state.name})',
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(copy('kpNextSupportiveWindows')),
                      ..._timingSynthesis!.nextSupportiveWindows(limit: 3).map(
                        (window) => Text(
                          '${window.dashaLord.toUpperCase()} / '
                          '${window.bhuktiLord.toUpperCase()} / '
                          '${window.antaraLord.toUpperCase()} • '
                          '${window.startUtc.toIso8601String().split('T').first} → '
                          '${window.endUtc.toIso8601String().split('T').first}',
                        ),
                      ),
                      if (_timingSynthesis!.nextSupportiveWindows(limit: 1).isEmpty)
                        Text(copy('kpNoSupportiveTiming')),
                      const SizedBox(height: 6),
                      Text(copy('kpTimingSeparationNote')),
                    ],
                    if (_timingConfirmation != null) ...[
                      const Divider(height: 20),
                      Text(
                        copy('kpTimingConfirmation'),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${copy('kpConfirmationState')}: '
                        '${_timingConfirmation!.state.name}',
                      ),
                      Text(
                        '${copy('kpConfidenceCeiling')}: '
                        '${_timingConfirmation!.confidenceCeiling.name}',
                      ),
                      Text(
                        '${copy('kpRpOverlap')}: '
                        '${_timingConfirmation!.fruitfulRulingPlanetOverlapCount}',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bengali
                            ? _timingConfirmation!.narrativeBn
                            : _timingConfirmation!.narrativeEn,
                      ),
                      const SizedBox(height: 8),
                      ..._timingConfirmation!.dbaTransitEvidence.map(
                        (evidence) => Text(
                          '${evidence.role.toUpperCase()}: '
                          '${evidence.transitPlanet.toUpperCase()} → '
                          'Star ${evidence.transitStarLord.toUpperCase()} '
                          '(${evidence.starLordNatalState.name})',
                        ),
                      ),
                      ..._timingConfirmation!.luminaryTransitEvidence.map(
                        (evidence) => Text(
                          '${evidence.role.toUpperCase()}: '
                          'Star ${evidence.transitStarLord.toUpperCase()} '
                          '(${evidence.starLordNatalState.name})',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(copy('kpConfirmationSafetyNote')),
                    ],
                    const Divider(height: 20),
                    Text(copy('kpPlacidusNoFallback')),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(copy('kpHoraryTitle'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(copy('kpHoraryIntro')),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _horaryNumberController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: copy('kpHoraryNumber'),
                            helperText: '1–249',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _horaryTopicIndex,
                          decoration: InputDecoration(
                            labelText: copy('kpHoraryTopic'),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 0,
                              child: Text(copy('kpHoraryGeneral')),
                            ),
                            DropdownMenuItem(
                              value: 1,
                              child: Text(copy('kpEventMarriage')),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text(copy('kpEventChildren')),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _horaryTopicIndex = value ?? 0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _horaryQuestionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: copy('kpHoraryQuestion'),
                      helperText: copy('kpHoraryQuestionHelper'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(copy('kpHoraryMomentLocationNote')),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _horaryRunning ? null : _castAndSaveHorary,
                    icon: _horaryRunning
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.question_answer_outlined),
                    label: Text(copy('kpHoraryCastSave')),
                  ),
                  if (_horaryChart != null) ...[
                    const Divider(height: 24),
                    Text(
                      '#${_horaryChart!.segment.number} • '
                      '${_horaryChart!.segment.sign} • '
                      '${_horaryChart!.segment.startLongitude.toStringAsFixed(6)}° → '
                      '${_horaryChart!.segment.endLongitude.toStringAsFixed(6)}°',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      'Star ${_horaryChart!.segment.starLord.toUpperCase()} • '
                      'Sub ${_horaryChart!.segment.subLord.toUpperCase()}',
                    ),
                    Text(
                      '${copy('kpHoraryAscendant')}: '
                      '${_horaryChart!.horaryAscendant.siderealLongitude.toStringAsFixed(6)}° • '
                      '${copy('kpHoraryCuspError')}: '
                      '${_horaryChart!.cuspSolutionErrorArcSeconds.toStringAsFixed(3)}″',
                    ),
                    const SizedBox(height: 8),
                    ..._horaryChart!.horaryCusps.map(
                      (cusp) => Text(
                        'H${cusp.house}: '
                        '${cusp.siderealLongitude.toStringAsFixed(6)}° • '
                        '${cusp.classification.nakshatra} • '
                        'Sub ${cusp.classification.subLord.toUpperCase()}',
                      ),
                    ),
                    if (_horaryChart!.eventJudgment != null) ...[
                      const Divider(height: 20),
                      Text(
                        '${copy('kpHoraryCuspEvidence')}: '
                        '${_horaryChart!.eventJudgment!.state.name}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        bengali
                            ? _horaryChart!.eventJudgment!.narrativeBn
                            : _horaryChart!.eventJudgment!.narrativeEn,
                      ),
                      if (_horaryChart!.timingConfirmation != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          copy('kpHoraryRpTiming'),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${copy('kpHoraryRpState')}: '
                          '${_horaryChart!.timingConfirmation!.state.name} • '
                          '${copy('kpHoraryConfidence')}: '
                          '${_horaryChart!.timingConfirmation!.confidenceCeiling.name}',
                        ),
                        Text(
                          '${copy('kpHoraryPrimaryRpOverlap')}: '
                          '${_horaryChart!.timingConfirmation!.primaryCuspSubLordRpOverlap ? copy('kpHoraryYes') : copy('kpHoraryNo')}',
                        ),
                        Text(
                          '${copy('kpHoraryFruitfulRp')}: '
                          '${_horaryChart!.timingConfirmation!.fruitfulStandardPlanets.isEmpty ? '-' : _horaryChart!.timingConfirmation!.fruitfulStandardPlanets.join(', ')}',
                        ),
                        if (_horaryChart!.timingConfirmation!.mixedStandardPlanets.isNotEmpty)
                          Text(
                            '${copy('kpHoraryMixedRp')}: '
                            '${_horaryChart!.timingConfirmation!.mixedStandardPlanets.join(', ')}',
                          ),
                        if (_horaryChart!.timingConfirmation!.detrimentalStandardPlanets.isNotEmpty)
                          Text(
                            '${copy('kpHoraryDetrimentalRp')}: '
                            '${_horaryChart!.timingConfirmation!.detrimentalStandardPlanets.join(', ')}',
                          ),
                        Text(
                          bengali
                              ? _horaryChart!.timingConfirmation!.narrativeBn
                              : _horaryChart!.timingConfirmation!.narrativeEn,
                        ),
                        const SizedBox(height: 4),
                        Text(copy('kpHoraryRpSafety')),
                      ],
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(copy('kpHoraryGeneralNoAutoJudgment')),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${copy('kpHorarySnapshot')}: '
                      '${_horarySnapshotId ?? '-'} • '
                      '${copy('kpHorarySavedTotal')}: '
                      '${widget.clientStore.kpHorarySnapshots.length}',
                    ),
                    const SizedBox(height: 6),
                    Text(copy('kpHorarySafetyNote')),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(copy('kpPointClassifier'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _pointController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: copy('kpSiderealLongitude'),
              helperText: copy('kpLongitudeHelper'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _classifyPoint,
            child: Text(copy('kpClassifyPoint')),
          ),
          if (_point != null) ...[
            const SizedBox(height: 12),
            _PointCard(point: _point!),
          ],
          const SizedBox(height: 22),
          Text(copy('kpRulingPlanets'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _ascController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: copy('kpAscendantLongitude'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _moonController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: copy('kpMoonLongitude'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: _weekday,
            decoration: InputDecoration(
              labelText: copy('kpWeekday'),
              border: const OutlineInputBorder(),
            ),
            items: List<DropdownMenuItem<int>>.generate(
              7,
              (index) => DropdownMenuItem<int>(
                value: index + 1,
                child: Text(copy('weekday${index + 1}')),
              ),
            ),
            onChanged: (value) => setState(() => _weekday = value ?? 1),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _buildRulingPlanets,
            child: Text(copy('kpBuildRulingPlanets')),
          ),
          if (_rulingPlanets != null) ...[
            const SizedBox(height: 12),
            _RulingPlanetCard(panel: _rulingPlanets!),
          ],
          const SizedBox(height: 22),
          Text(copy('kpCuspFramework'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _cuspsController,
            minLines: 5,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: copy('kpCuspLongitudes'),
              helperText: copy('kpCuspHelper'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _classifyCusps,
            child: Text(copy('kpClassifyCusps')),
          ),
          if (_cusps != null) ...[
            const SizedBox(height: 12),
            ..._cusps!.map(
              (cusp) => ListTile(
                dense: true,
                leading: CircleAvatar(child: Text('${cusp.house}')),
                title: Text(
                  '${cusp.point.sign} • ${cusp.point.nakshatra}',
                ),
                subtitle: Text(
                  'Star: ${cusp.point.starLord.toUpperCase()}  •  Sub: ${cusp.point.subLord.toUpperCase()}',
                ),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(copy('kpSourceSafetyNote')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _castNativeChart() async {
    setState(() {
      _nativeRunning = true;
      _error = null;
    });
    try {
      final utc = DateTime.parse(_utcController.text.trim()).toUtc();
      final latitude = double.parse(_latitudeController.text.trim());
      final longitude = double.parse(_longitudeController.text.trim());
      final chart = await KpNativeChartEngine(KpNativeFfiBridge.open()).cast(
        KpNativeChartInput(
          utc: utc,
          latitude: latitude,
          longitude: longitude,
          nodeMode: LunarNodeMode.trueNode,
        ),
      );
      if (!mounted) return;
      setState(() {
        _nativeChart = chart;
        _eventJudgment = null;
        _timingSynthesis = null;
        _timingConfirmation = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error =
          '${AppCopy.of(context, 'kpNativeChartFailed')}\n$error');
    } finally {
      if (mounted) setState(() => _nativeRunning = false);
    }
  }

  Future<void> _reviewNativeEvent() async {
    final chart = _nativeChart;
    if (chart == null || _nativeRunning) return;
    setState(() {
      _nativeRunning = true;
      _error = null;
    });
    try {
      final judgment = KpEventJudgmentEngine.judge(
        topic: _eventTopic,
        cusps: chart.cusps
            .map((cusp) => KpCuspClassification(
                  house: cusp.house,
                  point: cusp.classification,
                ))
            .toList(growable: false),
        houseEvidence: chart.houseEvidence,
      );
      final moon = chart.planets.firstWhere((planet) => planet.name == 'moon');
      final referenceUtc = DateTime.now().toUtc();
      final timing = KpDashaTimingEngine.build(
        topic: _eventTopic,
        eventJudgment: judgment,
        houseEvidence: chart.houseEvidence,
        moonSiderealLongitude: moon.siderealLongitude,
        birthUtc: DateTime.parse(_utcController.text.trim()).toUtc(),
        referenceUtc: referenceUtc,
      );
      final referenceChart = await KpNativeChartEngine(
        KpNativeFfiBridge.open(),
      ).cast(
        KpNativeChartInput(
          utc: referenceUtc,
          latitude: double.parse(_latitudeController.text.trim()),
          longitude: double.parse(_longitudeController.text.trim()),
          nodeMode: LunarNodeMode.trueNode,
        ),
      );
      final confirmation = KpTimingConfirmationEngine.build(
        topic: _eventTopic,
        eventJudgment: judgment,
        timingSynthesis: timing,
        natalHouseEvidence: chart.houseEvidence,
        referenceTransitPoints: <String, KpPointClassification>{
          for (final planet in referenceChart.planets)
            planet.name: planet.classification,
        },
        referenceRulingPlanets: referenceChart.rulingPlanets,
        referenceUtc: referenceUtc,
      );
      if (!mounted) return;
      setState(() {
        _eventJudgment = judgment;
        _timingSynthesis = timing;
        _timingConfirmation = confirmation;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error =
          '${AppCopy.of(context, 'kpTimingConfirmationFailed')}\n$error');
    } finally {
      if (mounted) setState(() => _nativeRunning = false);
    }
  }

  Future<void> _castAndSaveHorary() async {
    if (_horaryRunning) return;
    setState(() {
      _horaryRunning = true;
      _error = null;
    });
    try {
      final horaryNumber = int.parse(_horaryNumberController.text.trim());
      final question = _horaryQuestionController.text.trim();
      final utc = DateTime.parse(_utcController.text.trim()).toUtc();
      final latitude = double.parse(_latitudeController.text.trim());
      final longitude = double.parse(_longitudeController.text.trim());
      final topic = switch (_horaryTopicIndex) {
        1 => KpEventTopic.marriage,
        2 => KpEventTopic.children,
        _ => null,
      };
      final input = KpHoraryInput(
        question: question,
        horaryNumber: horaryNumber,
        queryUtc: utc,
        latitude: latitude,
        longitude: longitude,
        nodeMode: LunarNodeMode.trueNode,
        topic: topic,
      );
      final chart = await KpHoraryEngine(KpNativeFfiBridge.open()).cast(input);
      final snapshotId = await widget.clientStore.createKpHorarySnapshot(
        input: input,
        chart: chart,
      );
      if (!mounted) return;
      setState(() {
        _horaryChart = chart;
        _horarySnapshotId = snapshotId;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error =
          '${AppCopy.of(context, 'kpHoraryFailed')}\n$error');
    } finally {
      if (mounted) setState(() => _horaryRunning = false);
    }
  }

  void _classifyPoint() {
    try {
      final value = _parseLongitude(_pointController.text);
      setState(() {
        _point = KpFoundationEngine.classify(value);
        _error = null;
      });
    } catch (_) {
      setState(() => _error = AppCopy.of(context, 'kpInvalidLongitude'));
    }
  }

  void _buildRulingPlanets() {
    try {
      final asc = _parseLongitude(_ascController.text);
      final moon = _parseLongitude(_moonController.text);
      setState(() {
        _rulingPlanets = KpFoundationEngine.rulingPlanets(
          ascendantSiderealLongitude: asc,
          moonSiderealLongitude: moon,
          weekday: _weekday,
        );
        _error = null;
      });
    } catch (_) {
      setState(() => _error = AppCopy.of(context, 'kpInvalidLongitude'));
    }
  }

  void _classifyCusps() {
    try {
      final tokens = _cuspsController.text
          .split(RegExp(r'[\s,;]+'))
          .where((value) => value.trim().isNotEmpty)
          .toList(growable: false);
      if (tokens.length != 12) {
        throw const FormatException('Requires 12 cusps');
      }
      final values = tokens.map(_parseLongitude).toList(growable: false);
      setState(() {
        _cusps = KpFoundationEngine.classifyCusps(values);
        _error = null;
      });
    } catch (_) {
      setState(() => _error = AppCopy.of(context, 'kpInvalidCusps'));
    }
  }

  double _parseLongitude(String text) {
    final value = double.parse(text.trim());
    if (!value.isFinite || value < 0 || value >= 360) {
      throw const FormatException('Longitude must be [0,360)');
    }
    return value;
  }
}

class _PointCard extends StatelessWidget {
  const _PointCard({required this.point});

  final KpPointClassification point;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${point.sign} (${point.signLord.toUpperCase()})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text('${point.nakshatra} • Star lord: ${point.starLord.toUpperCase()}'),
              Text('Sub lord: ${point.subLord.toUpperCase()}'),
              Text(
                'Sub boundary: ${point.subStartLongitude.toStringAsFixed(6)}° – ${point.subEndLongitude.toStringAsFixed(6)}°',
              ),
            ],
          ),
        ),
      );
}

class _RulingPlanetCard extends StatelessWidget {
  const _RulingPlanetCard({required this.panel});

  final KpRulingPlanetPanel panel;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                panel.uniquePlanets.map((p) => p.toUpperCase()).join(' • '),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...panel.roles.map(
                (role) => Text(
                  '${role.rank}. ${role.role}: ${role.planet.toUpperCase()}',
                ),
              ),
            ],
          ),
        ),
      );
}
