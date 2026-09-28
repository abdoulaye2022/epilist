# Audit du mode hors ligne — 27 septembre 2026

> **MISE À JOUR (même jour) : les 11 constats ci-dessous sont corrigés.**
> Validation sur émulateur : liste + article créés hors ligne synchronisés
> avec remappage d'id (vérifié en BD serveur), file persistante à travers
> les redémarrages, cache des listes rafraîchi après synchro, carte budget
> servie depuis le cache au démarrage à froid hors ligne. Détail des
> correctifs dans le commit « Mode hors ligne : correction des 11 constats
> de l'audit ».

Audit combiné : lecture du code (`connectivity_service`, `offline_storage_service`,
`offline_queue_service`, `offline_sync_service`, blocs) **et** tests réels sur
émulateur Android 16 (coupure réseau via adb, ajout hors ligne, resynchronisation,
démarrage à froid hors ligne, redémarrages successifs).

## Verdict global

Le cœur du mode hors ligne **fonctionne** : consultation depuis le cache, actions
mises en file, resynchronisation automatique au retour du réseau (vérifiée jusqu'en
base de données serveur). Mais l'audit révèle **2 pertes de données silencieuses**
(factures et catégories créées hors ligne), un canal de synchro cassé depuis la
migration des tokens, et plusieurs trous de couverture.

## Ce qui fonctionne (vérifié en conditions réelles)

| Scénario testé | Résultat |
|---|---|
| Coupure réseau en cours d'usage | Bandeau « Mode hors ligne » en ~5 s |
| Consultation hors ligne | Listes (8), articles (9), profil, devise, avatar : tous servis depuis le cache |
| Ajout d'article hors ligne | Ajout local immédiat + `create_item` en queue |
| Cocher un article hors ligne | `toggle_item` en queue |
| Retour du réseau | Synchro automatique 2/2, **vérifiée en BD serveur** (article créé, `is_purchased=1`) |
| Démarrage à froid hors ligne | Session conservée, dashboard + listes depuis cache, bandeau affiché |
| Redémarrages successifs (en ligne) | Session et tokens conservés |
| Robustesse de la file | Versionnage du cache/queue, 5 retries max, purge des abandonnées > 7 j, tri chronologique |
| Indicateur de synchro | Compteur d'actions en attente + bouton « synchroniser maintenant » (`offline_indicator`) |

## Problèmes trouvés

### 1. CRITIQUE — Factures hors ligne perdues en silence
`OfflineSyncService().initialize(...)` dans `main.dart` n'injecte **ni
`receiptService` ni `budgetService`**. Dans `_syncAction`, `_receiptService?.createReceipt(...)`
sur un service null est un **no-op qui retourne `true`** : l'action est marquée
« synchronisée » sans qu'aucune requête ne parte. Toute facture créée/modifiée/
supprimée hors ligne est perdue sans erreur. Idem `delete_budget`.
**Fix** : injecter les deux services dans `main.dart` + remplacer les `?.` par un
échec explicite si le service manque.

### 2. CRITIQUE — Catégories hors ligne perdues
`category_bloc` met en queue `create_category` / `update_category` /
`delete_category`, mais le `switch` de `_syncAction` n'a **aucun case catégorie**
→ « Type d'action inconnu » → 5 retries → abandon. **Fix** : ajouter les 3 cases
(+ `reorder_categories`) avec `CategoryService`.

### 3. MAJEUR — `_getToken()` lit un emplacement vide depuis la migration TokenStore
`OfflineSyncService._getToken()` lit `SharedPreferences['access_token']`, or les
tokens vivent maintenant dans `flutter_secure_storage` (TokenStore) et la migration
**supprime** l'ancienne clé. Conséquences : la resynchro des préférences e-mail
échoue toujours (abandon après 5 essais) et le feedback part sur l'endpoint
**anonyme** même connecté. **Fix** : utiliser `TokenStore.readAccess()` (et idéalement
le Dio partagé avec intercepteur de refresh au lieu de `http`).

