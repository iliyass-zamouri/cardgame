# RevenueCat + IAP — integration setup

Full console + app + server setup for real-money gem/coin packs and Pro. Follow this when products fail to load, offerings are empty, or you are wiring a new Play / App Store listing.

Related: ads / Pro skip-interstitial live in [`GOOGLE_FIREBASE_ADMOB_INTEGRATION.md`](GOOGLE_FIREBASE_ADMOB_INTEGRATION.md). Server HTTP in [`SERVER.md`](../SERVER.md).

---

## Architecture

Play / App Store own the SKUs. RevenueCat is the SDK + catalog. Our Node server grants gems/coins **once per store transaction**.

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Flutter app                                                             │
│                                                                         │
│  PurchasesService.configure()     marketplace tap                        │
│           │                              │                              │
│           ▼                              ▼                              │
│  goog_ / appl_ public key      purchaseProduct(gems_100)                 │
│           │                              │                              │
│           ▼                              ▼                              │
│  RevenueCat SDK  ──GET offerings──►  RC dashboard                        │
│           │              │                 │                           │
│           │              │ empty OK        │ products must exist        │
│           │              ▼                 ▼                           │
│           │         getProducts(ids)  Google Play / App Store           │
│           │                              │                              │
│           │                              ▼                              │
│           │                    store sheet → StoreTransaction             │
│           │                              │                              │
│           ▼                              ▼                              │
│  syncAppUserId(playerId)     POST /economy/iap/verify                    │
│                                         │                               │
│                                         ▼                               │
│                               Node: redeemIapPurchase                    │
│                               (idempotent on transaction_id)              │
└─────────────────────────────────────────────────────────────────────────┘
```

| Piece | Role | Not this |
|-------|------|----------|
| **Google Play / App Store** | Source of truth for SKUs, prices, billing sheet | Does not grant gems. |
| **RevenueCat** | SDK, offerings, paywall, Customer Center, entitlements | Does not write our MySQL balances. |
| **Game server** | `POST /economy/iap/verify` → insert `iap_redemptions` + credit gems/coins | Does **not** call Play/RC REST to re-verify the receipt (trusts SDK `transactionId` + unique PK). |

**Package IDs (must match everywhere):**

| Platform | ID |
|----------|-----|
| Android `applicationId` | `com.hailsom.chameleon2d` |
| iOS / Apple Sign In bundle | `com.hailsom.chameleon2d` |
| Play listing | same package |
| RevenueCat apps | same bundle / package |

---

## Product catalog (must match exactly)

IDs are store product IDs. Shop catalog item IDs (`iap_gems_100`) are **not** store SKUs.

Defined in [`lib/core/monetization/purchases_config.dart`](../lib/core/monetization/purchases_config.dart), [`lib/game/models/shop_catalog.dart`](../lib/game/models/shop_catalog.dart), and [`server/src/economy/shop_catalog.js`](../server/src/economy/shop_catalog.js).

### Consumables (shop Currency tab)

| Store product ID | Shop item ID | Type | Grant | Stub USD |
|------------------|--------------|------|-------|----------|
| `gems_100` | `iap_gems_100` | consumable | 100 gems | $0.99 |
| `gems_500` | `iap_gems_500` | consumable | 500 gems | $4.99 |
| `gems_1200` | `iap_gems_1200` | consumable | 1200 gems | $9.99 |
| `coins_1000` | `iap_coins_1000` | consumable | 1000 coins | $0.99 |
| `coins_5000` | `iap_coins_5000` | consumable | 5000 coins | $3.99 |

Play Console: **Managed product**, **Consumable** (not one-time unmanaged, not subscription).

App Store Connect: **Consumable**.

### Pro subscription

| | Value |
|--------|--------|
| Entitlement identifier | `hailsom_technologies_inc_pro` |
| Used by | `PurchasesService.isPro`, Settings paywall, skip interstitials |
| Store product | you choose (e.g. `pro_monthly`). **Not** in the consumable list above. |

Create at least one subscription SKU, attach it to that entitlement, then attach the same package to the current Offering so RevenueCatUI paywall has something to sell.

---

## 1. Google Play Console

1. Open [Play Console](https://play.google.com/console) → app `com.hailsom.chameleon2d`.
2. Upload an AAB at least once (internal testing is enough). Billing catalog will not resolve for a package that has never been uploaded.
3. **Monetize → In-app products → Create product** for each consumable above.
   - Product ID = exact store ID (`gems_100`, …).
   - Name / description: anything human-readable.
   - Price: match the stub or your real price.
   - Status: **Active**.
4. **Monetize → Subscriptions** → create the Pro SKU if you want paywall.
5. **Setup → License testing** → add the Google account signed into the test device.
6. Put the tester on an **internal testing** track and install from Play (or Play internal app sharing). Sideloaded debug APKs often cannot see products even when the catalog is live.

### Play → RevenueCat credentials

RevenueCat must talk to Play as your app, or offerings stay empty.

1. Google Cloud Console (same cloud project as Play) → create a **service account**.
2. Play Console → **Users and permissions** → invite that service account with **View financial data** + **Manage orders and subscriptions** (or the current RevenueCat-recommended Play roles — see [rev.cat/google-service-account](https://rev.cat/google-service-account)).
3. RevenueCat dashboard → Android app → **Service credentials** → upload the JSON key.

Until this is linked, SDK logs look like:

```
You have configured the SDK with a Play Store API key, but there are no
Play Store products registered in the RevenueCat dashboard for your offerings.
```

---

## 2. App Store Connect (iOS)

1. [App Store Connect](https://appstoreconnect.apple.com) → app `com.hailsom.chameleon2d`.
2. **Features → In-App Purchases** → create the same five consumable IDs.
3. Create the Pro subscription (subscription group + product).
4. Paid Apps agreement + banking/tax must be **Active** or products stay missing in sandbox.
5. Xcode → Runner target → **Signing & Capabilities → + In-App Purchase**.  
   [`ios/Runner/Runner.entitlements`](../ios/Runner/Runner.entitlements) currently has Apple Sign In only; IAP capability is required before TestFlight / sandbox purchase.
6. Sandbox tester: App Store Connect → Users and Access → Sandbox.

RevenueCat iOS app: upload App Store Connect API key / shared secret as prompted in the RC Android/iOS app settings.

---

## 3. RevenueCat dashboard

Project: [app.revenuecat.com](https://app.revenuecat.com)

### 3.1 Apps

| RC app | Store | Bundle / package | Public SDK key prefix |
|--------|-------|------------------|------------------------|
| Android | Play Store | `com.hailsom.chameleon2d` | `goog_` |
| iOS | App Store | `com.hailsom.chameleon2d` | `appl_` |
| Optional Test Store | Test Store | — | `test_` |

Copy keys into Flutter env (section 4). Public SDK keys are **safe in the client**. Secret API keys (`sk_`) stay on the server only if you add REST verification later — this repo does not use them yet.

### 3.2 Products

**Products → + New** (or Import from store) for **each** Play SKU **and** each App Store SKU.

Same identifier on both stores: `gems_100`, `gems_500`, `gems_1200`, `coins_1000`, `coins_5000`, plus the Pro subscription ID.

If the product exists in Play but not in this list, `getOfferings()` throws `ConfigurationError` even when `getProducts` might still work.

### 3.3 Entitlements

1. Create entitlement identifier **`hailsom_technologies_inc_pro`** (exact).
2. Attach the Pro **subscription** product(s). Do **not** attach consumable gem/coin packs to Pro.

### 3.4 Offerings

1. Create an offering (e.g. `default`) and mark it **Current**.
2. Add packages:
   - Custom packages for each consumable (`gems_100`, …).
   - Monthly / annual package for Pro.
3. Attach the **Play** product **and** the **App Store** product to each package (RC shows both store columns).

Empty Play column on every package = the error in logcat.

Paywall + Customer Center in RevenueCatUI read **current offering**. Consumable shop purchases fall back to `Purchases.getProducts` if offerings fail, but paywall still needs this offering.

### 3.5 Paywall + Customer Center

1. **Paywalls** → attach to the current offering → include the Pro package.
2. **Customer Center** → enable restore / manage subscription.
3. Settings screen calls `presentPaywall` and `presentCustomerCenter` on these.

---

## 4. Flutter env keys

Loaded at startup ([`lib/main.dart`](../lib/main.dart)):

1. `.env.release` if `kReleaseMode`
2. else `.env.debug`
3. else `.env`
4. else `.env.example`

Resolution in [`PurchasesConfig.apiKey()`](../lib/core/monetization/purchases_config.dart):

1. `--dart-define=REVENUECAT_API_KEY=…` (wins on every platform)
2. iOS/macOS → `REVENUECAT_APPLE_API_KEY`
3. Android → `REVENUECAT_GOOGLE_API_KEY`
4. `REVENUECAT_API_KEY` (Test Store / fallback)
5. hardcoded `test_…` default in `purchases_config.dart`

[`.env.example`](../.env.example):

```env
REVENUECAT_GOOGLE_API_KEY=goog_YOUR_KEY
# REVENUECAT_APPLE_API_KEY=appl_YOUR_KEY
# REVENUECAT_API_KEY=test_YOUR_KEY
```

Put the real `goog_` key in **both** `.env.debug` and `.env.release` (this app uses Play in debug too). Hot reload does **not** reload dotenv — full restart.

`pubspec.yaml` already ships those files as assets.

---

## 5. Native app wiring (already in repo)

| Item | Location | Notes |
|-------|----------|--------|
| `purchases_flutter` / `purchases_ui_flutter` | `pubspec.yaml` `^10.9.1` | |
| Billing permission | `android/app/src/main/AndroidManifest.xml` | `com.android.vending.BILLING` |
| `applicationId` | `android/app/build.gradle.kts` | `com.hailsom.chameleon2d` |
| `minSdk` | same | `maxOf(flutter.minSdkVersion, 24)` |
| Configure SDK | `main()` → `PurchasesService.instance.configure()` | Before first purchase |
| Identify user | `CamouflageApp` listens `playerProfileProvider` → `syncAppUserId(playerId)` | Guest IDs look like `guest-…` in RC |
| Purchase | Marketplace → `purchaseIapPack` → `Purchases.purchase` | Offerings first, then store product |
| Redeem | `EconomyApiService.verifyIap` → `POST /economy/iap/verify` | After success + on `reconcileEconomy` |
| Pro | `isProProvider` | Settings badge; skip interstitial on match leave |
| Restore / paywall / Customer Center | Settings | |

Purchase path if offerings are empty: `_findPackage` swallows `ConfigurationError`, then `getProducts([productId])`. Shop packs still work **if** the SKU exists in Play **and** is imported as a Product in RC. Paywall still needs offerings.

---

## 6. Game server

Endpoint: `POST /economy/iap/verify`

Body:

```json
{
  "playerId": "…",
  "productId": "gems_100",
  "transactionId": "<StoreTransaction.transactionIdentifier>"
}
```

[`redeemIapPurchase`](../server/src/db/store.js):

1. Resolve catalog by `iapProductId` (`gems_100`) or shop `id`.
2. Reject unknown / non-`realMoney` packs (`invalid`).
3. `INSERT INTO iap_redemptions (transaction_id PRIMARY KEY, …)`.
4. Duplicate PK → return current balance, `alreadyRedeemed: true` (no double grant).
5. Else `UPDATE players SET gems/coins += grant`.

Grant amounts come from server catalog env overrides (`SHOP_IAP_GEMS_100_GRANT`, etc.), not from Play price.

No extra server env vars for RevenueCat today. Optional hardening: verify `transactionId` against [RevenueCat REST `GET /subscribers`](https://www.revenuecat.com/docs/api-v1#tag/customers) with a **secret** key before insert.

---

## 7. Test

### Android

1. License tester Google account on device.
2. Install from **internal testing** (or internal app sharing), not a random sideload of an unsigned debug APK if products do not appear.
3. Debug logcat: `adb logcat | grep -i Purchases`
4. Tap Gem Pouch. Store sheet must show Play price, not a RC configuration error.
5. After success, HUD gems match server (`GET` player / shop sync). Repeat purchase of the same pack: new store tx, new `transaction_id`, another grant. Same `transaction_id` must not double-credit.

### iOS

1. Sandbox Apple ID (Settings → App Store, not the production Apple ID).
2. Run from Xcode on a device (Simulator IAP is unreliable).
3. Same tap / HUD / idempotency checks.

### Offerings empty vs product missing

| Log | Meaning | Fix |
|-----|---------|-----|
| `no Play Store products registered … for your offerings` | RC offering has no Play products | Import Play SKUs + attach to current offering; fix Play service account |
| `[rc] offerings unavailable` then purchase works | Expected after client fallback | Offerings still needed for paywall |
| `[rc] product missing: gems_100` | SKU not in Play **or** not imported in RC Products | Create/activate SKU; import in RC |
| Purchase sheet OK, gems never land | `/economy/iap/verify` failed | Check server log; `playerId` + `transactionId` required |
| `already_redeemed` / `alreadyRedeemed` | Same tx posted twice | OK — balance unchanged |

---

## 8. Checklist

**Play**

- [ ] AAB uploaded (internal track)
- [ ] Five consumables **Active**, IDs exact
- [ ] Pro subscription SKU (if using paywall)
- [ ] License testers added
- [ ] RC service account invited + JSON uploaded in RC

**App Store**

- [ ] Same five consumables + Pro subscription
- [ ] Paid Apps agreement active
- [ ] Xcode In-App Purchase capability
- [ ] Sandbox testers

**RevenueCat**

- [ ] Android app + `goog_` key in `.env.debug` / `.env.release`
- [ ] iOS app + `appl_` key when shipping iOS
- [ ] All SKUs listed under Products (Play **and** App Store columns)
- [ ] Current offering has those packages
- [ ] Entitlement `hailsom_technologies_inc_pro` on the subscription only
- [ ] Paywall + Customer Center on current offering

**App / server**

- [ ] Full restart after env change
- [ ] `PurchasesService.configure()` runs
- [ ] Test on a signed Play-track build
- [ ] Verify redeem hits `/economy/iap/verify` and `iap_redemptions` row exists

---

## 9. Adding a new pack

1. Create store SKU (same ID on Play + App Store).
2. Import into RevenueCat Products; add to current offering.
3. Add shop row in `server/src/economy/shop_catalog.js` **and** `ShopCatalog._localCurrencyPacks` with matching `iapProductId`.
4. Append ID to `PurchasesConfig.gemProductIds` or `coinProductIds`.
5. Deploy server before the client that sells it (grant is server-authoritative).
