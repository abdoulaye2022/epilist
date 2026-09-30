# Audit final du chantier espaces (post-livraison)

> **MISE À JOUR 2026-09-30 : tous les constats C1-C6 sont CORRIGÉS**
> et vérifiés — la suite E2E passe de 161 à **180/180**. Détail des
> résolutions en fin de document. Bonus découvert pendant la
> correction : `Budget::isActive()` comparait `end_date` à minuit,
> rendant tout budget « inactif » pendant son DERNIER jour — corrigé
> (`endOfDay`), testé.

Réalisé le 2026-09-30, après la livraison des Phases 1-6 + §45.
Méthode : relecture systématique du code (requêtes restées « par
utilisateur », points d'accès, crons), vérifications en base locale,
re-exécution complète des validations. **Aucune correction appliquée
dans cet audit** : constats d'abord, décision ensuite.

## Ce qui est VALIDÉ (vérifié, pas supposé)

| Sujet | Preuve |
|---|---|
| Isolation inter-espaces (listes, items, budgets, inventaire, prix, prédictions, économies, alertes) | E2E **161/161** re-passés pendant l'audit |
| Hors ligne | file v2 : `space_id` capturé par action, `syncOverride` par rejeu, caches par espace (`@s{id}`) — vérifié dans le code |
| Migrations | les **6 fichiers re-exécutés d'affilée sans erreur** sur une base déjà migrée (idempotence prouvée) |
| Suppression d'espace | `Space` en SoftDeletes → `assertMember` refuse (membres exclus) ; aucun trou d'accès trouvé |
| Communauté §33 | aucune identité dans les agrégats ni les réponses (test E2E littéral), recalcul 403 sans secret |
| i18n | 0 untranslated, aucune chaîne en dur dans les 9 écrans espaces |
| Qualité app | `flutter analyze` 0, 18/18 tests, build debug OK |

## Constats

### C1 — MAJEUR · Les statistiques ignorent les espaces
`AnalyticsController` (`getUserAccessibleListIds`) ne connaît que les
listes possédées (`user_id`) + le partage legacy (`shared_list`).
`X-Space-Id` n'est jamais résolu. Conséquences :
- un membre du foyer ne voit PAS les dépenses des listes du foyer
  créées par les autres ;
- le créateur voit ses listes du foyer MÉLANGÉES à ses statistiques
  « personnelles », quel que soit l'espace actif.
Écrans touchés : Statistiques (dépenses, historique hebdo, dashboard
analytique). Correctif type : brancher `resolveSpace` + `scopeLists`
(comme ShoppingListController) sur les 3 entrées du contrôleur.

### C2 — MAJEUR · Budget général : dépensé calculé hors espace
`Budget::getUserSpentAmount()` (budget SANS liste liée) somme les
listes `accessibleBy(user_id du créateur)` : ses listes personnelles
+ celles qu'il a créées dans le foyer + le legacy — jamais le
périmètre de l'ESPACE du budget, et jamais les listes du foyer créées
par les autres membres. Un budget du foyer est donc faux dans les
deux sens. Propagé partout où le dépensé s'affiche : liste des
budgets, `/budgets/forecast`, brief « avant les courses », alertes
cron. Correctif type : si `space_id` non personnel → listes de
l'espace ; sinon → périmètre personnel strict (comme `scopeLists`).
Les budgets liés à UNE liste (`getListSpentAmount`) sont corrects.

### C3 — MOYEN · Planificateur de repas : prix estimés hors espace
`MealPlanController` (consolidation d'ingrédients) : l'inventaire
« déjà à la maison » est bien scoped espace, mais les PRIX estimés
lisent `PurchaseHistory::where('user_id')` — un plan de repas du foyer
ignore les prix observés par les autres membres et pioche dans le
personnel du demandeur (fuite de périmètre douce, incohérence §34).

### C4 — MINEUR · Alertes budget cron : seul le créateur est notifié
`checkBudgetAlerts` notifie `budget->user`. Dans un foyer, les autres
membres (droit `view_budgets`) ne reçoivent rien. Amélioration à
brancher sur les membres actifs de l'espace du budget.

### C5 — MINEUR · Données d'un espace supprimé : limbes
Après suppression d'un espace, ses listes/budgets/inventaire restent
en base : invisibles de tout listing (correct), mais une liste reste
accessible PAR ID à son créateur (`Space::find` → null → repli
« propriétaire »). Rien de dangereux ; à trancher : purge différée,
export, ou statu quo documenté. En local : 30 listes, 14 budgets,
29 demandes orphelines (résidus des tests E2E surtout).

### C6 — MINEUR · Alias appris au foyer visibles dans le scan personnel
`resolveLabels` en contexte personnel lit `ProductAlias::where(user)`,
qui inclut les alias créés par CE user dans un espace partagé. Fuite
limitée à des correspondances de libellés (aucun prix), mais
l'inverse du sens choisi partout ailleurs (perso strict).

### C7 — ASSUMÉ · Apprentissages personnels par conception
Suggestions personnalisées (`SmartSuggestionService`,
`product_suggestions`) et préférences de prédiction (« ne plus
suggérer », snooze) restent PAR UTILISATEUR — décision documentée
(un goût personnel ne masque rien pour les autres membres).

### C8 — INFO · Région communautaire
`spaces.region` existe mais la communauté agrège par `city` ; les
espaces personnels n'ont pas de ville → région vide regroupée. Déjà
noté dans les reports, à enrichir selon l'usage.

### C9 — ASSUMÉ · Écrans Phases 4-6 en ligne seulement
Alertes de prix, « Avant les courses », communauté : pas de file
hors ligne (états d'erreur propres). Cohérent avec la décision
« API complète + app essentielle ».

### Couverture E2E — trous connus
La suite (161 vérifications) ne couvre PAS : analytics (C1), dépensé
des budgets généraux partagés (C2), planificateur de repas (C3),
messages de listes d'espace (protégés par `canBeAccessedBy` étendu,
relu mais non testé E2E). À combler avec les correctifs.

## Résolutions (tout corrigé le 2026-09-30, E2E 180/180)

- **C1 corrigé** — `AnalyticsController` : espace actif résolu au
  début des 12 endpoints (avant le `try` : non-membre → 403, pas 500) ;
  `getUserAccessibleListIds` : espace partagé = toutes ses listes ;
  personnel = propres + legacy MOINS les listes d'espaces partagés ;
  `checkListAccess` délégué à `ListAccessService`. E2E : stats foyer =
  50 $ (achats des DEUX membres), stats perso de A à delta 0, 403
  après départ.
- **C2 corrigé** — `Budget::getUserSpentAmount` : budget d'espace
  partagé = listes de l'ESPACE (tous créateurs) ; personnel/legacy
  exclut les listes d'espaces partagés. E2E : dépensé foyer = 50 $,
  budgets persos de C à delta 0. Bonus : `isActive()` en `endOfDay`
  (budget actif son dernier jour — testé un 30 du mois !).
- **C3 corrigé** — prix estimés du planificateur de repas dans le même
  espace que l'inventaire (`scopeQuery`). Relu + lint (pas de harnais
  E2E recettes — assumé).
- **C4 corrigé** — alertes budget du cron : budget d'espace partagé →
  tous les membres actifs avec `view_budgets` ; anti-spam inchangé
  (par budget, 24 h) ; le pré-filtre « appareils du créateur » retiré
  (chaque destinataire est vérifié par `sendToUser`). Relu + lint
  (cron non couvert par le harnais HTTP — assumé).
- **C5 corrigé** — suppression d'espace SANS limbes : cascade dans
  `SpaceController::destroy` (listes + fournisseurs soft-supprimés,
  budgets + alertes de prix désactivés, listes récurrentes stoppées —
  l'historique `purchase_history` reste intact) ; et durcissement de
  `ListAccessService` (`check` + `checkSharedSpace`) : espace
  introuvable → accès refusé, AUCUN repli « propriétaire ». E2E :
  liste inaccessible même au créateur, budget/alerte désactivés,
  fournisseur soft-supprimé.
- **C6 corrigé** — `resolveLabels` en personnel exclut les alias
  appris dans un espace partagé. E2E : alias résolu avec l'en-tête
  foyer, ignoré en personnel.
- C7-C9 restent assumés (documentés), inchangés.

Couverture E2E ajoutée : 19 vérifications (161 → **180**), incluant
enfin analytics et budgets généraux partagés — les deux zones dont
l'absence de tests avait laissé passer C1 et C2.
