import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hypixel_tracker/core/utils/formatters.dart';
import 'package:hypixel_tracker/core/utils/skyblock_calendar.dart';
import 'package:hypixel_tracker/domain/entities/skyblock_events.dart';
import 'package:timezone/timezone.dart' as tz;

// Phone notifications for the SkyBlock events. Known times (a sale starting,
// the ballot opening...) are scheduled ahead with Android alarms, so they
// fire even when the app is closed. Each sync replaces the whole schedule.
class EventsNotifier {
  EventsNotifier._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'skyblock_events',
      'SkyBlock events',
      channelDescription: 'Fire sales, mayor elections and Bingo',
    ),
  );

  // Fixed ids, so a new schedule replaces the old one.
  static const _electionOpensId = 1;
  static const _newMayorId = 2;
  static const _bingoStartsId = 3;
  static const _bingoEndingId = 4;
  static const _testId = 5;
  static const _calendarId = 10; // + index of the festival
  static const _fireSaleStartsId = 100; // + index of the sale

  static const _bingoWarning = Duration(days: 1);

  // Fire sales already announced, kept next to the widget data.
  static const _seenFireSalesKey = 'seen_fire_sales';

  static Future<void> initialize() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  static Future<bool> areEnabled() async =>
      await _android?.areNotificationsEnabled() ?? false;

  /// Shows the Android 13+ permission prompt. True when granted.
  static Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? false;

  /// Right away, so the user can check alerts reach them.
  static Future<void> showTest() {
    return _plugin.show(
      id: _testId,
      title: 'Alerts are on',
      body: 'You will be told about fire sales, elections and Bingo.',
      notificationDetails: _details,
    );
  }

  static Future<void> update(SkyblockEvents events) async {
    await _announceNewFireSales(events.fireSales);

    await _plugin.cancelAllPendingNotifications();
    final now = DateTime.now();

    final election = events.election;
    if (election == null) {
      await _schedule(
        _electionOpensId,
        events.nextElectionAt,
        'Mayor election is open',
        'Go vote for the next mayor.',
      );
    } else {
      await _schedule(
        _newMayorId,
        events.termEndsAt,
        'The election is over',
        election.candidates.isEmpty
            ? 'A new mayor takes office.'
            : '${election.candidates.first.name} was leading at the last check.',
      );
    }

    final bingo = events.bingo;
    if (bingo != null) {
      if (bingo.start.isAfter(now)) {
        await _schedule(
          _bingoStartsId,
          bingo.start,
          'Bingo ${bingo.name} has started',
          'Fresh goals are waiting.',
        );
      }
      await _schedule(
        _bingoEndingId,
        bingo.end.subtract(_bingoWarning),
        'Bingo ends in 24 hours',
        'Last day to finish your ${bingo.name} card.',
      );
    }

    // Festivals only: the frequent events would mean an alert every hour.
    final festivals = SkyblockCalendar.events(now).where((e) => !e.frequent);
    for (final (i, festival) in festivals.indexed) {
      await _schedule(
        _calendarId + i,
        festival.start,
        '${festival.name} has started',
        'It lasts about an hour.',
      );
    }

    for (final (i, sale) in events.fireSales.indexed) {
      await _schedule(
        _fireSaleStartsId + i,
        sale.start,
        'Fire sale: ${sale.itemName}',
        '${sale.amount} for sale at ${sale.price} gems, '
            'until ${Formatters.dateTime(sale.end)}.',
      );
    }
  }

  // Right away, the first time a sale shows up in the API.
  static Future<void> _announceNewFireSales(List<FireSale> sales) async {
    final seen =
        (await HomeWidget.getWidgetData<String>(_seenFireSalesKey))
            ?.split(',')
            .toSet() ??
        {};
    final keys = {for (final sale in sales) _saleKey(sale): sale};

    for (final MapEntry(:key, value: sale) in keys.entries) {
      if (seen.contains(key)) continue;
      await _plugin.show(
        id: key.hashCode & 0x7fffffff,
        title: 'Fire sale announced: ${sale.itemName}',
        body:
            'Starts ${Formatters.dateTime(sale.start)}, '
            '${sale.amount} at ${sale.price} gems.',
        notificationDetails: _details,
      );
    }

    // Only the sales still listed, so the list does not grow forever.
    await HomeWidget.saveWidgetData<String>(
      _seenFireSalesKey,
      keys.keys.join(','),
    );
  }

  static String _saleKey(FireSale sale) =>
      '${sale.itemId}@${sale.start.millisecondsSinceEpoch}';

  // Inexact alarms: may fire a few minutes late, but need no special
  // permission. Times already passed are skipped.
  static Future<void> _schedule(
    int id,
    DateTime at,
    String title,
    String body,
  ) async {
    if (!at.isAfter(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(at, tz.UTC),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
    );
  }
}
