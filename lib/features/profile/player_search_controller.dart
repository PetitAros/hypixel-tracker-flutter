import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hypixel_tracker/domain/entities/player.dart';
import 'package:hypixel_tracker/domain/repositories/player_repository.dart';

sealed class PlayerSearchState {
  const PlayerSearchState();
}

// Nothing typed yet, or not enough to be a username.
class PlayerSearchIdle extends PlayerSearchState {
  const PlayerSearchIdle();
}

class PlayerSearchLoading extends PlayerSearchState {
  const PlayerSearchLoading();
}

class PlayerSearchFound extends PlayerSearchState {
  final Player player;

  const PlayerSearchFound(this.player);
}

// No account has this name, or it cannot be a username at all.
class PlayerSearchNotFound extends PlayerSearchState {
  final String name;

  const PlayerSearchNotFound(this.name);
}

class PlayerSearchError extends PlayerSearchState {
  const PlayerSearchError();
}

class PlayerSearchController extends ChangeNotifier {
  final PlayerRepository _repository;

  PlayerSearchController(this._repository);

  // Wait for a pause in typing before calling the network.
  static const _debounceDelay = Duration(milliseconds: 400);

  // Minecraft usernames: 3 to 16 letters, digits or underscores.
  static const _minNameLength = 3;
  static final _validName = RegExp(r'^[A-Za-z0-9_]{3,16}$');

  PlayerSearchState _state = const PlayerSearchIdle();
  PlayerSearchState get state => _state;

  Timer? _debounce;
  String _name = '';
  int _requestId = 0;
  bool _disposed = false;

  void onNameChanged(String value) {
    final name = value.trim();
    if (name == _name) return;
    _name = name;

    // Whatever was typed before is obsolete: drop the pending timer
    // and make any request still in flight a late one.
    _debounce?.cancel();
    _requestId++;

    if (name.length < _minNameLength) {
      _emit(const PlayerSearchIdle());
      return;
    }
    // No need to ask the network for a name that cannot exist.
    if (!_validName.hasMatch(name)) {
      _emit(PlayerSearchNotFound(name));
      return;
    }

    _emit(const PlayerSearchLoading());
    _debounce = Timer(_debounceDelay, search);
  }

  /// Looks up the current name now. Also used by Retry.
  Future<void> search() async {
    // A late response must never overwrite a newer one.
    final requestId = ++_requestId;
    final name = _name;
    _emit(const PlayerSearchLoading());

    try {
      final player = await _repository.findByName(name);
      if (requestId != _requestId) return;
      _emit(
        player == null ? PlayerSearchNotFound(name) : PlayerSearchFound(player),
      );
    } catch (_) {
      if (requestId != _requestId) return;
      _emit(const PlayerSearchError());
    }
  }

  void _emit(PlayerSearchState state) {
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
