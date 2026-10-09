import 'package:flutter/widgets.dart';
import 'package:hypixel_tracker/domain/entities/player.dart';
import 'package:hypixel_tracker/domain/entities/player_profiles.dart';
import 'package:hypixel_tracker/domain/repositories/profile_repository.dart';

sealed class ProfileState {
  const ProfileState();
}

// No player chosen yet.
class ProfileNone extends ProfileState {
  const ProfileNone();
}

class ProfileLoading extends ProfileState {
  final Player player;

  const ProfileLoading(this.player);
}

class ProfileLoaded extends ProfileState {
  final PlayerProfile profile;

  const ProfileLoaded(this.profile);
}

class ProfileFailed extends ProfileState {
  final Player player;

  const ProfileFailed(this.player);
}

// The player the app is following and their SkyBlock progress.
// App-wide state: one instance, created in main.dart and shared through
// ProfileScope, so any screen can read it.
class ProfileController extends ChangeNotifier {
  final ProfileRepository _repository;

  ProfileController(this._repository);

  ProfileState _state = const ProfileNone();
  ProfileState get state => _state;

  int _requestId = 0;

  /// Makes [player] the followed player and loads their progress.
  Future<void> select(Player player) async {
    // A late response must never overwrite a newer one.
    final requestId = ++_requestId;
    _emit(ProfileLoading(player));

    try {
      final profile = await _repository.loadProfile(player);
      if (requestId != _requestId) return;
      _emit(ProfileLoaded(profile));
    } catch (_) {
      if (requestId != _requestId) return;
      _emit(ProfileFailed(player));
    }
  }

  /// Goes back to no player chosen.
  void clear() {
    _requestId++;
    _emit(const ProfileNone());
  }

  void _emit(ProfileState state) {
    _state = state;
    notifyListeners();
  }
}

// Puts the ProfileController in the widget tree, above every page.
// `ProfileScope.of(context)` returns it and rebuilds the caller on change.
class ProfileScope extends InheritedNotifier<ProfileController> {
  const ProfileScope({
    super.key,
    required ProfileController controller,
    required super.child,
  }) : super(notifier: controller);

  static ProfileController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ProfileScope>();
    assert(scope != null, 'No ProfileScope above this widget');
    return scope!.notifier!;
  }
}
