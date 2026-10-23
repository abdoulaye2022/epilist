// screens/meal_planner_screen.dart - « Planifier mes repas ».
//
// L'écran montrait cinq repas fixes, du lundi au vendredi, qu'on ne
// pouvait ni changer ni compléter : il n'y avait aucun chemin vers un
// sixième plat, ni vers un plat à soi.
//
// Il part maintenant des JOURS — les sept, samedi et dimanche compris —
// et chacun porte son bouton « Ajouter un repas ». Derrière ce bouton,
// deux chemins, parce que planifier se fait des deux façons : écrire ce
// qu'on va faire, ou chercher une recette. Un jour peut porter deux
// repas (midi et soir), le même plat peut revenir dans la semaine, et
// chaque repas se déplace, se remplace ou se retire.
//
// Le reste n'a pas changé : l'aperçu des ingrédients consolidés
// identifie ce qui est « Déjà à la maison » et affiche un coût estimé
// avec sa couverture, puis crée le plan et la liste de courses.
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
import 'package:epilist/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Midi ou soir. Le jour en porte deux, pas plus : au-delà, ce n'est
/// plus un plan de repas, c'est un agenda.
enum MealSlot {
  lunch,
  dinner;

  String get api => name;
}

/// Un repas PLACÉ : une recette, un jour, un moment.
@immutable
class PlannedMeal {
  const PlannedMeal({
    required this.recipe,
    required this.weekday,
    required this.slot,
  });

  final RecipeSummary recipe;

  /// 1 = lundi … 7 = dimanche, la convention de `DateTime.weekday` et
  /// de `recurring_lists.weekday`.
  final int weekday;

  final MealSlot slot;

