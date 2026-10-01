#!/bin/bash

# Script d'arrêt de l'environnement de développement EpiList
# Arrête: API PHP (8001), Site web Next.js (3001), tunnel ngrok
# Usage: ./stop.sh

set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="$ROOT_DIR/.dev"

API_PORT=8001
WEB_PORT=3001

# Inspecteur ngrok : le port réellement utilisé est écrit par launch.sh.
# On ne balaie JAMAIS 4040 en dur : c'est souvent l'agent ngrok d'un AUTRE
# projet, et le tuer couperait son tunnel.
NGROK_PORT=$(cat "$RUN_DIR/ngrok.web_port" 2>/dev/null || echo "")

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

# Ce PID appartient-il BIEN à ce projet ? Un processus est reconnu comme
# nôtre si sa ligne de commande ou son répertoire courant pointe sous
# $ROOT_DIR. Garde-fou indispensable : stop.sh ne doit jamais toucher au
# serveur d'un AUTRE projet qui occuperait un de ces ports, ni à un
# processus qui aurait recyclé un PID écrit dans un fichier périmé.
belongs_to_project() { # $1 = pid
    local PID="$1" CMD CWD
    CMD=$(ps -o command= -p "$PID" 2>/dev/null || true)
    [ -z "$CMD" ] && return 1
    case "$CMD" in *"$ROOT_DIR"*) return 0 ;; esac

    CWD=$(lsof -a -p "$PID" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p' | head -1)
    case "$CWD" in "$ROOT_DIR"*) return 0 ;; esac
    return 1
}

# Décrit brièvement un processus étranger qu'on laisse tourner
describe_pid() { # $1 = pid
    ps -o comm= -p "$1" 2>/dev/null | sed 's#.*/##' || echo "inconnu"
}

# 1. Arrêt via les fichiers PID écrits par launch.sh
stop_by_pidfile() { # $1 = nom du service, $2 = fichier pid
    local NAME="$1" PIDFILE="$RUN_DIR/$2"
    [ -f "$PIDFILE" ] || return 1

    local PID
    PID=$(cat "$PIDFILE" 2>/dev/null)
    rm -f "$PIDFILE"
    [ -n "$PID" ] || return 1

    # PID périmé puis recyclé par un autre programme : on ne tue rien.
    if ! belongs_to_project "$PID"; then
        kill -0 "$PID" 2>/dev/null && warning "$NAME : PID $PID n'est plus à nous ($(describe_pid "$PID")) — laissé intact"
        return 1
    fi

    if kill_tree "$PID"; then
        success "$NAME arrêté (PID $PID)"
        STOPPED=$((STOPPED + 1))
        return 0
    fi
    return 1
}

stop_by_pidfile "API PHP" "api.pid"
stop_by_pidfile "Site web Next.js" "web.pid"
stop_by_pidfile "Tunnel ngrok" "ngrok.pid"

# 2. Filet de sécurité: processus de CE projet restés sur nos ports
#    (fichier PID perdu). Tout processus étranger est laissé tranquille.
stop_by_port() { # $1 = nom du service, $2 = port
    local NAME="$1" PORT="$2" PIDS
    PIDS=$(lsof -nP -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null || true)
    [ -z "$PIDS" ] && return 1

    for PID in $PIDS; do
        if ! belongs_to_project "$PID"; then
            warning "Port $PORT occupé par $(describe_pid "$PID") (PID $PID) — autre projet, laissé intact"
            continue
        fi
        kill_tree "$PID" && {
            success "$NAME arrêté sur le port $PORT (PID $PID)"
            STOPPED=$((STOPPED + 1))
        }
    done
}

stop_by_port "API PHP" "$API_PORT"
stop_by_port "Site web Next.js" "$WEB_PORT"
[ -n "$NGROK_PORT" ] && stop_by_port "Tunnel ngrok" "$NGROK_PORT"
rm -f "$RUN_DIR/ngrok.web_port" "$RUN_DIR/ngrok-epilist.yml"

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
for PORT in "$API_PORT" "$WEB_PORT" ${NGROK_PORT:+$NGROK_PORT}; do
    lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1 && REMAINING="$REMAINING $PORT"
done

if [ -n "$REMAINING" ]; then
    warning "Ports encore occupés :$REMAINING"
    warning "(normal s'ils appartiennent à un autre projet — stop.sh n'y touche pas)"
else
    success "Tous les ports sont libres (${API_PORT}, ${WEB_PORT}${NGROK_PORT:+, $NGROK_PORT})"
fi

echo ""
echo "  Les logs restent disponibles dans $RUN_DIR/"
echo ""
