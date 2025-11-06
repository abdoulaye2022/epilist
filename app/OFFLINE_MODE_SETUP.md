# 📴 Mode Hors Ligne - Guide d'Intégration

## ✅ Ce qui a été implémenté

### 🏗️ Architecture Complète

Le mode hors ligne complet a été implémenté avec **ZÉRO risque pour la base de données en production**.

### 📦 Services Créés

1. **OfflineStorageService** (`lib/services/offline_storage_service.dart`)
   - Cache sécurisé avec versioning
   - Stockage: listes, budgets, factures, profil, devise, catégories
   - Expiration: 7 jours
   - Nettoyage sécurisé (ne touche JAMAIS aux tokens)

2. **OfflineQueueService** (`lib/services/offline_queue_service.dart`)
   - File d'attente pour 15 types d'actions
   - Retry intelligent (max 5 tentatives)
   - Détection de doublons
   - Gestion des actions abandonnées

3. **OfflineSyncService** (`lib/services/offline_sync_service.dart`)
   - Synchronisation automatique
   - Écoute de la connectivité
   - Exécution via API validée UNIQUEMENT
   - Aucune modification directe de la BDD

4. **ConflictResolutionService** (`lib/services/conflict_resolution_service.dart`)
   - Détection automatique des conflits
   - 4 stratégies: SERVER_WINS (défaut), LOCAL_WINS, MERGE, ASK_USER
   - Fusion intelligente avec règles métier

5. **OfflineIndicator** (`lib/widgets/common/offline_indicator.dart`)
   - Badge visuel en temps réel
   - Dialog de détails
   - Bouton "Synchroniser maintenant"

---

## 🚀 Intégration dans votre Application

### Étape 1: Initialiser les Services dans `main.dart`

```dart
import 'package:epilist/services/offline_storage_service.dart';
import 'package:epilist/services/offline_queue_service.dart';
import 'package:epilist/services/offline_sync_service.dart';
import 'package:epilist/services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ ÉTAPE 1: Initialiser le cache
  await OfflineStorageService.initialize();
  print('✅ Cache initialisé');

  // ✅ ÉTAPE 2: Initialiser la queue
  await OfflineQueueService.initialize();
  print('✅ Queue initialisée');

  // ✅ ÉTAPE 3: Initialiser le service de connectivité
  final connectivityService = ConnectivityService();
  await connectivityService.initialize();
  print('✅ Connectivité initialisée');

  runApp(MyApp());
}
```

### Étape 2: Initialiser OfflineSyncService après le login

Dans votre `AuthBloc` ou après le login réussi:

```dart
import 'package:epilist/services/offline_sync_service.dart';
import 'package:epilist/services/shopping_list_service.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:epilist/services/receipt_service.dart';
import 'package:epilist/services/budget_service.dart';
import 'package:epilist/services/user_service.dart';

// Après le login réussi
final syncService = OfflineSyncService();

await syncService.initialize(
  shoppingListService: ShoppingListService(),
  listItemService: ListItemService(),
  receiptService: ReceiptService(),
  budgetService: BudgetService(),
  userService: UserService(),
);

// Démarrer l'écoute de la connectivité
await syncService.startListening();

print('✅ Service de synchronisation démarré');
```

### Étape 3: Ajouter l'OfflineIndicator dans votre Layout Principal

Dans `lib/screens/home_screen.dart` ou votre layout principal:

```dart
import 'package:epilist/widgets/common/offline_indicator.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        // ✅ Ajouter l'indicateur hors ligne en haut
        const OfflineIndicator(),

        // Votre contenu existant
        Expanded(
          child: YourMainContent(),
        ),
      ],
    ),
  );
}
```

### Étape 4: Mettre à Jour les Autres BLoCs (Optionnel mais Recommandé)

**ListItemBloc** - Exemple pour ajouter un item:

```dart
Future<void> _onCreateListItem(
  CreateListItem event,
  Emitter<ListItemState> emit,
) async {
  try {
    final newItem = await _listItemService.createListItem(
      event.listId,
      event.productName,
      price: event.price,
      quantity: event.quantity,
    );

    // Success
    emit(ListItemCreated(newItem));
  } catch (e) {
    // ✅ Si hors ligne, mettre en queue
    if (!ConnectivityService().isConnected) {
      await OfflineQueueService.enqueueAction(
        actionType: OfflineQueueService.ACTION_CREATE_ITEM,
        payload: {
          'list_id': event.listId,
          'product_name': event.productName,
          'price': event.price,
          'quantity': event.quantity,
        },
      );

      // Créer un item temporaire local
      final tempItem = ListItem(
        id: -DateTime.now().millisecondsSinceEpoch,
        listId: event.listId,
        productName: event.productName,
        price: event.price,
        quantity: event.quantity,
        isPurchased: false,
        createdAt: DateTime.now(),
      );

      emit(ListItemCreated(tempItem));
      return;
    }

    emit(ListItemError(e.toString()));
  }
}
```

