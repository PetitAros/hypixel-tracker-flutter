class Auction {
  final String id;
  final String itemName;
  final String tier;
  final String category;
  final bool isBin;
  final int price;
  final DateTime endsAt;

  const Auction({
    required this.id,
    required this.itemName,
    required this.tier,
    required this.category,
    required this.isBin,
    required this.price,
    required this.endsAt,
  });
}
