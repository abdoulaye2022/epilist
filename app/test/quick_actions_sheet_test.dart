// Ce que propose le bouton + de la barre du bas.
//
// Avant : il creait une liste, et rien d'autre — la place la plus
// accessible de l'ecran pour un geste hebdomadaire. Quatre des actions
// ci-dessous n'etaient atteignables que depuis le tableau de bord ou
// depuis le fond d'un dialogue (code-barres), et la photo d'un produit
// demandait six appuis.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/common/quick_actions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la feuille du bouton + propose les six actions',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => QuickActionsSheet.show(context),
              child: const Text('+'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();

    expect(find.text('Que voulez-vous ajouter ?'), findsOneWidget);
    for (final action in [
      'Ajouter un article',
      'Scanner un reçu',
      'Ajouter une facture',
      'Scanner un code-barres',
      "Photo d'un produit",
      'Créer une liste',
    ]) {
      expect(find.text(action), findsOneWidget,
          reason: '« $action » absent de la feuille');
    }
  });
}
