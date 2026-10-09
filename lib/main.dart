import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:hypixel_tracker/core/theme/app_theme.dart';

import 'core/storage/hive_boxes.dart';
import 'data/datasources/local/bazaar_local_datasource.dart';
import 'data/datasources/remote/hypixel_remote_datasource.dart';
import 'data/models/bazaar_item_model.dart';
import 'data/repositories/bazaar_repository_impl.dart';
import 'domain/repositories/bazaar_repository.dart';
import 'features/bazaar/bazaar_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(BazaarItemModelAdapter());

  final bazaarRepository = BazaarRepositoryImpl(
    remote: HypixelRemoteDatasource(client: http.Client()),
    local: BazaarLocalDatasource(
      itemsBox: await Hive.openBox<BazaarItemModel>(HiveBoxes.bazaar),
      namesBox: await Hive.openBox<String>(HiveBoxes.itemNames),
      metaBox: await Hive.openBox<dynamic>(HiveBoxes.meta),
    ),
  );

  runApp(MyApp(bazaarRepository: bazaarRepository));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.bazaarRepository});

  final BazaarRepository bazaarRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hypixel Tracker',
      theme: AppTheme.dark,
      home: BazaarPage(repository: bazaarRepository),
    );
  }
}
