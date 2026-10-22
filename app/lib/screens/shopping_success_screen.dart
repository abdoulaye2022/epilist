// screens/shopping_success_screen.dart - « Courses terminées, bravo ! »
//
// La planche « Version B » célèbre la fin des courses, et c'est une
// leçon prise à Happy Shared Shopping : le dernier article coché ne
// renvoyait sur rien. On refermait l'écran, et rien ne disait que
// c'était fini.
//
// L'écran dit trois choses : c'est fini, voilà ce que vous avez fait, et
// voilà où aller maintenant.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/screens/budget_screen.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:flutter/material.dart';

class ShoppingSuccessScreen extends StatelessWidget {
  const ShoppingSuccessScreen({
    super.key,
    required this.listName,
    required this.itemsCount,
  });

  final String listName;
  final int itemsCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md + 2,
            AppSpacing.xl,
            AppSpacing.md + 2,
            AppSpacing.xl,
          ),
          children: [
            // Les confettis sont dessinés, pas photographiés : rien à
            // charger, et la couleur suit la palette.
            Center(
              child: SizedBox(
                width: 220,
                height: 160,
                child: CustomPaint(painter: _ConfettiPainter()),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 56,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.shoppingSuccessTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            Text(
              l10n.shoppingSuccessSentence(listName, itemsCount),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BudgetScreen()),
                  ),
              icon: const Icon(Icons.savings_outlined),
              label: Text(l10n.shoppingSuccessSeeBudgets),
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            OutlinedButton.icon(
              onPressed: () => _back(context, MainTab.home),
              icon: const Icon(Icons.space_dashboard_outlined),
              label: Text(l10n.shoppingSuccessBackHome),
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            OutlinedButton.icon(
              onPressed: () => _back(context, MainTab.lists),
              icon: const Icon(Icons.checklist_rounded),
              label: Text(l10n.shoppingSuccessBackLists),
            ),
          ],
        ),
      ),
    );
  }

  /// Referme toute la pile — mode courses, détail, sélecteur — puis
  /// demande l'onglet. La portée de la coquille n'est pas accessible
  /// d'ici : un écran poussé est au-dessus d'elle, pas dedans.
  void _back(BuildContext context, MainTab tab) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    MainShellRoute.goToTab?.call(tab);
  }
}

class _ConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final couleurs = AppColors.chart;
    final pinceau = Paint()..style = PaintingStyle.fill;

    // Positions fixes, choisies à la main : un semis aléatoire
    // changerait à chaque reconstruction, et l'écran clignoterait.
    const grains = [
      (0.08, 0.18, 0.0),
      (0.22, 0.06, 0.6),
      (0.37, 0.22, 1.1),
      (0.52, 0.04, 0.3),
      (0.66, 0.20, 0.9),
      (0.81, 0.09, 1.4),
      (0.94, 0.24, 0.2),
      (0.14, 0.44, 1.2),
      (0.30, 0.56, 0.4),
      (0.46, 0.40, 0.8),
      (0.61, 0.58, 1.3),
      (0.76, 0.42, 0.5),
      (0.90, 0.60, 1.0),
      (0.20, 0.78, 0.7),
      (0.44, 0.84, 0.2),
      (0.68, 0.80, 1.1),
      (0.86, 0.90, 0.6),
    ];

    for (var i = 0; i < grains.length; i++) {
      final (fx, fy, angle) = grains[i];
      pinceau.color = couleurs[i % couleurs.length];
      canvas.save();
      canvas.translate(fx * size.width, fy * size.height);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 16, height: 7),
          const Radius.circular(3),
        ),
        pinceau,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => false;
}
