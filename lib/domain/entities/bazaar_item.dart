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
}
