import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/domain/repositories/auction_repository.dart';
import 'package:hypixel_tracker/domain/repositories/bazaar_repository.dart';
import 'package:hypixel_tracker/domain/repositories/events_repository.dart';
import 'package:hypixel_tracker/domain/repositories/market_repository.dart';
import 'package:hypixel_tracker/domain/repositories/player_repository.dart';
import 'package:hypixel_tracker/features/auction/auctions_page.dart';
import 'package:hypixel_tracker/features/bazaar/bazaar_page.dart';
import 'package:hypixel_tracker/features/events/events_page.dart';
import 'package:hypixel_tracker/features/profile/profile_page.dart';
import 'package:hypixel_tracker/features/settings/settings_controller.dart';
import 'package:hypixel_tracker/features/settings/settings_page.dart';

// The main tabs, under a floating see-through navigation bar.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.auctionRepository,
    required this.bazaarRepository,
    required this.eventsRepository,
    required this.marketRepository,
    required this.playerRepository,
    required this.settingsController,
  });

  final AuctionRepository auctionRepository;
  final BazaarRepository bazaarRepository;
  final EventsRepository eventsRepository;
  final MarketRepository marketRepository;
  final PlayerRepository playerRepository;
  final SettingsController settingsController;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // The app opens on the profile tab.
  int _index = _FloatingNavigationBar.profileIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The pages run under the navigation bar; their lists read the bottom
      // padding from MediaQuery so the last item can scroll clear of it.
      extendBody: true,
      // IndexedStack keeps every tab alive: no reload when switching.
      body: IndexedStack(
        index: _index,
        children: [
          AuctionsPage(
            repository: widget.auctionRepository,
            marketRepository: widget.marketRepository,
          ),
          BazaarPage(
            repository: widget.bazaarRepository,
            marketRepository: widget.marketRepository,
          ),
          ProfilePage(repository: widget.playerRepository),
          EventsPage(repository: widget.eventsRepository),
          SettingsPage(controller: widget.settingsController),
        ],
      ),
      bottomNavigationBar: _FloatingNavigationBar(
        index: _index,
        onChanged: (index) => setState(() => _index = index),
      ),
    );
  }
}

class _FloatingNavigationBar extends StatelessWidget {
  const _FloatingNavigationBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  // Same order as the pages in the IndexedStack. The names are not shown:
  // they are the tooltips and what screen readers announce.
  static const _tabs = [
    (Icons.gavel, 'Auctions'),
    (Icons.storefront, 'Bazaar'),
    (Icons.person, 'Profile'),
    (Icons.event, 'Events'),
    (Icons.settings, 'Options'),
  ];

  /// The profile sits in the middle, as a bigger button over the bar.
  static const profileIndex = 2;

  // How far the profile button rises above the top of the bar.
  static const _popOut = 16.0;

  static const _blur = 16.0;

  // Mostly transparent: the blur keeps the icons readable over the list.
  static const _backgroundOpacity = 0.45;
  static const _borderOpacity = 0.08;

  @override
  Widget build(BuildContext context) {
    final (profileIcon, profileLabel) = _tabs[profileIndex];

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: AppSpacing.sm),
      // Only as wide as its buttons, centred at the bottom of the screen.
      child: Align(
        heightFactor: 1,
        // The profile button is drawn over the bar, in a gap left for it.
        // The top padding keeps the part above the bar inside the stack,
        // where it can still be tapped.
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: _popOut),
              child: _bar(context),
            ),
            Positioned(
              bottom: AppSpacing.xs,
              child: _ProfileButton(
                icon: profileIcon,
                label: profileLabel,
                selected: index == profileIndex,
                onTap: () => onChanged(profileIndex),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.lg,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.palette.surfaceVariant.withValues(
              alpha: _backgroundOpacity,
            ),
            borderRadius: AppRadius.lg,
            border: Border.all(
              color: context.palette.onBackground.withValues(
                alpha: _borderOpacity,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.xs,
              children: [
                for (final (i, (icon, label)) in _tabs.indexed)
                  if (i == profileIndex)
                    const SizedBox(width: _ProfileButton.size)
                  else
                    _TabButton(
                      icon: icon,
                      label: label,
                      selected: i == index,
                      onTap: () => onChanged(i),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// The profile tab: a bigger filled square that rises above the bar.
class _ProfileButton extends StatelessWidget {
  const _ProfileButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const size = 64.0;
  static const _iconSize = 32.0;
  static const _shadowBlur = 16.0;
  static const _shadowOpacity = 0.5;
  static const _borderOpacity = 0.12;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    // Open: filled with the accent and glowing. Closed: a plain square in
    // the bar's colours, like the other tabs, so the difference is clear.
    return Semantics(
      selected: selected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.lg,
          border: selected
              ? null
              : Border.all(
                  color: palette.onBackground.withValues(alpha: _borderOpacity),
                ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: palette.accent.withValues(alpha: _shadowOpacity),
                blurRadius: _shadowBlur,
              ),
          ],
        ),
        child: IconButton(
          onPressed: onTap,
          tooltip: label,
          icon: Icon(icon, size: _iconSize),
          style: IconButton.styleFrom(
            fixedSize: const Size.square(size),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
            foregroundColor: selected
                ? palette.onAccent
                : palette.onSurfaceMuted,
            backgroundColor: selected ? palette.accent : palette.surfaceVariant,
          ),
        ),
      ),
    );
  }
}

// One page of the bar: an icon in a rounded square, filled when selected.
class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _size = 44.0;
  static const _selectedOpacity = 0.2;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: IconButton(
        onPressed: onTap,
        tooltip: label,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          fixedSize: const Size.square(_size),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
          foregroundColor: selected
              ? context.palette.accent
              : context.palette.onSurfaceMuted,
          backgroundColor: selected
              ? context.palette.accent.withValues(alpha: _selectedOpacity)
              : Colors.transparent,
        ),
      ),
    );
  }
}
