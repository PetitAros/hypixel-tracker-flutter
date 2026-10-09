// A Minecraft account: what Hypixel needs to look up SkyBlock data.
class Player {
  final String uuid; // 32 hex characters, no dashes
  final String name; // with the player's own capitalisation

  const Player({required this.uuid, required this.name});
}
