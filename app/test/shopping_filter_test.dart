// Le filtre du mode « En magasin ».
//
// Un article coche RESTE a sa place : il etait retire de son rayon et
// renvoye en bas de l'ecran, derriere un bouton en forme d'oeil. Au
// milieu des courses, un article qui disparait du rayon ou on vient de
// le prendre fait douter de l'avoir pris.
//
// « Tout » montre donc les deux, et c'est la valeur par defaut.
import 'package:epilist/screens/shopping_mode_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Tout garde les articles coches a leur place', () {
    expect(ShoppingFilter.tout.accepte(true), isTrue);
    expect(ShoppingFilter.tout.accepte(false), isTrue);
  });

  test('A prendre ne garde que ce qui reste a prendre', () {
    expect(ShoppingFilter.aPrendre.accepte(false), isTrue);
    expect(ShoppingFilter.aPrendre.accepte(true), isFalse);
  });

  test('Dans le panier ne garde que ce qui y est', () {
    expect(ShoppingFilter.dansLePanier.accepte(true), isTrue);
    expect(ShoppingFilter.dansLePanier.accepte(false), isFalse);
  });

  test('les trois valeurs existent, pas une quatrieme', () {
    expect(ShoppingFilter.values, hasLength(3));
  });
}
