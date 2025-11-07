# 🎯 Système d'Analyse des Habitudes - Résumé Exécutif

## ✅ Ce qui a été mis en place

### 1. Service d'Analyse Intelligent
**Fichier:** `/api/src/Services/UserHabitAnalysisService.php`

**Fonctionnalités:**
- ✅ Analyse automatique des 90 derniers jours de listes
- ✅ Détection de 5 patterns différents (daily, weekly, biweekly, irregular, inactive)
- ✅ Calcul de confiance basé sur la variance des intervalles
- ✅ Détection du jour préféré pour les patterns hebdomadaires
- ✅ Prédiction de la prochaine date attendue
- ✅ Décision intelligente pour envoyer ou non une notification

### 2. Intégration au Cron
**Fichier:** `/api/public/cron.php`

**Schedule:**
```
Tous les jours à 10h00 → Analyse des habitudes + notifications
Dimanche à 2h00 → Nettoyage des anciennes analyses
```

### 3. Messages Personnalisés

**Selon la fréquence détectée:**

| Type | Message Exemple |
|------|----------------|
| Daily | "D'habitude, vous créez une liste tous les 2-3 jours. Cela fait 3 jour(s), prêt ?" |
| Weekly | "C'est lundi ! D'habitude, vous créez votre liste ce jour-là. Prêt pour vos courses ?" |
| Biweekly | "D'habitude, vous faites vos courses toutes les 2 semaines. C'est le moment !" |
| Irregular | ❌ Aucune notification (pour éviter le spam) |

## 🧪 Comment Tester

### Test d'un utilisateur spécifique
```bash
cd /Users/mohamedahmedabdoulaye/Documents/mes-projets/epilist/api

# Analyser sans envoyer
php test_habit_analysis.php 123 analyze

# Analyser ET envoyer notification
php test_habit_analysis.php 123 notify

# Voir l'analyse sauvegardée
php test_habit_analysis.php 123 stored
```

### Test de tous les utilisateurs
```bash
php test_habit_analysis.php all all
```

## 📊 Exemple de Résultat

```json
{
  "user_id": 123,
  "frequency": "weekly",
  "pattern": "weekly_shopper",
  "confidence": 95,
  "preferred_day": 1,
  "average_interval_days": 7.2,
  "last_list_date": "2025-01-29",
  "days_since_last_list": 6,
  "next_expected_date": "2025-02-05",
  "should_notify": true,
  "total_lists_90d": 12
}
```

## 🎯 Algorithme de Détection

### Frequency Types & Critères

```
DAILY (Quotidien):
  ├─ Intervalle moyen ≤ 3 jours
  ├─ Variance < 50%
  └─ Notification: Si 2+ jours sans liste

WEEKLY (Hebdomadaire):
  ├─ Intervalle moyen: 6-9 jours
  ├─ Variance < 40%
  ├─ Détecte le jour préféré (≥30% des listes)
  └─ Notification: Le jour habituel OU 1 jour après

BIWEEKLY (Bi-hebdomadaire):
  ├─ Intervalle moyen: 10-18 jours
  ├─ Variance < 40%
  └─ Notification: ~14 jours après dernière liste

IRREGULAR (Irrégulier):
  ├─ Variance élevée (≥40%)
  └─ ❌ Aucune notification automatique

INACTIVE (Inactif):
  ├─ Aucune liste dans les 90 derniers jours
  └─ Géré par système d'inactivité existant
```

## 🔔 Existing Cron vs New System

### Avant (Existant)
```
Vendredi 19h → Rappel TOUS les utilisateurs sans liste cette semaine
Mardi 10h   → Rappel TOUS les utilisateurs inactifs 2+ semaines
```
**Problème:** Timing arbitraire, peut spammer certains utilisateurs

### Après (Nouveau)
```
Tous les jours 10h → Rappel UNIQUEMENT les utilisateurs dont c'est "le moment"
```
**Avantage:** Personnalisé, respecte les habitudes de chacun

## 📁 Fichiers Créés/Modifiés

### Nouveaux Fichiers
1. `/api/src/Services/UserHabitAnalysisService.php` - Service principal
2. `/api/test_habit_analysis.php` - Script de test
3. `/api/HABIT_ANALYSIS_SYSTEM.md` - Documentation complète
4. `/HABIT_SYSTEM_SUMMARY.md` - Ce fichier

### Fichiers Modifiés
1. `/api/public/cron.php` - Ajout de l'analyse des habitudes (ligne 85-88)

### Fichiers Générés Automatiquement
- `/api/storage/user_habit_{userId}.json` - Analyses sauvegardées
- `/api/storage/habit_analysis_{date}.lock` - Verrous quotidiens

## 🛡️ Protection Anti-Spam

### Mécanismes en Place
1. **Cooldown par fréquence:**
   - Daily: Min 1 jour entre notifications
   - Weekly: Min 6 jours entre notifications
   - Biweekly: Min 13 jours entre notifications

2. **Lock file quotidien:**
   - Une seule analyse par jour maximum

3. **Pas de spam pour irregular:**
   - Utilisateurs sans pattern = aucune notification

4. **Cache des analyses:**
   - Réutilisé pendant 7 jours
   - Évite les calculs répétés

## 📈 Métriques de Succès

### Indicateurs à Suivre
- **Taux de réponse:** % d'utilisateurs qui créent une liste après notification
- **Faux positifs:** % de notifications envoyées trop tôt/tard
- **Opt-out:** % d'utilisateurs qui désactivent les notifications
- **Precision:** Écart entre date prédite et date réelle

### Logs à Surveiller
```bash
# Voir l'exécution quotidienne
tail -f /var/log/epilist_cron.log | grep "habit analysis"

# Exemple de log
📊 Analyzing habits for user 123 (user@email.com)
  Found 15 lists in last 90 days
  Intervals: [7, 7, 6, 8, 7, 7, 7]
  Avg interval: 7.1 days, StdDev: 0.6, Variance: 8.4%
  Preferred day: lundi (12 lists)
  ✅ Sent reminder to user 123 (weekly)
```

## 🔮 Prochaines Étapes Possibles

### Phase 2 (Optionnel)
1. **Dashboard Admin:**
   - Voir les patterns de tous les utilisateurs
   - Statistiques globales (X% daily, Y% weekly, etc.)

2. **Préférences Utilisateur:**
   - Permettre de choisir son jour préféré
   - Option "Ne plus me rappeler"

3. **Machine Learning:**
   - Prédire en fonction de la météo, jours fériés
   - Améliorer la précision avec plus de données

4. **A/B Testing:**
   - Tester différents messages
   - Optimiser les heures d'envoi

## ✅ Checklist de Vérification

- [x] Service UserHabitAnalysisService créé
- [x] Intégration au cron.php
- [x] Protection anti-spam
- [x] Cache des analyses
- [x] Nettoyage automatique
- [x] Messages personnalisés
- [x] Script de test
- [x] Documentation complète
- [ ] Test avec utilisateurs réels
- [ ] Monitoring en production

## 🎉 Conclusion

Le système est **prêt à être testé**. Il fonctionne en complément des notifications existantes et respecte les habitudes individuelles de chaque utilisateur pour éviter le spam.

**Pour démarrer:**
1. Tester avec quelques utilisateurs: `php test_habit_analysis.php <user_id> notify`
2. Vérifier les logs après le cron du lendemain à 10h
3. Ajuster les paramètres si nécessaire (intervalles, variance)

---

**Date:** 2025-02-04
**Status:** ✅ Prêt pour tests
**Version:** 1.0
