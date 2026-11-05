import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:hypixel_tracker/core/theme/app_theme.dart';

import 'package:hypixel_tracker/core/storage/hive_boxes.dart';
import 'package:hypixel_tracker/data/datasources/local/auction_local_datasource.dart';
import 'package:hypixel_tracker/data/datasources/local/bazaar_local_datasource.dart';
import 'package:hypixel_tracker/data/datasources/local/preferences_local_datasource.dart';
import 'package:hypixel_tracker/data/datasources/local/profile_local_datasource.dart';
import 'package:hypixel_tracker/data/datasources/remote/coflnet_remote_datasource.dart';
import 'package:hypixel_tracker/data/datasources/remote/hypixel_remote_datasource.dart';
import 'package:hypixel_tracker/data/datasources/remote/mojang_remote_datasource.dart';
import 'package:hypixel_tracker/data/datasources/remote/worker_remote_datasource.dart';
import 'package:hypixel_tracker/data/models/auction_model.dart';
import 'package:hypixel_tracker/data/models/bazaar_item_model.dart';
import 'package:hypixel_tracker/data/repositories/auction_repository_impl.dart';
import 'package:hypixel_tracker/data/repositories/bazaar_repository_impl.dart';
import 'package:hypixel_tracker/data/repositories/events_repository_impl.dart';
import 'package:hypixel_tracker/data/repositories/market_repository_impl.dart';
import 'package:hypixel_tracker/data/repositories/player_repository_impl.dart';
import 'package:hypixel_tracker/data/repositories/profile_repository_impl.dart';
import 'package:hypixel_tracker/data/repositories/settings_repository_impl.dart';
import 'package:hypixel_tracker/domain/repositories/auction_repository.dart';
import 'package:hypixel_tracker/domain/repositories/bazaar_repository.dart';
import 'package:hypixel_tracker/domain/repositories/events_repository.dart';
import 'package:hypixel_tracker/domain/repositories/market_repository.dart';
import 'package:hypixel_tracker/domain/repositories/player_repository.dart';
import 'package:hypixel_tracker/features/events/background/events_sync.dart';
import 'package:hypixel_tracker/features/home/home_page.dart';
import 'package:hypixel_tracker/features/profile/profile_controller.dart';
import 'package:hypixel_tracker/features/settings/settings_controller.dart';

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

  final eventsRepository = EventsRepositoryImpl(remote: remote);

  // Home screen widget and alerts, refreshed in the background.
  await EventsSync.register();

  final preferences = PreferencesLocalDatasource(metaBox: metaBox);

  final marketRepository = MarketRepositoryImpl(
    remote: CoflnetRemoteDatasource(client: client),
    local: preferences,
  );

  final playerRepository = PlayerRepositoryImpl(
    remote: MojangRemoteDatasource(client: client),
    local: preferences,
  );

  final profileRepository = ProfileRepositoryImpl(
    remote: WorkerRemoteDatasource(client: client),
    resources: remote,
    local: ProfileLocalDatasource(metaBox: metaBox),
  );

  // App-wide state: the followed player and their SkyBlock progress.
  final profileController = ProfileController(
    profileRepository,
    playerRepository,
  )..restore();

  // App-wide state: the theme picked in the options tab.
  final settingsController = SettingsController(
    SettingsRepositoryImpl(local: preferences),
  );

  runApp(
    MyApp(
      bazaarRepository: bazaarRepository,
      auctionRepository: auctionRepository,
      eventsRepository: eventsRepository,
      marketRepository: marketRepository,
      playerRepository: playerRepository,
      profileController: profileController,
      settingsController: settingsController,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.bazaarRepository,
    required this.auctionRepository,
    required this.eventsRepository,
    required this.marketRepository,
    required this.playerRepository,
    required this.profileController,
    required this.settingsController,
  });

  final BazaarRepository bazaarRepository;
  final AuctionRepository auctionRepository;
  final EventsRepository eventsRepository;
  final MarketRepository marketRepository;
  final PlayerRepository playerRepository;
  final ProfileController profileController;
  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    // Above MaterialApp, so every page and pushed route can read it.
    return ProfileScope(
      controller: profileController,
      // Rebuilds the theme when the options change.
      child: ListenableBuilder(
        listenable: settingsController,
        builder: (context, _) => MaterialApp(
          title: 'Hypixel Tracker',
          theme: AppTheme.build(settingsController.settings),
          // A fade would rebuild every tab on each frame: switch at once.
          themeAnimationDuration: Duration.zero,
          home: HomePage(
            auctionRepository: auctionRepository,
            bazaarRepository: bazaarRepository,
            eventsRepository: eventsRepository,
            marketRepository: marketRepository,
            playerRepository: playerRepository,
            settingsController: settingsController,
          ),
        ),
      ),
    );
  }
}
