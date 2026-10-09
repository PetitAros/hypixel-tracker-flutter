import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/widgets/coflnet_credit.dart';
import 'package:hypixel_tracker/core/widgets/fading_app_bar.dart';
import 'package:hypixel_tracker/core/widgets/search_field.dart';
import 'package:hypixel_tracker/core/widgets/skeleton.dart';
import 'package:hypixel_tracker/core/widgets/state_message.dart';
import 'package:hypixel_tracker/domain/entities/bazaar_category.dart';
import 'package:hypixel_tracker/domain/entities/bazaar_item.dart';
import 'package:hypixel_tracker/domain/repositories/market_repository.dart';
import 'package:hypixel_tracker/features/bazaar/bazaar_controller.dart';
import 'package:hypixel_tracker/features/bazaar/bazaar_item_detail_page.dart';
import 'package:hypixel_tracker/features/bazaar/bazaar_status.dart';
import 'package:hypixel_tracker/features/bazaar/widgets/bazaar_list.dart';

enum BazaarSort {
  name('Name'),
  price('Price'),
  volume('Volume'),
  margin('Margin');

  const BazaarSort(this.label);

  final String label;

  // Names from A to Z; numbers from the biggest down.
  int compare(BazaarItem a, BazaarItem b) => switch (this) {
    BazaarSort.name => a.displayName.compareTo(b.displayName),
    BazaarSort.price => b.buyPrice.compareTo(a.buyPrice),
    BazaarSort.volume => b.weeklyVolume.compareTo(a.weeklyVolume),
    BazaarSort.margin => b.margin.compareTo(a.margin),
  };
}

// The products of one bazaar category, or all of them when [category] is null,
// with a search by name and a choice of order.
// Listens to the controller of the bazaar tab, so it stays in sync with it.
class BazaarCategoryPage extends StatefulWidget {
  const BazaarCategoryPage({
    super.key,
    required this.category,
    required this.controller,
    required this.marketRepository,
  });

  final BazaarCategory? category;
  final BazaarController controller;
  final MarketRepository marketRepository;

  @override
  State<BazaarCategoryPage> createState() => _BazaarCategoryPageState();
}

class _BazaarCategoryPageState extends State<BazaarCategoryPage> {
  final _searchField = TextEditingController();

  // Local state: what the user typed and picked on this page.
  String _query = '';
  BazaarSort _sort = BazaarSort.name;

  static const _sortBarHeight = 48.0;

  @override
  void dispose() {
    _searchField.dispose();
    super.dispose();
  }

  void _openItem(BazaarItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BazaarItemDetailPage(
          item: item,
          repository: widget.marketRepository,
        ),
      ),
    );
  }

  // The list is in memory, so filtering it is instant: no debounce needed.
  List<BazaarItem> _select(List<BazaarItem> items) {
    final query = _query.toLowerCase();

    return items
        .where(
          (item) =>
              (widget.category == null || item.category == widget.category) &&
              item.displayName.toLowerCase().contains(query),
        )
        .toList()
      ..sort(_sort.compare);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        final status = bazaarStatus(state);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: FadingAppBar(
            title: widget.category?.label ?? 'All items',
            subtitle: status?.text,
            subtitleColor: status?.offline == true ? AppColors.warning : null,
            // The textures come from SkyCofl.
            actions: const [CoflnetCreditButton()],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(
                SearchField.height + _sortBarHeight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SearchField(
                    controller: _searchField,
                    hintText: 'Search in this category',
                    onChanged: (value) => setState(() => _query = value.trim()),
                  ),
                  _buildSortBar(),
                ],
              ),
            ),
          ),
          body: switch (state) {
            BazaarLoading() => const SkeletonList(),
            BazaarEmpty() => const StateMessage(
              text: 'No bazaar items to show.',
            ),
            BazaarError() => StateMessage(
              text: 'Could not load the bazaar. Check your connection.',
              onRetry: widget.controller.load,
            ),
            BazaarData(:final snapshot) => _buildList(_select(snapshot.items)),
          },
        );
      },
    );
  }

  Widget _buildSortBar() {
    return SizedBox(
      height: _sortBarHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          for (final sort in BazaarSort.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Center(
                child: ChoiceChip(
                  label: Text(sort.label),
                  selected: sort == _sort,
                  onSelected: (_) => setState(() => _sort = sort),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList(List<BazaarItem> items) {
    if (items.isEmpty) {
      return StateMessage(
        text: _query.isEmpty
            ? 'No items in this category.'
            : 'No item matches "$_query" in this category.',
      );
    }

    return Builder(
      builder: (context) => RefreshIndicator(
        // Start the spinner below the app bar, not behind it.
        edgeOffset: MediaQuery.paddingOf(context).top,
        onRefresh: widget.controller.load,
        child: BazaarList(
          // A new list per order, so changing it scrolls back to the top.
          key: ValueKey(_sort),
          items: items,
          onTap: _openItem,
        ),
      ),
    );
  }
}
