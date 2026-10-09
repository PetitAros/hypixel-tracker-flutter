import 'package:hypixel_tracker/data/datasources/remote/coflnet_remote_datasource.dart';
import 'package:hypixel_tracker/domain/entities/bazaar_item_detail.dart';
import 'package:hypixel_tracker/domain/entities/item_auction.dart';
import 'package:hypixel_tracker/domain/entities/item_summary.dart';
import 'package:hypixel_tracker/domain/repositories/market_repository.dart';

class MarketRepositoryImpl implements MarketRepository {
  final CoflnetRemoteDatasource remote;

  MarketRepositoryImpl({required this.remote});

  @override
  Future<List<ItemSummary>> searchItems(String query) {
    return remote.searchItems(query);
  }

  @override
  Future<List<ItemAuction>> activeAuctions(String itemTag) {
    return remote.getActiveAuctions(itemTag);
  }

  @override
  Future<BazaarItemDetail> bazaarDetail(String itemTag) async {
    // The history is a bonus: the page still works without it.
    final pendingRange = remote
        .getBazaarDayRange(itemTag)
        .then<BazaarDayRange?>((range) => range, onError: (_) => null);

    final snapshot = await remote.getBazaarSnapshot(itemTag);
    return snapshot.withDayRange(await pendingRange);
  }
}
