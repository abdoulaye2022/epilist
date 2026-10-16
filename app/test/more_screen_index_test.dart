// L'ecran « Plus » est l'index de l'application : il doit lister les
// ecrans qui n'etaient atteignables depuis AUCUNE entree nommee.
//
// Mesure de depart (16 octobre 2026) : 42 ecrans, 18 listes quelque part.
// Douze ecrans fonctionnels — mode courses, comparaison de magasins,
// predictions, code-barres, membres et activite de l'espace, creation
// d'espace, messages, preferences de courriel, ordre des allees, detail
// du budget, factures — n'apparaissaient ni dans la barre du bas ni dans
// le tiroir. Ce test echoue si l'un d'eux disparait de l'index.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/screens/more_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpMore(WidgetTester tester, {Locale locale = const Locale('fr')}) async {
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const MoreScreen(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('liste les ecrans jusqu\'ici invisibles', (tester) async {
    // Hauteur genereuse : l'index tient alors en une seule passe, sans
    // defilement a simuler.
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpMore(tester);

    for (final label in [
      'Mes courses', // mode courses : etait derriere le menu ⋮ d'une liste
      'Comparer les magasins',
      'À prévoir bientôt', // predictions
      'Scanner un code-barres', // etait au fond d'AddItemDialog
      'Créer un espace',
      'Discussion', // messages
      'Notifications', // preferences de courriel
      'Statistiques',
      'Budgets',
      'À la maison', // inventaire
    ]) {
      expect(find.text(label), findsOneWidget, reason: '« $label » absent de l\'index');
    }
  });

  testWidgets('la recherche filtre l\'index', (tester) async {
    await _pumpMore(tester);

    await tester.enterText(find.byType(TextField), 'magasin');
    await tester.pumpAndSettle();

    expect(find.text('Comparer les magasins'), findsOneWidget);
    expect(find.text('Mes magasins'), findsOneWidget);
    // Hors du filtre : ces entrees ne doivent plus etre rendues.
    expect(find.text('Statistiques'), findsNothing);
    expect(find.text('Profil'), findsNothing);
  });

  testWidgets('une recherche sans resultat le dit', (tester) async {
    await _pumpMore(tester);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();

    expect(find.text('Aucun résultat trouvé'), findsOneWidget);
  });

  testWidgets('les entrees qui exigent une liste le signalent', (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpMore(tester);

    // « demande une liste » : mode courses, comparaison, code-barres,
    // discussion. Le dire evite le cul-de-sac silencieux.
    expect(find.text('demande une liste'), findsNWidgets(4));
  });
}
