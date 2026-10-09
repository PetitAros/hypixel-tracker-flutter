// One result of an item search.
class ItemSummary {
  final String id; // the item tag, e.g. "HYPERION"
  final String name;
  final String tier; // e.g. "LEGENDARY", or "UNKNOWN"
  final String? iconUrl;

  const ItemSummary({
    required this.id,
    required this.name,
    required this.tier,
    required this.iconUrl,
  });
}
