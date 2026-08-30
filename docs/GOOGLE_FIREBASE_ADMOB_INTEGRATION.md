# AdMob, Firebase, and Google Auth — integration guide

This document describes **how this repo actually wires** Google Mobile Ads, Firebase, and Google Sign-In. Follow it to reproduce the same stack in another Flutter app, or to onboard a new environment for Chameleon 2D.

Related shorter doc: [`server/docs/oauth.md`](../server/docs/oauth.md) (server token verification + guest linking only).

---

## Architecture (read this first)

These three products **do not form one pipeline**. They share a Google account / Cloud project in the console, but the app uses them as three independent integrations:

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter app                             │
│                                                                 │
│  Firebase Core          google_sign_in           google_mobile_ads
│  (Android only)         native picker            rewarded + interstitial
│         │                      │                         │
│         │                      │ ID token                │
│         ▼                      ▼                         ▼
│  google-services.json    POST /auth/google         AdMob network
│  (plugin + options)      game server (Node)        (fill + show)
│                                 │
│                                 ▼
│                          verify JWT (JWKS)
│                          find / link / create player
└─────────────────────────────────────────────────────────────────┘
```

| Piece | What this app uses it for | What it does **not** do |
|-------|---------------------------|-------------------------|
| **Firebase** | `firebase_core` init on Android so Google Play services / plugin graph is happy | No Firebase Auth, Analytics, Crashlytics, Firestore, FCM. Not used to verify Google login. |
| **Google Sign-In** | Native account picker → **ID token** → game server `POST /auth/google` | No Firebase Auth `signInWithCredential`. Session after login is **Hive** (`SessionAuthStatus`), not a Firebase user. |
| **AdMob** | Rewarded ads (gems) + interstitial (after match leave) | Gems are **server-authoritative**. Watching an ad locally is not enough; client must `POST /economy/rewarded-ad`. Pro (RevenueCat) skips interstitials only. |

**Package IDs (must match everywhere):**

| Platform | ID |
|----------|----|
| Android `applicationId` / namespace | `com.hailsom.chameleon2d` |
| iOS bundle ID | `com.hailsom.chameleon2d` |
| Play listing | same package |

**Two Google Cloud / Firebase project numbers appear in this repo.** Do not mix them up:

| Project | Number | Used for |
|---------|--------|----------|
| Firebase `hailsom-chameleon2d` | `585657728965` | `google-services.json`, `lib/firebase_options.dart` |
| OAuth clients in `server/.env.example` | `103580907433` | Web / Android / iOS OAuth client IDs for Google Sign-In `aud` |

Sign-in will fail if the **Web client ID** on the Flutter side and the IDs in server `GOOGLE_CLIENT_IDS` do not belong to the **same OAuth consent project**, or if the Android client SHA-1 does not match the keystore that signed the APK.

---

## 1. Console setup (do this before code)

### 1.1 Firebase (Android)

1. [Firebase Console](https://console.firebase.google.com/) → create or open project (`hailsom-chameleon2d` here).
2. Add an **Android** app:
   - Package name: `com.hailsom.chameleon2d`
   - Optional: nickname, SHA-1 (you **must** add SHA-1 later for Google Sign-In even if Firebase does not require it for `firebase_core`).
3. Download `google-services.json`.
4. Place it at **`android/app/google-services.json`** (Gradle plugin reads it from there). This repo also keeps a copy at repo root `google-services.json`; the one Gradle uses is under `android/app/`.
5. Generate Flutter options (this repo already has the file):

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   That writes `lib/firebase_options.dart`. **This project only configured Android.** iOS / macOS / web / Windows / Linux throw `UnsupportedError` in `DefaultFirebaseOptions.currentPlatform`.

Current Android options (must match the JSON):

| Field | Value in this repo |
|-------|--------------------|
| `projectId` | `hailsom-chameleon2d` |
| `appId` | `1:585657728965:android:3ad2f978fd066d2ae615ac` |
| `messagingSenderId` | `585657728965` |
| `storageBucket` | `hailsom-chameleon2d.firebasestorage.app` |

If you re-run FlutterFire, regenerate both the JSON and `firebase_options.dart` together.

**iOS Firebase is not wired.** There is no `GoogleService-Info.plist`. `main.dart` only calls `Firebase.initializeApp` when `TargetPlatform.android`. Adding iOS later: add an iOS app in Firebase, drop `GoogleService-Info.plist` into `ios/Runner/`, re-run `flutterfire configure`, then initialize on iOS the same way.

### 1.2 Google Cloud OAuth (Sign-In)

Google Sign-In needs **three OAuth client types** in [Google Cloud Console](https://console.cloud.google.com/apis/credentials) → APIs & Services → Credentials. Enable the **Google Sign-In / Identity** APIs if prompted. Configure OAuth consent screen (External or Internal) first.

#### Web client (required for ID tokens)

1. Create **OAuth client ID** → Application type **Web application**.
2. No authorized redirect URIs are required for the mobile `google_sign_in` ID-token flow used here.
3. Copy the client ID (`….apps.googleusercontent.com`).

This ID is:

- Flutter `GOOGLE_SERVER_CLIENT_ID` (passed as `GoogleSignIn(serverClientId: …)`). Without it, `authentication.idToken` is **null**.
- One of the audiences on the server (`GOOGLE_CLIENT_IDS`). The ID token `aud` claim is this Web client ID.

#### Android client (required on device; error 10 if missing)

1. Create **OAuth client ID** → **Android**.
2. Package name: `com.hailsom.chameleon2d`.
3. SHA-1 of the keystore that signs **this** build:

   ```bash
   cd android && ./gradlew signingReport
   ```

   - **Debug:** `android/app` debug keystore (comment in code mentions a debug SHA starting `5C:7F:97:E6:…:9D:3A` — yours will differ per machine).
   - **Release:** SHA-1 of `android/key.properties` upload/release keystore **and** Play App Signing cert (Play Console → App integrity) if you ship via Play.

4. You can have **multiple** Android clients (one per SHA-1). Put **all** those client IDs in server `GOOGLE_CLIENT_IDS`.

`ApiException: 10` / `DEVELOPER_ERROR` = package name or SHA-1 does not match any Android OAuth client.

#### iOS client (required for URL scheme)

1. Create **OAuth client ID** → **iOS**.
2. Bundle ID: `com.hailsom.chameleon2d`.
3. Copy the client ID. The **reversed** form is `com.googleusercontent.apps.<CLIENT_ID_WITHOUT_SUFFIX>` (Google Cloud shows “iOS URL scheme”).
4. Set that reversed ID in `ios/Flutter/Debug.xcconfig` and `Release.xcconfig` as `GOOGLE_REVERSED_CLIENT_ID`. **This repo still has `com.googleusercontent.apps.REPLACE_ME`** until you paste the real scheme.

`Info.plist` registers it:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>$(GOOGLE_REVERSED_CLIENT_ID)</string>
    </array>
  </dict>
</array>
```

