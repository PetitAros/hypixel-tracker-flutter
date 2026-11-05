import 'package:hypixel_tracker/data/datasources/local/profile_local_datasource.dart';
import 'package:hypixel_tracker/data/datasources/remote/coflnet_remote_datasource.dart';
import 'package:hypixel_tracker/data/datasources/remote/hypixel_remote_datasource.dart';
import 'package:hypixel_tracker/data/datasources/remote/worker_remote_datasource.dart';
import 'package:hypixel_tracker/data/models/skyblock_profile_model.dart';
import 'package:hypixel_tracker/domain/entities/player.dart';
import 'package:hypixel_tracker/domain/entities/player_profiles.dart';
import 'package:hypixel_tracker/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final WorkerRemoteDatasource remote;
  final HypixelRemoteDatasource resources;
  final ProfileLocalDatasource local;

  ProfileRepositoryImpl({
    required this.remote,
    required this.resources,
    required this.local,
  });

  // Level and tier tables only change with game updates: once per launch.
  Future<List<SkillTableModel>>? _skillTables;
  Future<List<CollectionTableModel>>? _collectionTables;

  @override
  Future<PlayerProfile> loadProfile(Player player) async {
    try {
      final profile = await _fetch(player);
      await local.save(profile);
      return profile;
    } on NoSkyBlockProfileException {
      rethrow;
    } catch (_) {
      // Offline or Hypixel down: the last copy of this player, if any.
      final cached = local.read();
      if (cached == null || cached.player.uuid != player.uuid) rethrow;
      return cached;
    }
  }

  Future<PlayerProfile> _fetch(Player player) async {
    final pendingSkills = _skillTables ??= resources.getSkillTables();
    final pendingCollections = _collectionTables ??= resources
        .getCollectionTables();

    final SkyblockProfileModel? model;
    final List<SkillTableModel> skillTables;
    final List<CollectionTableModel> collectionTables;
    try {
      (model, skillTables, collectionTables) = await (
        remote.getSelectedProfile(player.uuid),
        pendingSkills,
        pendingCollections,
      ).wait;
    } on ParallelWaitError {
      // Fetch the tables again next time instead of keeping a failure.
      _skillTables = null;
      _collectionTables = null;
      rethrow;
    }

    if (model == null) throw const NoSkyBlockProfileException();

    return PlayerProfile(
      player: player,
      profileName: model.cuteName,
      fromCache: false,
      skills: [
        for (final table in skillTables)
          table.toEntity(model.experience[table.id] ?? 0),
      ],
      // Only the collections the player has started.
      collections: [
        for (final table in collectionTables)
          if (model.collection[table.itemId] case final amount?)
            table.toEntity(
              amount,
              iconUrl: CoflnetRemoteDatasource.iconUrl(table.itemId),
            ),
      ],
      forge: [
        for (final process in model.forge)
          process.toEntity(
            quickForgeLevel: model.quickForgeLevel,
            iconUrl: CoflnetRemoteDatasource.iconUrl(process.itemId),
          ),
      ],
    );
  }
}
