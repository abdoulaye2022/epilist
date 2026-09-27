// services/category_guesser.dart
//
// Devine la catégorie d'un article à partir de son nom (dictionnaire
// mot-clé -> catégorie par défaut) ou des tags Open Food Facts d'un scan.
// 100 % local : aucune dépendance réseau, fonctionne hors ligne.
//
// La suggestion n'est jamais imposée : elle ne s'applique que si
// l'utilisateur n'a pas choisi de catégorie lui-même, et reste modifiable.

import 'package:epilist/models/category.dart';

class CategoryGuesser {
  // Noms EXACTS des 12 catégories créées par POST /categories/initialize-defaults.
  static const String fruitsLegumes = 'Fruits & Légumes';
  static const String viandesPoissons = 'Viandes & Poissons';
  static const String produitsLaitiers = 'Produits laitiers';
  static const String boulangerie = 'Boulangerie';
  static const String boissons = 'Boissons';
  static const String snacks = 'Snacks & Sucreries';
  static const String hygiene = 'Hygiène & Beauté';
  static const String entretien = 'Entretien ménager';
  static const String bebe = 'Bébé & Enfants';
  static const String animaux = 'Animaux';
  static const String sante = 'Santé & Pharmacie';

  /// Mot-clé (normalisé, sans accents) -> nom de catégorie par défaut.
  /// Le match se fait sur chaque mot du nom du produit, par préfixe
  /// (ex. "tomates" matche "tomate").
  static const Map<String, String> _keywords = {
    // Fruits & Légumes
    'pomme': fruitsLegumes, 'banane': fruitsLegumes, 'orange': fruitsLegumes,
    'fraise': fruitsLegumes, 'framboise': fruitsLegumes, 'bleuet': fruitsLegumes,
    'raisin': fruitsLegumes, 'citron': fruitsLegumes, 'lime': fruitsLegumes,
    'mangue': fruitsLegumes, 'ananas': fruitsLegumes, 'melon': fruitsLegumes,
    'peche': fruitsLegumes, 'poire': fruitsLegumes, 'kiwi': fruitsLegumes,
    'avocat': fruitsLegumes, 'tomate': fruitsLegumes, 'concombre': fruitsLegumes,
    'carotte': fruitsLegumes, 'patate': fruitsLegumes, 'pomme de terre': fruitsLegumes,
    'oignon': fruitsLegumes, 'ail': fruitsLegumes, 'salade': fruitsLegumes,
    'laitue': fruitsLegumes, 'epinard': fruitsLegumes, 'brocoli': fruitsLegumes,
    'chou': fruitsLegumes, 'courgette': fruitsLegumes, 'poivron': fruitsLegumes,
    'champignon': fruitsLegumes, 'celeri': fruitsLegumes, 'mais': fruitsLegumes,
    'haricot': fruitsLegumes, 'legume': fruitsLegumes, 'fruit': fruitsLegumes,
    'persil': fruitsLegumes, 'coriandre': fruitsLegumes, 'gingembre': fruitsLegumes,
    // Viandes & Poissons
    'poulet': viandesPoissons, 'boeuf': viandesPoissons, 'porc': viandesPoissons,
    'agneau': viandesPoissons, 'dinde': viandesPoissons, 'jambon': viandesPoissons,
    'saucisse': viandesPoissons, 'saucisson': viandesPoissons, 'bacon': viandesPoissons,
    'steak': viandesPoissons, 'viande': viandesPoissons, 'hache': viandesPoissons,
    'poisson': viandesPoissons, 'saumon': viandesPoissons, 'thon': viandesPoissons,
    'crevette': viandesPoissons, 'tilapia': viandesPoissons, 'morue': viandesPoissons,
    'sardine': viandesPoissons, 'merguez': viandesPoissons, 'cotelette': viandesPoissons,
    // Produits laitiers
    'lait': produitsLaitiers, 'fromage': produitsLaitiers, 'yaourt': produitsLaitiers,
    'yogourt': produitsLaitiers, 'beurre': produitsLaitiers, 'creme': produitsLaitiers,
    'oeuf': produitsLaitiers, 'mozzarella': produitsLaitiers, 'cheddar': produitsLaitiers,
    'parmesan': produitsLaitiers, 'feta': produitsLaitiers, 'margarine': produitsLaitiers,
    // Boulangerie
    'pain': boulangerie, 'baguette': boulangerie, 'croissant': boulangerie,
    'brioche': boulangerie, 'tortilla': boulangerie, 'pita': boulangerie,
    'muffin': boulangerie, 'bagel': boulangerie, 'farine': boulangerie,
    'levure': boulangerie, 'viennoiserie': boulangerie,
    // Boissons
    'eau': boissons, 'jus': boissons, 'cafe': boissons, 'the': boissons,
    'tisane': boissons, 'soda': boissons, 'cola': boissons, 'limonade': boissons,
    'sirop': boissons, 'boisson': boissons, 'smoothie': boissons,
    // Snacks & Sucreries
    'chocolat': snacks, 'bonbon': snacks, 'biscuit': snacks, 'gateau': snacks,
    'chips': snacks, 'croustille': snacks, 'craquelin': snacks, 'popcorn': snacks,
    'barre': snacks, 'cereale': snacks, 'confiture': snacks, 'miel': snacks,
    'nutella': snacks, 'sucre': snacks, 'dessert': snacks, 'glace': snacks,
    'creme glacee': snacks, 'noix': snacks, 'amande': snacks, 'arachide': snacks,
    // Hygiène & Beauté
    'savon': hygiene, 'shampoing': hygiene, 'shampooing': hygiene,
    'dentifrice': hygiene, 'brosse': hygiene, 'deodorant': hygiene,
    'rasoir': hygiene, 'mousse a raser': hygiene, 'papier toilette': hygiene,
    'papier hygienique': hygiene, 'serviette hygienique': hygiene,
    'tampon': hygiene, 'coton': hygiene, 'gel douche': hygiene,
    'lotion': hygiene, 'parfum': hygiene, 'maquillage': hygiene,
    // Entretien ménager
    'javel': entretien, 'detergent': entretien, 'lessive': entretien,
    'savon a vaisselle': entretien, 'liquide vaisselle': entretien,
    'eponge': entretien, 'essuie-tout': entretien, 'essuie tout': entretien,
    'nettoyant': entretien, 'desinfectant': entretien, 'sac poubelle': entretien,
    'aluminium': entretien, 'pellicule plastique': entretien, 'ziploc': entretien,
    'assouplissant': entretien, 'balai': entretien, 'vadrouille': entretien,
    // Bébé & Enfants
    'couche': bebe, 'lingette': bebe, 'lait bebe': bebe, 'puree bebe': bebe,
    'biberon': bebe, 'cerelac': bebe, 'pablum': bebe,
    // Animaux
    'croquette': animaux, 'litiere': animaux, 'nourriture chat': animaux,
    'nourriture chien': animaux, 'patee': animaux,
    // Santé & Pharmacie
    'vitamine': sante, 'medicament': sante, 'tylenol': sante, 'advil': sante,
    'aspirine': sante, 'pansement': sante, 'sirop toux': sante,
    'probiotique': sante, 'supplement': sante,
  };

