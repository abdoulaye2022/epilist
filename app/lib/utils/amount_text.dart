// utils/amount_text.dart - Un montant en TEXTE, pour une phrase.
//
// `FormattedAmount` est un widget : il ne sert pas dans « Total
// estimé : 87,00 $ » ni dans « Reste dans le budget : 270,00 $ », où le
// montant est au milieu d'une phrase traduite, et où couper la phrase
// en trois Text pour glisser le widget au milieu casserait l'ordre des
// mots en anglais.
//
// La devise vient d'où elle vient pour le widget : l'utilisateur
// authentifié d'abord, le CurrencyBloc ensuite. Faute de devise connue,
// le dollar canadien — celle de la quasi-totalité des comptes, et
// mieux vaut un symbole juste dans 99 % des cas qu'un nombre nu.
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/blocs/currency/currency_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

String amountText(BuildContext context, double amount) {
  try {
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthSuccess && auth.user.currency != null) {
      return auth.user.formatAmount(amount);
    }
  } catch (_) {
    // Pas d'AuthBloc au-dessus (test de widget isolé) : on continue.
  }
  try {
    final currency = context.read<CurrencyBloc>().getCurrentCurrency();
    if (currency != null) return currency.formatAmount(amount);
  } catch (_) {
    // Idem.
  }
  return '\$${amount.toStringAsFixed(2)}';
}
