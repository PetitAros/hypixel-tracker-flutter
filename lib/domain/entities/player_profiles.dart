import 'package:hypixel_tracker/domain/entities/player.dart';

// Progress of one skill, e.g. Farming level 42.
class SkillProgress {
  final String name;
  final int level;
  final int maxLevel;

  /// Share of the way to the next level, from 0 to 1 (1 at max level).
  final double progress;
  final int experience;

  const SkillProgress({
    required this.name,
    required this.level,
    required this.maxLevel,
    required this.progress,
    required this.experience,
  });
}

// Progress of one collection, e.g. Wheat tier 7 of 11.
class CollectionProgress {
  final String category; // e.g. "Farming"
  final String itemName;
  final String iconUrl;
  final int amount;
  final int tier;
  final int maxTier;

  const CollectionProgress({
    required this.category,
    required this.itemName,
    required this.iconUrl,
    required this.amount,
    required this.tier,
    required this.maxTier,
  });
}

// One item in the Dwarven Mines forge, e.g. a Refined Diamond in slot 2.
class ForgeSlot {
  final int slot; // from 1
  final String itemName;
  final String iconUrl;
  final DateTime startedAt;

  /// Null when the app does not know how long this item takes.
  final DateTime? readyAt;

  const ForgeSlot({
    required this.slot,
    required this.itemName,
    required this.iconUrl,
    required this.startedAt,
    required this.readyAt,
  });

  /// Share of the forge time done at [now], from 0 to 1. Null when the
  /// duration is unknown.
  double? progressAt(DateTime now) {
    final readyAt = this.readyAt;
    if (readyAt == null) return null;
    final total = readyAt.difference(startedAt).inMilliseconds;
    if (total <= 0) return 1;
    return (now.difference(startedAt).inMilliseconds / total).clamp(0, 1);
  }
}

// The SkyBlock progress of a player on one of their profiles.
class PlayerProfile {
  final Player player;
  final String
  profileName; // SkyBlock names profiles after fruits, e.g. "Mango"
  final List<SkillProgress> skills;
  final List<CollectionProgress> collections;

  /// The busy forge slots, in slot order.
  final List<ForgeSlot> forge;

  /// True when Hypixel could not be reached and this is the last copy saved.
  final bool fromCache;

  const PlayerProfile({
    required this.player,
    required this.profileName,
    required this.skills,
    required this.collections,
    required this.forge,
    required this.fromCache,
  });

  double get skillAverage => skills.isEmpty
      ? 0
      : skills.fold(0, (sum, skill) => sum + skill.level) / skills.length;
}