---

## 🔒 Garanties de Sécurité

### ✅ Aucun Risque pour la Base de Données Production

1. **Pas de modifications directes**
   - Toutes les actions passent par l'API avec validation
   - Aucun accès direct à la BDD

2. **Tokens protégés**
   ```dart
   // Le nettoyage ne touche JAMAIS ces clés:
   - access_token
   - refresh_token
   - user_id
   ```

3. **Stratégie par défaut sécurisée**
   - SERVER_WINS: Le serveur a toujours raison
   - En cas de conflit, la version serveur l'emporte

4. **Retry limité**
   - Maximum 5 tentatives par action
   - Abandon automatique après 5 échecs
   - Pas de boucles infinies

5. **Actions abandonnées nettoyées**
   - Suppression automatique après 7 jours
   - Nettoyage périodique du cache expiré

6. **Versioning du cache**
   - Version actuelle: `1.0.0`
   - Nettoyage automatique si version mismatch
   - Prévient la corruption lors des mises à jour

---

## 🧪 Tests Recommandés

### Test 1: Créer une Liste Hors Ligne

```bash
# 1. Mettre l'appareil en mode avion
# 2. Créer une nouvelle liste "Test Offline"
# 3. Vérifier que la liste apparaît
# 4. Vérifier le badge "Actions en attente: 1"
# 5. Rétablir la connexion
# 6. Vérifier la synchronisation automatique
# 7. Vérifier que la liste existe sur le serveur
```

### Test 2: Modifier des Items Hors Ligne

```bash
# 1. Charger une liste existante
# 2. Passer en mode avion
# 3. Ajouter 3 items
# 4. Modifier 2 items
# 5. Supprimer 1 item
# 6. Vérifier le badge "Actions en attente: 6"
# 7. Rétablir la connexion
# 8. Vérifier la synchronisation
# 9. Vérifier que toutes les modifications sont sur le serveur
```

### Test 3: Conflit de Données

```bash
# 1. Charger une liste sur l'appareil A
# 2. Charger la même liste sur l'appareil B
# 3. Sur A: modifier le nom de la liste en "Version A"
# 4. Sur B (mode avion): modifier le nom en "Version B"
# 5. Sur A: synchroniser (réussit)
# 6. Sur B: rétablir la connexion
# 7. Vérifier que le serveur gagne (stratégie SERVER_WINS)
# 8. Résultat attendu: "Version A"
```

### Test 4: Cache et Fallback

```bash
# 1. Utiliser l'app en ligne normalement
# 2. Fermer l'app
# 3. Passer en mode avion
# 4. Ouvrir l'app
# 5. Vérifier que les données du cache s'affichent
# 6. Vérifier le badge "Mode hors ligne"
```

---

## 📊 Monitoring et Statistiques

### Obtenir le Statut de la Queue

```dart
final status = await OfflineQueueService.getStatus();
print('Total: ${status['total']}');
print('En attente: ${status['pending']}');
print('En cours: ${status['processing']}');
print('Échecs: ${status['failed']}');
print('Abandonnés: ${status['abandoned']}');
```

### Obtenir les Statistiques Détaillées

```dart
final stats = await OfflineQueueService.getDetailedStats();
print('Par type: ${stats['by_action_type']}');
print('Action la plus ancienne: ${stats['oldest_action']}');
print('Âge de la queue: ${stats['queue_age_days']} jours');
```

### Obtenir les Statistiques du Cache

```dart
final cacheStats = await OfflineStorageService.getCacheStats();
print('Version: ${cacheStats['version']}');
print('Dernière sync: ${cacheStats['last_sync']}');
print('Cache valide: ${cacheStats['cache_valid']}');
print('Listes: ${cacheStats['shopping_lists_count']}');
print('Budgets: ${cacheStats['budgets_count']}');
```

---

## 🛠️ Configuration Avancée

### Changer la Stratégie de Résolution de Conflits

