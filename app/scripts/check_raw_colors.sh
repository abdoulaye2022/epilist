#!/bin/bash
# Cliquet sur les couleurs Material brutes.
#
# Le theme (lib/theme/app_theme.dart) est la seule source du look :
# deux palettes completes (clair, sombre), des jetons nommes, trois
# rayons, cinq espacements. Une couleur ecrite a la main dans un ecran
# echappe a tout cela — c'est exactement ce qui a tenu le mode sombre
# hors d'atteinte pendant toute la vie du projet : le theme ne peut pas
# corriger ce qu'il ne voit pas.
#
# Le compte est tombe de 791 a 0 le 2026-10-16. Le plafond est donc 0 :
# ce script n'est plus un cliquet qui descend, c'est une porte fermee.
#
# Le script compte DEUX choses, car une couleur echappe au theme de deux
# facons : par son nom Material (`Colors.teal`) et par son code
# hexadecimal (`Color(0xFF4CAF50)`). Le second passait inapercu : il en
# restait 61 apres la chasse au premier, dont les quarante-quatre
# couleurs du choix de categorie — cyan, magenta, gris anthracite — la
# ou la planche n'en admet que sept.
#
# Trois exceptions, et trois seulement :
#   - `Colors.transparent` : l'absence de couleur, identique dans les
#     deux modes, et l'idiome Flutter attendu. Lui donner un jeton
#     n'ajouterait que de l'indirection.
#   - lib/theme/ lui-meme, qui a le droit de nommer des couleurs.
#   - le bleu #4285F4 du bouton « Continuer avec Google ». C'est une
#     marque tierce, pas une couleur d'interface : la planche admet
#     explicitement les couleurs de marque (« logos des magasins dans
#     leurs couleurs de marque »), et Google impose les siennes.
#
# Attention au comptage : exiger un caractere non identifiant avant
# `Colors` ecarte `AppColors.primary` ET `_predefinedColors.length`.
# Sans cela, le premier audit avait annonce 2 182 au lieu de 791.
set -euo pipefail

cd "$(dirname "$0")/.."

PLAFOND=${PLAFOND:-0}
MOTIF='(?<![A-Za-z0-9_])Colors\.(?!transparent\b)[a-zA-Z][a-zA-Z0-9]*'

par_fichier() {
  while IFS= read -r f; do
    n=$(perl -ne "print \"\$&\n\" while /$MOTIF/g" "$f" | wc -l | tr -d ' ')
    h=$(grep -oE 'Color\(0x[0-9A-Fa-f]{8}\)' "$f" | grep -vc '0xFF4285F4' || true)
    n=$((n + h))
    [ "$n" != "0" ] && echo "$n $f"
  done < <(find lib -name '*.dart' -not -path 'lib/theme/*')
  # Sans ce return, le dernier fichier sans couleur brute fait sortir la
  # fonction en erreur (le test echoue) et `set -e` tue tout le script.
  return 0
}

TOTAL=$(par_fichier | awk '{s+=$1} END {print s+0}')

echo "Couleurs brutes hors lib/theme (nom Material + hexadecimal) : $TOTAL (plafond $PLAFOND)"

if [ "$TOTAL" -gt "$PLAFOND" ]; then
  echo
  echo "ECHEC : $((TOTAL - PLAFOND)) de plus que le plafond."
  echo "Utilisez les jetons de lib/theme/app_theme.dart (AppColors.*,"
  echo "AppTint.fill/line/ink pour une couleur recue en parametre)."
  echo
  echo "Fichiers en cause :"
  par_fichier | sort -rn | head -10
  exit 1
fi

if [ "$TOTAL" -lt "$PLAFOND" ]; then
  echo
  echo "Le plafond peut descendre a $TOTAL (PLAFOND dans ce script)."
fi
