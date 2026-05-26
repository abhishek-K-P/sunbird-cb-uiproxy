# sunbird-cb-uiproxy - Local Setup Guide

A comprehensive guide listing everything required to run the UI Proxy server locally.

---

## Table of Contents

1. [System Prerequisites](#1-system-prerequisites)
2. [Node.js & npm](#2-nodejs--npm)
3. [External Service Dependencies](#3-external-service-dependencies)
4. [Clone & Install](#4-clone--install)
5. [Environment Variables (Complete List)](#5-environment-variables-complete-list)
6. [Session Store Configuration](#6-session-store-configuration)
7. [Keycloak Authentication Setup](#7-keycloak-authentication-setup)
8. [Cassandra Database Setup](#8-cassandra-database-setup)
9. [Redis Setup (Optional)](#9-redis-setup-optional)
10. [Nodemon Configuration](#10-nodemon-configuration)
11. [Running the Server](#11-running-the-server)
12. [Build Process](#12-build-process)
13. [Port & Network Requirements](#13-port--network-requirements)
14. [Backend Services the Proxy Depends On](#14-backend-services-the-proxy-depends-on)
15. [Troubleshooting](#15-troubleshooting)

---

## 1. System Prerequisites

| Requirement | Details |
|-------------|---------|
| **OS** | Linux / macOS / Windows (WSL recommended) |
| **Git** | For cloning the repository |
| **Docker** (recommended) | For running Cassandra, Redis, Elasticsearch locally |
| **Puppeteer system libs** | Required if content-to-PDF features are used |

### Puppeteer System Libraries (Linux)

```bash
sudo apt-get install -y \
  libnotify-dev \
  libnss3 \
  libxss1 \
  libasound2 \
  fonts-liberation \
  libappindicator3-1 \
  libdrm2 \
  libgbm1 \
  libgconf-2-4 \
  xdg-utils
```

---

## 2. Node.js & npm

| Item | Version |
|------|---------|
| **Node.js** | >= 14.19.0 (recommended: Node 20 as used in Dockerfile) |
| **npm** | Comes with Node.js |
| **TypeScript** | 3.5.x (installed as devDependency) |
| **ts-node** | 8.x (installed as devDependency, used by nodemon) |

Use `nvm` to manage Node versions:
```bash
nvm install 20
nvm use 20
```

---

## 3. External Service Dependencies

The proxy connects to many backend microservices. **Minimum required for startup:**

| Service | Required? | Purpose |
|---------|-----------|---------|
| **Cassandra** | YES (default session store) | Session persistence + form-service |
| **Keycloak** | YES (for protected routes) | Authentication & authorization |
| **Redis** | Optional | Alternative session store, log-level sync |
| **Elasticsearch** | Optional | PID/search features |
| **Backend microservices** | Optional | Individual APIs will fail without their backend |

---

## 4. Clone & Install

```bash
# Clone
git clone https://github.com/sunbird-cb/sunbird-cb-uiproxy
cd sunbird-cb-uiproxy

# Install dependencies
npm install
```

> **Note:** Two dependencies are installed from custom Git repos:
> - `cassandra-store` → `git+https://github.com/KB-iGOT/cassandra-store.git#cbrelease-4.8.28`
> - `keycloak-connect` → `git+https://github.com/KB-iGOT/keycloak-nodejs-connect.git#4.8.21-test`
>
> Ensure you have access to these repositories (or network access to GitHub).

---

## 5. Environment Variables (Complete List)

### Core Server

| Variable | Default | Description |
|----------|---------|-------------|
| `PORTAL_PORT` | `3003` | Server listening port |
| `NODE_ENV` | `development` | Environment mode |
| `CORS_ENVIRONMENT` | `prod` | CORS config mode |
| `IS_DEVELOPMENT` | Derived from NODE_ENV | Dev mode flag |
| `TIMEOUT` | `10000` | Default request timeout (ms) |
| `PROXY_TIMEOUT` | `10000` | Proxy route timeout (ms) |
| `NODE_TLS_REJECT_UNAUTHORIZED` | (not set) | Set to `0` for dev to skip TLS validation |
| `APP_CONFIGURATIONS` | `/app-config` | App config path |
| `APP_LOGS` | `/logs` | Log directory |

### Cassandra Database

| Variable | Default | Description |
|----------|---------|-------------|
| `CASSANDRA_IP` | `10.177.157.30` | Cassandra host(s), comma-separated |
| `CASSANDRA_KEYSPACE` | `bodhi` | Keyspace name |
| `CASSANDRA_USERNAME` | (empty) | Auth username |
| `CASSANDRA_PASSWORD` | (empty) | Auth password |
| `CASSANDRA_AUTH_ENABLED` | `false` | Enable Cassandra auth |
| `CASSANDRA_REPLICATION_FORM` | `3` | Replication factor |
| `PORTAL_CASSANDRA_CONSISTENCY_LEVEL` | `one` | Consistency level |

### Keycloak Authentication

| Variable | Default | Description |
|----------|---------|-------------|
| `HTTPS_HOST` | `https://igot-dev.in` | Base HTTPS URL |
| `KEYCLOAK_REALM` | `sunbird` | Keycloak realm name |
| `KEYCLOAK_PUBLIC_KEY` | `publicKey` | **REQUIRED** - Public key for JWT verification |
| `KEYCLOAK_ADMIN_USERNAME` | `admin` | Admin username |
| `KEYCLOAK_ADMIN_PASSWORD` | (empty) | Admin password |
| `KEYCLOAK_SESSION_TTL` | `86400000` (24h) | Session TTL in ms |
| `KC_NEW_USER_DEFAULT_PWD` | `User@123` | Default password for new users |
| `MULTI_TENANT_KEYCLOAK` | `igot,https://portal.karmayogi.nic.in/auth,sunbird` | Multi-tenant config (semicolon-separated) |
| `PORTAL_AUTH_SERVER_URL` | `https://portal.karmayogi.nic.in/auth` | Auth server URL |
| `PORTAL_REALM` | `sunbird` | Portal realm |

### Redis (Session Store Alternative)

| Variable | Default | Description |
|----------|---------|-------------|
| `PORTAL_SESSION_STORE_TYPE` | `cassandra` | Options: `cassandra`, `redis`, `in-memory` |
| `IGOT_REDIS_HOST` | `localhost` | Redis host |
| `IGOT_REDIS_PORT` | `6379` | Redis port |
| `IGOT_REDIS_DB_INDEX` | `8` | Redis DB index |
| `LOG_LEVEL_SYNC_ENABLED` | `false` | Sync log level from Redis |
| `LOG_LEVEL_REDIS_KEY` | `ui_proxy_log_level` | Redis key for log level |

### Backend Service URLs

| Variable | Default | Description |
|----------|---------|-------------|
| `CONTENT_API_BASE` | `http://localhost:5903` | Content service |
| `JAVA_API_BASE` | `http://localhost:5825` | Java backend |
| `NODE_API_BASE` | `http://localhost:5001` | Node backend 1 |
| `NODE_API_BASE_2` | `http://localhost:3009` | Node backend 2 |
| `NODE_API_BASE_3` | `http://localhost:3015` | Node backend 3 |
| `SBEXT_API_BASE` | `http://localhost:5902` | Sunbird extension 1 |
| `SBEXT_API_BASE_2` | `http://localhost:7001` | Sunbird extension 2 |
| `SBEXT_API_BASE_3` | (fallback to SBEXT_2) | Sunbird extension 3 |
| `SBEXT_API_BASE_4` | (fallback to SBEXT_2) | Sunbird extension 4 |
| `ES_BASE` | `http://localhost:9200` | Elasticsearch |
| `ES_USERNAME` | `elastic` | ES auth user |
| `ES_PASSWORD` | `iGOT@123+` | ES auth password |
| `NOTIFICATIONS_API_BASE` | `http://localhost:5805` | Notifications |
| `TELEMETRY_API_BASE` | `http://localhost:8090` | Telemetry |
| `TELEMETRY_SB_BASE` | `http://localhost:9090` | Sunbird telemetry |
| `WEB_HOST_PROXY` | `http://localhost:3007` | Web host |
| `SUNBIRD_BACKEND` | `http://localhost:3011` | Authoring backend |
| `NETWORK_HUB_SERVICE_BACKEND` | `http://localhost:3013` | Network hub |
| `KHUB_GRAPH_DATA` | `http://localhost:3016` | Knowledge hub graph |
| `KHUB_SEARCH_BASE` | `http://localhost:3014` | Knowledge hub search |
| `STATIC_ILP_PROXY` | `http://localhost:3005` | Static ILP |
| `USER_PROFILE_API_BASE` | `http://localhost:3004` | User profile |
| `DISCUSSION_HUB_API_BASE` | `http://localhost:4567` | Discussion hub (NodeBB) |
| `DISCUSSION_HUB_MIDDLEWARE` | `http://localhost:3002` | Discussion middleware |
| `OPEN_SABER_USER_REGISTRY_BASE` | `http://localhost:8005` | OpenSaber user registry |
| `KONG_API_BASE` | `https://portal.karmayogi.nic.in/api` | Kong API gateway |
| `KNOWLEDGE_MW_API_BASE` | `http://knowledge-mw-service:5000` | Knowledge MW |
| `LEARNER_SERVICE_API_BASE` | `http://learner-service:9000` | Learner service |
| `CONTENT_SERVICE_API_BASE` | `http://content-service:9000` | Content service (SB) |
| `NOTIFICATION_SERVIC_API_BASE` | `http://notification-service:9000` | Notification service |
| `FRAC_API_BASE` | `https://frac.igot-dev.in` | FRAC service |
| `WORKFLOW_HANDLER_SERVICE_API_BASE` | `http://localhost:5099` | Workflow handler |
| `CONTENT_VALIDATION_API_BASE` | `http://localhost:6590` | Content validation |
| `PROFANITY_SERVICE_API_BASE` | `http://localhost:4001` | Profanity service |
| `SCORING_SERVICE_API_BASE` | `http://localhost:7014` | Scoring service |
| `PM_DASHBOARD_API_BASE` | `https://pm.igot-dev.in` | PM Dashboard |
| `DASHBOARD_API_BASE` | `https://igot-dashboard.tarento.com/api` | Dashboard |

### OAuth / SSO Integrations (Optional)

| Variable | Default | Description |
|----------|---------|-------------|
| `GOOGLE_CLIENT_ID` | `googleClientId` | Google OAuth client ID |
| `GOOGLE_CLIENT_SECRET` | `googleClientSecret` | Google OAuth secret |
| `PARICHAY_CLIENT_ID` | `parichayClientId` | Parichay OAuth client ID |
| `PARICHAY_CLIENT_SECRET` | `parichayClientSecret` | Parichay OAuth secret |
| `PARICHAY_AUTH_URL` | `parichayAuthUrl` | Parichay auth endpoint |
| `PARICHAY_TOKEN_URL` | `parichayTokenUrl` | Parichay token endpoint |
| `PARICHAY_USER_DETAILS_URL` | `parichayUserDetailsUrl` | Parichay user info URL |
| `OIL_CLIENT_ID` | `oilClientId` | OIL OAuth client ID |
| `OIL_CLIENT_SECRET` | `oilClientSecret` | OIL OAuth secret |
| `NTPC_CLIENT_ID` | `ntpcClientId` | NTPC OAuth client ID |
| `NTPC_CLIENT_SECRET` | `ntpcClientSecret` | NTPC OAuth secret |

### Connection Pool Tuning

| Variable | Default | Description |
|----------|---------|-------------|
| `UPSTREAM_MAX_CONNECTIONS` | `Infinity` | Max concurrent connections per upstream |
| `UPSTREAM_MAX_IDLE_CONNECTIONS` | `256` | Keep-alive idle sockets |
| `UPSTREAM_KEEPALIVE_TIMEOUT` | `40000` | Idle socket timeout (ms) |

### Logging

| Variable | Default | Description |
|----------|---------|-------------|
| `LOG_LEVEL` | `error` | Pino log level (trace/debug/info/warn/error/fatal) |
| `LOG_LEVEL_ADMIN_TOKEN` | (empty) | Token for runtime log level control |
| `LOG_LEVEL_POLL_INTERVAL_MS` | `10000` | Poll interval for log level sync |

### Application-Specific

| Variable | Default | Description |
|----------|---------|-------------|
| `X_CHANNEL_ID` | `0131397178949058560` | Channel identifier |
| `DEFAULT_ORG` | `dopt` | Default organization |
| `DEFAULT_ROOT_ORG` | `igot` | Default root org |
| `SB_API_KEY` | `bearer apiKey` | API key for telemetry/sunbird calls |
| `PORTAL_API_WHITELIST_CHECK` | `true` | Enable API whitelist enforcement |
| `DISCUSSION_HUB_DEFAULT_PASSWORD` | `nodebbUser123$` | NodeBB user password |
| `DISCUSSION_HUB_WRITE_API_KEY` | (UUID) | NodeBB write API key |

---

## 6. Session Store Configuration

The server supports 3 session store types (set via `PORTAL_SESSION_STORE_TYPE`):

### Option A: Cassandra (Default)
```bash
PORTAL_SESSION_STORE_TYPE=cassandra
CASSANDRA_IP=localhost
CASSANDRA_KEYSPACE=bodhi
```
Requires Cassandra running locally.

### Option B: Redis
```bash
PORTAL_SESSION_STORE_TYPE=redis
IGOT_REDIS_HOST=localhost
IGOT_REDIS_PORT=6379
IGOT_REDIS_DB_INDEX=8
```
Requires Redis running locally.

### Option C: In-Memory (Development only)
```bash
PORTAL_SESSION_STORE_TYPE=in-memory
```
No external dependency needed. **Sessions lost on restart.**

---

## 7. Keycloak Authentication Setup

The proxy uses Keycloak for protecting `/protected/v8` and `/proxies/v8` routes.

### Minimum Keycloak Requirements:
1. A Keycloak instance running (can point to remote dev/stage instance)
2. A realm named `sunbird` (or as configured)
3. A client named `portal` configured in that realm
4. The **realm public key** set in `KEYCLOAK_PUBLIC_KEY`

### For Local Development:
- Point `HTTPS_HOST` to a running Keycloak instance (e.g., `https://igot-dev.in`)
- Set `KEYCLOAK_PUBLIC_KEY` to the actual RSA public key from Keycloak realm settings
- Set `NODE_TLS_REJECT_UNAUTHORIZED=0` if using self-signed certs

### Multi-Tenant Setup:
```bash
MULTI_TENANT_KEYCLOAK="igot;https://igot-dev.in/auth;sunbird"
```
Format: `orgName;authServerUrl;realmName` (semicolon-separated)

---

## 8. Cassandra Database Setup

### Using Docker:
```bash
docker run -d \
  --name cassandra \
  -p 9042:9042 \
  cassandra:3.11
```

### Create Keyspace:
```sql
CREATE KEYSPACE IF NOT EXISTS bodhi
WITH replication = {
  'class': 'SimpleStrategy',
  'replication_factor': 1
};
```

### Required Tables:
The session store will auto-create its table. The `form-service` plugin also creates tables for form data.

### Connection Config:
```bash
CASSANDRA_IP=localhost        # or 127.0.0.1
CASSANDRA_KEYSPACE=bodhi
CASSANDRA_AUTH_ENABLED=false  # true if auth is configured
CASSANDRA_USERNAME=           # if auth enabled
CASSANDRA_PASSWORD=           # if auth enabled
```

---

## 9. Redis Setup (Optional)

### Using Docker:
```bash
docker run -d \
  --name redis \
  -p 6379:6379 \
  redis:7
```

### Configuration:
```bash
PORTAL_SESSION_STORE_TYPE=redis
IGOT_REDIS_HOST=localhost
IGOT_REDIS_PORT=6379
IGOT_REDIS_DB_INDEX=8
```

---

## 10. Nodemon Configuration

Two nodemon configs are available:

### `nodemon/nodemon.json` — Pure Local Dev
- All services point to `localhost`
- `CASSANDRA_AUTH_ENABLED: true`
- `IS_DEVELOPMENT: true`
- `NODE_TLS_REJECT_UNAUTHORIZED: 0`

### `nodemon/nodemon-igot-stage.json` — Pointing to Staging
- Services point to staging IP addresses (marked as `IP-ADDR`)
- `HTTPS_HOST: https://igot-dev.in`
- `CASSANDRA_AUTH_ENABLED: false`
- Points to remote Keycloak

> **To customize**: Copy one of these files and update the IP addresses/URLs to match your environment.

---

## 11. Running the Server

### Development Mode (with hot-reload):
```bash
# Using local config
npm run start:nodemon

# Using staging config
npm run start:igot
```

### Production Mode (after build):
```bash
npm run build
npm start
# or
npm run serve
```

### Direct TypeScript execution:
```bash
npx ts-node ./src/index.ts
```

### Server will be available at:
```
http://localhost:3003
```

### Health Check Endpoint:
```
GET http://localhost:3003/healthcheck
```

---

## 12. Build Process

### Build Command:
```bash
npm run build
```

This runs Gulp which:
1. Deletes `./dist/` directory
2. Compiles TypeScript → JavaScript into `./dist/`
3. Copies `package.json` to `dist/`
4. Copies all `.json` files from `src/` to `dist/`
5. Copies `src/assets/` to `dist/assets/`

### Lint:
```bash
npm run lint
```

---

## 13. Port & Network Requirements

### Ports Used by the Proxy:

| Port | Service |
|------|---------|
| **3003** | UI Proxy server (configurable via `PORTAL_PORT`) |

### Ports the Proxy Connects To (Outbound):

| Port | Service |
|------|---------|
| 9042 | Cassandra |
| 6379 | Redis |
| 9200 | Elasticsearch |
| 5903 | Content API |
| 5825 | Java API |
| 5001 | Node API 1 |
| 3009 | Node API 2 |
| 3015 | Node API 3 |
| 5902 | SB Ext API 1 |
| 7001 | SB Ext API 2 |
| 5805 | Notifications |
| 8090 | Telemetry |
| 9090 | Telemetry SB |
| 3007 | Web Host |
| 3011 | Sunbird Backend |
| 443 | Keycloak (HTTPS) |
| 4567 | Discussion Hub (NodeBB) |
| 3002 | Discussion Middleware |

---

## 14. Backend Services the Proxy Depends On

The proxy acts as an API gateway. It forwards requests to ~20+ backend services. For full local development of a specific feature, you need the corresponding backend running.

### Critical (Required for Server to Start):
1. **Cassandra** or **Redis** or use **in-memory** session store
2. **Keycloak** (for JWT validation on protected routes)

### Feature-Specific (Only needed for respective APIs):
| Feature | Backend Service | Port |
|---------|----------------|------|
| Content APIs | content-api-service | 5903 |
| User Management | java-api-base | 5825 |
| Social/Discussion | NodeBB + middleware | 4567, 3002 |
| Search | sb-ext-api | 5902 |
| Notifications | notification-service | 5805 |
| Telemetry | telemetry-service | 8090, 9090 |
| Knowledge Hub | khub-search, khub-graph | 3014, 3016 |
| Network Hub | network-hub-service | 3013 |
| User Profile | user-profile-service | 3004 |
| Workflow | workflow-handler | 5099 |
| Scoring | scoring-service | 7014 |
| FRAC | frac-service | (remote) |

---

## 15. Troubleshooting

### Common Issues:

| Issue | Solution |
|-------|----------|
| `Cannot connect to Cassandra` | Ensure Cassandra is running on the configured IP/port, or switch to `PORTAL_SESSION_STORE_TYPE=in-memory` |
| `KEYCLOAK_PUBLIC_KEY` error | Get the actual public key from Keycloak → Realm Settings → Keys → RSA Public Key |
| `ECONNREFUSED` on startup | Backend services not running; only the ones you're testing need to be up |
| `NODE_TLS_REJECT_UNAUTHORIZED` warning | Set to `0` in dev for self-signed certs |
| npm install fails on git deps | Ensure SSH/HTTPS access to KB-iGOT GitHub repos |
| TypeScript errors | Run `npm run lint` to check; ensure TypeScript 3.5.x |
| Port 3003 already in use | Change `PORTAL_PORT` or kill the existing process |
| Puppeteer fails | Install system libraries listed in Prerequisites section |

### Quick Start (Minimal - Just get it running):

```bash
# 1. Install
npm install

# 2. Set minimal env (in-memory session, skip Cassandra)
export PORTAL_SESSION_STORE_TYPE=in-memory
export NODE_ENV=development
export NODE_TLS_REJECT_UNAUTHORIZED=0
export HTTPS_HOST=https://igot-dev.in
export KEYCLOAK_PUBLIC_KEY=<actual-public-key-from-keycloak>
export PORTAL_PORT=3003

# 3. Run
npx ts-node ./src/index.ts
```

---

## Summary: Absolute Minimum to Start

1. **Node.js >= 14.19.0** installed
2. **`npm install`** successful (needs GitHub access for git dependencies)
3. **Session store** — either Cassandra running, Redis running, or set `PORTAL_SESSION_STORE_TYPE=in-memory`
4. **`KEYCLOAK_PUBLIC_KEY`** — actual RSA public key from your Keycloak instance
5. **`HTTPS_HOST`** — pointing to a valid Keycloak-enabled host
6. Run: `npm run start:nodemon` or `npm run start:igot`
