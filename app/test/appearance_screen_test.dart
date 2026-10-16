// L'ecran qui expose le mode sombre.
//
// Le mode sombre n'etait pas « manquant » par oubli : il etait
// impossible, 791 couleurs vivant hors du theme. Maintenant qu'il
// existe, il faut qu'on puisse le choisir — et le voir avant de
// parcourir l'application, d'ou l'apercu.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/screens/appearance_screen.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/theme/theme_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appThemeMode.value = ThemeMode.system;
  });
  tearDown(() {
    appThemeMode.value = ThemeMode.system;
    AppColors.palette = AppPalette.light;
  });

  Future<void> ouvrir(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const AppearanceScreen(),
    ),
  );

  testWidgets('propose les trois choix, et marque celui en cours', (
    tester,
  ) async {
    await ouvrir(tester);
    expect(find.text('Comme le système'), findsOneWidget);
    expect(find.text('Clair'), findsOneWidget);
    expect(find.text('Sombre'), findsOneWidget);
    // Un seul choix coche a la fois.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('choisir « Sombre » enregistre le choix', (tester) async {
    await ouvrir(tester);
    await tester.tap(find.text('Sombre'));
    await tester.pumpAndSettle();
    expect(appThemeMode.value, ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_theme_mode'), 'dark');

    // Le marqueur a suivi, sans quitter l'ecran.
    final coche = tester.widget<ListTile>(
      find.ancestor(of: find.text('Sombre'), matching: find.byType(ListTile)),
    );
    expect(coche.trailing, isNotNull);
  });

  testWidgets('l apercu montre un echantillon de chaque etat', (tester) async {
    await ouvrir(tester);
    expect(find.text('Aperçu'), findsOneWidget);
    for (final etiquette in ['OK', '!', '×', 'i']) {
      expect(
        find.text(etiquette),
        findsOneWidget,
        reason: 'echantillon « $etiquette » absent de l apercu',
      );
    }
  });
}
