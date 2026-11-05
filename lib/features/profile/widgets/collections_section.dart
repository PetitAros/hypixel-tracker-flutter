import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/domain/entities/player_profiles.dart';
import 'package:hypixel_tracker/features/profile/collection_category_page.dart';
import 'package:hypixel_tracker/features/profile/widgets/skills_section.dart';

// One card listing the collection categories (Farming, Mining...) with how
// far along each is. Tapping a category opens its items.
class CollectionsSection extends StatelessWidget {
  const CollectionsSection({
    super.key,
    required this.playerName,
    required this.collections,
  });

  final String playerName;
  final List<CollectionProgress> collections;

  // Categories that are not skills.
  static const _icons = {'Rift': Icons.blur_on};

  void _openCategory(
    BuildContext context,
    String category,
    List<CollectionProgress> items,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CollectionCategoryPage(
          category: category,
          playerName: playerName,
          collections: items,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the order in which the categories first appear.
    final byCategory = <String, List<CollectionProgress>>{};
    for (final collection in collections) {
      byCategory.putIfAbsent(collection.category, () => []).add(collection);
    }

    return Card(
      // Clips the tap ripple to the rounded corners.
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final MapEntry(key: category, value: items)
              in byCategory.entries)
            _CategoryRow(
              category: category,
              items: items,
              icon:
                  SkillsSection.icons[category] ??
                  _icons[category] ??
                  Icons.inventory_2_outlined,
              onTap: () => _openCategory(context, category, items),
            ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.items,
    required this.icon,
    required this.onTap,
  });

  final String category;
  final List<CollectionProgress> items;
  final IconData icon;
  final VoidCallback onTap;

  static const _barHeight = 6.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final maxedCount = items.where((item) => item.tier >= item.maxTier).length;
    final allMaxed = maxedCount == items.length;
    final tiers = items.fold(0, (sum, item) => sum + item.tier);
    final maxTiers = items.fold(0, (sum, item) => sum + item.maxTier);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              icon,
              color: allMaxed
                  ? context.palette.accent
                  : context.palette.onSurfaceMuted,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(category, style: textTheme.titleMedium),
                      ),
                      Text(
                        '$maxedCount/${items.length} maxed',
                        style: textTheme.bodyLarge?.copyWith(
                          color: allMaxed ? context.palette.accent : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  LinearProgressIndicator(
                    value: maxTiers == 0 ? 0 : tiers / maxTiers,
                    minHeight: _barHeight,
                    borderRadius: AppRadius.sm,
                    backgroundColor: context.palette.surface,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
