import 'package:hypixel_tracker/domain/entities/auction_page.dart';

abstract interface class AuctionRepository {
  AuctionPage? readCached();
  Future<AuctionPage> refresh();
}
