import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:hypixel_tracker/domain/entities/bazaar_item_detail.dart';
import 'package:hypixel_tracker/domain/entities/item_auction.dart';
import 'package:hypixel_tracker/domain/entities/item_summary.dart';

class CoflnetApiException implements Exception {
  final String message;

  const CoflnetApiException(this.message);

  @override
  String toString() => 'CoflnetApiException: $message';
}

// SkyCofl community API, for what Hypixel does not offer: item search,
// auctions by item and bazaar history. Keyless routes only.
// Their terms ask for a visible credit wherever the data is shown: CoflnetCredit.
class CoflnetRemoteDatasource {
  final http.Client client;

  CoflnetRemoteDatasource({required this.client});

  static const _baseUrl = 'https://sky.coflnet.com/api';
  static const _timeout = Duration(seconds: 15);

  /// The texture of an item, as a small PNG (or GIF for animated items).
  static String iconUrl(String itemTag) {
    return 'https://sky.coflnet.com/static/icon/${Uri.encodeComponent(itemTag)}';
  }

  Future<List<ItemSummary>> searchItems(String query) {
    final path = 'item/search/${Uri.encodeComponent(query)}';

    return _get(path, 'item search', (body) {
      final items = body as List<dynamic>? ?? const [];

      return items.map((item) {
        // The tier is a string, or -1 when Coflnet does not know it.
        final tier = item['tier'];
        return ItemSummary(
          id: item['id'] as String,
          name: item['name'] as String,
          tier: tier is String ? tier : 'UNKNOWN',
          iconUrl: item['iconUrl'] as String?,
        );
      }).toList();
    });
  }

  /// About a dozen active auctions of one item, cheapest first.
  Future<List<ItemAuction>> getActiveAuctions(String itemTag) {
    final path = 'auctions/tag/${Uri.encodeComponent(itemTag)}/active/overview';

    return _get(path, 'item auctions', (body) {
      final auctions = body as List<dynamic>? ?? const [];

      return auctions
          .map(
            (auction) => ItemAuction(
              id: auction['uuid'] as String,
              sellerName: auction['playerName'] as String? ?? 'Unknown',
              price: (auction['price'] as num).toInt(),
              endsAt: _parseUtc(auction['end'] as String),
            ),
          )
          .toList();
    });
  }

  /// The item sold by one auction, found from the auction id.
  Future<ItemSummary> getAuctionItem(String auctionId) {
    final path = 'auction/${Uri.encodeComponent(auctionId)}';

    return _get(path, 'auction', (body) {
      if (body == null) {
        throw const CoflnetApiException('Unknown auction');
      }

      final tag = body['tag'] as String;
      final tier = body['tier'];
      return ItemSummary(
        id: tag,
        name: body['itemName'] as String? ?? tag,
        tier: tier is String ? tier : 'UNKNOWN',
        iconUrl: iconUrl(tag),
      );
    });
  }

  Future<BazaarItemDetail> getBazaarSnapshot(String itemTag) {
    final path = 'bazaar/${Uri.encodeComponent(itemTag)}/snapshot';

    return _get(path, 'bazaar snapshot', (body) {
      // An unknown product answers 204 with no body.
      if (body == null) {
        throw const CoflnetApiException('No bazaar data for this item');
      }

      return BazaarItemDetail(
        buyPrice: (body['buyPrice'] as num).toDouble(),
        sellPrice: (body['sellPrice'] as num).toDouble(),
        buyVolume: (body['buyVolume'] as num).toInt(),
        sellVolume: (body['sellVolume'] as num).toInt(),
        buyMovingWeek: (body['buyMovingWeek'] as num).toInt(),
        sellMovingWeek: (body['sellMovingWeek'] as num).toInt(),
        buyOrders: _parseOrders(body['buyOrders']),
        sellOrders: _parseOrders(body['sellOrders']),
      );
    });
  }

  /// Price range over the last 24 hours, or null when there is no history.
  Future<BazaarDayRange?> getBazaarDayRange(String itemTag) {
    final path = 'bazaar/${Uri.encodeComponent(itemTag)}/history/day';

    return _get(path, 'bazaar history', (body) {
      final points = body as List<dynamic>? ?? const [];

      // Some points have no value for a side that had no orders: skip them.
      double? fold(String key, double Function(double, double) pick) {
        final values = points
            .map((point) => (point[key] as num?)?.toDouble())
            .nonNulls;
        return values.isEmpty ? null : values.reduce(pick);
      }

      final minBuy = fold('minBuy', (a, b) => a < b ? a : b);
      final maxBuy = fold('maxBuy', (a, b) => a > b ? a : b);
      final minSell = fold('minSell', (a, b) => a < b ? a : b);
      final maxSell = fold('maxSell', (a, b) => a > b ? a : b);
      if (minBuy == null ||
          maxBuy == null ||
          minSell == null ||
          maxSell == null) {
        return null;
      }

      return BazaarDayRange(
        // The API sends the newest point first.
        points: [
          for (final point in points.reversed)
            if (point['buy'] != null && point['sell'] != null)
              BazaarPricePoint(
                time: _parseUtc(point['timestamp'] as String),
                buy: (point['buy'] as num).toDouble(),
                sell: (point['sell'] as num).toDouble(),
              ),
        ],
        minBuy: minBuy,
        maxBuy: maxBuy,
        minSell: minSell,
        maxSell: maxSell,
      );
    });
  }

  static List<BazaarOrder> _parseOrders(dynamic orders) {
    return (orders as List<dynamic>? ?? const [])
        .map(
          (order) => BazaarOrder(
            pricePerUnit: (order['pricePerUnit'] as num).toDouble(),
            amount: (order['amount'] as num).toInt(),
            orders: (order['orders'] as num).toInt(),
          ),
        )
        .toList();
  }

  // Coflnet dates are UTC without a zone suffix: "2026-10-13T18:17:44".
  static DateTime _parseUtc(String value) {
    return DateTime.parse(value.endsWith('Z') ? value : '${value}Z').toLocal();
  }

  // [parse] receives the decoded JSON, or null for an empty answer.
  Future<T> _get<T>(
    String path,
    String label,
    T Function(dynamic body) parse,
  ) async {
    final response = await client
        .get(Uri.parse('$_baseUrl/$path'))
        .timeout(_timeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw CoflnetApiException(
        'Request for $label failed: ${response.statusCode}',
      );
    }

    try {
      return parse(response.body.isEmpty ? null : jsonDecode(response.body));
    } on TypeError {
      throw CoflnetApiException('Unexpected $label response format');
    } on FormatException {
      throw CoflnetApiException('Unexpected $label response format');
    }
  }
}
