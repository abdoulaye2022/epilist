// screens/meal_planner_screen.dart - Planificateur de repas V1 (§14-19) :
// choix des recettes, personnes, budget facultatif -> aperçu des
// ingrédients consolidés (« Déjà à la maison » identifié, coût estimé
// avec couverture affichée) -> création du plan + liste de courses.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/intelligence.dart';
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
  int _people = 4;
  final TextEditingController _budget = TextEditingController();
  bool _loading = true;
  bool _working = false;

  @override
  void initState() {
    super.initState();
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
      setState(() {
        _recipes = recipes;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.mealPlannerTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(l10n.chooseMeals,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.sm),
                ..._recipes.map((r) {
                  final selected = _selected.contains(r.id);
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      side: BorderSide(
                        color: selected ? AppColors.primary : AppColors.border,
                        width: selected ? 1.6 : 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: () => setState(() =>
                          selected ? _selected.remove(r.id) : _selected.add(r.id)),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textDisabled,
                              size: 22,
                            ),
                            const SizedBox(width: AppSpacing.sm + 2),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.name,
                                      style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                    [
                                      if (r.preparationTime != null)
                                        l10n.minutesShort(r.preparationTime!),
                                      l10n.servingsCount(r.servings),
                                    ].join(' · '),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text('${l10n.peopleCount} : ',
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textSecondary)),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _people > 1
                          ? () => setState(() => _people--)
                          : null,
                    ),
                    Text('$_people',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _people < 20
                          ? () => setState(() => _people++)
                          : null,
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 130,
                      child: TextField(
                        controller: _budget,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
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
                  child: _working
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
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
    final q = i.quantity == i.quantity.roundToDouble()
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
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
        child: Column(
          children: [
            if (p.estimatedTotal > 0) ...[
              Text(
                p.overBudget
                    ? l10n.planOverBudget(
                        '${p.estimatedTotal.toStringAsFixed(2)} \$')
                    : l10n.planEstimatedAt(
                        '${p.estimatedTotal.toStringAsFixed(2)} \$'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color:
                      p.overBudget ? AppColors.warning : AppColors.textPrimary,
                ),
              ),
              Text(
                l10n.estimationCoverage(p.priceCoveragePct),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
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
                    onChanged: (v) =>
                        setState(() => item.suggested = v ?? false),
                    title: Text('${item.productName} ${_qty(item)}',
                        style: const TextStyle(fontSize: 14)),
                    subtitle: item.atHome
                        ? Text(
                            '${l10n.alreadyAtHome} — ${l10n.addAnyway} ?',
                            style: const TextStyle(
                                fontSize: 11.5, color: AppColors.primary),
                          )
                        : (item.estimatedPrice != null
                            ? Text(
                                '≈ ${item.estimatedPrice!.toStringAsFixed(2)} \$',
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary),
                              )
                            : null),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      p.items.where((i) => i.suggested).toList(),
                    ),
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
