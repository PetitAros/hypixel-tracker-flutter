import 'package:hive_ce/hive.dart';
import 'package:hypixel_tracker/domain/entities/bazaar_category.dart';
import 'package:hypixel_tracker/domain/entities/bazaar_item.dart';

part 'bazaar_item_model.g.dart';

@HiveType(typeId: 0)
class BazaarItemModel extends HiveObject {
  @HiveField(0)
  final String productId; // Hypixel's raw field name, e.g. "product_id"

  @HiveField(1)
  final double buyPrice;

  @HiveField(2)
  final double sellPrice;

  @HiveField(3)
  final int weekVolume; // matches Hypixel's raw "sellMovingWeek"

  BazaarItemModel({
    required this.productId,
    required this.buyPrice,
    required this.sellPrice,
    required this.weekVolume,
  });

  // From Hypixel's raw JSON
  factory BazaarItemModel.fromJson(Map<String, dynamic> json) {
    final quickStatus = json['quick_status'];
    return BazaarItemModel(
      productId: json['product_id'],
      buyPrice: quickStatus['buyPrice'].toDouble(),
      sellPrice: quickStatus['sellPrice'].toDouble(),
      weekVolume: quickStatus['sellMovingWeek'].toInt(),
    );
  }

  // Converts to the clean entity the rest of the app uses.
  // [name] is the official name from the items resource, when known.
  BazaarItem toEntity({
    String? name,
    required BazaarCategory category,
    required String iconUrl,
  }) {
    return BazaarItem(
      id: productId,
      displayName: name ?? _prettify(productId),
      category: category,
      iconUrl: iconUrl,
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      weeklyVolume: weekVolume,
    );
  }

  static const _enchantmentPrefix = 'ENCHANTMENT_';

  // Id families whose prefix reads better as a suffix.
  static const _suffixedPrefixes = {'SHARD_': 'Shard', 'ESSENCE_': 'Essence'};

  // Fallback for the bazaar-only ids missing from the items resource
  // (about half of the products: enchanted books, shards, essences).
  static String _prettify(String raw) {
    // "ENCHANTMENT_SHARPNESS_7" -> "Sharpness 7"
    if (raw.startsWith(_enchantmentPrefix)) {
      return _titleCase(raw.substring(_enchantmentPrefix.length));
    }

    // "SHARD_QUEEN_BEE" -> "Queen Bee Shard"
    for (final MapEntry(key: prefix, value: suffix)
        in _suffixedPrefixes.entries) {
      if (raw.startsWith(prefix)) {
        return '${_titleCase(raw.substring(prefix.length))} $suffix';
      }
    }

    // "ENCHANTED_COAL" -> "Enchanted Coal"
    return _titleCase(raw);
  }

  static String _titleCase(String raw) => raw
      .toLowerCase()
      .split('_')
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}
