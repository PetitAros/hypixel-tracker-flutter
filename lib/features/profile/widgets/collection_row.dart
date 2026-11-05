import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/utils/formatters.dart';
import 'package:hypixel_tracker/core/widgets/item_icon.dart';
import 'package:hypixel_tracker/domain/entities/player_profiles.dart';

// One collection item with its tier, progress bar and amount collected.
class CollectionRow extends StatelessWidget {
  const CollectionRow({super.key, required this.collection});

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
                      color: maxed ? context.palette.accent : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              LinearProgressIndicator(
                value: collection.tier / collection.maxTier,
                minHeight: _barHeight,
                borderRadius: AppRadius.sm,
                backgroundColor: context.palette.surface,
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
