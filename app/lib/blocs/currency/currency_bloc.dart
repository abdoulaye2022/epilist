// blocs/currency/currency_bloc.dart - VERSION COMPLÈTE AVEC SYNC AUTH
import 'package:epilist/models/currency.dart';
import 'package:epilist/models/user_currency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/services/currency_service.dart';
import 'package:epilist/services/offline_storage_service.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:flutter/foundation.dart';
import 'currency_event.dart';
import 'currency_state.dart';

class CurrencyBloc extends Bloc<CurrencyEvent, CurrencyState> {
  final CurrencyService currencyService;
  final LocalizationBloc localizationBloc;
  final AuthBloc authBloc; // ✅ AJOUT pour synchroniser

  CurrencyBloc({
    required this.currencyService,
    required this.localizationBloc,
    required this.authBloc, // ✅ AJOUT
  }) : super(CurrencyInitial()) {
    on<LoadCurrencies>(_onLoadCurrencies);
    on<LoadUserCurrency>(_onLoadUserCurrency);
    on<UpdateUserCurrency>(_onUpdateUserCurrency);
    on<FormatUserAmount>(_onFormatUserAmount);
    on<SelectCurrency>(_onSelectCurrency);
    on<ClearCurrencyError>(_onClearCurrencyError);
    on<ResetCurrencySelection>(_onResetCurrencySelection);
    on<ClearCurrencyCache>(_onClearCurrencyCache);
    on<GetCurrencyByCode>(_onGetCurrencyByCode);
    on<GetCurrencyById>(_onGetCurrencyById);
  }

  /// Charger les devises disponibles
  Future<void> _onLoadCurrencies(
    LoadCurrencies event,
    Emitter<CurrencyState> emit,
  ) async {
    emit(CurrencyLoading());

    try {
      final currencies = await currencyService.getCachedCurrencies(
        forceRefresh: event.forceRefresh,
      );

      // Essayer de charger aussi la devise de l'utilisateur
      UserCurrency? userCurrency;
      try {
        userCurrency = await currencyService.getUserCurrency();
      } catch (e) {
        print('Impossible de charger la devise utilisateur: $e');
      }

      if (event.popularOnly) {
        final popularCurrencies =
            currencies.where((currency) => currency.isPopular).toList();

        emit(
          CurrenciesLoaded(
            currencies: popularCurrencies,
            userCurrency: userCurrency,
            isPopularOnly: true,
          ),
        );
      } else {
        emit(
          CurrenciesLoaded(
            currencies: currencies,
            userCurrency: userCurrency,
            isPopularOnly: false,
          ),
        );
      }
    } catch (e) {
      emit(
        CurrencyError(
          _getTranslatedErrorMessage('LOAD_CURRENCIES_ERROR', e.toString()),
        ),
      );
    }
  }

