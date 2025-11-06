# 🧪 Guide de Test du Chat - EpiList

## ✅ Prérequis Validés

Avant de commencer les tests, vérifions que tout est en place:

- ✅ **Base de données**: Tables `list_messages` et `message_read_status` créées
- ✅ **API Backend**: Routes configurées dans `index.php`
- ✅ **Frontend**: Bouton de chat ajouté dans `ListDetailAppBar`
- ✅ **Navigation**: Méthode `_openChatScreen()` implémentée

---

## 📋 Plan de Test

### Test 1: Visibilité du Bouton de Chat

**Objectif:** Vérifier que le bouton apparaît seulement pour les listes partagées

**Étapes:**
1. Ouvrir l'application EpiList
2. Se connecter avec votre compte
3. Aller dans "Mes listes"
4. Ouvrir une liste **NON partagée**
   - ❌ Le bouton de chat NE DOIT PAS apparaître
5. Retourner et ouvrir une liste **partagée**
   - ✅ Le bouton de chat (icône bulle) DOIT apparaître à côté du menu "..."

**Résultat attendu:**
- Bouton visible uniquement pour les listes partagées
- Icône: `chat_bubble_outline` (bulle de conversation)
- Position: Entre le bouton "+" et le menu "..."

---

### Test 2: Navigation vers le Chat

**Objectif:** Vérifier que l'écran de chat s'ouvre correctement

**Étapes:**
1. Depuis une liste partagée, cliquer sur le bouton de chat
2. Observer l'écran qui s'ouvre

**Résultat attendu:**
- ✅ L'écran de chat s'ouvre
- ✅ Le titre affiche le nom de la liste
- ✅ Un champ de texte apparaît en bas pour écrire un message
- ✅ Un bouton d'envoi (icône flèche) est visible

**Si erreur:**
- Vérifier les logs Flutter: `flutter logs`
- Vérifier les logs API: Dans le terminal du serveur PHP

---

### Test 3: Envoi d'un Premier Message

**Objectif:** Tester l'envoi de message

**Étapes:**
1. Dans l'écran de chat, taper un message dans le champ: "Bonjour, test du chat!"
2. Appuyer sur le bouton d'envoi (flèche)
3. Observer le résultat

**Résultat attendu:**
- ✅ Le message apparaît instantanément
- ✅ Le message est affiché à **droite** (bulle bleue)
- ✅ Votre nom/email apparaît au-dessus du message
- ✅ L'horodatage s'affiche
- ✅ Le champ de texte se vide automatiquement
- ✅ Le scroll va automatiquement vers le haut (dernier message)

**Vérification dans la BDD:**
```sql
SELECT * FROM list_messages ORDER BY created_at DESC LIMIT 5;
```

---

### Test 4: Réception de Message (Multi-utilisateur)

**Objectif:** Vérifier que les messages se synchronisent entre utilisateurs

**Prérequis:** 2 comptes avec accès à la même liste partagée

**Étapes:**
1. **Appareil/Compte 1:**
   - Ouvrir le chat de la liste partagée
   - Envoyer un message: "Message de l'utilisateur 1"

2. **Appareil/Compte 2:**
   - Ouvrir le chat de la même liste
   - Attendre 5 secondes (temps de polling)

**Résultat attendu sur Appareil 2:**
- ✅ Le message de l'utilisateur 1 apparaît automatiquement
- ✅ Le message est affiché à **gauche** (bulle grise)
- ✅ L'avatar avec les initiales de l'utilisateur 1 apparaît
- ✅ Le nom de l'utilisateur 1 s'affiche au-dessus

---

### Test 5: Conversation Bidirectionnelle

**Objectif:** Tester un échange de messages

**Étapes:**
1. **Utilisateur 1** envoie: "Peux-tu acheter du lait?"
2. **Utilisateur 2** envoie: "Oui, je m'en occupe!"
3. **Utilisateur 1** envoie: "Merci!"

**Résultat attendu:**
- ✅ Chaque utilisateur voit ses propres messages à droite (bleu)
- ✅ Chaque utilisateur voit les messages de l'autre à gauche (gris)
- ✅ L'ordre chronologique est respecté
- ✅ Les horodatages sont corrects

---

### Test 6: Pull-to-Refresh

**Objectif:** Tester l'actualisation manuelle

**Étapes:**
1. Dans l'écran de chat, tirer vers le bas (pull-to-refresh)
2. Observer l'animation de chargement

**Résultat attendu:**
- ✅ Indicateur de chargement s'affiche
- ✅ Les messages se rechargent
- ✅ Pas de duplication de messages

---

### Test 7: Suppression de Message

**Objectif:** Tester la suppression de son propre message

**Étapes:**
1. Envoyer un message de test: "Message à supprimer"
2. Faire un **appui long** sur ce message
3. Une boîte de dialogue apparaît demandant confirmation
4. Confirmer la suppression

**Résultat attendu:**
- ✅ Le message disparaît immédiatement
- ✅ Le message disparaît aussi pour les autres utilisateurs (après 5 sec)
- ✅ Pas de message d'erreur

**Vérification dans la BDD:**
```sql
SELECT * FROM list_messages WHERE message = 'Message à supprimer';
```
Le champ `deleted_at` devrait être rempli.

---

### Test 8: Tentative de Suppression d'un Message d'Autrui

**Objectif:** Vérifier qu'on ne peut supprimer que ses propres messages