  /// Préfixe de tag Open Food Facts -> nom de catégorie par défaut.
  /// Ordonné du plus spécifique au plus générique.
  static const Map<String, String> _offTagPrefixes = {
    'en:dairies': produitsLaitiers, 'en:cheeses': produitsLaitiers,
    'en:milks': produitsLaitiers, 'en:yogurts': produitsLaitiers,
    'en:eggs': produitsLaitiers, 'en:butters': produitsLaitiers,
    'en:breads': boulangerie, 'en:viennoiseries': boulangerie,
    'en:pastries': boulangerie, 'en:flours': boulangerie,
    'en:meats': viandesPoissons, 'en:poultries': viandesPoissons,
    'en:seafood': viandesPoissons, 'en:fishes': viandesPoissons,
    'en:sausages': viandesPoissons,
    'en:fruits': fruitsLegumes, 'en:vegetables': fruitsLegumes,
    'en:fresh-vegetables': fruitsLegumes, 'en:fresh-fruits': fruitsLegumes,
    'en:legumes': fruitsLegumes,
    'en:beverages': boissons, 'en:waters': boissons, 'en:juices': boissons,
    'en:sodas': boissons, 'en:coffees': boissons, 'en:teas': boissons,
    'en:snacks': snacks, 'en:sweet-snacks': snacks, 'en:salty-snacks': snacks,
    'en:chocolates': snacks, 'en:candies': snacks, 'en:biscuits': snacks,
    'en:breakfast-cereals': snacks, 'en:desserts': snacks,
    'en:ice-creams': snacks, 'en:jams': snacks,
    'en:baby-foods': bebe, 'en:baby-milks': bebe,
    'en:pet-food': animaux, 'en:cat-food': animaux, 'en:dog-food': animaux,
    'en:hygiene': hygiene, 'en:cosmetics': hygiene,
    'en:cleaning-products': entretien,
    'en:dietary-supplements': sante,
  };

