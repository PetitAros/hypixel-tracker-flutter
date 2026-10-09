import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/bazaar_snapshot.dart';
import 'bazaar_item_card.dart';

class BazaarList extends StatelessWidget {
  const BazaarList({super.key, required this.snapshot});

  final BazaarSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // Keeps pull-to-refresh working when the list is shorter than the screen.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: snapshot.items.length,
      itemBuilder: (context, index) =>
          BazaarItemCard(item: snapshot.items[index]),
    );
  }
}
