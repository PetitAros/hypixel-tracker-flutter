import 'package:hypixel_tracker/domain/entities/bazaar_category.dart';

class BazaarItem {
  final String id;
  final String displayName;
  final BazaarCategory category;
  final String iconUrl;
  final double buyPrice;
  final double sellPrice;
  final int weeklyVolume;

  const BazaarItem({
    required this.id,
    required this.displayName,
    required this.category,
    required this.iconUrl,
    required this.buyPrice,
    required this.sellPrice,
    required this.weeklyVolume,
  });

  /// What separates the price to buy now from the price to sell now.
  double get spread => buyPrice - sellPrice;

  /// The spread as a share of the sell price: what a flip would earn
  /// (buy with an order at the sell price, sell with one at the buy price).
  double get margin => sellPrice <= 0 ? 0 : spread / sellPrice;
}
