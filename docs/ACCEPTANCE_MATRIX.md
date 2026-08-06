# Acceptance Matrix

Release gates for Shadow Hand.

## Auth

| Case | Pass criteria |
|---|---|
| Guest auth | `POST /auth/guest` returns `playerId` + token |
| Google/Apple auth | `POST /auth/google` / `/auth/apple` upsert player |
| Token reuse | Protected routes reject missing/invalid bearer |
| WS auth | JWT required; `playerId` must match token subject |
| Offline | `--dart-define=ONLINE_MP=false` uses `NoopSocketClient` |

## Matchmaking / Rooms

| Case | Pass criteria |
|---|---|
| Queue join/cancel | `match.queue` / `match.cancel` update queue |
| Match found | Both clients get `match.found` + `match.snapshot` |
| Private room create/join | `room.create` / `room.join` emit `room.state` |
| Kick / leave / invite | Host kick + leave close member correctly |
| Rematch | `rematch.*` returns `rematch.state`; ready starts new match |

## Live Card Match

| Case | Pass criteria |
|---|---|
| Deal | 4 cards/player + starter discard |
| Reveal | 5s timed reveal; auto transition to playing |
| Draw / throw / swap | Match-value rules enforced server-side |
| Penalty | Wrong throw draws penalty card |
| Turn order | Auto advance after valid action |
| End game | Lowest score wins; history + stats persisted |
| Disconnect | Reconnect by `playerId` + token; rejoin match |

## Social / Economy / Profile

| Case | Pass criteria |
|---|---|
| Profile | `GET /players/:id` returns display + stats |
| Search | `GET /players/search?q=` |
| Match history | `GET /players/:id/matches` |
| Friends | request/respond/list/remove |
| Shop | catalog + purchase with idempotency key |
| Rewarded ads | claim endpoint respects daily cap |

## Ops

| Case | Pass criteria |
|---|---|
| Health | `GET /healthz` returns db + ws stats |
| Docker | Compose service `cardgame` listens `:8080` |
| Protocol parity | Dart events == `server/src/protocol.js` |
| WS smoke | `npm run test:smoke` passes |