#### Server audience list

On the Node server, **every** client ID that might appear as `aud` must be listed:

```
GOOGLE_CLIENT_IDS=<web>,<android-debug>,<android-release>,<ios>
```

See `server/.env.example`. Verification is JWT + Google JWKS (`server/src/auth/google_token.js`): issuer must be `accounts.google.com` or `https://accounts.google.com`, `aud` must be in that list, `sub` is the stable Google user id stored as `players.google_sub`.

### 1.3 AdMob

1. [AdMob](https://admob.google.com/) → Apps → add **two** apps (this repo uses separate Android and iOS AdMob apps).
2. Create ad units:

| Slot | Android (this repo) | iOS (this repo) |
|------|---------------------|-----------------|
| App ID | `ca-app-pub-9698112281637218~8544303991` (Chameleon 2D: hide & seek) | `ca-app-pub-9698112281637218~6439859764` (Chameleon 2D) |
| Rewarded | `…/2170542344` (gems) | `…/8979347485` (gems) |
| Interstitial | `…/6896230738` (freebies) | **placeholder still uses the Android interstitial unit** — create a real iOS interstitial and replace `AdConfig.prodInterstitialIos` |

3. Link the AdMob apps to the Firebase Android/iOS apps if you want the Firebase↔AdMob connection in consoles. **The Flutter code does not require that link**; ads work from App ID + unit IDs alone.
4. For policy: Android `AD_ID` permission is declared. iOS has `NSUserTrackingUsageDescription` in `Info.plist`. This app **does not call App Tracking Transparency** (`requestTrackingAuthorization`) in Dart — ATT is only the plist string. Add a request before `MobileAds.initialize()` if you need personalized ads on iOS 14.5+.

**Never use production unit IDs in debug.** Google sample IDs are hardcoded for debug/simulator (section 4).

---

## 2. Flutter packages

From `pubspec.yaml`:

```yaml
google_mobile_ads: ^5.3.1
google_sign_in: ^6.3.0
firebase_core: ^4.14.0
flutter_dotenv: ^5.2.1
```

Then:

```bash
flutter pub get
```

No `firebase_auth` package. Auth is custom HTTP.

---

## 3. Native Android

### 3.1 Google services plugin

`android/settings.gradle.kts`:

```kotlin
id("com.google.gms.google-services") version "4.4.2" apply false
```

`android/app/build.gradle.kts` plugins block:

```kotlin
id("com.google.gms.google-services")
```

`google-services.json` must sit at `android/app/google-services.json`.

### 3.2 AdMob App ID (debug vs release)

`AndroidManifest.xml` does **not** hardcode the App ID. It uses a Gradle placeholder:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="${admobAppId}"/>
```

`android/app/build.gradle.kts` sets:

| Build type | `admobAppId` |
|------------|----------------|
| `defaultConfig` / `debug` | Google sample `ca-app-pub-3940256099942544~3347511713` |
| `release` | Prod `ca-app-pub-9698112281637218~8544303991` |

**App ID in the manifest must match the family of unit IDs you load.** Debug uses sample App ID + sample units. Release uses prod App ID + prod units. Mixing them causes load failures.

### 3.3 Permissions and queries

`android/app/src/main/AndroidManifest.xml`:

- `INTERNET`
- `com.android.vending.BILLING` (IAP, not ads)
- `com.google.android.gms.permission.AD_ID` (Ads / Play advertising ID)
- `<queries>` for `https` and `market` (store / sign-in related activity resolution)

`minSdk` is `maxOf(flutter.minSdkVersion, 24)`.

### 3.4 Signing (Google Sign-In)

Release signing: `android/key.properties` + `signingConfigs.release`. If `key.properties` is missing, **release still signs with debug** — then Play/SHA-1 OAuth clients will not match a “real” release key. For Google Sign-In on a release APK, the Android OAuth client SHA-1 must be that of the **actual signing cert**.

---

## 4. Native iOS

### 4.1 Deployment target

`ios/Podfile`: `platform :ios, '15.0'` — required by `google_mobile_ads`.

`AppDelegate.swift` is stock Flutter; no extra Google / AdMob native code.

### 4.2 AdMob App ID (debug vs release)

`ios/Runner/Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>$(GAD_APPLICATION_IDENTIFIER)</string>
```

| File | Value |
|------|--------|
| `ios/Flutter/Debug.xcconfig` | Sample `ca-app-pub-3940256099942544~1458002511` |
| `ios/Flutter/Release.xcconfig` | Prod `ca-app-pub-9698112281637218~6439859764` |

### 4.3 Google Sign-In URL scheme

Same xcconfig files: `GOOGLE_REVERSED_CLIENT_ID` (see §1.2). Until you replace `REPLACE_ME`, iOS Google Sign-In cannot return to the app.

### 4.4 ATT copy

`NSUserTrackingUsageDescription` is set. No Dart ATT request yet.

---

## 5. Dart bootstrap (`lib/main.dart`)

Order matters:

1. `WidgetsFlutterBinding.ensureInitialized()`
2. Load env: `.env.release` if `kReleaseMode`, else `.env.debug`, else `.env`, else `.env.example`
3. Landscape lock
4. **Firebase** — Android only, errors swallowed:

   ```dart
   if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
     await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
     );
   }
   ```

5. **Mobile Ads** — `_initMobileAds()`:
   - Skip web and non iOS/Android
   - Emulator/simulator → `AdConfig.setForceTestIds(true)`
   - `MobileAds.instance.initialize()`
   - `RequestConfiguration(testDeviceIds: ['SIMULATOR'])` on simulator
6. RevenueCat `PurchasesService.instance.configure()`
7. Hive + session → initial route (`/authentication` vs main menu)

Ads init is **before** `runApp`. Providers later **preload** rewarded + interstitial when first read.

---

## 6. Environment files (Flutter)

Loaded by `flutter_dotenv`. Gitignores `.env`, `.env.debug`, `.env.release` (keeps `.env.example`).

| Variable | Who reads it | Purpose |
|----------|--------------|---------|
| `GOOGLE_SERVER_CLIENT_ID` | `GoogleSignInService.resolveServerClientId()` | Web OAuth client ID → `serverClientId` |
| `HTTP_URL` / `BASE_URL` | `httpUrlProvider` | Game API (`POST /auth/google`, economy) |
| `WS_URL` | sockets | Multiplayer (unrelated to ads/auth) |
| `REVENUECAT_*` | IAP | Pro entitlement skips **interstitials** |

Override without files:

```bash
flutter run \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT.apps.googleusercontent.com \
  --dart-define=HTTP_URL=http://10.0.2.2:8080 \
  --dart-define=ADMOB_TEST=true
