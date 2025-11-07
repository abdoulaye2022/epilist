# 🎯 Système d'Analyse des Habitudes et Notifications Intelligentes - EpiList

## 📋 Vue d'ensemble

Ce système analyse automatiquement les habitudes de création de listes de courses des utilisateurs et envoie des notifications personnalisées au moment optimal basé sur leurs comportements passés.

## 🧠 Intelligence du Système

### Détection Automatique des Fréquences

Le système identifie 5 types de comportements:

1. **DAILY** (Quotidien) 🌅
   - Utilisateur crée une liste tous les 2-3 jours
   - Intervalle moyen: ≤ 3 jours
   - Variance: < 50%
   - Notification envoyée: 2+ jours sans liste

2. **WEEKLY** (Hebdomadaire) 📅
   - Utilisateur crée une liste chaque semaine
   - Intervalle moyen: 6-9 jours
   - Variance: < 40%
   - Détecte le jour préféré de la semaine
   - Notification envoyée: Le jour habituel OU 1 jour après

3. **BIWEEKLY** (Bi-hebdomadaire) 📆
   - Utilisateur crée une liste toutes les 2 semaines
   - Intervalle moyen: 10-18 jours
   - Variance: < 40%
   - Notification envoyée: ~14 jours après la dernière liste

4. **IRREGULAR** (Irrégulier) 🔀
   - Pas de pattern clair détecté
   - Variance élevée (> 40%)
   - **Aucune notification automatique** (pour éviter le spam)

5. **INACTIVE** (Inactif) 💤
   - Aucune liste créée dans les 90 derniers jours
   - Traité par le système d'inactivité existant

## 📊 Algorithme d'Analyse

### Étapes de l'Analyse

```
1. Récupérer les listes des 90 derniers jours
2. Calculer les intervalles entre chaque liste
3. Calculer moyenne et écart-type des intervalles
4. Déterminer la fréquence selon:
   - Intervalle moyen
   - Coefficient de variation (variance)
5. Si pattern hebdomadaire/bi-hebdomadaire:
   - Détecter le jour préféré (≥30% des listes)
6. Calculer la date attendue de la prochaine liste
7. Décider si notification nécessaire
```

### Exemple de Calcul

**Utilisateur avec listes:**
- 01/01: Liste #1
- 08/01: Liste #2 (7 jours)
- 15/01: Liste #3 (7 jours)
- 22/01: Liste #4 (7 jours)
- 29/01: Liste #5 (7 jours)

**Résultat:**
- Intervalle moyen: 7 jours
- Écart-type: 0
- Variance: 0%
- **Pattern détecté: WEEKLY** ✅
- Jour préféré: Lundi (5/5 listes = 100%)
- Confiance: 100%

## 🔔 Messages Personnalisés

### Exemples de Notifications

#### Daily Shopper
```
🛒 Votre liste quotidienne
D'habitude, vous créez une liste tous les 2-3 jours.
Cela fait 3 jour(s), prêt pour vos courses ?
```

#### Weekly Shopper (avec jour préféré)
```
🛒 Votre liste de la semaine
C'est lundi ! D'habitude, vous créez votre liste ce jour-là.
Prêt pour vos courses hebdomadaires ?
```

#### Biweekly Shopper
```
🛒 Votre liste bi-hebdomadaire
D'habitude, vous faites vos courses toutes les 2 semaines.
C'est le moment de créer votre liste !
```

## ⚙️ Configuration du Cron

### Schedule Actuel

```bash
# Cron s'exécute toutes les heures
# L'analyse des habitudes se fait à 10h chaque jour

Heure 10:00 → Analyse des habitudes + notifications intelligentes
```

### Fichiers Concernés

1. **Service Principal:**
   ```
   /api/src/Services/UserHabitAnalysisService.php
   ```

2. **Intégration Cron:**
   ```
   /api/public/cron.php (ligne 85-88)
   ```

3. **Stockage des Analyses:**
   ```
   /api/storage/user_habit_{userId}.json
   ```