**Étapes:**
1. Ouvrir le chat avec des messages d'autres utilisateurs
2. Essayer de faire un appui long sur le message d'un autre utilisateur

**Résultat attendu:**
- ✅ Aucune option de suppression n'apparaît
- OU
- ✅ Message d'erreur si on tente via l'API

---

### Test 9: Historique et Pagination

**Objectif:** Tester le chargement des anciens messages

**Prérequis:** Avoir plus de 50 messages dans la conversation

**Étapes:**
1. Ouvrir le chat
2. Scroller vers le bas pour voir les anciens messages

**Résultat attendu:**
- ✅ Les messages se chargent progressivement (pagination)
- ✅ Pas de ralentissement de l'app
- ✅ L'ordre chronologique est maintenu

---

### Test 10: Horodatages Intelligents

**Objectif:** Vérifier l'affichage des dates

**Étapes:**
1. Envoyer un message aujourd'hui
2. Vérifier l'horodatage affiché

**Résultat attendu:**
- Messages d'aujourd'hui: "14:30" (heure seulement)
- Messages d'hier: "Hier à 14:30"
- Messages plus anciens: "3 janvier à 14:30"

---

### Test 11: Gestion des Erreurs Réseau

**Objectif:** Tester le comportement hors ligne

**Étapes:**
1. Ouvrir le chat
2. Activer le mode avion
3. Essayer d'envoyer un message

**Résultat attendu:**
- ✅ Message d'erreur s'affiche
- ✅ L'app ne crash pas
- ✅ Quand la connexion revient, possibilité de réessayer

---

### Test 12: Permissions

**Objectif:** Vérifier que les permissions sont respectées

**Étapes:**
1. Essayer d'accéder au chat d'une liste partagée dont on n'est pas membre (via manipulation d'URL)

**Résultat attendu:**
- ✅ Erreur 403 Forbidden de l'API
- ✅ Message d'erreur dans l'app

---

## 📊 Checklist Complète

### Avant de déployer en production:

- [ ] ✅ Test 1: Visibilité du bouton validé
- [ ] ✅ Test 2: Navigation validée
- [ ] ✅ Test 3: Envoi de message validé
- [ ] ✅ Test 4: Réception de message validée
- [ ] ✅ Test 5: Conversation bidirectionnelle validée
- [ ] ✅ Test 6: Pull-to-refresh validé
- [ ] ✅ Test 7: Suppression de message validée
- [ ] ✅ Test 8: Protection suppression validée
- [ ] ✅ Test 9: Pagination validée
- [ ] ✅ Test 10: Horodatages validés
- [ ] ✅ Test 11: Gestion erreurs validée
- [ ] ✅ Test 12: Permissions validées

---

## 🐛 Résolution de Problèmes

### Problème: Le bouton de chat n'apparaît pas

**Causes possibles:**
1. La liste n'est pas partagée
2. L'état `shoppingList.isShared` n'est pas correctement défini

**Solution:**
- Vérifier dans la BDD: `SELECT * FROM shopping_lists WHERE id = X;`
- La colonne `is_shared` devrait être à `1`

### Problème: Erreur 404 sur les routes API

**Causes possibles:**
1. Les routes ne sont pas configurées
2. Le serveur PHP n'a pas été redémarré

**Solution:**
```bash
# Vérifier que les routes sont présentes
grep -n "MessageController" api/public/index.php

# Redémarrer le serveur PHP
pkill -f "php -S"
cd api/public
php -S localhost:8000
```

### Problème: Messages ne s'affichent pas

**Causes possibles:**
1. Problème de connexion API
2. Erreur dans le ChatService

**Solution:**
- Vérifier les logs: `flutter logs | grep Chat`
- Tester l'API directement avec curl:
```bash
curl -X GET "http://localhost:8000/api/lists/1/messages" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Problème: Erreur lors de l'envoi de message

**Causes possibles:**
1. Token JWT invalide
2. Permissions insuffisantes

**Solution:**
- Vérifier le token dans les logs
- Se reconnecter si nécessaire

---

## 📝 Commandes Utiles

### Vérifier les messages dans la BDD:
```sql
-- Voir tous les messages d'une liste
SELECT
  lm.*,
  u.name as user_name
FROM list_messages lm
JOIN users u ON lm.user_id = u.id
WHERE lm.list_id = 1
ORDER BY lm.created_at DESC;

-- Compter les messages
SELECT COUNT(*) FROM list_messages WHERE list_id = 1;

-- Voir les messages non lus
SELECT * FROM list_messages
WHERE list_id = 1 AND is_read = 0;
```

### Tester l'API avec curl:
```bash
# Obtenir un token
TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password"}' \
  | jq -r '.data.access_token')

# Obtenir les messages
curl -X GET "http://localhost:8000/api/lists/1/messages" \
  -H "Authorization: Bearer $TOKEN"

# Envoyer un message
curl -X POST "http://localhost:8000/api/lists/1/messages" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message":"Test depuis curl","message_type":"text"}'
```

---

## 🎉 Validation Finale

Une fois tous les tests passés:

✅ **Le système de chat est fonctionnel à 100%**

Vous pouvez maintenant:
1. Déployer en production
2. Informer les utilisateurs de la nouvelle fonctionnalité
3. Surveiller les logs pour détecter d'éventuels problèmes

---

**Version de test:** 1.0
**Date:** Novembre 2025
**Statut:** Prêt pour tests utilisateurs
