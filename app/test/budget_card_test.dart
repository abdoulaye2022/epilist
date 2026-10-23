// La carte d'un budget, et sa pastille de pourcentage.
//
// Elle tenait dans un carre de 44 x 44 points, en gras. « 280 % » y
// fait 46 points de large : le texte passait a la ligne, le signe « % »
// se retrouvait seul sous le nombre, et l'ensemble debordait de la
// pastille.
//
// Le public de cette planche agrandit le texte — c'est la premiere
// chose qu'il fait dans les reglages de son telephone — donc le test
// relit la carte jusqu'au double, sur un ecran etroit.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/budget.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/budget/budget_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AppColors.palette = AppPalette.light);

  Budget budget({required double pourcentage, String nom = 'Budget Juin'}) {
    final maintenant = DateTime(2026, 8, 1);
    return Budget(
      id: 1,
      userId: 1,
      name: nom,
      budgetAmount: 10,
      formattedBudgetAmount: r'$10.00',
      periodType: BudgetPeriodType.monthly,
      startDate: maintenant,
      endDate: DateTime(2026, 8, 31),
      alertThreshold: 80,
      isActive: true,
      spentAmount: 10 * pourcentage / 100,
      formattedSpentAmount: r'$27.99',
      remainingAmount: 0,
      formattedRemainingAmount: r'$0.00',
      spentPercentage: pourcentage,
      daysRemaining: 0,
      status: pourcentage >= 100 ? BudgetStatus.exceeded : BudgetStatus.ok,
      isExceeded: pourcentage >= 100,
      isNearLimit: pourcentage >= 80,
      shouldShowAlert: false,
      createdAt: maintenant,
      updatedAt: maintenant,
    );
  }

  Future<void> poser(
    WidgetTester tester,
    Budget b, {
    double largeur = 360,
    double echelle = 1.0,
  }) async {
    tester.view.physicalSize = Size(largeur, 900);
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
          child: Scaffold(
            body: SingleChildScrollView(child: BudgetCard(budget: b)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('« 280 % » tient sur UNE ligne', (tester) async {
    await poser(tester, budget(pourcentage: 280));

    // L'espace de « 280 % » est insecable en francais : il vient de la
    // locale, et c'est justement ce qui empeche la coupure.
    final pastille = find.textContaining('280');
    expect(pastille, findsWidgets);

    final texte = tester.widget<Text>(pastille.first);
    expect(texte.maxLines, 1);
    expect(texte.softWrap, isFalse);

    // Une seule ligne DESSINEE, et pas seulement demandee.
    final rendu = tester.renderObject<RenderBox>(pastille.first);
    expect(rendu.size.height, lessThan(40));
  });

  testWidgets('rien ne deborde, meme au double grossissement', (tester) async {
    for (final echelle in [1.0, 1.3, 1.6, 2.0]) {
      for (final pct in [7.0, 100.0, 280.0]) {
        await poser(tester, budget(pourcentage: pct), echelle: echelle);
        expect(
          tester.takeException(),
          isNull,
          reason: 'grossissement $echelle a $pct %',
        );
      }
    }
  });

  testWidgets('la pastille s elargit avec le nombre', (tester) async {
    await poser(tester, budget(pourcentage: 7));
    final petite =
        tester.renderObject<RenderBox>(find.textContaining('7').first).size;

    await poser(tester, budget(pourcentage: 280));
    final grande =
        tester.renderObject<RenderBox>(find.textContaining('280').first).size;

    // Elle se mesure sur son contenu : un carre fige coupait le texte.
    expect(grande.width, greaterThan(petite.width));
  });
}
