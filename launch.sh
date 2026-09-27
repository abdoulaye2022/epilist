#!/bin/bash

# Script de démarrage de l'environnement de développement EpiList
# Lance: API PHP (8000), Site web Next.js (3000), tunnel ngrok vers l'API
# Usage: ./launch.sh

set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="$ROOT_DIR/.dev"

API_PORT=8000
WEB_PORT=3000
NGROK_API=http://127.0.0.1:4040

# Domaine ngrok réservé (permanent) : l'URL ne change jamais, ce qui évite de
# devoir remettre à jour app/lib/config/app_config.dart à chaque démarrage.
# Surchargeable : NGROK_DOMAIN=autre.ngrok.app ./launch.sh
NGROK_DOMAIN="${NGROK_DOMAIN:-m2atech.ngrok.app}"

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error()   { echo -e "${RED}✗${NC} $1"; }
info()    { echo -e "${BLUE}▸${NC} $1"; }

mkdir -p "$RUN_DIR"

echo "=========================================="
echo "   Démarrage EpiList - environnement dev"
echo "=========================================="
echo ""

# ------------------------------------------------------------------
# 1. Vérification des prérequis
# ------------------------------------------------------------------
MISSING=0
for CMD in php npm ngrok; do
    if ! command -v "$CMD" >/dev/null 2>&1; then
        error "$CMD n'est pas installé"
        MISSING=1
    fi
done
[ "$MISSING" -eq 1 ] && exit 1

# Fichier .env de l'API (obligatoire, Dotenv::load() échoue sans lui)
if [ ! -f "$ROOT_DIR/api/.env" ]; then
    error "api/.env est manquant — l'API ne peut pas démarrer."
    echo ""
    echo "  Variables requises:"
    echo "    APP_ENV=dev"
    echo "    DB_CONNECTION= DB_HOST= DB_PORT= DB_DATABASE= DB_USERNAME= DB_PASSWORD="
    echo "    JWT_SECRET= JWT_ALGORITHM= JWT_EXPIRATION="
    echo "    JWT_REFRESH_SECRET= JWT_REFRESH_ALGORITHM= JWT_REFRESH_EXPIRATION="
    echo "    FRONTEND_URL= UNSUBSCRIBE_URL="
    echo ""
    exit 1
fi

# APP_ENV doit valoir "dev", sinon index.php applique le basePath de production
if ! grep -qE '^\s*APP_ENV\s*=\s*dev\s*$' "$ROOT_DIR/api/.env"; then
    warning "APP_ENV n'est pas à 'dev' dans api/.env — le basePath de prod sera appliqué"
fi

# ------------------------------------------------------------------
# 2. Vérification des ports
# ------------------------------------------------------------------
port_busy() { lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1; }

for PORT in "$API_PORT" "$WEB_PORT" 4040; do
    if port_busy "$PORT"; then
        error "Le port $PORT est déjà utilisé. Lance ./stop.sh d'abord."
        exit 1
    fi
done

# ------------------------------------------------------------------
# 3. Dépendances
# ------------------------------------------------------------------
# On teste un binaire précis et non le dossier : un node_modules/ ou vendor/
# partiel (install interrompu) existe sans être utilisable.
if [ ! -f "$ROOT_DIR/api/vendor/autoload.php" ]; then
    info "Installation des dépendances PHP (composer install)..."
    (cd "$ROOT_DIR/api" && composer install --no-interaction) || { error "composer install a échoué"; exit 1; }
    success "Dépendances PHP installées"
fi

if [ ! -x "$ROOT_DIR/web/node_modules/.bin/next" ]; then
    info "Installation des dépendances Node (npm install, peut prendre quelques minutes)..."
    (cd "$ROOT_DIR/web" && npm install) || { error "npm install a échoué"; exit 1; }
    if [ ! -x "$ROOT_DIR/web/node_modules/.bin/next" ]; then
        error "next introuvable après npm install (voir web/package.json)"
        exit 1
    fi
    success "Dépendances Node installées"
fi

# ------------------------------------------------------------------
# 4. API PHP sur le port 8000
# ------------------------------------------------------------------
info "Démarrage de l'API sur http://localhost:$API_PORT ..."
# stdin sur /dev/null + disown : sinon les services héritent des descripteurs
# du terminal et le script ne rend jamais la main quand sa sortie est redirigée.
PHP_CLI_SERVER_WORKERS=4 php -S 0.0.0.0:"$API_PORT" -t "$ROOT_DIR/api/public" \
    < /dev/null > "$RUN_DIR/api.log" 2>&1 &
