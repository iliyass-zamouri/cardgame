# iOS App Store Release Prep — Playbook

Derived from what was done for **Chameleon 2D** (commit `678da14`, "Prepare iOS App Store release (1.0.7+20)", repo `chameleon_2d`) so the same steps can be applied to **cardgame** (bundle ID `com.hailsom.shadowhand`).

Stack assumed: Flutter + CocoaPods, `google_mobile_ads`, Firebase (Analytics / Crashlytics / FCM), Google Sign-In, RevenueCat IAP, Node/MySQL backend.

---

## 0. Overview — what the Chameleon commit changed

| Area | Files touched | Why |
|---|---|---|
| Firebase iOS app | `ios/Runner/GoogleService-Info.plist`, `lib/firebase_options.dart`, `project.pbxproj` | Analytics/Crashlytics/FCM silently no-op on iOS without it |
| Google Sign-In | `ios/Flutter/{Debug,Release}.xcconfig` (`GOOGLE_REVERSED_CLIENT_ID`) | Sign-in can't return to the app without the URL scheme |
| Build fix | both xcconfigs (`CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES=YES`) | `google_mobile_ads` release/device build fails otherwise |
| Deployment target | `Podfile`, `project.pbxproj` (3 build configs) | Pods need iOS 15; Xcode project said 13 |
| Signing | `project.pbxproj` `DEVELOPMENT_TEAM` | Switched to the correct Apple team |
| Info.plist | `ios/Runner/Info.plist` | Encryption declaration, ATS exception, SKAdNetwork, ATT string, full-screen |
| Privacy manifest | `ios/Runner/PrivacyInfo.xcprivacy` (+ added to Runner target Resources) | Required by Apple for submissions |
| AdMob | `lib/core/monetization/ad_config.dart` | Replaced placeholder (Android) unit IDs with real iOS units |
| Account deletion | Settings UI, `AccountApiService`, server `POST /account/delete`, l10n | **Guideline 5.1.1(v)** — apps with account creation must offer in-app deletion |
| Legal links | `AppConstants`, auth screen | Tappable Terms / Privacy links (required in app + in App Store Connect) |
| Version | `pubspec.yaml` | Build number must increase per upload |

---

## 1. Apple Developer / App Store Connect (manual, no code)

1. **Apple Developer account** → Certificates, Identifiers & Profiles → **Identifiers** → register App ID = bundle ID.
   Enable capabilities: **Push Notifications**, **Sign in with Apple** (if used).
2. **APNs key** (`.p8`) → upload to Firebase Console → Project settings → Cloud Messaging → *Apple app configuration*. Without it, FCM pushes never reach iOS.
3. **App Store Connect** → My Apps → **+ New App** (same bundle ID, SKU, primary language).
4. **In-App Purchases**: create products with the *same IDs* as in RevenueCat. Add them to the app version for review. Make sure the **Paid Apps Agreement** + banking/tax are active.
5. **RevenueCat**: add the iOS app, paste the App Store Connect **App-Specific Shared Secret / In-App Purchase key**, and put the **iOS public SDK key** in code.
6. Find your **Team ID** (Membership page) — needed for step 3.4.

---

## 2. Firebase (iOS app + Google Sign-In)

1. Firebase Console → Project settings → **Add app → iOS**, with the exact bundle ID.
2. Download **`GoogleService-Info.plist`** → place in `ios/Runner/`.
3. **Add it to the Xcode target** (Runner → right-click Runner group → *Add Files…*, tick *Copy if needed* + Runner target). Just dropping the file in Finder isn't enough — it must appear in `project.pbxproj` under *Resources* (Chameleon commit added both a `PBXFileReference` and a `PBXBuildFile`).
4. Update `lib/firebase_options.dart` → `DefaultFirebaseOptions.ios` with the iOS `apiKey` / `appId` (or run `flutterfire configure`). Chameleon had a literal `REPLACE_WITH_FIREBASE_IOS_APP_ID` placeholder — grep for `REPLACE` before shipping.
5. **Google Sign-In**:
   - Google Cloud Console → Credentials → the iOS OAuth client (auto-created by Firebase) → copy client ID.
   - `REVERSED_CLIENT_ID` (also in `GoogleService-Info.plist`) goes into **both** `ios/Flutter/Debug.xcconfig` and `Release.xcconfig`:
     ```
     GOOGLE_REVERSED_CLIENT_ID=com.googleusercontent.apps.<client-id-without-suffix>
     ```
   - `Info.plist` references it via `CFBundleURLTypes` → `$(GOOGLE_REVERSED_CLIENT_ID)`.
   - Add the **iOS client ID to the server's** `GOOGLE_CLIENT_IDS` env so token `aud` validation accepts iOS tokens.
