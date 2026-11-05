import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:hypixel_tracker/domain/entities/player.dart';
import 'package:hypixel_tracker/domain/entities/player_skin.dart';

class MojangApiException implements Exception {
  final String message;

  const MojangApiException(this.message);

  @override
  String toString() => 'MojangApiException: $message';
}

// Mojang's public API: turns a username into the account UUID (Hypixel
// only accepts UUIDs, so every player lookup starts here) and gives the
// skin. No key.
class MojangRemoteDatasource {
  final http.Client client;

  MojangRemoteDatasource({required this.client});

  static const _baseUrl = 'https://api.mojang.com';
  static const _sessionUrl = 'https://sessionserver.mojang.com';
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

  /// Null when the player wears the default skin, or the account is gone.
  Future<PlayerSkin?> getSkin(String uuid) async {
    final uri = Uri.parse(
      '$_sessionUrl/session/minecraft/profile/${Uri.encodeComponent(uuid)}',
    );

    final response = await client.get(uri).timeout(_timeout);

    if (response.statusCode == 404 || response.statusCode == 204) return null;
    if (response.statusCode != 200) {
      throw MojangApiException('Skin lookup failed: ${response.statusCode}');
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      // The textures come as base64 JSON inside the "textures" property.
      final property = (body['properties'] as List<dynamic>).firstWhere(
        (property) => property['name'] == 'textures',
      );
      final textures = jsonDecode(
        utf8.decode(base64.decode(property['value'] as String)),
      );
      final skin = textures['textures']['SKIN'] as Map<String, dynamic>?;
      if (skin == null) return null;

      return PlayerSkin(
        // Mojang still links over http, which Android blocks.
        url: (skin['url'] as String).replaceFirst('http://', 'https://'),
        slim: skin['metadata']?['model'] == 'slim',
      );
    } on TypeError {
      throw const MojangApiException('Unexpected skin response format');
    } on FormatException {
      throw const MojangApiException('Unexpected skin response format');
    } on StateError {
      throw const MojangApiException('Unexpected skin response format');
    }
  }
}
