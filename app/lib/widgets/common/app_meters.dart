// widgets/common/app_meters.dart - Tout ce qui MESURE, sur la planche
// « Version B ».
//
// Une règle unique les gouverne : **un chiffre dessiné est toujours
// doublé du même chiffre écrit**. Une jauge dit « 85 pour cent pleine »
// sous elle, une barre de tendance porte son montant au-dessus, une
// part écrit son pourcentage à côté de son nom. Sans cela, la mesure
// n'existe que pour qui voit bien et distingue les couleurs — et les
// barres de l'application n'avaient, jusqu'ici, aucun texte.
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Jauge horizontale, et son état écrit juste en dessous.
///
/// [ratio] est borné à [0, 1] : une liste remplie à 120 % existe dans
/// les données, pas dans une barre.
class AppGauge extends StatelessWidget {
  const AppGauge({
    super.key,
    required this.ratio,
    required this.label,
    this.color,
    this.semanticLabel,
    this.labelColor,
    this.labelMaxLines,
  });

  final double ratio;

  /// Ce qui est écrit sous la barre : « 85 pour cent pleine », « 29
  /// pour cent utilisé, 355 $ restants ».
  final String label;

  final Color? color;

  /// Lu par les lecteurs d'écran à la place de la barre. Par défaut
  /// [label], qui est déjà une phrase.
  final String? semanticLabel;

  /// L'encre de la phrase. Par défaut celle du texte courant — mais sur
  /// un fond vert plein, le texte courant serait sombre sur sombre.
  final Color? labelColor;

  /// Borne le nombre de lignes de la phrase. À ne poser que dans une
  /// boîte de hauteur FIXE : une phrase qui passe de deux lignes à
  /// trois y fait déborder toute la carte.
  final int? labelMaxLines;