  /// Charger la devise de l'utilisateur
  Future<void> _onLoadUserCurrency(
    LoadUserCurrency event,
    Emitter<CurrencyState> emit,
  ) async {
    emit(CurrencyLoading());

    try {
      final userCurrency = await currencyService.getUserCurrency();

      // ✅ Sauvegarder dans le cache
      await OfflineStorageService.saveCurrency(userCurrency.toJson());

      emit(UserCurrencyLoaded(userCurrency));

      // ✅ SYNCHRONISATION: Mettre à jour AuthBloc avec la devise chargée
      if (authBloc.state is AuthSuccess) {
        final currentUser = (authBloc.state as AuthSuccess).user;
        final updatedUser = currentUser.withDisplayCurrency(
          userCurrency.currency,
        );
        authBloc.add(UpdateUserData(updatedUser));
      }
    } catch (e) {
      debugPrint('Error loading user currency: $e');

      // ✅ Fallback: Charger depuis le cache (mode offline)
      try {
        final cachedCurrency = await OfflineStorageService.getCurrency();
        if (cachedCurrency != null) {
          debugPrint('📦 Loading user currency from cache (offline mode)');
          final userCurrency = UserCurrency.fromJson(cachedCurrency);
          emit(UserCurrencyLoaded(userCurrency));

          // ✅ SYNCHRONISATION avec AuthBloc
          if (authBloc.state is AuthSuccess) {
            final currentUser = (authBloc.state as AuthSuccess).user;
            final updatedUser = currentUser.withDisplayCurrency(
              userCurrency.currency,
            );
            authBloc.add(UpdateUserData(updatedUser));
          }
          return;
        } else {
          debugPrint('ℹ️ No cached currency available');
          // ✅ Fallback vers la devise du profil utilisateur si disponible
          if (authBloc.state is AuthSuccess) {
            final currentUser = (authBloc.state as AuthSuccess).user;
            if (currentUser.currency != null) {
              debugPrint('📦 Using currency from user profile');
              final userCurrency = UserCurrency(
                userId: currentUser.id,
                currency: currentUser.currency!,
                setAt: DateTime.now(),
              );
              emit(UserCurrencyLoaded(userCurrency));
              return;
            }
          }
        }
      } catch (cacheError) {
        debugPrint('❌ Currency cache load failed: $cacheError');
      }

      emit(
        CurrencyError(
          _getTranslatedErrorMessage('LOAD_USER_CURRENCY_ERROR', e.toString()),
        ),
      );
    }
  }

  /// Mettre à jour la devise de l'utilisateur
  Future<void> _onUpdateUserCurrency(
    UpdateUserCurrency event,
    Emitter<CurrencyState> emit,
  ) async {
    emit(CurrencyLoading());

    try {
      final updatedUserCurrency = await currencyService.updateUserCurrency(
        event.currencyId,
      );

      final successMessage = _getTranslatedSuccessMessage('CURRENCY_UPDATED');

      // ✅ ÉTAPE CRITIQUE: Synchroniser avec AuthBloc
      // Mettre à jour l'utilisateur dans AuthBloc avec la nouvelle devise
      if (authBloc.state is AuthSuccess) {
        final currentUser = (authBloc.state as AuthSuccess).user;
        final updatedUser = currentUser.withDisplayCurrency(
          updatedUserCurrency.currency,
        );

        // Déclencher une mise à jour dans AuthBloc
        authBloc.add(UpdateUserData(updatedUser));
      }

      emit(
        UserCurrencyUpdated(
          userCurrency: updatedUserCurrency,
          message: successMessage,
        ),
      );
    } catch (e) {
      emit(
        CurrencyError(
          _getTranslatedErrorMessage('UPDATE_CURRENCY_ERROR', e.toString()),
        ),
      );
    }
  }

  /// Formater un montant dans la devise de l'utilisateur (AFFICHAGE SEULEMENT)
  Future<void> _onFormatUserAmount(
    FormatUserAmount event,
    Emitter<CurrencyState> emit,
  ) async {
    try {
      final formattedAmount = await currencyService.formatUserAmount(
        event.amount,
        showCode: event.showCode,
      );

      emit(
        AmountFormatted(
          formattedAmount: formattedAmount,
          originalAmount: event.amount,
        ),
      );
    } catch (e) {
      // En cas d'erreur, utiliser un formatage de base CAD
      final fallbackFormat = '\$${event.amount.toStringAsFixed(2)}';
      emit(
        AmountFormatted(
          formattedAmount: fallbackFormat,
          originalAmount: event.amount,
        ),
      );
    }
  }

  /// Sélectionner une devise (pour les dialogs)
  Future<void> _onSelectCurrency(
    SelectCurrency event,
    Emitter<CurrencyState> emit,
  ) async {
    try {
      final currencies = await currencyService.getCachedCurrencies();
      final selectedCurrency = currencies.firstWhere(
        (currency) => currency.id == event.currencyId,
      );

      emit(CurrencySelected(selectedCurrency));
    } catch (e) {
      emit(
        CurrencyError(
          _getTranslatedErrorMessage('SELECT_CURRENCY_ERROR', e.toString()),
        ),
      );
    }
  }

