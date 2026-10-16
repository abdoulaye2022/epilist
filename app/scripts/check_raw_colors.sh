#!/bin/bash
# Cliquet sur les couleurs Material brutes.
#
# Le theme (lib/theme/app_theme.dart) est un bon systeme : seize couleurs
# nommees, trois rayons, cinq espacements. Mais des centaines de
# `Colors.<nom>` vivent encore hors de lui, et un theme ne peut pas
# corriger ce qu'il ne voit pas : c'est la seule raison pour laquelle le
# mode sombre n'existe pas.
#
# Ce script ne corrige rien. Il empeche le nombre de REMONTER, et dit
# quels fichiers payer d'abord. Baisser le plafond a chaque fichier
# migre fait le reste.
#
# Attention au comptage : `Colors\.` attrape aussi `AppColors.` — c'est
# ce qui avait produit un faux chiffre de 2 182 dans le premier audit.
# D'ou le (?<!App).
set -euo pipefail

cd "$(dirname "$0")/.."

PLAFOND=${PLAFOND:-791}
MOTIF='(?<!App)Colors\.[a-zA-Z][a-zA-Z0-9]*'

par_fichier() {
  while IFS= read -r f; do
    n=$(perl -ne "print \"\$&\n\" while /$MOTIF/g" "$f" | wc -l | tr -d ' ')
    [ "$n" != "0" ] && echo "$n $f"
  done < <(find lib -name '*.dart' -not -path 'lib/theme/*')
}

TOTAL=$(par_fichier | awk '{s+=$1} END {print s+0}')

echo "Couleurs Material brutes hors lib/theme : $TOTAL (plafond $PLAFOND)"

if [ "$TOTAL" -gt "$PLAFOND" ]; then
  echo
  echo "ECHEC : $((TOTAL - PLAFOND)) de plus que le plafond."
  echo "Utilisez les constantes de lib/theme/app_theme.dart (AppColors.*)."
  echo
  echo "Fichiers les plus charges :"
  par_fichier | sort -rn | head -10
  exit 1
fi

if [ "$TOTAL" -lt "$PLAFOND" ]; then
  echo
  echo "Le plafond peut descendre a $TOTAL (PLAFOND dans ce script)."
fi
