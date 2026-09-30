# Communauté de prix anonymisée (Phase 6)

Livré le 2026-09-30. Prérequis : Phases 1-5. Migration :
`api/migrations/add_spaces_phase6.sql` (idempotente).

## Principe (§33)

Les prix observés par les utilisateurs consentants nourrissent des
**agrégats communautaires** : produit × magasin × région → médiane,
min, moyenne, nombre d'observations, nombre de contributeurs, dernière
date. **Jamais d'identité** : la table `community_prices` ne contient
aucun `user_id` — les identités ne servent qu'à compter les
contributeurs distincts pendant le recalcul, puis disparaissent.

Le wording reste prudent partout : « prix observés par la
communauté », jamais des prix officiels.

## Règles de qualité AVANT publication

Un groupe n'est publié que si, dans la fenêtre de 90 jours :

1. **≥ 3 contributeurs distincts** — un agrégat à 1-2 contributeurs
   ré-identifierait son auteur ;
2. **≥ 5 observations** après nettoyage ;
3. **valeurs aberrantes écartées** : hors `[médiane/4, médiane×4]`
   (une erreur de saisie à 59,90 $ ne pollue pas la médiane — testé).

Sous ces seuils : rien n'est publié (vérifié E2E).

## Consentement et retrait

`users.community_prices_enabled` (défaut : activé, agrégats 100 %
anonymes). Retrait à tout moment :

- `GET/PUT /community/settings { enabled }` — API ;
- app : « Intelligence EpiList » → « Partager mes prix (anonymisé) ».

Le retrait exclut TOUTES les observations de l'utilisateur au prochain
recalcul (testé E2E : le retrait de B fait passer le groupe sous les
seuils et l'agrégat disparaît).

## Recalcul (cron)

`public/community_refresh.php` — REBUILD complet, même garde que
`campaign.php` (CLI libre ; HTTP exige `?key=CRON_SECRET` ou l'en-tête
`X-Cron-Key`, fail closed sans secret). Une fois par jour suffit :

```
0 6 * * * curl -s "https://m2atodev.com/api.epilist/public/community_refresh.php?key=TON_CRON_SECRET"
```

La réponse JSON ne contient que des statistiques d'exécution
(source_rows, published, rejected_quality).

## Lecture

- `GET /community/prices?product=&region=` — agrégats publiés, du
  moins cher au plus cher, avec fraîcheur (fresh/acceptable/old/stale)
  et les seuils de qualité rappelés dans la réponse.
- `GET /prices/check` (§29) porte maintenant un champ `community` :
  le meilleur agrégat publié pour le produit — utile surtout quand
  l'historique personnel est vide (`verdict: unknown` + repère
  communautaire, testé E2E).

## Application

- Réglages Intelligence : interrupteur serveur « Partager mes prix
  (anonymisé) » avec explication du principe et du retrait.
- « Est-ce un bon prix ? » : ligne « Communauté : médiane X $ ·
  magasin (N contributeurs) » quand un agrégat existe.
- 3 clés i18n fr/en (0 untranslated).

## Sécurité vérifiée (E2E 156/156)

Recalcul refusé sans le bon secret (403) ; aucune chaîne « user » dans
les réponses communautaires ; produit à 1 contributeur jamais publié ;
aberrante écartée (médiane stable à 5,69) ; retrait effectif au
recalcul suivant ; retour du consentement → republication.

## Pour la production

1. Sauvegarde SQL, puis migrations dans l'ordre :
   `add_spaces.sql` → `phase2` → `phase3` → `phase4` → `phase5` →
   `phase6`.
2. Planifier le cron quotidien `community_refresh.php` (ci-dessus).
3. Vérifier `CRON_SECRET` dans le `.env` de prod.

## Reporté (assumé)

- Région : issue de la ville de l'espace (souvent vide pour les
  espaces personnels) — un enrichissement du profil suivra l'usage.
- Dashboard adaptatif (§45) : dernière brique du chantier espaces.
