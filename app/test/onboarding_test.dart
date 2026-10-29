// Le parcours de départ ne doit se montrer qu'une fois.
//
// Deux façons de se tromper, et elles ne coûtent pas la même chose :
//
//   - ne pas le montrer à quelqu'un qui aurait dû le voir : on perd une
//     occasion d'expliquer, la personne se débrouille ;
//   - le montrer à quelqu'un qui l'a déjà fait : « Créez votre première
//     liste » à quelqu'un qui en a douze ressemble à une perte de
//     données, et c'est le genre de chose qui fait désinstaller.
//
// Le service penche donc toujours du premier côté : au moindre doute,
// il ne montre rien.
import 'package:dio/dio.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/services/onboarding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OnboardingService service;

  /// Un service pret a l'emploi. Le port 1 n'ecoute pas : les appels
  /// reseau echouent, ce qui est precisement le cas a eprouver.
  Future<OnboardingService> construire() async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:1'));

    return OnboardingService(
      dio: dio,
      authService: AuthService(
        dio: dio,
        sharedPreferences: await SharedPreferences.getInstance(),
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = await construire();
  });

  group('Faut-il montrer le parcours ?', () {
    test('compte neuf : oui', () async {
      expect(await service.doitMontrer(dejaFaitSelonServeur: false), isTrue);
    });

    test('compte qui l a deja vu : non', () async {
      expect(await service.doitMontrer(dejaFaitSelonServeur: true), isFalse);
    });

    test('serveur qui ne dit rien : non', () async {
      // Version anterieure a la migration 018 : le champ est absent.
      // Le montrer serait un pari sur un compte peut-etre ancien.
      expect(await service.doitMontrer(dejaFaitSelonServeur: null), isFalse);
    });
  });

  group('Une fois vu, il ne revient pas', () {
    test('le marquage local suffit, meme si le serveur n a pas repondu', () async {
      // L'appel reseau echoue ici (port 1, personne n'ecoute), et c'est
      // exactement le cas interessant : le parcours ne doit pas
      // reapparaitre au prochain demarrage pour autant.
      await service.marquerTermine();

      expect(await service.doitMontrer(dejaFaitSelonServeur: false), isFalse);
    });

    test('et une autre instance le sait aussi', () async {
      await service.marquerTermine();

      final autre = await construire();

      expect(await autre.doitMontrer(dejaFaitSelonServeur: false), isFalse);
    });

    test('le serveur a le dernier mot quand il dit « deja fait »', () async {
      // Nouveau telephone : le drapeau local est vide, mais le compte a
      // deja fait le parcours ailleurs.
      expect(await service.doitMontrer(dejaFaitSelonServeur: true), isFalse);
    });
  });

  group('Un autre compte sur le meme telephone', () {
    test('oublier remet le parcours a disposition', () async {
      await service.marquerTermine();
      expect(await service.doitMontrer(dejaFaitSelonServeur: false), isFalse);

      // A la deconnexion : la personne suivante a droit au sien.
      await service.oublier();

      expect(await service.doitMontrer(dejaFaitSelonServeur: false), isTrue);
    });
  });
}
