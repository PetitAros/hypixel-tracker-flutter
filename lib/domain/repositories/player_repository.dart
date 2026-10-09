import 'package:hypixel_tracker/domain/entities/player.dart';

abstract interface class PlayerRepository {
  /// The account with exactly this username (case does not matter),
  /// or null when there is none. Throws when the network fails.
  Future<Player?> findByName(String name);
}
