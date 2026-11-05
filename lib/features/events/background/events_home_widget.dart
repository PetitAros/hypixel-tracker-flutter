import 'package:home_widget/home_widget.dart';
import 'package:hypixel_tracker/core/utils/formatters.dart';
import 'package:hypixel_tracker/domain/entities/skyblock_events.dart';

// The Android home screen widget (EventsWidgetProvider.kt). Dart writes
// ready-to-show lines; the Kotlin side only puts them in the layout.
class EventsHomeWidget {
  EventsHomeWidget._();

  static const _provider = 'io.lecomte.hypixel_tracker.EventsWidgetProvider';

  static Future<void> update(SkyblockEvents events) async {
    final now = DateTime.now();
    final lines = {
      ..._mayorLines(events),
      ..._bingoLines(events.bingo, now),
      ..._fireSaleLines(events.fireSales, now),
      'updated': Formatters.dateTime(events.fetchedAt),
    };

    for (final MapEntry(:key, :value) in lines.entries) {
      await HomeWidget.saveWidgetData<String>(key, value);
    }
    await HomeWidget.updateWidget(qualifiedAndroidName: _provider);
  }

  static Map<String, String> _mayorLines(SkyblockEvents events) {
    final mayor = events.mayor;
    final election = events.election;
    final closes = Formatters.dateTime(events.termEndsAt);

    return {
      'mayor': mayor.minister == null
          ? 'Mayor ${mayor.name}'
          : 'Mayor ${mayor.name} · minister ${mayor.minister}',
      'mayor_detail': election == null
          ? 'Next election opens ${Formatters.dateTime(events.nextElectionAt)}'
          : election.candidates.isEmpty
          ? 'Election open, closes $closes'
          : 'Election closes $closes · ${election.candidates.first.name} leads',
    };
  }

  static Map<String, String> _bingoLines(BingoEvent? bingo, DateTime now) {
    if (bingo == null) return {'bingo': 'Bingo', 'bingo_detail': 'No event'};

    return {
      'bingo': 'Bingo ${bingo.name}',
      'bingo_detail': now.isBefore(bingo.start)
          ? 'Starts ${Formatters.dateTime(bingo.start)}'
          : now.isBefore(bingo.end)
          ? 'Ends ${Formatters.dateTime(bingo.end)}'
          : 'Ended',
    };
  }

  static Map<String, String> _fireSaleLines(
    List<FireSale> sales,
    DateTime now,
  ) {
    if (sales.isEmpty) {
      return {'fire_sale': 'Fire sales', 'fire_sale_detail': 'None announced'};
    }

    final sale = sales.first;
    final when = now.isBefore(sale.start)
        ? 'Starts ${Formatters.dateTime(sale.start)}'
        : 'Ends ${Formatters.dateTime(sale.end)}';
    final more = sales.length > 1 ? ' · +${sales.length - 1} more' : '';

    return {
      'fire_sale': 'Fire sale: ${sale.itemName}',
      'fire_sale_detail': '$when · ${sale.price} gems$more',
    };
  }
}
