import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hypixel_tracker/data/models/skyblock_profile_model.dart';

class WorkerApiException implements Exception {
  final String message;

  const WorkerApiException(this.message);

  @override
  String toString() => 'WorkerApiException: $message';
}

// Our Cloudflare Worker: the Hypixel routes that need the API key.
// The Worker adds the key, so it never ships in the app.
class WorkerRemoteDatasource {
  final http.Client client;

  WorkerRemoteDatasource({required this.client});

  static const _baseUrl = 'https://hypixel-profil.erwan9-lecomte.workers.dev';
  static const _timeout = Duration(seconds: 20);

  /// The profile [uuid] last played on. Null when they never played SkyBlock.
  Future<SkyblockProfileModel?> getSelectedProfile(String uuid) async {
    final response = await client
        .get(Uri.parse('$_baseUrl/${Uri.encodeComponent(uuid)}'))
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw WorkerApiException(
        'Profile request failed: ${response.statusCode}',
      );
    }

    // The response holds every profile with its inventories: often over a
    // megabyte, so it is decoded off the UI thread.
    return compute(_parse, (body: response.body, uuid: uuid));
  }

  static SkyblockProfileModel? _parse(({String body, String uuid}) input) {
    try {
      final body = jsonDecode(input.body) as Map<String, dynamic>;

      if (body['success'] != true) {
        throw WorkerApiException(
          body['cause']?.toString() ?? 'Unknown Hypixel API error',
        );
      }

      final profiles = body['profiles'] as List<dynamic>?;
      if (profiles == null || profiles.isEmpty) return null;

      final selected = profiles.firstWhere(
        (profile) => profile['selected'] == true,
        orElse: () => profiles.first,
      );
      return SkyblockProfileModel.fromJson(
        selected as Map<String, dynamic>,
        input.uuid,
      );
    } on TypeError {
      throw const WorkerApiException('Unexpected profile response format');
    } on FormatException {
      throw const WorkerApiException('Unexpected profile response format');
    }
  }
}