6. Crashlytics on iOS: make sure the dSYM upload build phase exists (Firebase docs: *Crashlytics → Flutter → iOS*) or crashes come back un-symbolicated.

---

## 3. Xcode project / build settings

### 3.1 Deployment target → 15.0
- `ios/Podfile`: `platform :ios, '15.0'`
- `ios/Runner.xcodeproj/project.pbxproj`: every `IPHONEOS_DEPLOYMENT_TARGET = 13.0` → `15.0` (Debug, Release, Profile project-level configs).

  ```bash
  sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 13.0;/IPHONEOS_DEPLOYMENT_TARGET = 15.0;/g' ios/Runner.xcodeproj/project.pbxproj
  ```

### 3.2 Fix `google_mobile_ads` release/device build
Add to **both** `ios/Flutter/Debug.xcconfig` and `ios/Flutter/Release.xcconfig`:
```
// google_mobile_ads imports a non-modular GMA header; required for device/release builds.
CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES=YES
```

### 3.3 AdMob App ID per configuration
Already the pattern in both repos — keep it:
- `Debug.xcconfig` → Google **sample** app ID `ca-app-pub-3940256099942544~1458002511`
- `Release.xcconfig` → **real iOS AdMob app ID** (create a separate iOS app in AdMob; don't reuse the Android one)
- `Info.plist` → `GADApplicationIdentifier = $(GAD_APPLICATION_IDENTIFIER)`

### 3.4 Signing
- Set `DEVELOPMENT_TEAM = <TEAM_ID>` on the Runner target (Debug/Release/Profile). Chameleon moved from team `WF434D82N7` to `ADH269CTVQ` — make sure cardgame uses the team that owns its bundle ID.
- Signing style: Automatic is fine; entitlements file is `Runner/Runner.entitlements`.

### 3.5 Entitlements (`Runner/Runner.entitlements`)
```xml
<key>aps-environment</key>
<string>development</string>   <!-- Xcode swaps to production automatically for App Store/TestFlight archives with automatic signing -->
<key>com.apple.developer.applesignin</key>
<array><string>Default</string></array>   <!-- only if Sign in with Apple is used -->
```

---

## 4. `Info.plist` changes

Open `ios/Runner/Info.plist` and make sure all of these exist:

| Key | Value | Notes |
|---|---|---|
| `CFBundleDisplayName` / `CFBundleName` | App name | Home-screen name |
| `ITSAppUsesNonEncryption` | `false` | Skips the export-compliance prompt on every upload (only HTTPS/standard crypto) |
| `NSAppTransportSecurity` → `NSExceptionDomains` → `<host>` → `NSExceptionAllowsInsecureHTTPLoads = true` | only if backend is plain HTTP/WS by IP | Chameleon needed it for `84.8.222.159`. **Best fix: put the backend behind HTTPS/WSS and delete the exception** — reviewers may question it |
| `NSUserTrackingUsageDescription` | "This identifier will be used to deliver personalized ads to you." | Required if the app uses IDFA / AdMob personalized ads |
| `SKAdNetworkItems` | Google's full SKAdNetwork ID list | Needed for ad-conversion attribution; keep list current ([Google docs](https://developers.google.com/admob/ios/quick-start#update_your_infoplist)) |
| `GADApplicationIdentifier` | `$(GAD_APPLICATION_IDENTIFIER)` | App crashes at launch without it |
| `CFBundleURLTypes` | `$(GOOGLE_REVERSED_CLIENT_ID)` | Google Sign-In callback |
| `UIBackgroundModes` | `remote-notification` | FCM silent pushes |
| `UISupportedInterfaceOrientations` (+`~ipad`) | Landscape only (game) | Match the game's actual orientation |
| `UIRequiresFullScreen` | `true` | Landscape-only apps on iPad must opt out of multitasking, otherwise App Store validation complains about iPad orientations |
| `UIStatusBarHidden` | `true` | Optional, game UI |

> ⚠️ **ATT caveat:** both repos currently only have the plist string. If the app uses `NSPrivacyTracking = true` (see §5), you should actually call the ATT prompt (`app_tracking_transparency` or `MobileAds` UMP consent flow) before `MobileAds.instance.initialize()`, otherwise a reviewer may flag a mismatch between declared tracking and behavior.

---

## 5. Privacy manifest — `ios/Runner/PrivacyInfo.xcprivacy`

Required for App Store submission. Steps:

1. Create the file in `ios/Runner/`.
2. **Add it to the Runner target's Resources** (pbxproj needs a `PBXFileReference` + `PBXBuildFile` in *Resources*; easiest via Xcode: File → Add Files to "Runner"). If it isn't in the target, it isn't bundled.
3. Contents used for Chameleon (adjust to what cardgame really collects):

**Tracking**
```
NSPrivacyTracking = true
NSPrivacyTrackingDomains = googleads.g.doubleclick.net, pagead2.googlesyndication.com,
                           pubads.g.doubleclick.net, googleadservices.com
```

**Collected data types** (Linked = tied to user identity; Tracking = used for tracking)

| Data type | Linked | Tracking | Purposes |
|---|---|---|---|
| EmailAddress | ✅ | ❌ | App functionality |
| Name | ✅ | ❌ | App functionality |
| UserID | ✅ | ❌ | App functionality, Analytics |
| DeviceID | ✅ | ✅ | App functionality, Analytics, Third-party advertising |
| PurchaseHistory | ✅ | ❌ | App functionality |
| ProductInteraction | ✅ | ❌ | Analytics |
| AdvertisingData | ✅ | ✅ | Third-party advertising |
| CrashData | ❌ | ❌ | App functionality |
| PerformanceData | ❌ | ❌ | Analytics |
| OtherUsageData | ✅ | ❌ | Analytics |

**Required-reason APIs**
| Category | Reason |
|---|---|
| `NSPrivacyAccessedAPICategoryUserDefaults` | `CA92.1` |
| `NSPrivacyAccessedAPICategoryFileTimestamp` | `C617.1` |

4. **The App Store Connect → App Privacy questionnaire must match this manifest.** Answer the same data types, mark "used for tracking" for DeviceID/AdvertisingData.
5. Sanity check: Xcode → Product → Archive → Distribute → *Generate Privacy Report*, or inspect the archive's merged report.

---

## 6. AdMob — real iOS ad units

Chameleon shipped initially with iOS placeholders that reused Android units (policy risk + revenue misattribution). Before release:

1. AdMob → Apps → **add the iOS app** (separate from Android).
2. Create units: Rewarded (gems), Rewarded (2x match rewards), Interstitial, Banner/others as used.
3. Paste IDs into `ad_config.dart` (`prodRewardedIos`, `prodMatchDoubleRewardedIos`, `prodInterstitialIos`, …).
4. Keep `useTestIds` for debug; verify **release** builds use prod IDs.
5. AdMob → Privacy & messaging: set up the **UMP consent message** (GDPR/EEA) and the iOS ATT message.
6. Add the iOS app to `app-ads.txt` on your developer website if you use one.

---

## 7. In-app account deletion (App Store guideline 5.1.1(v))

Mandatory if users can create an account (Google / Apple / guest accounts with server profile). Chameleon implementation — copy the pattern:

**Client**
- `AccountApiService.deleteAccount({playerId, idToken?, deviceId?})` → `POST {baseUrl}/account/delete`, 15 s timeout, throws typed exception.
- Settings screen: **DELETE ACCOUNT** button (danger style) → confirmation modal → on confirm:
  1. Get ownership proof: fresh `idToken` via Google/Apple sign-in for linked accounts, stable `deviceId` for guests.
  2. Call the API.
  3. Wipe local state: profile repository `clear()`, friends cache clear, invalidate providers, `signOut()`, `PurchasesService.logOut()`.
  4. `context.go(authentication)`.
  5. On error → error toast, keep the user signed in.
- l10n keys (all locales): `deleteAccount`, `deleteAccountConfirmTitle`, `deleteAccountConfirmBody`, `deleteAccountFailed`.

**Server** (`POST /account/delete`)
- `playerId` alone is **never** sufficient. Require proof:
  - `auth_type` google/apple → verify `idToken` and compare `claims.sub` to stored `google_sub` / `apple_sub` (401 if missing/invalid, 403 `not_owner` on mismatch).
  - guest → `deviceId` must equal stored `device_id`.
- Player already gone → return `200 {ok:true, deleted:false}` (idempotent so the client can finish cleanup).
- `deletePlayerAccount` runs in a **transaction**: null out `referred_by_player_id` pointers, anonymize `iap_redemptions.player_id = 'deleted'` (kept only for purchase replay protection), `DELETE FROM players` (child tables cascade via FKs).
- Deploy the server change **before** submitting the app, or review will fail on a 404.

**Web page**: also host a public "delete account" page (used in the Play Store data-safety form and good to reference in App Store Connect).

---

## 8. Legal / metadata links

- Host **Privacy Policy**, **Terms of Use**, **Delete-account** pages (Chameleon: GitHub Pages `…/apps-privacy/<app>/{privacy,terms,delete-account}/`).
- `AppConstants.privacyPolicyUrl / termsUrl / deleteAccountUrl`.
- On the sign-in screen, make "Terms" and "Privacy Policy" **tappable** (`TapGestureRecognizer` + `launchUrl(..., mode: LaunchMode.externalApplication)`).
- Add the same URLs in App Store Connect: *App Information → Privacy Policy URL* and *Support URL*; Terms in the app description or a custom EULA.
- If the app sells IAP/subscriptions, include **Restore Purchases** (Chameleon already has it in Settings).

---

## 9. Versioning

`pubspec.yaml` → `version: X.Y.Z+N`.
- `X.Y.Z` → `CFBundleShortVersionString` (`$(FLUTTER_BUILD_NAME)`)
- `N` → `CFBundleVersion` (`$(FLUTTER_BUILD_NUMBER)`) — **must be higher than any previous upload to App Store Connect for that version**. Bump `+N` on every TestFlight upload (Chameleon went `+19` → `+20` → `+21`).

---

## 10. App icon & launch screen

- `flutter_launcher_icons.yaml`: `ios: true`, `remove_alpha_ios: true` (**App Store rejects icons with an alpha channel**), then:
  ```bash
  dart run flutter_launcher_icons
  ```
- Verify `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` exists and has no transparency.
- Launch screen: `LaunchScreen.storyboard` + `LaunchBackground` / `LaunchImage` image sets (see `docs/NATIVE_SPLASH_SCREEN_SETUP.md` in Chameleon).

---

## 11. Build, archive, upload

```bash
flutter clean
flutter pub get
cd ios && pod repo update && pod install --repo-update && cd ..
flutter build ipa --release            # or: flutter build ios --release, then archive in Xcode
```

Then either:
- **Xcode**: open `ios/Runner.xcworkspace` → scheme *Runner* → *Any iOS Device (arm64)* → Product → Archive → Distribute App → *App Store Connect → Upload*.
- **CLI**: `xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios --apiKey <KEY> --apiIssuer <ISSUER>` (or the *Transporter* app).

After processing (5–30 min): App Store Connect → TestFlight → select build → answer export-compliance (skipped if `ITSAppUsesNonEncryption=false`) → test on a **real device** → then add the build to the App Store version and *Submit for Review*.

---

## 12. App Store Connect submission form

- **Screenshots**: 6.9" (or 6.7") iPhone and 13" (or 12.9") iPad *if* iPad is supported. Landscape sizes for landscape-only games.
- **App Privacy**: match `PrivacyInfo.xcprivacy` (§5).
- **Age rating questionnaire** (ads + user-generated content/chat → check what applies).
- **Review notes**: include a demo path (guest login works → no credentials needed), mention landscape-only, mention ads + IAP, mention where account deletion lives (*Settings → Delete Account*).
- **Content rights, export compliance, advertising identifier (IDFA)**: answer *Yes, serves ads* and tick the right usage boxes.
- Link IAPs to the version.

