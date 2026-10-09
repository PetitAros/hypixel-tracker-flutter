import 'package:hypixel_tracker/data/datasources/remote/mojang_remote_datasource.dart';
import 'package:hypixel_tracker/domain/entities/player.dart';
import 'package:hypixel_tracker/domain/repositories/player_repository.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  final MojangRemoteDatasource remote;

  PlayerRepositoryImpl({required this.remote});

  @override
  Future<Player?> findByName(String name) => remote.getPlayerByName(name);
}
