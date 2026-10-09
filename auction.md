# Auctions: to-do list

Steps to build the auctions screen the same way as the bazaar (same layers, same cache-first behaviour). Each step names the bazaar file to copy the pattern from.

API facts below were checked against the live API on 2026-10-09.

## 0. What is different from the bazaar

| | Bazaar | Auctions |
|---|---|---|
| Endpoint | `skyblock/bazaar` | `skyblock/auctions?page=N` |
| Size | 1 call, about 2,200 products | 45 pages of 1,000 auctions (44,494 in total), about 2.3 MB per page |
| Key | `product_id` | `uuid` |
| Name | missing, taken from the items resource | already there: `item_name` |
| Pagination | none | required (socle constraint 9) |

Response envelope: `success`, `page`, `totalPages`, `totalAuctions`, `lastUpdated`, `auctions`.
A page past the end returns `{"success": false, "cause": "Page not found"}`.

Useful fields of one auction: `uuid`, `item_name`, `tier`, `category`, `bin`, `starting_bid`, `highest_bid_amount`, `start`, `end`, `auctioneer`.
Ignore `item_lore` and `item_bytes` for the list: they are most of the 2.3 MB.

## 1. Domain

- [ ] Fill `lib/domain/entities/auction.dart` (it is empty): `id`, `itemName`, `tier`, `category`, `isBin`, `price`, `endsAt`.
  - `price` = `highest_bid_amount` if above 0, otherwise `starting_bid`.
- [ ] Add `lib/domain/entities/auction_page.dart`: `items`, `page`, `totalPages`, `lastUpdated`, `fromCache`. Pattern: `bazaar_snapshot.dart`.
- [ ] Add `lib/domain/repositories/auction_repository.dart` with two methods, like `bazaar_repository.dart`:
  - `AuctionPage? readCached(int page)`
  - `Future<AuctionPage> fetchPage(int page)`

## 2. Data: model and Hive

- [ ] Add `lib/data/models/auction_model.dart`. Pattern: `bazaar_item_model.dart`.
  - `@HiveType(typeId: 1)`. Type id 0 is taken by the bazaar; never reuse an id.
  - `fromJson` for the fields listed above, and `toEntity()`.
  - Store `end` as milliseconds (int), convert to `DateTime` in `toEntity()`.
- [ ] Run `dart run build_runner build` to generate `auction_model.g.dart`.
- [ ] Register the adapter in `main.dart`: `Hive.registerAdapter(AuctionModelAdapter())`.

## 3. Data: remote

- [ ] Add `getAuctions(int page)` to `hypixel_remote_datasource.dart`, using the existing `_get` helper.
  - It must return the models **and** `totalPages` and `lastUpdated`, so return a small result class, not just a list.
- [ ] Parse off the UI thread: 2.3 MB of JSON per page will drop frames. Wrap the decode in `compute()` or `Isolate.run()`.

## 4. Data: local

- [ ] Add `lib/data/datasources/local/auction_local_datasource.dart`. Pattern: `bazaar_local_datasource.dart`.
- [ ] Decide what is cached. Recommended: only the pages the user has opened, not all 45.
  - Simplest layout: one box, key = `uuid`, plus a meta entry per page listing its uuids in order and its `lastUpdated`.
- [ ] Keep the write safe against a kill, as in `save()` for the bazaar: write new entries first, delete stale ones after.
- [ ] `HiveBoxes.auctions` already exists in `hive_boxes.dart`; open it in `main.dart`.

## 5. Data: repository

- [ ] Add `lib/data/repositories/auction_repository_impl.dart`. Pattern: `bazaar_repository_impl.dart`.
  - `fetchPage`: remote call, save to Hive, return the page with `fromCache: false`.
  - `readCached`: return the saved page or null.
- [ ] No names lookup needed here.

## 6. Controller

- [ ] Add `lib/features/auctions/auctions_controller.dart`. Pattern: `bazaar_controller.dart`.
- [ ] States: reuse the same four (loading, data, empty, error) and the same `sync` idea (refreshing, up to date, offline).
- [ ] Extra state for pagination: `isLoadingMore`, `hasMore` (`page + 1 < totalPages`), and a "load more failed" flag.
- [ ] `load()`: show the cached page 0 at once, then fetch page 0.
- [ ] `loadMore()`: fetch the next page and append. Ignore the call if one is already running.
- [ ] Keep the request id guard, so a late response never overwrites a newer one.
- [ ] Remove duplicates by `uuid` when appending: the auction list moves between two calls, so the same auction can show up on two pages.
- [ ] If `lastUpdated` changes between two pages, the pages no longer line up. Simplest answer: accept it and rely on the duplicate filter.

## 7. UI

- [ ] `lib/features/auctions/auctions_page.dart`. Pattern: `bazaar_page.dart`.
- [ ] `widgets/auction_list.dart`: `ListView.builder` with one extra row at the end.
  - That last row shows a spinner while loading more, a Retry button if it failed, nothing when `hasMore` is false.
  - Trigger `loadMore()` when the user gets near the end (scroll listener, or when the last row is built).
- [ ] `widgets/auction_card.dart`: name, tier (colour per rarity), price, BIN or auction, time left.
- [ ] Reuse `StateMessage` (`lib/core/widgets/state_message.dart`) for empty and error.
- [ ] Reuse the status bar. `BazaarStatusBar` takes a `BazaarSnapshot` today: make it take a date and a sync value so both screens can use it, and move it to `lib/core/widgets/`.
- [ ] Give the list a fixed row height (`itemExtent` or `prototypeItem`): this is the list used for the performance module.

## 8. Wiring

- [ ] In `main.dart`: open the box, build the repository, pass it to the app.
- [ ] Add navigation between Bazaar and Auctions (bottom navigation bar). There is none yet: `home` is the bazaar page.

## 9. Check before calling it done

- [ ] `flutter analyze` is clean.
- [ ] Airplane mode after a full restart: the pages already opened are still readable, with the offline bar.
- [ ] Scrolling to the end loads the next page once, not several times.
- [ ] Load-more failure shows Retry and Retry works.
- [ ] Release APK from the CI works on the phone.

## Later, not needed for the first version

- **Icons:** an auction has no item id in clear. It is inside `item_bytes` (base64, gzip, NBT). Either decode it or map `item_name` to an id through the items resource.
- **Filters and sort:** the API has none, so they only apply to the pages already loaded.
- **Detail screen:** `item_lore` holds the description, with `§` colour codes to strip or render.
