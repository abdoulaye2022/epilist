// Ce que la planche « Version B » promet en FORME, et que le theme doit
// tenir dans les deux modes.
//
// Trois promesses, chacune verifiable sans appareil :
//   1. un bouton pleine largeur fait 60 dp de haut, en gelule ;
//   2. le texte courant part de 17, pas de 14 ;
//   3. les titres sortent en Sora au bon poids — et Sora est une fonte
//      VARIABLE, donc `fontWeight` seul ne suffit pas : sans
//      `fontVariations`, un titre « extra-gras » s'affiche en 400.
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/contrast.dart';

void main() {
  tearDown(() => AppColors.palette = AppPalette.light);

  for (final entry
      in {'clair': AppTheme.light, 'sombre': AppTheme.dark}.entries) {
    final nom = entry.key;
    final t = entry.value;

    test('$nom : les boutons font 60 dp et sont en gelule', () {
      for (final style in [
        t.filledButtonTheme.style,
        t.elevatedButtonTheme.style,
        t.outlinedButtonTheme.style,
      ]) {
        final taille = style!.minimumSize!.resolve({})!;
        expect(taille.height, AppSizes.button, reason: 'hauteur, mode $nom');
        expect(
          style.shape!.resolve({}),
          isA<StadiumBorder>(),
          reason: 'forme, mode $nom',
        );
      }
    });

    test('$nom : le texte courant est agrandi', () {
      expect(t.textTheme.bodyMedium!.fontSize, greaterThanOrEqualTo(17));
      expect(t.textTheme.bodyLarge!.fontSize, greaterThanOrEqualTo(18));
      expect(t.textTheme.labelLarge!.fontSize, greaterThanOrEqualTo(17));
      // Une cible touchable de 60 dp ne sert a rien si le libelle
      // dedans reste a 15.
      expect(
        t.filledButtonTheme.style!.textStyle!.resolve({})!.fontSize,
        greaterThanOrEqualTo(17),
      );
    });

    test('$nom : le texte courant porte la fonte lisible', () {
      // Atkinson Hyperlegible est posee sur le ThemeData, donc heritee
      // par tout ce qui ne demande pas Sora.
      expect(t.textTheme.bodyMedium!.fontFamily, AppFonts.body);
      expect(t.textTheme.bodyLarge!.fontFamily, AppFonts.body);
    });

    test('$nom : les titres sortent en Sora, et au bon poids', () {
      for (final style in [t.textTheme.headlineSmall, t.textTheme.titleLarge]) {
        expect(style!.fontFamily, AppFonts.display, reason: 'famille, $nom');
        // Sans cet axe, la fonte variable rend son instance par
        // defaut — un titre maigre.
        expect(
          style.fontVariations,
          isNotEmpty,
          reason: 'poids variable absent, mode $nom',
        );
        expect(style.fontVariations!.first.axis, 'wght');
        expect(style.fontVariations!.first.value, greaterThanOrEqualTo(700));
      }
    });
  }

  test('les coins sont tres arrondis, et la gelule est une gelule', () {
    expect(AppRadius.md, greaterThanOrEqualTo(16));
    expect(AppRadius.lg, greaterThan(AppRadius.md));
    expect(AppRadius.pill, greaterThanOrEqualTo(999));
  });

  group('le degrade du tableau de bord', () {
    test('suit le mode, et ne garde pas ses sept arrets lumineux', () {
      AppColors.palette = AppPalette.light;
      final clair = AppGradients.home.colors;
      AppColors.palette = AppPalette.dark;
      final sombre = AppGradients.home.colors;

      expect(clair.length, 7);
      expect(sombre.length, clair.length);
      for (var i = 0; i < clair.length; i++) {
        expect(sombre[i], isNot(clair[i]), reason: 'arret n°$i fige');
      }
    });

    test('le texte reste lisible dessus, dans les deux modes', () {
      for (final p in [AppPalette.light, AppPalette.dark]) {
        AppColors.palette = p;
        for (final arret in AppGradients.home.colors) {
          expect(
            contrast(p.textPrimary, arret),
            greaterThan(4.5),
            reason: 'texte sur un arret du degrade, mode ${p.brightness.name}',
          );
        }
      }
    });
  });

  group('La carte budget de la planche', () {
    test("l'orange du budget porte une encre lisible, dans les deux modes", () {
      // La planche : « Orange #F97316 : tout ce qui touche au budget,
      // sur toutes les pages avec la meme teinte ». Elle ecrit aussi
      // que cet orange porte du TEXTE SOMBRE — et sa propre maquette
      // pose pourtant du blanc, qui n'y donne que 2,8.
      for (final p in [AppPalette.light, AppPalette.dark]) {
        AppColors.palette = p;
        expect(
          contrast(AppColors.onWarning, p.warning),
          greaterThan(4.5),
          reason: 'encre du budget, mode ${p.brightness.name}',
        );
        expect(
          contrast(const Color(0xFFFFFFFF), p.warning),
          lessThan(4.5),
          reason: 'le blanc, lui, ne passe pas : mode ${p.brightness.name}',
        );
      }
    });
  });
}
