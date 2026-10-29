// L'auteur d'un message dont le compte a ete supprime.
//
// Ses messages restent dans la conversation — les retirer trouerait
// l'historique de ceux qui restent — mais il n'a plus de nom. Le serveur
// envoie « is_deleted » et un libelle deja traduit dans la langue
// enregistree du compte ; l'ecran, lui, suit la langue REELLE de
// l'application, qui peut differer. D'ou le drapeau.
//
// Ce qui se teste ici est la LECTURE de la charge utile pendant la
// bascule : les serveurs d'avant n'envoient pas le champ, et une
// application a jour ne doit pas pour autant afficher n'importe quoi.
import 'package:epilist/models/list_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> auteur({bool? supprime}) => {
    'id': 4,
    'name': supprime == true ? 'Utilisateur supprimé' : 'Awa Diop',
    'email': supprime == true ? '' : 'awa@example.com',
    if (supprime != null) 'is_deleted': supprime,
  };

  group('Un auteur supprime se reconnait', () {
    test('le drapeau du serveur fait foi', () {
      final parti = MessageUser.fromJson(auteur(supprime: true));
      final present = MessageUser.fromJson(auteur(supprime: false));

      expect(parti.isDeleted, isTrue);
      expect(present.isDeleted, isFalse);
      // Le serveur ne renvoie plus l'adresse d'un compte supprime.
      expect(parti.email, isEmpty);
    });

    test('serveur ancien : le champ manque, personne n est declare parti', () {
      // Avant la migration 016, « is_deleted » n'existe pas. Le defaut
      // doit etre « present » : annoncer a tort un compte supprime
      // effacerait le nom de quelqu'un qui est toujours la.
      expect(MessageUser.fromJson(auteur()).isDeleted, isFalse);
    });

    test('pas d initiales pour un compte supprime', () {
      // « Utilisateur supprimé » donnerait « US », ce qui ressemble aux
      // initiales d'une personne.
      expect(MessageUser.fromJson(auteur(supprime: true)).initials, '?');
      expect(MessageUser.fromJson(auteur(supprime: false)).initials, 'AD');
    });

    test('le drapeau survit a toJson', () {
      final parti = MessageUser.fromJson(auteur(supprime: true));

      expect(parti.toJson()['is_deleted'], isTrue);
      expect(MessageUser.fromJson(parti.toJson()).isDeleted, isTrue);
    });
  });

  group('Le message porte son auteur', () {
    Map<String, dynamic> message(Map<String, dynamic>? user) => {
      'id': 11,
      'list_id': 3,
      'user_id': 4,
      'message': 'Je prends le pain',
      'message_type': 'text',
      'created_at': '2026-10-29T10:00:00Z',
      'updated_at': '2026-10-29T10:00:00Z',
      if (user != null) 'user': user,
    };

    test('un auteur supprime remonte jusqu au message', () {
      final m = ListMessage.fromJson(message(auteur(supprime: true)));

      expect(m.user, isNotNull);
      expect(m.user!.isDeleted, isTrue);
      // Le message lui-meme n'est pas touche : c'est tout l'objet.
      expect(m.message, 'Je prends le pain');
    });

    test('un message sans auteur reste lisible', () {
      expect(ListMessage.fromJson(message(null)).user, isNull);
    });
  });
}
