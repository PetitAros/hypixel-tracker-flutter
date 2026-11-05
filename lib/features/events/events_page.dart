import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/utils/formatters.dart';
import 'package:hypixel_tracker/core/utils/skyblock_calendar.dart';
import 'package:hypixel_tracker/core/widgets/countdown.dart';
import 'package:hypixel_tracker/core/widgets/fading_app_bar.dart';
import 'package:hypixel_tracker/core/widgets/skeleton.dart';
import 'package:hypixel_tracker/core/widgets/state_message.dart';
import 'package:hypixel_tracker/domain/entities/skyblock_events.dart';
import 'package:hypixel_tracker/domain/repositories/events_repository.dart';
import 'package:hypixel_tracker/features/events/events_controller.dart';

// The events tab: mayor and election, Bingo, fire sales. Loading it also
// refreshes the home screen widget and the scheduled alerts.
class EventsPage extends StatefulWidget {
  const EventsPage({super.key, required this.repository});

  final EventsRepository repository;

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late final EventsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EventsController(widget.repository)..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: FadingAppBar(
            title: 'Events',
            subtitle: switch (state) {
              EventsLoaded(:final events) =>
                'Updated ${Formatters.dateTime(events.fetchedAt)}',
              _ => null,
            },
          ),
          body: switch (state) {
            EventsLoading() => const SkeletonList(
              itemCount: 3,
              itemHeight: 120,
            ),
            EventsFailed() => StateMessage(
              text: 'Could not load the events. Check your connection.',
              onRetry: _controller.load,
            ),
            EventsLoaded(:final events) => RefreshIndicator(
              onRefresh: _controller.load,
              child: _EventsList(events: events),
            ),
          },
        );
      },
    );
  }
}

class _EventsList extends StatelessWidget {
  const _EventsList({required this.events});

  final SkyblockEvents events;

  @override
  Widget build(BuildContext context) {
    // Starts below the app bar and ends above the navigation bar.
    final inset = MediaQuery.paddingOf(context);
    final bingo = events.bingo;

    return ListView(
      // Pull to refresh works even when the list is short.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: inset.top + AppSpacing.sm,
        bottom: inset.bottom + AppSpacing.sm,
      ),
      children: [
        _NextEventCard(events: events),
        const _CalendarCard(),
        _MayorCard(events: events),
        if (bingo != null) _BingoCard(bingo: bingo),
        _FireSalesCard(sales: events.fireSales),
      ],
    );
  }
}

// The soonest event to come, with a big countdown. Moves on to the next one
// by itself when the time comes.
class _NextEventCard extends StatefulWidget {
  const _NextEventCard({required this.events});

  final SkyblockEvents events;

  @override
  State<_NextEventCard> createState() => _NextEventCardState();
}

class _NextEventCardState extends State<_NextEventCard> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final upcoming = widget.events.upcoming(
      now,
      calendar: SkyblockCalendar.events(now),
    );
    final next = upcoming.firstOrNull;

    // Rebuilds when this event is reached, to show the one after.
    _timer?.cancel();
    if (next != null) {
      _timer = Timer(next.at.difference(now), () {
        if (mounted) setState(() {});
      });
    }

    return _EventCard(
      icon: Icons.timer_outlined,
      title: 'Next event',
      children: [
        if (next == null)
          Text('Nothing scheduled.', style: textTheme.bodyLarge)
        else ...[
          Text(next.label, style: textTheme.bodyLarge),
          Countdown(
            endsAt: next.at,
            style: textTheme.headlineLarge?.copyWith(
              color: context.palette.accent,
            ),
          ),
          Text(Formatters.dateTime(next.at), style: textTheme.bodyMedium),
          // A glimpse of what follows.
          for (final later in upcoming.skip(1).take(_laterCount))
            Row(
              children: [
                Expanded(
                  child: Text(
                    later.label,
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Countdown(endsAt: later.at, style: textTheme.bodyMedium),
              ],
            ),
        ],
      ],
    );
  }

  static const _laterCount = 2;
}

// The SkyBlock calendar: each event with its countdown, or the time left
// while it is on. Computed locally, so it moves on by itself.
class _CalendarCard extends StatefulWidget {
  const _CalendarCard();

