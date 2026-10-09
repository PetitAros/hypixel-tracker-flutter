import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/theme/rarity_color.dart';
import 'package:hypixel_tracker/core/utils/formatters.dart';
import 'package:hypixel_tracker/core/widgets/countdown.dart';
import 'package:hypixel_tracker/domain/entities/auction.dart';

class AuctionCard extends StatelessWidget {
  const AuctionCard({super.key, required this.auction, required this.onTap});

  final Auction auction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      // Clips the tap ripple to the rounded corners.
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction.itemName,
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      auction.tier.replaceAll('_', ' '),
                      style: textTheme.bodyMedium?.copyWith(
                        color: rarityColor(auction.tier),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${auction.isBin ? 'BIN' : 'Bid'} '
                    '${Formatters.compact(auction.price)}',
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Countdown(
                    endsAt: auction.endsAt,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
