// L'ecran de reussite des courses.
//
// Le dernier article coche ne renvoyait sur rien : on refermait le mode
// courses, et rien ne disait que c'etait fini. La planche celebre la
// fin, et propose ou aller ensuite.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/screens/shopping_success_screen.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AppColors.palette = AppPalette.light);

  Future<void> ouvrir(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const ShoppingSuccessScreen(
        listName: 'Courses de la semaine',
        itemsCount: 17,
      ),
    ),
  );

  testWidgets('il dit que c est fini, et ce qui a ete fait', (tester) async {
    await ouvrir(tester);
    expect(find.text('Courses terminées, bravo !'), findsOneWidget);
    expect(find.textContaining('Courses de la semaine'), findsOneWidget);
    expect(find.textContaining('17'), findsOneWidget);
  });

  testWidgets('il propose les trois suites', (tester) async {
    await ouvrir(tester);
    // Le troisieme bouton est sous le pli dans la fenetre de test : la
    // liste ne construit que ce qu'elle affiche.
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Voir mes budgets'), findsOneWidget);
    expect(find.text('Retour au tableau de bord'), findsOneWidget);
    expect(find.text('Retour à mes listes'), findsOneWidget);
  });

  testWidgets('en mode sombre, la coche reste lisible sur le vert', (
    tester,
  ) async {
    AppColors.palette = AppPalette.dark;
    await ouvrir(tester);
    await tester.pumpAndSettle();
    final coche = tester.widget<Icon>(find.byIcon(Icons.check_rounded));
    expect(coche.color, AppColors.onPrimary);
  });
}
