import 'package:hypixel_tracker/domain/entities/auction_page.dart';

abstract interface class AuctionRepository {
  /// The first page as last saved on disk, or null when nothing was saved.
  AuctionPage? readCached();

  /// Fetches the first page from the network and saves it to disk.
  Future<AuctionPage> refresh();

  /// Fetches one of the following pages. Network only: it is not saved.
  Future<AuctionPage> fetchPage(int page);
}
