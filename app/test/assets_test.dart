// Les fichiers que la planche a apportes sont-ils vraiment DANS le
// paquet ?
//
// Un `SvgPicture.asset` dont le chemin n'est pas declare dans
// pubspec.yaml passe l'analyse sans un mot et ne casse qu'a l'execution,
// sur l'ecran d'accueil. Les fontes, pareil : sans leur declaration, le
// texte repart sur la fonte systeme et personne ne le remarque avant de
// comparer deux captures.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // rootBundle passe par le ServicesBinding : sans cette ligne, le
  // premier `loadString` echoue avant d'avoir rien lu.
  TestWidgetsFlutterBinding.ensureInitialized();

  // La barre du bas portait cinq SVG de plus. Elle prend maintenant ses
  // dessins dans `AppIcons`, avec le menu et les tuiles : un seul style
  // de trait, et plus rien a declarer.
  const dessins = ['assets/images/chariot.svg'];

  const fontes = [
    'assets/fonts/AtkinsonHyperlegible-Regular.ttf',
    'assets/fonts/AtkinsonHyperlegible-Bold.ttf',
    'assets/fonts/AtkinsonHyperlegible-Italic.ttf',
    'assets/fonts/Sora-Variable.ttf',
  ];

  for (final chemin in dessins) {
    test('$chemin est livre, et c est bien un SVG', () async {
      final texte = await rootBundle.loadString(chemin);
      expect(texte, startsWith('<svg'));
      expect(texte, contains('</svg>'));
    });
  }

  for (final chemin in fontes) {
    test('$chemin est livre', () async {
      final data = await rootBundle.load(chemin);
      // Une fonte TrueType pese plus que quelques octets ; un fichier
      // vide passerait la simple existence.
      expect(data.lengthInBytes, greaterThan(10000));
    });
  }
}
