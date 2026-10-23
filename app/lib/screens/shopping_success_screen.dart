// screens/shopping_success_screen.dart - « Courses terminées, bravo ! »
//
// La planche « Version B » célèbre la fin des courses. Avant, le
// dernier article coché ne renvoyait sur rien : on refermait l'écran,
// et rien ne disait que c'était fini.
//
// L'écran dit trois choses : c'est fini, voilà ce que vous avez fait, et
// voilà où aller maintenant.
//
// Et il BOUCLE le cycle. Les courses remplissent la maison : un produit
// acheté qui était suivi y revient tout seul, côté serveur. Un produit
// qui ne l'était pas encore, lui, se propose — avec son nombre, et d'un
// seul geste. L'inventaire reste une liste CHOISIE : l'ajouter d'office
// en ferait le journal de tout ce qu'on achète, ce que personne n'a
// demandé.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/screens/budget_screen.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/main_bottom_bar.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:epilist/models/intelligence.dart';
import 'package:epilist/services/inventory_lookup.dart';
import 'package:epilist/services/intelligence_service.dart';
import 'package:epilist/services/screen_cache.dart';
import 'package:epilist/theme/app_icons.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShoppingSuccessScreen extends StatefulWidget {
  const ShoppingSuccessScreen({
    super.key,
    required this.listName,
    required this.itemsCount,
    this.remainingCount = 0,
    this.purchasedNames = const [],
  });

  final String listName;
  final int itemsCount;

  /// Les articles qui n'ont PAS été cochés. Ils restent dans la liste,
  /// et l'écran le dit : sans un mot, on referme la liste en croyant
  /// avoir tout pris, ou on la croit perdue.
  final int remainingCount;

  /// Ce qui a été mis dans le panier. Sert à proposer d'en suivre ce
  /// qui ne l'est pas encore. Vide : rien ne se propose, et l'écran ne
  /// touche pas au réseau.
  final List<String> purchasedNames;

  @override
  State<ShoppingSuccessScreen> createState() => _ShoppingSuccessScreenState();
}

class _ShoppingSuccessScreenState extends State<ShoppingSuccessScreen> {
  /// Les produits achetés qui ne sont pas suivis à la maison.
  List<String> _aSuivre = const [];
  bool _ajoute = false;

  @override
  void initState() {
    super.initState();
    if (widget.purchasedNames.isNotEmpty) _chercheLesNonSuivis();
  }

  Future<void> _chercheLesNonSuivis() async {
    final lookup = InventoryLookup(context.read<IntelligenceService>());
    final absents = <String>[];
    for (final nom in widget.purchasedNames) {
      if (nom.trim().isEmpty) continue;
      InventoryItem? chezMoi;
      try {
        chezMoi = await lookup.chezMoi(nom);
      } catch (_) {
        return; // Pas de reseau : on ne propose rien.
      }
      if (chezMoi == null && !absents.contains(nom)) absents.add(nom);
    }
    if (!mounted) return;
    setState(() => _aSuivre = absents);
  }

  Future<void> _ajouterAMaMaison() async {
    final l10n = AppLocalizations.of(context)!;
    final service = context.read<IntelligenceService>();
    setState(() => _ajoute = true);

    var faits = 0;
    for (final nom in _aSuivre) {
      try {
        await service.setInventoryStatus(nom, 'at_home');
        faits++;
      } catch (_) {
        // Un produit qui resiste n'empeche pas les autres.
      }
    }
    ScreenCache.invalidate('inventory');
    InventoryLookup.oublie();
    if (!mounted) return;
    setState(() {
      _aSuivre = const [];
      _ajoute = false;
    });
    SmartSnackBarManager.showSuccessSnackBar(
      context,
      l10n.shoppingToStockDone(faits),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      // La planche montre la barre du bas jusque sur l'ecran de
      // reussite : c'est de la qu'on repart.
      bottomNavigationBar: const AppPageBottomBar(tab: MainTab.lists),
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
              l10n.shoppingSuccessSentence(widget.listName, widget.itemsCount),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
            if (widget.remainingCount > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.shoppingUncheckedKept(widget.remainingCount),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (_aSuivre.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _proposerLeSuivi(l10n),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BudgetScreen()),
                  ),
              icon: const Icon(AppIcons.budgets),
              label: Text(l10n.shoppingSuccessSeeBudgets),
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            OutlinedButton.icon(
              onPressed: () => _back(context, MainTab.home),
              icon: const Icon(AppIcons.dashboard),
              label: Text(l10n.shoppingSuccessBackHome),
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            OutlinedButton.icon(
              onPressed: () => _back(context, MainTab.lists),
              icon: const Icon(AppIcons.lists),
              label: Text(l10n.shoppingSuccessBackLists),
            ),
          ],
        ),
      ),
    );
  }

  /// « À la fin des courses, les articles cochés s'ajoutent au stock. »
  ///
  /// Ceux qui étaient déjà suivis y sont revenus tout seuls, côté
  /// serveur. Les autres se proposent ici, d'un seul geste — et c'est
  /// une PROPOSITION : l'inventaire est une liste choisie, pas le
  /// journal de tout ce qu'on achète.
  Widget _proposerLeSuivi(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppTint.fill(AppColors.primary),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppTint.line(AppColors.primary), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.shoppingToStockTitle(_aSuivre.length),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            l10n.shoppingToStockWhy,
            style: TextStyle(
              fontSize: 17,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _ajoute ? null : _ajouterAMaMaison,
            icon:
                _ajoute
                    ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(AppIcons.inventory),
            label: Text(l10n.shoppingToStockAdd),
          ),
        ],
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
          const Radius.circular(AppRadius.sm),
        ),
        pinceau,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => false;
}
