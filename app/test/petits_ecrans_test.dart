// Le kit partage, sur un PETIT ecran et avec un GROS texte.
//
// Trois captures d'appareil de suite ont montre la meme famille de
// defaut, et aucune n'etait couverte :
//
//   - une boite de taille FIXE qui loge du texte (la pastille de 44 x 44
//     du pourcentage, ou « 280 % » passait a la ligne) ;
//   - un enfant NON RETRECISSABLE dans une Row (les pastilles d'un
//     magasin, la ligne qui debordait de 29 px).
//
// Les deux ne se voient qu'a l'execution, et seulement quand l'ecran
// est etroit ou le texte grossi. Ce test les cherche donc la : 320
// points de large — un petit telephone, ou une fenetre partagee — et
// jusqu'au double grossissement, ce que fait le public de cette
// planche des les premiers reglages de son telephone.
//
// Il est plus severe que la realite : les tests de widget mesurent
// chaque caractere comme un carre de la taille de la fonte. Un libelle
// y est a peu pres deux fois plus large que sur l'appareil. Ce qui
// passe ici passe partout.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/theme/app_icons.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_card.dart';
import 'package:epilist/widgets/common/app_empty_state.dart';
import 'package:epilist/widgets/common/app_meters.dart';
import 'package:epilist/widgets/common/app_section_header.dart';
import 'package:epilist/widgets/common/app_states.dart';
import 'package:epilist/models/budget.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/widgets/budget/budget_card.dart';
import 'package:epilist/widgets/home/action_tile.dart';
import 'package:epilist/widgets/common/app_dialog.dart';
import 'package:epilist/widgets/common/app_search_field.dart';
import 'package:epilist/widgets/common/store_front.dart';
import 'package:epilist/widgets/home/shopping_list_card.dart';
import 'package:epilist/widgets/list_detail/item_filters_bar.dart';
import 'package:epilist/widgets/shopping/empty_list_state.dart';
import 'package:epilist/widgets/shopping/list_filter_chips.dart';
import 'package:epilist/widgets/receipts/store_group_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AppColors.palette = AppPalette.light);

  // Des libelles LONGS, pris dans l'application : ce sont eux qui
  // debordent, pas « OK ».
  const long = 'Dernière visite : 12/10/2026';
  const tresLong =
      'Alerte stock bas : Riz basmati complet, sous le seuil que vous avez fixé.';

  // Les cartes composees, celles qui vivent dans les listes : ce sont
  // elles qui ont deborde sur l'appareil, pas les briques du kit.
  final maintenant = DateTime(2026, 10, 23);
  final liste = ShoppingList(
    id: 1,
    userId: 1,
    name: 'Courses de la semaine chez Metro Sainte-Catherine',
    createdAt: maintenant,
    updatedAt: maintenant,
    items: const [],
    receiptsCount: 3,
    receiptsTotal: 145,
    hasReceiptData: true,
  );
  final budget = Budget(
    id: 1,
    userId: 1,
    name: 'Budget des courses du mois',
    budgetAmount: 10,
    formattedBudgetAmount: r'10,00 $',
    periodType: BudgetPeriodType.monthly,
    startDate: maintenant,
    endDate: DateTime(2026, 10, 31),
    alertThreshold: 80,
    isActive: true,
    spentAmount: 28,
    formattedSpentAmount: r'27,99 $',
    remainingAmount: 0,
    formattedRemainingAmount: r'0,00 $',
    spentPercentage: 280,
    daysRemaining: 8,
    status: BudgetStatus.exceeded,
    isExceeded: true,
    isNearLimit: true,
    shouldShowAlert: true,
    createdAt: maintenant,
    updatedAt: maintenant,
  );

  final morceaux = <String, Widget>{
    'AppGauge': const AppGauge(
      ratio: 0.85,
      label: '85 pour cent utilisé, 270,00 \$ restants',
    ),
    'AppCounterCard': const AppCounterCard(
      count: '14 / 17 dans le panier',
      sentence:
          'Vous avez déjà mis 14 articles dans le panier. Encore 3 articles '
          'et vos courses sont terminées.',
      ratio: 0.82,
    ),
    'AppStatCard': const AppStatCard(
      value: '1 234,56 \$',
      sentence: 'Dépensé depuis le début du mois, toutes listes confondues.',
    ),
    'AppShareRow': const AppShareRow(
      label: 'Fruits et légumes frais de saison',
      share: '32 %',
      ratio: 0.32,
      color: Color(0xFF15803D),
    ),
    'AppTrendBars': const AppTrendBars(
      bars: [
        AppTrendBar(value: 98, label: 'Août', amount: '98 \$'),
        AppTrendBar(value: 145, label: 'Septembre', amount: '145 \$'),
        AppTrendBar(
          value: 120,
          label: 'Octobre, en cours',
          amount: '120 \$',
          current: true,
        ),
      ],
    ),
    'AppSparkline': const AppSparkline(
      values: [6.99, 6.49, 5.99, 5.99],
      summary: 'Le prix descend : de 6,99 \$ à 5,99 \$ sur 4 relevés.',
    ),
    'AppCheckRow': AppCheckRow(
      checked: true,
      title: 'Bœuf haché mi-maigre 500 grammes',
      subtitle: 'Quantité : 2',
      doneLabel: 'Dans le panier',
      onChanged: (_) {},
    ),
    'AppStateChip': const AppStateChip(
      state: StockState.peremption,
      label: 'À terminer dans 2 jours',
    ),
    'AppStateSwitch': AppStateSwitch(
      value: true,
      stateLabel: 'Activée, se génère tous les samedis',
      onChanged: (_) {},
    ),
    'AppFavoriteButton': AppFavoriteButton(
      favorite: true,
      label: 'Oui, magasin favori',
      onPressed: () {},
    ),
    'AppWarningLine': const AppWarningLine(text: tresLong),
    'AppSwitchTile': AppSwitchTile(
      title: 'Renouveler à la fin de la période',
      subtitle: 'La période suivante sera créée automatiquement.',
      stateLabel: 'Oui, la période suivante sera créée',
      value: true,
      onChanged: (_) {},
    ),
    'AppZoneCard': const AppZoneCard(
      title: 'Garde-manger (12)',
      tint: Color(0xFFFACC15),
      icon: Icons.shelves,
      children: [Text(long)],
    ),
    'AppSectionHeader': const AppSectionHeader(
      title: 'Mes listes de courses',
      icon: AppIcons.lists,
      trailingLabel: 'Tout voir',
      count: '12',
    ),
    'AppEmptyState': const AppEmptyState(
      icon: AppIcons.inventory,
      title: 'Rien à la maison pour l’instant',
      message:
          'Commencez par une dizaine de produits essentiels : ce sont eux '
          'qui manquent.',
      actionLabel: 'Ajouter un produit',
    ),
    'AppCard': const AppCard(child: Text(tresLong)),
    'AppSearchField': AppSearchField(
      hintText: 'Chercher un produit dans mes provisions',
      onChanged: (_) {},
    ),
    'AppDialogHeader': const AppDialogHeader(
      icon: Icons.edit_outlined,
      title: 'Quantité, seuils et péremption',
    ),
    'AppDialogActions': AppDialogActions(
      cancelLabel: 'Annuler',
      submitLabel: 'Enregistrer ce repas',
      onCancel: () {},
      onSubmit: () {},
    ),
    'StoreFront': const StoreFront(seed: 7),
    'ListFilterChips': ListFilterChips(
      selectedFilter: ListFilter.all,
      onFilterChanged: (_) {},
    ),
    'EmptyListState': EmptyListState(onCreateList: () {}),
    'ItemFiltersBar': ItemFiltersBar(
      criteria: ItemFilterCriteria(),
      onCriteriaChanged: (_) {},
      availableStores: const ['Metro Sainte-Catherine', 'IGA Papineau'],
    ),
    'StoreStatChips': const StoreStatChips(
      receiptsCount: 3,
      lastVisit: '12/10/2026',
    ),
    'BudgetCard': BudgetCard(budget: budget),
    'ShoppingListCard': ShoppingListCard(
      list: liste,
      onTap: () {},
      onAction: (_) {},
    ),
    'ActionTileRow': ActionTileRow(
      left: ActionTile(
        icon: AppIcons.mealPlanner,
        label: 'Planifier mes repas',
        tint: const Color(0xFFFACC15),
        onTap: () {},
      ),
      right: ActionTile(
        icon: AppIcons.stores,
        label: 'Mes magasins',
        tint: const Color(0xFFF97316),
        onTap: () {},
      ),
    ),
  };

  Future<void> poser(WidgetTester tester, Widget enfant, double echelle) async {
    // 320 points : un petit telephone, ou une fenetre partagee.
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(echelle)),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: enfant,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final mode
      in {'clair': AppPalette.light, 'sombre': AppPalette.dark}.entries) {
    group(mode.key, () {
      setUp(() => AppColors.palette = mode.value);

      for (final morceau in morceaux.entries) {
        testWidgets('${morceau.key} tient sur 320 points', (tester) async {
          for (final echelle in [1.0, 1.3, 1.6, 2.0]) {
            await poser(tester, morceau.value, echelle);
            expect(
              tester.takeException(),
              isNull,
              reason: '${morceau.key} au grossissement $echelle',
            );
          }
        });
      }
    });
  }
}