```

`GOOGLE_SERVER_CLIENT_ID` priority: `--dart-define` → dotenv.

If it is missing, `signInIdToken()` throws `GoogleSignInFailedException` immediately (does not open the picker).

---

## 7. Google Sign-In — client

**File:** `lib/core/services/google_sign_in_service.dart`

```dart
GoogleSignIn(
  scopes: const ['email', 'openid', 'profile'],
  serverClientId: <Web client ID>,
)
```

### 7.1 `signInIdToken()`

1. Abort if no `serverClientId`.
2. `GoogleSignIn.signIn()` — native picker. `null` account → `GoogleSignInCancelledException` (UI stays quiet).
3. `account.authentication` → require non-empty `idToken`.
4. Missing token → fail with message to use **Web** client as `GOOGLE_SERVER_CLIENT_ID`.
5. `PlatformException` containing `ApiException: 10` → mapped to Android SHA-1 / package setup message.

### 7.2 DI

`googleSignInServiceProvider` in `lib/app/dependency_injection.dart` constructs one `GoogleSignInService` with `resolveServerClientId()`.

### 7.3 Login screen flow

`lib/features/authentication/authentication_screen.dart` → `_enterGoogle()`:

```
idToken = GoogleSignInService.signInIdToken()
deviceId = DeviceIdentityService.fingerprint().deviceId   // Hive "local:<uuid>"
identity = OAuthAuthService.authenticateGoogle(idToken, deviceId)
PlayerProfileNotifier.applyGuestIdentity(...)
sessionAuth.enterWithGoogle()   // Hive SessionAuthStatus.google
go(mainMenu)
```

`OAuthAuthService` (`lib/core/services/oauth_auth_service.dart`):

```http
POST {HTTP_URL}/auth/google
Content-Type: application/json

