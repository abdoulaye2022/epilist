// screens/stores_screen.dart - « Mes magasins ».
//
// La distance jusqu'a un magasin se CALCULE : elle demande de savoir ou
// est le telephone, et c'etait tout le manque. La question se pose donc
// ici, une fois, avec sa phrase d'explication AVANT la fenetre du
// telephone — une fenetre de permission qui tombe sans prevenir se
// refuse. Un refus est une reponse : l'ecran propose alors le code
// postal, qui donne le secteur sans donner la position.
//
// Ce que la position sert : trier du plus proche au plus loin, et
// ecrire « A 1,2 km d'ici ». Rien d'autre. Elle n'est ni enregistree,
// ni envoyee au serveur — voir services/location_service.dart.
//
// L'itineraire passe par l'application de cartes du telephone : c'est
// elle qui sait l'etat du trafic, et elle est deja installee.
//
// Ce qui N'EST PAS fait, et pourquoi : la carte avec les epingles des
// magasins favoris demande des tuiles cartographiques, donc un
// fournisseur, des conditions d'utilisation et un cout a l'usage. De
// meme pour la photo reelle d'une devanture : elle appartient a
// l'enseigne ou au service de cartes. La devanture dessinee reste donc
// l'image de secours, et l'adresse se saisit a la main.
import 'package:epilist/widgets/common/app_top_bar.dart';
import 'package:epilist/widgets/common/app_drawer.dart';
import 'package:epilist/widgets/common/main_bottom_bar.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:epilist/screens/price_alerts_screen.dart';
import 'package:epilist/services/space_service.dart';
import 'package:epilist/widgets/common/app_states.dart';
import 'package:epilist/widgets/common/store_front.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/blocs/store/store_bloc.dart';
import 'package:epilist/blocs/store/store_event.dart';
import 'package:epilist/blocs/store/store_state.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/store.dart';
import 'package:epilist/screens/store_aisle_order_screen.dart';
import 'package:epilist/services/location_service.dart';
import 'package:epilist/services/store_service.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/theme/app_icons.dart';
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class StoresScreen extends StatelessWidget {
  const StoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              StoreBloc(storeService: context.read<StoreService>())
                ..add(const LoadStores()),
      child: const _StoresView(),
    );
  }
}

class _StoresView extends StatefulWidget {
  const _StoresView();

  @override
  State<_StoresView> createState() => _StoresViewState();
}

class _StoresViewState extends State<_StoresView> {
  /// Nombre d'alertes de prix ACTIVES par magasin. `null` tant que la
  /// requete n'a pas repondu — et elle peut ne jamais repondre : la
  /// ligne « alertes actives » disparait alors, au lieu d'afficher
  /// zero, qui serait un mensonge.
  Map<int, int>? _alertesParMagasin;

  /// La reponse a la question de la position, et ce qu'elle a donne.
  LocationChoice _choix = LocationChoice.pasEncore;
  Position? _position;
  String? _codePostal;
  bool _positionEnCours = false;

  @override
  void initState() {
    super.initState();
    _chargerAlertes();
    _chargerLeChoix();
    // « 4 articles a prendre chez IGA » se lit dans les listes. Si
    // personne n'est encore passe par l'onglet Listes, elles ne sont
    // pas chargees : on les demande, et le listener rafraichit l'ecran
    // quand elles arrivent.
    final listes = context.read<ShoppingListBloc>();
    if (listes.state is! ShoppingListLoaded) {
      listes.add(const LoadShoppingLists());
    }
  }

  Future<void> _chargerLeChoix() async {
    final choix = await LocationService.choix();
    final code = await LocationService.codePostal();
    if (!mounted) return;
    setState(() {
      _choix = choix;
      _codePostal = code;
    });
    // Le choix est deja fait : on reprend la position sans rien
    // demander. La permission du telephone reste maitresse, et un refus
    // depuis les reglages se traduit simplement par aucune distance.
    if (choix == LocationChoice.position) _demanderLaPosition(garder: false);
  }

