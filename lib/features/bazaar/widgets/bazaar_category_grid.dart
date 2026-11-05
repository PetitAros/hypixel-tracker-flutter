import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/widgets/item_icon.dart';
import 'package:hypixel_tracker/domain/entities/bazaar_category.dart';
import 'package:hypixel_tracker/domain/entities/bazaar_item.dart';

// The bazaar menu: one card per category, two per row, plus "All items".
class BazaarCategoryGrid extends StatelessWidget {
  const BazaarCategoryGrid({
    super.key,
    required this.items,
    required this.onTap,
  });

  final List<BazaarItem> items;

  /// Called with the tapped category, or null for "All items".
  final ValueChanged<BazaarCategory?> onTap;

  // The item whose texture is the logo of each category, and the icon shown
  // when that texture is missing.
  static const _logos = {
    BazaarCategory.farming: ('WHEAT', Icons.agriculture),
    BazaarCategory.mining: ('DIAMOND', Icons.diamond),
    BazaarCategory.combat: ('ROTTEN_FLESH', Icons.shield),
    BazaarCategory.woodsAndFishes: ('LOG', Icons.forest),
    BazaarCategory.enchantments: (
      'ENCHANTMENT_SHARPNESS_7',
      Icons.auto_stories,
    ),
    BazaarCategory.shards: ('SHARD_QUEEN_BEE', Icons.hexagon),
    BazaarCategory.oddities: ('BAZAAR_COOKIE', Icons.auto_awesome),
  };

  static const _columns = 2;

  @override
  Widget build(BuildContext context) {
    final counts = <BazaarCategory, int>{};
    final byId = <String, BazaarItem>{};
    for (final item in items) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
      byId[item.id] = item;
    }

    // Starts below the app bar and ends above the navigation bar,
    // and scrolls under both.
    final inset = MediaQuery.paddingOf(context);

    final cards = [
      for (final category in BazaarCategory.values)
        _CategoryCard(
          label: category.label,
          count: counts[category] ?? 0,
          iconUrl: byId[_logos[category]!.$1]?.iconUrl,
          fallback: _logos[category]!.$2,
          onTap: () => onTap(category),
        ),
      _CategoryCard(
        label: 'All items',
        count: items.length,
        iconUrl: null,
        fallback: Icons.apps,
        onTap: () => onTap(null),
      ),
    ];

    // Rows of two cards as tall as their content, rather than a grid with a
    // fixed aspect ratio: that overflowed on narrow screens and large fonts.
    return ListView(
      // Keeps pull-to-refresh working: the list is shorter than the screen.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        inset.top + AppSpacing.sm,
        AppSpacing.md,
        inset.bottom + AppSpacing.sm,
      ),
      children: [
        for (var i = 0; i < cards.length; i += _columns)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpacing.md),
            // Both cards of a row take the height of the taller one.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.md,
                children: [
                  for (var j = i; j < i + _columns; j++)
                    Expanded(
                      child: j < cards.length ? cards[j] : const SizedBox(),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.label,
    required this.count,
    required this.iconUrl,
    required this.fallback,
    required this.onTap,
  });

  final String label;
  final int count;
  final String? iconUrl;
  final IconData fallback;
  final VoidCallback onTap;

  static const _logoSize = 48.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      // The grid already spaces the cards.
      margin: EdgeInsets.zero,
      // Clips the tap ripple to the rounded corners.
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ItemIcon(url: iconUrl, size: _logoSize, fallback: fallback),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('$count items', style: textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
