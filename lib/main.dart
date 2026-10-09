import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:hypixel_tracker/core/theme/app_theme.dart';

import 'package:hypixel_tracker/core/storage/hive_boxes.dart';
import 'package:hypixel_tracker/data/datasources/local/auction_local_datasource.dart';
import 'package:hypixel_tracker/data/datasources/local/bazaar_local_datasource.dart';
import 'package:hypixel_tracker/data/datasources/remote/coflnet_remote_datasource.dart';
import 'package:hypixel_tracker/data/datasources/remote/hypixel_remote_datasource.dart';
import 'package:hypixel_tracker/data/datasources/remote/mojang_remote_datasource.dart';
import 'package:hypixel_tracker/data/models/auction_model.dart';
import 'package:hypixel_tracker/data/models/bazaar_item_model.dart';
import 'package:hypixel_tracker/data/repositories/auction_repository_impl.dart';
import 'package:hypixel_tracker/data/repositories/bazaar_repository_impl.dart';
import 'package:hypixel_tracker/data/repositories/fake_profile_repository.dart';
import 'package:hypixel_tracker/data/repositories/market_repository_impl.dart';
import 'package:hypixel_tracker/data/repositories/player_repository_impl.dart';
import 'package:hypixel_tracker/domain/repositories/auction_repository.dart';
import 'package:hypixel_tracker/domain/repositories/bazaar_repository.dart';
import 'package:hypixel_tracker/domain/repositories/market_repository.dart';
import 'package:hypixel_tracker/domain/repositories/player_repository.dart';
import 'package:hypixel_tracker/features/home/home_page.dart';
import 'package:hypixel_tracker/features/profile/profile_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(BazaarItemModelAdapter());
  Hive.registerAdapter(AuctionModelAdapter());

  final client = http.Client();
  final remote = HypixelRemoteDatasource(client: client);
  final metaBox = await Hive.openBox<dynamic>(HiveBoxes.meta);

  final bazaarRepository = BazaarRepositoryImpl(
    remote: remote,
    local: BazaarLocalDatasource(
      itemsBox: await Hive.openBox<BazaarItemModel>(HiveBoxes.bazaar),
      namesBox: await Hive.openBox<String>(HiveBoxes.itemNames),
      collectionsBox: await Hive.openBox<String>(HiveBoxes.collections),
      metaBox: metaBox,
    ),
  );

  final auctionRepository = AuctionRepositoryImpl(
    remote: remote,
    local: AuctionLocalDatasource(
      auctionsBox: await Hive.openBox<AuctionModel>(HiveBoxes.auctions),
      metaBox: metaBox,
    ),
  );

  final marketRepository = MarketRepositoryImpl(
    remote: CoflnetRemoteDatasource(client: client),
  );

  final playerRepository = PlayerRepositoryImpl(
    remote: MojangRemoteDatasource(client: client),
  );

  // App-wide state: the followed player and their SkyBlock progress.
  // Fake data until the Hypixel key is there.
  final profileController = ProfileController(FakeProfileRepository());

  runApp(
    MyApp(
      bazaarRepository: bazaarRepository,
      auctionRepository: auctionRepository,
      marketRepository: marketRepository,
      playerRepository: playerRepository,
      profileController: profileController,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.bazaarRepository,
    required this.auctionRepository,
    required this.marketRepository,
    required this.playerRepository,
    required this.profileController,
  });

  final BazaarRepository bazaarRepository;
  final AuctionRepository auctionRepository;
  final MarketRepository marketRepository;
  final PlayerRepository playerRepository;
  final ProfileController profileController;

  @override
  Widget build(BuildContext context) {
    // Above MaterialApp, so every page and pushed route can read it.
    return ProfileScope(
      controller: profileController,
      child: MaterialApp(
        title: 'Hypixel Tracker',
        theme: AppTheme.dark,
        home: HomePage(
          auctionRepository: auctionRepository,
          bazaarRepository: bazaarRepository,
          marketRepository: marketRepository,
          playerRepository: playerRepository,
        ),
      ),
    );
  }
}
