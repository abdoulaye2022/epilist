// screens/meal_planner_screen.dart - Planificateur de repas V1 (§14-19) :
// choix des recettes, personnes, budget facultatif -> aperçu des
// ingrédients consolidés (« Déjà à la maison » identifié, coût estimé
// avec couverture affichée) -> création du plan + liste de courses.
import 'package:epilist/widgets/common/app_top_bar.dart';
import 'package:epilist/widgets/common/app_drawer.dart';
import 'package:epilist/widgets/common/main_bottom_bar.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:epilist/widgets/common/app_states.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/intelligence.dart';
import 'package:epilist/services/screen_cache.dart';
import 'package:epilist/services/intelligence_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  List<RecipeSummary> _recipes = [];
  final Set<int> _selected = {};

  /// Le jour choisi pour chaque recette : 1 = lundi ... 7 = dimanche.
  /// « Lundi vert, Mardi jaune, Mercredi bleu », dit la planche. Une
  /// recette sans jour reste dans le plan : le jour est facultatif.
  final Map<int, int> _jours = {};

  int _people = 4;
  final TextEditingController _budget = TextEditingController();
  bool _loading = true;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    final cached = ScreenCache.read<List<RecipeSummary>>('recipes');
    if (cached != null) {
      _recipes = cached;
      _loading = false;
    }
    _load();
  }

  @override
  void dispose() {
    _budget.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final recipes = await context.read<IntelligenceService>().getRecipes();
      if (!mounted) return;
      ScreenCache.write('recipes', recipes);
      setState(() {
        _recipes = recipes;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// Les sept jours, ecrits. L'index vaut `weekday - 1`, la meme
  /// convention que `DateTime.weekday` et que `recurring_lists.weekday`
  /// cote serveur.
  List<String> _nomsDesJours(AppLocalizations l10n) => [
    l10n.weekdayMon,
    l10n.weekdayTue,
    l10n.weekdayWed,
    l10n.weekdayThu,
    l10n.weekdayFri,
    l10n.weekdaySat,
    l10n.weekdaySun,
  ];

  /// « Quel jour de la semaine ? », et le jour choisi ECRIT dessous.
  ///
  /// Les puces portent la couleur de la planche — « Lundi vert, Mardi
  /// jaune, Mercredi bleu » — mais la couleur ne dit jamais seule ce
  /// qui est choisi : la phrase sous les puces le dit aussi.
  Widget _choixDuJour(AppLocalizations l10n, int recetteId) {
    final noms = _nomsDesJours(l10n);
    final choisi = _jours[recetteId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.mealDayQuestion,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (var jour = 1; jour <= 7; jour++)
              ChoiceChip(
                label: Text(noms[jour - 1]),
                selected: choisi == jour,
                showCheckmark: false,
                selectedColor: AppTint.fill(
                  AppColors.chart[(jour - 1) % AppColors.chart.length],
                ),
                onSelected:
                    (pris) => setState(() {
                      if (pris) {
                        _jours[recetteId] = jour;
                      } else {
                        _jours.remove(recetteId);
                      }
                    }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          choisi == null
              ? l10n.mealDayNotChosen
              : l10n.mealDayLabel(noms[choisi - 1]),
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color:
                choisi == null ? AppColors.textSecondary : AppColors.successInk,
          ),
        ),
      ],
    );
  }

  /// Allume ou eteint l'etoile d'une recette, et le dit tout de suite.
  Future<void> _basculerFavori(RecipeSummary recette) async {
    final l10n = AppLocalizations.of(context)!;
    final voulu = !recette.isFavorite;

    // Reponse immediate : la planche demande qu'un controle reponde
    // « tout de suite ». On remet l'etat d'avant si le serveur refuse.
    setState(() {
      _recipes = [
        for (final r in _recipes)
          r.id == recette.id ? r.copyWith(isFavorite: voulu) : r,
      ];
    });

    try {
      await context.read<IntelligenceService>().setRecipeFavorite(
        recette.id,
        voulu,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recipes = [
          for (final r in _recipes)
            r.id == recette.id ? r.copyWith(isFavorite: !voulu) : r,
        ];
      });
      SmartSnackBarManager.showErrorSnackBar(
        context,
        l10n.recipeFavoriteFailed,
      );
    }
  }

  double? get _budgetMax {
    final v = double.tryParse(_budget.text.replaceAll(',', '.'));
    return v != null && v > 0 ? v : null;
  }

  Future<void> _createPlan() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selected.isEmpty) return;
    setState(() => _working = true);

    final service = context.read<IntelligenceService>();
    MealPlanPreview preview;
    try {
      preview = await service.previewMealPlan(
        recipeIds: _selected.toList(),
        people: _people,
        budgetMax: _budgetMax,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _working = false);
        SmartSnackBarManager.showErrorSnackBar(context, l10n.error);
      }
      return;
    }
    if (!mounted) return;
    setState(() => _working = false);

    final confirmed = await showModalBottomSheet<List<MealPlanItem>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MealPreviewSheet(preview: preview),
    );
    if (confirmed == null || confirmed.isEmpty || !mounted) return;

    try {
      await service.createMealPlan(
        recipeIds: _selected.toList(),
        weekdays: {
          for (final e in _jours.entries)
            if (_selected.contains(e.key)) e.key: e.value,
        },
        people: _people,
        budgetMax: _budgetMax,
        items: confirmed,
      );
      if (!mounted) return;
      SmartSnackBarManager.showSuccessSnackBar(context, l10n.listCreated);
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) SmartSnackBarManager.showErrorSnackBar(context, l10n.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppPageBottomBar(tab: MainTab.sections),
      appBar: AppTopBar(title: l10n.mealPlannerTitle),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Text(
                    l10n.mealPlannerIntro,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.chooseMeals, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.md),
                  // Un repas par bloc pleine largeur, en-tete teinte.
                  // Les cartes faisaient 14,5 points, avec un cercle a
                  // cocher de 22 : le choix de la semaine se faisait a
                  // la loupe. L'etat est maintenant ECRIT dans la
                  // ligne qu'on touche.
                  for (final (n, r) in _recipes.indexed)
                    AppZoneCard(
                      title: r.name,
                      tint: AppColors.chart[n % AppColors.chart.length],
                      icon: Icons.restaurant_menu_outlined,
                      children: [
                        // La photo du plat : elle dormait en base
                        // (recipes.image_url) sans jamais sortir de
                        // l'API.
                        if (r.imageUrl != null && r.imageUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.network(
                                  r.imageUrl!,
                                  fit: BoxFit.cover,
                                  // Une photo qui ne charge pas ne doit
                                  // pas laisser un trou : la carte se
                                  // referme sur son texte.
                                  errorBuilder:
                                      (_, _, _) => const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ),
                        if (r.description != null &&
                            r.description!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Text(
                              r.description!,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        Text(
                          [
                            l10n.mealServingsLine(r.servings),
                            if (r.preparationTime != null)
                              l10n.mealPrepLine(r.preparationTime!),
                            if (r.ingredientsCount > 0)
                              l10n.mealIngredientsLine(r.ingredientsCount),
                          ].join(' '),
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm + 4),
                        AppFavoriteButton(
                          favorite: r.isFavorite,
                          label:
                              r.isFavorite
                                  ? l10n.recipeFavoriteYes
                                  : l10n.recipeFavoriteNo,
                          onPressed: () => _basculerFavori(r),
                        ),
                        const SizedBox(height: AppSpacing.sm + 4),
                        AppCheckRow(
                          checked: _selected.contains(r.id),
                          title:
                              _selected.contains(r.id)
                                  ? l10n.mealChosenForWeek
                                  : l10n.mealChooseForWeek,
                          onChanged:
                              (v) => setState(
                                () =>
                                    v
                                        ? _selected.add(r.id)
                                        : _selected.remove(r.id),
                              ),
                        ),
                        // Le jour ne se demande qu'une fois le plat
                        // choisi : sinon la carte poserait une question
                        // sans objet.
                        if (_selected.contains(r.id)) ...[
                          const SizedBox(height: AppSpacing.sm + 4),
                          _choixDuJour(l10n, r.id),
                        ],
                      ],
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Text(
                        '${l10n.peopleCount} : ',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed:
                            _people > 1
                                ? () => setState(() => _people--)
                                : null,
                      ),
                      Text(
                        '$_people',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed:
                            _people < 20
                                ? () => setState(() => _people++)
                                : null,
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 130,
                        child: TextField(
                          controller: _budget,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.budgetMaxOptional,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed:
                        _selected.isEmpty || _working ? null : _createPlan,
                    child:
                        _working
                            ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Text(l10n.createMyPlan),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
    );
  }
}

/// Aperçu du plan : ingrédients cochables, « Déjà à la maison »,
/// budget honnête (couverture des prix affichée).
class _MealPreviewSheet extends StatefulWidget {
  final MealPlanPreview preview;

  const _MealPreviewSheet({required this.preview});

  @override
  State<_MealPreviewSheet> createState() => _MealPreviewSheetState();
}

class _MealPreviewSheetState extends State<_MealPreviewSheet> {
  String _qty(MealPlanItem i) {
    final q =
        i.quantity == i.quantity.roundToDouble()
            ? i.quantity.toInt().toString()
            : i.quantity.toStringAsFixed(2);
    return i.unit == null || i.unit == 'un' ? '×$q' : '$q ${i.unit}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = widget.preview;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      builder:
          (context, scrollController) => Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Column(
              children: [
                if (p.estimatedTotal > 0) ...[
                  Text(
                    p.overBudget
                        ? l10n.planOverBudget(
                          '${p.estimatedTotal.toStringAsFixed(2)} \$',
                        )
                        : l10n.planEstimatedAt(
                          '${p.estimatedTotal.toStringAsFixed(2)} \$',
                        ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color:
                          p.overBudget
                              ? AppColors.warning
                              : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    l10n.estimationCoverage(p.priceCoveragePct),
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: p.items.length,
                    itemBuilder: (context, index) {
                      final item = p.items[index];
                      return CheckboxListTile(
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: item.suggested,
                        onChanged:
                            (v) => setState(() => item.suggested = v ?? false),
                        title: Text(
                          '${item.productName} ${_qty(item)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        subtitle:
                            item.atHome
                                ? Text(
                                  '${l10n.alreadyAtHome} — ${l10n.addAnyway} ?',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: AppColors.primary,
                                  ),
                                )
                                : (item.estimatedPrice != null
                                    ? Text(
                                      '≈ ${item.estimatedPrice!.toStringAsFixed(2)} \$',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    )
                                    : null),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            () => Navigator.of(
                              context,
                            ).pop(p.items.where((i) => i.suggested).toList()),
                        child: Text(l10n.createTheList),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
