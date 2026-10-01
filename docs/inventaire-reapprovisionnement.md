# L'achat remet le produit « à la maison »

Livré le 2026-10-01. Aucune migration.

## Le manque

L'inventaire ne se mettait à jour que **manuellement** : les trois
pastilles, l'ajout d'un produit, ou la réponse « J'en ai encore » à une
suggestion. Ni le cochage d'un article, ni l'import d'une facture n'y
touchaient.

Conséquence : un produit marqué « Terminé », puis acheté et coché dans
la liste, **restait affiché « Terminé »** jusqu'à correction à la main.
La liaison n'existait que dans un sens — l'inventaire proposait d'ajouter
à la liste, mais la liste ne lui répondait jamais.

## Ce qui se passe maintenant

Cocher un article comme acheté repasse le produit correspondant à
**« À la maison »**, au même endroit que l'enregistrement de
l'historique d'achat (`ListItemController::recordPurchaseHistory`).

Deux garde-fous délibérés :

1. **Seuls les produits DÉJÀ suivis sont mis à jour.** L'inventaire est
   une liste choisie par l'utilisateur, pas le journal de tout ce qu'il
   a acheté. Acheter un produit absent de l'inventaire n'y crée rien.
2. **Les quantités ne sont pas touchées.** Une liste compte des
   articles, l'inventaire des kilos ou des litres : additionner les deux
   fabriquerait des chiffres faux. Les quantités et les seuils des
   espaces professionnels restent donc manuels.

La mise à jour porte `source = 'purchase'` (et non `manual`) : une
action manuelle **postérieure** reste prioritaire, et le moteur de
prédiction continue de raisonner sur l'historique — qui vient
justement d'enregistrer cet achat.

Échec silencieux : un problème ici ne fait jamais rater l'achat.

## Vérifié

Scénario complet sur l'API locale : produit marqué « Terminé » → ajouté
→ coché → **repassé « à la maison » avec `source=purchase`**. Produit
non suivi : **aucune entrée créée**. Trois vérifications ajoutées au
harnais E2E (dont la priorité du choix manuel postérieur).
