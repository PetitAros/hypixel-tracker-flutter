import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hypixel_tracker/domain/entities/auction.dart';
import 'package:hypixel_tracker/domain/entities/auction_page.dart';
import 'package:hypixel_tracker/domain/repositories/auction_repository.dart';

sealed class AuctionState {
  const AuctionState();
}

class AuctionLoading extends AuctionState {
  const AuctionLoading();
}

// How the list on screen relates to the network.
enum AuctionSync { refreshing, upToDate, offline }

enum AuctionSort {
  endingSoon('Ending soon'),
  lowestPrice('Lowest price'),
  highestPrice('Highest price');

  const AuctionSort(this.label);

  final String label;
}

// What the user asked to see. The API cannot filter, so this applies to the
// auctions already loaded.
class AuctionFilter {
  /// Keep only fixed-price "Buy It Now" sales.
  final bool binOnly;

  /// Keep only this rarity, e.g. "LEGENDARY". Null keeps them all.
  final String? tier;
  final AuctionSort sort;

  const AuctionFilter({
    this.binOnly = false,
    this.tier,
    this.sort = AuctionSort.endingSoon,
  });

  bool get isActive => binOnly || tier != null;

  bool matches(Auction auction) {
    return (!binOnly || auction.isBin) &&
        (tier == null || auction.tier == tier);
  }

  int compare(Auction a, Auction b) => switch (sort) {
    AuctionSort.endingSoon => a.endsAt.compareTo(b.endsAt),
    AuctionSort.lowestPrice => a.price.compareTo(b.price),
    AuctionSort.highestPrice => b.price.compareTo(a.price),
  };

  AuctionFilter withBinOnly(bool binOnly) {
    return AuctionFilter(binOnly: binOnly, tier: tier, sort: sort);
  }

  AuctionFilter withTier(String? tier) {
    return AuctionFilter(binOnly: binOnly, tier: tier, sort: sort);
  }

  AuctionFilter withSort(AuctionSort sort) {
    return AuctionFilter(binOnly: binOnly, tier: tier, sort: sort);
  }
}

class AuctionData extends AuctionState {
  /// The first page: when it was updated and how many pages exist.
  final AuctionPage page;
  final AuctionSync sync;
  final AuctionFilter filter;

  /// The auctions the list shows so far. It grows as the user scrolls.
  final List<Auction> visible;

  /// How many pages of the API have been fetched.
  final int loadedPages;

  /// False once every matching auction of every page is shown.
  final bool hasMore;

  /// True when fetching the next page failed; the list offers a Retry.
  final bool loadMoreFailed;

  /// True when a fetched page had nothing for the filter: the list stops
  /// fetching by itself and lets the user decide to go on.
  final bool loadMorePaused;

  const AuctionData({
    required this.page,
    required this.sync,
    required this.filter,
    required this.visible,
    required this.loadedPages,
    required this.hasMore,
    required this.loadMoreFailed,
    required this.loadMorePaused,
  });
}

class AuctionEmpty extends AuctionState {
  const AuctionEmpty();
}

class AuctionError extends AuctionState {
  const AuctionError();
}

class AuctionController extends ChangeNotifier {
  final AuctionRepository _repository;

  AuctionController(this._repository);

  // How many auctions each step of the infinite scroll reveals.
  static const _step = 10;

  AuctionState _state = const AuctionLoading();
  AuctionState get state => _state;

  int _requestId = 0;
  bool _disposed = false;

  // Infinite scroll. The API serves pages of about 1,000 auctions: the list
  // reveals them [_step] at a time and fetches the next page when it runs out.
  AuctionPage? _firstPage;
  AuctionSync _sync = AuctionSync.refreshing;
  AuctionFilter _filter = const AuctionFilter();
  List<Auction> _loaded = const []; // everything fetched
  List<Auction> _matching = const []; // [_loaded] filtered and sorted
  int _visibleCount = 0;
  int _loadedPages = 0;
  bool _loadingMore = false;
  bool _loadMoreFailed = false;
  bool _loadMorePaused = false;

