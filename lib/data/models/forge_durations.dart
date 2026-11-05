// How long each item takes in the Dwarven Mines forge, before Quick Forge.
// Hypixel's API gives when a forge started but not how long it lasts, so
// these come from the SkyBlock wiki. Add an item here to time it; the others
// are shown without a countdown.
class ForgeDurations {
  ForgeDurations._();

  static const _byItemId = <String, Duration>{
    // Refined materials
    'REFINED_DIAMOND': Duration(hours: 8),
    'REFINED_MITHRIL': Duration(hours: 6),
    'REFINED_TITANIUM': Duration(hours: 12),
    'REFINED_UMBER': Duration(hours: 2),
    'REFINED_TUNGSTEN': Duration(hours: 2),
    // Parts
    'FUEL_TANK': Duration(hours: 10),
    'BEJEWELED_HANDLE': Duration(minutes: 30),
    'DRILL_ENGINE': Duration(hours: 30),
    'GOLDEN_PLATE': Duration(hours: 6),
    'MITHRIL_PLATE': Duration(hours: 18),
    'GEMSTONE_MIXTURE': Duration(hours: 4),
    'GLACITE_AMALGAMATION': Duration(hours: 4),
    'PERFECT_PLATE': Duration(minutes: 30),
    'POWER_CRYSTAL': Duration(hours: 2),
    // Perfect gemstones
    'PERFECT_RUBY_GEM': Duration(hours: 20),
    'PERFECT_AMBER_GEM': Duration(hours: 20),
    'PERFECT_AMETHYST_GEM': Duration(hours: 20),
    'PERFECT_JADE_GEM': Duration(hours: 20),
    'PERFECT_SAPPHIRE_GEM': Duration(hours: 20),
    'PERFECT_TOPAZ_GEM': Duration(hours: 20),
    'PERFECT_JASPER_GEM': Duration(hours: 20),
    'PERFECT_OPAL_GEM': Duration(hours: 20),
    'PERFECT_AQUAMARINE_GEM': Duration(hours: 20),
    'PERFECT_CITRINE_GEM': Duration(hours: 20),
    'PERFECT_ONYX_GEM': Duration(hours: 20),
    'PERFECT_PERIDOT_GEM': Duration(hours: 20),
  };

  static const _quickForgeMaxLevel = 20;

  /// The time [itemId] takes with Quick Forge at [quickForgeLevel], or null
  /// when the item is not in the table.
  static Duration? of(String itemId, {required int quickForgeLevel}) {
    final base = _byItemId[itemId];
    if (base == null) return null;
    return base * (1 - _quickForgeReduction(quickForgeLevel));
  }

  // 10% plus 0.5% per level, and a jump to 30% at the max level.
  static double _quickForgeReduction(int level) {
    if (level <= 0) return 0;
    if (level >= _quickForgeMaxLevel) return 0.3;
    return 0.1 + 0.005 * level;
  }
}
