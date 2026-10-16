// Calcul de contraste WCAG 2.1, partage par les tests de couleur.
//
// C'est la seule chose qu'un test peut verifier a la place de l'oeil :
// qu'un texte ou une icone se detache de ce qu'il y a derriere. Le seuil
// de 4,5 vaut pour le texte courant, 3,0 pour le gros texte, les icones
// et les elements d'interface (WCAG 1.4.3 et 1.4.11).
import 'dart:math' as math;

import 'package:flutter/material.dart';

double luminance(Color c) {
  double canal(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * canal(c.r) + 0.7152 * canal(c.g) + 0.0722 * canal(c.b);
}

/// Rapport de contraste entre deux couleurs OPAQUES.
double contrast(Color a, Color b) {
  final la = luminance(a), lb = luminance(b);
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Compose une couleur translucide sur un fond opaque. Les fonds teintes
/// du theme sont volontairement translucides : sans cette composition,
/// les calculer n'a aucun sens.
Color over(Color fg, Color bg) => Color.from(
  alpha: 1,
  red: fg.r * fg.a + bg.r * (1 - fg.a),
  green: fg.g * fg.a + bg.g * (1 - fg.a),
  blue: fg.b * fg.a + bg.b * (1 - fg.a),
);
