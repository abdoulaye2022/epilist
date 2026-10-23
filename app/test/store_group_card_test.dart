// La carte d'un magasin dans « Factures ».
//
// Ses deux pastilles — « 3 factures », « Derniere visite : 12/10/2026 »
// — tenaient dans une Row. Sur un ecran de 320 dp, elles debordaient de
// 29 px par la droite : la date etait coupee, et la rayure jaune et
// noire s'affichait par-dessus.
//
// Ce test pose les pastilles dans une fenetre ETROITE, puis les relit en
// grossissant le texte comme le font les reglages du telephone. Une
// Row ne peut pas s'etirer ; un Wrap passe a la ligne.
//
// Les pastilles seules, et non la carte entiere : celle-ci demande les
// blocs de devise (`FormattedAmount`), que monter ici couterait plus
// cher que ce que le test verifierait.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/receipts/store_group_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AppColors.palette = AppPalette.light);

  Future<void> poser(
    WidgetTester tester, {
    double largeur = 320,
    double echelle = 1.0,
  }) async {
    tester.view.physicalSize = Size(largeur, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(echelle)),
          child: const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: StoreStatChips(
                  receiptsCount: 3,
                  lastVisit: '12/10/2026',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sur un ecran etroit, rien ne deborde', (tester) async {
    await poser(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('et rien ne deborde non plus quand le texte grossit', (
    tester,
  ) async {
    // Le public de cette planche agrandit le texte : c'est la premiere
    // chose qu'il fait dans les reglages de son telephone, et Android
    // monte jusqu'a deux fois.
    for (final echelle in [1.0, 1.3, 1.6, 2.0]) {
      await poser(tester, echelle: echelle);
      expect(tester.takeException(), isNull, reason: 'grossissement $echelle');
    }
  });

  testWidgets('les deux pastilles sont la, et lisibles', (tester) async {
    await poser(tester);
    expect(find.textContaining('3'), findsWidgets);
    expect(find.textContaining('12/10/2026'), findsOneWidget);
  });
}
