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

// The SkyBlock progress of a player on one of their profiles.
class PlayerProfile {
  final Player player;
  final String
  profileName; // SkyBlock names profiles after fruits, e.g. "Mango"
  final List<SkillProgress> skills;
  final List<CollectionProgress> collections;

  /// True while the data is generated instead of coming from Hypixel.
  final bool isDemo;

  const PlayerProfile({
    required this.player,
    required this.profileName,
    required this.skills,
    required this.collections,
    required this.isDemo,
  });

  double get skillAverage => skills.isEmpty
      ? 0
      : skills.fold(0, (sum, skill) => sum + skill.level) / skills.length;
}
