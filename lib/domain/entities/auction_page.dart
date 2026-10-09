import 'package:hypixel_tracker/domain/entities/auction.dart';

class AuctionPage {
  final List<Auction> items;
  final int page;
  final int totalPages;
  final DateTime lastUpdated;
  final bool fromCache;

  const AuctionPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.lastUpdated,
    required this.fromCache,
  });
}
