import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';
import 'package:hypixel_tracker/core/utils/formatters.dart';
import 'package:hypixel_tracker/core/widgets/async_view.dart';
import 'package:hypixel_tracker/core/widgets/coflnet_credit.dart';
import 'package:hypixel_tracker/core/widgets/fading_app_bar.dart';
import 'package:hypixel_tracker/domain/entities/bazaar_item.dart';
import 'package:hypixel_tracker/domain/entities/bazaar_item_detail.dart';
import 'package:hypixel_tracker/domain/repositories/market_repository.dart';

// Live prices, 24 hour range and order book of one bazaar product.
class BazaarItemDetailPage extends StatelessWidget {
  const BazaarItemDetailPage({
    super.key,
    required this.item,
    required this.repository,
  });

  final BazaarItem item;
  final MarketRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FadingAppBar(title: item.displayName),
      body: Column(
        children: [
          Expanded(
            child: AsyncView<BazaarItemDetail>(
              load: () => repository.bazaarDetail(item.id),
              isEmpty: (detail) => false,
              emptyText: '',
              errorText: 'Could not load this item. Check your connection.',
              builder: (context, detail) => _DetailList(detail: detail),
            ),
          ),
          CoflnetCredit(itemTag: item.id),
        ],
      ),
    );
  }
}

class _DetailList extends StatelessWidget {
  const _DetailList({required this.detail});

  final BazaarItemDetail detail;

  // The order book can hold dozens of lines; the best ones are enough.
  static const _maxOrders = 5;

  @override
  Widget build(BuildContext context) {
    final range = detail.dayRange;

    return ListView(
      // Keeps pull-to-refresh working when the content is short.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top,
        bottom: AppSpacing.sm,
      ),
      children: [
        _Section(
          title: 'Prices',
          rows: [
            ('Buy', Formatters.compact(detail.buyPrice)),
            ('Sell', Formatters.compact(detail.sellPrice)),
          ],
        ),
        if (range != null)
          _Section(
            title: 'Last 24 hours',
            rows: [
              ('Buy', _range(range.minBuy, range.maxBuy)),
              ('Sell', _range(range.minSell, range.maxSell)),
            ],
          ),
        _Section(
          title: 'Volume',
          rows: [
            ('Buy offers', Formatters.compact(detail.buyVolume)),
            ('Sell offers', Formatters.compact(detail.sellVolume)),
            ('Bought this week', Formatters.compact(detail.buyMovingWeek)),
            ('Sold this week', Formatters.compact(detail.sellMovingWeek)),
          ],
        ),
        if (detail.buyOrders.isNotEmpty)
          _Section(title: 'Top buy orders', rows: _orders(detail.buyOrders)),
        if (detail.sellOrders.isNotEmpty)
          _Section(title: 'Top sell orders', rows: _orders(detail.sellOrders)),
      ],
    );
  }

  static String _range(double low, double high) {
    return '${Formatters.compact(low)} to ${Formatters.compact(high)}';
  }

  static List<(String, String)> _orders(List<BazaarOrder> orders) {
    return [
      for (final order in orders.take(_maxOrders))
        (
          Formatters.compact(order.pricePerUnit),
          '${Formatters.compact(order.amount)} items',
        ),
    ];
  }
}

// A titled card of label / value rows.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleMedium),
            for (final (label, value) in rows) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(child: Text(label, style: textTheme.bodyMedium)),
                  Text(value, style: textTheme.bodyLarge),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
