import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/utils/formatters.dart';
import 'package:hypixel_tracker/core/widgets/async_view.dart';
import 'package:hypixel_tracker/core/widgets/coflnet_credit.dart';
import 'package:hypixel_tracker/core/widgets/countdown.dart';
import 'package:hypixel_tracker/core/widgets/fading_app_bar.dart';
import 'package:hypixel_tracker/domain/entities/item_auction.dart';
import 'package:hypixel_tracker/domain/entities/item_summary.dart';
import 'package:hypixel_tracker/domain/repositories/market_repository.dart';

// The active auctions of one item picked from the search.
class ItemAuctionsPage extends StatelessWidget {
  const ItemAuctionsPage({
    super.key,
    required this.item,
    required this.repository,
  });

  final ItemSummary item;
  final MarketRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FadingAppBar(title: item.name),
      body: Column(
        children: [
          Expanded(
            child: AsyncView<List<ItemAuction>>(
              load: () => repository.activeAuctions(item.id),
              isEmpty: (auctions) => auctions.isEmpty,
              emptyText: 'No active auctions for this item.',
              errorText: 'Could not load the auctions. Check your connection.',
              builder: (context, auctions) => ListView.builder(
                // Keeps pull-to-refresh working on a short list.
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top,
                  bottom: AppSpacing.sm,
                ),
                itemCount: auctions.length,
                itemBuilder: (context, index) =>
                    _ItemAuctionCard(auction: auctions[index]),
              ),
            ),
          ),
          CoflnetCredit(itemTag: item.id),
        ],
      ),
    );
  }
}

class _ItemAuctionCard extends StatelessWidget {
  const _ItemAuctionCard({required this.auction});

  final ItemAuction auction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.compact(auction.price),
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Sold by ${auction.sellerName}',
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Countdown(endsAt: auction.endsAt, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
