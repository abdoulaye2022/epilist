// Ce qui n'a pas le droit de sortir de l'application.
//
// Une mesure d'usage se trompe rarement d'un coup : elle se trompe un
// paramètre à la fois. Quelqu'un ajoute `list_name` « juste pour voir
// quelles listes marchent », et six mois plus tard la base d'un tiers
// contient les courses de tout le monde.
//
// Ce test est la barrière. Il vérifie qu'un paramètre inconnu est
// REFUSÉ — pas nettoyé, pas tronqué : refusé, avec l'événement entier.
// Et que l'opt-out du profil coupe tout, immédiatement.
import 'package:epilist/services/analytics_tracker.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un faux SDK : on veut savoir ce qui SERAIT parti, sans Firebase.
class _FauxAnalytics implements FirebaseAnalytics {
  final List<({String nom, Map<String, Object>? parametres})> envoyes = [];
  bool collecteActive = true;

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {
    envoyes.add((nom: name, parametres: parameters));
  }

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    collecteActive = enabled;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FauxAnalytics faux;
  late AnalyticsTracker mesure;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    faux = _FauxAnalytics();
    mesure = AnalyticsTracker(analytics: faux);
  });

  group('Aucune donnée personnelle ne sort', () {
    test('un nom d article est refusé, et l événement entier avec', () async {
      final parti = await mesure.envoyer(
        EvenementMesure.articleAjoute,
        parametres: {'product_name': 'Pain de campagne'},
      );

      expect(parti, isFalse);
      expect(faux.envoyes, isEmpty,
          reason: 'refuser le paramètre et envoyer le reste laisserait '
              'croire que la mesure est propre');
    });

    test('les autres fuites classiques sont refusées aussi', () async {
      for (final fuite in <String, Object>{
        'list_name': 'Épicerie de la semaine',
        'email': 'quelqu-un@example.com',
        'amount': 42.50,
        'store_name': 'Metro',
        'user_id': 1234,
        'query': 'lait sans lactose',
      }.entries) {
        final parti = await mesure.envoyer(
          EvenementMesure.listeCreee,
          parametres: {fuite.key: fuite.value},
        );

        expect(parti, isFalse, reason: fuite.key);
      }

      expect(faux.envoyes, isEmpty);
    });

    test('une valeur hors de la liste fermée est refusée', () async {
      // « method » existe, mais « facebook » n'est pas une méthode de
      // connexion d'EpiList : une valeur inventée est aussi suspecte
      // qu'un paramètre inventé.
      await mesure.compteCree(methode: 'facebook', source: 'organic');

      expect(faux.envoyes, isEmpty);
    });

    test('ce qui est autorisé part bien', () async {
      await mesure.compteCree(methode: 'google', source: 'invite');

      expect(faux.envoyes, hasLength(1));
      expect(faux.envoyes.single.nom, 'account_created');
      expect(faux.envoyes.single.parametres, {
        'method': 'google',
        'source': 'invite',
      });
    });

    test('toutes les valeurs annoncées sont acceptées', () async {
      // Si quelqu'un ajoute une valeur à la liste fermée sans l'utiliser,
      // ou l'inverse, ce test le dit.
      for (final entree in AnalyticsTracker.valeursAutorisees.entries) {
        for (final valeur in entree.value) {
          final parti = await mesure.envoyer(
            EvenementMesure.etapeParcours,
            parametres: {entree.key: valeur},
          );

          expect(parti, isTrue, reason: '${entree.key} = $valeur');
        }
      }
    });
  });

  group('Le choix de la personne est respecté', () {
    test('couper la mesure arrête tout, tout de suite', () async {
      await mesure.definirDesactivee(true);

      final parti = await mesure.envoyer(EvenementMesure.listeCreee);

      expect(parti, isFalse);
      expect(faux.envoyes, isEmpty);
      expect(faux.collecteActive, isFalse,
          reason: 'le SDK lui-même doit cesser de collecter, pas seulement '
              'notre code de cesser d appeler');
    });

    test('et la rallumer la remet en marche', () async {
      await mesure.definirDesactivee(true);
      await mesure.definirDesactivee(false);

      expect(await mesure.envoyer(EvenementMesure.listeCreee), isTrue);
      expect(faux.collecteActive, isTrue);
    });

    test('le choix survit au redémarrage', () async {
      await mesure.definirDesactivee(true);

      final autre = AnalyticsTracker(analytics: faux);

      expect(await autre.estDesactivee(), isTrue);
      expect(await autre.envoyer(EvenementMesure.listeCreee), isFalse);
    });

    test('par défaut, la mesure est active', () async {
      expect(await mesure.estDesactivee(), isFalse);
    });
  });

  group('Les compteurs', () {
    test('la première ouverture ne part qu une fois', () async {
      await mesure.premiereOuverture();
      await mesure.premiereOuverture();
      await mesure.premiereOuverture();

      expect(
        faux.envoyes.where((e) => e.nom == 'app_first_open'),
        hasLength(1),
      );
    });

    test('seuls le premier et le cinquième article sont comptés', () async {
      for (var i = 0; i < 12; i++) {
        await mesure.articleAjoute();
      }

      final articles = faux.envoyes.where((e) => e.nom == 'item_added').toList();

      expect(articles, hasLength(2),
          reason: 'mesurer chaque article dirait surtout à quelle vitesse '
              'les gens tapent');
      expect(articles.first.parametres, {'rank': 'first'});
      expect(articles.last.parametres, {'rank': 'fifth'});
    });

    test('oublier les compteurs rouvre le premier article', () async {
      await mesure.articleAjoute();
      await mesure.oublierLesCompteurs();
      await mesure.articleAjoute();

      expect(
        faux.envoyes.where(
          (e) => e.nom == 'item_added' && e.parametres?['rank'] == 'first',
        ),
        hasLength(2),
      );
    });
  });
}
