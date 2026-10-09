import 'package:hive_ce/hive.dart';
import 'package:hypixel_tracker/data/models/auction_model.dart';

class AuctionLocalDatasource {
  final Box<AuctionModel> auctionsBox;
  final Box<dynamic> metaBox;

  AuctionLocalDatasource({required this.auctionsBox, required this.metaBox});

  static const _lastUpdatedKey = 'auctions_last_updated';
  static const _totalPagesKey = 'auctions_total_pages';

  List<AuctionModel> read() => auctionsBox.values.toList();

  DateTime? get lastUpdated {
    final millis = metaBox.get(_lastUpdatedKey) as int?;
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  int? get totalPages => metaBox.get(_totalPagesKey) as int?;

  Future<void> save(
    List<AuctionModel> auctions,
    int totalPages,
    DateTime fetchedAt,
  ) async {
    // Write the new auctions before dropping the stale ones: if the app is
    // killed mid-save the box holds a mix of old and new, never nothing.
    final fresh = {for (final auction in auctions) auction.uuid: auction};
    final stale = auctionsBox.keys
        .where((key) => !fresh.containsKey(key))
        .toList();

    await auctionsBox.putAll(fresh);
    await auctionsBox.deleteAll(stale);
    await metaBox.put(_totalPagesKey, totalPages);
    await metaBox.put(_lastUpdatedKey, fetchedAt.millisecondsSinceEpoch);
  }
}
