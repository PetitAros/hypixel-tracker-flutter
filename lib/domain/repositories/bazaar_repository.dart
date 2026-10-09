import 'package:hypixel_tracker/domain/entities/bazaar_snapshot.dart';

abstract interface class BazaarRepository {
  /// The last bazaar saved on disk, or null when nothing was saved yet.
  BazaarSnapshot? readCached();

  /// Fetches the bazaar from the network and saves it to disk.
  /// Throws when the network fails; the disk cache is left untouched.
  Future<BazaarSnapshot> refresh();
}
