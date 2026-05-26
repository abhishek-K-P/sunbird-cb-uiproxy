#!/bin/bash
# Dev environment startup script for sunbird-cb-uiproxy
# Starts SSH tunnels, Redis, verifies Cassandra, and runs the proxy server.

set -e

SSH_USER="abhishekkoira"
SSH_HOST="10.175.2.83"
SSH_PORT="9822"

CASSANDRA_REMOTE="10.175.2.36:9042"
SYSTEM_API_REMOTE="10.175.2.37:8080"
JENKINS_REMOTE="10.175.2.88:8080"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- 1. Start SSH Tunnels ---
start_tunnel() {
    local local_port=$1
    local remote=$2
    local label=$3

    if ss -tlnp | grep -q ":${local_port} "; then
        log_warn "${label} tunnel already running on port ${local_port}"
    else
        log_info "Starting ${label} tunnel (localhost:${local_port} -> ${remote})..."
        ssh -f -N -L "0.0.0.0:${local_port}:${remote}" "${SSH_USER}@${SSH_HOST}" -p "${SSH_PORT}"
        sleep 1
        if ss -tlnp | grep -q ":${local_port} "; then
            log_info "${label} tunnel started successfully"
        else
            log_error "Failed to start ${label} tunnel"
            return 1
        fi
    fi
}

echo "========================================="
echo "  Starting Dev Environment"
echo "========================================="
echo ""

# SSH Tunnels
log_info "Setting up SSH tunnels..."
start_tunnel 9042 "$CASSANDRA_REMOTE" "Cassandra"
start_tunnel 8080 "$SYSTEM_API_REMOTE" "System API"
start_tunnel 8880 "$JENKINS_REMOTE" "Jenkins"
echo ""

# --- 2. Start Redis ---
log_info "Starting Redis..."
if sudo docker ps --format '{{.Names}}' | grep -q '^redis$'; then
    log_warn "Redis container already running"
else
    if sudo docker ps -a --format '{{.Names}}' | grep -q '^redis$'; then
        sudo docker start redis
    else
        sudo docker run -d --name redis -p 6379:6379 redis:7
    fi
    log_info "Redis started"
fi
echo ""

# --- 3. Verify Cassandra setup ---
log_info "Verifying Cassandra keyspace and sessions table..."
CQLSH_CMD="sudo docker run --rm --network host cassandra:3.11 cqlsh localhost 9042"

# Check portal keyspace
KEYSPACE_CHECK=$($CQLSH_CMD -e "SELECT keyspace_name FROM system_schema.keyspaces WHERE keyspace_name='portal';" 2>/dev/null | grep -c "portal" || true)
if [[ "$KEYSPACE_CHECK" -eq 0 ]]; then
    log_warn "Portal keyspace not found. Creating..."
    $CQLSH_CMD -e "CREATE KEYSPACE portal WITH replication = {'class': 'SimpleStrategy', 'replication_factor': '1'} AND durable_writes = true;"
    log_info "Portal keyspace created"
else
    log_info "Portal keyspace exists"
fi

# Check sessions table
TABLE_CHECK=$($CQLSH_CMD -e "SELECT table_name FROM system_schema.tables WHERE keyspace_name='portal' AND table_name='sessions';" 2>/dev/null | grep -c "sessions" || true)
if [[ "$TABLE_CHECK" -eq 0 ]]; then
    log_warn "Sessions table not found. Creating..."
    $CQLSH_CMD -e "CREATE TABLE portal.sessions (sid text PRIMARY KEY, expires timestamp, session text);"
    log_info "Sessions table created"
else
    log_info "Sessions table exists"
fi

# Show session count
SESSION_COUNT=$($CQLSH_CMD -e "SELECT count(*) FROM portal.sessions;" 2>/dev/null | grep -oP '^\s+\K\d+' || echo "0")
log_info "Current sessions in Cassandra: ${SESSION_COUNT}"
echo ""

# --- 4. Start UI Proxy ---
echo "========================================="
log_info "Starting UI Proxy server..."
echo "========================================="
echo ""
npm run start:dev
