import 'package:hive_ce/hive.dart';
import 'package:hypixel_tracker/domain/entities/app_settings.dart';
import 'package:hypixel_tracker/domain/entities/item_summary.dart';
import 'package:hypixel_tracker/domain/entities/player.dart';

// Small things the app remembers between launches, in the meta box.
// Stored as plain maps: too little data to deserve Hive adapters.
class PreferencesLocalDatasource {
  final Box<dynamic> metaBox;

  PreferencesLocalDatasource({required this.metaBox});

  static const _followedPlayerKey = 'followed_player';
  static const _recentItemsKey = 'recent_items';
  static const _settingsKey = 'settings';

  Player? readFollowedPlayer() {
    final saved = metaBox.get(_followedPlayerKey);
    if (saved is! Map) return null;

    final uuid = saved['uuid'];
    final name = saved['name'];
    if (uuid is! String || name is! String) return null;
    return Player(uuid: uuid, name: name);
  }

  Future<void> saveFollowedPlayer(Player? player) {
    if (player == null) return metaBox.delete(_followedPlayerKey);

    return metaBox.put(_followedPlayerKey, {
      'uuid': player.uuid,
      'name': player.name,
    });
  }

  /// Stored by enum name, so reordering the enums keeps the choice.
  AppSettings readSettings() {
    final saved = metaBox.get(_settingsKey);
    if (saved is! Map) return AppSettings.defaults;

    return AppSettings(
      brightness:
          AppBrightness.values.asNameMap()[saved['brightness']] ??
          AppSettings.defaults.brightness,
      accent:
          AppAccent.values.asNameMap()[saved['accent']] ??
          AppSettings.defaults.accent,
    );
  }

  Future<void> saveSettings(AppSettings settings) {
    return metaBox.put(_settingsKey, {
      'brightness': settings.brightness.name,
      'accent': settings.accent.name,
    });
  }

  List<ItemSummary> readRecentItems() {
    final saved = metaBox.get(_recentItemsKey);
    if (saved is! List) return const [];

    return [
      for (final item in saved)
        if (item is Map && item['id'] is String && item['name'] is String)
          ItemSummary(
            id: item['id'] as String,
            name: item['name'] as String,
            tier: item['tier'] as String? ?? 'UNKNOWN',
            iconUrl: item['iconUrl'] as String?,
          ),
    ];
  }

  Future<void> saveRecentItems(List<ItemSummary> items) {
    return metaBox.put(_recentItemsKey, [
      for (final item in items)
        {
          'id': item.id,
          'name': item.name,
          'tier': item.tier,
          'iconUrl': item.iconUrl,
        },
    ]);
  }
}
