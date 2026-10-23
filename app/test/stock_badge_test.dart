// Le badge d'etat d'une provision.
//
// Les zones de « A la maison » ont des fonds colores (lilas, menthe,
// miel, creme). Le seul etat dessine etait un triangle orange en
// contour mince, qui disparaissait sur le fond miel — et il n'y avait
// rien du tout pour « disponible » ni « rupture » : l'absence de
// triangle devait se lire comme une bonne nouvelle.
//
// Ce test garde les deux choses qui rendent le badge lisible : il se
// detache de son fond (3:1, WCAG 1.4.11 pour les elements d'interface),
// et son glyphe se detache de la pastille (4,5:1).
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/contrast.dart';

void main() {
  tearDown(() => AppColors.palette = AppPalette.light);

  final modes = {'clair': AppPalette.light, 'sombre': AppPalette.dark};

  for (final mode in modes.entries) {
    group(mode.key, () {
      setUp(() => AppColors.palette = mode.value);

      test('chaque badge se detache de la zone qui le porte', () {
        for (final etat in StockState.values) {
          final pastille = AppStateBadge.couleurDe(etat);
          // Le pire fond possible : la teinte de SON propre etat,
          // c'est-a-dire la zone dans laquelle il est range.
          final fonds = <String, Color>{
            'surface': AppColors.surface,
            'fond de page': AppColors.background,
            for (final autre in StockState.values)
              'zone ${autre.name}': over(
                AppTint.fill(AppStateBadge.couleurDe(autre)),
                AppColors.surface,
              ),
          };
          for (final fond in fonds.entries) {
            expect(
              contrast(pastille, fond.value),
              greaterThanOrEqualTo(3.0),
              reason: '${etat.name} sur ${fond.key}',
            );
          }
        }
      });

      test('le glyphe se detache de sa pastille', () {
        for (final etat in StockState.values) {
          final pastille = AppStateBadge.couleurDe(etat);
          expect(
            contrast(AppTint.onFilled(pastille), pastille),
            greaterThanOrEqualTo(4.5),
            reason: etat.name,
          );
        }
      });

      test('le texte ecrit a cote se lit aussi', () {
        for (final etat in StockState.values) {
          final encre = AppTint.ink(AppStateBadge.couleurDe(etat));
          expect(
            contrast(encre, AppColors.surface),
            greaterThanOrEqualTo(4.5),
            reason: etat.name,
          );
        }
      });
    });
  }

  test('les quatre etats portent quatre couleurs differentes', () {
    final couleurs = StockState.values.map(AppStateBadge.couleurDe).toSet();
    expect(couleurs, hasLength(StockState.values.length));
  });

  testWidgets('l etat est ECRIT a cote du badge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: AppStateChip(state: StockState.rupture, label: 'Rupture'),
        ),
      ),
    );
    expect(find.text('Rupture'), findsOneWidget);
    expect(find.byType(AppStateBadge), findsOneWidget);
  });

  testWidgets('les formes diffèrent, pas seulement les couleurs', (
    tester,
  ) async {
    // Qui distingue mal le vert et le rouge lit la FORME : disque avec
    // coche, triangle, disque avec croix, disque avec horloge.
    final formes = <IconData>{};
    for (final etat in StockState.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: AppStateBadge(state: etat)),
        ),
      );
      final icones = tester.widgetList<Icon>(find.byType(Icon));
      formes.add(icones.first.icon!);
    }
    expect(formes, hasLength(StockState.values.length));
  });
}
