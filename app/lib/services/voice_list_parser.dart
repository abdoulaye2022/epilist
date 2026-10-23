// services/voice_list_parser.dart - Une phrase dictée, plusieurs articles.
//
// L'écran proposait lui-même des exemples — « 3 pommes »,
// « 5 kilogrammes de tomates », « 2 litres de lait » — et le résultat ne
// les respectait pas : « viande croissant 2 kg » donnait UN article
// nommé « Viande croissant 2 kg » avec la quantité 1,0. La quantité
// restait dans le nom, l'unité aussi, et une phrase de plusieurs
// produits n'en faisait qu'un (« Tomate Igname Pain Arachide »).
//
// Ce fichier fait trois choses, et rien d'autre : il DÉCOUPE la phrase,
// il en EXTRAIT la quantité et l'unité, il rend une liste. Aucune
// dépendance à Flutter ni au micro — c'est ce qui permet de la vérifier
// (test/voice_list_parser_test.dart) avec les phrases mêmes de
// l'analyse.
//
// Ce qu'il ne peut PAS faire, et il faut le dire : retrouver des
// séparateurs qui n'ont pas été prononcés. « Tomate Igname Pain
// Arachide » dicté d'un trait reste un seul article : rien, dans le
// texte, ne dit où couper.
library;

/// Un article tel que la phrase l'a dit.
class DictatedItem {
  DictatedItem({
    required this.name,
    this.quantity = 1,
    this.unit,
    this.quantityStated = false,
  });

  /// Le produit, sans sa quantité ni son unité.
  String name;

  double quantity;

  /// kg, g, L, ml, ou un contenant (sac, boîte, paquet…). `null` quand
  /// la quantité est un simple nombre d'articles.
  String? unit;

  /// La quantité a-t-elle été PRONONCÉE ? Sinon elle vaut 1, et l'écran
  /// doit le montrer : une quantité devinée qui ne s'annonce pas est
  /// une quantité fausse qu'on ne corrige jamais.
  bool quantityStated;

  @override
  String toString() =>
      'DictatedItem($name, $quantity${unit != null ? ' $unit' : ''}'
      '${quantityStated ? '' : ', par défaut'})';
}

/// Les nombres écrits en lettres, français et anglais.
const Map<String, double> _nombres = {
  'un': 1,
  'une': 1,
  'deux': 2,
  'trois': 3,
  'quatre': 4,
  'cinq': 5,
  'six': 6,
  'sept': 7,
  'huit': 8,
  'neuf': 9,
  'dix': 10,
  'onze': 11,
  'douze': 12,
  'treize': 13,
  'quatorze': 14,
  'quinze': 15,
  'seize': 16,
  'vingt': 20,
  'trente': 30,
  'quarante': 40,
  'cinquante': 50,
  'one': 1,
  'a': 1,
  'an': 1,
  'two': 2,
  'three': 3,
  'four': 4,
  'five': 5,
  'seven': 7,
  'eight': 8,
  'nine': 9,
  'ten': 10,
  'eleven': 11,
  'twelve': 12,
  'thirteen': 13,
  'fourteen': 14,
  'fifteen': 15,
  'sixteen': 16,
  'seventeen': 17,
  'eighteen': 18,
  'nineteen': 19,
  'twenty': 20,
  'thirty': 30,
  'forty': 40,
  'fifty': 50,
};

