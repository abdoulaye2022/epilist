// services/currency_service.dart - VERSION AVEC DEVISES PRÉDÉFINIES
import 'package:dio/dio.dart';
import 'package:epilist/models/currency.dart';
import 'package:epilist/models/user_currency.dart';
import 'package:epilist/services/auth_service.dart';

class CurrencyService {
  final Dio dio;
  final AuthService authService;

  CurrencyService({required this.dio, required this.authService});

  /// ✅ NOUVEAU: Obtenir toutes les devises prédéfinies (pas d'appel réseau)
  Future<List<Currency>> getAllCurrencies({bool popularOnly = false}) async {
    try {
      print('🔄 Utilisation des devises prédéfinies (pas d\'appel API)');

      if (popularOnly) {
        final popularCurrencies = Currency.getPopular();
        print('✅ ${popularCurrencies.length} devises populaires chargées');
        return popularCurrencies;
      } else {
        final allCurrencies = Currency.getActive();
        print('✅ ${allCurrencies.length} devises actives chargées');
        return allCurrencies;
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des devises prédéfinies: $e');
      // Fallback avec les devises de base
      return [Currency.cad, Currency.usd, Currency.eur, Currency.gbp];
    }
  }

  /// ✅ NOUVEAU: Obtenir les devises populaires prédéfinies
  Future<List<Currency>> getPopularCurrencies() async {
    try {
      print('🔄 Récupération des devises populaires prédéfinies');
      final popularCurrencies = Currency.getPopular();
      print('✅ ${popularCurrencies.length} devises populaires disponibles');
      return popularCurrencies;
    } catch (e) {
      print('❌ Erreur lors de la récupération des devises populaires: $e');
      return [Currency.cad, Currency.usd, Currency.eur, Currency.gbp];
    }
  }

  /// ✅ NOUVEAU: Obtenir une devise par ID ou code (prédéfinie)
  Future<Currency> getCurrency(String idOrCode) async {
    try {
      print('🔍 Recherche de la devise: $idOrCode');

      Currency? currency;

      // Essayer par ID si c'est un nombre
      if (int.tryParse(idOrCode) != null) {
        final id = int.parse(idOrCode);
        currency = Currency.findById(id);
        if (currency != null) {
          print('✅ Devise trouvée par ID: ${currency.code}');
          return currency;
        }
      }

      // Essayer par code
      currency = Currency.findByCode(idOrCode);
      if (currency != null) {
        print('✅ Devise trouvée par code: ${currency.code}');
        return currency;
      }

      throw Exception('Devise non trouvée: $idOrCode');
    } catch (e) {
      print('❌ Erreur lors de la recherche de devise: $e');
      throw Exception('Devise non trouvée');
    }
  }

  /// Obtenir la devise d'affichage de l'utilisateur actuel
  Future<UserCurrency> getUserCurrency() async {
    try {
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      print('🔄 Récupération de la devise utilisateur depuis l\'API...');
      final response = await dio.get(
        '/user/currency',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        print('✅ Réponse API reçue pour la devise utilisateur');
        return UserCurrency.fromJson(response.data);
      } else {
        throw Exception(
          'Erreur lors de la récupération de la devise d\'affichage utilisateur',
        );
      }
    } on DioException catch (e) {
      print(
        '❌ Erreur réseau lors de la récupération de la devise utilisateur: ${e.message}',
      );
      if (e.response?.statusCode == 401) {
        throw Exception('Token d\'authentification invalide');
      }
      throw Exception('Erreur réseau: ${e.message}');
    } catch (e) {
      print(
        '❌ Erreur inattendue lors de la récupération de la devise utilisateur: $e',
      );
      throw Exception('Erreur inattendue: $e');
    }
  }

  /// Mettre à jour la devise d'affichage de l'utilisateur
  Future<UserCurrency> updateUserCurrency(int currencyId) async {
    try {
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      print('🔄 Mise à jour de la devise utilisateur vers ID: $currencyId');

      final response = await dio.put(
        '/user/currency',
        data: {'currency_id': currencyId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        print('✅ Devise utilisateur mise à jour avec succès');
        // Récupérer la devise mise à jour
        return await getUserCurrency();
      } else {
        throw Exception(
          'Erreur lors de la mise à jour de la devise d\'affichage',
        );
      }
    } on DioException catch (e) {
      print('❌ Erreur lors de la mise à jour de la devise: ${e.message}');
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData != null && errorData['error'] != null) {
          final errorCode = errorData['error']['code'];
          if (errorCode == 'INVALID_CURRENCY') {
            throw Exception('Devise d\'affichage sélectionnée non disponible');
          } else if (errorCode == 'VALIDATION_ERROR') {
            throw Exception('Données de devise invalides');
          }
        }
      } else if (e.response?.statusCode == 401) {
        throw Exception('Token d\'authentification invalide');
      } else if (e.response?.statusCode == 422) {
        throw Exception('Données de devise invalides');
      }
      throw Exception('Erreur réseau: ${e.message}');
    } catch (e) {
      print('❌ Erreur inattendue lors de la mise à jour: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  /// Formater un montant dans la devise d'affichage de l'utilisateur
  Future<String> formatUserAmount(
    double amount, {
    bool showCode = false,
  }) async {
    try {
      final token = await authService.getToken();
      if (token == null) {
        // Fallback sans authentification
        return '\$${amount.toStringAsFixed(2)}';
      }

      // Essayer d'utiliser l'endpoint de formatage si disponible
      final Map<String, dynamic> queryParams = {'amount': amount};
      if (showCode) {
        queryParams['show_code'] = 'true';
      }

      final response = await dio.post(
        '/currency/format-display',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['formatted_amount'] as String;
      } else {
        throw Exception('Erreur lors du formatage d\'affichage');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Fallback si token invalide
        return '\$${amount.toStringAsFixed(2)}';
      }
      // En cas d'erreur, essayer de récupérer la devise utilisateur et formater localement
      try {
        final userCurrency = await getUserCurrency();
        return userCurrency.formatAmount(amount, showCode: showCode);
      } catch (getUserError) {
        // Fallback final
        return '\$${amount.toStringAsFixed(2)}';
      }
    } catch (e) {
      // Fallback en cas d'erreur
      try {
        final userCurrency = await getUserCurrency();
        return userCurrency.formatAmount(amount, showCode: showCode);
      } catch (getUserError) {
        return '\$${amount.toStringAsFixed(2)}';
      }
    }
  }

  /// ✅ NOUVEAU: Cache local avec devises prédéfinies
  static List<Currency>? _cachedCurrencies;
  static DateTime? _cacheTime;
  static const Duration _cacheValidDuration = Duration(
    hours: 24,
  ); // Plus long car c'est prédéfini

  /// Obtenir les devises avec cache (prédéfinies)
  Future<List<Currency>> getCachedCurrencies({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();

    // Si on force le refresh ou si le cache est expiré
    if (forceRefresh ||
        _cachedCurrencies == null ||
        _cacheTime == null ||
        now.difference(_cacheTime!).compareTo(_cacheValidDuration) > 0) {
      print('🔄 Mise à jour du cache des devises');
      try {
        final currencies = await getAllCurrencies();
        _cachedCurrencies = currencies;
        _cacheTime = now;
        print('✅ Cache mis à jour avec ${currencies.length} devises');
        return currencies;
      } catch (e) {
        print('❌ Erreur lors de la mise à jour du cache: $e');
        // Retourner le cache même expiré en cas d'erreur
        if (_cachedCurrencies != null) {
          print('🔄 Utilisation du cache expiré');
          return _cachedCurrencies!;
        }
        // Fallback avec les devises prédéfinies de base
        print('🔄 Fallback vers les devises de base');
        return [Currency.cad, Currency.usd, Currency.eur, Currency.gbp];
      }
    }

    print(
      '✅ Utilisation du cache existant (${_cachedCurrencies!.length} devises)',
    );
    return _cachedCurrencies!;
  }

  /// Vider le cache des devises
  void clearCache() {
    print('🗑️ Vidage du cache des devises');
    _cachedCurrencies = null;
    _cacheTime = null;
  }

  /// Obtenir une devise depuis le cache par code
  Future<Currency?> getCachedCurrencyByCode(String code) async {
    try {
      final currencies = await getCachedCurrencies();
      return currencies.firstWhere(
        (currency) => currency.code.toUpperCase() == code.toUpperCase(),
      );
    } catch (e) {
      print('❌ Devise non trouvée dans le cache: $code');
      return Currency.findByCode(code); // Fallback vers les devises prédéfinies
    }
  }

  /// ✅ NOUVEAU: Initialiser le cache avec les devises prédéfinies
  Future<void> initializeCache() async {
    try {
      print('🚀 Initialisation du cache des devises avec devises prédéfinies');
      _cachedCurrencies = Currency.getActive();
      _cacheTime = DateTime.now();
      print('✅ Cache initialisé avec ${_cachedCurrencies!.length} devises');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation du cache: $e');
    }
  }
}
