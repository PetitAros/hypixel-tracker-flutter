import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/utils/formatters.dart';
import 'package:hypixel_tracker/core/widgets/coflnet_credit.dart';
import 'package:hypixel_tracker/core/widgets/fading_app_bar.dart';
import 'package:hypixel_tracker/core/widgets/state_message.dart';
import 'package:hypixel_tracker/domain/entities/player.dart';
import 'package:hypixel_tracker/domain/repositories/player_repository.dart';
import 'package:hypixel_tracker/features/profile/player_search_controller.dart';
import 'package:hypixel_tracker/features/profile/profile_controller.dart';
import 'package:hypixel_tracker/features/profile/widgets/player_head.dart';
import 'package:hypixel_tracker/features/profile/widgets/profile_dashboard.dart';

// The profile tab. Without a followed player it is a search by username;
// tapping the player found makes them the followed player (app-wide state,
// see ProfileScope) and the tab becomes their dashboard.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.repository});

  final PlayerRepository repository;

  @override
  Widget build(BuildContext context) {
    final profile = ProfileScope.of(context);

    return switch (profile.state) {
      ProfileNone() => _PlayerSearch(
        repository: repository,
        onSelect: profile.select,
      ),
      ProfileLoading(:final player) => _FollowedPlayerScaffold(
        player: player,
        onChange: profile.clear,
        body: const Center(child: CircularProgressIndicator()),
      ),
      ProfileFailed(:final player) => _FollowedPlayerScaffold(
        player: player,
        onChange: profile.clear,
        body: StateMessage(
          text: 'Could not load this profile. Check your connection.',
          onRetry: () => profile.select(player),
        ),
      ),
      ProfileLoaded(profile: final loaded) => _FollowedPlayerScaffold(
        player: loaded.player,
        onChange: profile.clear,
        body: ProfileDashboard(profile: loaded),
      ),
    };
  }
}

// The page once a player is followed: their name as title, and a button to
// go back to the search.
class _FollowedPlayerScaffold extends StatelessWidget {
  const _FollowedPlayerScaffold({
    required this.player,
    required this.onChange,
    required this.body,
  });

  final Player player;
  final VoidCallback onChange;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FadingAppBar(
        title: player.name,
        actions: [
          // The collection textures come from SkyCofl.
          const CoflnetCreditButton(),
          IconButton(
            icon: const Icon(Icons.switch_account),
            tooltip: 'Change player',
            onPressed: onChange,
          ),
        ],
      ),
      body: body,
    );
  }
}

class _PlayerSearch extends StatefulWidget {
  const _PlayerSearch({required this.repository, required this.onSelect});

  final PlayerRepository repository;
  final ValueChanged<Player> onSelect;

  @override
  State<_PlayerSearch> createState() => _PlayerSearchState();
}

class _PlayerSearchState extends State<_PlayerSearch> {
  late final PlayerSearchController _controller;
  final _nameField = TextEditingController();

  static const _nameFieldHeight = 56.0;

  @override
  void initState() {
    super.initState();
    _controller = PlayerSearchController(widget.repository);
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameField.dispose();
    super.dispose();
  }

  void _clear() {
    _nameField.clear();
    _controller.onNameChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FadingAppBar(
        title: 'Profile',
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(_nameFieldHeight),
          child: _buildNameField(),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => switch (_controller.state) {
          PlayerSearchIdle() => const StateMessage(
            text: 'Enter a Minecraft username to find a player.',
          ),
          PlayerSearchLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          PlayerSearchNotFound(:final name) => StateMessage(
            text: 'No player is named "$name".',
          ),
          PlayerSearchError() => StateMessage(
            text: 'The lookup failed. Check your connection.',
            onRetry: _controller.search,
          ),
          PlayerSearchFound(:final player) => _PlayerView(
            player: player,
            onTap: () => widget.onSelect(player),
          ),
        },
      ),
    );
  }

  Widget _buildNameField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SizedBox(
        height: _nameFieldHeight,
        child: TextField(
          controller: _nameField,
          onChanged: _controller.onNameChanged,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Minecraft username',
            prefixIcon: const Icon(Icons.person_search),
            suffixIcon: ListenableBuilder(
              listenable: _nameField,
              builder: (context, _) => _nameField.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear',
                      onPressed: _clear,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// The player found by the search. Tapping the card opens their dashboard.
class _PlayerView extends StatelessWidget {
  const _PlayerView({required this.player, required this.onTap});

  final Player player;
  final VoidCallback onTap;

  Future<void> _copyUuid(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: Formatters.uuid(player.uuid)));
    messenger.showSnackBar(const SnackBar(content: Text('UUID copied')));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Starts below the app bar and ends above the navigation bar.
    final inset = MediaQuery.paddingOf(context);

    return ListView(
      padding: EdgeInsets.only(
        top: inset.top + AppSpacing.sm,
        bottom: inset.bottom + AppSpacing.sm,
      ),
      children: [
        Card(
          // Clips the tap ripple to the rounded corners.
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  PlayerHead(uuid: player.uuid),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text('UUID', style: textTheme.bodyMedium),
                        Text(
                          Formatters.uuid(player.uuid),
                          style: textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy UUID',
                    onPressed: () => _copyUuid(context),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'Tap the player to open their dashboard.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
