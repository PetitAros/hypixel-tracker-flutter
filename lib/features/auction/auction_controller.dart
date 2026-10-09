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

class AuctionData extends AuctionState {
  /// The first page: when it was updated and how many pages exist.
  final AuctionPage page;
  final AuctionSync sync;

  /// The auctions the list shows so far. It grows as the user scrolls.
  final List<Auction> visible;

  /// How many pages of the API have been fetched.
  final int loadedPages;

  /// False once every auction of every page is shown.
  final bool hasMore;

  /// True when fetching the next page failed; the list offers a Retry.
  final bool loadMoreFailed;

  const AuctionData({
    required this.page,
    required this.sync,
    required this.visible,
    required this.loadedPages,
    required this.hasMore,
    required this.loadMoreFailed,
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
  List<Auction> _loaded = const [];
  int _visibleCount = 0;
  int _loadedPages = 0;
  bool _loadingMore = false;
  bool _loadMoreFailed = false;

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

  /// Called by the list when the user gets near its end.
  Future<void> loadMore() async {
    final firstPage = _firstPage;
    if (firstPage == null || _loadingMore || _loadMoreFailed) return;

    // Still some auctions in memory: reveal the next ones.
    if (_visibleCount < _loaded.length) {
      _visibleCount = min(_visibleCount + _step, _loaded.length);
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
      _visibleCount = min(_visibleCount + _step, _loaded.length);
    } catch (_) {
      if (requestId != _requestId) return;
      _loadMoreFailed = true;
    } finally {
      _loadingMore = false;
    }
    _emitData();
  }

  /// The Retry button at the end of the list.
  Future<void> retryLoadMore() {
    _loadMoreFailed = false;
    _emitData();
    return loadMore();
  }

  // Restarts the list from a fresh first page, keeping the user's position
  // when possible.
  void _showFirstPage(AuctionPage page) {
    _firstPage = page;
    _loaded = page.items;
    _loadedPages = 1;
    _visibleCount = min(max(_visibleCount, _step), _loaded.length);
    _loadMoreFailed = false;
  }

  void _emitData() {
    final firstPage = _firstPage;
    if (firstPage == null) return;

    _emit(
      AuctionData(
        page: firstPage,
        sync: _sync,
        visible: _loaded.sublist(0, _visibleCount),
        loadedPages: _loadedPages,
        hasMore:
            _visibleCount < _loaded.length ||
            _loadedPages < firstPage.totalPages,
        loadMoreFailed: _loadMoreFailed,
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
