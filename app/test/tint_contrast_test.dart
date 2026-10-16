// Aucune icone, aucun texte de la meme teinte que son fond teinte.
//
// Le motif etait partout : `Colors.orange` pose sur `Colors.orange[50]`,
// soit 2,0 de contraste — en dessous des 3,0 que WCAG demande a une
// icone. Les jetons `*Ink` existent pour cela : ils donnent la couleur
// du CONTENU sur le fond teinte de leur famille.
//
// Ce test lit les sources. C'est volontaire : il ne verifie pas un
// widget en particulier, il verifie qu'aucun nouvel ecran ne reintroduit
// la paire. Il est au meme rang que scripts/check_raw_colors.sh.
import 'dart:io';

import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/contrast.dart';

/// Les jetons nommes, resolus dans la palette active.
Map<String, Color> _jetons() => {
  'background': AppColors.background,
  'surface': AppColors.surface,
  'surfaceAlt': AppColors.surfaceAlt,
  'border': AppColors.border,
  'textPrimary': AppColors.textPrimary,
  'textSecondary': AppColors.textSecondary,
  'textDisabled': AppColors.textDisabled,
  'primary': AppColors.primary,
  'primaryDark': AppColors.primaryDark,
  'primaryLight': AppColors.primaryLight,
  'onPrimary': AppColors.onPrimary,
  'onOverlay': AppColors.onOverlay,
  'backdrop': AppColors.backdrop,
  'onWarning': AppColors.onWarning,
  'brandBand': AppColors.brandBand,
  'onBrandBand': AppColors.onBrandBand,
  'accent': AppColors.accent,
  'accentLight': AppColors.accentLight,
  'success': AppColors.success,
  'successInk': AppColors.successInk,
  'successTint': AppColors.successTint,
  'successBorder': AppColors.successBorder,
  'warning': AppColors.warning,
  'warningInk': AppColors.warningInk,
  'warningTint': AppColors.warningTint,
  'warningBorder': AppColors.warningBorder,
  'error': AppColors.error,
  'errorInk': AppColors.errorInk,
  'errorTint': AppColors.errorTint,
  'errorBorder': AppColors.errorBorder,
  'info': AppColors.info,
  'infoInk': AppColors.infoInk,
  'infoTint': AppColors.infoTint,
  'infoBorder': AppColors.infoBorder,
  'violet': AppColors.violet,
  'violetTint': AppColors.violetTint,
  'indigo': AppColors.indigo,
  'indigoTint': AppColors.indigoTint,
  'teal': AppColors.teal,
  'tealTint': AppColors.tealTint,
  'gold': AppColors.gold,
  'goldInk': AppColors.goldInk,
  'goldTint': AppColors.goldTint,
  'goldBorder': AppColors.goldBorder,
  'brown': AppColors.brown,
  'brownTint': AppColors.brownTint,
  'slate': AppColors.slate,
  'slateTint': AppColors.slateTint,
};

/// `BoxDecoration(color: AppColors.X,` — le fond d'une pastille.
final _fond = RegExp(
  r'BoxDecoration\(\s*(?:gradient[^)]*\)\s*,\s*)?color:\s*AppColors\.(\w+)\s*,',
);

/// La premiere icone ou le premier texte qui suit, dans la meme pastille.
final _contenu = RegExp(
  r'(?:Icon\([^)]{0,80}?color:|style:\s*(?:const\s*)?TextStyle\('
  r'[^)]{0,120}?color:)\s*AppColors\.(\w+)',
  dotAll: true,
);

class _Paire {
  _Paire(this.fichier, this.ligne, this.contenu, this.fond);
  final String fichier;
  final int ligne;
  final String contenu;
  final String fond;
  @override
  String toString() => '$fichier:$ligne — $contenu sur $fond';
}

List<_Paire> _paires() {
  final paires = <_Paire>[];
  for (final entite in Directory('lib').listSync(recursive: true)) {
    if (entite is! File || !entite.path.endsWith('.dart')) continue;
    if (entite.path.startsWith('lib/theme/')) continue;
    final source = entite.readAsStringSync();
    for (final f in _fond.allMatches(source)) {
      final fenetre = source.substring(
        f.end,
        f.end + 500 > source.length ? source.length : f.end + 500,
      );
      final c = _contenu.firstMatch(fenetre);
      if (c == null) continue;
      final ligne = source.substring(0, f.start).split('\n').length;
      paires.add(_Paire(entite.path, ligne, c.group(1)!, f.group(1)!));
    }
  }
  return paires;
}

void main() {
  tearDown(() => AppColors.palette = AppPalette.light);

  test('le lecteur trouve bien des pastilles a verifier', () {
    // Garde-fou : si les regex cessent de reconnaitre le code, le test
    // passerait en ne verifiant rien du tout.
    expect(_paires().length, greaterThan(60));
  });

  for (final palette in [AppPalette.light, AppPalette.dark]) {
    final nom = palette.brightness == Brightness.dark ? 'sombre' : 'clair';

    test('$nom : aucun contenu ne se fond dans sa pastille', () {
      AppColors.palette = palette;
      final jetons = _jetons();
      final fautes = <String>[];

      for (final paire in _paires()) {
        final fond = jetons[paire.fond];
        final contenu = jetons[paire.contenu];
        if (fond == null || contenu == null) continue;
        final fondOpaque = over(fond, AppColors.surface);
        final rapport = contrast(over(contenu, fondOpaque), fondOpaque);
        if (rapport < 3.0) {
          fautes.add('${rapport.toStringAsFixed(2)}  $paire');
        }
      }

      expect(
        fautes,
        isEmpty,
        reason:
            'Contenu trop proche de son fond (seuil WCAG 3,0 pour une '
            'icone). Utilisez l encre de la famille — warningInk sur '
            'warningTint, infoInk sur infoTint, primaryDark sur '
            'primaryLight :\n${fautes.join('\n')}',
      );
    });
  }
}
