import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/widgets/coflnet_credit.dart';
import 'package:hypixel_tracker/core/widgets/fading_app_bar.dart';
import 'package:hypixel_tracker/core/widgets/state_message.dart';
import 'package:hypixel_tracker/domain/entities/bazaar_category.dart';
import 'package:hypixel_tracker/domain/entities/bazaar_item.dart';
import 'package:hypixel_tracker/domain/repositories/market_repository.dart';
import 'package:hypixel_tracker/features/bazaar/bazaar_controller.dart';
import 'package:hypixel_tracker/features/bazaar/bazaar_item_detail_page.dart';
import 'package:hypixel_tracker/features/bazaar/bazaar_status.dart';
import 'package:hypixel_tracker/features/bazaar/widgets/bazaar_list.dart';

// The products of one bazaar category, or all of them when [category] is null.
// Listens to the controller of the bazaar tab, so it stays in sync with it.
class BazaarCategoryPage extends StatelessWidget {
  const BazaarCategoryPage({
    super.key,
    required this.category,
    required this.controller,
    required this.marketRepository,
  });

  final BazaarCategory? category;
  final BazaarController controller;
  final MarketRepository marketRepository;

  void _openItem(BuildContext context, BazaarItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            BazaarItemDetailPage(item: item, repository: marketRepository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        final status = bazaarStatus(state);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: FadingAppBar(
            title: category?.label ?? 'All items',
            subtitle: status?.text,
            subtitleColor: status?.offline == true ? AppColors.warning : null,
            // The textures come from SkyCofl.
            actions: const [CoflnetCreditButton()],
          ),
          body: switch (state) {
            BazaarLoading() => const Center(child: CircularProgressIndicator()),
            BazaarEmpty() => const StateMessage(
              text: 'No bazaar items to show.',
            ),
            BazaarError() => StateMessage(
              text: 'Could not load the bazaar. Check your connection.',
              onRetry: controller.load,
            ),
            BazaarData(:final snapshot) => _buildList(
              context,
              category == null
                  ? snapshot.items
                  : snapshot.items
                        .where((item) => item.category == category)
                        .toList(),
            ),
          },
        );
      },
    );
  }

  Widget _buildList(BuildContext context, List<BazaarItem> items) {
    if (items.isEmpty) {
      return const StateMessage(text: 'No items in this category.');
    }

    return Builder(
      builder: (context) => RefreshIndicator(
        // Start the spinner below the app bar, not behind it.
        edgeOffset: MediaQuery.paddingOf(context).top,
        onRefresh: controller.load,
        child: BazaarList(
          items: items,
          onTap: (item) => _openItem(context, item),
        ),
      ),
    );
  }
}
