import 'package:hypixel_tracker/domain/entities/bazaar_item_detail.dart';
import 'package:hypixel_tracker/domain/entities/item_auction.dart';
import 'package:hypixel_tracker/domain/entities/item_summary.dart';

/// Market lookups the Hypixel API cannot answer: search and per-item data.
/// Network only, nothing is cached.
abstract interface class MarketRepository {
  /// Items whose name matches [query].
  Future<List<ItemSummary>> searchItems(String query);

  /// Active auctions of one item, cheapest first.
  Future<List<ItemAuction>> activeAuctions(String itemTag);

  /// Live prices, order book and 24 hour range of one bazaar product.
  Future<BazaarItemDetail> bazaarDetail(String itemTag);
}
