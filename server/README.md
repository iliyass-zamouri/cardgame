# Shadow Hand Server

Unified Node 18+ process: REST + raw WebSocket `/ws` on `:8080`.

## Quick start

```bash
cp server/.env.example server/.env
docker compose up -d --build
curl http://127.0.0.1:8080/healthz
```

Service name in Docker: **`cardgame`**.

## Scripts

| Command | Purpose |
|---|---|
| `npm start` | Run API+WS |
| `npm run migrate` | Apply SQL migrations |
| `npm run test:parity` | Dart↔JS event parity |

## Deploy (Oracle VM)

```bash
./server/scripts/deploy_vm.sh
# host default 84.8.222.159
```
