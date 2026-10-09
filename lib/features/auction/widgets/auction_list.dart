import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/domain/entities/auction.dart';
import 'package:hypixel_tracker/features/auction/widgets/auction_card.dart';

// What the last row of the list has to say.
enum AuctionListEnd { loading, failed, paused, done }

// An infinite list: it asks for more auctions when the user nears its end.
class AuctionList extends StatelessWidget {
  const AuctionList({
    super.key,
    required this.auctions,
    required this.end,
    required this.onLoadMore,
    required this.onContinue,
    required this.onTap,
  });

  final List<Auction> auctions;
  final AuctionListEnd end;
  final VoidCallback onLoadMore;

  /// The button shown after a failure or a pause.
  final VoidCallback onContinue;
  final ValueChanged<Auction> onTap;

  // Ask for more this far before the end, so the user rarely sees the spinner.
  static const _loadMoreDistance = 400.0;

  bool _onMetrics(ScrollMetrics metrics) {
    if (end == AuctionListEnd.loading &&
        metrics.extentAfter < _loadMoreDistance) {
      onLoadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Scroll notifications cover scrolling; metrics notifications cover a
    // list too short to scroll, which would otherwise never load more.
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) => _onMetrics(notification.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) => _onMetrics(notification.metrics),
        child: ListView.builder(
          // Keeps pull-to-refresh working when the list is shorter than the
          // screen.
          physics: const AlwaysScrollableScrollPhysics(),
          // No padding given: the list takes it from MediaQuery, so it starts
          // below the app bar and ends above the navigation bar.
          itemCount: auctions.length + 1,
          itemBuilder: (context, index) {
            if (index == auctions.length) {
              return _Footer(
                end: end,
                isEmpty: auctions.isEmpty,
                onContinue: onContinue,
              );
            }
            final auction = auctions[index];
            return AuctionCard(auction: auction, onTap: () => onTap(auction));
          },
        ),
      ),
    );
  }
}

// The last row: loading the next auctions, a failure, a pause, or the end.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.end,
    required this.isEmpty,
    required this.onContinue,
  });

  final AuctionListEnd end;
  final bool isEmpty;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget withButton(String text, String button) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        ElevatedButton(onPressed: onContinue, child: Text(button)),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: switch (end) {
          AuctionListEnd.loading => const CircularProgressIndicator(),
          AuctionListEnd.failed => withButton(
            'Could not load more auctions.',
            'Retry',
          ),
          AuctionListEnd.paused => withButton(
            'Nothing more matches these filters in the auctions loaded so far.',
            'Search further',
          ),
          AuctionListEnd.done => Text(
            isEmpty ? 'No auction matches these filters.' : 'No more auctions.',
            style: textTheme.bodyMedium,
          ),
        },
      ),
    );
  }
}
