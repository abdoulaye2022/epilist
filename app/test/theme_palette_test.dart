// Ce que garantit le systeme de couleurs, et que l'oeil ne peut pas
// verifier sans appareil.
//
// Le mode sombre n'existait pas parce que 791 couleurs Material brutes
// vivaient hors du theme : un theme ne corrige pas ce qu'il ne voit
// pas. Elles sont toutes passees en jetons ; ces tests protegent les
// deux proprietes dont depend le resultat.
//
//   1. Les jetons SUIVENT la palette active. Aucun n'est reste figé sur
//      une valeur claire au passage des `const` aux accesseurs.
//   2. Les paires qui se superposent restent LISIBLES, dans les deux
//      modes, selon le calcul de contraste WCAG 2.1.
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/contrast.dart';

void main() {
  tearDown(() => AppColors.palette = AppPalette.light);

  group('les jetons suivent la palette', () {
    test('la palette sombre change tous les jetons de fond et de texte', () {
      AppColors.palette = AppPalette.light;
      final clair = [
        AppColors.background,
        AppColors.surface,
        AppColors.surfaceAlt,
        AppColors.border,
        AppColors.textPrimary,
        AppColors.textSecondary,
        AppColors.textDisabled,
        AppColors.primary,
        AppColors.primaryLight,
        AppColors.onPrimary,
        AppColors.brandBand,
      ];
      AppColors.palette = AppPalette.dark;
      final sombre = [
        AppColors.background,
        AppColors.surface,
        AppColors.surfaceAlt,
        AppColors.border,
        AppColors.textPrimary,
        AppColors.textSecondary,
        AppColors.textDisabled,
        AppColors.primary,
        AppColors.primaryLight,
        AppColors.onPrimary,
        AppColors.brandBand,
      ];
      for (var i = 0; i < clair.length; i++) {
        expect(
          sombre[i],
          isNot(clair[i]),
          reason: 'le jeton n°$i est reste fige sur sa valeur claire',
        );
      }
    });

    test('les jetons invariants ne bougent pas', () {
      // Un voile noir et le blanc pose dessus valent dans les deux modes.
      AppColors.palette = AppPalette.light;
      final avant = [
        AppColors.scrim,
        AppColors.onOverlay,
        AppColors.onWarning,
        AppColors.backdrop,
      ];
      AppColors.palette = AppPalette.dark;
      expect([
        AppColors.scrim,
        AppColors.onOverlay,
        AppColors.onWarning,
        AppColors.backdrop,
      ], avant);
    });

    test('la liste des graphiques suit aussi la palette', () {
      AppColors.palette = AppPalette.light;
      final clair = AppColors.chart;
      AppColors.palette = AppPalette.dark;
      expect(AppColors.chart.length, clair.length);
      expect(AppColors.chart.first, isNot(clair.first));
    });

    testWidgets('AppPaletteBinding pose la palette du theme effectif', (
      tester,
    ) async {
      AppColors.palette = AppPalette.light;

      Future<void> pump(ThemeMode mode) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          builder:
              (context, child) =>
                  AppPaletteBinding(child: child ?? const SizedBox.shrink()),
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      );

      // pumpAndSettle, et non pump : MaterialApp interpose un
      // AnimatedTheme, donc le theme effectif n'arrive qu'au bout de
      // l'animation. C'est aussi vrai dans l'application.
      await pump(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(AppColors.palette.brightness, Brightness.dark);
      expect(AppColors.surface, AppPalette.dark.surface);

      await pump(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(AppColors.palette.brightness, Brightness.light);
      expect(AppColors.surface, AppPalette.light.surface);
    });

    testWidgets('un ecran reconstruit apres un changement de mode', (
      tester,
    ) async {
      // L'invariant qui remplace un KeyedSubtree : un widget qui lit un
      // jeton n'est plus `const`, donc il est recree avec son parent.
      final mode = ValueNotifier(ThemeMode.light);
      addTearDown(mode.dispose);
      await tester.pumpWidget(
        ValueListenableBuilder<ThemeMode>(
          valueListenable: mode,
          builder:
              (context, m, _) => MaterialApp(
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: m,
                builder:
                    (context, child) => AppPaletteBinding(
                      child: child ?? const SizedBox.shrink(),
                    ),
                home: Scaffold(
                  body: Builder(
                    builder:
                        (context) => ColoredBox(
                          key: const Key('sonde'),
                          color: AppColors.surface,
                        ),
                  ),
                ),
              ),
        ),
      );
      ColoredBox box() =>
          tester.widget<ColoredBox>(find.byKey(const Key('sonde')));
      expect(box().color, AppPalette.light.surface);

      mode.value = ThemeMode.dark;
      await tester.pumpAndSettle();
      expect(box().color, AppPalette.dark.surface);
    });
  });

  group('contraste', () {
    for (final entry
        in {'clair': AppPalette.light, 'sombre': AppPalette.dark}.entries) {
      final nom = entry.key;
      final p = entry.value;

      test('$nom : le texte est lisible sur les deux fonds', () {
        for (final fond in [p.surface, p.background, p.surfaceAlt]) {
          expect(
            contrast(p.textPrimary, fond),
            greaterThan(7),
            reason: 'texte principal, mode $nom',
          );
          expect(
            contrast(p.textSecondary, fond),
            greaterThan(4.5),
            reason: 'texte secondaire, mode $nom',
          );
        }
      });

      test('$nom : le contenu est lisible sur les couleurs fortes', () {
        expect(
          contrast(p.onPrimary, p.primary),
          greaterThan(3),
          reason: 'contenu sur le vert de marque, mode $nom',
        );
        expect(
          contrast(p.onBrandBand, p.brandBand),
          greaterThan(4.5),
          reason: 'contenu du bandeau de marque, mode $nom',
        );
        expect(
          contrast(AppColors.onWarning, p.warning),
          greaterThan(4.5),
          reason: 'un orange est trop clair pour porter du blanc',
        );
        expect(
          contrast(AppColors.onWarning, p.gold),
          greaterThan(4.5),
          reason: 'un or est trop clair pour porter du blanc',
        );
        expect(
          contrast(AppColors.onOverlay, AppColors.backdrop),
          greaterThan(15),
          reason: 'une croix de fermeture sur une photo plein ecran',
        );
        expect(
          contrast(p.primaryDark, p.primaryLight),
          greaterThan(4.5),
          reason: 'encre de marque sur fond teinte de marque, mode $nom',
        );
      });

      test('$nom : chaque encre d etat est lisible sur son fond teinte', () {
        final familles = {
          'succes': [p.successInk, AppColors.successTint],
          'alerte': [p.warningInk, AppColors.warningTint],
          'erreur': [p.errorInk, AppColors.errorTint],
          'info': [p.infoInk, AppColors.infoTint],
          'or': [p.goldInk, AppColors.goldTint],
        };
        familles.forEach((nomFamille, paire) {
          // Le fond teinte est translucide : il se compose sur la surface.
          final fond = over(paire[1], p.surface);
          expect(
            contrast(paire[0], fond),
            greaterThan(4.5),
            reason: '$nomFamille, mode $nom',
          );
        });
      });

      test('$nom : les accents categoriels se distinguent de la surface', () {
        for (final accent in [p.violet, p.indigo, p.teal, p.brown, p.slate]) {
          expect(
            contrast(accent, p.surface),
            greaterThan(2.5),
            reason: 'un accent invisible sur la surface, mode $nom',
          );
        }
      });
    }

    test('le blanc sur voile reste lisible dans les deux modes', () {
      final voile = over(AppColors.scrim, const Color(0xFF9E9E9E));
      expect(contrast(AppColors.onOverlay, voile), greaterThan(4.5));
    });
  });

  group('AppTint', () {
    test('ink assombrit en clair et eclaircit en sombre', () {
      const source = Color(0xFF7E57C2);
      AppColors.palette = AppPalette.light;
      final clair = AppTint.ink(source);
      AppColors.palette = AppPalette.dark;
      final sombre = AppTint.ink(source);
      expect(luminance(clair), lessThan(luminance(source)));
      expect(luminance(sombre), greaterThan(luminance(source)));
    });

    test('fill et line sont translucides, donc suivent le fond', () {
      const source = Color(0xFF7E57C2);
      expect(AppTint.fill(source).a, lessThan(0.2));
      expect(AppTint.line(source).a, lessThan(0.5));
      expect(AppTint.line(source).a, greaterThan(AppTint.fill(source).a));
    });

    test('ink reste lisible sur fill, pour une couleur quelconque', () {
      for (final source in [
        const Color(0xFF7E57C2),
        const Color(0xFFF2B01E),
        const Color(0xFF00897B),
        const Color(0xFFD64545),
      ]) {
        for (final p in [AppPalette.light, AppPalette.dark]) {
          AppColors.palette = p;
          final fond = over(AppTint.fill(source), p.surface);
          expect(
            contrast(AppTint.ink(source), fond),
            greaterThan(4.5),
            reason: 'source $source, mode ${p.brightness.name}',
          );
        }
      }
    });
  });
}
