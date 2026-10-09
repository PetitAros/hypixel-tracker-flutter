import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/domain/repositories/auction_repository.dart';
import 'package:hypixel_tracker/domain/repositories/bazaar_repository.dart';
import 'package:hypixel_tracker/domain/repositories/market_repository.dart';
import 'package:hypixel_tracker/domain/repositories/player_repository.dart';
import 'package:hypixel_tracker/features/auction/auctions_page.dart';
import 'package:hypixel_tracker/features/bazaar/bazaar_page.dart';
import 'package:hypixel_tracker/features/profile/profile_page.dart';

// The main tabs, under a floating see-through navigation bar.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.auctionRepository,
    required this.bazaarRepository,
    required this.marketRepository,
    required this.playerRepository,
  });

  final AuctionRepository auctionRepository;
  final BazaarRepository bazaarRepository;
  final MarketRepository marketRepository;
  final PlayerRepository playerRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // The app opens on the profile, the middle tab.
  static const _profileIndex = 1;

  int _index = _profileIndex;

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
          ProfilePage(repository: widget.playerRepository),
          BazaarPage(
            repository: widget.bazaarRepository,
            marketRepository: widget.marketRepository,
          ),
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
    (Icons.person, 'Profile'),
    (Icons.storefront, 'Bazaar'),
  ];

  static const _blur = 16.0;

  // Mostly transparent: the blur keeps the icons readable over the list.
  static const _backgroundOpacity = 0.45;
  static const _borderOpacity = 0.08;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: AppSpacing.sm),
      // Only as wide as its buttons, centred at the bottom of the screen.
      child: Align(
        heightFactor: 1,
        child: ClipRRect(
          borderRadius: AppRadius.lg,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(
                  alpha: _backgroundOpacity,
                ),
                borderRadius: AppRadius.lg,
                border: Border.all(
                  color: AppColors.onBackground.withValues(
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
          foregroundColor: selected ? AppColors.gold : AppColors.onSurfaceMuted,
          backgroundColor: selected
              ? AppColors.gold.withValues(alpha: _selectedOpacity)
              : Colors.transparent,
        ),
      ),
    );
  }
}
