// The sections of the bazaar, close to the in-game menu.
// The API has no category, so each product is sorted by BazaarRepository.
enum BazaarCategory {
  farming('Farming'),
  mining('Mining'),
  combat('Combat'),
  woodsAndFishes('Woods & Fishes'),
  enchantments('Enchantments'),
  shards('Shards'),
  oddities('Oddities');

  const BazaarCategory(this.label);

  final String label;
}
