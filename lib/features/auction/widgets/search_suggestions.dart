import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/domain/entities/item_summary.dart';
import 'package:hypixel_tracker/features/auction/widgets/item_search_list.dart';

// What to show when a search finds nothing: why, and ways to carry on
// (items viewed recently, and a few searches that always work).
class SearchSuggestions extends StatelessWidget {
  const SearchSuggestions({
    super.key,
    required this.query,
    required this.recentItems,
    required this.onItemTap,
    required this.onSearch,
  });

  final String query;
  final List<ItemSummary> recentItems;
  final ValueChanged<ItemSummary> onItemTap;

  /// Replaces the text of the search field.
  final ValueChanged<String> onSearch;

  static const _popular = [
    'Hyperion',
    'Terminator',
    'Aspect of the Void',
    'Juju Shortbow',
    'Livid Dagger',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Starts below the app bar and ends above the navigation bar.
    final inset = MediaQuery.paddingOf(context);

    Widget title(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(text, style: textTheme.titleMedium),
    );

    return ListView(
      padding: EdgeInsets.only(
        top: inset.top + AppSpacing.md,
        bottom: inset.bottom + AppSpacing.md,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'No item matches "$query".\n'
            'Check the spelling, or try a shorter part of the name.',
            style: textTheme.bodyLarge,
          ),
        ),
        if (recentItems.isNotEmpty) ...[
          title('Recently viewed'),
          for (final item in recentItems)
            ItemSearchTile(item: item, onTap: () => onItemTap(item)),
        ],
        title('Popular searches'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final name in _popular)
                ActionChip(label: Text(name), onPressed: () => onSearch(name)),
            ],
          ),
        ),
      ],
    );
  }
}
