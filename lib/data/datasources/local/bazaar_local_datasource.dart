import 'package:hive_ce/hive.dart';
import '../../models/bazaar_item_model.dart';

class BazaarLocalDatasource {
  final Box<BazaarItemModel> itemsBox;
  final Box<String> namesBox;
  final Box<dynamic> metaBox;

  BazaarLocalDatasource({
    required this.itemsBox,
    required this.namesBox,
    required this.metaBox,
  });

  static const _lastUpdatedKey = 'bazaar_last_updated';
  static const _namesUpdatedKey = 'item_names_last_updated';

  List<BazaarItemModel> read() => itemsBox.values.toList();

  DateTime? get lastUpdated => _readDate(_lastUpdatedKey);

  Future<void> save(List<BazaarItemModel> items, DateTime fetchedAt) async {
    // Write the new items before dropping the stale ones: if the app is killed
    // mid-save the box holds a mix of old and new items, never nothing.
    final fresh = {for (final item in items) item.productId: item};
    final stale = itemsBox.keys.where((key) => !fresh.containsKey(key)).toList();

    await itemsBox.putAll(fresh);
    await itemsBox.deleteAll(stale);
    await metaBox.put(_lastUpdatedKey, fetchedAt.millisecondsSinceEpoch);
  }

  /// Display names by item id, from the Hypixel items resource.
  Map<String, String> readNames() => namesBox.toMap().cast<String, String>();

  DateTime? get namesUpdated => _readDate(_namesUpdatedKey);

  Future<void> saveNames(Map<String, String> names, DateTime fetchedAt) async {
    await namesBox.putAll(names);
    await metaBox.put(_namesUpdatedKey, fetchedAt.millisecondsSinceEpoch);
  }

  DateTime? _readDate(String key) {
    final millis = metaBox.get(key) as int?;
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }
}
