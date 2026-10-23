// L'ecran qui MONTRE l'architecture a plat.
//
// La planche « Version B » demande dix destinations egales. La
// hierarchie precedente faisait passer Budgets, Analyses, Alertes de
// prix et Listes recurrentes pour des dependances de Mes listes : elles
// vivaient apres deux separateurs du menu, et nulle part ailleurs.
//
// Ce test verrouille le CONTRAT de l'ecran : les dix, dans l'ordre de
// la planche. Un ajout ou un retrait silencieux le casse.
//
// Elles etaient numerotees « 1. » a « 10. ». Un numero n'aide pas a
// naviguer : personne ne cherche la section 7.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/screens/sections_screen.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AppColors.palette = AppPalette.light);

  Future<void> ouvrir(WidgetTester tester, {double echelle = 1.0}) =>
      tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(echelle)),
            child: const SectionsScreen(),
          ),
        ),
      );

  const attendues = [
    'Tableau de bord',
    'Mes listes de courses',
    'Budgets',
    'Analyses',
    'Avant les courses',
    'Alertes de prix',
    'À la maison',
    'Listes récurrentes',
    'Planifier mes repas',
    'Mes magasins',
  ];

  testWidgets('les dix sections, dans l ordre de la planche', (tester) async {
    await ouvrir(tester);
    for (final titre in attendues) {
      expect(find.text(titre), findsOneWidget, reason: titre);
    }
  });

  testWidgets('aucune onzieme tuile ne s est glissee dedans', (tester) async {
    await ouvrir(tester);
    // Les tuiles sont les InkWell de la grille ; le bouton du menu
    // lateral n'en est pas une (il n'existe que dans la coquille, et
    // cet ecran est ouvert seul).
    expect(
      find.descendant(
        of: find.byType(GridView),
        matching: find.byType(InkWell),
      ),
      findsNWidgets(attendues.length),
    );
  });

  testWidgets('l intro dit quoi faire, pas comment c est concu', (
    tester,
  ) async {
    await ouvrir(tester);
    expect(find.text('Toutes les sections'), findsOneWidget);
    expect(find.textContaining('Touchez une tuile'), findsOneWidget);
    // Le vocabulaire de concepteur n'a rien a faire sous les yeux de
    // quelqu'un qui veut juste faire ses courses.
    expect(find.textContaining('architecture'), findsNothing);
    expect(find.textContaining('destinations'), findsNothing);
  });

  testWidgets('hors de la coquille, le bouton du menu lateral disparait', (
    tester,
  ) async {
    // Il n'ouvrirait rien : le tiroir appartient au MainShell.
    await ouvrir(tester);
    expect(find.text('Ouvrir le menu latéral'), findsNothing);
  });

  testWidgets('les tuiles s allongent quand le texte grossit', (tester) async {
    // Un rapport largeur/hauteur FIXE ne tient pas : a deux fois,
    // « Mes magasins » sur deux lignes debordait de sa tuile. Le
    // public de cette planche agrandit le texte — c'est la premiere
    // chose qu'il fait dans les reglages de son telephone.
    for (final echelle in [1.0, 1.3, 1.6, 2.0]) {
      await ouvrir(tester, echelle: echelle);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'grossissement $echelle');
    }
  });
}
