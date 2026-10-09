import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/theme/rarity_color.dart';
import 'package:hypixel_tracker/core/utils/formatters.dart';
import 'package:hypixel_tracker/core/widgets/countdown.dart';
import 'package:hypixel_tracker/domain/entities/auction.dart';

// The details of one auction, shown in a bottom sheet, with a way to see
// every auction of the same item.
class AuctionSheet extends StatefulWidget {
  const AuctionSheet({
    super.key,
    required this.auction,
    required this.onSeeItem,
  });

  final Auction auction;

  /// Finds the item and opens its auctions. Throws when it cannot.
  final Future<void> Function() onSeeItem;

  static Future<void> show(
    BuildContext context, {
    required Auction auction,
    required Future<void> Function() onSeeItem,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) =>
          AuctionSheet(auction: auction, onSeeItem: onSeeItem),
    );
  }

  @override
  State<AuctionSheet> createState() => _AuctionSheetState();
}

class _AuctionSheetState extends State<AuctionSheet> {
  bool _searching = false;
  bool _failed = false;

  Future<void> _seeItem() async {
    setState(() {
      _searching = true;
      _failed = false;
    });
    try {
      await widget.onSeeItem();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  // "VERY_SPECIAL" -> "VERY SPECIAL", "misc" -> "Misc"
  static String _capitalised(String value) {
    return value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final auction = widget.auction;

    Widget row(String label, Widget value) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.bodyMedium)),
          value,
        ],
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(auction.itemName, style: textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              auction.tier.replaceAll('_', ' '),
              style: textTheme.bodyLarge?.copyWith(
                color: rarityColor(auction.tier),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            row(
              auction.isBin ? 'Buy It Now price' : 'Current bid',
              Text(
                '${Formatters.compact(auction.price)} coins',
                style: textTheme.bodyLarge,
              ),
            ),
            row(
              'Category',
              Text(_capitalised(auction.category), style: textTheme.bodyLarge),
            ),
            row(
              'Ends in',
              Countdown(endsAt: auction.endsAt, style: textTheme.bodyLarge),
            ),
            row(
              'Ends on',
              Text(
                Formatters.dateTime(auction.endsAt),
                style: textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_failed)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  'Could not find this item. Check your connection.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _searching ? null : _seeItem,
                child: Text(
                  _searching
                      ? 'Looking for the item...'
                      : 'See all auctions of this item',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