  PlannedMeal copyWith({int? weekday, MealSlot? slot, RecipeSummary? recipe}) =>
      PlannedMeal(
        recipe: recipe ?? this.recipe,
        weekday: weekday ?? this.weekday,
        slot: slot ?? this.slot,
      );
}

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  List<RecipeSummary> _recipes = [];

  /// La semaine, dans l'ordre où elle a été remplie.
  final List<PlannedMeal> _repas = [];

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

  /// Les sept jours, écrits.
  List<String> _nomsDesJours(AppLocalizations l10n) => [
    l10n.weekdayMon,
    l10n.weekdayTue,
    l10n.weekdayWed,
    l10n.weekdayThu,
    l10n.weekdayFri,
    l10n.weekdaySat,
    l10n.weekdaySun,
  ];

  String _nomDuMoment(AppLocalizations l10n, MealSlot slot) =>
      slot == MealSlot.lunch ? l10n.mealSlotLunch : l10n.mealSlotDinner;

  /// La date du jour N de la semaine EN COURS. « Lundi » tout seul ne
  /// dit pas lequel : celui qui vient, ou celui qui est passé ?
  DateTime _dateDuJour(int weekday) {
    final maintenant = DateTime.now();
    return maintenant.add(Duration(days: weekday - maintenant.weekday));
  }

  /// Allume ou eteint l'etoile d'une recette, et le dit tout de suite.
  Future<void> _basculerFavori(RecipeSummary recette) async {
    final l10n = AppLocalizations.of(context)!;
    final voulu = !recette.isFavorite;

    setState(() {
      _recipes = [
        for (final r in _recipes)
          r.id == recette.id ? r.copyWith(isFavorite: voulu) : r,
      ];
      _repas.setAll(0, [
        for (final p in _repas)
          p.recipe.id == recette.id
              ? p.copyWith(recipe: p.recipe.copyWith(isFavorite: voulu))
              : p,
      ]);
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
        _repas.setAll(0, [
          for (final p in _repas)
            p.recipe.id == recette.id
                ? p.copyWith(recipe: p.recipe.copyWith(isFavorite: !voulu))
                : p,
        ]);
      });
      SmartSnackBarManager.showErrorSnackBar(
        context,
        l10n.recipeFavoriteFailed,
      );
    }
  }

  // --- Ajouter, remplacer, déplacer, retirer ---------------------------

  /// Ouvre la feuille à deux onglets et place le repas choisi.
  ///
  /// [remplace] : le repas à remplacer, le cas échéant — même jour,
  /// autre plat.
  Future<void> _ajouterUnRepas(int weekday, {PlannedMeal? remplace}) async {
    final choix = await showModalBottomSheet<(RecipeSummary, MealSlot)>(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => _AddMealSheet(
            service: context.read<IntelligenceService>(),
            catalogue: _recipes,
            people: _people,
            slotInitial: remplace?.slot ?? MealSlot.dinner,
            onFavori: _basculerFavori,
          ),
    );
    if (choix == null || !mounted) return;

    setState(() {
      if (remplace != null) _repas.remove(remplace);
      _repas.add(
        PlannedMeal(recipe: choix.$1, weekday: weekday, slot: choix.$2),
      );
      // Une recette écrite à la main n'est pas encore dans le
      // catalogue chargé : elle doit l'être, sinon la prochaine
      // ouverture de la feuille ne la trouverait pas.
      if (!_recipes.any((r) => r.id == choix.$1.id)) {
        _recipes = [choix.$1, ..._recipes];
        ScreenCache.write('recipes', _recipes);
      }
    });
  }

  Future<void> _deplacer(PlannedMeal repas) async {
    final l10n = AppLocalizations.of(context)!;
    final noms = _nomsDesJours(l10n);

    final cible = await showDialog<int>(
      context: context,
      builder:
          (ctx) => SimpleDialog(
            title: Text(l10n.mealMoveTo),
            children: [
              for (var jour = 1; jour <= 7; jour++)
                SimpleDialogOption(
                  onPressed: () => Navigator.of(ctx).pop(jour),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      noms[jour - 1],
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
            ],
          ),
    );
    if (cible == null || !mounted) return;
    setState(() {
      final i = _repas.indexOf(repas);
      if (i >= 0) _repas[i] = repas.copyWith(weekday: cible);
    });
  }

  // --- Créer le plan ---------------------------------------------------

  double? get _budgetMax {
    final v = double.tryParse(_budget.text.replaceAll(',', '.'));
    return v != null && v > 0 ? v : null;
  }

  Future<void> _createPlan() async {
    final l10n = AppLocalizations.of(context)!;
    if (_repas.isEmpty) return;
    setState(() => _working = true);

    final service = context.read<IntelligenceService>();
    // Les ingrédients se consolident par RECETTE : un plat deux fois
    // dans la semaine compte deux fois côté serveur, et l'aperçu doit
    // donc recevoir l'identifiant deux fois.
    final ids = _repas.map((r) => r.recipe.id).toList();

    MealPlanPreview preview;
    try {
      preview = await service.previewMealPlan(
        recipeIds: ids,
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
        recipeIds: ids,
        assignments:
            _repas
                .map(
                  (r) => {
                    'recipe_id': r.recipe.id,
                    'weekday': r.weekday,
                    'meal_slot': r.slot.api,
                  },
                )
                .toList(),
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
    final locale = Localizations.localeOf(context).languageCode;
    final noms = _nomsDesJours(l10n);

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
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.mealWeekCount(_repas.length),
                    style: TextStyle(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _convives(l10n),
                  const SizedBox(height: AppSpacing.md),
                  // Un jour par bloc, les sept. Samedi et dimanche
                  // manquaient, et ce sont les jours où l'on cuisine.
                  for (var jour = 1; jour <= 7; jour++)
                    _carteDuJour(l10n, locale, jour, noms[jour - 1]),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: _repas.isEmpty || _working ? null : _createPlan,
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

  /// Combien de personnes, et le budget facultatif.
  Widget _convives(AppLocalizations l10n) {
    return Row(
      children: [
        Text(
          '${l10n.peopleCount} : ',
          style: TextStyle(fontSize: 17, color: AppColors.textSecondary),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: _people > 1 ? () => setState(() => _people--) : null,
        ),
        Text(
          '$_people',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: _people < 20 ? () => setState(() => _people++) : null,
        ),
        const Spacer(),
        SizedBox(
          width: 140,
          child: TextField(
            controller: _budget,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.budgetMaxOptional,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _carteDuJour(
    AppLocalizations l10n,
    String locale,
    int jour,
    String nom,
  ) {
    final duJour =
        _repas.where((r) => r.weekday == jour).toList()
          ..sort((a, b) => a.slot.index.compareTo(b.slot.index));
    final date = DateFormat('d MMMM', locale).format(_dateDuJour(jour));

    return AppZoneCard(
      title: '$nom $date',
      tint: AppColors.chart[(jour - 1) % AppColors.chart.length],
      icon: AppIcons.mealPlanner,
      children: [
        if (duJour.isEmpty)
          Text(
            l10n.mealEmptyDay,
            style: TextStyle(fontSize: 17, color: AppColors.textSecondary),
          )
        else
          for (final repas in duJour) _ligneDeRepas(l10n, repas),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => _ajouterUnRepas(jour),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, AppSizes.buttonSmall),
          ),
          icon: const Icon(Icons.add),
          label: Text(l10n.mealAddMeal),
        ),
      ],
    );
  }

  /// Un repas du jour : sa vignette, son nom, son moment écrit, et ce
  /// qu'on peut en faire.
  Widget _ligneDeRepas(AppLocalizations l10n, PlannedMeal repas) {
    final r = repas.recipe;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _vignette(r),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.name,
                  style: TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  [
                    _nomDuMoment(l10n, repas.slot),
                    l10n.mealServingsLine(_people),
                    if (r.preparationTime != null)
                      l10n.mealPrepLine(r.preparationTime!),
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 16.5,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
                // Un repas sans ingrédient n'ajoutera rien aux
                // courses : le dire ici, et pas seulement au moment de
                // générer la liste.
                if (r.ingredientsCount == 0)
                  Text(
                    l10n.mealNoIngredientsWarning,
                    style: TextStyle(
                      fontSize: 16.5,
                      color: AppColors.warningInk,
                    ),
                  ),
                AppFavoriteButton(
                  favorite: r.isFavorite,
                  label:
                      r.isFavorite
                          ? l10n.recipeFavoriteYes
                          : l10n.recipeFavoriteNo,
                  onPressed: () => _basculerFavori(r),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              size: 22,
              color: AppColors.textSecondary,
            ),
            onSelected: (action) async {
              switch (action) {
                case 'move':
                  await _deplacer(repas);
                case 'replace':
                  await _ajouterUnRepas(repas.weekday, remplace: repas);
                default:
                  setState(() => _repas.remove(repas));
              }
            },
            itemBuilder:
                (_) => [
                  PopupMenuItem(value: 'move', child: Text(l10n.mealMove)),
                  PopupMenuItem(
                    value: 'replace',
                    child: Text(l10n.mealReplace),
                  ),
                  PopupMenuItem(value: 'remove', child: Text(l10n.mealRemove)),
                ],
          ),
        ],
      ),
    );
  }

  /// La photo du plat, ou une vignette par défaut : un repas écrit à la
  /// main n'a pas de photo, et un trou gris à sa place ferait croire à
  /// une image qui n'a pas chargé.
  Widget _vignette(RecipeSummary r) {
    const taille = 64.0;
    final aUnePhoto = r.imageUrl != null && r.imageUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        width: taille,
        height: taille,
        child:
            aUnePhoto
                ? Image.network(
                  r.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _vignetteParDefaut(),
                )
                : _vignetteParDefaut(),
      ),
    );
  }

  Widget _vignetteParDefaut() => ColoredBox(
    color: AppTint.fill(AppColors.gold),
    child: Center(
      child: Icon(
        Icons.restaurant_rounded,
        size: 30,
        color: AppTint.ink(AppColors.gold),
      ),
    ),
  );
}

/// La feuille d'ajout : deux onglets, deux façons de planifier.
///
/// « Écrire mon repas » et « Chercher une recette » répondent à la même
/// question par deux chemins : on sait déjà ce qu'on va faire, ou on
/// cherche une idée. L'écran n'offrait aucun des deux.
class _AddMealSheet extends StatefulWidget {
  const _AddMealSheet({
    required this.service,
    required this.catalogue,
    required this.people,
    required this.slotInitial,
    required this.onFavori,
  });

  final IntelligenceService service;
  final List<RecipeSummary> catalogue;
  final int people;
  final MealSlot slotInitial;
  final Future<void> Function(RecipeSummary) onFavori;

  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _onglets;
  late MealSlot _slot;

  // --- Écrire mon repas
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _ingredient = TextEditingController();
  final List<String> _ingredients = [];
  bool _enregistre = false;

  // --- Chercher une recette
  final TextEditingController _recherche = TextEditingController();
  late List<RecipeSummary> _resultats;
  int? _maxTemps;
  bool _favorisSeuls = false;
  bool _cherche = false;

  @override
  void initState() {
    super.initState();
    _onglets = TabController(length: 2, vsync: this);
    _slot = widget.slotInitial;
    _resultats = widget.catalogue;
  }

  @override
  void dispose() {
    _onglets.dispose();
    _nom.dispose();
    _ingredient.dispose();
    _recherche.dispose();
    super.dispose();
  }

  Future<void> _lancerLaRecherche() async {
    setState(() => _cherche = true);
    try {
      final r = await widget.service.getRecipes(
        q: _recherche.text,
        maxTime: _maxTemps,
        favoritesOnly: _favorisSeuls,
      );
      if (!mounted) return;
      setState(() {
        _resultats = r;
        _cherche = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cherche = false);
    }
  }

  Future<void> _enregistrerLeRepas() async {
    final l10n = AppLocalizations.of(context)!;
    final nom = _nom.text.trim();
    if (nom.isEmpty) return;

    setState(() => _enregistre = true);
    try {
      final recette = await widget.service.createRecipe(
        name: nom,
        servings: widget.people,
        ingredients:
            _ingredients
                .map((i) => {'ingredient_name': i, 'quantity': 1})
                .toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop((recette, _slot));
    } catch (_) {
      if (!mounted) return;
      setState(() => _enregistre = false);
      SmartSnackBarManager.showErrorSnackBar(context, l10n.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        builder:
            (context, scrollController) => Column(
              children: [
                const SizedBox(height: AppSpacing.sm),
                TabBar(
                  controller: _onglets,
                  labelStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: [
                    Tab(text: l10n.mealWriteTab),
                    Tab(text: l10n.mealSearchTab),
                  ],
                ),
                // Le moment vaut pour les deux onglets : il est au-dessus.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${l10n.mealSlotQuestion} ',
                        style: TextStyle(
                          fontSize: 17,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      for (final s in MealSlot.values)
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.sm),
                          child: ChoiceChip(
                            label: Text(
                              s == MealSlot.lunch
                                  ? l10n.mealSlotLunch
                                  : l10n.mealSlotDinner,
                            ),
                            selected: _slot == s,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _slot = s),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _onglets,
                    children: [
                      _ecrire(l10n, scrollController),
                      _chercher(l10n),
                    ],
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _ecrire(AppLocalizations l10n, ScrollController controller) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        TextField(
          controller: _nom,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.mealName),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.mealIngredientsOptional,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Facultatifs, et on dit ce que ça coûte de ne pas les mettre.
        if (_ingredients.isEmpty)
          Text(
            l10n.mealNoIngredientsWarning,
            style: TextStyle(fontSize: 16.5, color: AppColors.warningInk),
          ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final i in _ingredients)
              Chip(
                label: Text(i, style: const TextStyle(fontSize: 16.5)),
                onDeleted: () => setState(() => _ingredients.remove(i)),
              ),
          ],
        ),
        TextField(
          controller: _ingredient,
          decoration: InputDecoration(
            labelText: l10n.mealAddIngredient,
            suffixIcon: IconButton(
              tooltip: l10n.mealAddIngredient,
              icon: const Icon(Icons.add),
              onPressed: () => _ajouteIngredient(_ingredient.text),
            ),
          ),
          onSubmitted: _ajouteIngredient,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed:
              _nom.text.trim().isEmpty || _enregistre
                  ? null
                  : _enregistrerLeRepas,
          child:
              _enregistre
                  ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(l10n.mealSaveMeal),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  void _ajouteIngredient(String brut) {
    final nom = brut.trim();
    if (nom.isEmpty) return;
    if (!_ingredients.any((i) => i.toLowerCase() == nom.toLowerCase())) {
      setState(() => _ingredients.add(nom));
    }
    _ingredient.clear();
  }

  Widget _chercher(AppLocalizations l10n) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _recherche,
                decoration: InputDecoration(
                  labelText: l10n.mealSearchHint,
                  prefixIcon: const Icon(Icons.search),
                ),
                onSubmitted: (_) => _lancerLaRecherche(),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.mealFilterTime,
                style: TextStyle(
                  fontSize: 16.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final (valeur, libelle) in [
                      (null, l10n.mealTimeAny),
                      (15, l10n.mealTimeUnder(15)),
                      (30, l10n.mealTimeUnder(30)),
                      (60, l10n.mealTimeUnder(60)),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(libelle),
                          selected: _maxTemps == valeur,
                          showCheckmark: false,
                          onSelected: (_) {
                            setState(() => _maxTemps = valeur);
                            _lancerLaRecherche();
                          },
                        ),
                      ),
                  ],
                ),
              ),
              AppSwitchTile(
                title: l10n.mealFavoritesOnly,
                stateLabel: _favorisSeuls ? l10n.mealYes : l10n.mealNo,
                value: _favorisSeuls,
                onChanged: (v) {
                  setState(() => _favorisSeuls = v);
                  _lancerLaRecherche();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _lancerLaRecherche,
                  icon: const Icon(Icons.search),
                  label: Text(l10n.search),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _cherche
                  ? const Center(child: CircularProgressIndicator())
                  : _resultats.isEmpty
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        l10n.mealNoResults,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.lg,
                    ),
                    itemCount: _resultats.length,
                    itemBuilder: (context, i) => _resultat(l10n, _resultats[i]),
                  ),
        ),
      ],
    );
  }

  Widget _resultat(AppLocalizations l10n, RecipeSummary r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: AppColors.border, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).pop((r, _slot)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.name,
                        style: TextStyle(
                          fontSize: 18.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        [
                          if (r.isMine) l10n.mealWritten,
                          l10n.mealServingsLine(r.servings),
                          if (r.preparationTime != null)
                            l10n.mealPrepLine(r.preparationTime!),
                          if (r.ingredientsCount > 0)
                            l10n.mealIngredientsLine(r.ingredientsCount),
                        ].join(' · '),
                        style: TextStyle(
                          fontSize: 16.5,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppFavoriteButton(
                  favorite: r.isFavorite,
                  label: r.isFavorite ? l10n.recipeFavoriteYes : '',
                  onPressed: () async {
                    await widget.onFavori(r);
                    if (!mounted) return;
                    setState(() {
                      _resultats = [
                        for (final x in _resultats)
                          x.id == r.id
                              ? x.copyWith(isFavorite: !x.isFavorite)
                              : x,
                      ];
                    });
                  },
                ),
              ],
            ),
          ),
        ),
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
