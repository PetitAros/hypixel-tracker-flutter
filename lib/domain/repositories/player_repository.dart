import 'package:hypixel_tracker/domain/entities/player.dart';
import 'package:hypixel_tracker/domain/entities/player_skin.dart';

abstract interface class PlayerRepository {
  /// The account with exactly this username (case does not matter),
  /// or null when there is none. Throws when the network fails.
  Future<Player?> findByName(String name);

  /// The player the app follows, kept across restarts. Null when none.
  Player? readFollowed();

  /// Remembers [player] as the followed player; null forgets them.
  Future<void> saveFollowed(Player? player);

  /// The skin [player] wears, null for the default one. Throws when the
  /// network fails.
  Future<PlayerSkin?> loadSkin(Player player);
}
