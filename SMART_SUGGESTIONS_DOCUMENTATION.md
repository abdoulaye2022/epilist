# Documentation: Système de Suggestions Intelligentes

## Table des Matières

1. [Vue d'ensemble](#vue-densemble)
2. [Architecture](#architecture)
3. [Algorithmes de Suggestions](#algorithmes-de-suggestions)
4. [Installation et Configuration](#installation-et-configuration)
5. [Utilisation](#utilisation)
6. [API Endpoints](#api-endpoints)
7. [Interface Utilisateur](#interface-utilisateur)
8. [Optimisation et Performance](#optimisation-et-performance)
9. [Dépannage](#dépannage)

---

## Vue d'ensemble

Le système de suggestions intelligentes d'EpiList analyse automatiquement l'historique d'achats des utilisateurs pour leur proposer des produits qu'ils pourraient avoir besoin d'acheter.

### Fonctionnalités Principales

- **Suggestions basées sur les habitudes** : Analyse la fréquence et la régularité des achats
- **Suggestions saisonnières** : Détecte les produits achetés pendant des périodes spécifiques
- **Suggestions par association** : Recommande des produits souvent achetés ensemble
- **Suggestions tendances** : Affiche les produits populaires récemment
- **Score de confiance** : Chaque suggestion a un niveau de confiance (faible, moyen, élevé)
- **Feedback loop** : Le système s'améliore avec les actions de l'utilisateur

### Technologies Utilisées

**Backend:**
- PHP 8+ avec Eloquent ORM
- MySQL avec triggers et stored procedures
- Algorithmes de pattern matching et collaborative filtering

**Frontend:**
- Flutter / Dart
- BLoC pour la gestion d'état
- Material Design 3

---

## Architecture

### Schéma de Base de Données

#### 1. Table `purchase_history`
Enregistre automatiquement tous les achats via un trigger SQL.

```sql
CREATE TABLE purchase_history (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    normalized_name VARCHAR(255) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    price DECIMAL(10, 2),
    category_id INT UNSIGNED,
    purchased_at DATETIME NOT NULL,
    list_id INT UNSIGNED,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_product (user_id, normalized_name),
    INDEX idx_purchased_at (purchased_at)
);
```

**Remplissage automatique** : Le trigger `after_item_purchased` s'exécute automatiquement quand un article est marqué comme acheté.

#### 2. Table `user_purchase_patterns`
Stocke les habitudes d'achat calculées pour chaque utilisateur.

```sql
CREATE TABLE user_purchase_patterns (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    normalized_name VARCHAR(255) NOT NULL,
    purchase_count INT NOT NULL DEFAULT 0,
    avg_quantity INT NOT NULL DEFAULT 1,
    avg_price DECIMAL(10, 2),
    preferred_category_id INT UNSIGNED,
    last_purchased_at DATETIME,
    next_suggested_date DATE,
    frequency_score DECIMAL(5, 2) DEFAULT 0,
    recency_score DECIMAL(5, 2) DEFAULT 0,
    regularity_score DECIMAL(5, 2) DEFAULT 0,
    UNIQUE KEY unique_user_product (user_id, normalized_name)
);
```

**Calcul** : La procédure stockée `calculate_purchase_patterns()` recalcule ces patterns périodiquement.

#### 3. Table `product_associations`
Identifie les produits souvent achetés ensemble.

```sql
CREATE TABLE product_associations (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    product_a VARCHAR(255) NOT NULL,
    product_b VARCHAR(255) NOT NULL,
    times_bought_together INT NOT NULL DEFAULT 1,
    confidence_score DECIMAL(5, 2),
    last_associated_at DATETIME,
    UNIQUE KEY unique_association (user_id, product_a, product_b)
);
```

#### 4. Table `suggestion_feedback`
Enregistre les réactions des utilisateurs aux suggestions.

```sql
CREATE TABLE suggestion_feedback (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    action ENUM('accepted', 'rejected', 'modified') NOT NULL,
    suggested_quantity INT,
    actual_quantity INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

---

## Algorithmes de Suggestions

### 1. Suggestions Basées sur les Habitudes (Pattern-Based)

Cet algorithme analyse trois dimensions :

```php
public function getSuggestionScore(): float
{
    return ($this->frequency_score * 0.4) +
           ($this->recency_score * 0.35) +
           ($this->regularity_score * 0.25);
}
```

#### Calcul du Frequency Score
Plus le produit est acheté souvent, plus le score est élevé.

```php
$frequencyScore = min(100, ($purchaseCount / $maxPurchases) * 100);
```

#### Calcul du Recency Score
Les achats récents ont un score plus élevé.

```php
$daysSinceLastPurchase = $today->diffInDays($lastPurchased);
$recencyScore = max(0, 100 - ($daysSinceLastPurchase * 2));
```

#### Calcul du Regularity Score
Mesure la régularité des achats (achetez-vous toujours le lait le samedi ?).

```php
$coefficient = $stdDev / $avgDaysBetween;
$regularityScore = max(0, 100 - ($coefficient * 50));
```

#### Prédiction de la Prochaine Date d'Achat

```php
$nextSuggestedDate = $lastPurchased->addDays($avgDaysBetween);
```

Le système suggère le produit dans une fenêtre de ±2 jours autour de cette date.

### 2. Suggestions Saisonnières (Seasonal)

Détecte les produits achetés pendant des mois spécifiques.

```php
$seasonalProducts = PurchaseHistory::where('user_id', $userId)
    ->selectRaw('
        product_name,
        MONTH(purchased_at) as purchase_month,
        COUNT(*) as purchase_count
    ')
    ->groupBy('product_name', 'purchase_month')
    ->having('purchase_count', '>=', 3)
    ->get();
```

**Exemple** : Si vous achetez des décorations en décembre chaque année, le système vous les suggérera en novembre/décembre.

### 3. Suggestions par Association (Association-Based)

Utilise un algorithme de collaborative filtering simplifié.

```php
$confidence = ($timesBoughtTogether / $totalTimesProductABought) * 100;
```

**Exemple** : Si vous achetez du pain 10 fois, et 8 fois vous achetez aussi du beurre, la confiance est de 80%.

### 4. Suggestions Tendances (Trending)

Produits populaires achetés récemment (30 derniers jours).

```sql
SELECT product_name, COUNT(*) as purchase_count
FROM purchase_history
WHERE purchased_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY product_name
ORDER BY purchase_count DESC
LIMIT 10;
```

---

## Installation et Configuration

### 1. Installation Backend

#### Exécuter la Migration

```bash
cd api
mysql -u root -p epilist < migrations/add_smart_suggestions.sql
```

Cette migration créera :
- 4 tables
- 1 fonction SQL `normalize_product_name()`
- 1 trigger `after_item_purchased`
- 1 procédure stockée `calculate_purchase_patterns()`

#### Vérifier l'Installation

```bash
php -r "require 'vendor/autoload.php'; \
use App\Models\PurchaseHistory; \
echo PurchaseHistory::count() . ' purchases recorded';"
```

#### Configuration du Cron Job

Ajoutez cette ligne au crontab pour recalculer les patterns quotidiennement :

```bash
0 2 * * * cd /path/to/api && php -r "require 'vendor/autoload.php'; \
use App\Services\SmartSuggestionService; \
\$service = new SmartSuggestionService(); \
\$service->recalculateAllPatterns();"
```

### 2. Installation Frontend

#### Ajouter le BLoC Provider

Dans `main.dart` :

```dart
MultiBlocProvider(
  providers: [
    // ... autres providers
    BlocProvider(
      create: (context) => SuggestionBloc(
        suggestionService: SuggestionService(dio: dio),
      ),
    ),
  ],
  child: MyApp(),
)
```

#### Intégrer dans l'UI

Dans n'importe quel écran :

```dart
import 'package:epilist/widgets/suggestions/smart_suggestions_widget.dart';

SmartSuggestionsWidget(
  currencySymbol: '€',
  onSuggestionSelected: (suggestion) {
    // Remplir automatiquement le formulaire
    productController.text = suggestion.productName;
    quantityController.text = suggestion.suggestedQuantity.toString();
    if (suggestion.avgPrice != null) {
      priceController.text = suggestion.avgPrice.toString();
    }
  },
  currentListItems: ['Lait', 'Pain'], // Articles déjà dans la liste
  maxSuggestions: 3,
)
```

---

## Utilisation

### Pour les Utilisateurs

#### 1. Lors de l'Ajout d'un Article

Quand vous ouvrez le dialogue "Ajouter un article", vous verrez automatiquement :

```
┌─────────────────────────────────────┐
│ ✨ Suggestions Intelligentes     3 │
├─────────────────────────────────────┤
│ ║ Lait                              │
│ ║ Vous achetez régulièrement     [+]│
├─────────────────────────────────────┤
```

Cliquez sur [+] pour ajouter instantanément le produit avec la quantité et le prix suggérés.

#### 2. Niveaux de Confiance

- 🟢 **Vert (Élevé)** : Score ≥ 70% - Fortement recommandé
- 🟠 **Orange (Moyen)** : Score ≥ 40% - Bonne correspondance
- ⚫ **Gris (Faible)** : Score < 40% - Pourrait vous plaire

#### 3. Badges Spéciaux

- **⏰ À acheter bientôt** : Produits dont la date d'achat prévue approche (±2 jours)
- **🔥 Tendance** : Produits populaires en ce moment

### Pour les Développeurs

#### Charger les Suggestions

```dart
context.read<SuggestionBloc>().add(
  LoadSuggestions(
    includeAssociations: true,
    currentListItems: ['Lait', 'Pain'],
  ),
);
```

#### Écouter les États

```dart
BlocBuilder<SuggestionBloc, SuggestionState>(
  builder: (context, state) {
    if (state is SuggestionLoaded) {
      return ListView(
        children: state.highConfidence.map((suggestion) {
          return ListTile(
            title: Text(suggestion.productName),
            subtitle: Text(suggestion.reason),
            trailing: Text('${suggestion.confidenceScore}%'),
          );
        }).toList(),
      );
    }
    return CircularProgressIndicator();
  },
)
```

#### Enregistrer le Feedback

```dart
// Acceptation
context.read<SuggestionBloc>().add(
  AcceptSuggestion('Lait', 2),
);

// Rejet
context.read<SuggestionBloc>().add(
  RejectSuggestion('Fromage'),
);

// Modification
context.read<SuggestionBloc>().add(
  ModifySuggestion('Pain', 1, 2), // suggéré: 1, acheté: 2
);
```

---

## API Endpoints

### 1. GET `/api/suggestions`

Récupère les suggestions personnalisées pour l'utilisateur connecté.

**Paramètres Query:**
```
- limit (int, défaut: 10) : Nombre maximum de suggestions
- include_associations (bool, défaut: true) : Inclure les suggestions par association
- current_items (string) : Liste des produits séparés par virgule (pour associations)
```

**Exemple:**
```bash
curl -X GET "http://localhost:8000/api/suggestions?limit=5&current_items=Lait,Pain" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Réponse:**
```json
{
  "success": true,
  "data": {
    "suggestions": [
      {
        "product_name": "Lait",
        "suggested_quantity": 2,
        "avg_price": 1.50,
        "preferred_store": null,
        "category_id": 5,
        "confidence_score": 85.5,
        "last_purchased": "2025-10-28",
        "should_buy_soon": true,
        "reason": "Vous achetez régulièrement (tous les 7 jours)",
        "type": "pattern",
        "based_on": "10 achats précédents"
      },
      {
        "product_name": "Beurre",
        "suggested_quantity": 1,
        "confidence_score": 75.0,
        "reason": "Souvent acheté avec Pain (8 fois sur 10)",
        "type": "association"
      }
    ],
    "count": 2
  }
}
```

### 2. GET `/api/suggestions/product`

Obtient une suggestion pour un produit spécifique.

**Paramètres Query:**
```
- product_name (string, requis) : Nom du produit
```

**Exemple:**
```bash
curl -X GET "http://localhost:8000/api/suggestions/product?product_name=Lait" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Réponse:**
```json
{
  "success": true,
  "data": {
    "product_name": "Lait",
    "suggested_quantity": 2,
    "suggested_price": 1.50,
    "last_purchased": "2025-10-28",
    "purchase_frequency_days": 7
  }
}
```

### 3. POST `/api/suggestions/feedback`

Enregistre le feedback de l'utilisateur sur une suggestion.

**Body:**
```json
{
  "product_name": "Lait",
  "action": "accepted",
  "suggested_quantity": 2,
  "actual_quantity": 2
}
```

**Actions possibles:** `accepted`, `rejected`, `modified`

**Réponse:**
```json
{
  "success": true,
  "message": "Feedback enregistré avec succès"
}
```

### 4. POST `/api/suggestions/recalculate`

Force le recalcul des patterns d'achat (admin uniquement).

**Réponse:**
```json
{
  "success": true,
  "message": "Patterns recalculés avec succès",
  "data": {
    "patterns_updated": 150,
    "processing_time_seconds": 2.5
  }
}
```

### 5. GET `/api/suggestions/stats`

Récupère les statistiques de suggestions pour l'utilisateur.

**Réponse:**
```json
{
  "success": true,
  "data": {
    "total_purchases": 250,
    "unique_products": 75,
    "active_patterns": 45,
    "suggestion_acceptance_rate": 0.65,
    "feedback": {
      "accepted": 120,
      "rejected": 30,
      "modified": 15
    }
  }
}
```

### 6. GET `/api/suggestions/trending`

Récupère les produits tendances (populaires récemment).

**Paramètres Query:**
```
- limit (int, défaut: 10) : Nombre de produits
```

**Réponse:**
```json
{
  "success": true,
  "data": {
    "trending": [
      {
        "product_name": "Masques",
        "purchase_count": 45,
        "trend_period": "30 jours"
      }
    ]
  }
}
```

---

## Interface Utilisateur

### Widgets Disponibles

#### 1. `SmartSuggestionsWidget`

Widget compact pour les dialogues et espaces restreints.

```dart
SmartSuggestionsWidget(
  currencySymbol: '€',
  onSuggestionSelected: (suggestion) {
    print('Sélectionné: ${suggestion.productName}');
  },
  currentListItems: ['Lait'],
  maxSuggestions: 3,
)
```

**Caractéristiques:**
- Affichage réduit/étendu (collapse/expand)
- Maximum 3 suggestions par défaut
- Badges de confiance colorés
- Indicateur "À acheter bientôt"

#### 2. `SuggestionList`

Liste complète avec pull-to-refresh et groupement par confiance.

```dart
SuggestionList(
  currencySymbol: '€',
  onSuggestionAccepted: (suggestion) {
    print('Accepté: ${suggestion.productName}');
  },
)
```

**Caractéristiques:**
- Groupement par niveau de confiance
- Pull-to-refresh
- Dialogue d'information sur les suggestions
- Boutons d'action (Accepter/Rejeter)

#### 3. `SuggestionCard`

Carte individuelle pour afficher une suggestion.

```dart
SuggestionCard(
  suggestion: SmartSuggestion(...),
  currencySymbol: '€',
  onAccept: () { },
  onReject: () { },
)
```

### Personnalisation du Thème

```dart
// Couleurs des niveaux de confiance
final confidenceColors = {
  ConfidenceLevel.high: Colors.green,
  ConfidenceLevel.medium: Colors.orange,
  ConfidenceLevel.low: Colors.grey,
};

// Style des cartes
Card(
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(
      color: theme.colorScheme.primary.withOpacity(0.3),
      width: 1.5,
    ),
  ),
)
```

---

## Optimisation et Performance

### 1. Indexation Base de Données

Vérifiez que ces index existent :

```sql
-- Index sur purchase_history
CREATE INDEX idx_user_product ON purchase_history(user_id, normalized_name);
CREATE INDEX idx_purchased_at ON purchase_history(purchased_at);

-- Index sur user_purchase_patterns
CREATE INDEX idx_next_suggested ON user_purchase_patterns(user_id, next_suggested_date);
CREATE INDEX idx_scores ON user_purchase_patterns(user_id, frequency_score DESC);
```

### 2. Caching

Le service utilise un cache simple pour éviter les recalculs fréquents :

```php
private static $patternCache = [];

public function getPatternsCached($userId) {
    if (!isset(self::$patternCache[$userId])) {
        self::$patternCache[$userId] = $this->getPatterns($userId);
    }
    return self::$patternCache[$userId];
}
```

### 3. Pagination

Limitez toujours le nombre de suggestions :

```php
$suggestions = $this->getSuggestionsForUser($userId, ['limit' => 10]);
```

### 4. Traitement Asynchrone

Pour de grandes quantités de données, utilisez un worker :

```bash
# Recalcul en arrière-plan
php artisan queue:work &
```

### 5. Optimisation Flutter

```dart
// Utiliser const constructors
const SmartSuggestionsWidget(...)

// Éviter les rebuilds inutiles
class SuggestionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use keys for list items
    return Card(key: ValueKey(suggestion.productName), ...);
  }
}
```

---

## Dépannage

### Problème : Aucune Suggestion n'Apparaît

**Cause possible 1** : Pas assez de données historiques

```sql
-- Vérifier le nombre d'achats
SELECT COUNT(*) FROM purchase_history WHERE user_id = 1;
```

**Solution** : Il faut au moins 3-5 achats pour générer des suggestions.

**Cause possible 2** : Patterns non calculés

```sql
-- Vérifier les patterns
SELECT COUNT(*) FROM user_purchase_patterns WHERE user_id = 1;
```

**Solution** : Exécuter manuellement :

```bash
php -r "require 'vendor/autoload.php'; \
use App\Services\SmartSuggestionService; \
\$service = new SmartSuggestionService(); \
\$service->recalculatePatternsForUser(1);"
```

**Cause possible 3** : Trigger non actif

```sql
-- Vérifier le trigger
SHOW TRIGGERS LIKE 'list_items';
```

**Solution** : Réexécuter la migration.

### Problème : Scores de Confiance Toujours Faibles

**Cause** : Pas assez de régularité dans les achats

**Solution** : Ajuster les poids de l'algorithme dans `SmartSuggestionService.php` :

```php
// Privilégier la fréquence sur la régularité
public function getSuggestionScore(): float
{
    return ($this->frequency_score * 0.6) +  // augmenté
           ($this->recency_score * 0.3) +
           ($this->regularity_score * 0.1);  // réduit
}
```

### Problème : Suggestions Incorrectes

**Cause** : Normalisation de texte défaillante

```sql
-- Vérifier la normalisation
SELECT product_name, normalized_name
FROM purchase_history
WHERE user_id = 1;
```

**Solution** : Améliorer la fonction `normalize_product_name()` :

```sql
CREATE FUNCTION normalize_product_name(name VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE normalized VARCHAR(255);
    SET normalized = LOWER(TRIM(name));
    -- Retirer accents
    SET normalized = REPLACE(normalized, 'é', 'e');
    SET normalized = REPLACE(normalized, 'è', 'e');
    -- Retirer pluriels
    IF RIGHT(normalized, 1) = 's' THEN
        SET normalized = LEFT(normalized, LENGTH(normalized) - 1);
    END IF;
    RETURN normalized;
END;
```

### Problème : Performance Dégradée

**Diagnostic** :

```sql
-- Temps de requête
SET profiling = 1;
CALL calculate_purchase_patterns(1);
SHOW PROFILES;
```

**Solution** : Optimiser avec `EXPLAIN` :

```sql
EXPLAIN SELECT * FROM user_purchase_patterns
WHERE user_id = 1 AND frequency_score >= 50;
```

Ajouter des index si nécessaire.

### Problème : Widget Flutter Ne S'Affiche Pas

**Diagnostic** :

```dart
BlocBuilder<SuggestionBloc, SuggestionState>(
  builder: (context, state) {
    print('Current state: ${state.runtimeType}');
    // ...
  },
)
```

**Solution** : Vérifier que le BLoC est bien fourni :

```dart
// Dans main.dart
BlocProvider(
  create: (context) => SuggestionBloc(
    suggestionService: context.read<SuggestionService>(),
  ),
)
```

---

## Prochaines Améliorations

### Fonctionnalités Futures

1. **Machine Learning Avancé**
   - Utiliser TensorFlow pour des prédictions plus précises
   - Clustering de produits similaires
   - Détection d'anomalies dans les habitudes d'achat

2. **Suggestions Contextuelles**
   - Suggestions basées sur la météo (BBQ si soleil)
   - Suggestions basées sur les événements (fêtes, vacances)
   - Suggestions basées sur la localisation

3. **Partage de Suggestions**
   - Suggestions partagées dans une famille/groupe
   - Templates de listes recommandées

4. **Analytics Avancés**
   - Dashboard de visualisation des habitudes
   - Rapport mensuel d'économies réalisées
   - Comparaison avec d'autres utilisateurs (anonymisé)

---

## Conclusion

Le système de suggestions intelligentes d'EpiList combine des algorithmes éprouvés (pattern matching, collaborative filtering) avec une architecture moderne (BLoC, triggers SQL) pour offrir une expérience utilisateur fluide et personnalisée.

Pour toute question ou contribution, consultez le dépôt GitHub du projet.

**Version:** 1.0.0
**Dernière mise à jour:** Novembre 2025
**Auteur:** Équipe EpiList
