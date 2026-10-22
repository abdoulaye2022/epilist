// L'en-tete de toutes les pages.
//
// La planche demande le menu « en haut a gauche du telephone sur les
// autres ecrans ». L'application, elle, a une pile de navigation : la
// fleche retour ne peut pas disparaitre. Les deux cohabitent donc dans
// le meme coin, et ces tests verrouillent les trois cas — page empilee
// avec tiroir, page de la coquille, page d'avant la connexion (sans
// tiroir, donc sans bouton menu : en afficher un leverait une
// exception).
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget page({required Widget scaffold, bool empilee = false}) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home:
        empilee
            ? Navigator(
              onGenerateRoute:
                  (_) => MaterialPageRoute(
                    builder: (_) => const Scaffold(body: SizedBox()),
                  ),
            )
            : scaffold,
  );

  Future<void> poserEmpilee(WidgetTester tester, Widget scaffold) async {
    final cle = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        navigatorKey: cle,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    unawaited(
      cle.currentState!.push(MaterialPageRoute(builder: (_) => scaffold)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('page empilee avec tiroir : retour ET menu', (tester) async {
    await poserEmpilee(
      tester,
      Scaffold(
        drawer: const Drawer(child: Text('tiroir')),
        appBar: const AppTopBar(title: 'Mes budgets'),
        body: const SizedBox(),
      ),
    );
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    expect(find.text('Mes budgets'), findsOneWidget);
  });

  testWidgets('le menu ouvre bien le tiroir de la page', (tester) async {
    await poserEmpilee(
      tester,
      Scaffold(
        drawer: const Drawer(child: Text('contenu du tiroir')),
        appBar: const AppTopBar(title: 'Mes budgets'),
        body: const SizedBox(),
      ),
    );
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    expect(find.text('contenu du tiroir'), findsOneWidget);
  });

  testWidgets('sans tiroir, aucun bouton menu', (tester) async {
    // Les ecrans d'avant la connexion. Un bouton menu y serait un piege :
    // Scaffold.of(context).openDrawer() leverait une exception.
    await poserEmpilee(
      tester,
      const Scaffold(
        appBar: AppTopBar(title: 'Changer mon mot de passe'),
        body: SizedBox(),
      ),
    );
    expect(find.byIcon(Icons.menu_rounded), findsNothing);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });

  testWidgets('page de premier plan : menu seul, pas de retour', (
    tester,
  ) async {
    await tester.pumpWidget(
      page(
        scaffold: Scaffold(
          drawer: const Drawer(child: Text('tiroir')),
          appBar: const AppTopBar(title: 'Accueil'),
          body: const SizedBox(),
        ),
      ),
    );
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
  });

  testWidgets('le titre est en Sora, et le sous-titre le suit', (tester) async {
    await tester.pumpWidget(
      page(
        scaffold: const Scaffold(
          appBar: AppTopBar(
            title: 'Les recus',
            subtitle: 'Courses de la semaine',
          ),
          body: SizedBox(),
        ),
      ),
    );
    final titre = tester.widget<Text>(find.text('Les recus'));
    expect(titre.style!.fontFamily, AppFonts.display);
    // Sora est une fonte VARIABLE : le poids se demande sur l'axe wght.
    expect(titre.style!.fontVariations!.first.value, greaterThanOrEqualTo(700));
    expect(find.text('Courses de la semaine'), findsOneWidget);
  });
}

void unawaited(Future<void> future) {}