---

## 13. Pre-submission verification checklist

Run on a **release build on a physical device** (or at least TestFlight):

- [ ] App launches without crash (missing `GADApplicationIdentifier`/plist = crash at start)
- [ ] Firebase initializes on iOS (no `FirebaseApp` errors); Analytics events visible in DebugView
- [ ] Crashlytics test crash arrives (symbolicated)
- [ ] Push notification received (APNs key uploaded; permission prompt works)
- [ ] Google Sign-In round-trips back into the app; Sign in with Apple works
- [ ] Rewarded + interstitial ads load with **prod** unit IDs (use a test device ID in AdMob, don't click your own ads)
- [ ] ATT prompt appears (if `NSPrivacyTracking = true`) and consent flow works
- [ ] IAP purchase + restore work in **sandbox**
- [ ] Delete Account works for guest, Google and Apple accounts; user is returned to the sign-in screen; server row is gone
- [ ] Terms / Privacy links open
- [ ] No HTTP-only endpoints or, if any, an ATS exception covers them
- [ ] Orientation behaves on iPhone and iPad
- [ ] `grep -rn "REPLACE" ios lib` returns nothing
- [ ] Version/build number bumped

---

## 14. cardgame — status (updated 2026-10-06)

| Item | Status |
|---|---|
| Bundle ID `com.hailsom.shadowhand` | ✅ Firebase iOS app + Google OAuth iOS client created |
| Deployment target 15.0 (Podfile + pbxproj) | ✅ done |
| `DEVELOPMENT_TEAM = ADH269CTVQ` | ✅ done (verify the App ID is registered under this team) |
| `GoogleService-Info.plist` + in Runner target | ✅ done |
| `firebase_options.dart` iOS | ✅ real app ID / API key |
| Google Sign-In (`GOOGLE_REVERSED_CLIENT_ID`, `GIDClientID`) | ✅ ShadowHand iOS client; build with `--dart-define-from-file=flavors/prod.json` for `GOOGLE_SERVER_CLIENT_ID` |
| `CLANG_ALLOW_NON_MODULAR_INCLUDES…` | ✅ both xcconfigs |
| `ITSAppUsesNonEncryption`, `CFBundleDisplayName` | ✅ added |
| `UIRequiresFullScreen` | ➖ not needed (portrait + all iPad orientations supported) |
| `PrivacyInfo.xcprivacy` + in target | ✅ added and reviewed against the published policy (+ CoarseLocation for AdMob) |
| AdMob iOS app + interstitial + rewarded IDs | ✅ `lib/ads/ad_ids.dart`, `Release.xcconfig` |
| ATT + UMP consent before `MobileAds.initialize()` | ✅ already in `lib/main.dart` |
| RevenueCat iOS key (`REVENUECAT_APPLE_API_KEY`) | ✅ in `flavors/*.json`; IAP products configured |
| In-app account deletion | ✅ UI exists; server fixed (`match_players` rows deleted in a transaction) — **deploy server before submitting** |
| Terms / Privacy links | ✅ live on GitHub Pages (`apps-privacy/shadowhand/{privacy,terms,delete-account}`), wired in app + flavors |
| Sign in with Apple entitlement | ➖ not used (Google + guest only) |
| Push: APNs key uploaded to Firebase, `aps-environment` | ✅ key uploaded (verify with a TestFlight push) |
| Version | ✅ `1.0.0+11` (bump `+N` for every upload) |
| Archive, TestFlight, App Store Connect form | ⬜ |

---

## 15. Suggested order of work

1. Apple Developer: App ID, capabilities, APNs key, App Store Connect app (§1)
2. Firebase iOS app + `GoogleService-Info.plist` + Google Sign-In scheme (§2)
3. Xcode/pbxproj: target 15.0, team, xcconfig fixes (§3)
4. `Info.plist` + entitlements (§4)
5. `PrivacyInfo.xcprivacy` (§5)
6. AdMob iOS units + consent (§6)
7. Account deletion verified end-to-end, server deployed (§7)
8. Legal pages + links (§8)
9. Icon check, bump version, archive, TestFlight (§9–11)
10. Fill App Store Connect form and submit (§12–13)

> Tip: do each step as its own small commit, or one `Prepare iOS App Store release (x.y.z+n)` commit like Chameleon's, so `git show` serves as a diff reference.
