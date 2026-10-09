import 'package:hypixel_tracker/domain/entities/player.dart';
import 'package:hypixel_tracker/domain/entities/player_profiles.dart';

abstract interface class ProfileRepository {
  /// The SkyBlock progress of [player]. Throws when it cannot be loaded.
  Future<PlayerProfile> loadProfile(Player player);
}
