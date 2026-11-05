import 'package:flutter/foundation.dart';
import 'package:hypixel_tracker/domain/entities/skyblock_events.dart';
import 'package:hypixel_tracker/domain/repositories/events_repository.dart';
import 'package:hypixel_tracker/features/events/background/events_sync.dart';

sealed class EventsState {
  const EventsState();
}

class EventsLoading extends EventsState {
  const EventsLoading();
}

class EventsLoaded extends EventsState {
  final SkyblockEvents events;

  const EventsLoaded(this.events);
}

class EventsFailed extends EventsState {
  const EventsFailed();
}

class EventsController extends ChangeNotifier {
  final EventsRepository _repository;

  EventsController(this._repository);

  EventsState _state = const EventsLoading();
  EventsState get state => _state;

  int _requestId = 0;
  bool _disposed = false;

  Future<void> load() async {
    // A late response must never overwrite a newer one.
    final requestId = ++_requestId;
    if (_state is! EventsLoaded) _emit(const EventsLoading());

    try {
      final events = await _repository.load();
      if (requestId != _requestId) return;
      _emit(EventsLoaded(events));

      // The widget and alerts follow what the app shows. A failure there
      // must not break the page.
      EventsSync.publish(events).catchError((_) {});
    } catch (_) {
      if (requestId != _requestId) return;
      if (_state is! EventsLoaded) _emit(const EventsFailed());
    }
  }

  void _emit(EventsState state) {
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
