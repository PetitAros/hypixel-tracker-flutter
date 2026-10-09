import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hypixel_tracker/domain/entities/item_summary.dart';
import 'package:hypixel_tracker/domain/repositories/market_repository.dart';

sealed class ItemSearchState {
  const ItemSearchState();
}

// No query typed (or too short): the page shows its normal content.
class ItemSearchIdle extends ItemSearchState {
  const ItemSearchIdle();
}

class ItemSearchLoading extends ItemSearchState {
  const ItemSearchLoading();
}

class ItemSearchResults extends ItemSearchState {
  final List<ItemSummary> items;

  const ItemSearchResults(this.items);
}

class ItemSearchEmpty extends ItemSearchState {
  final String query;

  const ItemSearchEmpty(this.query);
}

class ItemSearchError extends ItemSearchState {
  const ItemSearchError();
}

class ItemSearchController extends ChangeNotifier {
  final MarketRepository _repository;

  ItemSearchController(this._repository);

  // Wait for a pause in typing before calling the network.
  static const _debounceDelay = Duration(milliseconds: 400);
  static const _minQueryLength = 2;

  ItemSearchState _state = const ItemSearchIdle();
  ItemSearchState get state => _state;

  Timer? _debounce;
  String _query = '';
  int _requestId = 0;
  bool _disposed = false;

  void onQueryChanged(String value) {
    final query = value.trim();
    if (query == _query) return;
    _query = query;

    // Whatever was typed before is obsolete: drop the pending timer
    // and make any request still in flight a late one.
    _debounce?.cancel();
    _requestId++;

    if (query.length < _minQueryLength) {
      _emit(const ItemSearchIdle());
      return;
    }

    _emit(const ItemSearchLoading());
    _debounce = Timer(_debounceDelay, search);
  }

  /// Runs the current query now. Also used by Retry.
  Future<void> search() async {
    // A late response must never overwrite a newer one.
    final requestId = ++_requestId;
    _emit(const ItemSearchLoading());

    try {
      final items = await _repository.searchItems(_query);
      if (requestId != _requestId) return;
      _emit(items.isEmpty ? ItemSearchEmpty(_query) : ItemSearchResults(items));
    } catch (_) {
      if (requestId != _requestId) return;
      _emit(const ItemSearchError());
    }
  }

  void _emit(ItemSearchState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
