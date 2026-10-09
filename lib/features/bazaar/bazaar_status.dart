import 'package:hypixel_tracker/core/utils/formatters.dart';
import 'package:hypixel_tracker/features/bazaar/bazaar_controller.dart';

// The line shown under the title of the bazaar pages:
// refresh in progress, last update, or offline. Null when there is no data.
({String text, bool offline})? bazaarStatus(BazaarState state) {
  if (state is! BazaarData) return null;
  final updated = Formatters.dateTime(state.snapshot.lastUpdated);

  return switch (state.sync) {
    BazaarSync.refreshing => (
      text: 'Refreshing. Showing data from $updated',
      offline: false,
    ),
    BazaarSync.upToDate => (text: 'Updated $updated', offline: false),
    BazaarSync.offline => (
      text: 'Offline. Showing saved data from $updated',
      offline: true,
    ),
  };
}
