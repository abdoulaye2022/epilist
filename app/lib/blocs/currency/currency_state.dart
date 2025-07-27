// blocs/currency/currency_state.dart - VERSION COMPLÈTE
import 'package:equatable/equatable.dart';
import 'package:epilist/models/currency.dart';
import 'package:epilist/models/user_currency.dart';

abstract class CurrencyState extends Equatable {
  const CurrencyState();

  @override
  List<Object?> get props => [];
}

/// État initial des devises
class CurrencyInitial extends CurrencyState {}

/// État de chargement
class CurrencyLoading extends CurrencyState {}

/// État d'erreur
class CurrencyError extends CurrencyState {
  final String message;

  const CurrencyError(this.message);

  @override
  List<Object> get props => [message];
}

/// Devises chargées avec succès
class CurrenciesLoaded extends CurrencyState {
  final List<Currency> currencies;
  final UserCurrency? userCurrency;
  final bool isPopularOnly;

  const CurrenciesLoaded({
    required this.currencies,
    this.userCurrency,
    this.isPopularOnly = false,
  });

  @override
  List<Object?> get props => [currencies, userCurrency, isPopularOnly];
}

/// Devise d'affichage de l'utilisateur chargée
class UserCurrencyLoaded extends CurrencyState {
  final UserCurrency userCurrency;

  const UserCurrencyLoaded(this.userCurrency);

  @override
  List<Object> get props => [userCurrency];
}

/// Devise d'affichage de l'utilisateur mise à jour
class UserCurrencyUpdated extends CurrencyState {
  final UserCurrency userCurrency;
  final String message;

  const UserCurrencyUpdated({
    required this.userCurrency,
    required this.message,
  });

  @override
  List<Object> get props => [userCurrency, message];
}

/// Montant formaté pour l'affichage
class AmountFormatted extends CurrencyState {
  final String formattedAmount;
  final double originalAmount;

  const AmountFormatted({
    required this.formattedAmount,
    required this.originalAmount,
  });

  @override
  List<Object> get props => [formattedAmount, originalAmount];
}

/// Devise sélectionnée temporairement
class CurrencySelected extends CurrencyState {
  final Currency currency;

  const CurrencySelected(this.currency);

  @override
  List<Object> get props => [currency];
}

/// Devise trouvée par code
class CurrencyFoundByCode extends CurrencyState {
  final Currency currency;

  const CurrencyFoundByCode(this.currency);

  @override
  List<Object> get props => [currency];
}

/// Devise trouvée par ID
class CurrencyFoundById extends CurrencyState {
  final Currency currency;

  const CurrencyFoundById(this.currency);

  @override
  List<Object> get props => [currency];
}

/// Cache des devises vidé
class CurrencyCacheCleared extends CurrencyState {}
