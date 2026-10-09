import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/widgets/fading_app_bar.dart';
import 'package:hypixel_tracker/core/widgets/state_message.dart';
import 'package:hypixel_tracker/domain/entities/player.dart';
import 'package:hypixel_tracker/domain/repositories/player_repository.dart';
import 'package:hypixel_tracker/features/profile/player_search_controller.dart';

// Finds a player by username. For now it only shows the account found;
// the SkyBlock data comes later, once the Hypixel key is available.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.repository});

  final PlayerRepository repository;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
          PlayerSearchFound(:final player) => _PlayerView(player: player),
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

class _PlayerView extends StatelessWidget {
  const _PlayerView({required this.player});

  final Player player;

  static const _avatarSize = 48.0;

  Future<void> _copyUuid(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: player.uuid));
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
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(
                  Icons.account_circle,
                  size: _avatarSize,
                  color: AppColors.gold,
                ),
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
                      SelectableText(player.uuid, style: textTheme.bodyLarge),
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
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'SkyBlock data for this player is not loaded yet.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
