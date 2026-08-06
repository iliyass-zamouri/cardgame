# Shadow Hand

Flame + Riverpod client, unified Node backend (`cardgame` Docker service).

## Layout

| Path | Role |
|---|---|
| `lib/` | Flutter client (Flame + Riverpod + Camo design) |
| `packages/game_protocol` | Shared wire contract (Dart) |
| `server/` | Node REST + WS `/ws` on `:8080` |
| `docker-compose.yml` | MySQL + **`cardgame`** service |
| `docs/DESIGN_SYSTEM.md` | Camo visual system |
| `docs/ACCEPTANCE_MATRIX.md` | Release gates |
| `docs/DEPLOY.md` | Deploy runbook |

## Run backend

```bash
cp server/.env.example server/.env
docker compose up -d --build
curl http://127.0.0.1:8080/healthz
cd server && npm run test:parity && npm run test:smoke
```

## Run client

```bash
fvm flutter pub get
fvm flutter run --dart-define=BASE_URL=http://127.0.0.1:8080
fvm flutter run --dart-define=ONLINE_MP=false
```

VM: `84.8.222.159:8080` — `server/scripts/deploy_vm.sh`
