// Au lancement, une file d'actions hors ligne doit repartir toute seule.
//
// `connectivityStream` est un flux broadcast SANS rejeu, et l'etat initial y
// est emis par ConnectivityService.initialize() BIEN AVANT que
// OfflineSyncService ne s'y abonne. L'abonnement ne voit donc que les
// CHANGEMENTS a venir. Resultat : des articles ajoutes hors ligne, puis
// l'application fermee, n'etaient jamais envoyes au lancement suivant — il
// fallait que la connexion tombe PUIS revienne. Les ajouts semblaient perdus,
// et rien n'apparaissait dans les journaux du serveur : aucune requete
// n'etait partie.

import 'package:dio/dio.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:epilist/services/offline_queue_service.dart';
import 'package:epilist/services/offline_sync_service.dart';
import 'package:epilist/services/shopping_list_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Note les listes qu'on lui demande de creer, sans reseau.
class _ListesSimulees extends ShoppingListService {
  _ListesSimulees({required super.dio, required super.authService});

  final creees = <String>[];

  @override
  Future<ShoppingList> createShoppingList(String name) async {
    creees.add(name);
    return ShoppingList(
      id: 4242,
      userId: 1,
      name: name,
      createdAt: DateTime(2026, 10, 15),
      updatedAt: DateTime(2026, 10, 15),
      items: const [],
    );
  }

  @override
  Future<List<ShoppingList>> getShoppingLists() async => [];
}

void main() {
  test('la file remplie hors ligne repart au lancement, sans attendre une coupure', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final dio = Dio();
    final authService = AuthService(dio: dio, sharedPreferences: prefs);

    // Hier : l'utilisateur cree une liste hors ligne, puis ferme l'app.
    await OfflineQueueService.initialize();
    await OfflineQueueService.enqueueAction(
      actionType: OfflineQueueService.actionCreateList,
      payload: {'name': 'Courses du samedi'},
      localId: 'local-1',
    );
    expect(await OfflineQueueService.getPendingCount(), 1);

    // Aujourd'hui : l'app redemarre, le reseau est la depuis le debut, donc
    // le flux de connectivite n'emettra AUCUN changement.
    final listes = _ListesSimulees(dio: dio, authService: authService);
    await OfflineSyncService().initialize(
      shoppingListService: listes,
      listItemService: ListItemService(dio: dio, authService: authService),
    );

    // La synchro est lancee en arriere-plan : on lui laisse le temps
    // (500 ms de pause entre deux actions dans le service).
    for (var i = 0; i < 40 && listes.creees.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    // Avant : rien ne partait, la file restait pleine indefiniment.
    expect(listes.creees, ['Courses du samedi']);
    expect(await OfflineQueueService.getPendingCount(), 0);
  });
}
