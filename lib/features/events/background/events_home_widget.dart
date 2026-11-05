import 'package:home_widget/home_widget.dart';
import 'package:hypixel_tracker/core/utils/formatters.dart';
import 'package:hypixel_tracker/core/utils/skyblock_calendar.dart';
import 'package:hypixel_tracker/domain/entities/skyblock_events.dart';

// The Android home screen widget (EventsWidgetProvider.kt). Dart writes
// ready-to-show lines; the Kotlin side only puts them in the layout, except
// for the next event badge: Dart writes the coming events with their times,
// and Kotlin shows the first one not yet passed with a live countdown.
// Redraws are scheduled at each of those times so it moves on by itself.
class EventsHomeWidget {
  EventsHomeWidget._();

  static const _provider = 'io.lecomte.hypixel_tracker.EventsWidgetProvider';

  // The badge includes the hourly events (Dark Auction, Jacob's contests),
  // so the list must last well past the next background sync, which Android
  // may delay by hours.
  static const _nextHorizon = Duration(hours: 12);
  static const _nextCount = 40;

  static Future<void> update(SkyblockEvents events) async {
    final now = DateTime.now();
    final lines = {
      ..._mayorLines(events),
      ..._bingoLines(events.bingo, now),
      ..._fireSaleLines(events.fireSales, now),
      'updated': Formatters.dateTime(events.fetchedAt),
    };

    final next = _nextEvents(events, now).take(_nextCount).toList();
    // One "millis<TAB>label" per line, read by EventsWidgetProvider.kt.
    lines['next_events'] = [
      for (final event in next)
        '${event.at.millisecondsSinceEpoch}\t${event.label}',
    ].join('\n');

    for (final MapEntry(:key, :value) in lines.entries) {
      await HomeWidget.saveWidgetData<String>(key, value);
    }
    await HomeWidget.updateWidget(qualifiedAndroidName: _provider);
    await HomeWidget.scheduleWidgetUpdates([
      for (final event in next) event.at,
    ], qualifiedAndroidName: _provider);
  }

  // Election, Bingo and fire sales, plus every calendar event, frequent ones
  // included: the badge shows whatever comes first.
  static List<UpcomingEvent> _nextEvents(SkyblockEvents events, DateTime now) {
    final calendar = SkyblockCalendar.occurrences(now, within: _nextHorizon);

    return [
      ...events.upcoming(now),
      for (final event in calendar) ...[
        UpcomingEvent(
          // An instant, like the Dark Auction, just has its name.
          label: event.start == event.end ? event.name : '${event.name} starts',
          at: event.start,
        ),
        // A festival counts down to its end while it is on.
        if (!event.frequent)
          UpcomingEvent(label: '${event.name} ends', at: event.end),
      ],
    ].where((event) => event.at.isAfter(now)).toList()..sort(
      (a, b) => a.at.compareTo(b.at),
    );
  }

  static Map<String, String> _mayorLines(SkyblockEvents events) {
    final mayor = events.mayor;
    final election = events.election;
    final closes = Formatters.dateTime(events.termEndsAt);

    return {
      'mayor': mayor.minister == null
          ? 'Mayor ${mayor.name}'
          : 'Mayor ${mayor.name} · minister ${mayor.minister}',
      'mayor_detail': election == null
          ? 'Next election opens ${Formatters.dateTime(events.nextElectionAt)}'
          : election.candidates.isEmpty
          ? 'Election open, closes $closes'
          : 'Election closes $closes · ${election.candidates.first.name} leads',
    };
  }

  static Map<String, String> _bingoLines(BingoEvent? bingo, DateTime now) {
    if (bingo == null) return {'bingo': 'Bingo', 'bingo_detail': 'No event'};

    return {
      'bingo': 'Bingo ${bingo.name}',
      'bingo_detail': now.isBefore(bingo.start)
          ? 'Starts ${Formatters.dateTime(bingo.start)}'
          : now.isBefore(bingo.end)
          ? 'Ends ${Formatters.dateTime(bingo.end)}'
          : 'Ended',
    };
  }

  static Map<String, String> _fireSaleLines(
    List<FireSale> sales,
    DateTime now,
  ) {
    if (sales.isEmpty) {
      return {'fire_sale': 'Fire sales', 'fire_sale_detail': 'None announced'};
    }

    final sale = sales.first;
    final when = now.isBefore(sale.start)
        ? 'Starts ${Formatters.dateTime(sale.start)}'
        : 'Ends ${Formatters.dateTime(sale.end)}';
    final more = sales.length > 1 ? ' · +${sales.length - 1} more' : '';

    return {
      'fire_sale': 'Fire sale: ${sale.itemName}',
      'fire_sale_detail': '$when · ${sale.price} gems$more',
    };
  }
}
