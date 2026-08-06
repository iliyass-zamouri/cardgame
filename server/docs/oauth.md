# OAuth setup (Google + Guest)

Native Google sign-in on Flutter; Node verifies ID tokens and links guest
accounts when the provider subject is new.

## Server

1. Start MySQL + server:

```bash
cp .env.example .env
# set GOOGLE_CLIENT_IDS to comma-separated Web+iOS+Android client IDs
npm run docker:up
```

Or local node with MySQL already running on `127.0.0.1:3306`.

2. Endpoints:

| Method | Path           | Body                              | Notes                                          |
| ------ | -------------- | --------------------------------- | ---------------------------------------------- |
| `POST` | `/auth/guest`  | `{ deviceId, platform?, model? }` | `deviceId` must be `local:<uuid-v4>`           |
| `POST` | `/auth/google` | `{ idToken, deviceId? }`          | Verifies Google JWT; links guest by `deviceId` |

Response: `{ playerId, name, username, isNew, authType, linkedFromGuest? }`.

## Google Cloud console

1. Create OAuth clients: **Android** (package + SHA-1), **iOS** (bundle id), **Web** (for `serverClientId` / idToken).
2. Put **all** client IDs in server `GOOGLE_CLIENT_IDS`.
3. Flutter: set **Web** client ID as `--dart-define=GOOGLE_SERVER_CLIENT_ID=…` (see `.vscode/launch.json`).
4. iOS: set `GOOGLE_REVERSED_CLIENT_ID` in `ios/Flutter/Debug.xcconfig` and `Release.xcconfig` to the reversed iOS client id (`com.googleusercontent.apps.…`).

Android package id today: `com.hailsom.shadowhand`.