{ "idToken": "<jwt>", "deviceId": "local:…" }
```

Timeout 12s. 2xx JSON → `ServerIdentity` (`playerId`, `authType`, `linkedFromGuest`, economy stats, etc.).

### 7.4 Link Google from Settings (guest upgrade)

`lib/features/settings/settings_screen.dart` `_linkGoogle()` is the **same** `signInIdToken` + `authenticateGoogle` + `enterWithGoogle`. Server uses `deviceId` to upgrade a guest row in place when `google_sub` is still empty.

### 7.5 Sign out

`SessionAuthNotifier.signOut()` calls `GoogleSignInService().signOut()` best-effort, then writes `SessionAuthStatus.signedOut`. Note: it constructs a **new** `GoogleSignInService()` rather than the provider instance — still fine because `google_sign_in` uses the same native session.

Local “in app” gate is **not** Firebase: `main.dart` uses `sessionAuthRepo.load().isInApp`.

### 7.6 Device ID

`DeviceIdentityService` stores `local:<uuid>` in Hive. Do **not** use Android `Build.ID`. The same id is sent on guest auth and Google auth so the server can link.

---

## 8. Google Sign-In — server

**Files:** `server/src/index.js` (`POST /auth/google`), `server/src/auth/google_token.js`, `server/src/auth/oauth.js`, `server/src/db/store.js` (`findOrLinkOAuth`).

### 8.1 Verify token

`jose` `jwtVerify` against `https://www.googleapis.com/oauth2/v3/certs`.

