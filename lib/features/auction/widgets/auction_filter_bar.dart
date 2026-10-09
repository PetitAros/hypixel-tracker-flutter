import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/widgets/menu_chip.dart';
import 'package:hypixel_tracker/features/auction/auction_controller.dart';

// The row of chips under the search: BIN only, rarity and sort order.
// Sized to sit in the bottom slot of a FadingAppBar.
class AuctionFilterBar extends StatelessWidget implements PreferredSizeWidget {
  const AuctionFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final AuctionFilter filter;
  final ValueChanged<AuctionFilter> onChanged;

  static const height = 48.0;

  // Hypixel's raw tiers, lowest first. Null stands for "any rarity".
  static const _tiers = <String?>[
    null,
    'COMMON',
    'UNCOMMON',
    'RARE',
    'EPIC',
    'LEGENDARY',
    'MYTHIC',
    'DIVINE',
    'SPECIAL',
    'VERY_SPECIAL',
  ];

  // "VERY_SPECIAL" -> "Very special"
  static String _tierLabel(String? tier) {
    if (tier == null) return 'Any rarity';
    final words = tier.replaceAll('_', ' ').toLowerCase();
    return words[0].toUpperCase() + words.substring(1);
  }

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          Center(
            child: FilterChip(
              label: const Text('BIN only'),
              selected: filter.binOnly,
              onSelected: (selected) => onChanged(filter.withBinOnly(selected)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Center(
            child: MenuChip<String?>(
              label: _tierLabel(filter.tier),
              values: _tiers,
              labelOf: _tierLabel,
              highlighted: filter.tier != null,
              onSelected: (tier) => onChanged(filter.withTier(tier)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Center(
            child: MenuChip<AuctionSort>(
              label: filter.sort.label,
              values: AuctionSort.values,
              labelOf: (sort) => sort.label,
              highlighted: filter.sort != AuctionSort.endingSoon,
              onSelected: (sort) => onChanged(filter.withSort(sort)),
            ),
          ),
        ],
      ),
    );
  }
}
