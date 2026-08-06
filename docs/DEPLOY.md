# Deploy Runbook

## Local / dev

```bash
cp server/.env.example server/.env
docker compose up -d --build
curl http://127.0.0.1:8080/healthz
cd server && npm run test:parity && npm run test:smoke
```

## Client

```bash
fvm flutter run --dart-define=BASE_URL=http://127.0.0.1:8080
fvm flutter run --dart-define=BASE_URL=http://84.8.222.159:8080
```

## Oracle VM (84.8.222.159:8080)

```bash
./server/scripts/deploy_vm.sh
```

Systemd unit: `server/scripts/cardgame.service`

## Env

| Var | Default |
|---|---|
| `PORT` | 8080 |
| `JWT_SECRET` | change in prod |
| `MYSQL_*` | see `server/.env.example` |

## Metrics

- Queue latency (enqueue → `match.found`)
- Match completion rate
- Reconnect success rate
- Economy mutation error rate
