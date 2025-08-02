// widgets/currency/formatted_amount.dart - VERSION FINALE CORRIGÉE AVEC NORMES INTERNATIONALES
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/blocs/currency/currency_bloc.dart';
import 'package:epilist/blocs/currency/currency_state.dart';
import 'package:epilist/blocs/currency/currency_event.dart';
import 'package:epilist/models/user.dart';
import 'package:epilist/models/currency.dart';

/// Widget pour afficher un montant avec la devise d'affichage de l'utilisateur
class FormattedAmount extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final bool showCode;
  final String? fallbackCurrencyCode;

  const FormattedAmount({
    super.key,
    required this.amount,
    this.style,
    this.showCode = false,
    this.fallbackCurrencyCode,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return BlocBuilder<CurrencyBloc, CurrencyState>(
          builder: (context, currencyState) {
            // Essayer de charger la devise si nécessaire
            if (currencyState is CurrencyInitial && authState is AuthSuccess) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<CurrencyBloc>().add(const LoadUserCurrency());
              });
            }

            // Déterminer la devise à utiliser
            Currency currency = _getCurrentCurrency(
              authState,
              currencyState,
              context,
            );

            // Formater le montant selon les normes internationales
            final formatted = _formatAmountInternational(amount, currency);
            final displayText =
                showCode
                    ? '$formatted ${currency.code.toUpperCase()}'
                    : formatted;

            return Text(
              displayText,
              style: style,
              overflow: TextOverflow.ellipsis,
            );
          },
        );
      },
    );
  }

  /// Formater le montant selon les normes internationales
  String _formatAmountInternational(double amount, Currency currency) {
    final code = currency.code.toUpperCase();
    final decimals = _getDecimalsForCurrency(code);
    final formattedNumber = amount.toStringAsFixed(decimals);

    // Appliquer les séparateurs selon la région
    final localizedNumber = _applyLocalizedSeparators(formattedNumber, code);

    // Appliquer le placement du symbole selon les normes internationales
    return _applySymbolPlacement(localizedNumber, currency);
  }

  /// Obtenir le nombre de décimales selon la norme ISO 4217
  int _getDecimalsForCurrency(String currencyCode) {
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
  String _applyLocalizedSeparators(
    String formattedNumber,
    String currencyCode,
  ) {
    // Séparer la partie entière et décimale
    final parts = formattedNumber.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';

    // Déterminer les séparateurs selon la région
    String thousandSeparator = ',';
    String decimalSeparator = '.';

    // Régions utilisant virgule comme séparateur décimal et point pour milliers
    final commaDecimalCountries = [
      'EUR', 'CHF', 'DZD', 'MAD', 'TND', // Europe et Afrique du Nord
      'XOF', 'XAF', // Francs CFA (influence française)
    ];

    if (commaDecimalCountries.contains(currencyCode)) {
      thousandSeparator = '.';
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
  String _addThousandSeparators(String number, String separator) {
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
  String _applySymbolPlacement(String formattedNumber, Currency currency) {
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

  /// Obtenir le symbole correct pour un code de devise
  String _getSymbolForCode(String code) {
    final symbolMap = {
      // Devises principales
      'USD': '\$',
      'CAD': '\$',
      'AUD': 'A\$',
      'HKD': 'HK\$',
      'SGD': 'S\$',
      'NAD': 'N\$',
      'EUR': '€',
      'GBP': '£',
      'EGP': '£',
      'JPY': '¥',
      'CNY': '¥',
      'CHF': 'CHF',

      // Devises africaines
      'ZAR': 'R',
      'NGN': '₦',
      'MAD': 'د.م.',
      'XOF': 'CFA',
      'XAF': 'FCFA',
      'KES': 'KSh',
      'GHS': 'GH₵',
      'ETB': 'Br',
      'TND': 'د.ت',
      'DZD': 'د.ج',
      'UGX': 'USh',
      'MUR': '₨',
      'BWP': 'P',
    };

    return symbolMap[code.toUpperCase()] ?? '\$';
  }

  /// Déterminer la devise actuelle depuis les différents états
  Currency _getCurrentCurrency(
    AuthState authState,
    CurrencyState currencyState,
    BuildContext context,
  ) {
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
    try {
      final currencyBloc = BlocProvider.of<CurrencyBloc>(context);
      final currentCurrency = currencyBloc.getCurrentCurrency();
      if (currentCurrency != null) {
        return currentCurrency;
      }
    } catch (e) {
      print('CurrencyBloc non disponible: $e');
    }

    // 6. Fallback avec devise personnalisée
    if (fallbackCurrencyCode != null) {
      final predefinedCurrency = Currency.findByCode(fallbackCurrencyCode!);
      if (predefinedCurrency != null) {
        return predefinedCurrency;
      }

      // Créer une devise temporaire
      final now = DateTime.now();
      return Currency(
        id: 0,
        code: fallbackCurrencyCode!,
        name: fallbackCurrencyCode!,
        symbol: _getSymbolForCode(fallbackCurrencyCode!),
        isActive: true,
        isPopular: false,
        displayOrder: 999,
        createdAt: now,
        updatedAt: now,
      );
    }

    // 7. Fallback final: CAD
    return Currency.cad;
  }
}

/// Widget pour afficher uniquement l'indicateur de devise
class CurrencyIndicator extends StatelessWidget {
  final TextStyle? style;
  final String? fallbackCode;

  const CurrencyIndicator({super.key, this.style, this.fallbackCode = 'CAD'});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return BlocBuilder<CurrencyBloc, CurrencyState>(
          builder: (context, currencyState) {
            String currencyCode = _getCurrentCurrencyCode(
              authState,
              currencyState,
              context,
            );

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Text(
                currencyCode.toUpperCase(),
                style:
                    style ??
                    TextStyle(
                      fontSize: 12,
                      color: Colors.amber[700],
                      fontWeight: FontWeight.w500,
                    ),
              ),
            );
          },
        );
      },
    );
  }

  /// Obtenir le code de devise actuel
  String _getCurrentCurrencyCode(
    AuthState authState,
    CurrencyState currencyState,
    BuildContext context,
  ) {
    if (currencyState is UserCurrencyUpdated) {
      return currencyState.userCurrency.currency.code;
    }

    if (currencyState is UserCurrencyLoaded) {
      return currencyState.userCurrency.currency.code;
    }

    if (currencyState is CurrencySelected) {
      return currencyState.currency.code;
    }

    if (authState is AuthSuccess && authState.user.currency != null) {
      return authState.user.currency!.code;
    }

    try {
      final currencyBloc = BlocProvider.of<CurrencyBloc>(context);
      final currentCode = currencyBloc.getCurrentCurrencyCode();
      if (currentCode != 'CAD' || fallbackCode == null) {
        return currentCode;
      }
    } catch (e) {
      print('CurrencyBloc non disponible: $e');
    }

    return fallbackCode!;
  }
}
