import 'package:hypixel_tracker/core/utils/skyblock_calendar.dart';
import 'package:hypixel_tracker/data/datasources/remote/hypixel_remote_datasource.dart';
import 'package:hypixel_tracker/domain/entities/skyblock_events.dart';
import 'package:hypixel_tracker/domain/repositories/events_repository.dart';

// No disk cache: the events change on their own schedule, and the home
// screen widget already keeps the last copy.
class EventsRepositoryImpl implements EventsRepository {
  final HypixelRemoteDatasource remote;

  EventsRepositoryImpl({required this.remote});

  // The ballot opens on Late Summer 27 and closes on Late Spring 27 of the
  // following year, when the winner takes office.
  static const _electionDay = 27;

  @override
  Future<SkyblockEvents> load() async {
    final (fireSales, election, bingo) = await (
      remote.getFireSales(),
      remote.getElection(),
      remote.getBingo(),
    ).wait;
    final now = DateTime.now();

    return SkyblockEvents(
      mayor: election.mayor,
      termEndsAt: SkyblockCalendar.next(
        month: SkyblockCalendar.lateSpring,
        day: _electionDay,
        after: now,
      ),
      election: election.current,
      nextElectionAt: SkyblockCalendar.next(
        month: SkyblockCalendar.lateSummer,
        day: _electionDay,
        after: now,
      ),
      bingo: bingo,
      fireSales: [
        for (final sale in fireSales)
          if (sale.end > now.millisecondsSinceEpoch) sale.toEntity(),
      ]..sort((a, b) => a.start.compareTo(b.start)),
      fetchedAt: now,
    );
  }
}
