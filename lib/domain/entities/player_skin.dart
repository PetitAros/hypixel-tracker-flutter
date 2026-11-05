// The skin a player wears: a 64x64 texture (64x32 for very old skins).
class PlayerSkin {
  final String url;

  /// The "Alex" model, with arms 3 pixels wide instead of 4.
  final bool slim;

  const PlayerSkin({required this.url, required this.slim});
}
