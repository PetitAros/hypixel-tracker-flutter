import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/domain/repositories/auction_repository.dart';
import 'package:hypixel_tracker/domain/repositories/bazaar_repository.dart';
import 'package:hypixel_tracker/domain/repositories/market_repository.dart';
import 'package:hypixel_tracker/features/auction/auctions_page.dart';
import 'package:hypixel_tracker/features/bazaar/bazaar_page.dart';

// The two main tabs, under a floating see-through navigation bar.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.auctionRepository,
    required this.bazaarRepository,
    required this.marketRepository,
  });

  final AuctionRepository auctionRepository;
  final BazaarRepository bazaarRepository;
  final MarketRepository marketRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The pages run under the navigation bar; their lists read the bottom
      // padding from MediaQuery so the last item can scroll clear of it.
      extendBody: true,
      // IndexedStack keeps both tabs alive: no reload when switching.
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

  static const _height = 64.0;
  static const _blur = 16.0;

  // Mostly transparent: the blur keeps the labels readable over the list.
  static const _backgroundOpacity = 0.45;
  static const _borderOpacity = 0.08;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: ClipRRect(
          borderRadius: AppRadius.pill,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(
                  alpha: _backgroundOpacity,
                ),
                borderRadius: AppRadius.pill,
                border: Border.all(
                  color: AppColors.onBackground.withValues(
                    alpha: _borderOpacity,
                  ),
                ),
              ),
              child: NavigationBar(
                height: _height,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                selectedIndex: index,
                onDestinationSelected: onChanged,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.gavel),
                    label: 'Auctions',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.storefront),
                    label: 'Bazaar',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
