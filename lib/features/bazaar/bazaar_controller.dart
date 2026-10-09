import 'package:flutter/foundation.dart';
import '../../domain/entities/bazaar_snapshot.dart';
import '../../domain/repositories/bazaar_repository.dart';

sealed class BazaarState {
  const BazaarState();
}

class BazaarLoading extends BazaarState {
  const BazaarLoading();
}

// How the list on screen relates to the network.
enum BazaarSync { refreshing, upToDate, offline }

class BazaarData extends BazaarState {
  final BazaarSnapshot snapshot;
  final BazaarSync sync;

  const BazaarData(this.snapshot, this.sync);
}

class BazaarEmpty extends BazaarState {
  const BazaarEmpty();
}

class BazaarError extends BazaarState {
  const BazaarError();
}

class BazaarController extends ChangeNotifier {
  final BazaarRepository _repository;

  BazaarController(this._repository);

  BazaarState _state = const BazaarLoading();
  BazaarState get state => _state;

  int _requestId = 0;
  bool _disposed = false;

  Future<void> load() async {
    // A late response must never overwrite a newer one.
    final requestId = ++_requestId;

    // Show what we already have (on screen or on disk) right away,
    // then refresh behind it.
    final current = switch (_state) {
      BazaarData(:final snapshot) => snapshot,
      _ => _repository.readCached(),
    };
    _emit(
      current == null
          ? const BazaarLoading()
          : BazaarData(current, BazaarSync.refreshing),
    );

    try {
      final snapshot = await _repository.refresh();
      if (requestId != _requestId) return;
      _emit(
        snapshot.items.isEmpty
            ? const BazaarEmpty()
            : BazaarData(snapshot, BazaarSync.upToDate),
      );
    } catch (_) {
      if (requestId != _requestId) return;
      _emit(
        current == null
            ? const BazaarError()
            : BazaarData(current, BazaarSync.offline),
      );
    }
  }

  void _emit(BazaarState state) {
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