  @override
  State<_CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<_CalendarCard> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final events = SkyblockCalendar.events(now);

    // Rebuilds at the next start or end, to show the following occurrence.
    final changes = [
      for (final event in events) ...[event.start, event.end],
    ].where((time) => time.isAfter(now));
    _timer?.cancel();
    _timer = Timer(
      changes.reduce((a, b) => a.isBefore(b) ? a : b).difference(now),
      () {
        if (mounted) setState(() {});
      },
    );

    return _EventCard(
      icon: Icons.calendar_month,
      title: 'SkyBlock calendar',
      children: [
        for (final event in events)
          Row(
            children: [
              Expanded(
                child: Text(
                  event.name,
                  style: textTheme.bodyLarge?.copyWith(
                    color: event.isOn(now) ? context.palette.accent : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (event.isOn(now)) ...[
                Text('Now, ends in ', style: textTheme.bodyMedium),
                Countdown(endsAt: event.end, style: textTheme.bodyMedium),
              ] else
                Countdown(endsAt: event.start, style: textTheme.bodyMedium),
            ],
          ),
      ],
    );
  }
}

// A card with an icon and a title, then its content.
class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Row(
              children: [
                Icon(icon, color: context.palette.accent),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

// "Ends in 2d 4h", kept up to date.
class _TimeLine extends StatelessWidget {
  const _TimeLine({required this.label, required this.at});

  final String label;
  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;

    return Row(
      children: [
        Text('$label ', style: style),
        Countdown(
          endsAt: at,
          style: style?.copyWith(color: context.palette.accent),
        ),
      ],
    );
  }
}

class _MayorCard extends StatelessWidget {
  const _MayorCard({required this.events});

  final SkyblockEvents events;

  static const _barHeight = 6.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mayor = events.mayor;
    final election = events.election;

    return _EventCard(
      icon: Icons.account_balance,
      title: 'Mayor ${mayor.name}',
      children: [
        if (mayor.minister != null)
          Text('Minister ${mayor.minister}', style: textTheme.bodyLarge),
        if (mayor.perks.isNotEmpty)
          Text(mayor.perks.join(' · '), style: textTheme.bodyMedium),
        if (election == null)
          _TimeLine(label: 'Next election opens in', at: events.nextElectionAt)
        else ...[
          _TimeLine(label: 'Election closes in', at: events.termEndsAt),
          for (final candidate in election.candidates) ...[
            Row(
              children: [
                Expanded(
                  child: Text(candidate.name, style: textTheme.bodyLarge),
                ),
                Text(
                  '${Formatters.compact(candidate.votes)} votes',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
            LinearProgressIndicator(
              value: election.totalVotes == 0
                  ? 0
                  : candidate.votes / election.totalVotes,
              minHeight: _barHeight,
              borderRadius: AppRadius.sm,
              backgroundColor: context.palette.surface,
            ),
          ],
        ],
      ],
    );
  }
}

class _BingoCard extends StatelessWidget {
  const _BingoCard({required this.bingo});

  final BingoEvent bingo;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return _EventCard(
      icon: Icons.grid_on,
      title: 'Bingo ${bingo.name}',
      children: [
        if (now.isBefore(bingo.start))
          _TimeLine(label: 'Starts in', at: bingo.start)
        else if (now.isBefore(bingo.end))
          _TimeLine(label: 'Ends in', at: bingo.end)
        else
          Text('Ended', style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _FireSalesCard extends StatelessWidget {
  const _FireSalesCard({required this.sales});

  final List<FireSale> sales;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();

    return _EventCard(
      icon: Icons.local_fire_department,
      title: 'Fire sales',
      children: [
        if (sales.isEmpty)
          Text('No fire sale announced.', style: textTheme.bodyLarge),
        for (final sale in sales) ...[
          Text(sale.itemName, style: textTheme.bodyLarge),
          Text(
            '${Formatters.compact(sale.amount)} for sale · '
            '${Formatters.compact(sale.price)} gems',
            style: textTheme.bodyMedium,
          ),
          if (now.isBefore(sale.start))
            _TimeLine(label: 'Starts in', at: sale.start)
          else
            _TimeLine(label: 'Ends in', at: sale.end),
        ],
      ],
    );
  }
}
