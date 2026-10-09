import 'package:flutter/foundation.dart';
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
  final AuctionPage page;
  final AuctionSync sync;

  const AuctionData(this.page, this.sync);
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

  AuctionState _state = const AuctionLoading();
  AuctionState get state => _state;

  int _requestId = 0;
  bool _disposed = false;

  Future<void> load() async {
    // A late response must never overwrite a newer one.
    final requestId = ++_requestId;

    // Show what we already have (on screen or on disk) right away,
    // then refresh behind it.
    final current = switch (_state) {
      AuctionData(:final page) => page,
      _ => _repository.readCached(),
    };
    _emit(
      current == null
          ? const AuctionLoading()
          : AuctionData(current, AuctionSync.refreshing),
    );

    try {
      final page = await _repository.refresh();
      if (requestId != _requestId) return;
      _emit(
        page.items.isEmpty
            ? const AuctionEmpty()
            : AuctionData(page, AuctionSync.upToDate),
      );
    } catch (_) {
      if (requestId != _requestId) return;
      _emit(
        current == null
            ? const AuctionError()
            : AuctionData(current, AuctionSync.offline),
      );
    }
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