/// Les unités, vers leur forme courte. L'ordre importe : la plus longue
/// d'abord, sinon « kilo » mangerait le début de « kilogramme ».
const List<(String, String)> _unites = [
  ('kilogrammes', 'kg'),
  ('kilogramme', 'kg'),
  ('kilograms', 'kg'),
  ('kilogram', 'kg'),
  ('kilos', 'kg'),
  ('kilo', 'kg'),
  ('kgs', 'kg'),
  ('kg', 'kg'),
  ('grammes', 'g'),
  ('gramme', 'g'),
  ('grams', 'g'),
  ('gram', 'g'),
  ('gr', 'g'),
  ('g', 'g'),
  ('millilitres', 'ml'),
  ('millilitre', 'ml'),
  ('milliliters', 'ml'),
  ('milliliter', 'ml'),
  ('ml', 'ml'),
  ('litres', 'L'),
  ('litre', 'L'),
  ('liters', 'L'),
  ('liter', 'L'),
  ('l', 'L'),
  ('paquets', 'paquet'),
  ('paquet', 'paquet'),
  ('packs', 'paquet'),
  ('pack', 'paquet'),
  ('sacs', 'sac'),
  ('sac', 'sac'),
  ('bags', 'sac'),
  ('bag', 'sac'),
  ('boites', 'boîte'),
  ('boîtes', 'boîte'),
  ('boite', 'boîte'),
  ('boîte', 'boîte'),
  ('boxes', 'boîte'),
  ('box', 'boîte'),
  ('bouteilles', 'bouteille'),
  ('bouteille', 'bouteille'),
  ('bottles', 'bouteille'),
  ('bottle', 'bouteille'),
  ('pots', 'pot'),
  ('pot', 'pot'),
  ('tranches', 'tranche'),
  ('tranche', 'tranche'),
];

/// Les mots qui ne nomment rien et qui ouvrent une phrase dictée.
const List<String> _amorces = [
  "ajoute",
  "ajouter",
  "ajoutez",
  "mets",
  "mettre",
  "je veux",
  "il me faut",
  "il faut",
  "achete",
  "acheter",
  "prends",
  "prendre",
  "add",
  "i need",
  "i want",
  "buy",
  "get",
];

/// Ce qui sépare deux articles dans une phrase dictée. Les virgules et
/// les pauses deviennent des virgules ou des points dans le texte rendu
/// par la reconnaissance ; « et » et « puis » sont prononcés.
final RegExp _separateurs = RegExp(
  r'(?:[,;.•]|\bet\b|\bpuis\b|\bensuite\b|\band\b|\bthen\b|\bplus\b)',
  caseSensitive: false,
);

/// Découpe une phrase dictée en articles.
///
/// Rend une liste vide pour une phrase vide. Jamais d'exception : une
/// dictée mal comprise doit pouvoir se corriger à l'écran, pas faire
/// disparaître l'écran.
List<DictatedItem> parseDictation(String phrase) {
  final texte = phrase.trim().toLowerCase();
  if (texte.isEmpty) return [];

  final articles = <DictatedItem>[];
  for (final morceau in texte.split(_separateurs)) {
    final item = _article(morceau);
    if (item != null) articles.add(item);
  }
  return articles;
}

/// Un morceau de phrase -> un article, ou `null` s'il ne reste rien.
DictatedItem? _article(String morceau) {
  var reste = _nettoie(morceau);
  if (reste.isEmpty) return null;

  // La quantité est le plus souvent devant (« 3 pommes », « cinq
  // tomates »), mais elle se dit aussi derrière : « viande hachée 2 kg »
  // — c'est la phrase même qui a montré le problème.
  var (quantite, unite, suite) = _quantiteDevant(reste);
  if (quantite == null) {
    final derriere = _quantiteDerriere(reste);
    quantite = derriere.$1;
    unite = derriere.$2;
    suite = derriere.$3;
  }

  reste = _nettoie(suite);

  // « deux litres » sans produit : le morceau garde son texte, sinon
  // l'article disparaîtrait en silence.
  if (reste.isEmpty) {
    reste = _nettoie(morceau);
    if (reste.isEmpty) return null;
    return DictatedItem(name: _majuscule(reste));
  }

  return DictatedItem(
    name: _majuscule(reste),
    quantity: quantite ?? 1,
    unit: unite,
    quantityStated: quantite != null,
  );
}

