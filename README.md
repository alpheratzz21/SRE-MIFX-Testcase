# MIFX Site Reliability Engineer Test

## Tech Stack
- **Web Server**: Nginx (non-root, security hardened)
- **Language**: PHP 8.2-FPM
- **Base Image**: Alpine Linux
- **Container**: Docker + Docker Compose
- **Database**: PostgreSQL 16
- **Deployment**: Ansible
- **CI/CD**:  GitHub Actions

---

## Project Structure
```
mifx-testcase/
├── Dockerfile                       # Docker image definition (Nginx + PHP 8.2 on Alpine)
├── nginx.conf                       # Nginx configuration (security hardened)
├── compose.yaml               # Multi-container setup (app + PostgreSQL)
├── .github/
│   └── workflows/
│       └── pipeline.yml             # GitHub Actions pipeline (alternative)
├── .gitignore
├── README.md
│
├── app/
│   └── index.php                    # PHP application (Hello World)
│
├── ansible/
│   ├── deploy.yml                   # Ansible deployment playbook
│   └── inventory.ini                # Target server configuration (SSH key)
│
├── database/
│   ├── init.sql                     # Database users & privileges setup
│   └── postgresql.conf              # PostgreSQL custom config (max_connections)
│
└── scripts/
    ├── logrotate.sh                 # Log rotation bash script
    └── logrotate.py                 # Log rotation Python script
```

---

## Prerequisites
- Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- WSL2 (Windows users)
- Docker Hub account
- Python 3 & Ansible (for deployment only)

---

## How to Run Locally (WSL / Linux / Mac)

> **Windows users**: run all commands from WSL terminal, not PowerShell or CMD.

### 1. Verify Docker is Running
```bash
docker --version
docker compose version
# If you see version numbers, you're good to go
# If error, open Docker Desktop on Windows first
```

### 2. Clone the Repository
```bash
git clone https://github.com/alpheratzz21/SRE-MIFX-Testcase.git
cd mifx-testcase
```

### 3. Build Docker Image
```bash

docker build -t rifqiananda/mifx-nginx-php:latest .
```

### 4. Push to Docker Hub
```bash
# Login to Docker Hub
docker login

# Push image
docker push rifqiananda/mifx-nginx-php:latest
```

### 5. Start All Services
```bash
# Start app + database in background
docker compose up -d

# Check all containers are running (status should be "Up")
docker compose ps
```

### 6. Open in Browser
```
http://localhost:8080
```
You should see the PHP Hello World page.

### 7. Test the Database
```bash
# Enter the PostgreSQL container (check exact name with docker compose ps)
docker exec -it devops-test-db-1 psql -U fullaccess_user -d sre
```

Inside psql:
```sql
-- Check max_connections is set to 200
SHOW max_connections;

-- Exit psql
\q
```

### 8. Verify Security Hardening
```bash
# Check Server header — should show "webserver", not "nginx"
curl -I http://localhost:8080

# Check .git is blocked — should return 404
curl http://localhost:8080/.git/config

# Check directory listing is disabled — should return 403
curl http://localhost:8080/somefolder/
```

### Stop All Containers
```bash
# Stop but keep data
docker compose down

# Stop and delete all data including database
docker compose down -v
```

---

### Troubleshooting (WSL)

**Port already in use:**
```bash
# Check if port 8080 or 5432 is already taken
netstat -tulpn | grep 8080
netstat -tulpn | grep 5432

# If taken, change the port in docker-compose.yml (e.g. 8080 → 8081)
```

**Container fails to start:**
```bash
# Check detailed error logs
docker compose logs app
docker compose logs db
```

---

## Database

### Users
| User | Role |
|------|------|
| `fullaccess_user` | Full access to `sre` database (owner) |
| `readonly_user` | Read-only access (SELECT only) |

### Check max_connections
```sql
-- Run inside psql to verify max_connections is increased
SHOW max_connections;

-- Expected output:
--  max_connections
-- -----------------
--  200
```
> `max_connections` is set to `200` (default is 100) inside `database/postgresql.conf`

---

## Security Hardening

### Nginx
| Requirement | Solution |
|-------------|----------|
| No directory listing when no index file | `autoindex off` in nginx.conf |
| Block access to `.git` folder | `location ~ /\.git { deny all; return 404; }` |
| Nginx not running as root | `user www;` at top of nginx.conf |
| Server response header is not nginx | `server_tokens off` + `add_header Server "webserver"` |

