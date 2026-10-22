// widgets/common/store_front.dart - La devanture illustrée d'un magasin.
//
// La planche « Version B » donne à chaque magasin sa vitrine : auvent
// rayé, deux fenêtres, une porte, un ciel pâle. Le dessin sert à
// RECONNAÎTRE le magasin d'un coup d'œil, avant d'en lire le nom — ce
// que la pastille grise identique sur chaque ligne ne permettait pas.
//
// Il est dessiné, pas photographié : aucune image de marque réelle n'est
// embarquée, et la teinte vient de la palette, donc elle suit le mode
// sombre.
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';

class StoreFront extends StatelessWidget {
  const StoreFront({super.key, required this.seed, this.height = 130});

  /// Choisit la teinte de l'auvent. Le même magasin garde donc toujours
  /// la même devanture, sans qu'on ait à la stocker.
  final int seed;

  final double height;

  /// Les teintes possibles d'auvent, prises dans les sept couleurs.
  static List<Color> _tints() => [
    AppColors.primary,
    AppColors.warning,
    AppColors.error,
    AppColors.accent,
    AppColors.primaryDark,
  ];

  @override
  Widget build(BuildContext context) {
    final tints = _tints();
    final tint = tints[seed.abs() % tints.length];

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _StoreFrontPainter(
            sky: AppTint.fill(AppColors.gold),
            facade: AppColors.surface,
            awning: tint,
            window: AppTint.fill(tint),
            stripe: AppColors.surface,
            line: AppColors.border,
          ),
        ),
      ),
    );
  }
}

class _StoreFrontPainter extends CustomPainter {
  _StoreFrontPainter({
    required this.sky,
    required this.facade,
    required this.awning,
    required this.window,
    required this.stripe,
    required this.line,
  });

  final Color sky, facade, awning, window, stripe, line;

  @override
  void paint(Canvas canvas, Size size) {
    // Les coordonnées de la planche sont données dans un cadre de
    // 360 × 130 : on les y ramène une fois pour toutes.
    final sx = size.width / 360, sy = size.height / 130;
    Rect r(double x, double y, double w, double h) =>
        Rect.fromLTWH(x * sx, y * sy, w * sx, h * sy);
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    final pinceau = Paint()..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, pinceau..color = sky);
    canvas.drawRect(r(55, 38, 250, 92), pinceau..color = facade);

    // L'auvent, en trapèze.
    canvas.drawPath(
      Path()
        ..moveTo(45 * sx, 62 * sy)
        ..lineTo(315 * sx, 62 * sy)
        ..lineTo(300 * sx, 38 * sy)
        ..lineTo(60 * sx, 38 * sy)
        ..close(),
      pinceau..color = awning,
    );

    final trait = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7 * sx
      ..color = stripe;
    for (final (x1, x2) in const [
      (82.0, 93.0),
      (128.0, 133.0),
      (174.0, 174.0),
      (220.0, 215.0),
      (266.0, 255.0),
    ]) {
      canvas.drawLine(p(x1, 38), p(x2, 62), trait);
    }

    // Deux fenêtres et la porte.
    canvas.drawRect(r(86, 82, 52, 34), pinceau..color = window);
    canvas.drawRect(r(222, 82, 52, 34), pinceau..color = window);
    canvas.drawRect(r(158, 76, 44, 54), pinceau..color = awning);

    // La vitrine est cerclée, pour tenir même quand la surface et le
    // ciel se ressemblent en mode sombre.
    canvas.drawRect(
      r(55, 38, 250, 92),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * sx
        ..color = line,
    );

    canvas.drawCircle(p(118, 24), 15 * sx, pinceau..color = awning);
    canvas.drawCircle(p(298, 20), 10 * sx, pinceau..color = awning);
  }

  @override
  bool shouldRepaint(_StoreFrontPainter old) =>
      old.awning != awning ||
      old.sky != sky ||
      old.facade != facade ||
      old.window != window;
}
