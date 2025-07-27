// widgets/currency/formatted_amount.dart - VERSION FINALE PROPRE
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

  const FormattedAmount({
    super.key,
    required this.amount,
    this.style,
    this.showCode = false,
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
            Currency currency = _getCurrentCurrency(authState, currencyState);

            // Formater le montant
            final formatted = amount.toStringAsFixed(2);
            final displayText =
                showCode
                    ? '${currency.symbol}$formatted ${currency.code}'
                    : '${currency.symbol}$formatted';

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

  /// Déterminer la devise actuelle depuis les différents états
  Currency _getCurrentCurrency(
    AuthState authState,
    CurrencyState currencyState,
  ) {
    // 1. PRIORITÉ: État de devise mise à jour récemment
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

    // 4. Devise depuis l'utilisateur authentifié
    if (authState is AuthSuccess && authState.user.hasCurrency) {
      return authState.user.currency!;
    }

    // 5. Fallback: CAD par défaut
    return Currency.cad;
  }
}
