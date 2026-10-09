import 'package:hypixel_tracker/domain/entities/bazaar_category.dart';

// Sorts bazaar products into categories. Hypixel gives none, so this guesses:
// id families first (enchanted books, shards), then the skill collection the
// product belongs to or is crafted from (ENCHANTED_COAL contains COAL, a
// mining collection). Whatever is left lands in Oddities.
class BazaarCategorySorter {
  /// [collections] maps an item id to its collection group as Hypixel names
  /// it, e.g. "COAL" -> "MINING".
  BazaarCategorySorter(Map<String, String> collections) {
    collections.forEach((id, group) {
      final category = _groups[group];
      if (category == null) return;

      _exact[id] = category;

      // "LOG:2" also counts for products built on "LOG". An id without a
      // variant wins over one with: INK_SACK is fishing, INK_SACK:3 farming.
      final separator = id.indexOf(':');
      if (separator == -1) {
        _base[id] = category;
      } else {
        _base.putIfAbsent(id.substring(0, separator), () => category);
      }
    });
  }

  static const _groups = {
    'FARMING': BazaarCategory.farming,
    'MINING': BazaarCategory.mining,
    'COMBAT': BazaarCategory.combat,
    'FORAGING': BazaarCategory.woodsAndFishes,
    'FISHING': BazaarCategory.woodsAndFishes,
  };

  final _exact = <String, BazaarCategory>{};
  final _base = <String, BazaarCategory>{};

  BazaarCategory categoryOf(String productId) {
    if (productId.startsWith('ENCHANTMENT_')) {
      return BazaarCategory.enchantments;
    }
    if (productId.startsWith('SHARD_')) return BazaarCategory.shards;
    // Hoppity's rabbits contain "RABBIT", a farming collection, by accident.
    if (productId.startsWith('FACTION_')) return BazaarCategory.oddities;

    final exact = _exact[productId];
    if (exact != null) return exact;

    // Otherwise, the longest collection id found as whole words in the
    // product id: ENCHANTED_COAL_BLOCK contains COAL, so it is mining.
    final padded = '_${productId.split(':').first}_';
    String? best;
    for (final base in _base.keys) {
      if (padded.contains('_${base}_') &&
          (best == null || base.length > best.length)) {
        best = base;
      }
    }
    return _base[best] ?? BazaarCategory.oddities;
  }
}
