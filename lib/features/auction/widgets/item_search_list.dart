import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/rarity_color.dart';
import 'package:hypixel_tracker/core/widgets/item_icon.dart';
import 'package:hypixel_tracker/domain/entities/item_summary.dart';

class ItemSearchList extends StatelessWidget {
  const ItemSearchList({super.key, required this.items, required this.onTap});

  final List<ItemSummary> items;
  final ValueChanged<ItemSummary> onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // No padding given: the list takes it from MediaQuery, so it starts
      // below the app bar and ends above the navigation bar.
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ItemSearchTile(item: item, onTap: () => onTap(item));
      },
    );
  }
}

// One item of a search: texture, name and rarity.
class ItemSearchTile extends StatelessWidget {
  const ItemSearchTile({super.key, required this.item, required this.onTap});

  final ItemSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ItemIcon(url: item.iconUrl),
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        item.tier.replaceAll('_', ' '),
        style: TextStyle(color: rarityColor(item.tier)),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
