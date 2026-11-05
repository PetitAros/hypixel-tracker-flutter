import 'package:hypixel_tracker/domain/entities/player.dart';
import 'package:hypixel_tracker/domain/entities/player_profiles.dart';

/// Thrown by [ProfileRepository.loadProfile] when the player has no
/// SkyBlock profile: they never played it, or deleted every profile.
class NoSkyBlockProfileException implements Exception {
  const NoSkyBlockProfileException();
}

abstract interface class ProfileRepository {
  /// The SkyBlock progress of [player], from the last copy when offline.
  /// Throws when it cannot be loaded.
  Future<PlayerProfile> loadProfile(Player player);
}