  @override
  Widget build(BuildContext context) {
    final teinte = color ?? AppColors.primaryVivid;
    final r = ratio.isNaN ? 0.0 : ratio.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: semanticLabel ?? label,
          child: ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: SizedBox(
                height: 16,
                child: Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: AppColors.border)),
                    FractionallySizedBox(
                      widthFactor: r,
                      child: ColoredBox(color: teinte),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        Text(
          label,
          maxLines: labelMaxLines,
          overflow: labelMaxLines == null ? null : TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: labelColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Le compteur vivant : « 3 articles restants sur 17 », sa phrase, et sa
/// barre. Il s'annonce aux lecteurs d'écran à chaque changement, ce qui
/// est tout l'intérêt d'un compteur pendant les courses.
class AppCounterCard extends StatelessWidget {
  const AppCounterCard({
    super.key,
    required this.count,
    required this.sentence,
    required this.ratio,
    this.color,
  });

  /// La ligne forte : « 3 articles restants sur 17 ».
  final String count;

  /// Ce qu'il reste à faire, en une phrase complète.
  final String sentence;

  final double ratio;

  /// Fond de la carte. Le jaune poussin par défaut, comme sur la
  /// planche — il porte l'encre sombre, jamais du blanc.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fond = color ?? AppColors.gold;
    final r = ratio.isNaN ? 0.0 : ratio.clamp(0.0, 1.0);

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md + 4,
          AppSpacing.md + 2,
          AppSpacing.md + 4,
          AppSpacing.md + 2,
        ),
        decoration: BoxDecoration(
          color: fond,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count,
              style: AppFonts.displayStyle(
                size: 26,
                color: AppColors.onWarning,
                height: 1.25,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              sentence,
              style: TextStyle(fontSize: 18, color: AppColors.onWarning),
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: SizedBox(
                height: 16,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        color: AppColors.onWarning.withValues(alpha: 0.22),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: r,
                      child: ColoredBox(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un chiffre en grand, et la phrase qui dit ce qu'il signifie.
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.value,
    required this.sentence,
    this.color,
  });

  final String value;
  final String sentence;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 2),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppFonts.displayStyle(
              size: 38,
              color: color ?? AppColors.primary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            sentence,
            style: TextStyle(
              fontSize: 18.5,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Une part : son nom, son pourcentage écrit, et sa barre.
class AppShareRow extends StatelessWidget {
  const AppShareRow({
    super.key,
    required this.label,
    required this.share,
    required this.ratio,
    required this.color,
  });

  final String label;

  /// Écrit à droite du nom : « 32 % ».
  final String share;

  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final r = ratio.isNaN ? 0.0 : ratio.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md - 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                share,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 1),
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: SizedBox(
                height: 16,
                child: Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: AppColors.border)),
                    FractionallySizedBox(
                      widthFactor: r,
                      child: ColoredBox(color: color),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une barre de tendance, dans une rangée de barres.
@immutable
class AppTrendBar {
  const AppTrendBar({
    required this.value,
    required this.label,
    required this.amount,
    this.current = false,
  });

  /// Pour la hauteur, comparée au maximum de la rangée.
  final double value;

  /// Sous la barre : « Août », « Octobre, en cours ».
  final String label;

  /// Au-dessus de la barre, écrit : « 98 $ ».
  final String amount;

  /// Le mois en cours se distingue par sa couleur ET par son libellé.
  final bool current;
}

/// Une rangée de barres, chacune avec son montant écrit au-dessus.
///
/// Remplace le graphique muet : les barres disaient la forme, jamais les
/// valeurs, et il fallait deviner l'échelle.
class AppTrendBars extends StatelessWidget {
  const AppTrendBars({super.key, required this.bars, this.maxHeight = 90});

  final List<AppTrendBar> bars;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return const SizedBox.shrink();
    final max = bars.map((b) => b.value).reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final b in bars)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Column(
                children: [
                  Text(
                    b.amount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FractionallySizedBox(
                    widthFactor: 0.7,
                    child: Container(
                      height: max <= 0 ? 4 : (b.value / max) * maxHeight + 4,
                      decoration: BoxDecoration(
                        color:
                            b.current ? AppColors.warning : AppColors.primary,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.sm),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    b.label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Une courbe de prix, et la phrase qui dit ce qu'elle fait.
///
/// La planche montre des « courbes descendantes » sur chaque produit en
/// baisse. Une courbe seule ne dit rien a qui ne la voit pas : [summary]
/// est donc lue a sa place, et affichee sous elle.
class AppSparkline extends StatelessWidget {
  const AppSparkline({
    super.key,
    required this.values,
    required this.summary,
    this.color,
    this.height = 64,
  });

  /// Les relevés, du plus ancien au plus récent.
  final List<double> values;

  /// « Le prix descend : de 6,99 $ à 5,99 $ sur 4 relevés. »
  final String summary;

  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return Text(
        summary,
        style: TextStyle(
          fontSize: 18,
          height: 1.5,
          color: AppColors.textPrimary,
        ),
      );
    }

    final descend = values.last < values.first;
    final teinte =
        color ?? (descend ? AppColors.primary : AppColors.warningInk);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: summary,
          child: ExcludeSemantics(
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: CustomPaint(
                painter: _SparklinePainter(
                  values: values,
                  line: teinte,
                  dot: teinte,
                  base: AppColors.border,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          summary,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.line,
    required this.dot,
    required this.base,
  });

  final List<double> values;
  final Color line, dot, base;

  @override
  void paint(Canvas canvas, Size size) {
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final span = (max - min).abs() < 0.0001 ? 1.0 : max - min;

    Offset point(int i) => Offset(
      values.length == 1
          ? size.width / 2
          : i / (values.length - 1) * (size.width - 8) + 4,
      size.height - 6 - (values[i] - min) / span * (size.height - 16),
    );

    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      Paint()
        ..color = base
        ..strokeWidth = 2,
    );

    final chemin = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      chemin.lineTo(point(i).dx, point(i).dy);
    }
    canvas.drawPath(
      chemin,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final pastille = Paint()..color = dot;
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(point(i), i == values.length - 1 ? 7 : 4.5, pastille);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.line != line;
}
