// La barre du bas a devore l'ecran.
//
// Sur l'appareil, l'accueil s'ouvrait vide, les cinq icones centrees a
// mi-hauteur. L'arbre de rendu de l'app en marche a donne la reponse :
//
//     RenderIndexedStack ... id=_ScaffoldSlot.body
//       constraints: BoxConstraints(0.0<=w<=384.0, h=0.0)
//       size: Size(384.0, 0.0)
//
// Le Scaffold mesure sa barre AVANT son corps, en lui offrant toute la
// hauteur de l'ecran. Chaque bouton etait un Column centre en
// MainAxisSize.max : il a pris les 832 dp offerts, la barre avec lui,
// et il n'est rien reste pour la page.
//
// Ces tests tiennent les deux bouts : la barre reste courte, et le
// corps garde sa hauteur.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/main_bottom_bar.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cleCorps = ValueKey('corps');

  Future<MainTab?> poser(WidgetTester tester, {MainTab? attendu}) async {
    MainTab? choisi;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: const SizedBox.expand(key: cleCorps),
          bottomNavigationBar: MainBottomBar(
            current: MainTab.home,
            onSelect: (t) => choisi = t,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return choisi;
  }

  testWidgets('la barre ne prend que sa hauteur', (tester) async {
    await poser(tester);
    final barre = tester.getSize(find.byType(MainBottomBar)).height;
    expect(barre, greaterThanOrEqualTo(MainBottomBar.itemHeight));
    // Large, mais sans commune mesure avec les 832 dp de l'ecran.
    expect(barre, lessThan(130));
  });

  testWidgets('le corps de la page garde sa hauteur', (tester) async {
    // C'est l'assertion qui aurait attrape le defaut : la barre peut
    // bien grossir, c'est le corps a zero qui vide l'ecran.
    await poser(tester);
    final ecran = tester.getSize(find.byType(MaterialApp)).height;
    final corps = tester.getSize(find.byKey(cleCorps)).height;
    expect(corps, greaterThan(0));
    expect(corps, greaterThan(ecran * 0.8));
  });

  testWidgets('les cinq destinations sont la, une seule ecrite', (
    tester,
  ) async {
    await poser(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    // La planche n'ecrit le libelle que sous Accueil ; les quatre
    // autres ne le disent qu'aux lecteurs d'ecran.
    expect(find.text(l10n.tabHome), findsOneWidget);
    expect(find.text(l10n.priceAlerts), findsNothing);
    // Les quatre icones muettes n'ont que leur nom parle : sans lui,
    // elles seraient des dessins sans legende. (Accueil, lui, l'ecrit,
    // et son noeud porte deux fois le mot — d'ou la recherche large.)
    expect(
      find.bySemanticsLabel(RegExp(l10n.tabHome)),
      findsAtLeastNWidgets(1),
    );
    for (final libelle in [
      l10n.myShoppingLists,
      l10n.preShopping,
      l10n.priceAlerts,
      l10n.allSections,
    ]) {
      expect(
        find.bySemanticsLabel(libelle),
        findsAtLeastNWidgets(1),
        reason: libelle,
      );
    }
  });

  testWidgets('toucher une icone annonce son onglet', (tester) async {
    MainTab? choisi;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: const SizedBox.expand(key: cleCorps),
          bottomNavigationBar: MainBottomBar(
            current: MainTab.home,
            onSelect: (t) => choisi = t,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    await tester.tap(find.bySemanticsLabel(l10n.priceAlerts).first);
    expect(choisi, MainTab.alerts);
  });
}
