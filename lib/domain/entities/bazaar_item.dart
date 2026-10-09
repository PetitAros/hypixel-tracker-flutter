class BazaarItem {
  final String id;
  final String displayName;
  final double buyPrice;
  final double sellPrice;
  final int weeklyVolume;

  const BazaarItem({
    required this.id,
    required this.displayName,
    required this.buyPrice,
    required this.sellPrice,
    required this.weeklyVolume,
  });
}