import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/utils/formatters.dart';
import 'package:hypixel_tracker/core/widgets/item_icon.dart';
import 'package:hypixel_tracker/domain/entities/bazaar_item.dart';

class BazaarItemCard extends StatelessWidget {
  const BazaarItemCard({super.key, required this.item, required this.onTap});

  final BazaarItem item;
  final VoidCallback onTap;

  // From this share of the sell price, the spread is worth a flip.
  static const _goodMargin = 0.05;

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
              ItemIcon(url: item.iconUrl),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text.rich(
                      TextSpan(
                        text:
                            'Volume ${Formatters.compact(item.weeklyVolume)}'
                            '  ·  Margin ',
                        children: [
                          TextSpan(
                            text: Formatters.percent(item.margin),
                            style: TextStyle(
                              color: item.margin >= _goodMargin
                                  ? AppColors.success
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      style: textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Buy ${Formatters.compact(item.buyPrice)}',
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Sell ${Formatters.compact(item.sellPrice)}',
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
