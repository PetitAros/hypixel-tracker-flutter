import 'package:hypixel_tracker/domain/entities/skyblock_events.dart';

// One entry of skyblock/firesales.
class FireSaleModel {
  final String itemId;
  final int start;
  final int end;
  final int amount;
  final int price;

  const FireSaleModel({
    required this.itemId,
    required this.start,
    required this.end,
    required this.amount,
    required this.price,
  });

  factory FireSaleModel.fromJson(Map<String, dynamic> json) {
    return FireSaleModel(
      itemId: json['item_id'] as String,
      start: json['start'] as int,
      end: json['end'] as int,
      amount: json['amount'] as int,
      price: json['price'] as int,
    );
  }

  // The API only gives the id: "SNOW_SUIT" -> "Snow Suit".
  FireSale toEntity() {
    final name = itemId
        .split('_')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0] + word.substring(1).toLowerCase())
        .join(' ');

    return FireSale(
      itemId: itemId,
      itemName: name,
      start: DateTime.fromMillisecondsSinceEpoch(start),
      end: DateTime.fromMillisecondsSinceEpoch(end),
      amount: amount,
      price: price,
    );
  }
}

// resources/skyblock/election: the mayor in office and the open ballot.
class ElectionModel {
  final Mayor mayor;

  /// Null between elections.
  final Election? current;

  const ElectionModel({required this.mayor, required this.current});

  factory ElectionModel.fromJson(Map<String, dynamic> body) {
    final mayor = body['mayor'] as Map<String, dynamic>;
    final minister = mayor['minister'] as Map<String, dynamic>?;
    final current = body['current'] as Map<String, dynamic>?;

    return ElectionModel(
      mayor: Mayor(
        name: mayor['name'] as String,
        perks: [
          for (final perk in mayor['perks'] as List? ?? [])
            perk['name'] as String,
        ],
        minister: minister?['name'] as String?,
      ),
      current: current == null
          ? null
          : Election(
              year: current['year'] as int,
              candidates: [
                for (final candidate in current['candidates'] as List)
                  Candidate(
                    name: candidate['name'] as String,
                    // Hidden until enough people voted.
                    votes: candidate['votes'] as int? ?? 0,
                  ),
              ]..sort((a, b) => b.votes.compareTo(a.votes)),
            ),
    );
  }
}

// resources/skyblock/bingo, without the goals.
class BingoModel {
  static BingoEvent? fromJson(Map<String, dynamic> body) {
    final name = body['name'] as String?;
    final start = body['start'] as int?;
    final end = body['end'] as int?;
    if (name == null || start == null || end == null) return null;

    return BingoEvent(
      name: name,
      start: DateTime.fromMillisecondsSinceEpoch(start),
      end: DateTime.fromMillisecondsSinceEpoch(end),
    );
  }
}
