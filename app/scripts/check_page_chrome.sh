#!/usr/bin/env bash
# Garde-fou de la planche « Version B » :
#
#   « Le menu latéral est joignable de PARTOUT : bouton menu en haut à
#     gauche du téléphone sur les autres écrans. »
#   « La barre du bas est strictement la MÊME sur toutes les pages. »
#
# Chaque écran de l'application connectée doit donc porter les trois :
# AppTopBar (retour + menu + titre Sora), AppDrawer, AppPageBottomBar.
#
# Les exceptions sont NOMMÉES ici, chacune avec sa raison. Ajouter un
# écran sans l'un des trois fait échouer ce script — c'est le but.
set -uo pipefail
cd "$(dirname "$0")/.."

# Avant la connexion : aucune coquille n'est montée, et toucher un
# onglet refermerait la pile sur rien.
AVANT_CONNEXION="welcome_screen login_screen signup_screen \
email_verification_screen two_factor_screen password_change_screen \
share_invitation_screen privacy_policy_screen terms_of_service"

# Écrans de tâche plein écran : une barre de navigation par-dessus un
# viseur d'appareil photo, ou sous une barre d'actions de validation,
# détournerait du geste en cours.
PLEIN_ECRAN="barcode_scanner_screen receipt_validation_screen"

# La coquille EST la barre ; l'accueil et la réussite n'ont pas d'en-tête
# par choix de la planche (dégradé jusqu'en haut, page de félicitations).
PARTICULIERS="main_shell home_screen shopping_success_screen \
account_deletion_status_widget"

# Les cinq onglets : la coquille leur fournit barre et tiroir.
ONGLETS="shopping_list_screen pre_shopping_screen price_alerts_screen \
sections_screen"

manques=0
for f in lib/screens/*.dart; do
  nom=$(basename "$f" .dart)
  case " $AVANT_CONNEXION $PLEIN_ECRAN $PARTICULIERS " in *" $nom "*) continue;; esac
  grep -q "Scaffold(" "$f" || continue

  # Soit l'ecran construit l'en-tete partage lui-meme, soit il passe par
  # un en-tete a lui (ListDetailAppBar, ShoppingListAppBar...) : celui-la
  # doit alors etre bati sur AppTopBar.
  if ! grep -q "AppTopBar(" "$f"; then
    propre=$(grep -oE "appBar: (const )?[A-Z][A-Za-z]*AppBar\(" "$f" \
             | head -1 | grep -oE "[A-Z][A-Za-z]*AppBar")
    if [ -z "$propre" ] || ! grep -rqlE "class $propre\b" lib \
       || ! grep -rl "class $propre" lib | xargs grep -ql "AppTopBar("; then
      echo "MANQUE en-tete partage : $nom"
      manques=$((manques + 1))
    fi
  fi
  case " $ONGLETS " in *" $nom "*) continue;; esac
  if ! grep -q "AppPageBottomBar(" "$f"; then
    echo "MANQUE barre du bas : $nom"
    manques=$((manques + 1))
  fi
  if ! grep -q "drawer: const AppDrawer()" "$f"; then
    echo "MANQUE tiroir : $nom"
    manques=$((manques + 1))
  fi
done

echo "Ecrans sans l'habillage de la planche : $manques (plafond 0)"
[ "$manques" -eq 0 ]
