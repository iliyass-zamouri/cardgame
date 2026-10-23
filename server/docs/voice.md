# Voice chat (WebRTC + self-hosted coturn)

Voice audio goes directly from one phone to the other. The game WebSocket only passes along the setup messages (`voiceSignal`). Players on strict NATs, which includes most mobile data, fall back to our own TURN relay. That relay is **coturn**, running on the same OCI host, so there is no third-party service and no extra cost.

## 1. Configure `.env` on the server

```env
COMPOSE_PROFILES=voice
TURN_SHARED_SECRET=<openssl rand -hex 32>
TURN_REALM=cardgame
# OCI uses 1:1 NAT: <public-ip>/<private-ip of the instance VNIC>
TURN_EXTERNAL_IP=203.0.113.10/10.0.0.12
TURN_PRIVATE_IP=10.0.0.12
TURN_URLS=turn:203.0.113.10:3478?transport=udp,turn:203.0.113.10:3478?transport=tcp
```

`GET /voice/ice` gives each signed-in player TURN credentials that expire after 6 hours, signed with `TURN_SHARED_SECRET`. If `TURN_URLS` is empty, the server falls back to STUN only.

## 2. Open the ports on OCI

You need to open the ports in two places.

**VCN → Security List (or NSG) → Ingress rules:**

- TCP 3478
- UDP 3478
- UDP 49160–49200 (the relay range, `min-port`/`max-port` in `server/turn/turnserver.conf`)

**On the instance:** Oracle's Ubuntu images ship with restrictive iptables rules, so add:

```sh
sudo iptables -I INPUT -p udp --dport 3478 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 3478 -j ACCEPT
sudo iptables -I INPUT -p udp --dport 49160:49200 -j ACCEPT
sudo netfilter-persistent save
```

## 3. Start it

```sh
docker compose up -d   # starts coturn too when COMPOSE_PROFILES=voice
docker logs -f cardgame-coturn
```

## 4. Verify

1. Get credentials: `curl -H "Authorization: Bearer <jwt>" https://<host>/voice/ice`
2. Open <https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/>.
3. Add the TURN URL with that username and credential, then click *Gather candidates*.

A `relay` candidate with your public IP means the relay works.

## Capacity

Each call relays two Opus audio streams of about 30–50 kbit/s each, and only when no direct path exists. The config caps each stream at 128 kbit/s and allows 400 allocations in total.