  /// Demande la position. [garder] enregistre la reponse — on ne la
  /// garde qu'au premier passage, pas aux rafraichissements.
  Future<void> _demanderLaPosition({bool garder = true}) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _positionEnCours = true);
    final position = await LocationService.position();
    if (!mounted) return;
    setState(() {
      _position = position;
      _positionEnCours = false;
      if (garder) _choix = LocationChoice.position;
    });
    if (garder) await LocationService.garderLeChoix(LocationChoice.position);
    if (position == null && mounted) {
      // Service eteint, permission refusee, delai depasse : on le DIT,
      // et on propose le code postal plutot que de laisser un bouton
      // qui ne repond pas.
      SmartSnackBarManager.showInfoSnackBar(
        context,
        l10n.storeLocationUnavailable,
      );
    }
  }

  Future<void> _demanderLeCodePostal() async {
    final l10n = AppLocalizations.of(context)!;
    final controleur = TextEditingController(text: _codePostal ?? '');

    final donne = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.storePostalTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.storePostalWhy,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: controleur,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 7,
                  decoration: const InputDecoration(hintText: 'H3B 1A1'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.save),
              ),
            ],
          ),
    );
    if (donne != true || !mounted) return;

    final code = controleur.text.trim();
    await LocationService.garderLeCodePostal(code);
    await LocationService.garderLeChoix(LocationChoice.codePostal);
    if (!mounted) return;
    setState(() {
      _codePostal = code.isEmpty ? null : code.toUpperCase();
      _choix = LocationChoice.codePostal;
      _position = null;
    });
  }

  Future<void> _refuserLaPosition() async {
    await LocationService.garderLeChoix(LocationChoice.refusee);
    if (!mounted) return;
    setState(() {
      _choix = LocationChoice.refusee;
      _position = null;
    });
  }

  /// La distance jusqu'a ce magasin, ou `null` : sans position, ou sans
  /// coordonnees pour le magasin.
  double? _distanceKm(Store store) {
    final p = _position;
    if (p == null || store.latitude == null || store.longitude == null) {
      return null;
    }
    return LocationService.distanceKm(
      p.latitude,
      p.longitude,
      store.latitude!,
      store.longitude!,
    );
  }

  /// Combien d'articles restent a prendre dans ce magasin.
  ///
  /// « 4 articles a prendre chez IGA » : c'est ce qui donne un usage a
  /// la liste des magasins, et il se lit dans les listes deja
  /// chargees — aucun appel de plus.
  int _articlesAPrendre(Store store) {
    final etat = context.read<ShoppingListBloc>().state;
    if (etat is! ShoppingListLoaded) return 0;
    final nom = store.name.trim().toLowerCase();
    var compte = 0;
    for (final liste in etat.lists) {
      for (final article in liste.items) {
        if (article.isPurchased) continue;
        if ((article.storeName ?? '').trim().toLowerCase() == nom) compte++;
      }
    }
    return compte;
  }

  /// Ouvre l'itineraire dans l'application de cartes du telephone.
  ///
  /// Les coordonnees d'abord quand on les a, l'adresse ecrite sinon :
  /// une adresse se cherche, des coordonnees se pointent.
  Future<void> _itineraire(Store store) async {
    final l10n = AppLocalizations.of(context)!;
    final adresse = store.addressLine;
    if (store.latitude == null && adresse == null) {
      SmartSnackBarManager.showInfoSnackBar(
        context,
        l10n.storeDirectionsNoAddress,
      );
      return;
    }

    final requete =
        store.latitude != null && store.longitude != null
            ? '${store.latitude},${store.longitude}'
            : Uri.encodeComponent(adresse!);
    // Le schema universel des applications de cartes. Il ouvre Plans
    // sur iPhone, Google Maps ou l'application installee sur Android —
    // et c'est a l'utilisatrice que le choix revient, pas a nous.
    final lien = Uri.parse('https://maps.apple.com/?daddr=$requete');
    final geo = Uri.parse('geo:0,0?q=$requete');

    try {
      if (await canLaunchUrl(geo)) {
        await launchUrl(geo, mode: LaunchMode.externalApplication);
        return;
      }
      if (await canLaunchUrl(lien)) {
        await launchUrl(lien, mode: LaunchMode.externalApplication);
        return;
      }
      if (!mounted) return;
      SmartSnackBarManager.showErrorSnackBar(
        context,
        l10n.storeDirectionsFailed,
      );
    } catch (_) {
      if (!mounted) return;
      SmartSnackBarManager.showErrorSnackBar(
        context,
        l10n.storeDirectionsFailed,
      );
    }
  }

  /// Allume ou eteint l'etoile, et le dit tout de suite.
  ///
  /// L'ecran se recharge depuis le bloc : le serveur est la source de
  /// verite du favori, et c'est lui qui decide aussi de l'ordre — les
  /// magasins favoris remontent en tete.
  Future<void> _basculerFavori(Store store) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await context.read<StoreService>().setFavorite(
        store.id,
        !store.isFavorite,
      );
      if (!mounted) return;
      context.read<StoreBloc>().add(const LoadStores());
    } catch (_) {
      if (!mounted) return;
      SmartSnackBarManager.showErrorSnackBar(context, l10n.storeFavoriteFailed);
    }
  }

  /// Une ligne « icone + phrase », pour l'adresse et les horaires.
  Widget _ligne(IconData icone, String texte) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 22, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              texte,
              style: TextStyle(
                fontSize: 17,
                height: 1.45,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// « Ouvert aujourd'hui de 8 h a 21 h » ou « Ferme aujourd'hui ».
  ///
  /// La phrase parle du JOUR EN COURS : c'est la seule question qu'on
  /// se pose devant une carte de magasin.
  String _horairesDuJour(AppLocalizations l10n, Store store) {
    final heures = store.hoursFor(DateTime.now().weekday);
    return heures == null
        ? l10n.storeClosedToday
        : l10n.storeOpenToday(heures.open, heures.close);
  }

  /// « Ouvert maintenant » ou « Ferme maintenant ».
  ///
  /// Chaine vide quand on ne sait pas : « Ferme » affiche faute
  /// d'horaires ferait renoncer a une sortie.
  String _ouvertMaintenant(AppLocalizations l10n, Store store) {
    final ouvert = store.isOpenAt();
    if (ouvert == null) return '';
    return ouvert ? l10n.storeOpenNow : l10n.storeClosedNow;
  }

  Future<void> _chargerAlertes() async {
    try {
      final alertes = await context.read<SpaceService>().getPriceAlerts();
      if (!mounted) return;
      final compte = <int, int>{};
      for (final a in alertes) {
        if (!a.isActive || a.storeId == null) continue;
        compte[a.storeId!] = (compte[a.storeId!] ?? 0) + 1;
      }
      setState(() => _alertesParMagasin = compte);
    } catch (_) {
      // Sans reponse, on n'ecrit rien sur les alertes.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppPageBottomBar(tab: MainTab.sections),
      appBar: AppTopBar(title: l10n.myStores),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStoreNameDialog(context),
        backgroundColor: AppColors.primary,
        icon: Icon(Icons.add_business, color: AppColors.onPrimary),
        label: Text(
          l10n.addStore,
          style: TextStyle(color: AppColors.onPrimary),
        ),
      ),
      body: BlocListener<ShoppingListBloc, ShoppingListState>(
        // Les listes arrivent : les compteurs « a prendre ici » peuvent
        // enfin s'ecrire.
        listener: (context, state) {
          if (state is ShoppingListLoaded && mounted) setState(() {});
        },
        child: BlocConsumer<StoreBloc, StoreState>(
          listener: (context, state) {
            if (state is StoreError) {
              SmartSnackBarManager.showErrorSnackBar(context, state.message);
            } else if (state is StoreOperationSuccess) {
              final message = switch (state.message) {
                'store_created' => l10n.storeCreated,
                'store_renamed' => l10n.storeRenamed,
                'store_deleted' => l10n.storeDeleted,
                'order_saved' => l10n.aisleOrderSaved,
                'stores_merged' => l10n.storesMerged,
                _ => state.message,
              };
              SmartSnackBarManager.showSuccessSnackBar(context, message);
            }
          },
          builder: (context, state) {
            if (state is StoreLoading || state is StoreInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            final stores = switch (state) {
              StoreLoaded(:final stores) => stores,
              StoreOperationSuccess(:final stores) => stores,
              StoreError(:final stores) => stores,
              _ => const <Store>[],
            };

            if (stores.isEmpty) {
              return _buildEmptyState(l10n);
            }

            // Tri par distance REELLE quand on la connait. Les magasins
            // sans coordonnees passent apres, dans l'ordre du serveur
            // (favoris en tete) : les ranger au hasard effacerait le
            // seul classement qu'on ait.
            final tries = [...stores];
            if (_position != null) {
              tries.sort((a, b) {
                final da = _distanceKm(a);
                final db = _distanceKm(b);
                if (da == null && db == null) return 0;
                if (da == null) return 1;
                if (db == null) return -1;
                return da.compareTo(db);
              });
            }

            return RefreshIndicator(
              onRefresh:
                  () async => context.read<StoreBloc>().add(const LoadStores()),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: tries.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Text(
                            l10n.storesIntro,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        _carteDeLaPosition(l10n),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    );
                  }
                  final store = tries[index - 1];
                  return _buildStoreCard(
                    context,
                    l10n,
                    store,
                    _alertesParMagasin?[store.id] ??
                        (_alertesParMagasin == null ? null : 0),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// La question de la position, et ce qu'elle a donne.
  ///
  /// Tant qu'elle n'a pas de reponse, elle s'explique AVANT d'ouvrir la
  /// fenetre du telephone — c'est tout l'objet de cette carte. Une fois
  /// repondue, elle se reduit a une ligne, avec de quoi revenir dessus.
  Widget _carteDeLaPosition(AppLocalizations l10n) {
    if (_choix != LocationChoice.pasEncore) {
      final secteur = LocationService.secteur(_codePostal);
      final dit = switch (_choix) {
        LocationChoice.position =>
          _position != null
              ? l10n.storeLocationUse
              : l10n.storeLocationUnavailable,
        LocationChoice.codePostal =>
          secteur != null
              ? l10n.storeInMySector(secteur)
              : l10n.storePostalTitle,
        _ => l10n.storeLocationRefused,
      };

      return Row(
        children: [
          Icon(AppIcons.storePin, size: 22, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              dit,
              style: TextStyle(
                fontSize: 16.5,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _choix = LocationChoice.pasEncore),
            child: Text(l10n.storeLocationRedo),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppTint.fill(AppColors.accent),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppTint.line(AppColors.accent), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.storeLocationTitle,
            style: AppFonts.displayStyle(
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // La phrase AVANT la fenetre du telephone : elle dit a quoi
          // sert la position, et ce qu'on n'en fait pas.
          Text(
            l10n.storeLocationWhy,
            style: TextStyle(
              fontSize: 17,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _positionEnCours ? null : () => _demanderLaPosition(),
            icon:
                _positionEnCours
                    ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.my_location_rounded),
            label: Text(l10n.storeLocationUse),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          OutlinedButton.icon(
            onPressed: _demanderLeCodePostal,
            icon: const Icon(Icons.markunread_mailbox_outlined),
            label: Text(l10n.storeLocationPostal),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          // Refuser doit etre aussi simple qu'accepter, et aussi
          // visible.
          OutlinedButton.icon(
            onPressed: _refuserLaPosition,
            icon: const Icon(Icons.location_off_outlined),
            label: Text(l10n.storeLocationNever),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront, size: 72, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(
              l10n.noStoresYet,
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontVariations: const [FontVariation('wght', 800)],
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noStoresHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// La carte d'un magasin, comme sur la planche : sa devanture, ce
  /// qu'on sait de lui en phrases, son etoile avec l'etat ECRIT, et ses
  /// deux actions.
  ///
  /// Avant, tout cela tenait dans une `ListTile` : une pastille grise
  /// identique pour chaque magasin, un sous-titre de 13 points, et
  /// l'ordre des rayons atteignable par un appui sur la ligne — sans
  /// que rien ne dise qu'elle etait touchable.
  Widget _buildStoreCard(
    BuildContext context,
    AppLocalizations l10n,
    Store store,
    int? alertes,
  ) {
    final configured = store.hasAisleOrder;
    final distance = _distanceKm(store);
    final aPrendre = _articlesAPrendre(store);
    // Magasin créé hors ligne, pas encore synchronisé : édition bloquée
    // tant que le serveur ne lui a pas donné son vrai id.
    final pendingSync = store.id < 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              image: true,
              label: l10n.storeFrontOf(store.name),
              child: StoreFront(seed: store.id),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.name,
                          style: AppFonts.displayStyle(
                            size: 23,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (pendingSync)
                        Icon(Icons.cloud_upload, color: AppColors.warningInk)
                      else
                        _storeMenu(context, l10n, store),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    pendingSync
                        ? l10n.storePendingSync
                        : configured
                        ? l10n.storeAisleConfigured(store.categoryOrder.length)
                        : l10n.storeAisleMissing,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (alertes != null) ...[
                    const SizedBox(height: AppSpacing.xs + 2),
                    Text(
                      l10n.storeActiveAlerts(alertes),
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                  // L'adresse et les horaires que la planche montre sur
                  // chaque carte. Ils n'existaient pas en base avant la
                  // migration 012 : la carte n'avait que le nom.
                  if (store.addressLine != null) ...[
                    const SizedBox(height: AppSpacing.xs + 2),
                    _ligne(Icons.place_outlined, store.addressLine!),
                  ],
                  if (store.hasOpeningHours) ...[
                    const SizedBox(height: AppSpacing.xs + 2),
                    _ligne(
                      Icons.schedule_outlined,
                      // « Ouvert maintenant » d'abord, les heures du
                      // jour ensuite : c'est la question qu'on se pose
                      // devant une carte de magasin, et il fallait
                      // jusqu'ici comparer soi-meme avec sa montre.
                      // Le point separateur ne s'ecrit que s'il separe
                      // vraiment deux phrases.
                      [
                        _ouvertMaintenant(l10n, store),
                        _horairesDuJour(l10n, store),
                      ].where((p) => p.isNotEmpty).join(' · '),
                    ),
                  ],
                  // La distance, CALCULEE : elle n'existe que si la
                  // position est connue et le magasin situe.
                  if (distance != null) ...[
                    const SizedBox(height: AppSpacing.xs + 2),
                    _ligne(
                      AppIcons.storePin,
                      l10n.storeDistance(
                        LocationService.distanceEcrite(
                          distance,
                          anglais:
                              Localizations.localeOf(context).languageCode ==
                              'en',
                        ),
                      ),
                    ),
                  ],
                  // Ce qui donne un usage a tout ceci : ce qu'il reste
                  // a prendre ICI.
                  if (aPrendre > 0) ...[
                    const SizedBox(height: AppSpacing.xs + 2),
                    _ligne(
                      Icons.shopping_basket_outlined,
                      l10n.storeItemsToGet(aPrendre),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm + 4),
                  // Le favori vit sur le SERVEUR depuis la migration
                  // 012. Il suivait l'appareil auparavant : perdu au
                  // changement de telephone, et invisible pour les
                  // autres membres de l'espace.
                  AppFavoriteButton(
                    favorite: store.isFavorite,
                    label:
                        store.isFavorite
                            ? l10n.storeFavoriteYes
                            : l10n.storeFavoriteNo,
                    // Un magasin pas encore synchronise n'a pas
                    // d'identifiant serveur : l'etoile ne peut rien
                    // enregistrer, et on le DIT plutot que d'offrir un
                    // bouton qui ne repond pas.
                    onPressed:
                        pendingSync
                            ? () => SmartSnackBarManager.showInfoSnackBar(
                              context,
                              l10n.storePendingSync,
                            )
                            : () => _basculerFavori(store),
                  ),
                  const SizedBox(height: AppSpacing.sm + 4),
                  // L'itineraire part dans l'application de cartes du
                  // telephone : c'est elle qui sait le trafic, et elle
                  // est deja installee.
                  OutlinedButton.icon(
                    onPressed: () => _itineraire(store),
                    icon: const Icon(Icons.directions_outlined),
                    label: Text(l10n.storeDirections),
                  ),
                  const SizedBox(height: AppSpacing.sm + 4),
                  OutlinedButton.icon(
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PriceAlertsScreen(),
                          ),
                        ),
                    icon: const Icon(AppIcons.priceAlerts),
                    label: Text(l10n.storeSeeAlerts),
                  ),
                  const SizedBox(height: AppSpacing.sm + 4),
                  FilledButton.icon(
                    onPressed:
                        pendingSync
                            ? null
                            : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => BlocProvider.value(
                                      value: context.read<StoreBloc>(),
                                      child: StoreAisleOrderScreen(
                                        storeId: store.id,
                                      ),
                                    ),
                              ),
                            ),
                    icon: const Icon(Icons.reorder_rounded),
                    label: Text(l10n.aisleOrder),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renommer, fusionner, supprimer.
  Widget _storeMenu(BuildContext context, AppLocalizations l10n, Store store) {
    return PopupMenuButton<String>(
      color: AppColors.surface,
      onSelected: (value) {
        switch (value) {
          case 'rename':
            _showStoreNameDialog(context, store: store);
            break;
          case 'merge':
            _showMergeDialog(context, l10n, store);
            break;
          case 'delete':
            _confirmDelete(context, l10n, store);
            break;
        }
      },
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    // « Le magasin et son adresse », et non
                    // « Renommer » : c'est la que l'adresse se saisit,
                    // et « Renommer » ne le laissait pas deviner.
                    l10n.storeDetailsTitle,
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'merge',
              child: Row(
                children: [
                  Icon(Icons.merge, size: 20, color: AppColors.teal),
                  const SizedBox(width: 8),
                  Text(
                    l10n.mergeStore,
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(
                    l10n.deleteStore,
                    style: TextStyle(color: AppColors.error),
                  ),
                ],
              ),
            ),
          ],
    );
  }

  /// Le nom ET l'adresse.
  ///
  /// Les colonnes d'adresse existaient en base depuis la migration 012,
  /// et l'API les acceptait — mais AUCUN ecran ne les remplissait. Une
  /// adresse qu'on ne peut pas saisir ne sert ni a l'itineraire, ni a
  /// la distance.
  void _showStoreNameDialog(BuildContext context, {Store? store}) {
    final l10n = AppLocalizations.of(context)!;
    final nom = TextEditingController(text: store?.name ?? '');
    final adresse = TextEditingController(text: store?.address ?? '');
    final ville = TextEditingController(text: store?.city ?? '');
    final code = TextEditingController(text: store?.postalCode ?? '');
    final bloc = context.read<StoreBloc>();

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              store == null ? l10n.addStore : l10n.storeDetailsTitle,
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nom,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 120,
                    decoration: InputDecoration(
                      labelText: l10n.storeName,
                      hintText: l10n.storeNameHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  Text(
                    l10n.storeDetailsHint,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: adresse,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 255,
                    decoration: InputDecoration(
                      labelText: l10n.storeAddressLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: ville,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 120,
                    decoration: InputDecoration(
                      labelText: l10n.storeCityLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: code,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 12,
                    decoration: InputDecoration(
                      labelText: l10n.storePostalLabel,
                      hintText: 'H3B 1A1',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                onPressed: () async {
                  final nouveau = store == null;
                  _submitStoreName(dialogContext, bloc, nom.text, store);
                  // L'adresse passe par l'API des details, que le bloc
                  // ne connait pas. Sur un magasin NOUVEAU, son
                  // identifiant n'existe pas encore : l'adresse se
                  // saisit alors par « Le magasin et son adresse »,
                  // juste apres la creation.
                  if (!nouveau && store.id > 0) {
                    await _enregistrerLAdresse(
                      store,
                      nom.text,
                      adresse.text,
                      ville.text,
                      code.text,
                    );
                  }
                },
                child: Text(store == null ? l10n.addStore : l10n.save),
              ),
            ],
          ),
    );
  }

  /// Enregistre l'adresse, en gardant le nom que le serveur exige.
  Future<void> _enregistrerLAdresse(
    Store store,
    String nom,
    String adresse,
    String ville,
    String code,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await context.read<StoreService>().updateStoreDetails(
        store.id,
        name: nom.trim().isEmpty ? store.name : nom.trim(),
        address: adresse.trim(),
        city: ville.trim(),
        postalCode: code.trim().toUpperCase(),
      );
      if (!mounted) return;
      context.read<StoreBloc>().add(const LoadStores());
    } catch (_) {
      if (!mounted) return;
      SmartSnackBarManager.showErrorSnackBar(context, l10n.error);
    }
  }

  void _submitStoreName(
    BuildContext dialogContext,
    StoreBloc bloc,
    String name,
    Store? store,
  ) {
    final trimmed = name.trim();
    if (trimmed.length < 2) return;
    Navigator.of(dialogContext).pop();
    if (store == null) {
      bloc.add(CreateStore(trimmed));
    } else {
      bloc.add(RenameStore(store.id, trimmed));
    }
  }

  void _showMergeDialog(
    BuildContext context,
    AppLocalizations l10n,
    Store source,
  ) {
    final bloc = context.read<StoreBloc>();
    final state = bloc.state;
    final all = switch (state) {
      StoreLoaded(:final stores) => stores,
      StoreOperationSuccess(:final stores) => stores,
      StoreError(:final stores) => stores,
      _ => const <Store>[],
    };
    final targets = all.where((s) => s.id != source.id && s.id > 0).toList();
    if (targets.isEmpty) return;

    showDialog(
      context: context,
      builder:
          (dialogContext) => SimpleDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              '${l10n.mergeStore} ${source.name}',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
            children:
                targets
                    .map(
                      (target) => SimpleDialogOption(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _confirmMerge(context, l10n, source, target);
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.storefront,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                target.name,
                                style: TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
          ),
    );
  }

  void _confirmMerge(
    BuildContext context,
    AppLocalizations l10n,
    Store source,
    Store target,
  ) {
    final bloc = context.read<StoreBloc>();
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              l10n.mergeStore,
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Text(
              l10n.mergeStoreConfirm(source.name, target.name),
              style: TextStyle(color: AppColors.textPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: AppColors.onPrimary,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  bloc.add(MergeStores(source.id, target.id));
                },
                child: Text(l10n.mergeStore),
              ),
            ],
          ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
    Store store,
  ) {
    final bloc = context.read<StoreBloc>();
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              l10n.deleteStore,
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Text(
              l10n.deleteStoreConfirm(store.name),
              style: TextStyle(color: AppColors.textPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  bloc.add(DeleteStore(store.id));
                },
                child: Text(l10n.delete),
              ),
            ],
          ),
    );
  }
}
