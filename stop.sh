#!/bin/bash

# Script d'arrêt de l'environnement de développement EpiList
# Arrête: API PHP (8000), Site web Next.js (3000), tunnel ngrok
# Usage: ./stop.sh

set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="$ROOT_DIR/.dev"

API_PORT=8000
WEB_PORT=3000
NGROK_PORT=4040

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
info()    { echo -e "${BLUE}▸${NC} $1"; }

echo "=========================================="
echo "   Arrêt EpiList - environnement dev"
echo "=========================================="
echo ""

STOPPED=0

# Arrêt propre (SIGTERM) puis forcé (SIGKILL) d'un PID et de ses enfants
kill_tree() {
    local PID="$1"
    kill -0 "$PID" 2>/dev/null || return 1

    # Enfants d'abord (npm run dev lance next-server dans un sous-processus,
    # php -S avec PHP_CLI_SERVER_WORKERS lance des workers)
    local CHILDREN
    CHILDREN=$(pgrep -P "$PID" 2>/dev/null || true)

    kill -TERM "$PID" 2>/dev/null
    for CHILD in $CHILDREN; do
        kill -TERM "$CHILD" 2>/dev/null
    done

    for _ in $(seq 1 10); do
        kill -0 "$PID" 2>/dev/null || break
        sleep 0.5
    done

    if kill -0 "$PID" 2>/dev/null; then
        kill -9 "$PID" 2>/dev/null
    fi
    for CHILD in $CHILDREN; do
        kill -9 "$CHILD" 2>/dev/null
    done
    return 0
}

# 1. Arrêt via les fichiers PID écrits par launch.sh
stop_by_pidfile() { # $1 = nom du service, $2 = fichier pid
    local NAME="$1" PIDFILE="$RUN_DIR/$2"
    [ -f "$PIDFILE" ] || return 1

    local PID
    PID=$(cat "$PIDFILE" 2>/dev/null)
    rm -f "$PIDFILE"

    if [ -n "$PID" ] && kill_tree "$PID"; then
        success "$NAME arrêté (PID $PID)"
        STOPPED=$((STOPPED + 1))
        return 0
    fi
    return 1
}

stop_by_pidfile "API PHP" "api.pid"
stop_by_pidfile "Site web Next.js" "web.pid"
stop_by_pidfile "Tunnel ngrok" "ngrok.pid"

# 2. Filet de sécurité: tout processus restant sur les ports concernés
stop_by_port() { # $1 = nom du service, $2 = port
    local NAME="$1" PORT="$2" PIDS
    PIDS=$(lsof -nP -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null || true)
    [ -z "$PIDS" ] && return 1

    for PID in $PIDS; do
        kill_tree "$PID" && {
            success "$NAME arrêté sur le port $PORT (PID $PID)"
            STOPPED=$((STOPPED + 1))
        }
    done
}

stop_by_port "API PHP" "$API_PORT"
stop_by_port "Site web Next.js" "$WEB_PORT"
stop_by_port "Tunnel ngrok" "$NGROK_PORT"

# 3. Nettoyage de l'URL ngrok mémorisée
rm -f "$RUN_DIR/ngrok.url"

echo ""
if [ "$STOPPED" -eq 0 ]; then
    warning "Aucun service en cours d'exécution"
else
    info "$STOPPED service(s) arrêté(s)"
fi

# Vérification finale
REMAINING=""
for PORT in "$API_PORT" "$WEB_PORT" "$NGROK_PORT"; do
    lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1 && REMAINING="$REMAINING $PORT"
done

if [ -n "$REMAINING" ]; then
    warning "Ports encore occupés :$REMAINING"
else
    success "Tous les ports sont libres (${API_PORT}, ${WEB_PORT}, ${NGROK_PORT})"
fi

echo ""
echo "  Les logs restent disponibles dans $RUN_DIR/"
echo ""
