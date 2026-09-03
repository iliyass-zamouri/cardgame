# Server Connection & Administration Guide (84.8.220.240)

Connection and operational manual for Oracle Cloud Infrastructure (OCI) production instance hosting `cardgame`.

---

## 1. Server Overview

| Attribute            | Value                              |
| -------------------- | ---------------------------------- |
| **Host IP**          | `84.8.220.240`                     |
| **Provider**         | Oracle Cloud Infrastructure (OCI)  |
| **OS User**          | `ubuntu`                           |
| **Default SSH Key**  | `~/.ssh/id_upsell`                 |
| **Remote Directory** | `~/cardgame`                       |
| **HTTP / WS Port**   | `8080`                             |
| **MySQL Port**       | `3308` (mapped to internal `3306`) |

---

## 2. Connecting via SSH

### Direct Connection

Ensure SSH key has correct permissions:

```bash
chmod 600 ~/.ssh/id_upsell
```

Connect directly:

```bash
ssh -i ~/.ssh/id_upsell ubuntu@84.8.220.240
```

### SSH Config Shortcut (Recommended)

Add entry to local `~/.ssh/config`:

```sshconfig
Host cardgame-prod
    HostName 84.8.220.240
    User ubuntu
    IdentityFile ~/.ssh/id_upsell
    IdentitiesOnly yes
```

Then connect with:

```bash
ssh cardgame-prod
```

---

## 3. Remote Service Architecture

Containers run via Docker Compose in `~/cardgame`:

- **`cardgame-server`**: Node.js backend (`0.0.0.0:8080`).
- **`cardgame-mysql`**: MySQL 8.4 database (`0.0.0.0:3308 -> 3306`).
- **Storage Volume**: `cardgame_mysql_data` for persistent database files.

---

## 4. Common Server Operations

Once connected to the server (`cd ~/cardgame`):

### Check Container Status

```bash
sudo docker compose ps
```

### View Live Logs

```bash
# All containers
sudo docker compose logs -f

# App server only
sudo docker compose logs -f server

# MySQL only
sudo docker compose logs -f mysql
```

### Restart Services

```bash
# Restart app server without stopping MySQL
sudo docker compose restart server

# Full stack restart
sudo docker compose down && sudo docker compose up -d
```

### Rebuild and Run After Code Changes

```bash
sudo docker compose up --build -d
```

### Health Check

From server:

```bash
curl -sS http://127.0.0.1:8080/health
```

From local machine:

```bash
curl -sS http://84.8.220.240:8080/health
```

Expected response:

```json
{ "status": "ok" }
```

---

## 5. Deployment from Local Machine

Deploy changes directly using repository script:

```bash
./scripts/deploy-oci.sh
```

### Optional Environment Overrides

```bash
CARDGAME_OCI_HOST="ubuntu@84.8.220.240" \
CARDGAME_OCI_KEY="$HOME/.ssh/id_upsell" \
CARDGAME_OCI_DIR="~/cardgame" \
./scripts/deploy-oci.sh
```

---

## 6. Troubleshooting

### 1. `Permission denied (publickey)`

- Verify private key exists: `ls -la ~/.ssh/id_upsell`
- Verify correct file mode: `chmod 600 ~/.ssh/id_upsell`
- Confirm username is `ubuntu` (not `root` or `admin`).

### 2. `Connection timed out` on port 22 or 8080

- Check OCI VCN Ingress Rules / Security Lists allow TCP port 22 (SSH) and port 8080 (HTTP).
- Check instance `iptables` / `ufw` on the server:
  ```bash
  sudo iptables -L -n -v
  ```

### 3. Server Unhealthy / Crashing

Inspect container termination exit code and output:

```bash
sudo docker compose ps -a
sudo docker compose logs --tail=100 server
```

Verify MySQL container is healthy before app startup:

```bash
sudo docker compose exec mysql mysqladmin ping -uroot -proot
```
