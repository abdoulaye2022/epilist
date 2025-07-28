// widgets/currency/formatted_amount.dart - VERSION FINALE CORRIGÉE
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
  final String?
  fallbackCurrencyCode; // Optionnel pour spécifier un fallback différent

  const FormattedAmount({
    super.key,
    required this.amount,
    this.style,
    this.showCode = false,
    this.fallbackCurrencyCode, // Par défaut null = CAD
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return BlocBuilder<CurrencyBloc, CurrencyState>(
          builder: (context, currencyState) {
            // ✅ CORRECTION: Essayer de charger la devise si nécessaire
            if (currencyState is CurrencyInitial && authState is AuthSuccess) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<CurrencyBloc>().add(const LoadUserCurrency());
              });
            }

            // ✅ CORRECTION: Déterminer la devise à utiliser dynamiquement
            Currency currency = _getCurrentCurrency(
              authState,
              currencyState,
              context,
            );

            // ✅ CORRECTION: Formater le montant avec la vraie devise
            final formatted = _formatAmount(amount, currency);
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

  /// ✅ CORRECTION: Formater le montant selon les règles de la devise
  String _formatAmount(double amount, Currency currency) {
    // Gérer les décimales selon la devise
    final decimals = _getDecimalsForCurrency(currency.code);
    final formattedNumber = amount.toStringAsFixed(decimals);

    // Appliquer le symbole selon la devise
    switch (currency.code.toUpperCase()) {
      case 'EUR':
        return '$formattedNumber€'; // Euro après le montant
      case 'USD':
      case 'CAD':
      case 'AUD':
        return '${currency.symbol}$formattedNumber'; // Dollar avant le montant
      case 'GBP':
        return '£$formattedNumber'; // Livre avant le montant
      case 'JPY':
        return '¥${amount.toStringAsFixed(0)}'; // Yen sans décimales
      case 'CHF':
        return 'CHF $formattedNumber'; // Franc suisse avec espace
      default:
        return '${currency.symbol}$formattedNumber';
    }
  }

  /// ✅ NOUVEAU: Obtenir le nombre de décimales selon la devise
  int _getDecimalsForCurrency(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'JPY': // Yen japonais sans décimales
      case 'KRW': // Won coréen sans décimales
        return 0;
      case 'BHD': // Dinar de Bahreïn avec 3 décimales
      case 'KWD': // Dinar koweïtien avec 3 décimales
        return 3;
      default:
        return 2; // La plupart des devises ont 2 décimales
    }
  }

  /// ✅ CORRECTION: Déterminer la devise actuelle depuis les différents états
  Currency _getCurrentCurrency(
    AuthState authState,
    CurrencyState currencyState,
    BuildContext context,
  ) {
    // 1. PRIORITÉ MAXIMALE: État de devise mise à jour récemment
    if (currencyState is UserCurrencyUpdated) {
      return currencyState.userCurrency.currency;
    }

    // 2. État de devise chargée via CurrencyBloc
    if (currencyState is UserCurrencyLoaded) {
      return currencyState.userCurrency.currency;
    }

    // 3. État de devise sélectionnée temporairement
    if (currencyState is CurrencySelected) {
      return currencyState.currency;
    }

    // 4. ✅ CORRECTION: Devise depuis l'utilisateur authentifié (priorité élevée)
    if (authState is AuthSuccess && authState.user.currency != null) {
      return authState.user.currency!;
    }

    // 5. ✅ CORRECTION: Utiliser le CurrencyBloc pour obtenir la devise actuelle
    try {
      final currencyBloc = BlocProvider.of<CurrencyBloc>(context);
      final currentCurrency = currencyBloc.getCurrentCurrency();
      if (currentCurrency != null) {
        return currentCurrency;
      }
    } catch (e) {
      // Si le BlocProvider n'est pas disponible, continuer avec les fallbacks
      print('CurrencyBloc non disponible: $e');
    }

    // 6. ✅ NOUVEAU: Fallback avec devise personnalisée si spécifiée
    if (fallbackCurrencyCode != null) {
      // Essayer de trouver la devise dans les devises prédéfinies
      final predefinedCurrency = Currency.findByCode(fallbackCurrencyCode!);
      if (predefinedCurrency != null) {
        return predefinedCurrency;
      }

      // Si pas trouvé, créer une devise temporaire
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

    // 7. Fallback final: CAD par défaut
    return Currency.cad;
  }

  /// ✅ NOUVEAU: Obtenir le symbole pour un code de devise
  String _getSymbolForCode(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CAD':
        return '\$';
      case 'AUD':
        return '\$';
      case 'CHF':
        return 'CHF';
      default:
        return '\$';
    }
  }
}

/// ✅ NOUVEAU: Widget pour afficher uniquement l'indicateur de devise (pour les placeholders)
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
            // ✅ CORRECTION CRITIQUE: Ajouter le paramètre context manquant
            String currencyCode = _getCurrentCurrencyCode(
              authState,
              currencyState,
              context, // ✅ AJOUTÉ LE CONTEXT MANQUANT
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

  /// ✅ CORRECTION: Obtenir le code de devise actuel avec tous les paramètres
  String _getCurrentCurrencyCode(
    AuthState authState,
    CurrencyState currencyState,
    BuildContext context, // ✅ PARAMÈTRE CONTEXT AJOUTÉ
  ) {
    // Vérifier les états de devise dans l'ordre de priorité
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

    // Utiliser le CurrencyBloc
    try {
      final currencyBloc = BlocProvider.of<CurrencyBloc>(context);
      final currentCode = currencyBloc.getCurrentCurrencyCode();
      if (currentCode != 'CAD' || fallbackCode == null) {
        return currentCode;
      }
    } catch (e) {
      // Si le BlocProvider n'est pas disponible, utiliser le fallback
      print('CurrencyBloc non disponible: $e');
    }

    return fallbackCode!;
  }
}
