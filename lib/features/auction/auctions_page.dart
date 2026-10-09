import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/utils/formatters.dart';
import 'package:hypixel_tracker/core/widgets/coflnet_credit.dart';
import 'package:hypixel_tracker/core/widgets/fading_app_bar.dart';
import 'package:hypixel_tracker/core/widgets/state_message.dart';
import 'package:hypixel_tracker/domain/entities/item_summary.dart';
import 'package:hypixel_tracker/domain/repositories/auction_repository.dart';
import 'package:hypixel_tracker/domain/repositories/market_repository.dart';
import 'package:hypixel_tracker/features/auction/auction_controller.dart';
import 'package:hypixel_tracker/features/auction/item_auctions_page.dart';
import 'package:hypixel_tracker/features/auction/item_search_controller.dart';
import 'package:hypixel_tracker/features/auction/widgets/auction_list.dart';
import 'package:hypixel_tracker/features/auction/widgets/item_search_list.dart';

// Named AuctionsPage because AuctionPage is the entity (one page of auctions).
class AuctionsPage extends StatefulWidget {
  const AuctionsPage({
    super.key,
    required this.repository,
    required this.marketRepository,
  });

  final AuctionRepository repository;
  final MarketRepository marketRepository;

  @override
  State<AuctionsPage> createState() => _AuctionsPageState();
}

class _AuctionsPageState extends State<AuctionsPage> {
  late final AuctionController _controller;
  late final ItemSearchController _search;
  final _searchField = TextEditingController();

  static const _searchFieldHeight = 56.0;

  @override
  void initState() {
    super.initState();
    _controller = AuctionController(widget.repository)..load();
    _search = ItemSearchController(widget.marketRepository);
  }

  @override
  void dispose() {
    _controller.dispose();
    _search.dispose();
    _searchField.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchField.clear();
    _search.onQueryChanged('');
  }

  void _openItem(ItemSummary item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            ItemAuctionsPage(item: item, repository: widget.marketRepository),
      ),
    );
  }

  // Refresh in progress, last update, or offline: shown under the title.
  // Hidden during a search, where it would describe a list that is not shown.
  String? _status() {
    final state = _controller.state;
    if (state is! AuctionData || _search.state is! ItemSearchIdle) return null;

    final page = state.page;
    final updated = Formatters.dateTime(page.lastUpdated);
    final pages = 'page ${page.page + 1}/${page.totalPages}';

    return switch (state.sync) {
      AuctionSync.refreshing => 'Refreshing. Data from $updated, $pages',
      AuctionSync.upToDate => 'Updated $updated, $pages',
      AuctionSync.offline => 'Offline. Saved data from $updated, $pages',
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, _search]),
      builder: (context, _) {
        final state = _controller.state;
        final offline =
            state is AuctionData && state.sync == AuctionSync.offline;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: FadingAppBar(
            title: 'Auctions',
            subtitle: _status(),
            subtitleColor: offline ? AppColors.warning : null,
            actions: const [CoflnetCreditButton()],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(_searchFieldHeight),
              child: _buildSearchField(),
            ),
          ),
          body: switch (_search.state) {
            // No search: the auctions ending soonest.
            ItemSearchIdle() => _buildAuctions(state),
            ItemSearchLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ItemSearchEmpty() => const StateMessage(
              text: 'No item matches this search.',
            ),
            ItemSearchError() => StateMessage(
              text: 'The search failed. Check your connection.',
              onRetry: _search.search,
            ),
            ItemSearchResults(:final items) => ItemSearchList(
              items: items,
              onTap: _openItem,
            ),
          },
        );
      },
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SizedBox(
        height: _searchFieldHeight,
        child: TextField(
          controller: _searchField,
          onChanged: _search.onQueryChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search an item',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: ListenableBuilder(
              listenable: _searchField,
              builder: (context, _) => _searchField.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear',
                      onPressed: _clearSearch,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuctions(AuctionState state) {
    return switch (state) {
      AuctionLoading() => const Center(child: CircularProgressIndicator()),
      AuctionEmpty() => const StateMessage(text: 'No auctions to show.'),
      AuctionError() => StateMessage(
        text: 'Could not load the auctions. Check your connection.',
        onRetry: _controller.load,
      ),
      AuctionData(:final page) => Builder(
        builder: (context) => RefreshIndicator(
          // Start the spinner below the app bar, not behind it.
          edgeOffset: MediaQuery.paddingOf(context).top,
          onRefresh: _controller.load,
          child: AuctionList(page: page),
        ),
      ),
    };
  }
}
