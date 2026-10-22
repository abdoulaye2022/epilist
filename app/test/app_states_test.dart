// La seconde regle de la planche : l'etat d'un controle est ECRIT a
// cote de lui.
//
// Un interrupteur, une etoile, une case cochee ne disent leur etat que
// par une position et une couleur. Ces tests verrouillent le fait que
// le mot suit le geste — et que la cible touchable fait bien les 64 dp
// que la planche demande, au lieu des 48 de Material.
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AppColors.palette = AppPalette.light);

  Future<void> poser(WidgetTester tester, Widget enfant) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: SingleChildScrollView(child: enfant)),
    ),
  );

  group('AppCheckRow', () {
    testWidgets('la ligne fait au moins 64 dp de haut', (tester) async {
      await poser(
        tester,
        AppCheckRow(checked: false, title: 'Carottes', onChanged: (_) {}),
      );
      expect(
        tester.getSize(find.byType(ConstrainedBox).first).height,
        greaterThanOrEqualTo(AppSizes.row),
      );
    });

    testWidgets('toucher la ligne entiere bascule la case', (tester) async {
      var valeur = false;
      await poser(
        tester,
        AppCheckRow(
          checked: false,
          title: 'Carottes',
          subtitle: 'Quantite : 1 sac de 1 kg',
          onChanged: (v) => valeur = v,
        ),
      );
      // Sur le TEXTE, pas sur la case : c'est tout l'interet d'une
      // grande zone tactile.
      await tester.tap(find.text('Carottes'));
      expect(valeur, isTrue);
    });

    testWidgets('coche, elle ecrit ce qui est fait et rature le nom', (
      tester,
    ) async {
      await poser(
        tester,
        AppCheckRow(
          checked: true,
          title: 'Pommes Gala',
          doneLabel: 'Dans le panier',
          onChanged: (_) {},
        ),
      );
      expect(find.text('Dans le panier'), findsOneWidget);
      final texte = tester.widget<Text>(find.text('Pommes Gala'));
      expect(texte.style!.decoration, TextDecoration.lineThrough);
    });

    testWidgets('sans libelle de fin, rien ne s ecrit', (tester) async {
      // Une liste de dix-sept articles porterait sinon dix-sept fois le
      // meme mot.
      await poser(
        tester,
        AppCheckRow(checked: true, title: 'Bananes', onChanged: (_) {}),
      );
      expect(find.text('Bananes'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });
  });

  group('AppStateSwitch', () {
    testWidgets('l etat est ecrit, et suit la bascule', (tester) async {
      await poser(
        tester,
        AppStateSwitch(
          value: true,
          stateLabel: 'Etat : Activee',
          onChanged: (_) {},
        ),
      );
      expect(find.text('Etat : Activee'), findsOneWidget);

      await poser(
        tester,
        AppStateSwitch(
          value: false,
          stateLabel: 'Etat : En pause',
          onChanged: (_) {},
        ),
      );
      expect(find.text('Etat : En pause'), findsOneWidget);
    });

    testWidgets('la bascule rend la valeur contraire', (tester) async {
      bool? recu;
      await poser(
        tester,
        AppStateSwitch(
          value: false,
          stateLabel: 'Etat : En pause',
          onChanged: (v) => recu = v,
        ),
      );
      await tester.tap(find.byType(Switch));
      expect(recu, isTrue);
    });
  });

  group('AppFavoriteButton', () {
    testWidgets('l etoile dit en mots si c est un favori', (tester) async {
      await poser(
        tester,
        AppFavoriteButton(
          favorite: true,
          label: 'Favori : Oui, magasin favori',
          onPressed: () {},
        ),
      );
      expect(find.text('Favori : Oui, magasin favori'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('non favori : etoile vide, et le mot le dit aussi', (
      tester,
    ) async {
      await poser(
        tester,
        AppFavoriteButton(
          favorite: false,
          label: 'Favori : Non, pas encore favori',
          onPressed: () {},
        ),
      );
      expect(find.text('Favori : Non, pas encore favori'), findsOneWidget);
      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
    });
  });

  group('AppZoneCard et AppWarningLine', () {
    testWidgets('la zone porte son titre et son contenu', (tester) async {
      await poser(
        tester,
        AppZoneCard(
          title: 'Refrigerateur',
          tint: AppColors.accent,
          icon: Icons.kitchen_outlined,
          children: const [Text('Lait Lactantia')],
        ),
      );
      expect(find.text('Refrigerateur'), findsOneWidget);
      expect(find.text('Lait Lactantia'), findsOneWidget);
    });

    testWidgets('une alerte est une phrase, avec son icone', (tester) async {
      await poser(
        tester,
        const AppWarningLine(text: 'Alerte stock bas : Riz, un sac restant.'),
      );
      expect(
        find.text('Alerte stock bas : Riz, un sac restant.'),
        findsOneWidget,
      );
      expect(find.byType(Icon), findsOneWidget);
    });
  });
}
