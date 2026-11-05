import 'dart:math';

import 'package:hypixel_tracker/data/models/forge_durations.dart';
import 'package:hypixel_tracker/domain/entities/player_profiles.dart';

// The SkyBlock profile a player last played on, reduced to what the app shows.
class SkyblockProfileModel {
  final String cuteName; // e.g. "Mango"

  /// Experience by skill id, e.g. "FARMING" -> 1234567.8.
  /// Empty when the player turned their skills API off.
  final Map<String, double> experience;

  /// Items collected by item id, e.g. "WHEAT" -> 51234.
  /// Empty when the player turned their collections API off.
  final Map<String, int> collection;

  /// What is in the forge, in slot order. Empty when it is idle.
  final List<ForgeProcessModel> forge;

  /// The Heart of the Mountain perk that shortens every forge. 0 if not
  /// unlocked.
  final int quickForgeLevel;

  const SkyblockProfileModel({
    required this.cuteName,
    required this.experience,
    required this.collection,
    required this.forge,
    required this.quickForgeLevel,
  });

  static const _skillPrefix = 'SKILL_';
  static const _quickForgeNode = 'forge_time';

  /// [profile] is one entry of the Hypixel `profiles` list; [uuid] picks the
  /// player among its members (coop profiles have several).
  factory SkyblockProfileModel.fromJson(
    Map<String, dynamic> profile,
    String uuid,
  ) {
    final member = profile['members'][uuid] as Map<String, dynamic>;
    final experience =
        member['player_data']?['experience'] as Map<String, dynamic>? ?? {};
    final collection = member['collection'] as Map<String, dynamic>? ?? {};
    // One map per forge, "forge_1", then one entry per busy slot.
    final forges =
        member['forge']?['forge_processes'] as Map<String, dynamic>? ?? {};
    // The perk tree moved in the API over time: read both places.
    final quickForge =
        member['skill_tree']?['nodes']?['mining']?[_quickForgeNode] ??
        member['mining_core']?['nodes']?[_quickForgeNode];

    return SkyblockProfileModel(
      cuteName: profile['cute_name'] as String,
      experience: {
        for (final MapEntry(:key, :value) in experience.entries)
          if (key.startsWith(_skillPrefix))
            key.substring(_skillPrefix.length): (value as num).toDouble(),
      },
      collection: {
        for (final MapEntry(:key, :value) in collection.entries)
          key: (value as num).toInt(),
      },
      forge: [
        for (final slots in forges.values)
          for (final process in (slots as Map<String, dynamic>).values)
            ForgeProcessModel.fromJson(process as Map<String, dynamic>),
      ]..sort((a, b) => a.slot.compareTo(b.slot)),
      quickForgeLevel: quickForge is num ? quickForge.toInt() : 0,
    );
  }
}

// One item being forged, from the profile's `forge_processes`.
class ForgeProcessModel {
  final String itemId; // e.g. "REFINED_DIAMOND"
  final int slot; // from 1
  final int startTime; // epoch milliseconds

  const ForgeProcessModel({
    required this.itemId,
    required this.slot,
    required this.startTime,
  });

  factory ForgeProcessModel.fromJson(Map<String, dynamic> json) {
    return ForgeProcessModel(
      itemId: json['id'] as String,
      slot: (json['slot'] as num).toInt(),
      startTime: (json['startTime'] as num).toInt(),
    );
  }

  ForgeSlot toEntity({required int quickForgeLevel, required String iconUrl}) {
    final startedAt = DateTime.fromMillisecondsSinceEpoch(startTime);
    final duration = ForgeDurations.of(
      itemId,
      quickForgeLevel: quickForgeLevel,
    );
    return ForgeSlot(
      slot: slot,
      itemName: _nameOf(itemId),
      iconUrl: iconUrl,
      startedAt: startedAt,
      readyAt: duration == null ? null : startedAt.add(duration),
    );
  }

  // "PERFECT_RUBY_GEM" -> "Perfect Ruby Gem"
  static String _nameOf(String itemId) => itemId
      .split('_')
      .map((word) => word[0] + word.substring(1).toLowerCase())
      .join(' ');
}

// How much experience each level of a skill costs, from resources/skyblock/skills.
class SkillTableModel {
  final String id; // e.g. "FARMING"
  final String name; // e.g. "Farming"
  final int maxLevel;

  /// Total experience needed to reach each level: index 0 is level 1.
  final List<double> totalExperience;

  const SkillTableModel({
    required this.id,
    required this.name,
    required this.maxLevel,
    required this.totalExperience,
  });

  factory SkillTableModel.fromJson(String id, Map<String, dynamic> json) {
    return SkillTableModel(
      id: id,
      name: json['name'] as String,
      maxLevel: json['maxLevel'] as int,
      totalExperience: [
        for (final level in json['levels'] as List<dynamic>)
          (level['totalExpRequired'] as num).toDouble(),
      ],
    );
  }

  SkillProgress toEntity(double experience) {
    final cap = min(maxLevel, totalExperience.length);

    var level = 0;
    while (level < cap && experience >= totalExperience[level]) {
      level++;
    }

    var progress = 1.0;
    if (level < cap) {
      final floor = level == 0 ? 0.0 : totalExperience[level - 1];
      progress = (experience - floor) / (totalExperience[level] - floor);
    }

    return SkillProgress(
      name: name,
      level: level,
      maxLevel: cap,
      progress: progress.clamp(0, 1),
      experience: experience.round(),
    );
  }
}

// The tiers of one collection, from resources/skyblock/collections.
class CollectionTableModel {
  final String category; // e.g. "Farming"
  final String itemId; // e.g. "WHEAT"
  final String name; // e.g. "Wheat"

  /// Items needed for each tier: index 0 is tier 1.
  final List<int> tiers;

  const CollectionTableModel({
    required this.category,
    required this.itemId,
    required this.name,
    required this.tiers,
  });

  factory CollectionTableModel.fromJson(
    String category,
    String itemId,
    Map<String, dynamic> json,
  ) {
    return CollectionTableModel(
      category: category,
      itemId: itemId,
      name: json['name'] as String,
      tiers: [
        for (final tier in json['tiers'] as List<dynamic>)
          (tier['amountRequired'] as num).toInt(),
      ],
    );
  }

  CollectionProgress toEntity(int amount, {required String iconUrl}) {
    return CollectionProgress(
      category: category,
      itemName: name,
      iconUrl: iconUrl,
      amount: amount,
      tier: tiers.where((required) => amount >= required).length,
      maxTier: tiers.length,
    );
  }
}
