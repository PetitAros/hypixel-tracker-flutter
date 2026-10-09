import 'dart:math';

import 'package:hypixel_tracker/data/datasources/remote/coflnet_remote_datasource.dart';
import 'package:hypixel_tracker/domain/entities/player.dart';
import 'package:hypixel_tracker/domain/entities/player_profiles.dart';
import 'package:hypixel_tracker/domain/repositories/profile_repository.dart';

// Stand-in for the Hypixel profile call, which needs an API key.
// It invents plausible progress, always the same for a given player.
// Replace it in main.dart with a Hypixel-backed repository when the key is
// there; nothing else has to change.
class FakeProfileRepository implements ProfileRepository {
  // Long enough to see the loading state, like a real network call.
  static const _delay = Duration(milliseconds: 600);

  static const _profileNames = ['Apple', 'Banana', 'Mango', 'Kiwi', 'Peach'];

  // Skill name and its level cap.
  static const _skills = [
    ('Farming', 60),
    ('Mining', 60),
    ('Combat', 60),
    ('Foraging', 50),
    ('Fishing', 50),
    ('Enchanting', 60),
    ('Alchemy', 50),
    ('Taming', 50),
    ('Carpentry', 50),
    ('Runecrafting', 25),
    ('Social', 25),
  ];

  // Category, item id, item name and number of tiers.
  static const _collections = [
    ('Farming', 'WHEAT', 'Wheat', 11),
    ('Farming', 'CARROT_ITEM', 'Carrot', 9),
    ('Farming', 'POTATO_ITEM', 'Potato', 9),
    ('Farming', 'PUMPKIN', 'Pumpkin', 11),
    ('Farming', 'SUGAR_CANE', 'Sugar Cane', 9),
    ('Mining', 'COBBLESTONE', 'Cobblestone', 10),
    ('Mining', 'COAL', 'Coal', 10),
    ('Mining', 'IRON_INGOT', 'Iron Ingot', 12),
    ('Mining', 'GOLD_INGOT', 'Gold Ingot', 9),
    ('Mining', 'DIAMOND', 'Diamond', 9),
    ('Combat', 'ROTTEN_FLESH', 'Rotten Flesh', 10),
    ('Combat', 'BONE', 'Bone', 10),
    ('Combat', 'STRING', 'String', 9),
    ('Combat', 'ENDER_PEARL', 'Ender Pearl', 9),
    ('Foraging', 'LOG', 'Oak Wood', 9),
    ('Foraging', 'LOG:1', 'Spruce Wood', 9),
    ('Foraging', 'LOG:2', 'Birch Wood', 10),
    ('Fishing', 'RAW_FISH', 'Raw Fish', 11),
    ('Fishing', 'RAW_FISH:1', 'Raw Salmon', 9),
    ('Fishing', 'SPONGE', 'Sponge', 9),
  ];

  @override
  Future<PlayerProfile> loadProfile(Player player) async {
    await Future<void>.delayed(_delay);

    // Seeded with the player, so the same player always gets the same data.
    final seed = int.tryParse(player.uuid.substring(0, 7), radix: 16) ?? 0;
    final random = Random(seed);

    return PlayerProfile(
      player: player,
      profileName: _profileNames[random.nextInt(_profileNames.length)],
      isDemo: true,
      skills: [
        for (final (name, maxLevel) in _skills) _skill(name, maxLevel, random),
      ],
      collections: [
        for (final (category, id, name, maxTier) in _collections)
          _collection(category, id, name, maxTier, random),
      ],
    );
  }

  static SkillProgress _skill(String name, int maxLevel, Random random) {
    final level = random.nextInt(maxLevel + 1);

    return SkillProgress(
      name: name,
      level: level,
      maxLevel: maxLevel,
      progress: level == maxLevel ? 1 : random.nextDouble(),
      // Roughly the shape of the real curve: each level costs more.
      experience: level * level * level * 500 + random.nextInt(5000),
    );
  }

  static CollectionProgress _collection(
    String category,
    String itemId,
    String itemName,
    int maxTier,
    Random random,
  ) {
    final tier = random.nextInt(maxTier + 1);

    return CollectionProgress(
      category: category,
      itemName: itemName,
      iconUrl: CoflnetRemoteDatasource.iconUrl(itemId),
      // Each tier needs about 2.5 times more items than the one before.
      amount: (50 * pow(2.5, tier)).round() + random.nextInt(50),
      tier: tier,
      maxTier: maxTier,
    );
  }
}
