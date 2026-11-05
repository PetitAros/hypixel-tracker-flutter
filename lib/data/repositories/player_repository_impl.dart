import 'package:hypixel_tracker/data/datasources/local/preferences_local_datasource.dart';
import 'package:hypixel_tracker/data/datasources/remote/mojang_remote_datasource.dart';
import 'package:hypixel_tracker/domain/entities/player.dart';
import 'package:hypixel_tracker/domain/entities/player_skin.dart';
import 'package:hypixel_tracker/domain/repositories/player_repository.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  final MojangRemoteDatasource remote;
  final PreferencesLocalDatasource local;

  PlayerRepositoryImpl({required this.remote, required this.local});

  @override
  Future<Player?> findByName(String name) => remote.getPlayerByName(name);

  @override
  Player? readFollowed() => local.readFollowedPlayer();

  @override
  Future<void> saveFollowed(Player? player) {
    return local.saveFollowedPlayer(player);
  }

  @override
  Future<PlayerSkin?> loadSkin(Player player) => remote.getSkin(player.uuid);
}
