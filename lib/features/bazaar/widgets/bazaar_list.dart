import 'package:flutter/material.dart';
import 'package:hypixel_tracker/domain/entities/bazaar_item.dart';
import 'package:hypixel_tracker/features/bazaar/widgets/bazaar_item_card.dart';

class BazaarList extends StatelessWidget {
  const BazaarList({super.key, required this.items, required this.onTap});

  final List<BazaarItem> items;
  final ValueChanged<BazaarItem> onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // Keeps pull-to-refresh working when the list is shorter than the screen.
      physics: const AlwaysScrollableScrollPhysics(),
      // No padding given: the list takes it from MediaQuery, so it starts
      // below the app bar and scrolls under it.
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return BazaarItemCard(item: item, onTap: () => onTap(item));
      },
    );
  }
}
