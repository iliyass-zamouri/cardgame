# Firebase Cloud Messaging (FCM) + Analytics + Crashlytics

Shadow Hand uses Firebase project **`shadow-hand`** (`com.hailsom.shadowhand`).

## Client packages

- `firebase_core`, `firebase_analytics`, `firebase_messaging`, `firebase_crashlytics`
- `flutter_local_notifications` (foreground banners)

Android channel id: **`shadowhand_default`**

## Console (manual)

1. Firebase project: `shadow-hand`
2. Enable **Cloud Messaging**
3. **Android**: existing `android/app/google-services.json` is enough
4. **iOS**:
   - Add iOS app (`com.hailsom.shadowhand`) in Firebase Console
   - Download `GoogleService-Info.plist` → `ios/Runner/`
   - Run `flutterfire configure` (or fix `lib/firebase_options.dart` iOS `appId`)
   - Upload APNs Auth Key (`.p8`) under Project settings → Cloud Messaging
5. Create a **service account** (Firebase Admin SDK) → download JSON

## Server env

In `.env`:

```bash
FIREBASE_SERVICE_ACCOUNT_JSON=/absolute/path/to/serviceAccount.json
# or paste the raw JSON string

ADMIN_PUSH_SECRET=long-random-secret
```

Schema is auto-created via `ensurePushSchema()` on server boot (`device_tokens`, notify pref columns, `player_notifications`).

## Ops dashboard

Open `http://<host>:<port>/admin` (logged on server start). Enter `ADMIN_PUSH_SECRET`.

Tabs: Overview · Live · Matches · Players · Data (Google players CSV) · Push (preview + marketing blast).

All `/admin/*` APIs (except the HTML page) require header `x-admin-push-secret`.

## Client behavior

- Soft permission prompt on home after first visit
- Token register: `POST /devices/register` after identity known
- Prefs: Settings → Notifications
- Inbox: bell on home → notifications panel
- Deeplinks use `Navigator.push` so back/pop works; table invites pop to home then confirm join

## Automatic push events

| Event              | Category  | Payload type              |
| ------------------ | --------- | ------------------------- |
| Table invite       | invites   | `table_invite` + `roomId` |
| Friend request     | social    | `friend_request`          |
| Friend accept      | social    | `friend_accepted`         |
| `POST /admin/push` | marketing | `marketing`               |

## Crashlytics

Enabled in release via `CrashlyticsService` (`FlutterError` + `runZonedGuarded`). User id set with analytics on login.
