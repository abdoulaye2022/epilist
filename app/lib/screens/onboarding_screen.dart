// screens/onboarding_screen.dart — les trois premières minutes.
//
// L'audit a compté environ quatorze gestes entre l'installation et la
// première liste, dont un aller-retour dans une boîte de courriel. Ce
// parcours s'occupe de ce qui reste une fois la porte ouverte : créer
// une liste, inviter quelqu'un, poser un budget.
//
// TROIS RÈGLES, et elles comptent plus que le contenu :
//
//   1. chaque écran a « Passer », visible, en haut à droite. Personne
//      n'est retenu ;
//   2. rien n'est obligatoire — on peut traverser les trois pages sans
//      rien faire et se retrouver dans l'application ;
//   3. il ne se montre QU'UNE FOIS, et le drapeau vit sur le serveur :
//      changer de téléphone ne doit pas le faire revenir.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/services/analytics_tracker.dart';
import 'package:epilist/models/shared_enums.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:epilist/services/onboarding_service.dart';
import 'package:epilist/services/shared_list_service.dart';
import 'package:epilist/services/shopping_list_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controleurPages = PageController();
  final _controleurNom = TextEditingController();

  /// Les articles cochés sur la première page. Rien n'est coché par
  /// défaut : une liste pré-remplie qu'on n'a pas choisie se vide mal.
  final Set<String> _choisis = {};

  int _page = 0;
  bool _enCours = false;

  /// La liste créée à la première page — c'est elle qu'on partagera.
  int? _listeCreee;

  @override
  void initState() {
    super.initState();
    // Le nom est pré-rempli : il y a moins d'effort à effacer un mot
    // qu'à en trouver un devant un champ vide.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controleurNom.text = AppLocalizations.of(context)!.onboardFirstListName;
    });
  }

  @override
  void dispose() {
    _controleurPages.dispose();
    _controleurNom.dispose();
    super.dispose();
  }

  /// Quitter, par « Passer » comme par « Terminer » : dans les deux cas
  /// le parcours est vu, et ne doit plus revenir.
  Future<void> _terminer() async {
    final service = context.read<OnboardingService>();
    final navigateur = Navigator.of(context);

    // Passer est une reponse, pas un silence : on la mesure comme le
    // reste, sinon on ne saura jamais QUELLE etape fait fuir.
    _mesurer(_etapeCourante, 'skip');

    await service.marquerTermine();

    if (mounted) {
      navigateur.pop();
    }
  }

  /// Le nom de l'etape affichee, pour la mesure.
  String get _etapeCourante => switch (_page) {
    0 => 'first_list',
    1 => 'invite',
    _ => 'budget',
  };

  /// Aucun contenu ne part : l'etape et « done » ou « skip », rien de plus.
  void _mesurer(String etape, String action) {
    context.read<AnalyticsTracker>().etapeParcours(etape: etape, action: action);
  }

  void _pageSuivante() {
    if (_page >= 2) {
      _terminer();
      return;
    }

    _controleurPages.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  // ------------------------------------------------ première liste

  Future<void> _creerLaListe() async {
    final l10n = AppLocalizations.of(context)!;
    final nom = _controleurNom.text.trim();

    if (nom.isEmpty) {
      _pageSuivante();
      return;
    }

    setState(() => _enCours = true);

    try {
      final service = context.read<ShoppingListService>();
      final itemService = context.read<ListItemService>();
      final liste = await service.createShoppingList(nom);

      _listeCreee = liste.id;

      // Les articles cochés, un par un. Un échec sur l'un d'eux ne doit
      // pas faire perdre la liste : on continue.
      for (final article in _choisis) {
        try {
          await itemService.addListItem(listId: liste.id, productName: article);
        } catch (e) {
          debugPrint('[Onboarding] article non ajouté ($article) : $e');
        }
      }

      if (!mounted) return;

      _mesurer('first_list', 'done');
      setState(() => _enCours = false);
      _pageSuivante();
    } catch (e) {
      if (!mounted) return;

      setState(() => _enCours = false);
      SmartSnackBarManager.showMessage(
        context,
        l10n.anErrorOccurred,
        type: SnackBarType.error,
      );
      _pageSuivante();
    }
  }

  // ------------------------------------------------ invitation

  Future<void> _partagerLaListe() async {
    final l10n = AppLocalizations.of(context)!;
    final listeId = _listeCreee;

    if (listeId == null) {
      _pageSuivante();
      return;
    }

    setState(() => _enCours = true);

    try {
      final partage = await context.read<SharedListService>().createShareLink(
        listId: listeId,
        permission: SharePermission.edit,
      );

      if (!mounted) return;

      setState(() => _enCours = false);

      // Le message porte le lien ET le code à six caractères : le lien
      // ne survit pas toujours au passage par le magasin, le code si.
      final message = (partage['share_message'] ?? partage['share_url'] ?? '')
          .toString();

      if (message.isEmpty) {
        _pageSuivante();
        return;
      }

      await SharePlus.instance.share(ShareParams(text: message));

      if (mounted) {
        _mesurer('invite', 'done');
        context.read<AnalyticsTracker>().listePartagee(canal: 'native_sheet');
        _pageSuivante();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _enCours = false);
      SmartSnackBarManager.showMessage(
        context,
        l10n.anErrorOccurred,
        type: SnackBarType.error,
      );
      _pageSuivante();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // « Passer » en haut à droite, sur les trois pages.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  right: AppSpacing.sm,
                  top: AppSpacing.xs,
                ),
                child: TextButton(
                  onPressed: _enCours ? null : _terminer,
                  child: Text(l10n.skipStep),
                ),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _controleurPages,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _pagePremiereListe(l10n),
                  _pageInvitation(l10n),
                  _pageBudget(l10n),
                ],
              ),
            ),

            _points(),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _points() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(3, (i) {
      final actif = i == _page;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: actif ? 18 : 6,
        height: 6,
        decoration: BoxDecoration(
          color: actif ? AppColors.primary : AppColors.border,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }),
  );

  Widget _cadre({
    required IconData icone,
    required String titre,
    required String corps,
    required List<Widget> contenu,
    required String libelleAction,
    required VoidCallback action,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icone, size: 30, color: AppColors.primaryDark),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            titre,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontVariations: const [FontVariation('wght', 800)],
              fontSize: 24,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            corps,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...contenu,
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: _enCours ? null : action,
            child:
                _enCours
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(libelleAction),
          ),
        ],
      ),
    );
  }

  Widget _pagePremiereListe(AppLocalizations l10n) {
    // Cinq suggestions, volontairement banales : ce qu'on retrouve dans
    // presque toutes les listes, pour que le premier toucher soit utile
    // et non un exercice d'imagination.
    final suggestions = [
      l10n.onboardSuggestionBread,
      l10n.onboardSuggestionMilk,
      l10n.onboardSuggestionEggs,
      l10n.onboardSuggestionFruit,
      l10n.onboardSuggestionCoffee,
    ];

    return _cadre(
      icone: Icons.playlist_add_check_rounded,
      titre: l10n.onboardFirstListTitle,
      corps: l10n.onboardFirstListBody,
      libelleAction: l10n.onboardCreateList,
      action: _creerLaListe,
      contenu: [
        TextField(
          controller: _controleurNom,
          enabled: !_enCours,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.listName,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.onboardSuggestionsTitle,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children:
              suggestions.map((article) {
                final choisi = _choisis.contains(article);

                return FilterChip(
                  label: Text(article),
                  selected: choisi,
                  onSelected:
                      _enCours
                          ? null
                          : (valeur) => setState(() {
                            if (valeur) {
                              _choisis.add(article);
                            } else {
                              _choisis.remove(article);
                            }
                          }),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _pageInvitation(AppLocalizations l10n) {
    return _cadre(
      icone: Icons.group_add_outlined,
      titre: l10n.onboardInviteTitle,
      corps: l10n.onboardInviteBody,
      libelleAction: l10n.onboardInviteAction,
      action: _partagerLaListe,
      contenu: const [],
    );
  }

  Widget _pageBudget(AppLocalizations l10n) {
    return _cadre(
      icone: Icons.savings_outlined,
      titre: l10n.onboardBudgetTitle,
      corps: l10n.onboardBudgetBody,
      libelleAction: l10n.onboardFinish,
      action: () {
        _mesurer('budget', 'done');
        _terminer();
      },
      contenu: const [],
    );
  }
}
