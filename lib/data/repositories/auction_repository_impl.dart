import 'package:hypixel_tracker/domain/entities/auction.dart';
import 'package:hypixel_tracker/domain/entities/auction_page.dart';
import 'package:hypixel_tracker/domain/repositories/auction_repository.dart';
import 'package:hypixel_tracker/data/datasources/local/auction_local_datasource.dart';
import 'package:hypixel_tracker/data/datasources/remote/hypixel_remote_datasource.dart';
import 'package:hypixel_tracker/data/models/auction_model.dart';

class AuctionRepositoryImpl implements AuctionRepository {
  final HypixelRemoteDatasource remote;
  final AuctionLocalDatasource local;

  AuctionRepositoryImpl({required this.remote, required this.local});

  // The first page is the one kept on disk.
  static const _page = 0;

  @override
  AuctionPage? readCached() {
    final cached = local.read();
    final lastUpdated = local.lastUpdated;
    final totalPages = local.totalPages;
    if (cached.isEmpty || lastUpdated == null || totalPages == null) {
      return null;
    }

    return AuctionPage(
      items: _toEntities(cached),
      page: _page,
      totalPages: totalPages,
      lastUpdated: lastUpdated,
      fromCache: true,
    );
  }

  @override
  Future<AuctionPage> refresh() async {
    final response = await remote.getAuctions(page: _page);

    final fetchedAt = DateTime.now();
    await local.save(response.auctions, response.totalPages, fetchedAt);

    return AuctionPage(
      items: _toEntities(response.auctions),
      page: response.page,
      totalPages: response.totalPages,
      lastUpdated: fetchedAt,
      fromCache: false,
    );
  }

  @override
  Future<AuctionPage> fetchPage(int page) async {
    final response = await remote.getAuctions(page: page);

    return AuctionPage(
      items: _toEntities(response.auctions),
      page: response.page,
      totalPages: response.totalPages,
      lastUpdated: DateTime.now(),
      fromCache: false,
    );
  }

  // Ending soonest first, so the network and the cache show the same order.
  static List<Auction> _toEntities(List<AuctionModel> models) {
    return models.map((model) => model.toEntity()).toList()
      ..sort((a, b) => a.endsAt.compareTo(b.endsAt));
  }
}
