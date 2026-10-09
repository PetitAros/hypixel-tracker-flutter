import 'bazaar_item.dart';

class BazaarSnapshot {
  final List<BazaarItem> items;
  final DateTime lastUpdated;
  final bool fromCache; // true when the network failed and disk data was served

  const BazaarSnapshot({
    required this.items,
    required this.lastUpdated,
    required this.fromCache,
  });
}
