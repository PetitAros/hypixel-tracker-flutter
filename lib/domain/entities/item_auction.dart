// One active auction of a given item, as listed when browsing by item.
class ItemAuction {
  final String id;
  final String sellerName;
  final int price;
  final DateTime endsAt;

  const ItemAuction({
    required this.id,
    required this.sellerName,
    required this.price,
    required this.endsAt,
  });
}
