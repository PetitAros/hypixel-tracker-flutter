import '../../domain/entities/bazaar_item.dart';
import '../../domain/entities/bazaar_snapshot.dart';
import '../../domain/repositories/bazaar_repository.dart';
import '../datasources/local/bazaar_local_datasource.dart';
import '../datasources/remote/hypixel_remote_datasource.dart';
import '../models/bazaar_item_model.dart';

class BazaarRepositoryImpl implements BazaarRepository {
  final HypixelRemoteDatasource remote;
  final BazaarLocalDatasource local;

  BazaarRepositoryImpl({required this.remote, required this.local});

  // Item names rarely change, so one fetch a day is enough.
  static const _namesMaxAge = Duration(days: 1);

  @override
  BazaarSnapshot? readCached() {
    final cached = local.read();
    final lastUpdated = local.lastUpdated;
    if (cached.isEmpty || lastUpdated == null) return null;

    return BazaarSnapshot(
      items: _toEntities(cached, local.readNames()),
      lastUpdated: lastUpdated,
      fromCache: true,
    );
  }

  @override
  Future<BazaarSnapshot> refresh() async {
    final pendingNames = _itemNames();
    final models = await remote.getBazaar();
    final names = await pendingNames;

    final fetchedAt = DateTime.now();
    await local.save(models, fetchedAt);

    return BazaarSnapshot(
      items: _toEntities(models, names),
      lastUpdated: fetchedAt,
      fromCache: false,
    );
  }

  // Never throws: without names the bazaar still works with prettified ids.
  Future<Map<String, String>> _itemNames() async {
    final cached = local.readNames();
    final updated = local.namesUpdated;
    final isFresh =
        updated != null && DateTime.now().difference(updated) < _namesMaxAge;
    if (cached.isNotEmpty && isFresh) return cached;

    try {
      final names = await remote.getItemNames();
      await local.saveNames(names, DateTime.now());
      return names;
    } catch (_) {
      return cached;
    }
  }

  static List<BazaarItem> _toEntities(
    List<BazaarItemModel> models,
    Map<String, String> names,
  ) {
    return models
        .map((model) => model.toEntity(name: names[model.productId]))
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }
}