  Future<void> load() async {
    // A late response must never overwrite a newer one.
    final requestId = ++_requestId;

    // Show what we already have (on screen or on disk) right away,
    // then refresh behind it.
    final current = _firstPage ?? _repository.readCached();
    if (current == null) {
      _emit(const AuctionLoading());
    } else {
      if (_firstPage == null) _showFirstPage(current);
      _sync = AuctionSync.refreshing;
      _emitData();
    }

    try {
      final page = await _repository.refresh();
      if (requestId != _requestId) return;
      if (page.items.isEmpty) {
        _firstPage = null;
        _emit(const AuctionEmpty());
        return;
      }
      _showFirstPage(page);
      _sync = AuctionSync.upToDate;
      _emitData();
    } catch (_) {
      if (requestId != _requestId) return;
      if (current == null) {
        _emit(const AuctionError());
      } else {
        _sync = AuctionSync.offline;
        _emitData();
      }
    }
  }

  /// Changes what is shown and how it is ordered, back at the top.
  void setFilter(AuctionFilter filter) {
    _filter = filter;
    _loadMorePaused = false;
    _applyFilter();
    _visibleCount = min(_step, _matching.length);
    _emitData();
  }

  /// Called by the list when the user gets near its end.
  Future<void> loadMore() async {
    final firstPage = _firstPage;
    if (firstPage == null ||
        _loadingMore ||
        _loadMoreFailed ||
        _loadMorePaused) {
      return;
    }

    // Still some auctions in memory: reveal the next ones.
    if (_visibleCount < _matching.length) {
      _visibleCount = min(_visibleCount + _step, _matching.length);
      _emitData();
      return;
    }
    if (_loadedPages >= firstPage.totalPages) return;

    // Out of auctions: fetch the next page.
    final requestId = _requestId;
    _loadingMore = true;
    try {
      final page = await _repository.fetchPage(_loadedPages);
      // A refresh started meanwhile: the list restarted from the first page.
      if (requestId != _requestId) return;

      // The auction house moves between two calls, so an auction can show
      // up on two pages.
      final known = {for (final auction in _loaded) auction.id};
      _loaded = [
        ..._loaded,
        ...page.items.where((auction) => known.add(auction.id)),
      ];
      _loadedPages++;

      final before = _matching.length;
      _applyFilter();
      _visibleCount = min(_visibleCount + _step, _matching.length);
      // A whole page (about 2 MB) without a match: a rare filter could walk
      // through every page, so stop and let the user decide.
      _loadMorePaused = _matching.length == before;
    } catch (_) {
      if (requestId != _requestId) return;
      _loadMoreFailed = true;
    } finally {
      _loadingMore = false;
    }
    _emitData();
  }

  /// The button at the end of the list, after a failure or a pause.
  Future<void> retryLoadMore() {
    _loadMoreFailed = false;
    _loadMorePaused = false;
    _emitData();
    return loadMore();
  }

  // Restarts the list from a fresh first page, keeping the user's position
  // when possible.
  void _showFirstPage(AuctionPage page) {
    _firstPage = page;
    _loaded = page.items;
    _loadedPages = 1;
    _loadMoreFailed = false;
    _loadMorePaused = false;
    _applyFilter();
    _visibleCount = min(max(_visibleCount, _step), _matching.length);
  }

  void _applyFilter() {
    _matching = _loaded.where(_filter.matches).toList()..sort(_filter.compare);
  }

  void _emitData() {
    final firstPage = _firstPage;
    if (firstPage == null) return;

    _emit(
      AuctionData(
        page: firstPage,
        sync: _sync,
        filter: _filter,
        visible: _matching.sublist(0, min(_visibleCount, _matching.length)),
        loadedPages: _loadedPages,
        hasMore:
            _visibleCount < _matching.length ||
            _loadedPages < firstPage.totalPages,
        loadMoreFailed: _loadMoreFailed,
        loadMorePaused: _loadMorePaused,
      ),
    );
  }

  void _emit(AuctionState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
