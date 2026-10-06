# App Review reply — Guideline 2.1 (Information Needed)

Paste the **Reply** into App Store Connect (Resolution Center → Reply), and paste the **Notes field** version into *App Information → App Review Information → Notes*. Both are the same content; the Notes version is the short form.

Before sending, **record the screen video** (see checklist at the bottom) and attach it to the reply.

---

## Reply (Resolution Center)

Hello App Review team,

Thank you for the review. Here is the information requested for **ShadowHand** (`com.hailsom.shadowhand`). A screen recording from a physical iPhone is attached.

### 1. Screen recording
Recorded on a physical iPhone (latest iOS). It starts at app launch and shows: sign-in as guest and with Google, a practice match, finding/creating a multiplayer match, the friends list with **Report** and **Block**, the Marketplace and an In-App Purchase, Restore Purchases, and **Settings → Delete Account**.

### 2. Purpose and audience
ShadowHand is a head-to-head multiplayer card game ("Two players. One table.") for casual players aged 13+. Players compete in short matches, climb a global ranking, collect cosmetic card decks and avatars, and play with friends via private room codes. It solves the "quick, fair, two-player card game with friends" need: no setup, play as a guest in seconds, optional account linking to keep progress.
In-game "money" and "chips" are **virtual currency only**; they have no cash value, can't be withdrawn, and the app is **not real-money gambling**. This is stated in the Marketplace and in our Terms.

### 3. How to access the main features
No credentials are required.
1. Launch the app and tap **Play as Guest** (or **Continue with Google**).
2. Home screen:
   - **Practice vs Robot**: plays a full match against a bot, no opponent needed (works offline).
   - **Find match**: online matchmaking against another player.
   - **Create room / Join room**: private match with a 6-letter code (use two devices to test).
   - **Ranking**: global leaderboard. **Friends**: friend list. **Marketplace**: items and purchases. **How to play**: rules. **Deck**: card-back cosmetics.
3. **Settings** (gear icon): language, Restore Purchases, Privacy Policy, Terms, Sign out, **Delete Account**.

No demo account is needed because guest play is complete. If you want to test Google sign-in, any Google account works.

### 4. External services
- **Google Sign-In**: optional account sign-in
- **Firebase** (Analytics, Crashlytics, Cloud Messaging/APNs): usage analytics, crash reports, push notifications
- **Google AdMob**: interstitial and rewarded ads (iOS shows the App Tracking Transparency prompt; EEA/UK users see Google's consent prompt)
- **RevenueCat** with the App Store: in-app purchase processing and entitlement validation
- **Our own backend** (Node.js game server and MySQL on Oracle Cloud): accounts, matchmaking, rankings, friends
- No AI services. No third-party content or data providers.

### 5. Regional differences
The app works the same in all regions. The only difference is the interface language (English, Spanish, French, Portuguese, Arabic) and that users in the EEA/UK see a consent message for ads.

### 6. Regulated industry / protected material
Not applicable. ShadowHand is an entertainment game; it uses no real-money wagering, no protected third-party material, and no regulated services. All art and code are owned by Hailsom.

### 7. In-App Purchase
Consumable "Chips" packs (virtual currency used for items and stakes):
| Product | Price (USD) |
|---|---|
| 1 Chip | $0.99 |
| 5 Chips | $3.99 |
| 10 Chips | $8.99 |
| 25 Chips | $19.99 |
| 50 Chips | $34.99 |

**Where to find it:** Home → **Marketplace** → scroll to the chip packs → tap **Buy** on a pack. **Restore Purchases** is under Settings. Users can also earn free in-game money by watching an optional rewarded ad (Marketplace → *Watch ad*). There are no subscriptions in this version.
The In-App Purchase products are attached to this app version.

### Account deletion, reporting, and blocking
- **Delete Account:** Settings → **Delete Account** → confirm. It permanently deletes the server profile and related data and returns to the sign-in screen. Details: https://iliyass-zamouri.github.io/apps-privacy/shadowhand/delete-account/
- **Report / Block:** Home → **Friends** → open the ⋮ menu on a player → **Report** or **Block**. Reports are reviewed and offending accounts can be suspended (Terms §8).
- Privacy Policy: https://iliyass-zamouri.github.io/apps-privacy/shadowhand/privacy/
- Terms of Service: https://iliyass-zamouri.github.io/apps-privacy/shadowhand/terms/

Contact: privacy@hailsom.com

Thank you,
Iliyass Zamouri

---

## Notes field (App Review Information) — short form

```
ShadowHand is a two-player online card game (13+). Virtual currency only, no real-money gambling.

ACCESS: No login needed. Tap "Play as Guest". (Optional: "Continue with Google" with any Google account.)
MAIN FEATURES (Home): Practice vs Robot (single device, no opponent needed), Find match (online), Create/Join room (6-letter code), Ranking, Friends, Marketplace, How to play, Deck.
SETTINGS (gear): Restore Purchases, Privacy Policy, Terms, Sign out, Delete Account (permanent, in-app).
UGC SAFETY: Friends -> menu on a player -> Report / Block.
IN-APP PURCHASE: Marketplace -> chip packs (consumable, 1/5/10/25/50 Chips, $0.99-$34.99). Restore in Settings. Optional rewarded ad for free in-game money. No subscriptions.
SERVICES: Google Sign-In, Firebase (Analytics, Crashlytics, FCM), Google AdMob (ATT prompt on iOS), RevenueCat, own Node.js backend on Oracle Cloud. No AI services.
REGIONS: Same everywhere. Languages: EN, ES, FR, PT, AR. EEA/UK users see an ad-consent prompt.
REGULATED/THIRD-PARTY MATERIAL: Not applicable.
Privacy: https://iliyass-zamouri.github.io/apps-privacy/shadowhand/privacy/
Delete account: https://iliyass-zamouri.github.io/apps-privacy/shadowhand/delete-account/
Contact: privacy@hailsom.com
```

---

## Screen-recording checklist (physical iPhone, latest iOS)

Record via Control Center → Screen Record (turn the mic off or narrate). Keep it 2–4 minutes, one take if possible.

1. **Launch** the app from the Home Screen (start recording before tapping the icon).
2. Allow the **ATT prompt** (and consent prompt if shown) and push permission.
3. **Guest sign-in** → Home screen.
4. **How to play** (a few seconds), then **Practice vs Robot** — play a few turns to the end of a match.
5. **Find match** or **Create room** (show the room code; ideally join from a second device).
6. **Ranking** screen, then **Friends**: add a friend, open the ⋮ menu → show **Report** and **Block**.
7. **Marketplace**: show chip packs and complete one **sandbox purchase** (sign in with a Sandbox Apple ID). Show the **rewarded ad** option.
8. **Settings** → **Restore Purchases** → open **Privacy Policy** / **Terms**.
9. **Sign in with Google** (link account) if you want to show account registration.
10. **Settings → Delete Account** → confirm → back at the sign-in screen. Do this last (use a throwaway account, not your main).

Before sending: run through steps 3–10 on the exact TestFlight build to catch bugs and crashes first.

## Before you reply — things to double-check

- The IAP products exist in App Store Connect with IDs `chips_1`, `chips_5`, `chips_10`, `chips_25`, `chips_50`, are "Ready to Submit", and are attached to the version.
- Screenshots show real gameplay (not just title/login) — guideline 2.3.3.
- **Guideline 4.8:** the app offers Google sign-in but no Sign in with Apple. Guest play needs no login at all, but Apple may still raise 4.8 (third-party login must be paired with a privacy-preserving option). If they do, the fix is to add Sign in with Apple. I haven't confirmed how Apple would treat guest play here.
