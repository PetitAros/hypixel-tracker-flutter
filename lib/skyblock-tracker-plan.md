# SkyBlock Tracker: project plan

Summary of the feasibility discussion for a Flutter app that follows Hypixel SkyBlock progress, bazaar and auctions, checked against the course brief.

Items marked **(verify)** come from memory and should be checked against current docs before you rely on them.

## 1. Verdict

The app is feasible within the brief. Nothing in the brief requires login, notifications or a backend, so the core app (bazaar, auctions, player progress) covers the whole socle. Crash alerts and Firebase are optional extras.

## 2. Hypixel API facts

- The Public API is plain REST at `https://api.hypixel.net/v2`. There is no WebSocket, SSE or webhook.
- The brief allows this: constraint 10 accepts a periodic refresh when the API has no websocket.
- Bazaar, auctions and resources endpoints need **no API key**.
- Player data (SkyBlock profiles, progress) **needs a key**.
- Development keys expire after a few days; a permanent key requires an application to Hypixel **(verify)**. Apply early.
- The Hypixel Mod API is event-driven but only works inside a Minecraft client, so it is not usable here.

## 3. Architecture

```
Flutter app
 ├─ Hypixel data source  ──► api.hypixel.net   (bazaar, auctions, resources; no key)
 ├─ Worker data source   ──► Cloudflare Worker ──► Hypixel (player data; key added server-side)
 ├─ Repository           (arbitrates network vs cache)
 └─ Hive                 (local cache + watchlist)
```

- Two data sources behind one repository, matching the four layers in section 6 of the brief.
- Each base URL lives in exactly one file (the "one file" test).

### Cloudflare Worker (light backend)

- Holds the Hypixel key as a Worker secret. Never ship the key in the APK.
- Expose only the routes you need (player lookup, profiles), not a generic pass-through.
- Cache responses for about a minute with the Workers Cache API to protect the key's rate limit.

## 4. Socle mapping

| # | Constraint | In the app |
|---|---|---|
| 1 | 4 to 5 screens | Bazaar list, item detail, auctions, player search/progress, watchlist |
| 2 | List from API | Bazaar products |
| 3 | Detail with second call | Item page: item data + recently ended auctions for price history |
| 4 | Global state | Watchlist (plus logged-in user if Firebase is added) |
| 5 | Responsive screens | Portrait, landscape, tablet |
| 6 | Local state screen | Alert threshold / watchlist entry form |
| 7 | Typed navigation arguments | Pass item / auction objects between screens |
| 8 | Search with debounce | Player search by name (Mojang lookup, then SkyBlock profiles via the Worker) |
| 9 | Paginated list | Auctions (the API already serves pages of about 1,000) |
| 10 | Real-time screen | Bazaar polling every 30 to 60 s, timer cancelled on screen close |

Why player search for constraint 8: Hypixel has no auction search endpoint, and filtering a local list would not demonstrate the rule that a late response must never overwrite a newer one.

## 5. Real conditions

- **Airplane mode:** everything already viewed must stay readable after an app restart. Cache to disk (Hive), not just memory. Test this hardest.
- **CI:** GitHub Actions must produce a downloadable APK dated before the deadline. A red CI at hand-in scores zero on that point.
- **Four states** on every connected screen: loading, data, empty (no Retry button), error (Retry button that really retries).

## 6. Local storage: Hive

- Fine for this project; data persists across restarts.
- Use the maintained fork `hive_ce` rather than the original `hive` package **(verify on pub.dev)**.
- Hive is key-value, not a query engine: filtering or sorting thousands of auctions is done in Dart after loading. Acceptable at this scale.

## 7. Item images

Hypixel does not host item icons. The `resources/skyblock/items` endpoint gives each item's `material`, and head items carry a `skin` value that decodes to a texture URL on Mojang's texture server.

Websites either:

- render images themselves (bundled Minecraft textures + a 3D head renderer), as SkyCrypt does, or
- use a community icon service by item ID, e.g. Coflnet (`sky.coflnet.com/static/icon/ITEM_ID`) or SkyCrypt's item/head routes **(verify they still exist and allow outside use)**.

For the project: one URL per item ID, loaded with `cached_network_image`, plus a placeholder icon for failures.

## 8. Modules

- **Performance (mandatory):** 1000+ items with remote images, no frame above 16 ms over 10 s of fast scrolling, DevTools measurements before and after. The auctions list with item icons fits.
- **Second module, without Firebase:** design system, accessibility, APK size budget or visual regression tests. All work with a read-only API.
- **Offline-first:** only makes sense if Firebase is added, because it needs a remote to write to (optimistic writes, replayed mutation queue).
- **WebSocket module:** skip. It needs a bidirectional stream, which Hypixel cannot provide; you would have to run your own server.

## 9. Optional extension: accounts and alerts

If you add Firebase (free Spark plan) later:

- Auth, Firestore and FCM push are free. Cloud Functions are not, so Firebase cannot watch prices itself.
- Use a Cloudflare Worker cron to poll Hypixel and send pushes.

Worker limits to plan for **(verify free-tier numbers)**:

- **Auctions are too big for one run:** dozens of pages against a cap of about 50 subrequests and about 10 ms CPU per invocation. Scan a few pages per run in rotation, or use the recently ended auctions endpoint (one small call). The bazaar is a single call.
- **FCM is manual:** the Firebase Admin SDK does not run in Workers. Sign a JWT with the service account key (WebCrypto), exchange it for an access token, cache it for about an hour, then call the FCM HTTP v1 API.
- **Price history:** store it in D1 or KV, which saves Firestore quota for users and watchlists.

Definitions you must choose yourself:

- **Estimated price:** e.g. median of recent sales.
- **Bazaar crash:** e.g. a percentage drop against a stored average.

Simpler alternative without a cron: background checks in the app with WorkManager (minimum every 15 minutes) and local notifications. Enough for a bazaar crash, too slow for sniping auctions.

## 10. Risks checklist

- [ ] Permanent Hypixel API key requested
- [ ] Key stored only in the Worker
- [ ] Third-party icon source confirmed, placeholder in place
- [ ] Airplane mode tested after a full app restart
- [ ] CI green and APK artifact produced before the deadline
- [ ] Performance measurements recorded before and after