/// Quantité (et unité) en tête de morceau.
(double?, String?, String) _quantiteDevant(String texte) {
  // « 500 grammes de bœuf haché », « 2,5 litres de lait »
  final chiffres = RegExp(r'^(\d+(?:[.,]\d+)?)\s*(.*)$').firstMatch(texte);
  if (chiffres != null) {
    final valeur = double.tryParse(chiffres.group(1)!.replaceAll(',', '.'));
    if (valeur != null) {
      final (unite, suite) = _unite(chiffres.group(2) ?? '');
      return (valeur, unite, suite);
    }
  }

  // « une douzaine d'œufs » : une douzaine est un nombre, pas une unité.
  final douzaine = RegExp(
    r'^(?:une\s+)?(demi[-\s]douzaine|douzaine)\s*(.*)$',
  ).firstMatch(texte);
  if (douzaine != null) {
    final valeur = douzaine.group(1)!.startsWith('demi') ? 6.0 : 12.0;
    return (valeur, null, _sansLiaison(douzaine.group(2) ?? ''));
  }

  // « trois pommes », « cinq kilos de farine »
  final mots = RegExp(
    r"^([a-zàâäéèêëîïôöùûüçñœæ']+)\s+(.*)$",
  ).firstMatch(texte);
  if (mots != null) {
    final valeur = _nombres[mots.group(1)!];
    if (valeur != null) {
      final (unite, suite) = _unite(mots.group(2) ?? '');
      return (valeur, unite, suite);
    }
  }

  return (null, null, texte);
}

/// Quantité (et unité) en fin de morceau : « viande hachee 2 kg ».
(double?, String?, String) _quantiteDerriere(String texte) {
  final fin = RegExp(
    r'^(.*?)\s+(\d+(?:[.,]\d+)?)\s*([a-zàâäéèêëîïôöùûüç]*)$',
  ).firstMatch(texte);
  if (fin == null) return (null, null, texte);

  final valeur = double.tryParse(fin.group(2)!.replaceAll(',', '.'));
  if (valeur == null) return (null, null, texte);

  final suffixe = (fin.group(3) ?? '').trim();
  // Un mot inconnu derrière le nombre n'est pas une unité : « lait 2
  // pour cent » ne doit pas devenir « lait, 2 cent ».
  if (suffixe.isNotEmpty) {
    final (unite, apres) = _unite(suffixe);
    if (unite == null || apres.trim().isNotEmpty) return (null, null, texte);
    return (valeur, unite, fin.group(1) ?? '');
  }
  return (valeur, null, fin.group(1) ?? '');
}

/// Une unité en tête de texte, et ce qui reste après elle (sans le
/// « de » de liaison).
(String?, String) _unite(String texte) {
  final t = texte.trimLeft();
  for (final (mot, courte) in _unites) {
    if (t == mot) return (courte, '');
    if (t.startsWith('$mot ') || t.startsWith("$mot'")) {
      return (courte, _sansLiaison(t.substring(mot.length)));
    }
  }
  return (null, t);
}

/// Retire le « de », « d' », « of » qui relie l'unité au produit :
/// « 5 kilogrammes DE tomates ».
String _sansLiaison(String texte) {
  final t = texte.trimLeft();
  for (final liaison in [
    "de la ",
    "de l'",
    "d'",
    "de ",
    "des ",
    "du ",
    "of ",
  ]) {
    if (t.startsWith(liaison)) return t.substring(liaison.length).trim();
  }
  return t.trim();
}

/// Enlève les amorces (« ajoute… ») et les articles de tête.
String _nettoie(String texte) {
  var t = texte.trim();
  for (final amorce in _amorces) {
    if (t == amorce) return '';
    if (t.startsWith('$amorce ')) {
      t = t.substring(amorce.length).trim();
      break;
    }
  }
  // Un seul passage de liaison : « du pain » -> « pain », mais « de
  // blé » dans « pain de blé » n'est jamais en tête.
  t = _sansLiaison(t);
  return t.trim();
}

String _majuscule(String texte) {
  if (texte.isEmpty) return texte;
  return texte[0].toUpperCase() + texte.substring(1);
}
