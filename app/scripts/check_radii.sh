#!/usr/bin/env bash
# Garde-fou de la planche « Version B » : « coins tres arrondis ».
#
# Le theme nomme quatre rayons — 12 (sm), 18 (md), 26 (lg), 999
# (gelule) — et c'est tout le vocabulaire de l'application. Il y avait
# 528 rayons ecrits en chiffres, ecran par ecran : 110 a 8 points, 232 a
# 12, trois a 2. Un coin a 2 points n'est pas « tres arrondi », et dix
# valeurs differentes dans une meme page ne font pas une forme.
set -uo pipefail
cd "$(dirname "$0")/.."

fautes=$(grep -rnE "(BorderRadius|Radius)\.circular\([0-9]" lib | grep -v '^lib/theme/')
n=$(printf '%s' "$fautes" | grep -c . || true)
if [ "$n" -gt 0 ]; then
  printf '%s\n' "$fautes" | grep . | head -20
  echo
  echo "Utilisez AppRadius.sm / md / lg / pill (lib/theme/app_theme.dart)."
fi
echo "Rayons ecrits en chiffres hors lib/theme : $n (plafond 0)"
[ "$n" -eq 0 ]
