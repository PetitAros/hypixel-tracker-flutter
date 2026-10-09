import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/domain/entities/auction.dart';
import 'package:hypixel_tracker/features/auction/widgets/auction_card.dart';

// An infinite list: it asks for more auctions when the user nears its end.
class AuctionList extends StatelessWidget {
  const AuctionList({
    super.key,
    required this.auctions,
    required this.hasMore,
    required this.loadMoreFailed,
    required this.onLoadMore,
    required this.onRetry,
  });

  final List<Auction> auctions;
  final bool hasMore;
  final bool loadMoreFailed;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  // Ask for more this far before the end, so the user rarely sees the spinner.
  static const _loadMoreDistance = 400.0;

  bool _onMetrics(ScrollMetrics metrics) {
    if (hasMore && metrics.extentAfter < _loadMoreDistance) onLoadMore();
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
          itemBuilder: (context, index) => index < auctions.length
              ? AuctionCard(auction: auctions[index])
              : _Footer(
                  hasMore: hasMore,
                  failed: loadMoreFailed,
                  onRetry: onRetry,
                ),
        ),
      ),
    );
  }
}

// The last row: loading the next auctions, a failure, or the end.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.hasMore,
    required this.failed,
    required this.onRetry,
  });

  final bool hasMore;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: switch ((hasMore, failed)) {
          (false, _) => Text('No more auctions.', style: textTheme.bodyMedium),
          (true, false) => const CircularProgressIndicator(),
          (true, true) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Could not load more auctions.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        },
      ),
    );
  }
}
