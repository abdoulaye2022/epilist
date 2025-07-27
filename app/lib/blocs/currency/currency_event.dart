// blocs/currency/currency_event.dart - VERSION COMPLÈTE
import 'package:equatable/equatable.dart';

abstract class CurrencyEvent extends Equatable {
  const CurrencyEvent();

  @override
  List<Object?> get props => [];
}

/// Charger toutes les devises disponibles
class LoadCurrencies extends CurrencyEvent {
  final bool popularOnly;
  final bool forceRefresh;

  const LoadCurrencies({this.popularOnly = false, this.forceRefresh = false});

  @override
  List<Object?> get props => [popularOnly, forceRefresh];
}

/// Charger la devise d'affichage de l'utilisateur actuel
class LoadUserCurrency extends CurrencyEvent {
  const LoadUserCurrency();
}

/// Mettre à jour la devise d'affichage de l'utilisateur
class UpdateUserCurrency extends CurrencyEvent {
  final int currencyId;

  const UpdateUserCurrency(this.currencyId);

  @override
  List<Object?> get props => [currencyId];
}

/// Formater un montant dans la devise d'affichage de l'utilisateur (SANS CONVERSION)
class FormatUserAmount extends CurrencyEvent {
  final double amount;
  final bool showCode;

  const FormatUserAmount({required this.amount, this.showCode = false});

  @override
  List<Object?> get props => [amount, showCode];
}

/// Sélectionner une devise temporairement (pour les dialogues)
class SelectCurrency extends CurrencyEvent {
  final int currencyId;

  const SelectCurrency(this.currencyId);

  @override
  List<Object?> get props => [currencyId];
}

/// Effacer les erreurs de devise
class ClearCurrencyError extends CurrencyEvent {
  const ClearCurrencyError();
}

/// Réinitialiser la sélection de devise
class ResetCurrencySelection extends CurrencyEvent {
  const ResetCurrencySelection();
}

/// Vider le cache des devises
class ClearCurrencyCache extends CurrencyEvent {
  const ClearCurrencyCache();
}

/// Obtenir une devise par son code
class GetCurrencyByCode extends CurrencyEvent {
  final String code;

  const GetCurrencyByCode(this.code);

  @override
  List<Object?> get props => [code];
}

/// Obtenir une devise par son ID
class GetCurrencyById extends CurrencyEvent {
  final int id;

  const GetCurrencyById(this.id);

  @override
  List<Object?> get props => [id];
}
