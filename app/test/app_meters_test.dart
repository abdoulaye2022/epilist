// La regle que la planche « Version B » impose aux mesures : un chiffre
// DESSINE est toujours double du meme chiffre ECRIT.
//
// C'est la seule chose qu'un test peut verifier a la place de l'oeil :
// que la phrase existe a cote de la barre, et que la barre ne sort pas
// de son cadre quand la donnee est absurde — une liste remplie a 120 %
// existe dans les donnees, pas dans une jauge.
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_meters.dart';
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

  group('AppGauge', () {
    testWidgets('la jauge ecrit son etat sous elle', (tester) async {
      await poser(
        tester,
        const AppGauge(ratio: 0.85, label: '85 pour cent pleine'),
      );
      expect(find.text('85 pour cent pleine'), findsOneWidget);
    });

    testWidgets('un ratio hors bornes ne deborde pas', (tester) async {
      for (final ratio in [-1.0, 1.4, double.nan]) {
        await poser(tester, AppGauge(ratio: ratio, label: 'peu importe'));
        final boite = tester.widget<FractionallySizedBox>(
          find.byType(FractionallySizedBox),
        );
        expect(boite.widthFactor, inInclusiveRange(0.0, 1.0), reason: '$ratio');
      }
    });
  });

  group('AppCounterCard', () {
    testWidgets('le compteur dit son compte ET sa phrase', (tester) async {
      await poser(
        tester,
        const AppCounterCard(
          count: '3 articles restants sur 17',
          sentence: 'Encore 3 articles et vos courses sont terminees.',
          ratio: 0.82,
        ),
      );
      expect(find.text('3 articles restants sur 17'), findsOneWidget);
      expect(
        find.text('Encore 3 articles et vos courses sont terminees.'),
        findsOneWidget,
      );
    });

    testWidgets('il s annonce aux lecteurs d ecran a chaque changement', (
      tester,
    ) async {
      // Sans `liveRegion`, le compteur change en silence : pendant les
      // courses, c'est precisement l'information qu'on suit.
      await poser(
        tester,
        const AppCounterCard(count: '2 sur 10', sentence: 'phrase', ratio: 0.2),
      );
      final semantics = tester.getSemantics(
        find.ancestor(
          of: find.text('2 sur 10'),
          matching: find.byType(Semantics).first,
        ),
      );
      expect(semantics, isNotNull);
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
        findsWidgets,
      );
    });

    testWidgets('son encre tient sur le jaune, dans les deux modes', (
      tester,
    ) async {
      // Le jaune poussin est trop clair pour porter du blanc : la carte
      // doit utiliser l'encre sombre invariante.
      for (final p in [AppPalette.light, AppPalette.dark]) {
        AppColors.palette = p;
        await poser(
          tester,
          const AppCounterCard(count: 'c', sentence: 's', ratio: 0.5),
        );
        final texte = tester.widget<Text>(find.text('s'));
        expect(texte.style!.color, AppColors.onWarning);
      }
    });
  });

  group('AppShareRow et AppStatCard', () {
    testWidgets('une part ecrit son pourcentage a cote de son nom', (
      tester,
    ) async {
      await poser(
        tester,
        AppShareRow(
          label: 'Fruits et legumes',
          share: '32 %',
          ratio: 0.32,
          color: AppColors.primary,
        ),
      );
      expect(find.text('Fruits et legumes'), findsOneWidget);
      expect(find.text('32 %'), findsOneWidget);
    });

    testWidgets('un chiffre en grand garde sa phrase', (tester) async {
      await poser(
        tester,
        const AppStatCard(value: '23,40 \$', sentence: 'D economies ce mois.'),
      );
      expect(find.text('23,40 \$'), findsOneWidget);
      expect(find.text('D economies ce mois.'), findsOneWidget);
    });
  });

  group('AppTrendBars', () {
    testWidgets('chaque barre porte son montant et son libelle', (
      tester,
    ) async {
      await poser(
        tester,
        const AppTrendBars(
          bars: [
            AppTrendBar(value: 98, label: 'Aout', amount: '98 \$'),
            AppTrendBar(value: 121, label: 'Septembre', amount: '121 \$'),
            AppTrendBar(
              value: 145,
              label: 'Octobre',
              amount: '145 \$',
              current: true,
            ),
          ],
        ),
      );
      for (final t in ['98 \$', '121 \$', '145 \$', 'Aout', 'Octobre']) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
    });

    testWidgets('une rangee vide ne casse pas l ecran', (tester) async {
      await poser(tester, const AppTrendBars(bars: []));
      expect(tester.takeException(), isNull);
    });
  });
}
