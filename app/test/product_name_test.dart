// La normalisation du nom d'un produit, cote application.
//
// Elle doit donner EXACTEMENT le meme resultat que
// PurchaseHistory::normalizeProductName (api/src/Models/
// PurchaseHistory.php) : c'est la cle sur laquelle le serveur range
// l'historique, les alias, les prix de la communaute et l'inventaire.
// Une divergence et l'application croit qu'un produit n'est pas suivi
// alors qu'il l'est.
//
// Les cas gardes ici sont ceux qui ont deja fait diverger les deux.
import 'package:epilist/utils/product_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('minuscules, accents, ponctuation, espaces', () {
    expect(normalizeProductName('Lait 2%'), 'lait 2');
    expect(normalizeProductName('  Pommes   Gala  '), 'pommes gala');
    expect(normalizeProductName('Crème fraîche'), 'creme fraiche');
    expect(normalizeProductName('Pâté de campagne'), 'pate de campagne');
  });

  test('la ligature oe ne disparait pas', () {
    // « Œuf » devenait « uf » : le caractere n'etait pas traduit, puis
    // le filtre [^a-z0-9 ] le jetait. « Oeuf » et « Œuf » donnaient
    // alors deux produits differents.
    expect(normalizeProductName('Œuf'), 'oeuf');
    expect(normalizeProductName('Oeuf'), 'oeuf');
    expect(normalizeProductName('Œufs frais'), 'oeufs frais');
    expect(normalizeProductName('Ædipe'), 'aedipe');
  });

  test('un nom qui ne laisse rien donne une chaine vide', () {
    expect(normalizeProductName('???'), '');
    expect(normalizeProductName('   '), '');
  });

  test('les chiffres restent', () {
    expect(normalizeProductName('Yogourt 750 g'), 'yogourt 750 g');
  });
}
