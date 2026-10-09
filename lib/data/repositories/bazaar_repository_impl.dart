import 'package:hypixel_tracker/data/datasources/local/bazaar_local_datasource.dart';
import 'package:hypixel_tracker/data/datasources/remote/coflnet_remote_datasource.dart';
import 'package:hypixel_tracker/data/datasources/remote/hypixel_remote_datasource.dart';
import 'package:hypixel_tracker/data/models/bazaar_category_sorter.dart';
import 'package:hypixel_tracker/data/models/bazaar_item_model.dart';
import 'package:hypixel_tracker/domain/entities/bazaar_item.dart';
import 'package:hypixel_tracker/domain/entities/bazaar_snapshot.dart';
import 'package:hypixel_tracker/domain/repositories/bazaar_repository.dart';

class BazaarRepositoryImpl implements BazaarRepository {
  final HypixelRemoteDatasource remote;
  final BazaarLocalDatasource local;

  BazaarRepositoryImpl({required this.remote, required this.local});

  // Item names and collections rarely change, so one fetch a day is enough.
  static const _resourceMaxAge = Duration(days: 1);

  @override
  BazaarSnapshot? readCached() {
    final cached = local.read();
    final lastUpdated = local.lastUpdated;
    if (cached.isEmpty || lastUpdated == null) return null;

    return BazaarSnapshot(
      items: _toEntities(cached, local.readNames(), local.readCollections()),
      lastUpdated: lastUpdated,
      fromCache: true,
    );
  }

  @override
  Future<BazaarSnapshot> refresh() async {
    final pendingNames = _dailyResource(
      cached: local.readNames(),
      updated: local.namesUpdated,
      fetch: remote.getItemNames,
      save: local.saveNames,
    );
    final pendingCollections = _dailyResource(
      cached: local.readCollections(),
      updated: local.collectionsUpdated,
      fetch: remote.getCollectionGroups,
      save: local.saveCollections,
    );

    final models = await remote.getBazaar();
    final names = await pendingNames;
    final collections = await pendingCollections;

    final fetchedAt = DateTime.now();
    await local.save(models, fetchedAt);

    return BazaarSnapshot(
      items: _toEntities(models, names, collections),
      lastUpdated: fetchedAt,
      fromCache: false,
    );
  }

  // Never throws: without it the bazaar still works, with prettified ids
  // for names and everything unsorted in Oddities for collections.
  Future<Map<String, String>> _dailyResource({
    required Map<String, String> cached,
    required DateTime? updated,
    required Future<Map<String, String>> Function() fetch,
    required Future<void> Function(Map<String, String>, DateTime) save,
  }) async {
    final isFresh =
        updated != null && DateTime.now().difference(updated) < _resourceMaxAge;
    if (cached.isNotEmpty && isFresh) return cached;

    try {
      final fetched = await fetch();
      await save(fetched, DateTime.now());
      return fetched;
    } catch (_) {
      return cached;
    }
  }

  static List<BazaarItem> _toEntities(
    List<BazaarItemModel> models,
    Map<String, String> names,
    Map<String, String> collections,
  ) {
    final sorter = BazaarCategorySorter(collections);

    return models
        .map(
          (model) => model.toEntity(
            name: names[model.productId],
            category: sorter.categoryOf(model.productId),
            iconUrl: CoflnetRemoteDatasource.iconUrl(model.productId),
          ),
        )
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }
}
