enum Ayanamsha { lahiri, raman, krishnamurti }

enum VedicChartStyle { northIndian, southIndian, eastIndian }

enum WesternHouseSystem { placidus, wholeSign, equal }

enum LunarNodeMode { trueNode, meanNode }

class AstrologySettings {
  const AstrologySettings({
    required this.ayanamsha,
    required this.vedicChartStyle,
    required this.westernHouseSystem,
    required this.lunarNodeMode,
  });

  final Ayanamsha ayanamsha;
  final VedicChartStyle vedicChartStyle;
  final WesternHouseSystem westernHouseSystem;
  final LunarNodeMode lunarNodeMode;

  static const defaults = AstrologySettings(
    ayanamsha: Ayanamsha.lahiri,
    vedicChartStyle: VedicChartStyle.northIndian,
    westernHouseSystem: WesternHouseSystem.placidus,
    lunarNodeMode: LunarNodeMode.trueNode,
  );

  Map<String, Object?> toDatabaseMap() => {
        'id': 1,
        'ayanamsha': ayanamsha.name,
        'vedic_chart_style': vedicChartStyle.name,
        'western_house_system': westernHouseSystem.name,
        'lunar_node_mode': lunarNodeMode.name,
      };

  factory AstrologySettings.fromDatabaseMap(Map<String, Object?> map) =>
      AstrologySettings(
        ayanamsha: Ayanamsha.values.byName(map['ayanamsha'] as String),
        vedicChartStyle: VedicChartStyle.values
            .byName(map['vedic_chart_style'] as String),
        westernHouseSystem: WesternHouseSystem.values
            .byName(map['western_house_system'] as String),
        lunarNodeMode:
            LunarNodeMode.values.byName(map['lunar_node_mode'] as String),
      );
}

