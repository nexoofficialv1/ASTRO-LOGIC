import 'package:astro_logic/src/models/astro_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('implemented dashboard modules are available and placeholders are gated', () {
    final byKey = {for (final module in astroModules) module.copyKey: module};

    for (final key in [
      'clients',
      'vedic',
      'numerology',
      'gemstoneRemedies',
      'reports',
      'settings',
    ]) {
      expect(byKey[key]?.availability, AstroModuleAvailability.available);
    }

    for (final key in ['kp', 'western', 'vastu', 'palmistry', 'practice']) {
      expect(byKey[key]?.availability, AstroModuleAvailability.comingSoon);
    }
  });
}