echo $! > "$RUN_DIR/api.pid"
disown

# ------------------------------------------------------------------
# 5. Site web Next.js sur le port 3000
# ------------------------------------------------------------------
info "Démarrage du site web sur http://localhost:$WEB_PORT ..."
# exec dans le sous-shell : $! est directement le PID de npm, pas celui du sous-shell
(cd "$ROOT_DIR/web" && exec npm run dev -- --port "$WEB_PORT") \
    < /dev/null > "$RUN_DIR/web.log" 2>&1 &
echo $! > "$RUN_DIR/web.pid"
disown

# ------------------------------------------------------------------
# 6. Tunnel ngrok vers l'API
# ------------------------------------------------------------------
info "Démarrage du tunnel ngrok ($NGROK_DOMAIN) vers le port $API_PORT ..."
ngrok http --url="https://$NGROK_DOMAIN" "$API_PORT" --log=stdout \
    < /dev/null > "$RUN_DIR/ngrok.log" 2>&1 &
echo $! > "$RUN_DIR/ngrok.pid"
disown

# ------------------------------------------------------------------
# 7. Attente et vérification
# ------------------------------------------------------------------
echo ""
info "Attente du démarrage des services..."

wait_for() { # $1 = url, $2 = label, $3 = timeout
    local i=0
    while [ "$i" -lt "$3" ]; do
        curl -sf -o /dev/null --max-time 2 "$1" && { success "$2 prêt"; return 0; }
        sleep 1
        i=$((i + 1))
    done
    warning "$2 ne répond pas encore (voir $RUN_DIR)"
    return 1
}

wait_for "http://localhost:$API_PORT/test" "API PHP" 15
wait_for "http://localhost:$WEB_PORT" "Site web Next.js" 60

# Récupération de l'URL publique ngrok
NGROK_URL=""
for _ in $(seq 1 20); do
    NGROK_URL=$(curl -sf --max-time 2 "$NGROK_API/api/tunnels" 2>/dev/null \
        | grep -oE '"public_url":"https://[^"]+"' | head -1 | cut -d'"' -f4)
    [ -n "$NGROK_URL" ] && break
    sleep 1
done

if [ -n "$NGROK_URL" ]; then
    echo "$NGROK_URL" > "$RUN_DIR/ngrok.url"
    if [ "$NGROK_URL" = "https://$NGROK_DOMAIN" ]; then
        success "Tunnel ngrok prêt sur le domaine réservé"
    else
        warning "ngrok a démarré sur $NGROK_URL au lieu de https://$NGROK_DOMAIN"
    fi
else
    error "Tunnel ngrok indisponible — dernières lignes du log :"
    grep -iE "err|fail" "$RUN_DIR/ngrok.log" 2>/dev/null | tail -3 \
        || tail -3 "$RUN_DIR/ngrok.log" 2>/dev/null
    warning "Le domaine $NGROK_DOMAIN est peut-être déjà utilisé par une autre session."
fi

# ------------------------------------------------------------------
# 8. Récapitulatif
# ------------------------------------------------------------------
echo ""
echo "=========================================="
echo "   Services démarrés"
echo "=========================================="
echo -e "  API PHP        ${GREEN}http://localhost:$API_PORT${NC}"
echo -e "  Site web       ${GREEN}http://localhost:$WEB_PORT${NC}"
if [ -n "$NGROK_URL" ]; then
    echo -e "  Tunnel ngrok   ${GREEN}$NGROK_URL${NC}  →  port $API_PORT"
fi
echo -e "  Interface ngrok $NGROK_API"
echo ""
echo "  Logs   : $RUN_DIR/{api,web,ngrok}.log"
echo "  Arrêt  : ./stop.sh"
echo ""

echo "  Pour l'app Flutter, dans app/lib/config/app_config.dart :"
echo ""
echo "    Simulateur iOS    : http://localhost:$API_PORT"
echo "    Emulateur Android : http://10.0.2.2:$API_PORT"
if [ -n "$NGROK_URL" ]; then
    echo "    Appareil réel     : $NGROK_URL"
fi
echo ""
