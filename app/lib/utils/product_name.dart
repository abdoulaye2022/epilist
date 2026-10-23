// utils/product_name.dart - Le nom d'un produit, réduit à sa forme
// comparable.
//
// Le serveur range tout par `normalized_name` : l'historique d'achats,
// les alias, les prix de la communauté, l'inventaire. Pour demander
// « en ai-je déjà à la maison ? » sans aller au serveur, l'application
// doit réduire le nom de la MÊME façon — sinon « Lait 2% » et « lait 2
// % » sont deux produits.
//
// C'est la traduction fidèle de `PurchaseHistory::normalizeProductName`
// (api/src/Models/PurchaseHistory.php). Si l'une des deux change,
// l'autre doit changer avec : le test product_name_test.dart garde les
// cas qui les ont fait diverger.
library;

/// Minuscules, sans accents, sans ponctuation, espaces simples.
String normalizeProductName(String name) {
  var s = name.toLowerCase();

  // Les ligatures AVANT le filtre : « Œuf » devenait « uf », parce que
  // le « œ » n'était pas traduit puis jeté par le filtre. « Oeuf » et
  // « Œuf » donnaient alors deux produits différents.
  const equivalences = {
    'à': 'a',
    'â': 'a',
    'á': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ó': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
    'œ': 'oe',
    'æ': 'ae',
  };
  for (final e in equivalences.entries) {
    s = s.replaceAll(e.key, e.value);
  }

  s = s.replaceAll(RegExp(r'[^a-z0-9 ]'), '');
  s = s.replaceAll(RegExp(r' +'), ' ');
  return s.trim();
}
