import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/utils/formatters.dart';
import 'package:hypixel_tracker/core/widgets/coflnet_credit.dart';
import 'package:hypixel_tracker/core/widgets/fading_app_bar.dart';
import 'package:hypixel_tracker/core/widgets/search_field.dart';
import 'package:hypixel_tracker/core/widgets/skeleton.dart';
import 'package:hypixel_tracker/core/widgets/state_message.dart';
import 'package:hypixel_tracker/domain/entities/auction.dart';
import 'package:hypixel_tracker/domain/entities/item_summary.dart';
import 'package:hypixel_tracker/domain/repositories/auction_repository.dart';
import 'package:hypixel_tracker/domain/repositories/market_repository.dart';
import 'package:hypixel_tracker/features/auction/auction_controller.dart';
import 'package:hypixel_tracker/features/auction/item_auctions_page.dart';
import 'package:hypixel_tracker/features/auction/item_search_controller.dart';
import 'package:hypixel_tracker/features/auction/widgets/auction_filter_bar.dart';
import 'package:hypixel_tracker/features/auction/widgets/auction_list.dart';
import 'package:hypixel_tracker/features/auction/widgets/auction_sheet.dart';
import 'package:hypixel_tracker/features/auction/widgets/item_search_list.dart';
import 'package:hypixel_tracker/features/auction/widgets/search_suggestions.dart';

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

  // Types [query] in the search field, as if the user had.
  void _searchFor(String query) {
    _searchField.text = query;
    _search.onQueryChanged(query);
  }

  void _openItem(ItemSummary item) {
    widget.marketRepository.rememberItem(item);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            ItemAuctionsPage(item: item, repository: widget.marketRepository),
      ),
    );
  }

  void _openAuction(Auction auction) {
    AuctionSheet.show(
      context,
      auction: auction,
      onSeeItem: () async {
        // The auction list has no item id: ask which item this auction sells.
        final item = await widget.marketRepository.itemOfAuction(auction.id);
        if (!mounted) return;
        Navigator.of(context).pop(); // the sheet
        _openItem(item);
      },
    );
  }

  // Refresh in progress, last update, or offline: shown under the title.
  // Hidden during a search, where it would describe a list that is not shown.
  String? _status() {
    final state = _controller.state;
    if (state is! AuctionData || _search.state is! ItemSearchIdle) return null;

    final page = state.page;
    final updated = Formatters.dateTime(page.lastUpdated);
    final pages = 'page ${state.loadedPages}/${page.totalPages}';

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
        // The filters apply to the auction list, not to the item search.
        final showFilters =
            state is AuctionData && _search.state is ItemSearchIdle;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: FadingAppBar(
            title: 'Auctions',
            subtitle: _status(),
            subtitleColor: offline ? AppColors.warning : null,
            actions: const [CoflnetCreditButton()],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(
                SearchField.height +
                    (showFilters ? AuctionFilterBar.height : 0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SearchField(
                    controller: _searchField,
                    hintText: 'Search an item',
                    onChanged: _search.onQueryChanged,
                  ),
                  if (showFilters)
                    AuctionFilterBar(
                      filter: state.filter,
                      onChanged: _controller.setFilter,
                    ),
                ],
              ),
            ),
          ),
          body: switch (_search.state) {
            // No search: the auctions ending soonest.
            ItemSearchIdle() => _buildAuctions(state),
            ItemSearchLoading() => const SkeletonList(),
            ItemSearchEmpty(:final query) => SearchSuggestions(
              query: query,
              recentItems: widget.marketRepository.recentItems(),
              onItemTap: _openItem,
              onSearch: _searchFor,
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

  Widget _buildAuctions(AuctionState state) {
    return switch (state) {
      AuctionLoading() => const SkeletonList(),
      AuctionEmpty() => const StateMessage(text: 'No auctions to show.'),
      AuctionError() => StateMessage(
        text: 'Could not load the auctions. Check your connection.',
        onRetry: _controller.load,
      ),
      AuctionData() => Builder(
        builder: (context) => RefreshIndicator(
          // Start the spinner below the app bar, not behind it.
          edgeOffset: MediaQuery.paddingOf(context).top,
          onRefresh: _controller.load,
          child: AuctionList(
            // A new list per filter, so changing it scrolls back to the top.
            key: ObjectKey(state.filter),
            auctions: state.visible,
            end: switch (state) {
              AuctionData(loadMoreFailed: true) => AuctionListEnd.failed,
              AuctionData(loadMorePaused: true) => AuctionListEnd.paused,
              AuctionData(hasMore: true) => AuctionListEnd.loading,
              _ => AuctionListEnd.done,
            },
            onLoadMore: _controller.loadMore,
            onContinue: _controller.retryLoadMore,
            onTap: _openAuction,
          ),
        ),
      ),
    };
  }
}
