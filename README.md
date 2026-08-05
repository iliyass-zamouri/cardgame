# Card Game

Flutter multiplayer card game with an **authoritative** Node WebSocket server.

## Stack

| Layer | Tech |
| --- | --- |
| Client | Flutter 3.35 (FVM) + Riverpod + Flame |
| Server | Node.js + `ws` room authority |
| Protocol | Commands in → per-player snapshots out |

## Project layout

```
lib/
  app/          # Riverpod session controller + immutable UI state
  data/         # WebSocket client
  domain/       # Snapshot models
  ui/
    flame/      # Flame gameplay board (cards, hands, table)
    screens/    # Lobby / waiting room / HUD shell
server/
```

## Setup

```bash
# Flutter (uses FVM pin in .fvmrc)
fvm flutter pub get

# Server
npm install
```

## Run

```bash
# Terminal 1 — game server (ws://127.0.0.1:8080)
npm start

# Terminal 2 — app
fvm flutter run -d <device>
```

Or use VS Code / Cursor **Full Stack: iOS + Server** from Run and Debug.

## Play

1. Create room on device A → note the 6-character code  
2. Join that code on device B  
3. Start game when both connected  
4. Eye button reveals bottom cards for 5 seconds  

## Test

```bash
fvm flutter analyze
fvm flutter test
npm test
```

## Config

| Env / define | Default | Meaning |
| --- | --- | --- |
| `HOST` / `PORT` | `127.0.0.1` / `8080` | Server bind |
| `--dart-define=WS_HOST=` | `127.0.0.1` | Client host |
| `--dart-define=WS_PORT=` | `8080` | Client port |

Android emulator uses `WS_HOST=10.0.2.2` (see `.vscode/launch.json`).