- `aud` ∈ `GOOGLE_CLIENT_IDS` (comma-separated)
- `iss` ∈ `{accounts.google.com, https://accounts.google.com}`
- Returns `{ sub, email?, name? }`

Invalid token → HTTP 401 `{ error: "invalid_google_token", message }`.

### 8.2 Account resolution (`findOrLinkOAuth`)

1. Player already has `google_sub = sub` → return that player (`linkedFromGuest: false`).
2. Else `deviceId` maps to a **guest** with empty `google_sub` → `UPDATE` that row to `auth_type = google`, set `google_sub` (`linkedFromGuest: true`). **Same `playerId`.**
3. Else `INSERT` new player `id = google-<uuid>`.

Race on unique `google_sub` is handled (return existing).

### 8.3 Client identity apply

`ServerIdentity.fromJson` maps the JSON. Profile + session persist locally. `syncLocalPlayerProfile` pushes name/username/avatar to `PlayerApiService`.

Migration: `server/sql/migrations/008_oauth_provider_subs.sql`.

---

## 9. AdMob — IDs and test vs prod

**File:** `lib/core/monetization/ad_config.dart`

### 9.1 Which IDs load

`AdConfig.useTestIds` is true when:

1. `setForceTestIds(true)` (emulator/simulator at startup), or
2. `--dart-define=ADMOB_TEST=true`, or
3. not `kReleaseMode` (debug/profile)

Force prod units even in debug: `--dart-define=ADMOB_PROD=true` (still loses to force-test / simulator).

| | Android | iOS |
|--|---------|-----|
| Test App ID | `ca-app-pub-3940256099942544~3347511713` | `…~1458002511` |
| Test rewarded | `…/5224354917` | `…/1712484513` |
| Test interstitial | `…/1033173712` | `…/4411468910` |
| Prod App ID | `…~8544303991` | `…~6439859764` |
| Prod rewarded | `…/2170542344` | `…/8979347485` |
| Prod interstitial | `…/6896230738` | **same Android unit until iOS unit exists** |

Native **App ID** (manifest / GADApplicationIdentifier) is chosen by **Gradle/xcconfig build type**, not by `AdConfig.useTestIds`. That is why debug Gradle uses the sample App ID: Dart debug also uses sample units. If you `ADMOB_PROD=true` on a **debug** APK, Dart would request prod units while the manifest still has the **sample App ID** — do not do that. Use a **release** build for prod ads, or change both layers together.

### 9.2 SDK init

See `_initMobileAds()` in `main.dart`. Services no-op when `kIsWeb` or not iOS/Android (`isSupported`).

---

## 10. Rewarded ads (gems)

### 10.1 Load / show

`lib/core/monetization/rewarded_ad_service.dart`

- `RewardedAd.load` with `AdRequest()`
- Prefetch; on show, detach instance so a failed show is not reused
- `onUserEarnedReward` sets `earned`; dismiss without reward → `RewardedShowResult.dismissed`
- After dismiss/fail, `preload()` again

Provider (`rewardedAdServiceProvider`) constructs, `preload()` immediately, `dispose` on provider dispose.

### 10.2 Product flow

Marketplace item kind `ShopItemKind.rewardedAd` → `PlayerProfileNotifier.claimRewardedAd`:

