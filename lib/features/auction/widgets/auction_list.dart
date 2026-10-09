import 'package:flutter/material.dart';
import 'package:hypixel_tracker/domain/entities/auction_page.dart';
import 'package:hypixel_tracker/features/auction/widgets/auction_card.dart';

class AuctionList extends StatelessWidget {
  const AuctionList({super.key, required this.page});

  final AuctionPage page;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // Keeps pull-to-refresh working when the list is shorter than the screen.
      physics: const AlwaysScrollableScrollPhysics(),
      // No padding given: the list takes it from MediaQuery, so it starts
      // below the app bar and ends above the navigation bar.
      itemCount: page.items.length,
      itemBuilder: (context, index) => AuctionCard(auction: page.items[index]),
    );
  }
}
