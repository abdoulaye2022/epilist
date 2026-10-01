# Ouvrir le bon écran depuis une notification

Livré le 2026-10-01. Aucune migration — le serveur envoyait déjà tout
ce qu'il fallait.

## Ce qui ne marchait pas

Les clics sur notification étaient bien détectés, mais la navigation
était un **TODO** : la méthode se contentait d'un `debugPrint`. Toucher
une notification ouvrait donc l'application sur l'accueil.

## Ce qui se passe maintenant

| Notification | Écran ouvert |
|---|---|
| Nouveau message (`action: open_chat`) | la **conversation** de la liste |
| Liste modifiée / partagée / terminée (`open_list`, `add_receipt`) | le **détail de la liste** |
| Alerte de budget (`type: budget_*`) | l'écran **Budgets** |
| Alerte de prix (`type: price_alert`) | l'écran **Alertes de prix** |
| Type inconnu | rien — mieux vaut ne rien ouvrir qu'ouvrir au hasard |

Le serveur envoyait déjà `action`, `type`, `list_id` et `list_name`
dans la charge utile : rien à changer côté API.

## Les trois cas couverts

1. **Application au premier plan** : une notification locale est
   affichée avec les données en charge utile ; son clic est routé.
2. **Application en arrière-plan** : `onMessageOpenedApp`.
3. **Application fermée** : `getInitialMessage` au lancement. À cet
   instant le navigateur n'existe pas encore — l'ouverture est
   **mémorisée** puis rejouée dès que l'application est prête.

## Points de conception

- **`appNavigatorKey`** (`lib/config/app_navigator.dart`) : un clic sur
  notification survient hors de l'arbre de widgets, parfois avant même
  qu'un écran existe. La clé du navigateur racine permet d'ouvrir un
  écran sans `BuildContext` d'écran.
- **Jamais par-dessus l'écran de connexion** : sans session, l'ouverture
  reste en attente jusqu'à ce que l'utilisateur se connecte.
- **Le détail d'une liste** n'est pas transmis par la notification (elle
  ne porte que l'identifiant) : la liste est donc récupérée par l'API
  avant d'ouvrir l'écran.
- Les services sont lus **avant** toute attente : un `BuildContext` ne
  doit pas traverser un `await`.

## Vérifié

`flutter analyze` 0, 18/18 tests, build debug OK. Le parcours complet
reste à éprouver sur appareil (envoyer une notification réelle et
toucher la bannière dans les trois états).