```dart
import 'package:epilist/services/conflict_resolution_service.dart';

// Stratégie 1: Le serveur gagne toujours (PAR DÉFAUT - LE PLUS SÛR)
await ConflictResolutionService.setResolutionStrategy(
  ConflictResolutionService.STRATEGY_SERVER_WINS,
);

// Stratégie 2: Les modifications locales gagnent (RISQUÉ)
await ConflictResolutionService.setResolutionStrategy(
  ConflictResolutionService.STRATEGY_LOCAL_WINS,
);

// Stratégie 3: Fusion intelligente (RECOMMANDÉ SI TESTÉ)
await ConflictResolutionService.setResolutionStrategy(
  ConflictResolutionService.STRATEGY_MERGE,
);

// Stratégie 4: Demander à l'utilisateur (UX COMPLEXE)
await ConflictResolutionService.setResolutionStrategy(
  ConflictResolutionService.STRATEGY_ASK_USER,
);
```

### Forcer une Synchronisation Manuelle

```dart
final syncService = OfflineSyncService();
await syncService.forceSyncNow();
```

### Nettoyer le Cache Manuellement

```dart
// ⚠️ ATTENTION: Ne touche PAS aux tokens d'authentification
await OfflineStorageService.clearAll();
```

### Nettoyer la Queue

```dart
await OfflineQueueService.clearQueue();
```

---

## 🐛 Dépannage

### Problème: Les actions ne se synchronisent pas

**Vérifications:**
1. Le service de sync est-il initialisé?
   ```dart
   final syncService = OfflineSyncService();
   await syncService.startListening();
   ```

2. La connectivité est-elle détectée?
   ```dart
   final isConnected = ConnectivityService().isConnected;
   print('Connecté: $isConnected');
   ```

3. Y a-t-il des actions en attente?
   ```dart
   final count = await OfflineQueueService.getPendingCount();
   print('Actions en attente: $count');
   ```

### Problème: Le cache ne se charge pas

**Vérifications:**
1. Le cache est-il initialisé?
   ```dart
   await OfflineStorageService.initialize();
   ```

2. Le cache est-il valide (< 7 jours)?
   ```dart
   final isValid = await OfflineStorageService.isCacheValid();
   print('Cache valide: $isValid');
   ```

3. Y a-t-il des données en cache?
   ```dart
   final lists = await OfflineStorageService.getShoppingLists();
   print('Listes en cache: ${lists?.length ?? 0}');
   ```

### Problème: L'indicateur ne s'affiche pas

**Vérifications:**
1. Le widget est-il ajouté au layout?
   ```dart
   Column(
     children: [
       const OfflineIndicator(), // ✅ Ici
       ...
     ],
   )
   ```

2. Les traductions sont-elles générées?
   ```bash
   flutter gen-l10n
   ```

---

## 📝 Notes Importantes

### ⚠️ IMPORTANT - Production

1. **Tester exhaustivement** avant de déployer en production
2. **Commencer avec SERVER_WINS** (stratégie par défaut)
3. **Monitorer les logs** pour détecter les problèmes
4. **Vérifier les statistiques** régulièrement

### 🔐 Sécurité

- Aucune modification directe de la BDD ✅
- Tokens protégés ✅
- API validée utilisée ✅
- Retry limité ✅
- Nettoyage automatique ✅

### 📈 Performance

- Cache versionné (évite la corruption) ✅
- Expiration automatique (7 jours) ✅
- Délai entre sync (500ms) ✅
- Détection de doublons ✅

---

## ✅ Checklist d'Intégration

- [ ] Services initialisés dans `main.dart`
- [ ] OfflineSyncService démarré après login
- [ ] OfflineIndicator ajouté au layout principal
- [ ] ShoppingListBloc mis à jour (FAIT ✅)
- [ ] ListItemBloc mis à jour
- [ ] ReceiptBloc mis à jour
- [ ] BudgetBloc mis à jour
- [ ] Tests effectués (mode avion, sync, conflits)
- [ ] Monitoring configuré
- [ ] Documentation lue et comprise

---

## 🎯 Prochaines Étapes Suggérées

1. **Compléter l'intégration** - Suivre les étapes ci-dessus
2. **Tester en profondeur** - Utiliser les scénarios de test
3. **Monitorer en développement** - Vérifier les logs et statistiques
4. **Déployer progressivement** - Commencer avec un petit groupe d'utilisateurs
5. **Collecter les retours** - Améliorer selon les feedbacks

---

**✅ Mode Hors Ligne - Prêt pour l'Intégration!**

Toute l'architecture est en place et sécurisée. Il suffit maintenant de l'intégrer dans votre application en suivant ce guide.
