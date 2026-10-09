import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/widgets/coflnet_credit.dart';
import 'package:hypixel_tracker/core/widgets/fading_app_bar.dart';
import 'package:hypixel_tracker/core/widgets/skeleton.dart';
import 'package:hypixel_tracker/core/widgets/state_message.dart';
import 'package:hypixel_tracker/domain/entities/bazaar_category.dart';
import 'package:hypixel_tracker/domain/repositories/bazaar_repository.dart';
import 'package:hypixel_tracker/domain/repositories/market_repository.dart';
import 'package:hypixel_tracker/features/bazaar/bazaar_category_page.dart';
import 'package:hypixel_tracker/features/bazaar/bazaar_controller.dart';
import 'package:hypixel_tracker/features/bazaar/bazaar_status.dart';
import 'package:hypixel_tracker/features/bazaar/widgets/bazaar_category_grid.dart';

// The bazaar menu: a grid of categories, each opening its list of products.
class BazaarPage extends StatefulWidget {
  const BazaarPage({
    super.key,
    required this.repository,
    required this.marketRepository,
  });

  final BazaarRepository repository;
  final MarketRepository marketRepository;

  @override
  State<BazaarPage> createState() => _BazaarPageState();
}

class _BazaarPageState extends State<BazaarPage> {
  late final BazaarController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BazaarController(widget.repository)..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Null opens every product.
  void _openCategory(BazaarCategory? category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BazaarCategoryPage(
          category: category,
          controller: _controller,
          marketRepository: widget.marketRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;
        final status = bazaarStatus(state);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: FadingAppBar(
            title: 'Bazaar',
            subtitle: status?.text,
            subtitleColor: status?.offline == true ? AppColors.warning : null,
            actions: const [CoflnetCreditButton()],
          ),
          body: switch (state) {
            BazaarLoading() => const SkeletonList(columns: 2),
            BazaarEmpty() => const StateMessage(
              text: 'No bazaar items to show.',
            ),
            BazaarError() => StateMessage(
              text: 'Could not load the bazaar. Check your connection.',
              onRetry: _controller.load,
            ),
            BazaarData(:final snapshot) => Builder(
              builder: (context) => RefreshIndicator(
                // Start the spinner below the app bar, not behind it.
                edgeOffset: MediaQuery.paddingOf(context).top,
                onRefresh: _controller.load,
                child: BazaarCategoryGrid(
                  items: snapshot.items,
                  onTap: _openCategory,
                ),
              ),
            ),
          },
        );
      },
    );
  }
}
