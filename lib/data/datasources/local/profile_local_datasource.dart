import 'package:hive_ce/hive.dart';
import 'package:hypixel_tracker/domain/entities/player.dart';
import 'package:hypixel_tracker/domain/entities/player_profiles.dart';

// The last profile loaded, so the profile tab still works offline.
// One profile only, the followed player's: loading another player replaces it.
// Stored as plain maps in the meta box, like the preferences.
class ProfileLocalDatasource {
  final Box<dynamic> metaBox;

  ProfileLocalDatasource({required this.metaBox});

  static const _profileKey = 'followed_profile';

  /// The saved profile, marked as coming from the cache. Null when none.
  PlayerProfile? read() {
    final saved = metaBox.get(_profileKey);
    if (saved is! Map) return null;

    try {
      return PlayerProfile(
        player: Player(
          uuid: saved['uuid'] as String,
          name: saved['name'] as String,
        ),
        profileName: saved['profileName'] as String,
        fromCache: true,
        skills: [
          for (final skill in saved['skills'] as List)
            SkillProgress(
              name: skill['name'] as String,
              level: skill['level'] as int,
              maxLevel: skill['maxLevel'] as int,
              progress: skill['progress'] as double,
              experience: skill['experience'] as int,
            ),
        ],
        collections: [
          for (final collection in saved['collections'] as List)
            CollectionProgress(
              category: collection['category'] as String,
              itemName: collection['itemName'] as String,
              iconUrl: collection['iconUrl'] as String,
              amount: collection['amount'] as int,
              tier: collection['tier'] as int,
              maxTier: collection['maxTier'] as int,
            ),
        ],
        // Missing from copies saved before the forge was tracked.
        forge: [
          for (final slot in saved['forge'] as List? ?? const [])
            ForgeSlot(
              slot: slot['slot'] as int,
              itemName: slot['itemName'] as String,
              iconUrl: slot['iconUrl'] as String,
              startedAt: DateTime.fromMillisecondsSinceEpoch(
                slot['startedAt'] as int,
              ),
              readyAt: switch (slot['readyAt']) {
                final int millis => DateTime.fromMillisecondsSinceEpoch(millis),
                _ => null,
              },
            ),
        ],
      );
    } on TypeError {
      // Saved by an older version of the app.
      return null;
    }
  }

  Future<void> save(PlayerProfile profile) {
    return metaBox.put(_profileKey, {
      'uuid': profile.player.uuid,
      'name': profile.player.name,
      'profileName': profile.profileName,
      'skills': [
        for (final skill in profile.skills)
          {
            'name': skill.name,
            'level': skill.level,
            'maxLevel': skill.maxLevel,
            'progress': skill.progress,
            'experience': skill.experience,
          },
      ],
      'collections': [
        for (final collection in profile.collections)
          {
            'category': collection.category,
            'itemName': collection.itemName,
            'iconUrl': collection.iconUrl,
            'amount': collection.amount,
            'tier': collection.tier,
            'maxTier': collection.maxTier,
          },
      ],
      'forge': [
        for (final slot in profile.forge)
          {
            'slot': slot.slot,
            'itemName': slot.itemName,
            'iconUrl': slot.iconUrl,
            'startedAt': slot.startedAt.millisecondsSinceEpoch,
            'readyAt': slot.readyAt?.millisecondsSinceEpoch,
          },
      ],
    });
  }
}
