import 'package:astro_logic/src/models/astrology_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculation settings round-trip through database map', () {
    const settings = AstrologySettings(
      ayanamsha: Ayanamsha.krishnamurti,
      vedicChartStyle: VedicChartStyle.eastIndian,
      westernHouseSystem: WesternHouseSystem.wholeSign,
      lunarNodeMode: LunarNodeMode.meanNode,
    );

    final restored = AstrologySettings.fromDatabaseMap(settings.toDatabaseMap());

    expect(restored.ayanamsha, Ayanamsha.krishnamurti);
    expect(restored.vedicChartStyle, VedicChartStyle.eastIndian);
    expect(restored.westernHouseSystem, WesternHouseSystem.wholeSign);
    expect(restored.lunarNodeMode, LunarNodeMode.meanNode);
  });
}

