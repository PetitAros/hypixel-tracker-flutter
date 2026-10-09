import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/bazaar_item_model.dart';

class HypixelApiException implements Exception {
  final String message;

  const HypixelApiException(this.message);

  @override
  String toString() => 'HypixelApiException: $message';
}

// Keyless Hypixel endpoints only (bazaar, auctions, resources).
// Player data needs a key and goes through the Worker, not this class.
class HypixelRemoteDatasource {
  final http.Client client;

  HypixelRemoteDatasource({required this.client});

  static const _baseUrl = 'https://api.hypixel.net/v2';
  static const _timeout = Duration(seconds: 15);

  // Formatting codes in item names: "§cRed Gift" and "%%red%%Volcanic Rock"
  static final _colorCode = RegExp('§.|%%[a-z_]+%%');

  Future<List<BazaarItemModel>> getBazaar() {
    return _get('skyblock/bazaar', 'bazaar', (body) {
      final products = body['products'] as Map<String, dynamic>;

      return products.values
          .map((product) => BazaarItemModel.fromJson(product))
          .toList();
    });
  }

  /// Official display names by item id, e.g. "ENCHANTED_COAL" -> "Enchanted Coal".
  Future<Map<String, String>> getItemNames() {
    return _get('resources/skyblock/items', 'items', (body) {
      final items = body['items'] as List<dynamic>;

      return {
        for (final item in items)
          item['id'] as String: (item['name'] as String)
              .replaceAll(_colorCode, '')
              .trim(),
      };
    });
  }

  Future<T> _get<T>(
    String path,
    String label,
    T Function(Map<String, dynamic> body) parse,
  ) async {
    final response = await client
        .get(Uri.parse('$_baseUrl/$path'))
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw HypixelApiException(
        'Request for $label failed: ${response.statusCode}',
      );
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (body['success'] != true) {
        throw HypixelApiException(
          body['cause']?.toString() ?? 'Unknown Hypixel API error',
        );
      }

      return parse(body);
    } on TypeError {
      throw HypixelApiException('Unexpected $label response format');
    } on FormatException {
      throw HypixelApiException('Unexpected $label response format');
    }
  }
}
