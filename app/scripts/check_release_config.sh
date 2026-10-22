#!/usr/bin/env bash
# Garde-fou de la configuration : une build de RELEASE doit viser la
# production.
#
# `baseUrl` est une CONSTANTE compilee : elle est figee dans le binaire.
# Une build partie avec l'URL de developpement ne joindra rien chez les
# gens qui l'installent, et rien dans l'application ne le dira — elle
# affichera des erreurs reseau, c'est tout.
#
# Le piege est reel : pour tester sur un appareil, on bascule sur ngrok
# ou sur le port local, et ce changement n'est PAS commite. Il reste
# donc dans la copie de travail, exactement la ou la build le prendra.
#
# A lancer avant `flutter build apk --release` / `ipa`.
#
# Avec --fix, la ligne active est remise sur la production.
set -uo pipefail
cd "$(dirname "$0")/.."

FICHIER=lib/config/app_config.dart
PROD='https://m2atodev.com/api.epilist/public'

# La ligne ACTIVE : celle qui n'est pas commentee.
active=$(grep -E "^\s*static const String baseUrl" "$FICHIER" | head -1)
url=$(printf '%s' "$active" | sed -E "s/.*'([^']*)'.*/\1/")

if [ "$url" = "$PROD" ]; then
  echo "Configuration de release : production ($url) — ok"
  exit 0
fi

echo "ECHEC : l'application vise « $url », pas la production."
echo

if [ "${1:-}" = "--fix" ]; then
  # Commenter la ligne active, decommenter celle de production.
  perl -pi -e "s{^(\s*)(static const String baseUrl = '(?!\Q$PROD\E)[^']*';)}{\$1// \$2}" "$FICHIER"
  perl -pi -e "s{^(\s*)// (static const String baseUrl = '\Q$PROD\E';)}{\$1\$2}" "$FICHIER"
  active=$(grep -E "^\s*static const String baseUrl" "$FICHIER" | head -1)
  url=$(printf '%s' "$active" | sed -E "s/.*'([^']*)'.*/\1/")
  if [ "$url" = "$PROD" ]; then
    echo "Remis sur la production. Relancez l'application : baseUrl est"
    echo "une constante COMPILEE, un rechargement a chaud ne la change pas."
    exit 0
  fi
  echo "Le remplacement automatique a echoue : editez $FICHIER a la main."
  exit 1
fi

echo "Pour corriger :  bash scripts/check_release_config.sh --fix"
echo "Pour revenir au developpement ensuite, decommentez la ligne voulue"
echo "dans $FICHIER."
exit 1
