// L'invitation doit survivre au magasin d'applications.
//
// Le chemin qu'on teste ici est celui qui casse tout le reste quand il
// casse : quelqu'un touche un lien de partage, n'a pas l'application,
// l'installe, l'ouvre — et le jeton a disparu entre le clic et le
// premier lancement. Sur Android, Google Play rend le « referrer » qui
// le contenait ; encore faut-il savoir le lire, y compris quand il
// arrive encodé une ou deux fois selon le chemin suivi.
//
// Et le jeton en attente doit tenir sur le disque : il vivait dans une
// variable statique, donc fermer l'application pendant l'inscription —
// pour aller chercher son code de vérification dans sa boîte de
// courriel, par exemple — perdait l'invitation sans laisser de trace.
import 'package:dio/dio.dart';
import 'package:epilist/services/invitation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const jetonValide = 'a1b2c3d4e5f60718293a4b5c6d7e8f90';

  group('Lire le referrer de Google Play', () {
    test('la forme que le lien de partage produit', () {
      expect(
        InvitationService.jetonDepuisReferrer(
          'share_token=$jetonValide&utm_source=share',
        ),
        jetonValide,
      );
    });

    test('encodé une fois', () {
      final encode = Uri.encodeComponent(
        'share_token=$jetonValide&utm_source=share',
      );

      expect(InvitationService.jetonDepuisReferrer(encode), jetonValide);
    });

    test('encodé deux fois', () {
      // Selon le chemin — navigateur, application de messagerie,
      // magasin — le referrer revient parfois encodé une fois de trop.
      final doubleEncode = Uri.encodeComponent(
        Uri.encodeComponent('share_token=$jetonValide&utm_source=share'),
      );

      expect(InvitationService.jetonDepuisReferrer(doubleEncode), jetonValide);
    });

    test('majuscules acceptées, rendues en minuscules', () {
      expect(
        InvitationService.jetonDepuisReferrer(
          'share_token=${jetonValide.toUpperCase()}',
        ),
        jetonValide,
      );
    });

    test('un referrer ordinaire ne donne rien', () {
      // Le cas le plus courant : quelqu'un installe depuis le magasin,
      // sans invitation. Rien ne doit être retenu.
      expect(
        InvitationService.jetonDepuisReferrer(
          'utm_source=google-play&utm_medium=organic',
        ),
        isNull,
      );
      expect(InvitationService.jetonDepuisReferrer(''), isNull);
    });

    test('un jeton fantaisiste est refusé', () {
      // Le referrer vient de l'extérieur : il n'a aucune raison d'être
      // honnête, et ce qui en sort finit en base de données.
      for (final faux in [
        'share_token=bonjour',
        'share_token=../../etc/passwd',
        'share_token=<script>alert(1)</script>',
        'share_token=${jetonValide.substring(0, 31)}', // 31 caractères
        'share_token=${jetonValide}ff', // 34 caractères
        'share_token=zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz', // hors hexadécimal
      ]) {
        expect(
          InvitationService.jetonDepuisReferrer(faux),
          isNull,
          reason: faux,
        );
      }
    });
  });

  group('Le jeton en attente tient sur le disque', () {
    late InvitationService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = InvitationService(dio: Dio());
    });

    test('rien au départ', () async {
      expect(await service.jetonEnAttente(), isNull);
      expect(await service.sourceInscription(), SourceInscription.direct);
    });

    test('ce qui est gardé se relit, avec sa provenance', () async {
      await service.garderJeton(
        jetonValide,
        source: SourceInscription.referrerInstallation,
      );

      expect(await service.jetonEnAttente(), jetonValide);
      expect(
        await service.sourceInscription(),
        SourceInscription.referrerInstallation,
      );
    });

    test('une autre instance le retrouve', () async {
      // C'est tout l'intérêt : l'écran de bienvenue, le bloc
      // d'authentification et le gestionnaire de liens profonds ne
      // partagent qu'un disque.
      await service.garderJeton(
        jetonValide,
        source: SourceInscription.codeInvitation,
      );

      final autre = InvitationService(dio: Dio());

      expect(await autre.jetonEnAttente(), jetonValide);
    });

    test('oublier efface aussi la provenance', () async {
      await service.garderJeton(
        jetonValide,
        source: SourceInscription.lienPartage,
      );
      await service.oublierJeton();

      expect(await service.jetonEnAttente(), isNull);
      expect(await service.sourceInscription(), SourceInscription.direct);
    });

    test('un jeton vide ne remplace pas celui qui attend', () async {
      await service.garderJeton(
        jetonValide,
        source: SourceInscription.lienPartage,
      );
      await service.garderJeton('   ', source: SourceInscription.direct);

      expect(await service.jetonEnAttente(), jetonValide);
    });
  });

  group('Le code à six caractères', () {
    late InvitationService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = InvitationService(dio: Dio());
    });

    test('un code qui ne fait pas six caractères ne part même pas', () async {
      // Vérifié AVANT tout appel réseau : inutile de déranger l'API
      // pour une saisie incomplète, et le plafond de cadence est
      // précieux.
      for (final saisi in ['', 'ABC', 'ABC-12', 'ABCDEFG', '   ']) {
        expect(await service.resoudreCode(saisi), isNull, reason: saisi);
      }
    });
  });
}