### 4. MAJEUR — Pas de mappage id local → id serveur
Une liste créée hors ligne reçoit un id négatif. Toute action ultérieure sur cette
liste hors ligne (ajout d'article, renommage, suppression, duplication) est mise en
queue **avec l'id négatif** : à la synchro, la liste est créée côté serveur avec un
nouvel id, mais les actions suivantes partent avec l'id local → 404 → 5 retries →
abandon. Les magasins gèrent déjà ce cas (skip des ids < 0) ; les listes/articles non.
**Fix minimal** : à la synchro d'un `create_list`, récupérer l'id serveur et
réécrire les payloads en queue portant le `local_id` correspondant (le champ existe
déjà). À défaut, bloquer les actions dépendantes comme pour les magasins.

### 5. MAJEUR (UX) — Carte budget vide hors ligne (constaté à l'écran)
Seul `_onLoadBudgets` a un fallback cache, et `saveBudgets` n'est appelé que là.
Le dashboard passe par un autre chemin (`RefreshBudgets` / filtres) : hors ligne il
affiche « Aucun budget pour Septembre 2026 » alors qu'un budget 500 $ existe.
**Fix** : sauvegarder le cache à chaque chargement réussi et ajouter le fallback
dans `_onRefreshBudgets` et `_onLoadBudgetsWithFilters`.

### 6. MOYEN — Actions bloquées en « processing » si l'app est tuée pendant une synchro
`getPendingActions()` ne reprend que le statut `pending`. Une action passée à
`processing` au moment où l'app est tuée n'est **jamais** reprise ni nettoyée
(la purge ne touche que `abandoned`). **Fix** : au démarrage, requalifier en
`pending` toute action `processing` datant de plus de ~2 min (`processing_at`).

### 7. MOYEN — Cache des listes non rafraîchi après synchro
Après la resynchro, l'app ne recharge pas les listes : au démarrage hors ligne
suivant, la carte « test » affichait 2/9 au lieu de 2/10. **Fix** : déclencher un
rechargement (et `saveShoppingLists`) après une synchro avec succès.

### 8. MOYEN — Budgets : pas de file hors ligne du tout
`budget_bloc` n'enqueue rien (les cases `create/update_budget` du sync retournent
d'ailleurs `false` en dur). Créer un budget hors ligne échoue simplement. Cohérent
mais différent des listes/articles ; à documenter ou implémenter.

### 9. MINEUR — `isDuplicateAction` jamais appelé
La protection anti-doublons existe dans la queue mais aucun bloc ne l'utilise.

### 10. À SURVEILLER — Perte des tokens observée une fois
Pendant les tests, le secure storage s'est retrouvé vidé de ses tokens après une
réinstallation dev (déconnexion forcée au démarrage suivant). Non reproduit sur
redémarrages normaux (2 cycles OK). `flutter_secure_storage` +
EncryptedSharedPreferences a des cas connus de réinitialisation (accès concurrent
depuis l'isolate FCM en arrière-plan, clé keystore invalidée). Recommandation :
logger distinctement « token présent mais indéchiffrable » vs « absent », et
soigner l'UX de reconnexion (message clair plutôt que retour silencieux au Welcome).

### 11. MINEUR — Démarrage à froid hors ligne lent
~15–20 s en debug avant le dashboard (Firebase init, premier check de connectivité
~5 s de timeout, attentes FCM). En release ce sera plus court, mais le timeout du
premier check réseau (5 s) reste incompressible sur le chemin critique.

## Ordre de correction conseillé

1. (#1) Injecter receipt/budget services + supprimer les `?.` silencieux.
2. (#2) Cases catégories dans `_syncAction`.
3. (#3) `TokenStore.readAccess()` dans `_getToken()`.
4. (#5) Cache budgets (save partout + fallback partout).
5. (#6) Requalification des actions `processing` orphelines au démarrage.
6. (#4) Mappage id local → serveur (ou blocage type « magasins »).
7. (#7, #9) Rechargement post-synchro, brancher l'anti-doublons.
