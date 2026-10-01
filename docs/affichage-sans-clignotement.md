# Afficher puis rafraîchir (fin du spinner à chaque page)

Livré le 2026-10-01. Aucune migration.

## Le problème

Chaque écran rechargeait ses données dans `initState` et affichait un
indicateur de chargement **à chaque navigation** — même quand les
données venaient d'être lues quelques secondes plus tôt. L'application
donnait l'impression de tout recharger en permanence.

## Le principe retenu

**Afficher d'abord ce qu'on sait, rafraîchir ensuite en silence.**

1. l'écran affiche immédiatement la dernière version connue ;
2. l'appel réseau part quand même, sans rien bloquer ;
3. l'affichage est remplacé quand la réponse arrive.

Un indicateur de chargement n'apparaît donc **que s'il n'y a rien à
montrer** : première ouverture, ou après une erreur.

Corollaire tout aussi important : **un rafraîchissement raté reste
invisible**. Si des données sont déjà à l'écran, un échec réseau ne les
remplace plus par une page d'erreur.

## Deux mécanismes selon le type d'écran

### Écrans alimentés par un BLoC

Les BLoC sont fournis à la racine de l'application : leur état survit
déjà à la navigation. Le seul tort était d'émettre `Loading` à chaque
rechargement. Chaque gestionnaire de chargement commence désormais par :

```dart
final nothingDisplayed = state is XInitial || state is XError;
if (nothingDisplayed) {
  emit(XLoading());
}
```

et son émission d'erreur est conditionnée au même booléen.

14 gestionnaires traités, dans : listes de courses, budgets, catégories,
magasins, factures, listes partagées, devises, suggestions, suggestions
de produits, statistiques.

**Détail de liste** : `ListItemLoaded` porte maintenant le `listId`.
Revenir sur la MÊME liste n'affiche plus de spinner ; ouvrir une AUTRE
liste en affiche un (sinon on verrait un instant les articles de la
liste précédente).

### Écrans qui appellent directement un service

`lib/services/screen_cache.dart` : cache **en mémoire** (durée de vie =
la session), cloisonné par espace actif, vidé à la déconnexion.

```dart
@override
void initState() {
  super.initState();
  _alerts = ScreenCache.read<List<PriceAlertInfo>>('price_alerts');
  _load();
}

Future<void> _load() async {
  try {
    final list = await _service.getPriceAlerts();
    ScreenCache.write('price_alerts', list);
    if (!mounted) return;
    setState(() { _alerts = list; _error = false; });
  } catch (_) {
    if (!mounted) return;
    if (_alerts == null) setState(() => _error = true); // sinon on garde
  }
}
```

11 écrans traités : alertes de prix, fournisseurs, demandes d'achat,
activité d'espace, membres d'espace, avant les courses, prédictions,
inventaire, listes récurrentes, planificateur de repas, préférences
email.

## Cloisonnement par espace

Chaque entrée du cache est implicitement rattachée à l'espace actif
(`clé@sID`). Basculer du personnel au foyer ne peut pas ressortir les
données de l'autre espace : c'est un défaut de cache, donc un
chargement normal.

## Ce qui n'est PAS caché (volontairement)

- **Messages d'une liste** (`chat_screen`) : l'état ne porte pas
  l'identifiant de la liste ; afficher la conversation d'une autre liste
  serait pire qu'un spinner. À traiter comme le détail de liste si le
  besoin se confirme.
- **Données persistantes hors ligne** : elles restent du ressort
  d'`OfflineStorageService`, qui survit à la fermeture de
  l'application. `ScreenCache` ne vit que le temps de la session.

## Vérifié

`flutter analyze` 0, 18/18 tests, build debug OK.
