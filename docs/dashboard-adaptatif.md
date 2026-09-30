# Dashboard adaptatif (§45)

Livré le 2026-09-30. Prérequis : Phases 1-6. **Aucune migration** :
tout s'appuie sur l'existant (le brief §28, l'inventaire §21,
l'attribution §10 posée en Phase 2).

## Principe

L'accueil s'adapte au TYPE de l'espace actif :

- **Personnel** : l'expérience actuelle, inchangée — aucun bruit.
- **Espace partagé** : une carte de bord apparaît sous l'accueil,
  alimentée par `/assistant/pre-shopping` (une requête) :

| Type | Contenu de la carte |
|---|---|
| Foyer | à racheter probablement, ruptures/sous seuil, raccourci activité |
| Restaurant / organisation | demandes d'achat en attente (en premier), **stock critique** (produits sous le seuil, nommés), à racheter, fournisseurs, activité |

Chaque ligne navigue vers l'écran correspondant ; la carte se
recharge au retour et au changement d'espace.

## Attribution visible (report Phase 2, §10)

Dans les listes d'un espace partagé, chaque article porte maintenant
« Ajouté par X » (ou « Acheté par Y » une fois coché) :

- API : `GET /shopping-lists/{id}/items` joint les noms UNIQUEMENT
  pour les listes d'espaces partagés — une liste personnelle n'expose
  aucun champ d'attribution (vérifié E2E).
- App : puce discrète dans la carte d'article ; `copyWith` préserve
  les noms (leçon du bug d'avatar).

## Seuils éditables (report Phase 3, §21)

Écran inventaire :

- ligne « quantité / seuil » sous le produit, en rouge avec la mention
  « sous le seuil » quand `below_min` ;
- menu ⋮ → « Quantité et seuils… » : quantité, unité, seuil d'alerte,
  quantité de réappro (l'API existante fait le reste).

## Bug corrigé au passage

`POST /inventory/status` réécrivait à NULL la quantité et les seuils
dès qu'ils n'étaient pas renvoyés : un simple tap sur une pastille de
statut effaçait les seuils du restaurant. Désormais **les champs
absents du payload ne sont pas touchés** (une clé envoyée à null
efface volontairement). Vérifié E2E : changement de statut → quantité,
unité et deux seuils intacts.

## Sécurité vérifiée (E2E 161/161)

Attribution présente sur les articles du foyer (« ajouté par » ≠
« acheté par ») ; aucun champ d'attribution sur une liste personnelle ;
seuils intacts après changement de statut.

## Chantier espaces : état final

Les 6 phases + §45 sont livrées. Reports restants, documentés :

- Prix par fournisseur (§22) : attend l'enregistrement du prix payé à
  la clôture d'une demande d'achat.
- Action « Ajouter à la liste » depuis la notification push d'alerte
  de prix.
- Notification planifiée « avant les courses » (opt-in).
- Région communautaire : enrichissement du profil selon l'usage.
