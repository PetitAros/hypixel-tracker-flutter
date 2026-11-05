import 'package:hypixel_tracker/domain/entities/skyblock_events.dart';

// SkyBlock time: a day lasts 20 real minutes, a month 31 days, a year
// 12 months (124 real hours). Year 1 started at [epoch].
class SkyblockCalendar {
  SkyblockCalendar._();

  static final epoch = DateTime.fromMillisecondsSinceEpoch(1560275700000);

  static const hourLength = Duration(seconds: 50);
  static const dayLength = Duration(minutes: 20);
  static const monthLength = Duration(minutes: 20 * 31);
  static const yearLength = Duration(minutes: 20 * 31 * 12);

  // Month indexes, Early Spring being 0.
  static const lateSpring = 2;
  static const earlySummer = 3;
  static const lateSummer = 5;
  static const autumn = 7;
  static const earlyWinter = 9;
  static const lateWinter = 11;

  /// The first time after [after] that the calendar reaches [day] (from 1)
  /// of [month] (from 0), e.g. Late Spring 27.
  static DateTime next({
    required int month,
    required int day,
    required DateTime after,
  }) {
    return _nextRepeating(
      period: yearLength,
      offset: monthLength * month + dayLength * (day - 1),
      after: after,
    );
  }

  /// The events that come back on fixed SkyBlock dates, each at its current
  /// or next occurrence, the soonest first. Pure maths: no network needed.
  static List<CalendarEvent> events(DateTime now) {
    // Three SkyBlock days, i.e. one real hour.
    const threeDays = Duration(minutes: 60);

    CalendarEvent yearly(
      String name,
      List<(int, int)> dates, {
      Duration length = threeDays,
    }) {
      // Searching from `now - length` finds an occurrence still under way.
      final start = dates
          .map(
            (date) =>
                next(month: date.$1, day: date.$2, after: now.subtract(length)),
          )
          .reduce((a, b) => a.isBefore(b) ? a : b);
      return CalendarEvent(name: name, start: start, end: start.add(length));
    }

    CalendarEvent repeating(
      String name, {
      required Duration period,
      required Duration offset,
      required Duration length,
    }) {
      final start = _nextRepeating(
        period: period,
        offset: offset,
        after: now.subtract(length),
      );
      return CalendarEvent(
        name: name,
        start: start,
        end: start.add(length),
        frequent: true,
      );
    }

    // Days 7, 14, 21 and 28 of every month, from 00:00 to 06:00.
    const cultLength = Duration(minutes: 5);
    final cult = [
      for (final day in [7, 14, 21, 28])
        _nextRepeating(
          period: monthLength,
          offset: dayLength * (day - 1),
          after: now.subtract(cultLength),
        ),
    ].reduce((a, b) => a.isBefore(b) ? a : b);

    return [
      yearly('Traveling Zoo', [(earlySummer, 1), (earlyWinter, 1)]),
      yearly('Spooky Festival', [(autumn, 29)]),
      yearly('Season of Jerry', [(lateWinter, 24)]),
      yearly('New Year Celebration', [(lateWinter, 29)]),
      CalendarEvent(
        name: 'Cult of the Fallen Star',
        start: cult,
        end: cult.add(cultLength),
        frequent: true,
      ),
      // The epoch fell at :55, so the auction runs every hour at :55.
      repeating(
        'Dark Auction',
        period: threeDays,
        offset: Duration.zero,
        length: Duration.zero,
      ),
      // Every hour at :15, for 20 minutes.
      repeating(
        "Jacob's Farming Contest",
        period: threeDays,
        offset: dayLength,
        length: dayLength,
      ),
    ]..sort((a, b) => a.start.compareTo(b.start));
  }

  /// Every occurrence of every calendar event that is on at [now] or
  /// starts before `now + within`, the soonest first. Unlike [events], the
  /// frequent ones are there many times, e.g. each hourly Dark Auction.
  static List<CalendarEvent> occurrences(
    DateTime now, {
    required Duration within,
  }) {
    final until = now.add(within);
    final found = <String, CalendarEvent>{};

    // Steps from one start or end to the next, collecting what is on or
    // coming at each step.
    var time = now;
    while (time.isBefore(until)) {
      final current = events(time);
      for (final event in current) {
        if (event.start.isBefore(until)) {
          found['${event.name}@${event.start.millisecondsSinceEpoch}'] = event;
        }
      }
      time = [
        for (final event in current) ...[event.start, event.end],
      ].where((t) => t.isAfter(time)).reduce((a, b) => a.isBefore(b) ? a : b);
    }

    return found.values.toList()..sort((a, b) => a.start.compareTo(b.start));
  }

  // The first `epoch + offset + n * period` after [after].
  static DateTime _nextRepeating({
    required Duration period,
    required Duration offset,
    required DateTime after,
  }) {
    final periodsDone =
        after.difference(epoch.add(offset)).inMilliseconds ~/
        period.inMilliseconds;
    final date = epoch.add(offset + period * periodsDone);
    return date.isAfter(after) ? date : date.add(period);
  }
}
