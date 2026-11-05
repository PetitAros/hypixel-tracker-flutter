import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hypixel_tracker/data/datasources/remote/hypixel_remote_datasource.dart';
import 'package:hypixel_tracker/data/repositories/events_repository_impl.dart';
import 'package:hypixel_tracker/domain/entities/skyblock_events.dart';
import 'package:hypixel_tracker/features/events/background/events_home_widget.dart';
import 'package:hypixel_tracker/features/events/background/events_notifier.dart';
import 'package:workmanager/workmanager.dart';

// Keeps the home screen widget and the scheduled notifications up to date:
// every time the app loads the events, and every hour in the background
// (Android may run it later to save battery).
class EventsSync {
  EventsSync._();

  static const _taskName = 'skyblock_events_sync';
  static const _frequency = Duration(hours: 1);

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Call once at startup, before [publish].
  static Future<void> register() async {
    if (!_supported) return;

    await EventsNotifier.initialize();
    await Workmanager().initialize(eventsSyncDispatcher);
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: _frequency,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  /// Pushes fresh events to the widget and the notification schedule.
  static Future<void> publish(SkyblockEvents events) async {
    if (!_supported) return;

    await EventsHomeWidget.update(events);
    await EventsNotifier.update(events);
  }
}

// Runs in a background isolate, without the app: it builds its own
// repository.
@pragma('vm:entry-point')
void eventsSyncDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final client = http.Client();
    try {
      final repository = EventsRepositoryImpl(
        remote: HypixelRemoteDatasource(client: client),
      );
      await EventsNotifier.initialize();
      await EventsSync.publish(await repository.load());
      return true;
    } catch (_) {
      // WorkManager retries later.
      return false;
    } finally {
      client.close();
    }
  });
}