  /// Obtenir une devise par son code
  Future<void> _onGetCurrencyByCode(
    GetCurrencyByCode event,
    Emitter<CurrencyState> emit,
  ) async {
    try {
      final currency = await currencyService.getCachedCurrencyByCode(
        event.code,
      );
      if (currency != null) {
        emit(CurrencyFoundByCode(currency));
      } else {
        emit(
          CurrencyError(
            _getTranslatedErrorMessage(
              'SELECT_CURRENCY_ERROR',
              'Devise ${event.code} non trouvée',
            ),
          ),
        );
      }
    } catch (e) {
      emit(
        CurrencyError(
          _getTranslatedErrorMessage('SELECT_CURRENCY_ERROR', e.toString()),
        ),
      );
    }
  }

  /// Obtenir une devise par son ID
  Future<void> _onGetCurrencyById(
    GetCurrencyById event,
    Emitter<CurrencyState> emit,
  ) async {
    try {
      final currencies = await currencyService.getCachedCurrencies();
      final currency = currencies.firstWhere(
        (c) => c.id == event.id,
        orElse: () => throw Exception('Devise avec ID ${event.id} non trouvée'),
      );

      emit(CurrencyFoundById(currency));
    } catch (e) {
      emit(
        CurrencyError(
          _getTranslatedErrorMessage('SELECT_CURRENCY_ERROR', e.toString()),
        ),
      );
    }
  }

  /// Vider le cache des devises
  Future<void> _onClearCurrencyCache(
    ClearCurrencyCache event,
    Emitter<CurrencyState> emit,
  ) async {
    try {
      currencyService.clearCache();
      emit(CurrencyCacheCleared());
    } catch (e) {
      emit(
        CurrencyError(
          _getTranslatedErrorMessage('UNKNOWN_ERROR', e.toString()),
        ),
      );
    }
  }

  /// Effacer les erreurs
  void _onClearCurrencyError(
    ClearCurrencyError event,
    Emitter<CurrencyState> emit,
  ) {
    if (state is CurrencyError) {
      emit(CurrencyInitial());
    }
  }

  /// Réinitialiser la sélection
  void _onResetCurrencySelection(
    ResetCurrencySelection event,
    Emitter<CurrencyState> emit,
  ) {
    emit(CurrencyInitial());
  }

  /// Obtenir un message d'erreur traduit
  String _getTranslatedErrorMessage(String errorCode, String originalMessage) {
    final isEnglish =
        localizationBloc.state is LocalizationLoaded &&
        (localizationBloc.state as LocalizationLoaded).locale.languageCode ==
            'en';

    const Map<String, String> frenchMessages = {
      'LOAD_CURRENCIES_ERROR': 'Erreur lors du chargement des devises',
      'LOAD_USER_CURRENCY_ERROR': 'Erreur lors du chargement de votre devise',
      'UPDATE_CURRENCY_ERROR': 'Erreur lors de la mise à jour de la devise',
      'SELECT_CURRENCY_ERROR': 'Erreur lors de la sélection de la devise',
      'NETWORK_ERROR': 'Erreur de réseau',
      'UNKNOWN_ERROR': 'Une erreur inattendue est survenue',
      'CACHE_ERROR': 'Erreur de cache des devises',
      'CURRENCY_NOT_FOUND': 'Devise non trouvée',
      'SERVICE_ERROR': 'Erreur du service de devises',
    };

    const Map<String, String> englishMessages = {
      'LOAD_CURRENCIES_ERROR': 'Error loading currencies',
      'LOAD_USER_CURRENCY_ERROR': 'Error loading your currency',
      'UPDATE_CURRENCY_ERROR': 'Error updating currency',
      'SELECT_CURRENCY_ERROR': 'Error selecting currency',
      'NETWORK_ERROR': 'Network error',
      'UNKNOWN_ERROR': 'An unexpected error occurred',
      'CACHE_ERROR': 'Currency cache error',
      'CURRENCY_NOT_FOUND': 'Currency not found',
      'SERVICE_ERROR': 'Currency service error',
    };

    final messages = isEnglish ? englishMessages : frenchMessages;
    return messages[errorCode] ?? messages['UNKNOWN_ERROR']!;
  }

