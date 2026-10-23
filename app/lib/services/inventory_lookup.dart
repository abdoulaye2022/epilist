// services/inventory_lookup.dart - « En avez-vous déjà à la maison ? »
//
// Avant d'ajouter un article à une liste, l'application doit pouvoir
// répondre à cette question : sans elle, on rachète un sac de riz qu'on
// a déjà, et le même sac se retrouve à la fois dans la liste de courses
// et dans l'inventaire — ce qui était exactement le cas.
//
// Le coût d'une telle vérification doit rester nul pour qui ajoute un
// article : elle lit d'abord le cache d'écran (« À la maison » vient
// peut-être d'être ouvert), sinon elle interroge le serveur UNE fois et
// garde la réponse. Un échec ne bloque jamais l'ajout.
import 'package:epilist/models/intelligence.dart';
import 'package:epilist/services/intelligence_service.dart';
import 'package:epilist/services/screen_cache.dart';
import 'package:epilist/utils/product_name.dart';

class InventoryLookup {
  InventoryLookup(this._service);

  final IntelligenceService _service;

  /// Combien de temps une réponse sert avant d'être redemandée. Court :
  /// l'inventaire change quand on fait ses courses.
  static const Duration fraicheur = Duration(minutes: 5);

  static List<InventoryItem>? _memoire;
  static DateTime? _depuis;

  /// Oublie ce qui est en mémoire. À appeler quand l'inventaire a
  /// changé dans cette session.
  static void oublie() {
    _memoire = null;
    _depuis = null;
  }

  /// La provision correspondant à ce nom, ou `null` si elle n'est pas
  /// suivie, ou si l'inventaire n'a pas pu être lu.
  Future<InventoryItem?> chezMoi(String productName) async {
    final cherche = normalizeProductName(productName);
    if (cherche.isEmpty) return null;

    final items = await _items();
    for (final item in items) {
      if (normalizeProductName(item.productName) == cherche) return item;
    }
    return null;
  }

  Future<List<InventoryItem>> _items() async {
    final frais =
        _depuis != null && DateTime.now().difference(_depuis!) < fraicheur;
    if (_memoire != null && frais) return _memoire!;

    final cache = ScreenCache.read<List<InventoryItem>>('inventory');
    if (cache != null) {
      _memoire = cache;
      _depuis = DateTime.now();
      return cache;
    }

    try {
      final items = await _service.getInventory();
      _memoire = items;
      _depuis = DateTime.now();
      return items;
    } catch (_) {
      // Pas de réseau, pas de droit sur l'inventaire de l'espace : la
      // question reste sans réponse, et l'ajout continue.
      return const [];
    }
  }
}
