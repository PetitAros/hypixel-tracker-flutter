import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/utils/formatters.dart';
import 'package:hypixel_tracker/core/widgets/item_icon.dart';
import 'package:hypixel_tracker/domain/entities/player_profiles.dart';

// One card per collection category (Farming, Mining...), each listing its
// items with their tier.
class CollectionsSection extends StatelessWidget {
  const CollectionsSection({super.key, required this.collections});

  final List<CollectionProgress> collections;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Keeps the order in which the categories first appear.
    final byCategory = <String, List<CollectionProgress>>{};
    for (final collection in collections) {
      byCategory.putIfAbsent(collection.category, () => []).add(collection);
    }

    return Column(
      children: [
        for (final MapEntry(key: category, value: items) in byCategory.entries)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.md,
                children: [
                  Text(category, style: textTheme.titleMedium),
                  for (final item in items) _CollectionRow(collection: item),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({required this.collection});

  final CollectionProgress collection;

  static const _barHeight = 6.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxed = collection.tier >= collection.maxTier;

    return Row(
      children: [
        ItemIcon(url: collection.iconUrl),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      collection.itemName,
                      style: textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Tier ${collection.tier}/${collection.maxTier}',
                    style: textTheme.bodyLarge?.copyWith(
                      color: maxed ? AppColors.gold : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              LinearProgressIndicator(
                value: collection.tier / collection.maxTier,
                minHeight: _barHeight,
                borderRadius: AppRadius.sm,
                backgroundColor: AppColors.surface,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${Formatters.compact(collection.amount)} collected',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