1. Need `playerId` (guest or Google). Else `needsAccount`.
2. `ads.show()` — only `success` (reward callback) continues.
3. `POST {HTTP_URL}/economy/rewarded-ad` `{ "playerId" }`
4. Apply `gems` from response.

**Client does not send an AdMob token.** Trust is: user watched an ad on device, then server grants gems with a **UTC daily cap**. A modified client could skip the ad and still POST. Acceptable for this game’s threat model; not fraud-proof.

### 10.3 Server grant

`POST /economy/rewarded-ad` → `claimRewardedAd` in `store.js`:

- Row lock `FOR UPDATE`
- Cap: `REWARDED_AD_DAILY_CAP` (default **5**, env `REWARDED_AD_DAILY_CAP`)
- Grant: `REWARDED_AD_GEMS` (default **25**, env `REWARDED_AD_GEMS`)
- Catalog also exposes these via `GET /shop/catalog` → Flutter `ShopCatalog.economy`

`daily_cap` → client toast `rewardedAdDailyCap`.

---

## 11. Interstitial ads (freebies)

`lib/core/monetization/interstitial_ad_service.dart` — same preload / show / reload pattern. Result enum: `success | unsupported | loadFailed | showFailed`. Navigation **always** continues.

**When shown:** `lib/game/engine/game_screen.dart` `_showInterstitialThen`:

- After quit confirm → matchmaking
- After leave → main menu

Skipped if `isProProvider` is true (RevenueCat entitlement `hailsom_technologies_inc_pro`). Errors are swallowed so ads never block navigation.

Rewarded ads are **not** skipped for Pro (shop still offers watch-ad gems).

---

## 12. End-to-end checklists

### Google Sign-In (Android debug)

1. `.env.debug` (or `.env`): `GOOGLE_SERVER_CLIENT_ID=<Web client>`
2. Server `.env`: same Web ID (and Android debug client ID) in `GOOGLE_CLIENT_IDS`
3. Cloud Console: Android OAuth client for `com.hailsom.chameleon2d` + **debug** SHA-1 from `./gradlew signingReport`
4. `google-services.json` in `android/app/`
5. `flutter run` (debug) → Continue with Google → account picker → main menu
6. Server log: `[auth/google]`; DB `players.auth_type = google`, `google_sub` set

### Google Sign-In (iOS)

1. Same Web `GOOGLE_SERVER_CLIENT_ID` in Flutter env
2. iOS OAuth client + **real** `GOOGLE_REVERSED_CLIENT_ID` in both xcconfigs
3. `pod install` / `flutter run` on device or sim
4. Server `GOOGLE_CLIENT_IDS` includes iOS client ID

### AdMob rewarded (debug)

1. Debug build (sample App ID in manifest + sample units in Dart)
2. Physical device preferred (emulator forces test IDs anyway)
3. Marketplace → watch ad → gems increase; second through fifth work; sixth same UTC day → daily cap
4. Logs: `RewardedAd load start unit=… test=true`

### AdMob prod

1. `flutter build appbundle` / iOS Release
2. Confirm release manifest/xcconfig App ID is **prod**
3. Confirm `kReleaseMode` so `useTestIds` is false (and not on simulator)
4. AdMob console: impressions on the prod units

---

## 13. Troubleshooting

