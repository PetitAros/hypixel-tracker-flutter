import 'package:hypixel_tracker/domain/entities/skyblock_events.dart';

abstract interface class EventsRepository {
  /// The mayor, election, Bingo and fire sales, fresh from the network.
  /// Throws when any of them cannot be loaded.
  Future<SkyblockEvents> load();
}