### PHP
| Requirement | Solution |
|-------------|----------|
| PHP cannot run `exec()` | `disable_functions = exec,shell_exec,system,passthru` in security.ini |
| PHP-FPM not running as root | `sed` in Dockerfile changes FPM user from `www-data` to `www` |

---

## Ansible

### Files
- `inventory.ini` — defines target server with SSH key authentication
- `deploy.yml` — pulls latest Docker image and force-recreates containers

### Run Deployment
```bash
# Make sure your SSH key is at ~/.ssh/id_rsa
# Edit ansible/inventory.ini and fill in your server IP first

ansible-playbook -i ansible/inventory.ini ansible/deploy.yml
```

### How it works
1. Connects to target server via SSH key (no password needed)
2. Copies `docker-compose.yml` to the server
3. Runs `docker compose pull` to get the latest image
4. Runs `docker compose up -d --force-recreate` to force update all containers

---

## CI/CD

### Option A — GitLab CI (.gitlab-ci.yml)

#### Pipeline Behavior
```
Commit touches Dockerfile          → runs: build → deploy
Commit touches docker-compose.yml  → runs: deploy only
```

#### Setup CI/CD Variables
Go to: `GitLab repo → Settings → CI/CD → Variables`

| Key | Value | Note |
|-----|-------|------|
| `DOCKER_USERNAME` | your Docker Hub username | ✅ Mask this |
| `DOCKER_PASSWORD` | your Docker Hub password | ✅ Mask this |

> **Never hardcode credentials in `pipeline.yml`** — always use CI/CD Variables.

---

### Option B — GitHub Actions (.github/workflows/pipeline.yml)

#### Pipeline Behavior
```
Commit touches Dockerfile          → runs: build → deploy
Commit touches docker-compose.yml  → runs: deploy only
```

#### Setup Secrets
Go to: `GitHub repo → Settings → Secrets and variables → Actions → New repository secret`

| Name | Value | Note |
|------|-------|------|
| `DOCKER_USERNAME` | your Docker Hub username | ✅ Keep secret |
| `DOCKER_PASSWORD` | your Docker Hub password | ✅ Keep secret |
| `SSH_PRIVATE_KEY` | your SSH private key content | ✅ Keep secret |

---

## Quiz — Fix Broken .gitlab-ci.yml

**Problem:**
```yaml
stages:
  - unittest
  -security-scan      # ← BUG: missing space after "-"
```

**Fix:**
```yaml
stages:
  - unittest
  - security-scan     # ← FIXED: added space after "-"
```
> YAML lists require a space between `-` and the value. Without it, GitLab cannot parse the stage name correctly and the pipeline will fail to run.

---

## Database Case Scenario — Slow Query Analysis

**Slow query reported:**
```sql
SELECT count(affiliates) FROM client WHERE client_id = 'this_is_client_id';
```

**Root Cause:**

The `client_id` column has no index. PostgreSQL performs a **full table scan** — it reads every single row in the table to find matching records. The larger the table, the slower the query, which causes CPU spikes on the database server.

**Why the dashboard showed no spikes:**
The bottleneck was entirely in the database layer (full table scan = heavy read I/O + CPU usage). The application layer was fine — it was just waiting for the DB to respond, so no spikes appeared on the backend dashboard.

**Solution:**
```sql
-- Add an index on the client_id column
-- After this, PostgreSQL jumps directly to matching rows instead of scanning all rows
CREATE INDEX idx_client_client_id ON client(client_id);

-- Verify the query now uses the index
-- Look for "Index Scan" in the output instead of "Seq Scan"
EXPLAIN ANALYZE SELECT count(affiliates) FROM client WHERE client_id = 'this_is_client_id';
```

---

## Scripting

### What does `set -e` do?
`set -e` makes a bash script **immediately stop** if any command fails (returns a non-zero exit code).

- **Without `set -e`**: if a command fails, the script keeps running — potentially causing unintended side effects.
- **With `set -e`**: the script stops at the first failure, making errors easier to catch and debug.

### Run logrotate (Bash)
```bash
chmod +x scripts/logrotate.sh
./scripts/logrotate.sh
```

### Run logrotate (Python)
```bash
python3 scripts/logrotate.py
```

### Logrotate Behavior
- Scans every `.log` file in the configured directory
- If file size > **5MB**: compresses it to a `.gz` archive with timestamp, then truncates the original file to 0 bytes
- All actions (archived, skipped, truncated) are logged with timestamps to a script log file