| Symptom | Cause | Fix |
|---------|--------|-----|
| `GOOGLE_SERVER_CLIENT_ID missing` | Empty dotenv / define | Set Web client ID in `.env.debug` / `.env.release` |
| Picker works, then “Missing Google idToken” | `serverClientId` is Android/iOS client, not **Web** | Use Web client as `GOOGLE_SERVER_CLIENT_ID` |
| `ApiException: 10` / DEVELOPER_ERROR | Android OAuth client SHA-1 or package mismatch | `signingReport`; add SHA-1; wait a few minutes; reinstall app |
| `401 invalid_google_token` | Token `aud` not in `GOOGLE_CLIENT_IDS`, or clock/JWKS | Add the Web (and platform) client IDs on the server; restart Node |
| Guest progress lost after Google | `deviceId` not sent or different install | Same install Hive id; server only links if guest has empty `google_sub` |
| iOS returns from Google and dies | URL scheme still `REPLACE_ME` | Set reversed iOS client ID in xcconfig |
| Ads fail to load in debug | Prod units + sample App ID, or no fill | Stay on sample units in debug; use test device / `ADMOB_TEST` |
| Ads fail in release on emulator | Simulator forces test IDs; prod rarely fills on emulators | Test ads on a physical device with a release build |
| Interstitial never shows | User is Pro, or load fail | Check `isProProvider`; log `InterstitialAd load failed` |
| iOS interstitial no-fill in prod | `prodInterstitialIos` still Android unit | Create iOS interstitial in AdMob; paste into `AdConfig` |
| Firebase init “fails” silently | Catch-all in `main.dart` | Log the catch if debugging; confirm JSON + plugin |
| iOS crash on `DefaultFirebaseOptions` | Calling `currentPlatform` on iOS | Do not init Firebase on iOS until options exist (current `main.dart` already skips) |

---

## 14. File map

| Path | Role |
|------|------|
| `pubspec.yaml` | `firebase_core`, `google_sign_in`, `google_mobile_ads` |
| `lib/main.dart` | Env, Firebase (Android), `MobileAds.initialize` |
| `lib/firebase_options.dart` | Android `FirebaseOptions` only |
| `google-services.json` / `android/app/google-services.json` | Firebase Android client |
| `android/settings.gradle.kts` | `google-services` plugin version |
| `android/app/build.gradle.kts` | Apply plugin; `admobAppId` placeholder |
| `android/app/src/main/AndroidManifest.xml` | `APPLICATION_ID` meta-data, `AD_ID` |
| `ios/Podfile` | iOS 15 |
| `ios/Runner/Info.plist` | `GADApplicationIdentifier`, URL scheme, ATT string |
| `ios/Flutter/Debug.xcconfig` / `Release.xcconfig` | AdMob App ID + reversed Google client |
| `lib/core/services/google_sign_in_service.dart` | Native Google → ID token |
| `lib/core/services/oauth_auth_service.dart` | `POST /auth/google` |
| `lib/core/services/server_identity.dart` | Auth JSON model |
| `lib/features/authentication/authentication_screen.dart` | Continue with Google |
| `lib/features/settings/settings_screen.dart` | Link Google from guest |
| `lib/game/providers/session_auth_provider.dart` | Local session + signOut |
| `lib/core/monetization/ad_config.dart` | Test/prod unit IDs |
| `lib/core/monetization/rewarded_ad_service.dart` | Rewarded load/show |
| `lib/core/monetization/interstitial_ad_service.dart` | Interstitial load/show |
| `lib/app/dependency_injection.dart` | Ad + Google + OAuth providers |
| `lib/game/providers/player_profile_provider.dart` | `claimRewardedAd` |
| `lib/core/monetization/economy_api_service.dart` | `POST /economy/rewarded-ad` |
| `lib/game/engine/game_screen.dart` | Interstitial before leave |
| `server/src/auth/google_token.js` | JWT verify |
| `server/src/auth/oauth.js` | Link/create |
| `server/.env.example` | `GOOGLE_CLIENT_IDS` |
| `.env.example` | Flutter `GOOGLE_SERVER_CLIENT_ID` |

---

## 15. Copy-paste: new project with the same pattern

1. Firebase Android app + `google-services.json` + `flutterfire configure` (Android).
2. Gradle: `com.google.gms.google-services` on the app module; init `Firebase.initializeApp` on Android.
3. Cloud OAuth: Web + Android (SHA-1) + iOS (URL scheme). Flutter gets **Web** ID as `serverClientId`.
4. Backend: verify Google JWT with `aud` = those client IDs; persist `sub`.
5. AdMob: two apps; debug sample App ID + sample units; release prod App ID + prod units; never mix.
6. Rewarded: show SDK ad → only then call your economy API with a daily cap.
7. Interstitial: non-blocking; skip for paid entitlement if you have one.

That is the integration as implemented in Chameleon 2D.
