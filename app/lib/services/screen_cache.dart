// services/screen_cache.dart - Cache mémoire des écrans (vie = session).
//
// Problème résolu : chaque écran rechargeait ses données dans initState
// et affichait un indicateur de chargement, à CHAQUE navigation — même
// quand les données venaient d'être lues trente secondes plus tôt.
//
// Principe « afficher puis rafraîchir » :
//   1. l'écran lit ici ce qu'il avait déjà (instantané, pas de spinner) ;
//   2. il lance quand même l'appel réseau, en silence ;
//   3. il remplace l'affichage quand la réponse arrive.
// Un indicateur de chargement n'apparaît donc que la PREMIÈRE fois.
//
// Cloisonnement : chaque entrée est implicitement rattachée à l'espace
// actif. Basculer du personnel au foyer ne peut pas ressortir les
// données de l'autre espace. Tout est vidé à la déconnexion.
//
// Ce cache est volontairement EN MÉMOIRE : il disparaît à la fermeture
// de l'application. La persistance hors ligne, elle, reste le travail
// d'OfflineStorageService.
import 'package:epilist/models/space.dart';
import 'package:epilist/services/space_service.dart';

class ScreenCache {
  ScreenCache._();

  static final Map<String, Object?> _store = {};

  /// Clé réelle : la donnée appartient à l'espace actif.
  static String _scoped(String key) {
    final Space? space = ActiveSpaceStore.current.value;
    return '$key@s${space?.id ?? 0}';
  }

  /// Valeur mémorisée, ou null si absente (ou d'un autre type).
  static T? read<T>(String key) {
    final value = _store[_scoped(key)];
    return value is T ? value : null;
  }

  static void write(String key, Object? value) {
    _store[_scoped(key)] = value;
  }

  /// Oublie une entrée : à appeler après une modification qui rend la
  /// copie mémorisée fausse et qu'on ne veut pas réafficher.
  static void invalidate(String key) {
    _store.remove(_scoped(key));
  }

  /// Vidage complet (déconnexion, changement de compte).
  static void clear() {
    _store.clear();
  }
}
