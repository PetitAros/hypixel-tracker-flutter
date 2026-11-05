// SkyBlock time: a day lasts 20 real minutes, a month 31 days, a year
// 12 months (124 real hours). Year 1 started at [epoch].
class SkyblockCalendar {
  SkyblockCalendar._();

  static final epoch = DateTime.fromMillisecondsSinceEpoch(1560275700000);

  static const dayLength = Duration(minutes: 20);
  static const monthLength = Duration(minutes: 20 * 31);
  static const yearLength = Duration(minutes: 20 * 31 * 12);

  // Month indexes, Early Spring being 0.
  static const lateSpring = 2;
  static const lateSummer = 5;

  /// The first time after [after] that the calendar reaches [day] (from 1)
  /// of [month] (from 0), e.g. Late Spring 27.
  static DateTime next({
    required int month,
    required int day,
    required DateTime after,
  }) {
    final yearsDone =
        after.difference(epoch).inMilliseconds ~/ yearLength.inMilliseconds;
    final date = epoch.add(
      yearLength * yearsDone + monthLength * month + dayLength * (day - 1),
    );
    return date.isAfter(after) ? date : date.add(yearLength);
  }
}
