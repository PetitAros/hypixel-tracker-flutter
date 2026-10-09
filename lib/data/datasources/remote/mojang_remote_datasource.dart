import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:hypixel_tracker/domain/entities/player.dart';

class MojangApiException implements Exception {
  final String message;

  const MojangApiException(this.message);

  @override
  String toString() => 'MojangApiException: $message';
}

// Mojang's public API: turns a username into the account UUID.
// Hypixel only accepts UUIDs, so every player lookup starts here. No key.
class MojangRemoteDatasource {
  final http.Client client;

  MojangRemoteDatasource({required this.client});

  static const _baseUrl = 'https://api.mojang.com';
  static const _timeout = Duration(seconds: 15);

  /// Null when no account has this name.
  Future<Player?> getPlayerByName(String name) async {
    final uri = Uri.parse(
      '$_baseUrl/users/profiles/minecraft/${Uri.encodeComponent(name)}',
    );

    final response = await client.get(uri).timeout(_timeout);

    // Unknown names answer 404 (204 on older versions of the API).
    if (response.statusCode == 404 || response.statusCode == 204) return null;
    if (response.statusCode != 200) {
      throw MojangApiException('Player lookup failed: ${response.statusCode}');
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return Player(uuid: body['id'] as String, name: body['name'] as String);
    } on TypeError {
      throw const MojangApiException('Unexpected player response format');
    } on FormatException {
      throw const MojangApiException('Unexpected player response format');
    }
  }
}