  /// Obtenir un message de succès traduit
  String _getTranslatedSuccessMessage(String successCode) {
    final isEnglish =
        localizationBloc.state is LocalizationLoaded &&
        (localizationBloc.state as LocalizationLoaded).locale.languageCode ==
            'en';

    const Map<String, String> frenchMessages = {
      'CURRENCY_UPDATED': 'Devise d\'affichage mise à jour avec succès',
      'CURRENCY_SELECTED': 'Devise d\'affichage sélectionnée',
      'CURRENCY_LOADED': 'Devise d\'affichage chargée',
      'CACHE_CLEARED': 'Cache des devises vidé',
    };

    const Map<String, String> englishMessages = {
      'CURRENCY_UPDATED': 'Display currency updated successfully',
      'CURRENCY_SELECTED': 'Display currency selected',
      'CURRENCY_LOADED': 'Display currency loaded',
      'CACHE_CLEARED': 'Currency cache cleared',
    };

    final messages = isEnglish ? englishMessages : frenchMessages;
    return messages[successCode] ?? 'Success';
  }

  /// ✅ NOUVELLE MÉTHODE: Forcer la synchronisation avec AuthBloc
  void forceSyncWithAuth() {
    if (state is UserCurrencyLoaded) {
      final userCurrency = (state as UserCurrencyLoaded).userCurrency;
      if (authBloc.state is AuthSuccess) {
        final currentUser = (authBloc.state as AuthSuccess).user;
        final updatedUser = currentUser.withDisplayCurrency(
          userCurrency.currency,
        );
        authBloc.add(UpdateUserData(updatedUser));
      }
    } else if (state is UserCurrencyUpdated) {
      final userCurrency = (state as UserCurrencyUpdated).userCurrency;
      if (authBloc.state is AuthSuccess) {
        final currentUser = (authBloc.state as AuthSuccess).user;
        final updatedUser = currentUser.withDisplayCurrency(
          userCurrency.currency,
        );
        authBloc.add(UpdateUserData(updatedUser));
      }
    }
  }

  /// ✅ NOUVELLE MÉTHODE: Obtenir la devise actuelle depuis l'état
  Currency? getCurrentCurrency() {
    if (state is UserCurrencyLoaded) {
      return (state as UserCurrencyLoaded).userCurrency.currency;
    } else if (state is UserCurrencyUpdated) {
      return (state as UserCurrencyUpdated).userCurrency.currency;
    } else if (state is CurrencySelected) {
      return (state as CurrencySelected).currency;
    } else if (authBloc.state is AuthSuccess) {
      final user = (authBloc.state as AuthSuccess).user;
      return user.currency;
    }
    return null;
  }

  /// ✅ NOUVELLE MÉTHODE: Vérifier si une devise est sélectionnée
  bool hasCurrency() {
    return getCurrentCurrency() != null;
  }

  /// ✅ NOUVELLE MÉTHODE: Obtenir le code de devise actuel
  String getCurrentCurrencyCode() {
    return getCurrentCurrency()?.code ?? 'CAD';
  }

  /// ✅ NOUVELLE MÉTHODE: Obtenir le symbole de devise actuel
  String getCurrentCurrencySymbol() {
    return getCurrentCurrency()?.symbol ?? '\$';
  }

  @override
  Future<void> close() {
    // Nettoyer les ressources si nécessaire
    return super.close();
  }
}
