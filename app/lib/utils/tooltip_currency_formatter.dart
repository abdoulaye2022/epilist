// utils/tooltip_currency_formatter.dart - Helper pour formater les devises dans les tooltips
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/blocs/currency/currency_bloc.dart';
import 'package:epilist/blocs/currency/currency_state.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:epilist/models/currency.dart';

class TooltipCurrencyFormatter {
  /// Formate un montant selon la devise de l'utilisateur pour les tooltips
  static String formatAmount(BuildContext context, double amount) {
    final currency = _getCurrentCurrency(context);
    final locale = _getCurrentLocale(context);
    return _formatAmountInternational(amount, currency, locale);
  }

  /// Formate un montant selon les normes internationales
  static String _formatAmountInternational(
    double amount,
    Currency currency,
    Locale locale,
  ) {
    final code = currency.code.toUpperCase();
    final decimals = _getDecimalsForCurrency(code);
    final formattedNumber = amount.toStringAsFixed(decimals);

    // Appliquer les séparateurs selon la région et la langue
    final localizedNumber = _applyLocalizedSeparators(
      formattedNumber,
      code,
      locale,
    );

    // Appliquer le placement du symbole selon les normes internationales
    return _applySymbolPlacement(localizedNumber, currency);
  }

  /// Obtenir le nombre de décimales selon la norme ISO 4217
  static int _getDecimalsForCurrency(String currencyCode) {
    switch (currencyCode) {
      // Devises sans décimales (0 décimales)
      case 'JPY': // Yen japonais
      case 'KRW': // Won coréen
      case 'VND': // Dong vietnamien
      case 'CLP': // Peso chilien
      case 'ISK': // Couronne islandaise
      case 'XOF': // Franc CFA BCEAO (traditionnellement sans décimales)
      case 'XAF': // Franc CFA BEAC (traditionnellement sans décimales)
        return 0;

      // Devises avec 3 décimales
      case 'BHD': // Dinar de Bahreïn
      case 'KWD': // Dinar koweïtien
      case 'OMR': // Rial omanais
      case 'JOD': // Dinar jordanien
      case 'IQD': // Dinar irakien
      case 'LYD': // Dinar libyen
      case 'TND': // Dinar tunisien
        return 3;

      // Toutes les autres devises (2 décimales - standard)
      default:
        return 2;
    }
  }

  /// Appliquer les séparateurs localisés (décimal et milliers)
  static String _applyLocalizedSeparators(
    String formattedNumber,
    String currencyCode,
    Locale locale,
  ) {
    // Séparer la partie entière et décimale
    final parts = formattedNumber.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';

    // Déterminer les séparateurs selon la région ET la langue de l'utilisateur
    String thousandSeparator = ',';
    String decimalSeparator = '.';

    // Si la langue de l'utilisateur est le français ou si c'est une devise européenne/africaine francophone
    final isFrenchLocale = locale.languageCode == 'fr';
    final commaDecimalCountries = [
      'EUR', 'CHF', 'DZD', 'MAD', 'TND', // Europe et Afrique du Nord
      'XOF', 'XAF', // Francs CFA (influence française)
    ];

    if (isFrenchLocale || commaDecimalCountries.contains(currencyCode)) {
      thousandSeparator = ' '; // Espace pour le français (norme française)
      decimalSeparator = ',';
    }

    // Ajouter les séparateurs de milliers
    String formattedInteger = _addThousandSeparators(
      integerPart,
      thousandSeparator,
    );

    // Reconstituer le nombre
    if (decimalPart.isNotEmpty) {
      return '$formattedInteger$decimalSeparator$decimalPart';
    }
    return formattedInteger;
  }

  /// Ajouter les séparateurs de milliers
  static String _addThousandSeparators(String number, String separator) {
    if (number.length <= 3) return number;

    final reversed = number.split('').reversed.toList();
    final result = <String>[];

    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        result.add(separator);
      }
      result.add(reversed[i]);
    }

    return result.reversed.join();
  }

  /// Appliquer le placement du symbole selon les normes internationales
  static String _applySymbolPlacement(
    String formattedNumber,
    Currency currency,
  ) {
    final code = currency.code.toUpperCase();
    final symbol = currency.symbol;

    // Devises avec symbole APRÈS le montant (avec espace)
    final symbolAfterWithSpace = [
      'EUR', 'CHF', 'DZD', 'MAD', 'TND', // Europe et Afrique du Nord
      'XOF', 'XAF', // Francs CFA
      'ZAR', 'NAD', // Afrique du Sud et Namibie
    ];

    // Devises avec symbole APRÈS le montant (sans espace)
    final symbolAfterNoSpace = [
      'SEK', 'NOK', 'DKK', // Pays nordiques
    ];

    // Devises avec code AVANT le montant (avec espace)
    final codeBeforeWithSpace = [
      'CHF', 'XOF', 'XAF', 'NGN', 'EGP', 'KES', 'GHS',
      'ETB', 'UGX', 'BWP', // Devises africaines spécifiques
    ];

    if (symbolAfterWithSpace.contains(code)) {
      return '$formattedNumber $symbol';
    } else if (symbolAfterNoSpace.contains(code)) {
      return '$formattedNumber$symbol';
    } else if (codeBeforeWithSpace.contains(code) && symbol.length > 2) {
      // Utiliser le code pour les symboles longs
      return '$symbol $formattedNumber';
    } else {
      // Symbole AVANT le montant (standard anglophone)
      return '$symbol$formattedNumber';
    }
  }

  /// Obtenir la locale actuelle de l'utilisateur
  static Locale _getCurrentLocale(BuildContext context) {
    try {
      final localizationState = context.read<LocalizationBloc>().state;
      if (localizationState is LocalizationLoaded) {
        return localizationState.locale;
      }
    } catch (e) {
      print('Erreur lors de la récupération de la locale: $e');
    }

    // Fallback: locale du système ou français par défaut
    return Localizations.localeOf(context);
  }

  /// Déterminer la devise actuelle depuis les différents états
  static Currency _getCurrentCurrency(BuildContext context) {
    try {
      final authState = context.read<AuthBloc>().state;
      final currencyState = context.read<CurrencyBloc>().state;

      // 1. État de devise mise à jour récemment
      if (currencyState is UserCurrencyUpdated) {
        return currencyState.userCurrency.currency;
      }

      // 2. État de devise chargée
      if (currencyState is UserCurrencyLoaded) {
        return currencyState.userCurrency.currency;
      }

      // 3. État de devise sélectionnée
      if (currencyState is CurrencySelected) {
        return currencyState.currency;
      }

      // 4. Devise depuis l'utilisateur authentifié
      if (authState is AuthSuccess && authState.user.currency != null) {
        return authState.user.currency!;
      }

      // 5. Utiliser le CurrencyBloc
      final currencyBloc = context.read<CurrencyBloc>();
      final currentCurrency = currencyBloc.getCurrentCurrency();
      if (currentCurrency != null) {
        return currentCurrency;
      }
    } catch (e) {
      print('Erreur lors de la récupération de la devise: $e');
    }

    // Fallback final: CAD
    return Currency.cad;
  }
}
