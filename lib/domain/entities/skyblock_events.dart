// An item sold for gems for a limited time, announced ahead.
class FireSale {
  final String itemId;
  final String itemName;
  final DateTime start;
  final DateTime end;
  final int amount; // copies for sale
  final int price; // in gems

  const FireSale({
    required this.itemId,
    required this.itemName,
    required this.start,
    required this.end,
    required this.amount,
    required this.price,
  });
}

class Mayor {
  final String name;
  final List<String> perks;
  final String? minister;

  const Mayor({required this.name, required this.perks, this.minister});
}

class Candidate {
  final String name;
  final int votes;

  const Candidate({required this.name, required this.votes});
}

// A ballot that is open right now.
class Election {
  final int year;

  /// From the most votes down.
  final List<Candidate> candidates;

  const Election({required this.year, required this.candidates});

  int get totalVotes => candidates.fold(0, (sum, c) => sum + c.votes);
}

// The monthly Bingo event.
class BingoEvent {
  final String name; // e.g. "November 2026"
  final DateTime start;
  final DateTime end;

  const BingoEvent({
    required this.name,
    required this.start,
    required this.end,
  });
}

// An event of the SkyBlock calendar, e.g. the Spooky Festival, at its
// current or next occurrence.
class CalendarEvent {
  final String name;
  final DateTime start;
  final DateTime end; // same as start for an instant, e.g. the Dark Auction

  /// Comes back at least every few hours: shown, but never alerted about.
  final bool frequent;

  const CalendarEvent({
    required this.name,
    required this.start,
    required this.end,
    this.frequent = false,
  });

  bool isOn(DateTime now) => !now.isBefore(start) && now.isBefore(end);
}

// A known moment to come, e.g. "Bingo ends" on the 12th.
class UpcomingEvent {
  final String label;
  final DateTime at;

  const UpcomingEvent({required this.label, required this.at});
}

// What is going on in SkyBlock: the mayor, the election, Bingo, fire sales.
class SkyblockEvents {
  final Mayor mayor;

  /// When the ballot closes and the next mayor takes office.
  final DateTime termEndsAt;

  /// Null between elections.
  final Election? election;

  /// When the next ballot opens. Only meaningful while [election] is null.
  final DateTime nextElectionAt;

  /// The current or last Bingo event, null if the API has none.
  final BingoEvent? bingo;

  /// Announced and running sales, the soonest first.
  final List<FireSale> fireSales;

  final DateTime fetchedAt;

  const SkyblockEvents({
    required this.mayor,
    required this.termEndsAt,
    required this.election,
    required this.nextElectionAt,
    required this.bingo,
    required this.fireSales,
    required this.fetchedAt,
  });

  /// Every known moment after [now], the soonest first. The [calendar]
  /// festivals are included too; the frequent calendar events are not.
  List<UpcomingEvent> upcoming(
    DateTime now, {
    List<CalendarEvent> calendar = const [],
  }) {
    final election = this.election;
    final bingo = this.bingo;

    return [
        if (election == null)
          UpcomingEvent(label: 'Mayor election opens', at: nextElectionAt)
        else
          UpcomingEvent(label: 'Election results', at: termEndsAt),
        if (bingo != null) ...[
          UpcomingEvent(label: 'Bingo ${bingo.name} starts', at: bingo.start),
          UpcomingEvent(label: 'Bingo ${bingo.name} ends', at: bingo.end),
        ],
        for (final sale in fireSales) ...[
          UpcomingEvent(label: 'Fire sale: ${sale.itemName}', at: sale.start),
          UpcomingEvent(label: '${sale.itemName} sale ends', at: sale.end),
        ],
        for (final event in calendar)
          if (!event.frequent) ...[
            UpcomingEvent(label: '${event.name} starts', at: event.start),
            UpcomingEvent(label: '${event.name} ends', at: event.end),
          ],
      ].where((event) => event.at.isAfter(now)).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
  }
}
