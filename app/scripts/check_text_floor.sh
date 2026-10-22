#!/usr/bin/env bash
# Garde-fou de la planche « Version B » : « Textes agrandis ».
#
# Le theme pose deja le corps a 17. Ce sont les `fontSize:` ecrits a la
# main, ecran par ecran, qui le defont : il y en avait 461 entre 8 et 14
# points avant la refonte. 14,5 est le plancher — en dessous, une
# legende cesse d'etre lisible pour qui a une basse vision, et c'est
# precisement le public de cette planche.
#
# Au-dessus du plancher, les tailles restent libres : la hierarchie se
# choisit ecran par ecran.
set -uo pipefail
cd "$(dirname "$0")/.."

# lib/theme definit le theme lui-meme : ses tailles SONT la reference.
fautes=$(grep -rnE "fontSize: *([0-9]|1[0-3])(\.[0-9]+)?[,) ]" lib \
         | grep -v "^lib/theme/" \
         | grep -vE "fontSize: *14\.5")
fautes="$fautes$(grep -rnE "fontSize: *14(\.[0-4])?[,) ]" lib | grep -v '^lib/theme/')"

n=$(printf '%s' "$fautes" | grep -c . || true)
if [ "$n" -gt 0 ]; then
  printf '%s\n' "$fautes" | grep . | head -20
fi
echo "Textes sous le plancher de 14,5 : $n (plafond 0)"
[ "$n" -eq 0 ]
