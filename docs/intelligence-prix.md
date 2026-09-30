# Intelligence prix par espace (Phase 4)

Livré le 2026-09-30. Prérequis : Phases 1-3. Migration :
`api/migrations/add_spaces_phase4.sql` (idempotente).

> ⚠️ **Production** : `purchase_history` est la table la plus volumineuse.
> Faire une **sauvegarde SQL** avant d'exécuter la migration, puis
> l'exécuter hors heure de pointe. Le backfill est un `UPDATE + JOIN`
> unique, sans suppression.

## Modèle d'observation (§23)

Chaque achat (article coché avec prix, ligne de reçu importée) reste une
ligne de `purchase_history` — jamais un remplacement — et porte
maintenant `space_id` en plus de `user_id` :

- `space_id` = l'espace **de la liste** d'origine (pas l'en-tête client,
  §40) ; `user_id` = qui a acheté (traçabilité).
- Backfill : tout l'historique existant est rattaché à l'espace
  personnel de son auteur.
- Provenance conservée : `source`, `receipt_id`, `store_id`, date.
- Le vocabulaire reste prudent : « prix observé », jamais « prix
  officiel ».

## Isolation (§34) et portées de lecture

- `GET /price-history` : périmètre = **espace actif** (X-Space-Id).
  Membre du foyer → historique du foyer ; sans en-tête → personnel
  strict (`space_id` personnel ou NULL) : les observations du foyer
  portent aussi le `user_id` de l'acheteur, elles sont **exclues** du
  contexte personnel. Vérifié E2E.
- Comparateur de magasins et optimiseur : périmètre = **espace de la
  liste** comparée.
- `resolve-labels` (validation de scan) : alias et historique de
  l'espace actif — un membre du foyer valide « LAIT NAT 2% » une fois,
  tous en profitent (`product_aliases.space_id`).
- Import de reçu : magasin résolu/créé dans l'espace de la liste ; la
  **signature anti-doublon est par espace** (deux membres qui importent
  le même reçu → un seul historique).

## Fraîcheur (§24)

Logique 14/30/90 existante réutilisée et exposée partout :
`fresh` (≤ 14 j), `acceptable` (≤ 30 j), `old` (≤ 90 j), `stale`.
`price-history` renvoie `age_days` + `freshness` par observation et
`last_freshness` dans les stats.

## Prix cible (§25) et suggestion (§26)

Table `price_alerts` par espace : produit (nom normalisé), magasin
optionnel (NULL = tous), `target_price`, actif/inactif, créateur.

- `GET /price-alerts` — alertes de l'espace actif + dernière
  observation connue par produit.
- `GET /price-alerts/suggest?product=` — seuil suggéré depuis
  l'historique de l'espace (90 j) : prix habituel = **médiane**, bon
  prix = **25e percentile**. Moins de 3 observations → pas de
  suggestion (l'utilisateur saisit lui-même). Jamais imposé : l'app
  pré-remplit, l'humain confirme.
- `POST /price-alerts` — membre avec `add_items` ; une seule alerte
  active par (espace, produit, magasin) → 409 `ALERT_EXISTS`.
- `PUT/DELETE /price-alerts/{id}` — créateur ou `manage_lists`.
  Changer le seuil réarme l'alerte (compteurs de notification remis à
  zéro).

## Alertes de baisse dédupliquées (§27)

`PriceAlertService::onObservation` est appelé après **chaque** nouvelle
observation (cochage avec prix, ligne de reçu), hors transaction,
jamais bloquant. Déclenchement si `prix ≤ cible`, avec anti-spam :

- silence de **48 h** après une notification ;
- **exception** : un prix strictement plus bas que le dernier notifié
  re-déclenche immédiatement (vraie meilleure affaire).

Au déclenchement : push au créateur de l'alerte (fr/en selon sa
langue), `last_triggered_at`/`last_notified_price` mis à jour, événement
`price_alert_triggered` dans le journal de l'espace (espaces partagés).

Une alerte liée à un magasin précis ne se déclenche que sur une
observation de CE magasin ; un cochage sans magasin identifié ne
déclenche que les alertes « tous magasins ».

## Application

- Drawer : « Alertes de prix » pour tous les types d'espace.
- Écran : liste (cible, dernier prix vu, créateur, interrupteur
  actif/pause), création avec bouton « Suggérer un seuil » (§26),
  modification du seuil au tap, suppression à l'appui long.
- Activité : événement `price_alert_triggered` rendu traduit.
- 16 clés i18n fr/en (0 untranslated).

## Sécurité vérifiée (E2E 113/113)

Observation d'un cochage rattachée au foyer (DB) ; observation et alias
d'un reçu importé rattachés au foyer ; reçu ré-importé par un autre
membre → 409 ; prix du foyer invisibles dans le contexte personnel ;
non-membre → 403 (historique, création, modification) ; alerte en
double → 409 ; seuil manquant → 422 ; déclenchement à 4,25 ≤ 4,50 ;
pas de re-notification à 4,30 ; re-notification à 3,50 ; alerte
personnelle invisible dans le foyer.

## Reporté (assumé)

- Comparaison de prix **par fournisseur** (§22) : `purchase_requests`
  ne porte pas encore de `supplier_id` ni de prix réel d'achat — sera
  branché quand la clôture d'une demande enregistrera le prix payé.
- « Est-ce un bon prix ? » au moment de l'ajout (§29), économies
  estimées (§30), panier optimal (§31) → Phase 5 (assistant).
- Action « Ajouter à la liste » depuis la notification push → avec le
  dashboard adaptatif (§45).
