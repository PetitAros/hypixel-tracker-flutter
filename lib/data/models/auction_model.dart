import 'package:hive_ce/hive.dart';
import 'package:hypixel_tracker/domain/entities/auction.dart';

part 'auction_model.g.dart';

@HiveType(typeId: 1)
class AuctionModel extends HiveObject {
  @HiveField(0)
  final String uuid;

  @HiveField(1)
  final String itemName; // Hypixel's raw "item_name"

  @HiveField(2)
  final String tier; // e.g. "LEGENDARY"

  @HiveField(3)
  final String category; // e.g. "misc"

  @HiveField(4)
  final bool bin; // true for a fixed-price "Buy It Now" sale

  @HiveField(5)
  final int startingBid; // matches Hypixel's raw "starting_bid"

  @HiveField(6)
  final int highestBid; // matches Hypixel's raw "highest_bid_amount", 0 without bids

  @HiveField(7)
  final int end; // end time in milliseconds since epoch

  AuctionModel({
    required this.uuid,
    required this.itemName,
    required this.tier,
    required this.category,
    required this.bin,
    required this.startingBid,
    required this.highestBid,
    required this.end,
  });

  // From Hypixel's raw JSON
  factory AuctionModel.fromJson(Map<String, dynamic> json) {
    return AuctionModel(
      uuid: json['uuid'] as String,
      itemName: json['item_name'] as String,
      tier: json['tier'] as String,
      category: json['category'] as String,
      bin: json['bin'] == true,
      startingBid: (json['starting_bid'] as num).toInt(),
      highestBid: (json['highest_bid_amount'] as num).toInt(),
      end: (json['end'] as num).toInt(),
    );
  }

  // Converts to the clean entity the rest of the app uses
  Auction toEntity() {
    return Auction(
      id: uuid,
      itemName: itemName,
      tier: tier,
      category: category,
      isBin: bin,
      // The price to pay now: the top bid, or the starting bid without bids.
      price: highestBid > 0 ? highestBid : startingBid,
      endsAt: DateTime.fromMillisecondsSinceEpoch(end),
    );
  }
}
