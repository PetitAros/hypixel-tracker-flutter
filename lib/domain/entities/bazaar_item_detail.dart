// One line of the bazaar order book.
class BazaarOrder {
  final double pricePerUnit;
  final int amount;
  final int orders;

  const BazaarOrder({
    required this.pricePerUnit,
    required this.amount,
    required this.orders,
  });
}

// Lowest and highest prices over the last 24 hours.
class BazaarDayRange {
  final double minBuy;
  final double maxBuy;
  final double minSell;
  final double maxSell;

  const BazaarDayRange({
    required this.minBuy,
    required this.maxBuy,
    required this.minSell,
    required this.maxSell,
  });
}

// Live state of one bazaar product: prices, volumes and order book.
class BazaarItemDetail {
  final double buyPrice;
  final double sellPrice;
  final int buyVolume;
  final int sellVolume;
  final int buyMovingWeek;
  final int sellMovingWeek;
  final List<BazaarOrder> buyOrders;
  final List<BazaarOrder> sellOrders;
  final BazaarDayRange? dayRange; // null when there is no history

  const BazaarItemDetail({
    required this.buyPrice,
    required this.sellPrice,
    required this.buyVolume,
    required this.sellVolume,
    required this.buyMovingWeek,
    required this.sellMovingWeek,
    required this.buyOrders,
    required this.sellOrders,
    this.dayRange,
  });

  BazaarItemDetail withDayRange(BazaarDayRange? dayRange) {
    return BazaarItemDetail(
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      buyVolume: buyVolume,
      sellVolume: sellVolume,
      buyMovingWeek: buyMovingWeek,
      sellMovingWeek: sellMovingWeek,
      buyOrders: buyOrders,
      sellOrders: sellOrders,
      dayRange: dayRange,
    );
  }
}