  /// Normalise : minuscules, sans accents, espaces simples.
  static String _normalize(String input) {
    const accents = 'àâäéèêëîïôöùûüçñ';
    const plain = 'aaaeeeeiioouuucn';
    var s = input.toLowerCase().trim();
    for (var i = 0; i < accents.length; i++) {
      s = s.replaceAll(accents[i], plain[i]);
    }
    return s.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Devine le NOM de la catégorie par défaut depuis le nom d'un produit.
  /// Retourne null si aucun mot-clé ne matche (jamais "Autre" : on ne
  /// catégorise pas par défaut, on laisse le choix à l'utilisateur).
  static String? guessFromName(String productName) {
    final normalized = _normalize(productName);
    if (normalized.isEmpty) return null;

    // 1. Expressions à plusieurs mots d'abord (plus spécifiques)
    for (final entry in _keywords.entries) {
      if (entry.key.contains(' ') && normalized.contains(entry.key)) {
        return entry.value;
      }
    }
    // 2. Puis mot à mot, par préfixe ("tomates" -> "tomate")
    for (final word in normalized.split(' ')) {
      if (word.length < 3) continue;
      for (final entry in _keywords.entries) {
        if (entry.key.contains(' ')) continue;
        if (word == entry.key || word.startsWith(entry.key)) {
          return entry.value;
        }
      }
    }
    return null;
  }

  /// Devine le NOM de la catégorie depuis les tags Open Food Facts d'un scan.
  static String? guessFromOffTags(List<String> categoriesTags) {
    for (final tag in categoriesTags) {
      for (final entry in _offTagPrefixes.entries) {
        if (tag == entry.key || tag.startsWith('${entry.key}-')) {
          return entry.value;
        }
      }
    }
    return null;
  }

  /// Résout un nom de catégorie deviné vers la catégorie de l'utilisateur
  /// (comparaison insensible à la casse et aux accents).
  static Category? resolve(List<Category> userCategories, String? guessedName) {
    if (guessedName == null) return null;
    final target = _normalize(guessedName);
    for (final cat in userCategories) {
      if (_normalize(cat.name) == target) {
        return cat;
      }
    }
    return null;
  }

  /// Raccourci : devine depuis le nom + résout vers les catégories de
  /// l'utilisateur en un seul appel.
  static Category? guessCategory(List<Category> userCategories, String productName) {
    return resolve(userCategories, guessFromName(productName));
  }
}
