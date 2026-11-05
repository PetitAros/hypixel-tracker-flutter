import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/widgets/coflnet_credit.dart';
import 'package:hypixel_tracker/core/widgets/fading_app_bar.dart';
import 'package:hypixel_tracker/domain/entities/player_profiles.dart';
import 'package:hypixel_tracker/features/profile/widgets/collection_row.dart';

// Every collection of one category (Farming, Mining...) with its tier.
class CollectionCategoryPage extends StatelessWidget {
  const CollectionCategoryPage({
    super.key,
    required this.category,
    required this.playerName,
    required this.collections,
  });

  final String category;
  final String playerName;
  final List<CollectionProgress> collections;

  @override
  Widget build(BuildContext context) {
    // Starts below the app bar and ends above the navigation bar.
    final inset = MediaQuery.paddingOf(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FadingAppBar(
        title: category,
        subtitle: playerName,
        // The collection textures come from SkyCofl.
        actions: const [CoflnetCreditButton()],
      ),
      body: ListView(
        padding: EdgeInsets.only(
          top: inset.top + AppSpacing.sm,
          bottom: inset.bottom + AppSpacing.sm,
        ),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                spacing: AppSpacing.md,
                children: [
                  for (final collection in collections)
                    CollectionRow(collection: collection),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
