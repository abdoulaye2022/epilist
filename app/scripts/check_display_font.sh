#!/usr/bin/env bash
# Garde-fou de la planche « Version B » : deux fontes, et deux seulement.
#
# Atkinson Hyperlegible pour le texte courant — dessinee pour la basse
# vision, elle distingue I l 1 et O 0 la ou les fontes d'interface les
# confondent. Sora pour les titres.
#
# Le theme les pose. Mais un ecran qui ecrit son propre TextStyle repart
# de la fonte par defaut : 54 titres etaient ainsi rendus dans la fonte
# du systeme, sans que rien ne le signale.
#
# Un titre, ici : au moins 20 points ET gras. En dessous, la limite
# entre un titre et une etiquette forte n'est pas tranchee.
set -uo pipefail
cd "$(dirname "$0")/.."

n=$(python3 - <<'PY'
import re, pathlib
STYLE = re.compile(r'TextStyle\((?:[^()]|\([^()]*\))*\)')
n = 0
for p in pathlib.Path('lib').rglob('*.dart'):
    if p.parts[1] == 'theme':
        continue
    for m in STYLE.finditer(p.read_text(encoding='utf-8')):
        b = m.group(0)
        t = re.search(r'fontSize: ([0-9.]+)', b)
        g = re.search(r'fontWeight: FontWeight\.(w[789]00|bold)', b)
        if t and g and float(t.group(1)) >= 20 and 'fontFamily' not in b:
            n += 1
            if n <= 10:
                print(f'{p}: {b[:70]}...', file=__import__('sys').stderr)
print(n)
PY
)
echo "Titres sans fonte d'affichage hors lib/theme : $n (plafond 0)"
[ "$n" -eq 0 ]