## 📁 Structure des Données Sauvegardées

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
  "total_lists_90d": 12,
  "analyzed_at": "2025-02-04T10:00:00+00:00"
}
```

## 🛡️ Protection Anti-Spam

### Cooldowns

- **Daily:** Minimum 1 jour entre notifications
- **Weekly:** Minimum 6 jours entre notifications
- **Biweekly:** Minimum 13 jours entre notifications
- **Lock File:** Une seule analyse par jour maximum

### Verrous

```
/api/storage/habit_analysis_2025-02-04.lock
```

## 🧹 Nettoyage Automatique

Le système nettoie automatiquement:

1. **Analyses d'habitudes:**
   - Fichiers > 30 jours supprimés
   - Exécution: Dimanche 2h00

2. **Lock files:**
   - Fichiers > 7 jours supprimés
   - Exécution: Dimanche 2h00

## 📈 Métriques & Monitoring

### Logs Disponibles

```bash
# Voir les logs d'analyse
tail -f /var/log/epilist_cron.log | grep "Analyzing habits"

# Résultat d'une analyse
📊 Analyzing habits for user 123 (user@email.com)
  Found 15 lists in last 90 days
  Intervals: [7, 7, 6, 8, 7, 7, 7, ...]
  Avg interval: 7.1 days, StdDev: 0.6, Variance: 8.4%
  Preferred day: lundi (12 lists)
  Analysis result: {"frequency":"weekly","confidence":92}
  ✅ Sent reminder to user 123 (weekly)
```

### Indicateurs de Performance

- **Analyzed:** Nombre d'utilisateurs analysés
- **Notifications sent:** Nombre de rappels envoyés
- **Errors:** Erreurs rencontrées

## 🔧 Utilisation Manuelle

### Analyser un Utilisateur Spécifique

```php
use App\Services\UserHabitAnalysisService;
use App\Models\User;

$habitService = new UserHabitAnalysisService();
$user = User::find(123);

// Analyser
$analysis = $habitService->analyzeUserHabits($user);
print_r($analysis);

// Envoyer notification si nécessaire
if ($analysis['should_notify']) {
    $sent = $habitService->sendHabitBasedReminder($user, $analysis);
}
```

### Récupérer l'Analyse Sauvegardée

```php
$storedAnalysis = $habitService->getStoredHabitAnalysis(123);

if ($storedAnalysis) {
    echo "User frequency: " . $storedAnalysis['frequency'];
    echo "Confidence: " . $storedAnalysis['confidence'] . "%";
}
```

## 🎯 Avantages du Système

### 1. Personnalisation
- Chaque utilisateur reçoit des notifications adaptées à SES habitudes
- Pas de timing arbitraire "tous les vendredis à 19h"

### 2. Non-Intrusif
- Utilisateurs irréguliers = **aucun spam**
- Utilisateurs réguliers = rappel au bon moment

### 3. Auto-Apprenant
- S'adapte si l'utilisateur change ses habitudes
- Réanalyse tous les 7 jours maximum

### 4. Économie de Ressources
- Un seul cron par jour (10h)
- Cache des analyses (réutilisable dans l'app)

## 🔮 Évolutions Futures Possibles

1. **Machine Learning:**
   - Prédiction basée sur l'historique + jours fériés + saisons

2. **Contexte Externe:**
   - Intégrer météo (plus de courses si neige prévue)
   - Événements (Black Friday, Noël)

3. **Préférences Utilisateur:**
   - Permettre à l'utilisateur de choisir son jour préféré
   - Option "Ne plus me rappeler"

4. **A/B Testing:**
   - Tester différents messages
   - Optimiser les heures d'envoi

## 📞 Support

Pour toute question sur ce système:
- Consulter les logs: `/var/log/epilist_cron.log`
- Vérifier le stockage: `/api/storage/user_habit_*.json`
- Tester manuellement avec la fonction `forceTestAnalysis(userId)`

---

**Créé le:** 2025-02-04
**Auteur:** Claude Code
**Version:** 1.0
